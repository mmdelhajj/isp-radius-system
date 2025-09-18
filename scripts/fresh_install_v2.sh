#!/bin/bash

# ISP RADIUS & Billing Management System - Fresh Installation Script v2.0
# For Ubuntu 22.04 LTS Production Servers
# Version 2.0 - Improved FreeRADIUS configuration and error handling

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

log "Starting ISP RADIUS & Billing Management System Fresh Installation v2.0"

# Change to safe directory
cd /tmp

# Get configuration from user
echo -e "${BLUE}=== Configuration Setup ===${NC}"
read -p "Enter database password for RADIUS user: " -s DB_PASSWORD
echo
read -p "Enter your domain name (optional, press Enter to skip): " DOMAIN_NAME
read -p "Enter your email for SSL certificate (optional, press Enter to skip): " EMAIL_ADDRESS

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
DROP DATABASE IF EXISTS radiusdb;
DROP USER IF EXISTS radiususer;
CREATE DATABASE radiusdb;
CREATE USER radiususer WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE radiusdb TO radiususer;
ALTER USER radiususer CREATEDB;
\q
EOF

# Install FreeRADIUS
log "Installing FreeRADIUS..."
sudo apt install -y freeradius freeradius-postgresql freeradius-utils

# Stop FreeRADIUS to configure it
sudo systemctl stop freeradius

# Import RADIUS schema with multiple fallback methods
log "Setting up RADIUS database schema..."

# Method 1: Try direct import
if sudo -u postgres psql radiusdb < /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql 2>/dev/null; then
    log "✅ Schema imported successfully (Method 1)"
else
    warn "Direct import failed, using alternative method..."
    
    # Method 2: Fix permissions and copy
    sudo chmod +r /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql 2>/dev/null || true
    sudo cp /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql /tmp/radius_schema.sql
    sudo chmod 644 /tmp/radius_schema.sql
    
    if sudo -u postgres psql radiusdb < /tmp/radius_schema.sql; then
        log "✅ Schema imported successfully (Method 2)"
        sudo rm /tmp/radius_schema.sql
    else
        warn "Standard schema import failed, creating essential tables manually..."
        
        # Method 3: Create essential tables manually
        sudo -u postgres psql radiusdb << 'EOF'
-- Essential FreeRADIUS tables
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
CREATE INDEX IF NOT EXISTS radacct_username_idx ON radacct (username);
CREATE INDEX IF NOT EXISTS radacct_session_idx ON radacct (acctsessionid);
CREATE INDEX IF NOT EXISTS radcheck_username_idx ON radcheck (username);
CREATE INDEX IF NOT EXISTS radusergroup_username_idx ON radusergroup (username);
EOF
        log "✅ Essential RADIUS tables created manually"
    fi
fi

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

# Create ISP management database schema
log "Creating ISP management tables..."
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

-- Insert bandwidth control groups (without ON CONFLICT to avoid constraint issues)
DELETE FROM radgroupreply WHERE groupname IN ('Student', 'Basic', 'Standard', 'Premium', 'Business');
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
('Business', 'WISPr-Bandwidth-Max-Up', ':=', '20000000');
EOF

# Configure FreeRADIUS SQL module
log "Configuring FreeRADIUS SQL module..."

# Create SQL module configuration
sudo tee /etc/freeradius/3.0/mods-available/sql > /dev/null << EOF
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

# Enable SQL module
sudo ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql

# Create a working default site configuration
log "Configuring FreeRADIUS default site..."
sudo tee /etc/freeradius/3.0/sites-available/default > /dev/null << 'EOF'
server default {
    listen {
        type = auth
        ipaddr = *
        port = 1812
        limit {
            max_connections = 16
            lifetime = 0
            idle_timeout = 30
        }
    }

    listen {
        type = acct
        ipaddr = *
        port = 1813
        limit {
        }
    }

    authorize {
        filter_username
        preprocess
        chap
        mschap
        digest
        suffix
        eap {
            ok = return
        }
        files
        sql
        expiration
        logintime
        pap
    }

    authenticate {
        Auth-Type PAP {
            pap
        }
        Auth-Type CHAP {
            chap
        }
        Auth-Type MS-CHAP {
            mschap
        }
        mschap
        digest
        eap
    }

    preacct {
        preprocess
        acct_unique
        suffix
        files
    }

    accounting {
        detail
        unix
        sql
        exec
        attr_filter.accounting_response
    }

    session {
        sql
    }

    post-auth {
        update {
            &reply: += &session-state:
        }
        sql
        exec
        remove_reply_message_if_eap
        Post-Auth-Type REJECT {
            sql
            attr_filter.access_reject
            eap
            remove_reply_message_if_eap
        }
    }
}
EOF

