# Quick Installation Commands - Copy & Paste
## ISP RADIUS System on Ubuntu Server 22.04

## 🚀 Method 1: One-Command Installation

```bash
# Download and run automated installer
wget https://raw.githubusercontent.com/your-repo/isp-radius/main/quick_install.sh && chmod +x quick_install.sh && ./quick_install.sh
```

## 🔧 Method 2: Manual Commands (Step by Step)

### System Update
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git unzip software-properties-common ufw
```

### PostgreSQL Installation
```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Database Setup
```bash
sudo -u postgres psql << 'EOF'
CREATE DATABASE radiusdb;
CREATE USER radiususer WITH PASSWORD 'YourSecurePassword123!';
GRANT ALL PRIVILEGES ON DATABASE radiusdb TO radiususer;
ALTER USER radiususer CREATEDB;
\q
EOF
```

### FreeRADIUS Installation
```bash
sudo apt install -y freeradius freeradius-postgresql freeradius-utils
sudo -u postgres psql radiusdb < /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql
sudo ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql
```

### FreeRADIUS SQL Configuration
```bash
sudo tee /etc/freeradius/3.0/mods-enabled/sql > /dev/null << 'EOF'
sql {
    driver = "rlm_sql_postgresql"
    dialect = "postgresql"
    server = "localhost"
    port = 5432
    login = "radiususer"
    password = "YourSecurePassword123!"
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
```

### Enable SQL in RADIUS
```bash
sudo sed -i '/authorize {/,/}/ { /files/ a\\tsql' /etc/freeradius/3.0/sites-enabled/default
```

### Redis Installation
```bash
sudo apt install -y redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

### Node.js Installation
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### Nginx Installation
```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Database Schema Creation
```bash
sudo -u postgres psql radiusdb << 'EOF'
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

INSERT INTO service_profiles (name, download_speed, upload_speed, data_quota, price, description) VALUES
('Student', 15, 3, 75, 19.99, 'Perfect for students and light users'),
('Basic', 10, 2, 50, 29.99, 'Essential internet for everyday use'),
('Standard', 25, 5, 150, 49.99, 'Great for families and streaming'),
('Premium', 50, 10, 300, 79.99, 'High-speed for power users'),
('Business', 100, 20, NULL, 149.99, 'Unlimited business-grade service');

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
```

### Firewall Configuration
```bash
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 1812/udp
sudo ufw allow 1813/udp
```

### Create Test User
```bash
sudo -u postgres psql radiusdb << 'EOF'
INSERT INTO radcheck (username, attribute, op, value) VALUES ('testuser', 'Cleartext-Password', ':=', 'testpass');
INSERT INTO radusergroup (username, groupname, priority) VALUES ('testuser', 'Standard', 1);
EOF
```

### Restart Services
```bash
sudo systemctl restart postgresql freeradius redis-server nginx
```

### Create Web Interface
```bash
sudo tee /var/www/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>ISP RADIUS Management System</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; text-align: center; }
        .status { padding: 15px; margin: 10px 0; border-radius: 5px; background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .command { background: #f8f9fa; padding: 10px; border-radius: 5px; font-family: monospace; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 ISP RADIUS Management System</h1>
        <div class="status">
            <h3>✅ Installation Complete!</h3>
            <p>Your ISP RADIUS & Billing Management System is now running.</p>
        </div>
        <div class="status">
            <h3>🔧 Test Commands</h3>
            <div class="command">echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123</div>
            <div class="command">sudo systemctl status postgresql freeradius redis-server nginx</div>
        </div>
    </div>
</body>
</html>
EOF
```

### Setup Backup System
```bash
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
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/isp-radius/backup.sh") | crontab -
```

### SSL Certificate (Optional)
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

## 🧪 Testing Commands

### Test RADIUS Authentication
```bash
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123
```

### Check Service Status
```bash
sudo systemctl status postgresql freeradius redis-server nginx
```

### Check Database
```bash
sudo -u postgres psql radiusdb -c "SELECT * FROM service_profiles;"
```

### Check Ports
```bash
sudo netstat -tlnp | grep -E ':(80|1812|1813|5432|6379)'
```

### View Logs
```bash
sudo tail -f /var/log/freeradius/radius.log
```

## 🚨 Troubleshooting Commands

### RADIUS Debug Mode
```bash
sudo systemctl stop freeradius
sudo freeradius -X
```

### Check Configuration
```bash
sudo freeradius -C
sudo nginx -t
```

### Database Connection Test
```bash
sudo -u postgres psql radiusdb -c "\dt"
```

## ✅ Verification Checklist

Run these commands to verify installation:

```bash
# 1. Check all services are running
sudo systemctl status postgresql freeradius redis-server nginx

# 2. Test RADIUS authentication
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123

# 3. Check database connection
sudo -u postgres psql radiusdb -c "SELECT COUNT(*) FROM service_profiles;"

# 4. Check web interface
curl -I http://localhost

# 5. Check firewall
sudo ufw status

# 6. Check listening ports
sudo netstat -tlnp | grep -E ':(80|1812|1813|5432|6379)'
```

**Expected Results:**
- All services should show "active (running)"
- RADIUS test should return "Access-Accept"
- Database should return "5" (number of service profiles)
- Web interface should return "200 OK"
- Firewall should show configured rules
- All required ports should be listening

Your ISP RADIUS system is now ready for production use!

