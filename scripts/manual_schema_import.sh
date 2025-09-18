#!/bin/bash

# Manual FreeRADIUS Schema Import Script
# Use this if the automatic installation fails

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

log "Manual FreeRADIUS Schema Import"

# Check if PostgreSQL is running
if ! sudo systemctl is-active --quiet postgresql; then
    error "PostgreSQL is not running. Please start it first: sudo systemctl start postgresql"
    exit 1
fi

# Get database password
read -p "Enter the database password for radiususer: " -s DB_PASSWORD
echo

# Method 1: Try direct import with sudo
log "Attempting Method 1: Direct schema import..."
if sudo -u postgres psql radiusdb < /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql 2>/dev/null; then
    log "✅ Method 1 successful!"
else
    warn "Method 1 failed, trying Method 2..."
    
    # Method 2: Copy to accessible location
    log "Attempting Method 2: Copy and import..."
    sudo cp /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql /tmp/schema.sql
    sudo chmod 644 /tmp/schema.sql
    
    if sudo -u postgres psql radiusdb < /tmp/schema.sql; then
        log "✅ Method 2 successful!"
        sudo rm /tmp/schema.sql
    else
        warn "Method 2 failed, trying Method 3..."
        
        # Method 3: Manual SQL execution
        log "Attempting Method 3: Manual SQL execution..."
        sudo -u postgres psql radiusdb << 'EOF'
-- FreeRADIUS PostgreSQL Schema (Essential Tables)

CREATE TABLE IF NOT EXISTS radacct (
    radacctid BIGSERIAL PRIMARY KEY,
    acctsessionid VARCHAR(64) NOT NULL DEFAULT '',
    acctuniqueid VARCHAR(32) NOT NULL DEFAULT '',
    username VARCHAR(64) NOT NULL DEFAULT '',
    realm VARCHAR(64) DEFAULT '',
    nasipaddress INET NOT NULL,
    nasportid VARCHAR(15),
    nasporttype VARCHAR(32),
    acctstarttime TIMESTAMP with time zone,
    acctupdatetime TIMESTAMP with time zone,
    acctstoptime TIMESTAMP with time zone,
    acctinterval BIGINT,
    acctsessiontime BIGINT,
    acctauthentic VARCHAR(32),
    connectinfo_start VARCHAR(50),
    connectinfo_stop VARCHAR(50),
    acctinputoctets BIGINT,
    acctoutputoctets BIGINT,
    calledstationid VARCHAR(50),
    callingstationid VARCHAR(50),
    acctterminatecause VARCHAR(32),
    servicetype VARCHAR(32),
    framedprotocol VARCHAR(32),
    framedipaddress INET
);

CREATE TABLE IF NOT EXISTS radcheck (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op CHAR(2) NOT NULL DEFAULT '==',
    value VARCHAR(253) NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS radreply (
    id SERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op CHAR(2) NOT NULL DEFAULT '=',
    value VARCHAR(253) NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS radgroupcheck (
    id SERIAL PRIMARY KEY,
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op CHAR(2) NOT NULL DEFAULT '==',
    value VARCHAR(253) NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS radgroupreply (
    id SERIAL PRIMARY KEY,
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op CHAR(2) NOT NULL DEFAULT '=',
    value VARCHAR(253) NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS radusergroup (
    username VARCHAR(64) NOT NULL DEFAULT '',
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    priority INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS radpostauth (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL DEFAULT '',
    pass VARCHAR(64) NOT NULL DEFAULT '',
    reply VARCHAR(32) NOT NULL DEFAULT '',
    authdate TIMESTAMP with time zone NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS nas (
    id SERIAL PRIMARY KEY,
    nasname VARCHAR(128) NOT NULL,
    shortname VARCHAR(32),
    type VARCHAR(30) DEFAULT 'other',
    ports INTEGER,
    secret VARCHAR(60) NOT NULL DEFAULT 'secret',
    server VARCHAR(64),
    community VARCHAR(50),
    description VARCHAR(200) DEFAULT 'RADIUS Client'
);

-- Create indexes
CREATE INDEX radacct_username_idx ON radacct USING btree (username);
CREATE INDEX radacct_session_idx ON radacct USING btree (acctsessionid);
CREATE INDEX radacct_unique_idx ON radacct USING btree (acctuniqueid);
CREATE INDEX radacct_start_idx ON radacct USING btree (acctstarttime);
CREATE INDEX radacct_stop_idx ON radacct USING btree (acctstoptime);
CREATE INDEX radacct_nas_idx ON radacct USING btree (nasipaddress);

CREATE INDEX radcheck_username_idx ON radcheck USING btree (username);
CREATE INDEX radreply_username_idx ON radreply USING btree (username);
CREATE INDEX radgroupcheck_groupname_idx ON radgroupcheck USING btree (groupname);
CREATE INDEX radgroupreply_groupname_idx ON radgroupreply USING btree (groupname);
CREATE INDEX radusergroup_username_idx ON radusergroup USING btree (username);
CREATE INDEX radusergroup_groupname_idx ON radusergroup USING btree (groupname);

CREATE UNIQUE INDEX radcheck_username_attribute_idx ON radcheck (username, attribute);
CREATE UNIQUE INDEX radgroupcheck_groupname_attribute_idx ON radgroupcheck (groupname, attribute);
CREATE UNIQUE INDEX radusergroup_username_groupname_idx ON radusergroup (username, groupname);
EOF
        
        if [ $? -eq 0 ]; then
            log "✅ Method 3 successful!"
        else
            error "All methods failed. Please check PostgreSQL permissions and try again."
            exit 1
        fi
    fi
fi

# Now add our custom tables
log "Adding ISP management tables..."
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

# Verify tables were created
log "Verifying database tables..."
TABLE_COUNT=$(sudo -u postgres psql radiusdb -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
log "Created $TABLE_COUNT tables in radiusdb"

# List the tables
log "Database tables:"
sudo -u postgres psql radiusdb -c "\dt"

log "✅ Schema import completed successfully!"
echo -e "\n${GREEN}Next steps:${NC}"
echo "1. Configure FreeRADIUS SQL module"
echo "2. Restart FreeRADIUS service"
echo "3. Test RADIUS authentication"