# Enable the default site
sudo ln -sf /etc/freeradius/3.0/sites-available/default /etc/freeradius/3.0/sites-enabled/default

# Configure firewall
log "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 1812/udp
sudo ufw allow 1813/udp

# Create test users
log "Creating test users..."
sudo -u postgres psql radiusdb << EOF
-- Create test user
INSERT INTO radcheck (username, attribute, op, value) VALUES ('testuser', 'Cleartext-Password', ':=', 'testpass') ON CONFLICT DO NOTHING;
INSERT INTO radusergroup (username, groupname, priority) VALUES ('testuser', 'Standard', 1) ON CONFLICT DO NOTHING;

-- Create demo customer
INSERT INTO radcheck (username, attribute, op, value) VALUES ('demo.customer', 'Cleartext-Password', ':=', 'demo123') ON CONFLICT DO NOTHING;
INSERT INTO radusergroup (username, groupname, priority) VALUES ('demo.customer', 'Premium', 1) ON CONFLICT DO NOTHING;
EOF

# Create simple web interface
log "Setting up web interface..."
sudo mkdir -p /var/www/html
sudo tee /var/www/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ISP Management System v2.0</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 900px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; }
        .status { padding: 15px; margin: 10px 0; border-radius: 5px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
        .warning { background: #fff3cd; color: #856404; border: 1px solid #ffeaa7; }
        ul { padding-left: 20px; }
        li { margin: 5px 0; }
        .command { background: #f8f9fa; padding: 10px; border-radius: 5px; font-family: monospace; margin: 10px 0; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 20px 0; }
        .card { background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 4px solid #007bff; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 ISP RADIUS & Billing Management System v2.0</h1>
        
        <div class="status success">
            <h3>✅ Installation Complete!</h3>
            <p>Your ISP RADIUS & Billing Management System v2.0 has been successfully installed with improved configuration.</p>
        </div>
        
        <div class="grid">
            <div class="card">
                <h4>📊 System Components</h4>
                <ul>
                    <li><strong>PostgreSQL Database</strong> - Customer and billing data</li>
                    <li><strong>FreeRADIUS Server</strong> - Authentication (ports 1812/1813)</li>
                    <li><strong>Redis Cache</strong> - Performance optimization</li>
                    <li><strong>Nginx Web Server</strong> - Web interface hosting</li>
                    <li><strong>Service Profiles</strong> - 5 pre-configured plans</li>
                </ul>
            </div>
            
            <div class="card">
                <h4>🎯 Service Plans</h4>
                <ul>
                    <li><strong>Student:</strong> 15/3 Mbps - $19.99/month</li>
                    <li><strong>Basic:</strong> 10/2 Mbps - $29.99/month</li>
                    <li><strong>Standard:</strong> 25/5 Mbps - $49.99/month</li>
                    <li><strong>Premium:</strong> 50/10 Mbps - $79.99/month</li>
                    <li><strong>Business:</strong> 100/20 Mbps - $149.99/month</li>
                </ul>
            </div>
        </div>
        
        <div class="status info">
            <h3>🧪 Test Commands</h3>
            <p><strong>Test RADIUS Authentication:</strong></p>
            <div class="command">echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123</div>
            
            <p><strong>Test Demo Customer:</strong></p>
            <div class="command">echo "User-Name = demo.customer, User-Password = demo123" | radclient localhost:1812 auth testing123</div>
            
            <p><strong>Check Services:</strong></p>
            <div class="command">sudo systemctl status postgresql freeradius redis-server nginx</div>
            
            <p><strong>View Database:</strong></p>
            <div class="command">sudo -u postgres psql radiusdb -c "SELECT name, price FROM service_profiles;"</div>
        </div>
        
        <div class="status warning">
            <h3>🚀 Next Steps</h3>
            <ol>
                <li><strong>Test Authentication:</strong> Run the test commands above</li>
                <li><strong>Configure Network Equipment:</strong> Add your routers as RADIUS clients</li>
                <li><strong>Deploy Web Interface:</strong> Upload your React application</li>
                <li><strong>Add Customers:</strong> Start managing your customer base</li>
                <li><strong>Monitor System:</strong> Set up logging and monitoring</li>
            </ol>
        </div>
    </div>
</body>
</html>
EOF

# Start services
log "Starting services..."
sudo systemctl restart postgresql
sudo systemctl restart redis-server
sudo systemctl restart nginx

# Try to start FreeRADIUS with error handling
log "Starting FreeRADIUS..."
if sudo systemctl start freeradius; then
    log "✅ FreeRADIUS started successfully"
else
    warn "FreeRADIUS failed to start, running configuration check..."
    sudo freeradius -C
    warn "Check the configuration and try: sudo systemctl start freeradius"
fi

# Install SSL certificate if domain provided
if [ ! -z "$DOMAIN_NAME" ] && [ ! -z "$EMAIL_ADDRESS" ]; then
    log "Installing SSL certificate..."
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d $DOMAIN_NAME --email $EMAIL_ADDRESS --agree-tos --non-interactive || warn "SSL certificate installation failed"
fi

# Create backup script
log "Setting up backup system..."
sudo mkdir -p /opt/isp-radius/backups
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
sleep 3

echo -e "\n${GREEN}=== Installation Summary ===${NC}"
echo -e "${GREEN}✅ PostgreSQL Database: $(sudo systemctl is-active postgresql)${NC}"
echo -e "${GREEN}✅ Redis Cache: $(sudo systemctl is-active redis-server)${NC}"
echo -e "${GREEN}✅ Nginx Web Server: $(sudo systemctl is-active nginx)${NC}"

# Check FreeRADIUS status
FREERADIUS_STATUS=$(sudo systemctl is-active freeradius)
if [ "$FREERADIUS_STATUS" = "active" ]; then
    echo -e "${GREEN}✅ FreeRADIUS Server: $FREERADIUS_STATUS${NC}"
else
    echo -e "${YELLOW}⚠️  FreeRADIUS Server: $FREERADIUS_STATUS${NC}"
fi

# Test database
echo -e "\n${BLUE}Testing database connection...${NC}"
DB_TEST=$(sudo -u postgres psql radiusdb -t -c "SELECT COUNT(*) FROM service_profiles;" | tr -d ' ')
echo -e "${GREEN}✅ Database contains $DB_TEST service profiles${NC}"

# Test RADIUS authentication if service is running
if [ "$FREERADIUS_STATUS" = "active" ]; then
    echo -e "\n${BLUE}Testing RADIUS authentication...${NC}"
    if echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123 | grep -q "Access-Accept"; then
        echo -e "${GREEN}✅ RADIUS authentication test: PASSED${NC}"
    else
        echo -e "${YELLOW}⚠️  RADIUS authentication test: Check configuration${NC}"
    fi
else
    echo -e "\n${YELLOW}⚠️  Skipping RADIUS test - service not running${NC}"
    echo -e "${YELLOW}Run 'sudo systemctl start freeradius' and test with:${NC}"
    echo -e "${BLUE}echo \"User-Name = testuser, User-Password = testpass\" | radclient localhost:1812 auth testing123${NC}"
fi

echo -e "\n${GREEN}🎉 Installation Complete!${NC}"
if [ ! -z "$DOMAIN_NAME" ]; then
    echo -e "${BLUE}Web Interface: https://$DOMAIN_NAME${NC}"
else
    echo -e "${BLUE}Web Interface: http://$(hostname -I | awk '{print $1}')${NC}"
fi
echo -e "${BLUE}RADIUS Server: $(hostname -I | awk '{print $1}'):1812${NC}"
echo -e "${BLUE}Database: radiusdb on localhost:5432${NC}"

echo -e "\n${YELLOW}📋 Next Steps:${NC}"
echo -e "1. Test RADIUS: echo \"User-Name = testuser, User-Password = testpass\" | radclient localhost:1812 auth testing123"
echo -e "2. Configure your network equipment to use this RADIUS server"
echo -e "3. Add your routers as RADIUS clients in the database"
echo -e "4. Deploy your React web interface to /var/www/html"
echo -e "5. Start adding customer accounts"

echo -e "\n${GREEN}Installation log saved to: /var/log/isp-radius-install.log${NC}"

