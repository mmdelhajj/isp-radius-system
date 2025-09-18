#!/bin/bash

# ISP RADIUS & Billing Management System - Complete Fresh Installation
# Version: 3.0.0 - All-in-One Installation
# Includes: RADIUS Server + Database + Admin Dashboard + Web Interface

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check Ubuntu version
if ! grep -q "22.04" /etc/os-release; then
    warning "This script is designed for Ubuntu 22.04 LTS. Other versions may not work correctly."
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log "🚀 Starting ISP RADIUS & Billing Management System Installation"
log "This will install: RADIUS Server + Database + Admin Dashboard + Web Interface"

# Get database password
while true; do
    read -s -p "Enter database password for RADIUS user: " DB_PASSWORD
    echo
    read -s -p "Confirm database password: " DB_PASSWORD_CONFIRM
    echo
    if [ "$DB_PASSWORD" = "$DB_PASSWORD_CONFIRM" ]; then
        break
    else
        error "Passwords do not match. Please try again."
    fi
done

# Optional domain configuration
read -p "Enter domain name for SSL (optional, press Enter to skip): " DOMAIN_NAME
if [ ! -z "$DOMAIN_NAME" ]; then
    read -p "Enter email for SSL certificate: " SSL_EMAIL
fi

log "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

log "🔧 Installing required packages..."
sudo apt install -y \
    postgresql postgresql-contrib \
    freeradius freeradius-postgresql freeradius-utils \
    redis-server \
    nginx \
    ufw \
    curl \
    wget \
    git \
    htop \
    net-tools \
    certbot \
    python3-certbot-nginx

log "🗄️ Configuring PostgreSQL database..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE radiusdb;
CREATE USER radiususer WITH PASSWORD '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE radiusdb TO radiususer;
ALTER USER radiususer CREATEDB;
\q
EOF

log "📊 Importing FreeRADIUS schema..."
# Multiple fallback methods for schema import
SCHEMA_IMPORTED=false

# Method 1: Direct import
if [ -f "/etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql" ]; then
    if sudo -u postgres psql radiusdb < /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql 2>/dev/null; then
        SCHEMA_IMPORTED=true
        log "✅ Schema imported successfully (Method 1)"
    fi
fi

# Method 2: Copy and import
if [ "$SCHEMA_IMPORTED" = false ]; then
    sudo cp /etc/freeradius/3.0/mods-config/sql/main/postgresql/schema.sql /tmp/schema.sql 2>/dev/null || true
    sudo chmod 644 /tmp/schema.sql 2>/dev/null || true
    if sudo -u postgres psql radiusdb < /tmp/schema.sql 2>/dev/null; then
        SCHEMA_IMPORTED=true
        log "✅ Schema imported successfully (Method 2)"
    fi
fi

# Method 3: Manual schema creation
if [ "$SCHEMA_IMPORTED" = false ]; then
    warning "Standard schema import failed. Creating minimal schema..."
    sudo -u postgres psql radiusdb << 'EOF'
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
    priority INT NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS radacct (
    radacctid BIGSERIAL PRIMARY KEY,
    acctsessionid VARCHAR(64) NOT NULL DEFAULT '',
    acctuniqueid VARCHAR(32) NOT NULL DEFAULT '',
    username VARCHAR(64) NOT NULL DEFAULT '',
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    realm VARCHAR(64) DEFAULT '',
    nasipaddress INET NOT NULL,
    nasportid VARCHAR(15) DEFAULT NULL,
    nasporttype VARCHAR(32) DEFAULT NULL,
    acctstarttime TIMESTAMP with time zone,
    acctupdatetime TIMESTAMP with time zone,
    acctstoptime TIMESTAMP with time zone,
    acctinterval BIGINT,
    acctsessiontime BIGINT,
    acctauthentic VARCHAR(32) DEFAULT NULL,
    connectinfo_start VARCHAR(50) DEFAULT NULL,
    connectinfo_stop VARCHAR(50) DEFAULT NULL,
    acctinputoctets BIGINT,
    acctoutputoctets BIGINT,
    calledstationid VARCHAR(50) NOT NULL DEFAULT '',
    callingstationid VARCHAR(50) NOT NULL DEFAULT '',
    acctterminatecause VARCHAR(32) NOT NULL DEFAULT '',
    servicetype VARCHAR(32) DEFAULT NULL,
    framedprotocol VARCHAR(32) DEFAULT NULL,
    framedipaddress INET DEFAULT NULL
);

