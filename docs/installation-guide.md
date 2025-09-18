# Ubuntu Server Installation Steps
## Complete ISP RADIUS & Billing Management System

## 🖥️ Server Requirements

### Minimum Requirements:
- **OS**: Ubuntu Server 22.04 LTS (fresh installation)
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 50GB SSD
- **Network**: Static IP address recommended

### Recommended Requirements:
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Storage**: 100GB+ SSD
- **Network**: 1Gbps connection with static IP

## 📋 Pre-Installation Checklist

- [ ] Ubuntu Server 22.04 LTS installed and updated
- [ ] Root or sudo access available
- [ ] Static IP address configured (recommended)
- [ ] Domain name pointing to your server (optional but recommended)
- [ ] SSH access configured
- [ ] Firewall disabled temporarily for installation

## 🚀 Installation Methods

### Method 1: Automated Installation (Recommended)

#### Step 1: Download Installation Script
```bash
# Connect to your server via SSH
ssh username@your-server-ip

# Download the installation script
wget https://raw.githubusercontent.com/your-repo/isp-radius/main/quick_install.sh

# Make it executable
chmod +x quick_install.sh

# Run the installation
./quick_install.sh
```

#### Step 2: Follow Installation Prompts
The script will ask for:
- Database password for RADIUS user
- Your domain name (optional)
- Email address for SSL certificate (optional)

### Method 2: Manual Step-by-Step Installation

#### Step 1: System Preparation
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git unzip software-properties-common ufw

# Reboot if kernel was updated
sudo reboot
```

#### Step 2: PostgreSQL Database Installation
```bash
# Install PostgreSQL 15
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Check PostgreSQL status
sudo systemctl status postgresql

# Set up database and user
sudo -u postgres psql
```

**In PostgreSQL prompt:**
```sql
-- Create database
CREATE DATABASE radiusdb;

-- Create user (replace 'your_password' with a strong password)
CREATE USER radiususer WITH PASSWORD 'your_secure_password_here';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE radiusdb TO radiususer;
ALTER USER radiususer CREATEDB;

-- Exit PostgreSQL
\q
```

#### Step 3: FreeRADIUS Installation
```bash
# Install FreeRADIUS with PostgreSQL support
sudo apt install -y freeradius freeradius-postgresql freeradius-utils

# Import RADIUS database schema
sudo -u postgres psql radiusdb < /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql

# Enable SQL module
sudo ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql

# Check FreeRADIUS status
sudo systemctl status freeradius
```

#### Step 4: Configure FreeRADIUS SQL Connection
```bash
# Edit SQL module configuration
sudo nano /etc/freeradius/3.0/mods-enabled/sql
```

**Update the SQL configuration:**
```bash
sql {
    driver = "rlm_sql_postgresql"
    dialect = "postgresql"
    
    # Connection info
    server = "localhost"
    port = 5432
    login = "radiususer"
    password = "your_secure_password_here"
    radius_db = "radiusdb"
    
    # Table names
    acct_table1 = "radacct"
    acct_table2 = "radacct"
    postauth_table = "radpostauth"
    authcheck_table = "radcheck"
    groupcheck_table = "radgroupcheck"
    authreply_table = "radreply"
    groupreply_table = "radgroupreply"
    usergroup_table = "radusergroup"
    
    # Enable group and profile reading
    read_groups = yes
    read_profiles = yes
    
    # Connection pool
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
```

#### Step 5: Enable SQL in RADIUS Authorization
```bash
# Edit the default site configuration
sudo nano /etc/freeradius/3.0/sites-enabled/default

# Find the "authorize {" section and add "sql" after "files"
# It should look like this:
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
    -ldap
    expiration
    logintime
    pap
}
```

#### Step 6: Redis Installation (for caching)
```bash
# Install Redis
sudo apt install -y redis-server

# Start and enable Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server

# Check Redis status
sudo systemctl status redis-server
```

#### Step 7: Node.js Installation (for web interface)
```bash
# Install Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

#### Step 8: Nginx Installation (web server)
```bash
# Install Nginx
sudo apt install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Check Nginx status
sudo systemctl status nginx
```

#### Step 9: Create Database Schema and Service Plans
```bash
# Connect to database
sudo -u postgres psql radiusdb
```

**Execute the following SQL:**
```sql
-- Create service profiles table
CREATE TABLE service_profiles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    download_speed INTEGER NOT NULL,
    upload_speed INTEGER NOT NULL,
    data_quota INTEGER,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create customers table
CREATE TABLE customers (
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

-- Create billing table
CREATE TABLE customer_billing (
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
('Business', 100, 20, NULL, 149.99, 'Unlimited business-grade service');

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
('Business', 'WISPr-Bandwidth-Max-Up', ':=', '20000000');

-- Exit PostgreSQL
\q
```

#### Step 10: Configure Firewall
```bash
# Enable UFW firewall
sudo ufw enable

# Allow SSH (important - don't lock yourself out!)
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow RADIUS ports
sudo ufw allow 1812/udp  # RADIUS Authentication
sudo ufw allow 1813/udp  # RADIUS Accounting

# Check firewall status
sudo ufw status
```

#### Step 11: Create Test User and Test System
```bash
# Add a test user to RADIUS
sudo -u postgres psql radiusdb << EOF
INSERT INTO radcheck (username, attribute, op, value) VALUES ('testuser', 'Cleartext-Password', ':=', 'testpass');
INSERT INTO radusergroup (username, groupname, priority) VALUES ('testuser', 'Standard', 1);
EOF

# Restart FreeRADIUS
sudo systemctl restart freeradius

# Test RADIUS authentication
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123
```

