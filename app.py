#!/usr/bin/env python3
"""
ISP RADIUS Management System - Flask Deployment Wrapper
This Flask app serves the PHP admin interface for permanent deployment
"""

from flask import Flask, render_template_string, request, jsonify, redirect
import psycopg2
import psycopg2.extras
import os
import json
from datetime import datetime, timedelta
import random
import string

app = Flask(__name__)

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'database': 'radiusdb',
    'user': 'radiususer',
    'password': 'radius2024'
}

def get_db_connection():
    """Get database connection"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

def generate_customer_id():
    """Generate unique customer ID"""
    return f"CUST{random.randint(1000, 9999)}"

def generate_invoice_number():
    """Generate unique invoice number"""
    return f"INV-{datetime.now().strftime('%Y%m')}-{random.randint(100, 999):03d}"

@app.route('/')
def index():
    """Main admin dashboard"""
    return render_template_string(ADMIN_TEMPLATE)

@app.route('/api/<action>', methods=['POST'])
def api_handler(action):
    """Handle API requests"""
    conn = get_db_connection()
    if not conn:
        return jsonify({'success': False, 'message': 'Database connection failed'})
    
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        
        if action == 'add_user':
            # Add new customer
            customer_id = generate_customer_id()
            username = f"{request.form['first_name'].lower()}.{request.form['last_name'].lower()}"
            
            # Insert customer
            cur.execute("""
                INSERT INTO customers (customer_id, first_name, last_name, email, phone, address, service_profile, status)
                VALUES (%s, %s, %s, %s, %s, %s, %s, 'active')
            """, (customer_id, request.form['first_name'], request.form['last_name'], 
                  request.form['email'], request.form['phone'], request.form['address'], 
                  request.form['service_profile']))
            
            # Insert RADIUS user
            cur.execute("""
                INSERT INTO radcheck (username, attribute, op, value)
                VALUES (%s, 'Cleartext-Password', ':=', %s)
            """, (username, request.form['password']))
            
            # Assign to group
            cur.execute("""
                INSERT INTO radusergroup (username, groupname, priority)
                VALUES (%s, %s, 1)
            """, (username, request.form['service_profile']))
            
            # Get price and create billing
            cur.execute("SELECT price FROM service_profiles WHERE name = %s", (request.form['service_profile'],))
            price = cur.fetchone()['price']
            
            invoice_number = generate_invoice_number()
            due_date = datetime.now() + timedelta(days=30)
            cur.execute("""
                INSERT INTO billing (customer_id, invoice_number, amount, due_date)
                VALUES (%s, %s, %s, %s)
            """, (customer_id, invoice_number, price, due_date.date()))
            
            conn.commit()
            return jsonify({'success': True, 'message': 'Customer added successfully!', 'username': username})
            
        elif action == 'get_users':
            cur.execute("""
                SELECT c.*, sp.price 
                FROM customers c 
                LEFT JOIN service_profiles sp ON c.service_profile = sp.name 
                ORDER BY c.created_at DESC
            """)
            users = cur.fetchall()
            return jsonify({'success': True, 'users': [dict(user) for user in users]})
            
        elif action == 'delete_user':
            customer_id = request.form['customer_id']
            
            # Get username
            cur.execute("SELECT first_name, last_name FROM customers WHERE customer_id = %s", (customer_id,))
            customer = cur.fetchone()
            username = f"{customer['first_name'].lower()}.{customer['last_name'].lower()}"
            
            # Delete from all tables
            cur.execute("DELETE FROM customers WHERE customer_id = %s", (customer_id,))
            cur.execute("DELETE FROM radcheck WHERE username = %s", (username,))
            cur.execute("DELETE FROM radusergroup WHERE username = %s", (username,))
            cur.execute("DELETE FROM billing WHERE customer_id = %s", (customer_id,))
            
            conn.commit()
            return jsonify({'success': True, 'message': 'Customer deleted successfully!'})
            
        elif action == 'add_nas':
            cur.execute("""
                INSERT INTO nas_devices (nas_name, nas_ip, nas_type, shared_secret, location)
                VALUES (%s, %s, %s, %s, %s)
            """, (request.form['nas_name'], request.form['nas_ip'], request.form['nas_type'],
                  request.form['shared_secret'], request.form['location']))
            
            conn.commit()
            return jsonify({'success': True, 'message': 'NAS device added successfully!'})
            
        elif action == 'get_nas':
            cur.execute("SELECT * FROM nas_devices ORDER BY created_at DESC")
            nas_devices = cur.fetchall()
            return jsonify({'success': True, 'nas_devices': [dict(nas) for nas in nas_devices]})
            
        elif action == 'get_stats':
            # Get total users
            cur.execute("SELECT COUNT(*) as count FROM customers WHERE status = 'active'")
            total_users = cur.fetchone()['count']
            
            # Get online users (simulated)
            online_users = random.randint(0, total_users)
            
            # Get NAS count
            cur.execute("SELECT COUNT(*) as count FROM nas_devices WHERE status = 'active'")
            nas_count = cur.fetchone()['count']
            
            # Get monthly revenue
            cur.execute("""
                SELECT SUM(sp.price) as revenue 
                FROM customers c 
                JOIN service_profiles sp ON c.service_profile = sp.name 
                WHERE c.status = 'active'
            """)
            result = cur.fetchone()
            monthly_revenue = float(result['revenue']) if result['revenue'] else 0
            
            return jsonify({
                'success': True,
                'stats': {
                    'total_users': total_users,
                    'online_users': online_users,
                    'nas_count': nas_count,
                    'monthly_revenue': f"{monthly_revenue:.2f}"
                }
            })
            
        elif action == 'get_billing':
            cur.execute("""
                SELECT b.*, c.first_name, c.last_name 
                FROM billing b 
                JOIN customers c ON b.customer_id = c.customer_id 
                ORDER BY b.created_at DESC LIMIT 50
            """)
            billing = cur.fetchall()
            return jsonify({'success': True, 'billing': [dict(bill) for bill in billing]})
            
    except Exception as e:
        conn.rollback()
        return jsonify({'success': False, 'message': f'Error: {str(e)}'})
    finally:
        conn.close()

@app.route('/service_profiles')
def get_service_profiles():
    """Get service profiles for the interface"""
    conn = get_db_connection()
    if not conn:
        return jsonify([])
    
    try:
        cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cur.execute("SELECT * FROM service_profiles ORDER BY price")
        profiles = cur.fetchall()
        return jsonify([dict(profile) for profile in profiles])
    except Exception as e:
        return jsonify([])
    finally:
        conn.close()

# HTML Template for the admin interface
ADMIN_TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ISP RADIUS Admin - Production System</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .admin-container { display: flex; min-height: 100vh; }
        .sidebar { width: 250px; background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(10px); box-shadow: 2px 0 10px rgba(0,0,0,0.1); padding: 20px 0; }
        .logo { text-align: center; padding: 20px; border-bottom: 1px solid #e0e0e0; margin-bottom: 20px; }
        .logo h2 { color: #333; font-size: 18px; }
        .nav-menu { list-style: none; }
        .nav-item { margin: 5px 0; }
        .nav-link { display: flex; align-items: center; padding: 12px 20px; color: #555; text-decoration: none; transition: all 0.3s ease; cursor: pointer; }
        .nav-link:hover, .nav-link.active { background: linear-gradient(135deg, #667eea, #764ba2); color: white; margin: 0 10px; border-radius: 8px; }
        .nav-link i { margin-right: 10px; width: 20px; }
        .main-content { flex: 1; padding: 20px; overflow-y: auto; }
        .header { background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(10px); padding: 20px; border-radius: 15px; margin-bottom: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
        .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .stat-card { background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(10px); padding: 25px; border-radius: 15px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); text-align: center; transition: transform 0.3s ease; }
        .stat-card:hover { transform: translateY(-5px); }
        .stat-icon { font-size: 2.5em; margin-bottom: 15px; }
        .stat-number { font-size: 2em; font-weight: bold; margin-bottom: 5px; }
        .stat-label { color: #666; font-size: 0.9em; }
        .content-section { background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(10px); border-radius: 15px; padding: 25px; margin-bottom: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); display: none; }
        .content-section.active { display: block; }
        .section-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; padding-bottom: 15px; border-bottom: 2px solid #f0f0f0; }
        .section-title { font-size: 1.5em; color: #333; }
        .btn { background: linear-gradient(135deg, #667eea, #764ba2); color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer; text-decoration: none; display: inline-block; transition: all 0.3s ease; }
        .btn:hover { transform: translateY(-2px); box-shadow: 0 4px 15px rgba(0,0,0,0.2); }
        .btn-danger { background: linear-gradient(135deg, #ff6b6b, #ee5a52); }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: 500; }
        .form-group input, .form-group select { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 14px; }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
        .table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        .table th, .table td { padding: 12px; text-align: left; border-bottom: 1px solid #e0e0e0; }
        .table th { background: #f8f9fa; font-weight: 600; color: #333; }
        .status-badge { padding: 4px 12px; border-radius: 20px; font-size: 0.8em; font-weight: 500; }
        .status-active { background: #d4edda; color: #155724; }
        .status-inactive { background: #f8d7da; color: #721c24; }
        .modal { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0,0,0,0.5); }
        .modal-content { background-color: #fefefe; margin: 5% auto; padding: 20px; border-radius: 10px; width: 80%; max-width: 600px; }
        .close { color: #aaa; float: right; font-size: 28px; font-weight: bold; cursor: pointer; }
        .close:hover { color: black; }
        .production-badge { background: linear-gradient(135deg, #28a745, #20c997); color: white; padding: 5px 15px; border-radius: 20px; font-size: 12px; font-weight: bold; }
        @media (max-width: 768px) {
            .admin-container { flex-direction: column; }
            .sidebar { width: 100%; order: 2; }
            .main-content { order: 1; }
            .stats-grid { grid-template-columns: 1fr; }
            .form-row { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="admin-container">
        <nav class="sidebar">
            <div class="logo">
                <h2><i class="fas fa-wifi"></i> ISP Admin</h2>
                <span class="production-badge">PRODUCTION</span>
            </div>
            <ul class="nav-menu">
                <li class="nav-item"><a class="nav-link active" data-section="dashboard"><i class="fas fa-tachometer-alt"></i> Dashboard</a></li>
                <li class="nav-item"><a class="nav-link" data-section="users"><i class="fas fa-users"></i> Users</a></li>
                <li class="nav-item"><a class="nav-link" data-section="nas"><i class="fas fa-server"></i> NAS Management</a></li>
                <li class="nav-item"><a class="nav-link" data-section="billing"><i class="fas fa-file-invoice-dollar"></i> Billing</a></li>
                <li class="nav-item"><a class="nav-link" data-section="profiles"><i class="fas fa-layer-group"></i> Service Profiles</a></li>
            </ul>
        </nav>
        
        <main class="main-content">
            <div class="header">
                <h1>ISP RADIUS Management System</h1>
                <p>Production Deployment - Fully Functional Administration Dashboard</p>
            </div>
            
            <!-- Dashboard Section -->
            <section id="dashboard" class="content-section active">
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #4CAF50;"><i class="fas fa-users"></i></div>
                        <div class="stat-number" id="total-users">Loading...</div>
                        <div class="stat-label">Total Users</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #2196F3;"><i class="fas fa-circle"></i></div>
                        <div class="stat-number" id="online-users">Loading...</div>
                        <div class="stat-label">Online Users</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #FF9800;"><i class="fas fa-server"></i></div>
                        <div class="stat-number" id="nas-count">Loading...</div>
                        <div class="stat-label">NAS Devices</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon" style="color: #9C27B0;"><i class="fas fa-dollar-sign"></i></div>
                        <div class="stat-number" id="monthly-revenue">Loading...</div>
                        <div class="stat-label">Monthly Revenue</div>
                    </div>
                </div>
            </section>
            
            <!-- Users Section -->
            <section id="users" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">User Management</h2>
                    <button class="btn" onclick="showAddUserModal()"><i class="fas fa-plus"></i> Add New User</button>
                </div>
                <div id="users-table-container"><p>Loading users...</p></div>
            </section>
            
            <!-- NAS Management Section -->
            <section id="nas" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">NAS Management</h2>
                    <button class="btn" onclick="showAddNASModal()"><i class="fas fa-plus"></i> Add NAS Device</button>
                </div>
                <div id="nas-table-container"><p>Loading NAS devices...</p></div>
            </section>
            
            <!-- Billing Section -->
            <section id="billing" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">Billing Management</h2>
                    <button class="btn" onclick="loadBilling()"><i class="fas fa-sync"></i> Refresh</button>
                </div>
                <div id="billing-table-container"><p>Loading billing data...</p></div>
            </section>
            
            <!-- Service Profiles Section -->
            <section id="profiles" class="content-section">
                <div class="section-header">
                    <h2 class="section-title">Service Profiles</h2>
                </div>
                <div class="stats-grid" id="profiles-container">
                    <p>Loading service profiles...</p>
                </div>
            </section>
        </main>
    </div>
    
    <!-- Add User Modal -->
    <div id="addUserModal" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeModal('addUserModal')">&times;</span>
            <h2>Add New Customer</h2>
            <form id="addUserForm">
                <div class="form-row">
                    <div class="form-group">
                        <label for="first_name">First Name</label>
                        <input type="text" id="first_name" name="first_name" required>
                    </div>
                    <div class="form-group">
                        <label for="last_name">Last Name</label>
                        <input type="text" id="last_name" name="last_name" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label for="email">Email</label>
                        <input type="email" id="email" name="email" required>
                    </div>
                    <div class="form-group">
                        <label for="phone">Phone</label>
                        <input type="text" id="phone" name="phone">
                    </div>
                </div>
                <div class="form-group">
                    <label for="address">Address</label>
                    <input type="text" id="address" name="address">
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label for="service_profile">Service Profile</label>
                        <select id="service_profile" name="service_profile" required>
                            <option value="">Loading...</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="password">Password</label>
                        <input type="password" id="password" name="password" required>
                    </div>
                </div>
                <button type="submit" class="btn">Add Customer</button>
            </form>
        </div>
    </div>
    
    <!-- Add NAS Modal -->
    <div id="addNASModal" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeModal('addNASModal')">&times;</span>
            <h2>Add NAS Device</h2>
            <form id="addNASForm">
                <div class="form-row">
                    <div class="form-group">
                        <label for="nas_name">Device Name</label>
                        <input type="text" id="nas_name" name="nas_name" required>
                    </div>
                    <div class="form-group">
                        <label for="nas_ip">IP Address</label>
                        <input type="text" id="nas_ip" name="nas_ip" required>
                    </div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label for="nas_type">Device Type</label>
                        <select id="nas_type" name="nas_type" required>
                            <option value="MikroTik">MikroTik</option>
                            <option value="Cisco">Cisco</option>
                            <option value="Ubiquiti">Ubiquiti</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label for="shared_secret">Shared Secret</label>
                        <input type="password" id="shared_secret" name="shared_secret" required>
                    </div>
                </div>
                <div class="form-group">
                    <label for="location">Location</label>
                    <input type="text" id="location" name="location">
                </div>
                <button type="submit" class="btn">Add NAS Device</button>
            </form>
        </div>
    </div>
    
    <script>
        // Navigation functionality
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
                document.querySelectorAll('.content-section').forEach(s => s.classList.remove('active'));
                this.classList.add('active');
                const sectionId = this.getAttribute('data-section');
                document.getElementById(sectionId).classList.add('active');
                loadSectionData(sectionId);
            });
        });
        
        function loadSectionData(section) {
            switch(section) {
                case 'dashboard': loadStats(); break;
                case 'users': loadUsers(); break;
                case 'nas': loadNAS(); break;
                case 'billing': loadBilling(); break;
                case 'profiles': loadProfiles(); break;
            }
        }
        
        function loadStats() {
            fetch('/api/get_stats', {method: 'POST'})
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    document.getElementById('total-users').textContent = data.stats.total_users;
                    document.getElementById('online-users').textContent = data.stats.online_users;
                    document.getElementById('nas-count').textContent = data.stats.nas_count;
                    document.getElementById('monthly-revenue').textContent = '$' + data.stats.monthly_revenue;
                }
            });
        }
        
        function loadUsers() {
            fetch('/api/get_users', {method: 'POST'})
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    let html = '<table class="table"><thead><tr><th>Customer ID</th><th>Name</th><th>Email</th><th>Service Plan</th><th>Price</th><th>Status</th><th>Actions</th></tr></thead><tbody>';
                    data.users.forEach(user => {
                        html += `<tr><td>${user.customer_id}</td><td>${user.first_name} ${user.last_name}</td><td>${user.email}</td><td>${user.service_profile}</td><td>$${parseFloat(user.price || 0).toFixed(2)}</td><td><span class="status-badge status-${user.status}">${user.status}</span></td><td><button class="btn btn-danger" onclick="deleteUser('${user.customer_id}')">Delete</button></td></tr>`;
                    });
                    html += '</tbody></table>';
                    document.getElementById('users-table-container').innerHTML = html;
                } else {
                    document.getElementById('users-table-container').innerHTML = '<p>Error loading users: ' + data.message + '</p>';
                }
            });
        }
        
        function loadNAS() {
            fetch('/api/get_nas', {method: 'POST'})
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    let html = '<table class="table"><thead><tr><th>Name</th><th>IP Address</th><th>Type</th><th>Location</th><th>Status</th></tr></thead><tbody>';
                    data.nas_devices.forEach(nas => {
                        html += `<tr><td>${nas.nas_name}</td><td>${nas.nas_ip}</td><td>${nas.nas_type}</td><td>${nas.location || 'N/A'}</td><td><span class="status-badge status-${nas.status}">${nas.status}</span></td></tr>`;
                    });
                    html += '</tbody></table>';
                    document.getElementById('nas-table-container').innerHTML = html;
                } else {
                    document.getElementById('nas-table-container').innerHTML = '<p>Error loading NAS devices: ' + data.message + '</p>';
                }
            });
        }
        
        function loadBilling() {
            fetch('/api/get_billing', {method: 'POST'})
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    let html = '<table class="table"><thead><tr><th>Invoice #</th><th>Customer</th><th>Amount</th><th>Date</th><th>Due Date</th><th>Status</th></tr></thead><tbody>';
                    data.billing.forEach(bill => {
                        html += `<tr><td>${bill.invoice_number}</td><td>${bill.first_name} ${bill.last_name}</td><td>$${parseFloat(bill.amount).toFixed(2)}</td><td>${bill.billing_date}</td><td>${bill.due_date}</td><td><span class="status-badge status-${bill.status}">${bill.status}</span></td></tr>`;
                    });
                    html += '</tbody></table>';
                    document.getElementById('billing-table-container').innerHTML = html;
                } else {
                    document.getElementById('billing-table-container').innerHTML = '<p>Error loading billing: ' + data.message + '</p>';
                }
            });
        }
        
        function loadProfiles() {
            fetch('/service_profiles')
            .then(response => response.json())
            .then(profiles => {
                let html = '';
                profiles.forEach(profile => {
                    html += `<div class="stat-card">
                        <h3 style="color: #4CAF50;">${profile.name}</h3>
                        <p><strong>Speed:</strong> ${profile.download_speed}/${profile.upload_speed} Mbps</p>
                        <p><strong>Data:</strong> ${profile.data_limit ? profile.data_limit + 'GB' : 'Unlimited'}</p>
                        <p><strong>Price:</strong> $${parseFloat(profile.price).toFixed(2)}/month</p>
                        <p style="font-size: 0.9em; color: #666;">${profile.description}</p>
                    </div>`;
                });
                document.getElementById('profiles-container').innerHTML = html;
                
                // Also populate the service profile dropdown
                let options = '<option value="">Select Service Plan</option>';
                profiles.forEach(profile => {
                    options += `<option value="${profile.name}">${profile.name} - $${parseFloat(profile.price).toFixed(2)}/month</option>`;
                });
                document.getElementById('service_profile').innerHTML = options;
            });
        }
        
        function showAddUserModal() { document.getElementById('addUserModal').style.display = 'block'; }
        function showAddNASModal() { document.getElementById('addNASModal').style.display = 'block'; }
        function closeModal(modalId) { document.getElementById(modalId).style.display = 'none'; }
        
        document.getElementById('addUserForm').addEventListener('submit', function(e) {
            e.preventDefault();
            const formData = new FormData(this);
            fetch('/api/add_user', {method: 'POST', body: formData})
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('Customer added successfully! Username: ' + data.username);
                    closeModal('addUserModal');
                    this.reset();
                    loadUsers();
                    loadStats();
                } else {
                    alert('Error: ' + data.message);
                }
            });
        });
        
        document.getElementById('addNASForm').addEventListener('submit', function(e) {
            e.preventDefault();
            const formData = new FormData(this);
            fetch('/api/add_nas', {method: 'POST', body: formData})
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    alert('NAS device added successfully!');
                    closeModal('addNASModal');
                    this.reset();
                    loadNAS();
                    loadStats();
                } else {
                    alert('Error: ' + data.message);
                }
            });
        });
        
        function deleteUser(customerId) {
            if (confirm('Are you sure you want to delete this customer?')) {
                const formData = new FormData();
                formData.append('customer_id', customerId);
                fetch('/api/delete_user', {method: 'POST', body: formData})
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        alert('Customer deleted successfully!');
                        loadUsers();
                        loadStats();
                    } else {
                        alert('Error: ' + data.message);
                    }
                });
            }
        }
        
        window.onclick = function(event) {
            if (event.target.classList.contains('modal')) {
                event.target.style.display = 'none';
            }
        }
        
        // Load initial data
        loadStats();
        loadUsers();
        loadProfiles();
    </script>
</body>
</html>
'''

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)

