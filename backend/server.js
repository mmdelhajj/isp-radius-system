const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Database connection
const pool = new Pool({
  user: process.env.DB_USER || 'radiususer',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'radiusdb',
  password: process.env.DB_PASSWORD || 'your_secure_password_here',
  port: process.env.DB_PORT || 5432,
});

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined'));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Get all service profiles
app.get('/api/service-profiles', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM service_profiles ORDER BY price ASC');
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching service profiles:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all customers
app.get('/api/customers', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT c.*, sp.price, sp.download_speed, sp.upload_speed, sp.data_quota
      FROM customers c
      LEFT JOIN service_profiles sp ON c.service_profile = sp.name
      ORDER BY c.created_at DESC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching customers:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Add new customer
app.post('/api/customers', async (req, res) => {
  const {
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    address,
    city,
    state,
    zip_code,
    service_profile,
    username,
    password,
    notes
  } = req.body;

  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // Insert customer
    await client.query(`
      INSERT INTO customers (
        customer_id, first_name, last_name, email, phone, address, 
        city, state, zip_code, service_profile, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
    `, [customer_id, first_name, last_name, email, phone, address, city, state, zip_code, service_profile, notes]);

    // Add RADIUS authentication
    await client.query(`
      INSERT INTO radcheck (username, attribute, op, value) 
      VALUES ($1, 'Cleartext-Password', ':=', $2)
    `, [username, password]);

    // Add user to service group
    await client.query(`
      INSERT INTO radusergroup (username, groupname, priority) 
      VALUES ($1, $2, 1)
    `, [username, service_profile]);

    // Get service profile price for billing
    const profileResult = await client.query(
      'SELECT price FROM service_profiles WHERE name = $1',
      [service_profile]
    );

    if (profileResult.rows.length > 0) {
      const price = profileResult.rows[0].price;
      const invoiceNumber = `INV-${new Date().getFullYear()}${(new Date().getMonth() + 1).toString().padStart(2, '0')}-${customer_id.replace('CUST', '')}`;
      
      // Create first billing record
      await client.query(`
        INSERT INTO customer_billing (
          customer_id, billing_cycle_start, billing_cycle_end, 
          amount, due_date, invoice_number
        ) VALUES ($1, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month', $2, CURRENT_DATE + INTERVAL '15 days', $3)
      `, [customer_id, price, invoiceNumber]);
    }

    await client.query('COMMIT');
    res.json({ message: 'Customer added successfully', customer_id });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Error adding customer:', err);
    res.status(500).json({ error: 'Failed to add customer' });
  } finally {
    client.release();
  }
});

// Get customer billing
app.get('/api/customers/:id/billing', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM customer_billing WHERE customer_id = $1 ORDER BY created_at DESC',
      [req.params.id]
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching billing:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get dashboard statistics
app.get('/api/dashboard/stats', async (req, res) => {
  try {
    const customerCount = await pool.query('SELECT COUNT(*) FROM customers WHERE status = $1', ['active']);
    const totalRevenue = await pool.query(`
      SELECT COALESCE(SUM(sp.price), 0) as total
      FROM customers c
      JOIN service_profiles sp ON c.service_profile = sp.name
      WHERE c.status = 'active'
    `);
    const pendingBills = await pool.query('SELECT COUNT(*) FROM customer_billing WHERE status = $1', ['pending']);
    
    res.json({
      total_customers: parseInt(customerCount.rows[0].count),
      monthly_revenue: parseFloat(totalRevenue.rows[0].total),
      pending_bills: parseInt(pendingBills.rows[0].count),
      active_services: parseInt(customerCount.rows[0].count)
    });
  } catch (err) {
    console.error('Error fetching dashboard stats:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Test database connection
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ 
      status: 'Database connected successfully', 
      timestamp: result.rows[0].now 
    });
  } catch (err) {
    console.error('Database connection error:', err);
    res.status(500).json({ error: 'Database connection failed' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`ISP RADIUS Backend API running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
});

module.exports = app;

