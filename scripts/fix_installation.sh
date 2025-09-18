#!/bin/bash

# Fix for FreeRADIUS schema import permission issue
# Run this script to resolve the installation error

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

log "Fixing FreeRADIUS schema import permission issue..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as a regular user with sudo privileges."
fi

# Get database password
read -p "Enter the database password you used during installation: " -s DB_PASSWORD
echo

# Fix schema file permissions
log "Fixing schema file permissions..."
sudo chmod +r /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql

# Alternative: Copy schema to accessible location
log "Copying schema to accessible location..."
sudo cp /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql /tmp/radius_schema.sql
sudo chmod 644 /tmp/radius_schema.sql

# Import schema using the copied file
log "Importing FreeRADIUS schema..."
sudo -u postgres psql radiusdb < /tmp/radius_schema.sql

# Create our custom tables
log "Creating custom ISP management tables..."
sudo -u postgres psql radiusdb << 'EOF'
-- Service profiles table
CREATE TABLE IF NOT EXISTS service_profiles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    download_speed INTEGER NOT NULL,
    upload_speed INTEGER NOT NULL,
    data_quota INTEGER,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customers table
CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(20),
    zip_code VARCHAR(10),
    service_profile VARCHAR(50),
    status VARCHAR(20) DEFAULT 'active',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Billing table
CREATE TABLE IF NOT EXISTS customer_billing (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(20),
    billing_cycle_start DATE NOT NULL,
    billing_cycle_end DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    paid_date DATE,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default service profiles
INSERT INTO service_profiles (name, download_speed, upload_speed, data_quota, price, description) VALUES
('Student', 15, 3, 75, 19.99, 'Perfect for students and light users'),
('Basic', 10, 2, 50, 29.99, 'Essential internet for everyday use'),
('Standard', 25, 5, 150, 49.99, 'Great for families and streaming'),
('Premium', 50, 10, 300, 79.99, 'High-speed for power users'),
('Business', 100, 20, NULL, 149.99, 'Unlimited business-grade service')
ON CONFLICT (name) DO NOTHING;

-- Add bandwidth control groups to RADIUS
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
('Student', 'WISPr-Bandwidth-Max-Down', ':=', '15000000'),
('Student', 'WISPr-Bandwidth-Max-Up', ':=', '3000000'),
('Basic', 'WISPr-Bandwidth-Max-Down', ':=', '10000000'),
('Basic', 'WISPr-Bandwidth-Max-Up', ':=', '2000000'),
('Standard', 'WISPr-Bandwidth-Max-Down', ':=', '25000000'),
('Standard', 'WISPr-Bandwidth-Max-Up', ':=', '5000000'),
('Premium', 'WISPr-Bandwidth-Max-Down', ':=', '50000000'),
('Premium', 'WISPr-Bandwidth-Max-Up', ':=', '10000000'),
('Business', 'WISPr-Bandwidth-Max-Down', ':=', '100000000'),
('Business', 'WISPr-Bandwidth-Max-Up', ':=', '20000000')
ON CONFLICT (groupname, attribute) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_service_profile ON customers(service_profile);
CREATE INDEX IF NOT EXISTS idx_billing_customer_id ON customer_billing(customer_id);
CREATE INDEX IF NOT EXISTS idx_billing_status ON customer_billing(status);
CREATE INDEX IF NOT EXISTS idx_radcheck_username ON radcheck(username);
CREATE INDEX IF NOT EXISTS idx_radusergroup_username ON radusergroup(username);
EOF

# Configure FreeRADIUS SQL module
log "Configuring FreeRADIUS SQL module..."
sudo tee /etc/freeradius/3.0/mods-enabled/sql > /dev/null << EOF
sql {
    driver = "rlm_sql_postgresql"
    dialect = "postgresql"
    
    server = "localhost"
    port = 5432
    login = "radiususer"
    password = "$DB_PASSWORD"
    radius_db = "radiusdb"
    
    acct_table1 = "radacct"
    acct_table2 = "radacct"
    postauth_table = "radpostauth"
    authcheck_table = "radcheck"
    groupcheck_table = "radgroupcheck"
    authreply_table = "radreply"
    groupreply_table = "radgroupreply"
    usergroup_table = "radusergroup"
    
    read_groups = yes
    read_profiles = yes
    
    pool {
        start = 1
        min = 0
        max = 32
        spare = 3
        uses = 0
        retry_delay = 30
        lifetime = 0
        idle_timeout = 60
    }
}
EOF

# Enable SQL in authorize section
log "Enabling SQL in FreeRADIUS authorize section..."
sudo sed -i '/authorize {/,/}/ { /files/ { a\\tsql
} }' /etc/freeradius/3.0/sites-enabled/default

# Create test user
log "Creating test user..."
sudo -u postgres psql radiusdb << EOF
INSERT INTO radcheck (username, attribute, op, value) VALUES ('testuser', 'Cleartext-Password', ':=', 'testpass') ON CONFLICT DO NOTHING;
INSERT INTO radusergroup (username, groupname, priority) VALUES ('testuser', 'Standard', 1) ON CONFLICT DO NOTHING;
EOF

# Restart services
log "Restarting services..."
sudo systemctl restart postgresql
sudo systemctl restart freeradius
sudo systemctl restart redis-server
sudo systemctl restart nginx

# Test RADIUS authentication
log "Testing RADIUS authentication..."
sleep 3
if echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123 | grep -q "Access-Accept"; then
    log "✅ RADIUS authentication test: PASSED"
else
    warn "⚠️  RADIUS authentication test: Check configuration"
    log "Running FreeRADIUS in debug mode for troubleshooting..."
    sudo systemctl stop freeradius
    echo "Run 'sudo freeradius -X' in another terminal to debug"
fi

# Check service status
log "Checking service status..."
echo -e "\n${BLUE}=== Service Status ===${NC}"
echo -e "${GREEN}PostgreSQL: $(sudo systemctl is-active postgresql)${NC}"
echo -e "${GREEN}FreeRADIUS: $(sudo systemctl is-active freeradius)${NC}"
echo -e "${GREEN}Redis: $(sudo systemctl is-active redis-server)${NC}"
echo -e "${GREEN}Nginx: $(sudo systemctl is-active nginx)${NC}"

# Clean up temporary files
sudo rm -f /tmp/radius_schema.sql

log "✅ Installation fix completed!"
echo -e "\n${GREEN}Your ISP RADIUS system should now be working correctly.${NC}"
echo -e "${BLUE}Test authentication: echo \"User-Name = testuser, User-Password = testpass\" | radclient localhost:1812 auth testing123${NC}"