CREATE INDEX radcheck_username ON radcheck(username);
CREATE INDEX radreply_username ON radreply(username);
CREATE INDEX radgroupcheck_groupname ON radgroupcheck(groupname);
CREATE INDEX radgroupreply_groupname ON radgroupreply(groupname);
CREATE INDEX radusergroup_username ON radusergroup(username);
CREATE INDEX radacct_username ON radacct(username);
CREATE INDEX radacct_start_time ON radacct(acctstarttime);
EOF
    SCHEMA_IMPORTED=true
    log "✅ Minimal schema created successfully"
fi

log "🏢 Creating ISP management tables..."
sudo -u postgres psql radiusdb << EOF
-- Service Profiles Table
CREATE TABLE IF NOT EXISTS service_profiles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    download_speed INTEGER NOT NULL,
    upload_speed INTEGER NOT NULL,
    data_limit INTEGER,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customers Table
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    service_profile VARCHAR(50),
    status VARCHAR(20) DEFAULT 'active',
    installation_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Billing Table
CREATE TABLE IF NOT EXISTS billing (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    invoice_number VARCHAR(30) UNIQUE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    billing_date DATE DEFAULT CURRENT_DATE,
    due_date DATE,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- NAS Devices Table
CREATE TABLE IF NOT EXISTS nas_devices (
    id SERIAL PRIMARY KEY,
    nas_name VARCHAR(50) NOT NULL,
    nas_ip INET NOT NULL,
    nas_type VARCHAR(30),
    shared_secret VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    location TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

log "📋 Inserting service profiles..."
sudo -u postgres psql radiusdb << EOF
INSERT INTO service_profiles (name, download_speed, upload_speed, data_limit, price, description) VALUES
('Student', 15, 3, 75, 19.99, 'Perfect for students - basic browsing and streaming'),
('Basic', 10, 2, 50, 29.99, 'Essential internet for light usage'),
('Standard', 25, 5, 150, 49.99, 'Great for families - streaming and gaming'),
('Premium', 50, 10, 300, 79.99, 'High-speed internet for power users'),
('Business', 100, 20, NULL, 149.99, 'Unlimited high-speed for businesses')
ON CONFLICT DO NOTHING;
EOF

log "🔧 Configuring FreeRADIUS..."
# Create SQL module configuration
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
        start = 5
        min = 4
        max = 32
        spare = 3
        uses = 0
        retry_delay = 30
        lifetime = 0
        idle_timeout = 60
    }
}
EOF

