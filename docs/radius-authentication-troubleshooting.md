# RADIUS Authentication Troubleshooting Guide

Complete guide to resolve RADIUS authentication issues and Access-Reject errors.

## 🚨 Common Issue: Access-Reject Error

If you see this error during installation:
```
(0) -: Expected Access-Accept got Access-Reject
```

This is a common RADIUS configuration issue that can be easily fixed.

## 🚀 Quick Fix

**One-Command Fix:**
```bash
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/scripts/fix_radius_auth.sh && chmod +x fix_radius_auth.sh && ./fix_radius_auth.sh
```

## 🔍 What Causes Access-Reject

### 1. SQL Module Configuration Issues
- Database connection problems
- Incorrect password or credentials
- Missing SQL module in authorize section

### 2. Missing or Invalid Test Users
- No users in radcheck table
- Incorrect password format
- Missing user-group assignments

### 3. Client Configuration Problems
- Shared secret mismatch
- Missing localhost client
- Incorrect client IP configuration

### 4. Database Permission Issues
- radiususer lacks proper permissions
- Database connection refused
- PostgreSQL not running

### 5. FreeRADIUS Configuration Errors
- Syntax errors in configuration files
- Missing or disabled modules
- Incorrect site configuration

## 🛠️ Manual Troubleshooting Steps

### Step 1: Check Database Connection
```bash
# Test database connectivity
sudo -u postgres psql radiusdb -c "SELECT COUNT(*) FROM radcheck;"

# Check if test users exist
sudo -u postgres psql radiusdb -c "SELECT username, attribute, value FROM radcheck;"
```

### Step 2: Verify FreeRADIUS Configuration
```bash
# Test configuration syntax
sudo freeradius -C

# Check if SQL module is enabled
ls -la /etc/freeradius/3.0/mods-enabled/sql
```

### Step 3: Check Service Status
```bash
# Check FreeRADIUS service
sudo systemctl status freeradius

# Check PostgreSQL service
sudo systemctl status postgresql

# View FreeRADIUS logs
sudo journalctl -u freeradius -f
```

### Step 4: Test Authentication
```bash
# Test with demo user
echo "User-Name = demo.customer, User-Password = demopass123" | radclient localhost:1812 auth testing123

# Test with test user
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123
```

### Step 5: Debug Mode
```bash
# Stop FreeRADIUS service
sudo systemctl stop freeradius

# Run in debug mode
sudo freeradius -X

# In another terminal, test authentication
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123

# Stop debug mode and restart service
sudo systemctl start freeradius
```

## 🔧 Manual Fix Procedures

### Fix 1: Recreate SQL Module Configuration
```bash
sudo tee /etc/freeradius/3.0/mods-enabled/sql > /dev/null << 'EOF'
sql {
    driver = "rlm_sql_postgresql"
    dialect = "postgresql"
    
    server = "localhost"
    port = 5432
    login = "radiususer"
    password = "YOUR_DB_PASSWORD"
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

### Fix 2: Create Test Users
```bash
sudo -u postgres psql radiusdb << 'EOF'
-- Delete existing test users
DELETE FROM radcheck WHERE username IN ('demo.customer', 'testuser');
DELETE FROM radusergroup WHERE username IN ('demo.customer', 'testuser');

-- Create test users
INSERT INTO radcheck (username, attribute, op, value) VALUES
('demo.customer', 'Cleartext-Password', ':=', 'demopass123'),
('testuser', 'Cleartext-Password', ':=', 'testpass');

-- Assign to groups
INSERT INTO radusergroup (username, groupname, priority) VALUES
('demo.customer', 'Standard', 1),
('testuser', 'Basic', 1);
EOF
```

### Fix 3: Configure Clients
```bash
sudo tee /etc/freeradius/3.0/clients.conf > /dev/null << 'EOF'
client localhost {
    ipaddr = 127.0.0.1
    secret = testing123
    require_message_authenticator = no
    nas_type = other
}

client localhost_ipv6 {
    ipv6addr = ::1
    secret = testing123
}

client private-network-1 {
    ipaddr = 192.168.0.0/16
    secret = testing123
}
EOF
```

### Fix 4: Update Default Site
```bash
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
        update {
            &reply: += &session-state:
        }
        sql
        exec
        remove_reply_message_if_eap
    }
}
EOF
```

## 📊 Verification Steps

### 1. Configuration Test
```bash
sudo freeradius -C
# Should show: Configuration appears to be OK
```

### 2. Service Status
```bash
sudo systemctl status freeradius
# Should show: active (running)
```

### 3. Authentication Test
```bash
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123
# Should show: Access-Accept
```

### 4. Database Verification
```bash
sudo -u postgres psql radiusdb -c "SELECT username FROM radcheck;"
# Should show: demo.customer, testuser
```

## 🚨 Common Error Messages and Solutions

### Error: "rlm_sql_postgresql: Connection failed"
**Solution:** Check database password and ensure PostgreSQL is running
```bash
sudo systemctl restart postgresql
sudo systemctl status postgresql
```

### Error: "Module sql not found"
**Solution:** Enable SQL module
```bash
sudo ln -sf /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled/
```

### Error: "User not found"
**Solution:** Create test users in database
```bash
sudo -u postgres psql radiusdb -c "INSERT INTO radcheck (username, attribute, op, value) VALUES ('testuser', 'Cleartext-Password', ':=', 'testpass');"
```

### Error: "Shared secret mismatch"
**Solution:** Update clients.conf with correct secret
```bash
sudo sed -i 's/secret = .*/secret = testing123/' /etc/freeradius/3.0/clients.conf
```

## 🎯 Expected Results After Fix

### Successful Authentication Test
```bash
$ echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123
Sent Access-Request Id 123 from 0.0.0.0:12345 to 127.0.0.1:1812 length 44
Received Access-Accept Id 123 from 127.0.0.1:1812 to 0.0.0.0:12345 length 32
```

### Service Status
```bash
$ sudo systemctl status freeradius
● freeradius.service - FreeRADIUS multi-protocol policy server
   Loaded: loaded (/lib/systemd/system/freeradius.service; enabled)
   Active: active (running)
```

### Database Connectivity
```bash
$ sudo -u postgres psql radiusdb -c "SELECT COUNT(*) FROM radcheck;"
 count 
-------
     2
```

## 📞 Additional Support

If you continue to experience issues after following this guide:

1. **Check Installation Logs:** `/var/log/isp-radius-install.log`
2. **View FreeRADIUS Logs:** `sudo journalctl -u freeradius -f`
3. **Run Debug Mode:** `sudo freeradius -X`
4. **Verify Database:** `sudo -u postgres psql radiusdb`

## 🔄 Complete Reset (Last Resort)

If all else fails, you can completely reset the RADIUS configuration:

```bash
# Stop services
sudo systemctl stop freeradius

# Remove configuration
sudo rm -rf /etc/freeradius/3.0/mods-enabled/sql
sudo rm -rf /etc/freeradius/3.0/sites-enabled/default

# Reinstall FreeRADIUS
sudo apt remove --purge freeradius freeradius-postgresql
sudo apt install freeradius freeradius-postgresql

# Run the fix script
./fix_radius_auth.sh
```

This comprehensive guide should resolve any RADIUS authentication issues you encounter during installation or operation of your ISP RADIUS & Billing Management System.

