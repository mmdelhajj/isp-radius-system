#!/bin/bash

# Fix RADIUS Authentication Issues
# This script resolves common RADIUS Access-Reject problems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log "Starting RADIUS Authentication Fix..."

# Get database password
read -p "Enter your database password: " -s DB_PASSWORD
echo

# Stop FreeRADIUS to make changes
log "Stopping FreeRADIUS service..."
sudo systemctl stop freeradius

# Fix 1: Ensure SQL module is properly configured
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

# Fix 2: Configure proper default site
log "Configuring FreeRADIUS default site..."
sudo tee /etc/freeradius/3.0/sites-enabled/default > /dev/null << 'EOF'
server default {
    listen {
        type = auth
        ipaddr = *
        port = 0
        limit {
            max_connections = 16
            lifetime = 0
            idle_timeout = 30
        }
    }
    
    listen {
        ipaddr = *
        port = 0
        type = acct
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
    }
    
    pre-proxy {
    }
    
    post-proxy {
        eap
    }
}
EOF

# Fix 3: Ensure clients.conf has proper configuration
log "Configuring RADIUS clients..."
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

client private-network-2 {
    ipaddr = 10.0.0.0/8
    secret = testing123
}

client private-network-3 {
    ipaddr = 172.16.0.0/12
    secret = testing123
}
EOF

# Fix 4: Ensure database has proper test user
log "Creating/updating test users in database..."
sudo -u postgres psql radiusdb << EOF
-- Delete existing test users
DELETE FROM radcheck WHERE username IN ('demo.customer', 'testuser');
DELETE FROM radusergroup WHERE username IN ('demo.customer', 'testuser');

-- Create test users with proper attributes
INSERT INTO radcheck (username, attribute, op, value) VALUES
('demo.customer', 'Cleartext-Password', ':=', 'demopass123'),
('testuser', 'Cleartext-Password', ':=', 'testpass');

-- Assign to groups
INSERT INTO radusergroup (username, groupname, priority) VALUES
('demo.customer', 'Standard', 1),
('testuser', 'Basic', 1);

-- Verify data
SELECT 'Users in radcheck:' as info;
SELECT username, attribute, value FROM radcheck WHERE username IN ('demo.customer', 'testuser');

SELECT 'Users in radusergroup:' as info;
SELECT username, groupname FROM radusergroup WHERE username IN ('demo.customer', 'testuser');
EOF

# Fix 5: Test FreeRADIUS configuration
log "Testing FreeRADIUS configuration..."
sudo freeradius -C
if [ $? -ne 0 ]; then
    error "FreeRADIUS configuration test failed!"
    exit 1
fi

# Fix 6: Start FreeRADIUS service
log "Starting FreeRADIUS service..."
sudo systemctl start freeradius
sudo systemctl enable freeradius

# Wait for service to start
sleep 3

# Fix 7: Test authentication
log "Testing RADIUS authentication..."

echo "Testing demo.customer..."
RESULT1=$(echo "User-Name = demo.customer, User-Password = demopass123" | radclient localhost:1812 auth testing123 2>/dev/null)
if echo "$RESULT1" | grep -q "Access-Accept"; then
    log "✅ demo.customer authentication: SUCCESS"
else
    warning "❌ demo.customer authentication: FAILED"
    echo "Result: $RESULT1"
fi

echo "Testing testuser..."
RESULT2=$(echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123 2>/dev/null)
if echo "$RESULT2" | grep -q "Access-Accept"; then
    log "✅ testuser authentication: SUCCESS"
else
    warning "❌ testuser authentication: FAILED"
    echo "Result: $RESULT2"
fi

# Fix 8: Check service status
log "Checking service status..."
sudo systemctl status freeradius --no-pager -l

# Fix 9: Show debug information if still failing
if ! echo "$RESULT1" | grep -q "Access-Accept" || ! echo "$RESULT2" | grep -q "Access-Accept"; then
    warning "Authentication still failing. Running debug mode..."
    echo "Starting FreeRADIUS in debug mode for 10 seconds..."
    sudo systemctl stop freeradius
    timeout 10s sudo freeradius -X &
    sleep 2
    echo "Testing authentication in debug mode..."
    echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123
    sleep 3
    sudo pkill -f freeradius
    sudo systemctl start freeradius
fi

log "RADIUS authentication fix completed!"
log "If authentication is still failing, check the debug output above for specific errors."

# Summary
echo
echo "=================================================================="
echo -e "${GREEN}🔧 RADIUS AUTHENTICATION FIX SUMMARY${NC}"
echo "=================================================================="
echo -e "${BLUE}✅ SQL module configured${NC}"
echo -e "${BLUE}✅ Default site configured${NC}"
echo -e "${BLUE}✅ Clients configuration updated${NC}"
echo -e "${BLUE}✅ Test users created in database${NC}"
echo -e "${BLUE}✅ FreeRADIUS service restarted${NC}"
echo
echo -e "${BLUE}🧪 Test Commands:${NC}"
echo "echo \"User-Name = demo.customer, User-Password = demopass123\" | radclient localhost:1812 auth testing123"
echo "echo \"User-Name = testuser, User-Password = testpass\" | radclient localhost:1812 auth testing123"
echo
echo -e "${BLUE}🔍 Debug Command:${NC}"
echo "sudo freeradius -X"
echo "=================================================================="

