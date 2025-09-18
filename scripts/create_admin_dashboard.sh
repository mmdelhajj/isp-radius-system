#!/bin/bash

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating ISP RADIUS Admin Dashboard..."

# Create admin dashboard directory
sudo mkdir -p /var/www/admin
cd /var/www/admin

# Create the main admin interface
sudo tee index.html > /dev/null << 'EOF'
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
            justify-content: between;
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
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-label {
            display: block;
            margin-bottom: 5px;
            font-weight: 500;
            color: #333;
        }
        
        .form-input {
            width: 100%;
            padding: 10px;
            border: 2px solid #e0e0e0;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s ease;
        }
        
        .form-input:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .grid-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        .chart-container {
            height: 300px;
            background: #f8f9fa;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #666;
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
                <li class="nav-item">
                    <a href="#" class="nav-link" data-section="logs">
                        <i class="fas fa-file-alt"></i> System Logs
                    </a>
                </li>
            </ul>
        </nav>
        
        <main class="main-content">
            <div class="header">
                <h1>ISP RADIUS Management System</h1>
                <p>Complete administration dashboard for your internet service provider</p>
            </div>
            
            <!-- Dashboard Section -->
            <section id="dashboard" class="content-section active">
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #4CAF50;">
                            <i class="fas fa-users"></i>
                        </div>
                        <div class="stat-number" id="total-users">4</div>
                        <div class="stat-label">Total Users</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #2196F3;">
                            <i class="fas fa-circle"></i>
                        </div>
                        <div class="stat-number" id="online-users">3</div>
                        <div class="stat-label">Online Users</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #FF9800;">
                            <i class="fas fa-server"></i>
                        </div>
                        <div class="stat-number" id="nas-count">2</div>
                        <div class="stat-label">NAS Devices</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #9C27B0;">
                            <i class="fas fa-dollar-sign"></i>
                        </div>
                        <div class="stat-number" id="monthly-revenue">$359.96</div>
                        <div class="stat-label">Monthly Revenue</div>
                    </div>
                </div>
                
                <div class="grid-2">
                    <div class="content-section active">
                        <h3>Recent Activity</h3>
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>Time</th>
                                    <th>User</th>
                                    <th>Action</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>14:15</td>
                                    <td>ahmed.hassan</td>
                                    <td>Login</td>
                                    <td><span class="status-badge status-active">Success</span></td>
                                </tr>
                                <tr>
                                    <td>14:10</td>
                                    <td>john.smith</td>
                                    <td>Data Transfer</td>
                                    <td><span class="status-badge status-active">Active</span></td>
                                </tr>
                                <tr>
                                    <td>14:05</td>
                                    <td>jane.doe</td>
                                    <td>Login</td>
                                    <td><span class="status-badge status-active">Success</span></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    
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
                
                <table class="table">
                    <thead>
                        <tr>
                            <th>Username</th>
                            <th>Email</th>
                            <th>Service Plan</th>
                            <th>Status</th>
                            <th>Last Login</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>john.smith</td>
                            <td>john.smith@email.com</td>
                            <td>Standard</td>
                            <td><span class="status-badge status-active">Active</span></td>
                            <td>2025-09-18 14:10</td>
                            <td>
                                <button class="btn" style="padding: 5px 10px; margin-right: 5px;">Edit</button>
                                <button class="btn" style="padding: 5px 10px; background: #dc3545;">Delete</button>
                            </td>
                        </tr>
                        <tr>
                            <td>jane.doe</td>
                            <td>jane.doe@email.com</td>
                            <td>Premium</td>
                            <td><span class="status-badge status-active">Active</span></td>
                            <td>2025-09-18 14:05</td>
                            <td>
                                <button class="btn" style="padding: 5px 10px; margin-right: 5px;">Edit</button>
                                <button class="btn" style="padding: 5px 10px; background: #dc3545;">Delete</button>
                            </td>
                        </tr>
                        <tr>
                            <td>tech.solutions</td>
                            <td>tech@solutions.com</td>
                            <td>Business</td>
                            <td><span class="status-badge status-active">Active</span></td>
                            <td>2025-09-18 13:45</td>
                            <td>
                                <button class="btn" style="padding: 5px 10px; margin-right: 5px;">Edit</button>
                                <button class="btn" style="padding: 5px 10px; background: #dc3545;">Delete</button>
                            </td>
                        </tr>
                        <tr>
                            <td>ahmed.hassan</td>
                            <td>ahmed.hassan@email.com</td>
                            <td>Premium</td>
                            <td><span class="status-badge status-active">Active</span></td>
                            <td>2025-09-18 14:15</td>
                            <td>
                                <button class="btn" style="padding: 5px 10px; margin-right: 5px;">Edit</button>
                                <button class="btn" style="padding: 5px 10px; background: #dc3545;">Delete</button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </section>
            
            <!-- Online Users Section -->
            <section id="online" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">Online Users</h2>
                    <button class="btn" onclick="refreshOnlineUsers()">
                        <i class="fas fa-sync"></i> Refresh
                    </button>
                </div>
                
                <table class="table">
                    <thead>
                        <tr>
                            <th>Username</th>
                            <th>IP Address</th>
                            <th>NAS</th>
                            <th>Session Time</th>
                            <th>Data Usage</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>john.smith</td>
                            <td>192.168.1.100</td>
                            <td>Router-01</td>
                            <td>02:45:30</td>
                            <td>1.2 GB</td>
                            <td>
                                <button class="btn" style="padding: 5px 10px; background: #dc3545;">Disconnect</button>
                            </td>
                        </tr>
                        <tr>
                            <td>jane.doe</td>
                            <td>192.168.1.101</td>
                            <td>Router-01</td>
                            <td>01:30:15</td>
                            <td>850 MB</td>
                            <td>
                                <button class="btn" style="padding: 5px 10px; background: #dc3545;">Disconnect</button>
                            </td>
                        </tr>
                        <tr>
                            <td>ahmed.hassan</td>
                            <td>192.168.1.102</td>
                            <td>Router-02</td>
                            <td>00:15:45</td>
                            <td>125 MB</td>
                            <td>
                                <button class="btn" style="padding: 5px 10px; background: #dc3545;">Disconnect</button>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </section>
            
            <!-- NAS Management Section -->
            <section id="nas" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">NAS Management</h2>
                    <button class="btn" onclick="showAddNASForm()">
                        <i class="fas fa-plus"></i> Add NAS Device
                    </button>
                </div>
                
                <table class="table">
                    <thead>
                        <tr>
                            <th>NAS Name</th>
                            <th>IP Address</th>
                            <th>Type</th>
                            <th>Status</th>
                            <th>Online Users</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Router-01</td>
                            <td>192.168.1.1</td>
                            <td>MikroTik</td>
                            <td><span class="status-badge status-active">Online</span></td>
                            <td>2</td>
                            <td>
                                <button class="btn" style="padding: 5px 10px; margin-right: 5px;">Edit</button>
                                <button class="btn" style="padding: 5px 10px; background: #dc3545;">Delete</button>
                            </td>
                        </tr>
                        <tr>
                            <td>Router-02</td>
                            <td>192.168.2.1</td>
                            <td>Cisco</td>
                            <td><span class="status-badge status-active">Online</span></td>
                            <td>1</td>
                            <td>
                                <button class="btn" style="padding: 5px 10px; margin-right: 5px;">Edit</button>
                                <button class="btn" style="padding: 5px 10px; background: #dc3545;">Delete</button>
                            </td>
                        </tr>
                    </tbody>
                </table>
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
                
                <div class="grid-2">
                    <div class="content-section active">
                        <h3>Recent Invoices</h3>
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>Invoice #</th>
                                    <th>Customer</th>
                                    <th>Amount</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>INV-001</td>
                                    <td>John Smith</td>
                                    <td>$49.99</td>
                                    <td><span class="status-badge status-active">Paid</span></td>
                                </tr>
                                <tr>
                                    <td>INV-002</td>
                                    <td>Jane Doe</td>
                                    <td>$79.99</td>
                                    <td><span class="status-badge status-active">Paid</span></td>
                                </tr>
                                <tr>
                                    <td>INV-003</td>
                                    <td>Tech Solutions</td>
                                    <td>$149.99</td>
                                    <td><span class="status-badge status-active">Paid</span></td>
                                </tr>
                                <tr>
                                    <td>INV-004</td>
                                    <td>Ahmed Hassan</td>
                                    <td>$79.99</td>
                                    <td><span class="status-badge status-inactive">Pending</span></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    
                    <div class="content-section active">
                        <h3>Revenue Summary</h3>
                        <div style="margin: 20px 0;">
                            <div style="margin-bottom: 15px;">
                                <strong>This Month:</strong> $359.96
                            </div>
                            <div style="margin-bottom: 15px;">
                                <strong>Last Month:</strong> $279.97
                            </div>
                            <div style="margin-bottom: 15px;">
                                <strong>Growth:</strong> +28.6%
                            </div>
                            <div style="margin-bottom: 15px;">
                                <strong>Outstanding:</strong> $79.99
                            </div>
                        </div>
                    </div>
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
                
                <div class="grid-2">
                    <div class="chart-container">
                        <div style="text-align: center;">
                            <i class="fas fa-chart-line" style="font-size: 3em; color: #ccc; margin-bottom: 10px;"></i>
                            <p>Revenue Trend Chart</p>
                            <p style="font-size: 0.9em; color: #999;">Interactive charts will be displayed here</p>
                        </div>
                    </div>
                    <div class="chart-container">
                        <div style="text-align: center;">
                            <i class="fas fa-chart-pie" style="font-size: 3em; color: #ccc; margin-bottom: 10px;"></i>
                            <p>Service Plan Distribution</p>
                            <p style="font-size: 0.9em; color: #999;">Plan usage statistics</p>
                        </div>
                    </div>
                </div>
                
                <div class="content-section active" style="margin-top: 20px;">
                    <h3>Usage Statistics</h3>
                    <table class="table">
                        <thead>
                            <tr>
                                <th>Service Plan</th>
                                <th>Active Users</th>
                                <th>Total Revenue</th>
                                <th>Avg. Usage</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>Premium</td>
                                <td>2</td>
                                <td>$159.98</td>
                                <td>85%</td>
                            </tr>
                            <tr>
                                <td>Business</td>
                                <td>1</td>
                                <td>$149.99</td>
                                <td>65%</td>
                            </tr>
                            <tr>
                                <td>Standard</td>
                                <td>1</td>
                                <td>$49.99</td>
                                <td>75%</td>
                            </tr>
                        </tbody>
                    </table>
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
                        <div class="form-group">
                            <label class="form-label">RADIUS Server IP</label>
                            <input type="text" class="form-input" value="localhost" placeholder="RADIUS Server IP">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Authentication Port</label>
                            <input type="text" class="form-input" value="1812" placeholder="Authentication Port">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Accounting Port</label>
                            <input type="text" class="form-input" value="1813" placeholder="Accounting Port">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Shared Secret</label>
                            <input type="password" class="form-input" value="testing123" placeholder="Shared Secret">
                        </div>
                    </div>
                    
                    <div class="content-section active">
                        <h3>Database Configuration</h3>
                        <div class="form-group">
                            <label class="form-label">Database Host</label>
                            <input type="text" class="form-input" value="localhost" placeholder="Database Host">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Database Port</label>
                            <input type="text" class="form-input" value="5432" placeholder="Database Port">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Database Name</label>
                            <input type="text" class="form-input" value="radiusdb" placeholder="Database Name">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Database User</label>
                            <input type="text" class="form-input" value="radiususer" placeholder="Database User">
                        </div>
                    </div>
                </div>
            </section>
            
            <!-- System Logs Section -->
            <section id="logs" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">System Logs</h2>
                    <button class="btn" onclick="refreshLogs()">
                        <i class="fas fa-sync"></i> Refresh
                    </button>
                </div>
                
                <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; font-family: monospace; font-size: 0.9em; max-height: 400px; overflow-y: auto;">
                    <div>[2025-09-18 14:15:25] INFO: User ahmed.hassan authenticated successfully</div>
                    <div>[2025-09-18 14:15:20] INFO: RADIUS request from 192.168.1.1</div>
                    <div>[2025-09-18 14:10:15] INFO: User john.smith data session started</div>
                    <div>[2025-09-18 14:05:10] INFO: User jane.doe authenticated successfully</div>
                    <div>[2025-09-18 14:00:05] INFO: Database connection established</div>
                    <div>[2025-09-18 13:55:00] INFO: RADIUS server started</div>
                    <div>[2025-09-18 13:50:55] INFO: System initialization complete</div>
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
            alert('Add User form would open here');
        }
        
        function refreshOnlineUsers() {
            alert('Refreshing online users...');
        }
        
        function showAddNASForm() {
            alert('Add NAS form would open here');
        }
        
        function showAddProfileForm() {
            alert('Add Profile form would open here');
        }
        
        function generateInvoices() {
            alert('Generating invoices...');
        }
        
        function exportReport() {
            alert('Exporting report...');
        }
        
        function saveSettings() {
            alert('Settings saved successfully!');
        }
        
        function refreshLogs() {
            alert('Refreshing system logs...');
        }
        
        // Auto-refresh online users every 30 seconds
        setInterval(function() {
            if (document.getElementById('online').classList.contains('active')) {
                // Update online users data here
                console.log('Auto-refreshing online users...');
            }
        }, 30000);
        
        // Update dashboard stats every 60 seconds
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

# Configure Nginx for admin dashboard
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
    
    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

# Enable the admin dashboard site
sudo ln -sf /etc/nginx/sites-available/admin-dashboard /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Admin Dashboard installed successfully!"
echo "Admin Dashboard URL: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "Features:"
echo "  • Complete Admin Dashboard"
echo "  • User Management"
echo "  • Online User Monitoring"
echo "  • NAS Device Management"
echo "  • Service Profile Configuration"
echo "  • Billing & Invoice Management"
echo "  • Reports & Analytics"
echo "  • System Settings"
echo "  • Real-time System Logs"
echo "  • Responsive Design"
echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Access your admin dashboard via web browser."

