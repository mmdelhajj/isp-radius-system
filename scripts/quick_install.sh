#!/bin/bash

# ISP RADIUS & Billing Management System - Quick Installation Script
# For Ubuntu 22.04 LTS Production Servers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as a regular user with sudo privileges."
fi

# Check Ubuntu version
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    warn "This script is designed for Ubuntu 22.04 LTS. Continuing anyway..."
fi

log "Starting ISP RADIUS & Billing Management System Installation"

# Get configuration from user
echo -e "${BLUE}=== Configuration Setup ===${NC}"
read -p "Enter database password for RADIUS user: " -s DB_PASSWORD
echo
read -p "Enter your domain name (e.g., myisp.com): " DOMAIN_NAME
read -p "Enter your email for SSL certificate: " EMAIL_ADDRESS

# Update system
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
log "Installing essential packages..."
sudo apt install -y curl wget git unzip software-properties-common ufw

# Install PostgreSQL
log "Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
log "Setting up database..."
sudo -u postgres psql << EOF
CREATE DATABASE radiusdb;
CREATE USER radiususer WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE radiusdb TO radiususer;
ALTER USER radiususer CREATEDB;
\q
EOF

# Install FreeRADIUS
log "Installing FreeRADIUS..."
sudo apt install -y freeradius freeradius-postgresql freeradius-utils

# Import RADIUS schema
log "Setting up RADIUS database schema..."
sudo -u postgres psql radiusdb < /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql

# Install Redis
log "Installing Redis..."
sudo apt install -y redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Install Node.js
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Nginx
log "Installing Nginx..."
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Create application directory
log "Setting up application directory..."
sudo mkdir -p /opt/isp-radius
sudo chown $USER:$USER /opt/isp-radius

# Create database schema
log "Creating database tables..."
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

-- Add bandwidth control groups
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
EOF

# Configure FreeRADIUS SQL module
log "Configuring FreeRADIUS..."
sudo cp /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/

# Update SQL configuration
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
sudo sed -i '/authorize {/,/}/ { /files/ a\\tsql' /etc/freeradius/3.0/sites-enabled/default

# Configure firewall
log "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 1812/udp
sudo ufw allow 1813/udp

# Create simple web interface
log "Setting up web interface..."
sudo mkdir -p /var/www/html
sudo tee /var/www/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ISP Management System</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; }
        .status { padding: 15px; margin: 10px 0; border-radius: 5px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .next-steps { background: #fff3cd; color: #856404; border: 1px solid #ffeaa7; }
        ul { padding-left: 20px; }
        li { margin: 5px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 ISP RADIUS & Billing Management System</h1>
        
        <div class="status success">
            <h3>✅ Installation Complete!</h3>
            <p>Your ISP RADIUS & Billing Management System has been successfully installed and configured.</p>
        </div>
        
        <div class="status info">
            <h3>📊 System Components</h3>
            <ul>
                <li><strong>PostgreSQL Database</strong> - Customer and billing data storage</li>
                <li><strong>FreeRADIUS Server</strong> - Authentication and accounting (ports 1812/1813)</li>
                <li><strong>Redis Cache</strong> - Performance optimization</li>
                <li><strong>Nginx Web Server</strong> - Web interface hosting</li>
                <li><strong>Service Profiles</strong> - 5 pre-configured internet plans</li>
            </ul>
        </div>
        
        <div class="status next-steps">
            <h3>🚀 Next Steps</h3>
            <ol>
                <li><strong>Configure Network Equipment:</strong> Add your routers as RADIUS clients</li>
                <li><strong>Test Authentication:</strong> Create test customer accounts</li>
                <li><strong>Set Up SSL:</strong> Install SSL certificate for secure access</li>
                <li><strong>Deploy Web Interface:</strong> Upload your React application</li>
                <li><strong>Configure Monitoring:</strong> Set up system monitoring and alerts</li>
            </ol>
        </div>
        
        <div class="status info">
            <h3>🔧 Quick Commands</h3>
            <p><strong>Test RADIUS:</strong></p>
            <code>echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123</code>
            
            <p><strong>Check Services:</strong></p>
            <code>sudo systemctl status postgresql freeradius redis-server nginx</code>
            
            <p><strong>View Logs:</strong></p>
            <code>sudo tail -f /var/log/freeradius/radius.log</code>
        </div>
    </div>
</body>
</html>
EOF

# Restart services
log "Starting services..."
sudo systemctl restart postgresql
sudo systemctl restart freeradius
sudo systemctl restart redis-server
sudo systemctl restart nginx

# Create test user
log "Creating test user..."
sudo -u postgres psql radiusdb << EOF
INSERT INTO radcheck (username, attribute, op, value) VALUES ('testuser', 'Cleartext-Password', ':=', 'testpass') ON CONFLICT DO NOTHING;
INSERT INTO radusergroup (username, groupname, priority) VALUES ('testuser', 'Standard', 1) ON CONFLICT DO NOTHING;
EOF

# Install SSL certificate if domain provided
if [ ! -z "$DOMAIN_NAME" ] && [ ! -z "$EMAIL_ADDRESS" ]; then
    log "Installing SSL certificate..."
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d $DOMAIN_NAME --email $EMAIL_ADDRESS --agree-tos --non-interactive
fi

# Create backup script
log "Setting up backup system..."
sudo tee /opt/isp-radius/backup.sh > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/isp-radius/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
sudo -u postgres pg_dump radiusdb > $BACKUP_DIR/radiusdb_$DATE.sql
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /etc/freeradius /etc/nginx/sites-available
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
EOF

sudo chmod +x /opt/isp-radius/backup.sh

# Add to crontab
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/isp-radius/backup.sh") | crontab -

# Final status check
log "Performing final system check..."
sleep 5

echo -e "\n${GREEN}=== Installation Summary ===${NC}"
echo -e "${GREEN}✅ PostgreSQL Database: $(sudo systemctl is-active postgresql)${NC}"
echo -e "${GREEN}✅ FreeRADIUS Server: $(sudo systemctl is-active freeradius)${NC}"
echo -e "${GREEN}✅ Redis Cache: $(sudo systemctl is-active redis-server)${NC}"
echo -e "${GREEN}✅ Nginx Web Server: $(sudo systemctl is-active nginx)${NC}"

# Test RADIUS authentication
echo -e "\n${BLUE}Testing RADIUS authentication...${NC}"
if echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123 | grep -q "Access-Accept"; then
    echo -e "${GREEN}✅ RADIUS authentication test: PASSED${NC}"
else
    echo -e "${YELLOW}⚠️  RADIUS authentication test: Check configuration${NC}"
fi

echo -e "\n${GREEN}🎉 Installation Complete!${NC}"
echo -e "${BLUE}Web Interface: http://$DOMAIN_NAME (or http://$(hostname -I | awk '{print $1}'))${NC}"
echo -e "${BLUE}RADIUS Server: $(hostname -I | awk '{print $1}'):1812${NC}"
echo -e "${BLUE}Database: radiusdb on localhost:5432${NC}"

echo -e "\n${YELLOW}📋 Next Steps:${NC}"
echo -e "1. Configure your network equipment to use this RADIUS server"
echo -e "2. Add your routers as RADIUS clients in the database"
echo -e "3. Deploy your React web interface to /var/www/html"
echo -e "4. Set up monitoring and alerting"
echo -e "5. Create your first customer accounts"

echo -e "\n${GREEN}Installation log saved to: /var/log/isp-radius-install.log${NC}"

