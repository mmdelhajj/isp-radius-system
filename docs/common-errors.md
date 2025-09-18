# Common Installation Errors and Fixes

## 🚨 Most Common Installation Issues

### Error 1: Permission Denied on Directory Access

**Error Message:**
```
could not change directory to "/home/username": Permission denied
```

**Cause:** The installation script is running from a directory with restricted permissions.

**Solution:**
```bash
# Change to a directory with proper permissions
cd /tmp

# Or run the fix script
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/scripts/fix_current_installation.sh
chmod +x fix_current_installation.sh
./fix_current_installation.sh
```

### Error 2: Database Constraint Conflict

**Error Message:**
```
ERROR: there is no unique or exclusion constraint matching the ON CONFLICT specification
```

**Cause:** The `radgroupreply` table doesn't have the expected unique constraint for ON CONFLICT handling.

**Solution:**
```bash
# Fix the database constraint issue
sudo -u postgres psql radiusdb << 'EOF'
-- Remove existing entries if any
DELETE FROM radgroupreply WHERE groupname IN ('Student', 'Basic', 'Standard', 'Premium', 'Business');

-- Insert bandwidth control groups without ON CONFLICT
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

### Error 3: Sed Command Syntax Error

**Error Message:**
```
sed: -e expression #1, char 0: unmatched '{'
```

**Cause:** The sed command to modify FreeRADIUS configuration has syntax issues.

**Solution:**
```bash
# Instead of using sed, replace the entire configuration file
sudo tee /etc/freeradius/3.0/sites-enabled/default > /dev/null << 'EOF'
server default {
    listen {
        type = auth
        ipaddr = *
        port = 0
    }
    listen {
        ipaddr = *
        port = 0
        type = acct
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
```

### Error 4: FreeRADIUS Schema Import Permission Denied

**Error Message:**
```
/etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql: Permission denied
```

**Solution:**
```bash
# Fix file permissions and copy to accessible location
sudo chmod +r /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql
sudo cp /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql /tmp/schema.sql
sudo -u postgres psql radiusdb < /tmp/schema.sql
sudo rm /tmp/schema.sql
```

### Error 5: PostgreSQL Connection Failed

**Error Message:**
```
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed
```

**Solution:**
```bash
# Check and start PostgreSQL
sudo systemctl status postgresql
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify database exists
sudo -u postgres psql -l | grep radiusdb

# Create database if missing
sudo -u postgres createdb radiusdb
```

### Error 6: FreeRADIUS Won't Start

**Error Message:**
```
Job for freeradius.service failed because the control process exited with error code
```

**Solution:**
```bash
# Check configuration
sudo freeradius -C

# Run in debug mode to see errors
sudo systemctl stop freeradius
sudo freeradius -X

# Common fixes:
# 1. Check SQL module is properly configured
sudo ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/sql

# 2. Verify database password in SQL config
sudo nano /etc/freeradius/3.0/mods-enabled/sql
```

## 🔧 Complete Fix Script

For all the above issues, use the comprehensive fix script:

```bash
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/scripts/fix_current_installation.sh
chmod +x fix_current_installation.sh
./fix_current_installation.sh
```

## 🧪 Verification Commands

After applying fixes, verify your installation:

```bash
# Check service status
sudo systemctl status postgresql freeradius redis-server nginx

# Test database connection
sudo -u postgres psql radiusdb -c "SELECT COUNT(*) FROM service_profiles;"

# Test RADIUS authentication
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123

# Check listening ports
sudo netstat -tlnp | grep -E ':(80|1812|1813|5432|6379)'
```

## 📋 Expected Results

After successful fixes:
- All services should show "active (running)"
- Database should return "5" (number of service profiles)
- RADIUS test should return "Access-Accept"
- All required ports should be listening

## 🆘 If Issues Persist

If you continue to have problems:

1. **Check logs:**
   ```bash
   sudo tail -f /var/log/freeradius/radius.log
   sudo journalctl -u freeradius -f
   ```

2. **Run debug mode:**
   ```bash
   sudo systemctl stop freeradius
   sudo freeradius -X
   ```

3. **Verify database:**
   ```bash
   sudo -u postgres psql radiusdb -c "\dt"
   ```

4. **Check configuration:**
   ```bash
   sudo freeradius -C
   sudo nginx -t
   ```

Most installation issues can be resolved with the fix script, which handles all common error scenarios automatically.