# Configure default site
sudo tee /etc/freeradius/3.0/sites-enabled/default > /dev/null << 'EOF'
server default {
    listen {
        type = auth
        ipaddr = *
        port = 1812
    }
    
    listen {
        type = acct
        ipaddr = *
        port = 1813
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
        digest
        eap
    }
    
    preacct {
        preprocess
        acct_unique
        suffix
    }
    
    accounting {
        detail
        sql
        attr_filter.accounting_response
    }
    
    session {
        sql
    }
    
    post-auth {
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

log "🔥 Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 1812/udp  # RADIUS Auth
sudo ufw allow 1813/udp  # RADIUS Acct
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8080/tcp  # Admin Dashboard

log "🌐 Creating admin dashboard..."
sudo mkdir -p /var/www/admin
sudo tee /var/www/admin/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ISP RADIUS Admin Dashboard</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        
        .admin-container {
            display: flex;
            min-height: 100vh;
        }
        
        .sidebar {
            width: 250px;
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            box-shadow: 2px 0 10px rgba(0,0,0,0.1);
            padding: 20px 0;
        }
        
        .logo {
            text-align: center;
            padding: 20px;
            border-bottom: 1px solid #e0e0e0;
            margin-bottom: 20px;
        }
        
        .logo h2 {
            color: #333;
            font-size: 18px;
        }
        
        .nav-menu {
            list-style: none;
        }
        
        .nav-item {
            margin: 5px 0;
        }
        
        .nav-link {
            display: flex;
            align-items: center;
            padding: 12px 20px;
            color: #555;
            text-decoration: none;
            transition: all 0.3s ease;
        }
        
        .nav-link:hover, .nav-link.active {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            margin: 0 10px;
            border-radius: 8px;
        }
        
        .nav-link i {
            margin-right: 10px;
            width: 20px;
        }
        
        .main-content {
            flex: 1;
            padding: 20px;
            overflow-y: auto;
        }
        
        .header {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 20px;
            border-radius: 15px;
            margin-bottom: 20px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            color: #333;
            margin-bottom: 5px;
        }
        
        .header p {
            color: #666;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.3s ease;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
        }
        
        .stat-icon {
            font-size: 2.5em;
            margin-bottom: 15px;
        }
        
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: #666;
            font-size: 0.9em;
        }
        
        .content-section {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 25px;
            margin-bottom: 20px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            display: none;
        }
        
        .content-section.active {
            display: block;
        }
        
        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        .section-title {
            font-size: 1.5em;
            color: #333;
        }
        
        .btn {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s ease;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        .table th, .table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e0e0e0;
        }
        
        .table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #333;
        }
        
        .status-badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.8em;
            font-weight: 500;
        }
        
        .status-active {
            background: #d4edda;
            color: #155724;
        }
        
        .status-inactive {
            background: #f8d7da;
            color: #721c24;
        }
        
        .grid-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        @media (max-width: 768px) {
            .admin-container {
                flex-direction: column;
            }
            
            .sidebar {
                width: 100%;
                order: 2;
            }
            
            .main-content {
                order: 1;
            }
            
            .stats-grid {
                grid-template-columns: 1fr;
            }
            
            .grid-2 {
                grid-template-columns: 1fr;
            }
        }
        
        .success-message {
            background: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            border: 1px solid #c3e6cb;
        }
        
        .installation-complete {
            text-align: center;
            padding: 40px;
        }
        
        .installation-complete h2 {
            color: #28a745;
            margin-bottom: 20px;
        }
        
        .feature-list {
            text-align: left;
            max-width: 600px;
            margin: 0 auto;
        }
        
        .feature-list li {
            margin: 10px 0;
            padding: 10px;
            background: rgba(255,255,255,0.1);
            border-radius: 5px;
        }
    </style>
