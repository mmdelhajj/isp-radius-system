# ISP RADIUS Installation Troubleshooting Guide

## 🚨 Common Installation Issues and Solutions

### Issue 1: Permission Denied on Schema Import

**Error**: `./quick_install.sh: line 80: /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql: Permission denied`

#### Solution A: Run the Fix Script (Recommended)
```bash
# Download and run the fix script
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/fix_installation.sh
chmod +x fix_installation.sh
./fix_installation.sh
```

#### Solution B: Manual Fix
```bash
# Fix file permissions
sudo chmod +r /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql

# Copy to accessible location
sudo cp /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql /tmp/schema.sql

# Import schema
sudo -u postgres psql radiusdb < /tmp/schema.sql

# Clean up
sudo rm /tmp/schema.sql
```

#### Solution C: Manual Schema Creation
```bash
# Run the manual schema import script
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/manual_schema_import.sh
chmod +x manual_schema_import.sh
./manual_schema_import.sh
```

### Issue 2: PostgreSQL Connection Failed

**Error**: `psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed`

#### Solution:
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Start PostgreSQL if not running
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Check if database exists
sudo -u postgres psql -l | grep radiusdb

# Create database if missing
sudo -u postgres createdb radiusdb
sudo -u postgres psql -c "CREATE USER radiususer WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE radiusdb TO radiususer;"
```

### Issue 3: FreeRADIUS Won't Start

**Error**: `Job for freeradius.service failed because the control process exited with error code`

#### Solution:
```bash
# Check FreeRADIUS configuration
sudo freeradius -C

# Run in debug mode to see errors
sudo systemctl stop freeradius
sudo freeradius -X

# Common fixes:
# 1. Check SQL module configuration
sudo nano /etc/freeradius/3.0/mods-enabled/sql

# 2. Verify database password
sudo -u postgres psql radiusdb -c "SELECT 1;"

# 3. Check if SQL module is properly linked
sudo ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql
```

### Issue 4: RADIUS Authentication Fails

**Error**: `Access-Reject` when testing authentication

#### Solution:
```bash
# Check if test user exists
sudo -u postgres psql radiusdb -c "SELECT * FROM radcheck WHERE username = 'testuser';"

# Add test user if missing
sudo -u postgres psql radiusdb << EOF
INSERT INTO radcheck (username, attribute, op, value) VALUES ('testuser', 'Cleartext-Password', ':=', 'testpass');
INSERT INTO radusergroup (username, groupname, priority) VALUES ('testuser', 'Standard', 1);
EOF

# Test authentication
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123

# Check RADIUS logs
sudo tail -f /var/log/freeradius/radius.log
```

### Issue 5: Web Interface Not Loading

**Error**: `Connection refused` or `502 Bad Gateway`

#### Solution:
```bash
# Check Nginx status
sudo systemctl status nginx

# Check if port 80 is listening
sudo netstat -tlnp | grep :80

# Restart Nginx
sudo systemctl restart nginx

# Check Nginx configuration
sudo nginx -t

# Check firewall
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

## 🔧 Step-by-Step Recovery Process

### Complete System Recovery

If your installation is completely broken, follow these steps:

#### Step 1: Clean Installation
```bash
# Stop all services
sudo systemctl stop freeradius nginx redis-server

# Remove existing installation
sudo apt remove --purge freeradius freeradius-postgresql
sudo rm -rf /etc/freeradius

# Drop and recreate database
sudo -u postgres dropdb radiusdb
sudo -u postgres createdb radiusdb
```

#### Step 2: Fresh Installation
```bash
# Download fresh installer
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/scripts/quick_install.sh
chmod +x quick_install.sh

# Run with verbose output
bash -x ./quick_install.sh
```

#### Step 3: Manual Configuration
```bash
# If automated installation fails, configure manually:

# 1. Install packages
sudo apt install -y freeradius freeradius-postgresql postgresql redis-server nginx

# 2. Create database
sudo -u postgres createdb radiusdb
sudo -u postgres psql -c "CREATE USER radiususer WITH PASSWORD 'your_password';"

# 3. Import schema manually
./manual_schema_import.sh

# 4. Configure FreeRADIUS
sudo cp /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/
# Edit SQL configuration with your database password

# 5. Start services
sudo systemctl start postgresql freeradius redis-server nginx
```

## 🧪 Testing Commands

### Database Testing
```bash
# Test PostgreSQL connection
sudo -u postgres psql radiusdb -c "SELECT version();"

# Check tables exist
sudo -u postgres psql radiusdb -c "\dt"

# Verify service profiles
sudo -u postgres psql radiusdb -c "SELECT * FROM service_profiles;"

# Check RADIUS tables
sudo -u postgres psql radiusdb -c "SELECT COUNT(*) FROM radcheck;"
```

### RADIUS Testing
```bash
# Test RADIUS server
radtest testuser testpass localhost 1812 testing123

# Alternative test
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123

# Check RADIUS status
sudo systemctl status freeradius

# View RADIUS logs
sudo tail -20 /var/log/freeradius/radius.log
```

### Service Testing
```bash
# Check all services
sudo systemctl status postgresql freeradius redis-server nginx

# Check listening ports
sudo netstat -tlnp | grep -E ':(80|1812|1813|5432|6379)'

# Test web interface
curl -I http://localhost
```

## 🔍 Log File Locations

### Important Log Files
```bash
# FreeRADIUS logs
sudo tail -f /var/log/freeradius/radius.log

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-14-main.log

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# System logs
sudo journalctl -u freeradius -f
sudo journalctl -u postgresql -f
```

## 🚀 Quick Recovery Commands

### One-Line Fixes
```bash
# Fix schema permissions
sudo chmod +r /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql && sudo -u postgres psql radiusdb < /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql

# Restart all services
sudo systemctl restart postgresql freeradius redis-server nginx

# Create test user
sudo -u postgres psql radiusdb -c "INSERT INTO radcheck (username, attribute, op, value) VALUES ('testuser', 'Cleartext-Password', ':=', 'testpass') ON CONFLICT DO NOTHING;"

# Test authentication
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123
```

## 📞 Getting Help

### Debug Information to Collect
When asking for help, provide:

1. **System Information**:
   ```bash
   lsb_release -a
   uname -a
   free -h
   df -h
   ```

2. **Service Status**:
   ```bash
   sudo systemctl status postgresql freeradius redis-server nginx
   ```

3. **Log Excerpts**:
   ```bash
   sudo tail -50 /var/log/freeradius/radius.log
   sudo journalctl -u freeradius --no-pager -n 50
   ```

4. **Configuration Check**:
   ```bash
   sudo freeradius -C
   sudo nginx -t
   ```

### Common Solutions Summary

| Issue | Quick Fix |
|-------|-----------|
| Permission denied | `sudo chmod +r /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql` |
| PostgreSQL not running | `sudo systemctl start postgresql` |
| FreeRADIUS config error | `sudo freeradius -C` to check config |
| Authentication fails | Check user exists in `radcheck` table |
| Web interface down | `sudo systemctl restart nginx` |
| Port not listening | Check firewall: `sudo ufw allow 80/tcp` |

Most installation issues can be resolved by running the fix script or manually importing the database schema. The system is designed to be robust and recoverable.

