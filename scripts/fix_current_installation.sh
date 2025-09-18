#!/bin/bash

# Fix for Current Installation Issues
# Addresses the specific errors encountered during installation

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
}

log "Fixing current installation issues..."

# Get database password
read -p "Enter the database password you used during installation: " -s DB_PASSWORD
echo

# Fix 1: Directory permission issue
log "Fixing directory permissions..."
cd /tmp

# Fix 2: Handle the ON CONFLICT error for radgroupreply
log "Fixing database constraint issues..."
sudo -u postgres psql radiusdb << 'EOF'
-- First, let's check if the radgroupreply entries already exist and handle conflicts properly
DO $$
BEGIN
    -- Insert bandwidth control groups with proper conflict handling
    INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('Student', 'WISPr-Bandwidth-Max-Down', ':=', '15000000')
    ON CONFLICT (groupname, attribute) DO UPDATE SET value = EXCLUDED.value;
    
    INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('Student', 'WISPr-Bandwidth-Max-Up', ':=', '3000000')
    ON CONFLICT (groupname, attribute) DO UPDATE SET value = EXCLUDED.value;
    
    INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('Basic', 'WISPr-Bandwidth-Max-Down', ':=', '10000000')
    ON CONFLICT (groupname, attribute) DO UPDATE SET value = EXCLUDED.value;
    
    INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('Basic', 'WISPr-Bandwidth-Max-Up', ':=', '2000000')
    ON CONFLICT (groupname, attribute) DO UPDATE SET value = EXCLUDED.value;
    
    INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('Standard', 'WISPr-Bandwidth-Max-Down', ':=', '25000000')
    ON CONFLICT (groupname, attribute) DO UPDATE SET value = EXCLUDED.value;
    
    INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('Standard', 'WISPr-Bandwidth-Max-Up', ':=', '5000000')
    ON CONFLICT (groupname, attribute) DO UPDATE SET value = EXCLUDED.value;
    
    INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('Premium', 'WISPr-Bandwidth-Max-Down', ':=', '50000000')
    ON CONFLICT (groupname, attribute) DO UPDATE SET value = EXCLUDED.value;
    
    INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('Premium', 'WISPr-Bandwidth-Max-Up', ':=', '10000000')
    ON CONFLICT (groupname, attribute) DO UPDATE SET value = EXCLUDED.value;
    
    INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('Business', 'WISPr-Bandwidth-Max-Down', ':=', '100000000')
    ON CONFLICT (groupname, attribute) DO UPDATE SET value = EXCLUDED.value;
    
    INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
    ('Business', 'WISPr-Bandwidth-Max-Up', ':=', '20000000')
    ON CONFLICT (groupname, attribute) DO UPDATE SET value = EXCLUDED.value;
    
EXCEPTION
    WHEN others THEN
        -- If there's no unique constraint, just insert without conflict handling
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
END $$;
EOF

# Fix 3: Properly configure FreeRADIUS SQL module
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

# Fix 4: Properly enable SQL in authorize section (fix the sed command)
log "Enabling SQL in FreeRADIUS authorize section..."
sudo cp /etc/freeradius/3.0/sites-enabled/default /etc/freeradius/3.0/sites-enabled/default.backup

# Create a proper default site configuration
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
        -ldap
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
        -sql
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
            -sql
            attr_filter.access_reject
            eap
            remove_reply_message_if_eap
        }
    }

    pre-proxy {
    }

    post-proxy {
        eap
    }
}
EOF

# Create test user
log "Creating test user..."
sudo -u postgres psql radiusdb << EOF
-- Delete existing test user if exists
DELETE FROM radcheck WHERE username = 'testuser';
DELETE FROM radusergroup WHERE username = 'testuser';

-- Insert test user
INSERT INTO radcheck (username, attribute, op, value) VALUES ('testuser', 'Cleartext-Password', ':=', 'testpass');
INSERT INTO radusergroup (username, groupname, priority) VALUES ('testuser', 'Standard', 1);
EOF

# Restart services
log "Restarting services..."
sudo systemctl restart postgresql
sudo systemctl restart freeradius
sudo systemctl restart redis-server
sudo systemctl restart nginx

# Wait a moment for services to start
sleep 3

# Check service status
log "Checking service status..."
echo -e "\n${BLUE}=== Service Status ===${NC}"
echo -e "${GREEN}PostgreSQL: $(sudo systemctl is-active postgresql)${NC}"
echo -e "${GREEN}FreeRADIUS: $(sudo systemctl is-active freeradius)${NC}"
echo -e "${GREEN}Redis: $(sudo systemctl is-active redis-server)${NC}"
echo -e "${GREEN}Nginx: $(sudo systemctl is-active nginx)${NC}"

# Test RADIUS authentication
log "Testing RADIUS authentication..."
if echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123 | grep -q "Access-Accept"; then
    echo -e "${GREEN}✅ RADIUS authentication test: PASSED${NC}"
else
    echo -e "${YELLOW}⚠️  RADIUS authentication test: FAILED${NC}"
    echo -e "${YELLOW}Running FreeRADIUS debug to check configuration...${NC}"
    
    # Stop FreeRADIUS and run in debug mode briefly
    sudo systemctl stop freeradius
    timeout 10s sudo freeradius -X || true
    sudo systemctl start freeradius
    
    echo -e "${YELLOW}Check the debug output above for any configuration errors${NC}"
fi

# Verify database tables
log "Verifying database setup..."
TABLE_COUNT=$(sudo -u postgres psql radiusdb -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
echo -e "${BLUE}Database contains $TABLE_COUNT tables${NC}"

# Show service profiles
echo -e "\n${BLUE}=== Service Profiles ===${NC}"
sudo -u postgres psql radiusdb -c "SELECT name, download_speed, upload_speed, price FROM service_profiles ORDER BY price;"

# Show bandwidth groups
echo -e "\n${BLUE}=== Bandwidth Control Groups ===${NC}"
sudo -u postgres psql radiusdb -c "SELECT groupname, attribute, value FROM radgroupreply WHERE attribute LIKE '%Bandwidth%' ORDER BY groupname, attribute;"

log "✅ Installation fixes completed!"

echo -e "\n${GREEN}🎉 Your ISP RADIUS system should now be working correctly!${NC}"
echo -e "\n${YELLOW}📋 Next Steps:${NC}"
echo -e "1. Test authentication: echo \"User-Name = testuser, User-Password = testpass\" | radclient localhost:1812 auth testing123"
echo -e "2. Add your network equipment as RADIUS clients"
echo -e "3. Start adding customer accounts"
echo -e "4. Configure your routers to use this RADIUS server"

echo -e "\n${BLUE}📊 System Information:${NC}"
echo -e "RADIUS Server: $(hostname -I | awk '{print $1}'):1812"
echo -e "Database: radiusdb on localhost:5432"
echo -e "Web Interface: http://$(hostname -I | awk '{print $1}')"