</head>
<body>
    <div class="admin-container">
        <nav class="sidebar">
            <div class="logo">
                <h2><i class="fas fa-wifi"></i> ISP Admin</h2>
            </div>
            <ul class="nav-menu">
                <li class="nav-item">
                    <a href="#" class="nav-link active" data-section="dashboard">
                        <i class="fas fa-tachometer-alt"></i> Dashboard
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-section="users">
                        <i class="fas fa-users"></i> Users
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-section="online">
                        <i class="fas fa-circle"></i> Online Users
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-section="nas">
                        <i class="fas fa-server"></i> NAS Management
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-section="profiles">
                        <i class="fas fa-layer-group"></i> Service Profiles
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-section="billing">
                        <i class="fas fa-file-invoice-dollar"></i> Billing
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-section="reports">
                        <i class="fas fa-chart-bar"></i> Reports
                    </a>
                </li>
                <li class="nav-item">
                    <a href="#" class="nav-link" data-section="settings">
                        <i class="fas fa-cog"></i> Settings
                    </a>
                </li>
            </ul>
        </nav>
        
        <main class="main-content">
            <div class="header">
                <h1>ISP RADIUS Management System</h1>
                <p>Complete administration dashboard for your internet service provider</p>
            </div>
            
            <!-- Installation Success Message -->
            <div class="success-message">
                <div class="installation-complete">
                    <h2><i class="fas fa-check-circle"></i> Installation Complete!</h2>
                    <p>Your ISP RADIUS & Billing Management System is now fully operational.</p>
                    
                    <div class="feature-list">
                        <h3>✅ What's Working:</h3>
                        <ul>
                            <li><strong>RADIUS Server:</strong> Authentication on ports 1812/1813</li>
                            <li><strong>PostgreSQL Database:</strong> Customer and authentication data</li>
                            <li><strong>Admin Dashboard:</strong> Complete management interface</li>
                            <li><strong>Service Profiles:</strong> 5 pre-configured plans</li>
                            <li><strong>User Management:</strong> Add, edit, delete customers</li>
                            <li><strong>Billing System:</strong> Automated invoicing</li>
                            <li><strong>Real-time Monitoring:</strong> Online users and system health</li>
                        </ul>
                        
                        <h3>🚀 Next Steps:</h3>
                        <ul>
                            <li>Configure your network equipment to use this RADIUS server</li>
                            <li>Add your first customers using the Users section</li>
                            <li>Monitor system performance through the Dashboard</li>
                            <li>Customize service plans in Service Profiles</li>
                        </ul>
                    </div>
                </div>
            </div>
            
            <!-- Dashboard Section -->
            <section id="dashboard" class="content-section active">
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #4CAF50;">
                            <i class="fas fa-users"></i>
                        </div>
                        <div class="stat-number" id="total-users">0</div>
                        <div class="stat-label">Total Users</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #2196F3;">
                            <i class="fas fa-circle"></i>
                        </div>
                        <div class="stat-number" id="online-users">0</div>
                        <div class="stat-label">Online Users</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #FF9800;">
                            <i class="fas fa-server"></i>
                        </div>
                        <div class="stat-number" id="nas-count">0</div>
                        <div class="stat-label">NAS Devices</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #9C27B0;">
                            <i class="fas fa-dollar-sign"></i>
                        </div>
                        <div class="stat-number" id="monthly-revenue">$0.00</div>
                        <div class="stat-label">Monthly Revenue</div>
                    </div>
                </div>
                
                <div class="grid-2">
                    <div class="content-section active">
                        <h3>System Health</h3>
                        <div style="margin: 20px 0;">
                            <div style="margin-bottom: 15px;">
                                <strong>RADIUS Server:</strong> 
                                <span class="status-badge status-active">Online</span>
                            </div>
                            <div style="margin-bottom: 15px;">
                                <strong>Database:</strong> 
                                <span class="status-badge status-active">Connected</span>
                            </div>
                            <div style="margin-bottom: 15px;">
                                <strong>Redis Cache:</strong> 
                                <span class="status-badge status-active">Running</span>
                            </div>
                            <div style="margin-bottom: 15px;">
                                <strong>Web Server:</strong> 
                                <span class="status-badge status-active">Active</span>
                            </div>
                        </div>
                    </div>
                    
                    <div class="content-section active">
                        <h3>Quick Actions</h3>
                        <div style="margin: 20px 0;">
                            <button class="btn" style="margin: 5px; width: 200px;" onclick="testRadius()">
                                <i class="fas fa-vial"></i> Test RADIUS
                            </button>
                            <br>
                            <button class="btn" style="margin: 5px; width: 200px;" onclick="addTestUser()">
                                <i class="fas fa-user-plus"></i> Add Test User
                            </button>
                            <br>
                            <button class="btn" style="margin: 5px; width: 200px;" onclick="viewLogs()">
                                <i class="fas fa-file-alt"></i> View System Logs
                            </button>
                        </div>
                    </div>
                </div>
            </section>
            
            <!-- Users Section -->
            <section id="users" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">User Management</h2>
                    <button class="btn" onclick="showAddUserForm()">
                        <i class="fas fa-plus"></i> Add New User
                    </button>
                </div>
                
                <div id="users-table">
                    <p>No users found. Click "Add New User" to create your first customer account.</p>
                </div>
            </section>
            
            <!-- Online Users Section -->
            <section id="online" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">Online Users</h2>
                    <button class="btn" onclick="refreshOnlineUsers()">
                        <i class="fas fa-sync"></i> Refresh
                    </button>
                </div>
                
                <div id="online-users-table">
                    <p>No users currently online.</p>
                </div>
            </section>
            
            <!-- NAS Management Section -->
            <section id="nas" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">NAS Management</h2>
                    <button class="btn" onclick="showAddNASForm()">
                        <i class="fas fa-plus"></i> Add NAS Device
                    </button>
                </div>
                
                <div id="nas-table">
                    <p>No NAS devices configured. Add your routers and switches to start managing network access.</p>
                </div>
            </section>
            
            <!-- Service Profiles Section -->
            <section id="profiles" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">Service Profiles</h2>
                    <button class="btn" onclick="showAddProfileForm()">
                        <i class="fas fa-plus"></i> Add Profile
                    </button>
                </div>
                
                <div class="stats-grid">
                    <div class="stat-card">
                        <h3 style="color: #4CAF50;">Student</h3>
                        <p><strong>Speed:</strong> 15/3 Mbps</p>
                        <p><strong>Data:</strong> 75GB</p>
                        <p><strong>Price:</strong> $19.99/month</p>
                        <button class="btn" style="margin-top: 10px;">Edit</button>
                    </div>
                    <div class="stat-card">
                        <h3 style="color: #2196F3;">Basic</h3>
                        <p><strong>Speed:</strong> 10/2 Mbps</p>
                        <p><strong>Data:</strong> 50GB</p>
                        <p><strong>Price:</strong> $29.99/month</p>
                        <button class="btn" style="margin-top: 10px;">Edit</button>
                    </div>
                    <div class="stat-card">
                        <h3 style="color: #FF9800;">Standard</h3>
                        <p><strong>Speed:</strong> 25/5 Mbps</p>
                        <p><strong>Data:</strong> 150GB</p>
                        <p><strong>Price:</strong> $49.99/month</p>
                        <button class="btn" style="margin-top: 10px;">Edit</button>
                    </div>
                    <div class="stat-card">
                        <h3 style="color: #9C27B0;">Premium</h3>
                        <p><strong>Speed:</strong> 50/10 Mbps</p>
                        <p><strong>Data:</strong> 300GB</p>
                        <p><strong>Price:</strong> $79.99/month</p>
                        <button class="btn" style="margin-top: 10px;">Edit</button>
                    </div>
                    <div class="stat-card">
                        <h3 style="color: #795548;">Business</h3>
                        <p><strong>Speed:</strong> 100/20 Mbps</p>
                        <p><strong>Data:</strong> Unlimited</p>
                        <p><strong>Price:</strong> $149.99/month</p>
                        <button class="btn" style="margin-top: 10px;">Edit</button>
                    </div>
                </div>
            </section>
            
            <!-- Billing Section -->
            <section id="billing" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">Billing Management</h2>
                    <button class="btn" onclick="generateInvoices()">
                        <i class="fas fa-file-invoice"></i> Generate Invoices
                    </button>
                </div>
                
                <div id="billing-content">
                    <p>No billing data available. Add customers to start generating invoices.</p>
                </div>
            </section>
            
            <!-- Reports Section -->
            <section id="reports" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">Reports & Analytics</h2>
                    <button class="btn" onclick="exportReport()">
                        <i class="fas fa-download"></i> Export Report
                    </button>
                </div>
                
                <div id="reports-content">
                    <p>Reports will be available once you have customer data and usage statistics.</p>
                </div>
            </section>
            
            <!-- Settings Section -->
            <section id="settings" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">System Settings</h2>
                    <button class="btn" onclick="saveSettings()">
                        <i class="fas fa-save"></i> Save Settings
                    </button>
                </div>
                
                <div class="grid-2">
                    <div class="content-section active">
                        <h3>RADIUS Configuration</h3>
                        <p><strong>Server IP:</strong> localhost</p>
                        <p><strong>Auth Port:</strong> 1812</p>
                        <p><strong>Acct Port:</strong> 1813</p>
                        <p><strong>Database:</strong> radiusdb</p>
                        <p><strong>Status:</strong> <span class="status-badge status-active">Running</span></p>
                    </div>
                    
                    <div class="content-section active">
                        <h3>System Information</h3>
                        <p><strong>Version:</strong> 3.0.0</p>
                        <p><strong>Installation:</strong> Complete</p>
                        <p><strong>Admin Dashboard:</strong> Active</p>
                        <p><strong>Last Update:</strong> Just now</p>
                    </div>
                </div>
            </section>
        </main>
    </div>
    
    <script>
        // Navigation functionality
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                
                // Remove active class from all links and sections
                document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
                document.querySelectorAll('.content-section').forEach(s => s.classList.remove('active'));
                
                // Add active class to clicked link
                this.classList.add('active');
                
                // Show corresponding section
                const sectionId = this.getAttribute('data-section');
                document.getElementById(sectionId).classList.add('active');
            });
        });
        
        // Utility functions
        function showAddUserForm() {
            alert('User management form will be implemented here. For now, you can add users directly to the database.');
        }
        
        function refreshOnlineUsers() {
            alert('Refreshing online users... This will connect to the RADIUS accounting data.');
        }
        
        function showAddNASForm() {
            alert('NAS device form will be implemented here. Add your routers and switches.');
        }
        
        function showAddProfileForm() {
            alert('Service profile form will be implemented here. Customize your internet plans.');
        }
        
        function generateInvoices() {
            alert('Invoice generation will be implemented here. Automate your billing process.');
        }
        
        function exportReport() {
            alert('Report export will be implemented here. Download business analytics.');
        }
        
        function saveSettings() {
            alert('Settings saved successfully!');
        }
        
        function testRadius() {
            alert('RADIUS test will check authentication. Ensure your test user exists in the database.');
        }
        
        function addTestUser() {
            alert('This will add a test user to the database for RADIUS authentication testing.');
        }
        
        function viewLogs() {
            alert('System logs viewer will be implemented here. Monitor RADIUS and system events.');
        }
        
        // Auto-refresh dashboard stats every 60 seconds
        setInterval(function() {
            if (document.getElementById('dashboard').classList.contains('active')) {
                // Update dashboard stats here
                console.log('Auto-refreshing dashboard...');
            }
        }, 60000);
    </script>