**Expected output:** `Access-Accept` (if successful)

#### Step 12: Create Simple Web Interface
```bash
# Create a simple status page
sudo tee /var/www/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>ISP RADIUS Management System</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        h1 { color: #2c3e50; text-align: center; }
        .status { padding: 15px; margin: 10px 0; border-radius: 5px; background: #d4edda; color: #155724; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 ISP RADIUS Management System</h1>
        <div class="status">
            <h3>✅ System Status: Online</h3>
            <p>Your ISP RADIUS & Billing Management System is running successfully!</p>
        </div>
    </div>
</body>
</html>
EOF
```

## 🔧 Post-Installation Configuration

### Step 1: Service Status Check
```bash
# Check all services are running
sudo systemctl status postgresql freeradius redis-server nginx

# Check listening ports
sudo netstat -tlnp | grep -E ':(80|1812|1813|5432|6379)'
```

### Step 2: Set Up SSL Certificate (Optional but Recommended)
```bash
# Install Certbot for Let's Encrypt SSL
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate (replace with your domain)
sudo certbot --nginx -d yourdomain.com

# Set up auto-renewal
sudo crontab -e
# Add this line:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

### Step 3: Create Backup System
```bash
# Create backup directory
sudo mkdir -p /opt/isp-radius/backups

# Create backup script
sudo tee /opt/isp-radius/backup.sh > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/isp-radius/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p $BACKUP_DIR

# Database backup
sudo -u postgres pg_dump radiusdb > $BACKUP_DIR/radiusdb_$DATE.sql

# Configuration backup
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /etc/freeradius /etc/nginx/sites-available

# Keep only last 30 days
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
EOF

# Make executable
sudo chmod +x /opt/isp-radius/backup.sh

# Add to crontab for daily backups
sudo crontab -e
# Add this line:
# 0 2 * * * /opt/isp-radius/backup.sh
```

## ✅ Installation Verification

### Step 1: Service Verification
```bash
# Check PostgreSQL
sudo -u postgres psql radiusdb -c "SELECT COUNT(*) FROM service_profiles;"

# Check FreeRADIUS
sudo systemctl status freeradius
sudo freeradius -X  # Debug mode (Ctrl+C to exit)

# Check Redis
redis-cli ping

# Check Nginx
curl -I http://localhost
```

### Step 2: RADIUS Authentication Test
```bash
# Test with the test user
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123

# Expected output: Access-Accept
```

### Step 3: Database Connection Test
```bash
# Test database connectivity
sudo -u postgres psql radiusdb -c "\dt"  # List tables
sudo -u postgres psql radiusdb -c "SELECT * FROM service_profiles;"  # Show service plans
```

## 🚨 Troubleshooting Common Issues

### Issue 1: FreeRADIUS Won't Start
```bash
# Check configuration
sudo freeradius -X

# Check SQL module
sudo freeradius -C

# Check logs
sudo tail -f /var/log/freeradius/radius.log
```

### Issue 2: Database Connection Failed
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Test database connection
sudo -u postgres psql radiusdb

# Check user permissions
sudo -u postgres psql -c "\du"
```

### Issue 3: Web Interface Not Accessible
```bash
# Check Nginx status
sudo systemctl status nginx

# Check Nginx configuration
sudo nginx -t

# Check firewall
sudo ufw status
```

### Issue 4: RADIUS Authentication Fails
```bash
# Check RADIUS logs
sudo tail -f /var/log/freeradius/radius.log

# Test in debug mode
sudo systemctl stop freeradius
sudo freeradius -X
# Try authentication in another terminal
```

## 📊 System Monitoring Commands

### Daily Health Checks:
```bash
# Service status
sudo systemctl status postgresql freeradius redis-server nginx

# Disk usage
df -h

# Memory usage
free -h

# RADIUS logs
sudo tail -20 /var/log/freeradius/radius.log

# Database size
sudo -u postgres psql radiusdb -c "SELECT pg_size_pretty(pg_database_size('radiusdb'));"
```

## 🎯 Next Steps After Installation

1. **Configure Network Equipment**: Add your routers as RADIUS clients
2. **Deploy Web Interface**: Upload your React application
3. **Create Customer Accounts**: Start adding real customers
4. **Set Up Monitoring**: Configure alerts and monitoring
5. **Configure Billing**: Set up payment processing

## 📋 Installation Checklist

- [ ] Ubuntu Server 22.04 LTS installed
- [ ] PostgreSQL database running
- [ ] FreeRADIUS server configured and running
- [ ] Redis cache server running
- [ ] Nginx web server running
- [ ] Database schema created
- [ ] Service profiles configured
- [ ] Firewall configured
- [ ] Test user authentication working
- [ ] Backup system configured
- [ ] SSL certificate installed (optional)
- [ ] Web interface accessible

## 🔐 Security Recommendations

1. **Change Default Passwords**: Update all default passwords
2. **Enable Firewall**: Configure UFW with minimal required ports
3. **SSL Certificate**: Install SSL for web interface
4. **Regular Updates**: Keep system packages updated
5. **Backup Strategy**: Implement regular automated backups
6. **Monitor Logs**: Set up log monitoring and alerts
7. **Access Control**: Limit SSH access and use key-based authentication

Your ISP RADIUS & Billing Management System is now ready for production use!