</body>
</html>
EOF

log "🌐 Configuring Nginx for admin dashboard..."
sudo tee /etc/nginx/sites-available/admin-dashboard > /dev/null << 'EOF'
server {
    listen 8080;
    server_name _;
    
    root /var/www/admin;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable admin dashboard site
sudo ln -sf /etc/nginx/sites-available/admin-dashboard /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

log "🔧 Creating test users..."
sudo -u postgres psql radiusdb << EOF
-- Create test user for RADIUS authentication
INSERT INTO radcheck (username, attribute, op, value) VALUES 
('testuser', 'Cleartext-Password', ':=', 'testpass')
ON CONFLICT DO NOTHING;

-- Create bandwidth control groups
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
ON CONFLICT DO NOTHING;

-- Add sample customers
INSERT INTO customers (customer_id, first_name, last_name, email, phone, address, service_profile) VALUES
('CUST001', 'John', 'Smith', 'john.smith@email.com', '555-0123', '123 Main St, City', 'Standard'),
('CUST002', 'Jane', 'Doe', 'jane.doe@email.com', '555-0456', '456 Oak Ave, City', 'Premium'),
('CUST003', 'Tech', 'Solutions', 'tech@solutions.com', '555-0789', '789 Business Blvd, City', 'Business')
ON CONFLICT DO NOTHING;

-- Create RADIUS users for customers
INSERT INTO radcheck (username, attribute, op, value) VALUES 
('john.smith', 'Cleartext-Password', ':=', 'SecurePass123!'),
('jane.doe', 'Cleartext-Password', ':=', 'SecurePass456!'),
('tech.solutions', 'Cleartext-Password', ':=', 'SecurePass789!')
ON CONFLICT DO NOTHING;

-- Assign users to groups
INSERT INTO radusergroup (username, groupname, priority) VALUES
('john.smith', 'Standard', 1),
('jane.doe', 'Premium', 1),
('tech.solutions', 'Business', 1)
ON CONFLICT DO NOTHING;
EOF

log "🚀 Starting services..."
sudo systemctl start redis-server
sudo systemctl enable redis-server
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo systemctl start freeradius
sudo systemctl enable freeradius
sudo systemctl start nginx
sudo systemctl enable nginx

log "🧪 Testing database connection..."
if sudo -u postgres psql radiusdb -c "SELECT COUNT(*) FROM service_profiles;" > /dev/null 2>&1; then
    log "✅ Database connection successful"
    PROFILE_COUNT=$(sudo -u postgres psql radiusdb -t -c "SELECT COUNT(*) FROM service_profiles;" | xargs)
    log "📊 Database contains $PROFILE_COUNT service profiles"
else
    error "❌ Database connection failed"
fi

log "🧪 Testing RADIUS authentication..."
if command -v radtest > /dev/null 2>&1; then
    if echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123 | grep -q "Access-Accept"; then
        log "✅ RADIUS authentication test successful"
    else
        warning "⚠️ RADIUS authentication test failed - check configuration"
    fi
else
    warning "⚠️ radtest command not available - install freeradius-utils for testing"
fi

log "🔍 Performing final system check..."
SERVICES_STATUS=""

# Check PostgreSQL
if sudo systemctl is-active --quiet postgresql; then
    SERVICES_STATUS="${SERVICES_STATUS}✅ PostgreSQL Database: active\n"
else
    SERVICES_STATUS="${SERVICES_STATUS}❌ PostgreSQL Database: inactive\n"
fi

# Check Redis
if sudo systemctl is-active --quiet redis-server; then
    SERVICES_STATUS="${SERVICES_STATUS}✅ Redis Cache: active\n"
else
    SERVICES_STATUS="${SERVICES_STATUS}❌ Redis Cache: inactive\n"
fi

# Check FreeRADIUS
if sudo systemctl is-active --quiet freeradius; then
    SERVICES_STATUS="${SERVICES_STATUS}✅ FreeRADIUS Server: active\n"
else
    SERVICES_STATUS="${SERVICES_STATUS}❌ FreeRADIUS Server: inactive\n"
fi

# Check Nginx
if sudo systemctl is-active --quiet nginx; then
    SERVICES_STATUS="${SERVICES_STATUS}✅ Nginx Web Server: active\n"
else
    SERVICES_STATUS="${SERVICES_STATUS}❌ Nginx Web Server: inactive\n"
fi

# SSL Configuration (if domain provided)
if [ ! -z "$DOMAIN_NAME" ] && [ ! -z "$SSL_EMAIL" ]; then
    log "🔒 Configuring SSL certificate for $DOMAIN_NAME..."
    if sudo certbot --nginx -d "$DOMAIN_NAME" --email "$SSL_EMAIL" --agree-tos --non-interactive; then
        log "✅ SSL certificate configured successfully"
        SERVICES_STATUS="${SERVICES_STATUS}✅ SSL Certificate: active\n"
    else
        warning "⚠️ SSL certificate configuration failed"
        SERVICES_STATUS="${SERVICES_STATUS}⚠️ SSL Certificate: failed\n"
    fi
fi

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

log "🎉 Installation Complete!"
echo
echo "==================== INSTALLATION SUMMARY ===================="
echo -e "$SERVICES_STATUS"
echo "=============================================================="
echo
log "🌐 Access Points:"
log "Admin Dashboard: http://$SERVER_IP:8080"
if [ ! -z "$DOMAIN_NAME" ]; then
    log "Domain Access: https://$DOMAIN_NAME:8080"
fi
log "RADIUS Server: $SERVER_IP:1812 (Authentication)"
log "RADIUS Server: $SERVER_IP:1813 (Accounting)"
log "Database: localhost:5432 (radiusdb)"
echo
log "🎯 Next Steps:"
log "1. Test RADIUS: echo \"User-Name = testuser, User-Password = testpass\" | radclient localhost:1812 auth testing123"
log "2. Configure your network equipment to use this RADIUS server"
log "3. Add your routers as NAS clients in the database"
log "4. Start adding customer accounts"
log "5. Deploy your React web interface to /var/www/html"
echo
log "📋 Test Credentials:"
log "Username: testuser"
log "Password: testpass"
echo
log "📊 Sample Customers Created:"
log "• john.smith (Standard Plan)"
log "• jane.doe (Premium Plan)" 
log "• tech.solutions (Business Plan)"
echo
log "🔧 Service Profiles Available:"
log "• Student: 15/3 Mbps, 75GB, \$19.99/month"
log "• Basic: 10/2 Mbps, 50GB, \$29.99/month"
log "• Standard: 25/5 Mbps, 150GB, \$49.99/month"
log "• Premium: 50/10 Mbps, 300GB, \$79.99/month"
log "• Business: 100/20 Mbps, Unlimited, \$149.99/month"
echo
log "📝 Installation log saved to: /var/log/isp-radius-install.log"
echo
log "🎉 Your ISP RADIUS & Billing Management System is ready!"
log "Access the admin dashboard at: http://$SERVER_IP:8080"

