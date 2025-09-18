# Complete Guide: Adding Customers & Configuring Billing Plans

## Overview

This guide will walk you through the complete process of adding new customers to your ISP RADIUS system and setting up billing plans. We'll cover both the database operations and web interface procedures.

## Part 1: Setting Up Service Profiles (Billing Plans)

### Step 1: Create Service Profiles in Database

First, let's create some standard service profiles that define bandwidth, data limits, and pricing:

```sql
-- Connect to the database
sudo -u postgres psql radiusdb

-- Create a table for service profiles
CREATE TABLE IF NOT EXISTS service_profiles (
    id SERIAL PRIMARY KEY,
    profile_name VARCHAR(50) UNIQUE NOT NULL,
    download_speed INTEGER NOT NULL, -- in Mbps
    upload_speed INTEGER NOT NULL,   -- in Mbps
    data_limit INTEGER,              -- in GB (NULL for unlimited)
    monthly_price DECIMAL(10,2) NOT NULL,
    billing_cycle VARCHAR(20) DEFAULT 'monthly',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample service profiles
INSERT INTO service_profiles (profile_name, download_speed, upload_speed, data_limit, monthly_price, description) VALUES
('Basic', 10, 2, 50, 29.99, 'Basic internet plan for light users'),
('Standard', 25, 5, 150, 49.99, 'Standard plan for regular home use'),
('Premium', 50, 10, 300, 79.99, 'Premium plan for heavy users'),
('Business', 100, 20, NULL, 149.99, 'Unlimited business plan'),
('Student', 15, 3, 75, 19.99, 'Discounted plan for students');

-- View the created profiles
SELECT * FROM service_profiles;
```

### Step 2: Configure RADIUS Attributes for Profiles

Now let's add the RADIUS attributes that will control bandwidth for each profile:

```sql
-- Add bandwidth control attributes for each profile
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
-- Basic Plan (10 Mbps down, 2 Mbps up)
('Basic', 'WISPr-Bandwidth-Max-Down', ':=', '10485760'),  -- 10 Mbps in bytes
('Basic', 'WISPr-Bandwidth-Max-Up', ':=', '2097152'),    -- 2 Mbps in bytes
('Basic', 'Session-Timeout', ':=', '86400'),             -- 24 hours

-- Standard Plan (25 Mbps down, 5 Mbps up)
('Standard', 'WISPr-Bandwidth-Max-Down', ':=', '26214400'), -- 25 Mbps
('Standard', 'WISPr-Bandwidth-Max-Up', ':=', '5242880'),    -- 5 Mbps
('Standard', 'Session-Timeout', ':=', '86400'),

-- Premium Plan (50 Mbps down, 10 Mbps up)
('Premium', 'WISPr-Bandwidth-Max-Down', ':=', '52428800'),  -- 50 Mbps
('Premium', 'WISPr-Bandwidth-Max-Up', ':=', '10485760'),    -- 10 Mbps
('Premium', 'Session-Timeout', ':=', '86400'),

-- Business Plan (100 Mbps down, 20 Mbps up)
('Business', 'WISPr-Bandwidth-Max-Down', ':=', '104857600'), -- 100 Mbps
('Business', 'WISPr-Bandwidth-Max-Up', ':=', '20971520'),    -- 20 Mbps
('Business', 'Session-Timeout', ':=', '86400'),

-- Student Plan (15 Mbps down, 3 Mbps up)
('Student', 'WISPr-Bandwidth-Max-Down', ':=', '15728640'),   -- 15 Mbps
('Student', 'WISPr-Bandwidth-Max-Up', ':=', '3145728'),      -- 3 Mbps
('Student', 'Session-Timeout', ':=', '86400');
```

## Part 2: Adding New Customers

### Step 1: Create Customer Information Table

```sql
-- Create a comprehensive customer table
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    service_profile VARCHAR(50) REFERENCES service_profiles(profile_name),
    installation_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'active',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Step 2: Add a New Customer (Example)

Let's add a sample customer:

```sql
-- Add customer information
INSERT INTO customers (
    customer_id, first_name, last_name, email, phone, 
    address, city, state, zip_code, service_profile
) VALUES (
    'CUST001', 'John', 'Smith', 'john.smith@email.com', '555-0123',
    '123 Main Street', 'Springfield', 'IL', '62701', 'Standard'
);

-- Create RADIUS user account for the customer
INSERT INTO radcheck (username, attribute, op, value) VALUES
('john.smith', 'Cleartext-Password', ':=', 'SecurePass123!');

-- Assign the customer to their service profile group
INSERT INTO radusergroup (username, groupname, priority) VALUES
('john.smith', 'Standard', 1);
```

### Step 3: Set Up Customer Billing

```sql
-- Create billing table
CREATE TABLE IF NOT EXISTS customer_billing (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(20) REFERENCES customers(customer_id),
    billing_cycle_start DATE NOT NULL,
    billing_cycle_end DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    due_date DATE NOT NULL,
    paid_date DATE,
    payment_method VARCHAR(50),
    invoice_number VARCHAR(50) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create first billing cycle for the customer
INSERT INTO customer_billing (
    customer_id, billing_cycle_start, billing_cycle_end, 
    amount, due_date, invoice_number
) VALUES (
    'CUST001', 
    CURRENT_DATE, 
    CURRENT_DATE + INTERVAL '1 month',
    49.99,
    CURRENT_DATE + INTERVAL '15 days',
    'INV-' || TO_CHAR(CURRENT_DATE, 'YYYYMM') || '-001'
);
```

## Part 3: Using the Web Interface

### Step 1: Access the Web Interface

1. **Start the React application:**
   ```bash
   cd /home/ubuntu/isp-radius-interface
   npm start
   ```

2. **Open browser and navigate to:** `http://localhost:3000`

3. **Login with credentials:**
   - Username: `admin`
   - Password: `admin`

### Step 2: Navigate to User Management

1. Click on **"Users"** in the sidebar
2. Select **"Users List"** to see existing users
3. Click the **"Add User"** button

### Step 3: Add New Customer via Web Interface

Fill out the user creation form:

**Basic Information:**
- Username: `jane.doe`
- Password: `SecurePass456!`
- First Name: `Jane`
- Last Name: `Doe`
- Email: `jane.doe@email.com`

**Service Configuration:**
- Profile: Select `Premium` from dropdown
- Expiration Date: Set to one month from today
- Status: `Active`

**Contact Information:**
- Phone: `555-0456`
- Address: `456 Oak Avenue, Springfield, IL 62702`

### Step 4: Configure Billing Plan

1. Navigate to **"Profiles"** section
2. View existing service profiles
3. Assign customer to appropriate profile
4. Set billing cycle and payment terms

## Part 4: Advanced Customer Management

### Step 1: Create Customer with Custom Attributes

```sql
-- Add customer with special requirements
INSERT INTO customers (
    customer_id, first_name, last_name, email, phone,
    address, city, state, zip_code, service_profile, notes
) VALUES (
    'CUST002', 'Business', 'Corp', 'admin@businesscorp.com', '555-0789',
    '789 Business Blvd', 'Springfield', 'IL', '62703', 'Business',
    'Corporate account - requires static IP and priority support'
);

-- Create RADIUS account
INSERT INTO radcheck (username, attribute, op, value) VALUES
('business.corp', 'Cleartext-Password', ':=', 'CorpPass789!');

-- Assign to business profile
INSERT INTO radusergroup (username, groupname, priority) VALUES
('business.corp', 'Business', 1);

-- Add static IP assignment
INSERT INTO radreply (username, attribute, op, value) VALUES
('business.corp', 'Framed-IP-Address', ':=', '192.168.100.50');
```

### Step 2: Set Up Automated Billing

```sql
-- Create a function for automatic billing generation
CREATE OR REPLACE FUNCTION generate_monthly_bills()
RETURNS void AS $$
DECLARE
    customer_record RECORD;
    new_invoice_number VARCHAR(50);
BEGIN
    FOR customer_record IN 
        SELECT c.customer_id, c.service_profile, sp.monthly_price
        FROM customers c
        JOIN service_profiles sp ON c.service_profile = sp.profile_name
        WHERE c.status = 'active'
    LOOP
        -- Generate invoice number
        new_invoice_number := 'INV-' || TO_CHAR(CURRENT_DATE, 'YYYYMM') || '-' || 
                             LPAD(customer_record.customer_id::text, 3, '0');
        
        -- Insert billing record
        INSERT INTO customer_billing (
            customer_id, billing_cycle_start, billing_cycle_end,
            amount, due_date, invoice_number
        ) VALUES (
            customer_record.customer_id,
            CURRENT_DATE,
            CURRENT_DATE + INTERVAL '1 month',
            customer_record.monthly_price,
            CURRENT_DATE + INTERVAL '15 days',
            new_invoice_number
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

## Part 5: Testing Customer Authentication

### Step 1: Test RADIUS Authentication

```bash
# Test the new customer authentication
radtest john.smith SecurePass123! localhost 1812 testing123

# Expected output should show Access-Accept
```

### Step 2: Monitor Customer Sessions

```sql
-- View active sessions
SELECT username, nasipaddress, acctstarttime, acctinputoctets, acctoutputoctets
FROM radacct 
WHERE acctstoptime IS NULL;

-- View customer usage statistics
SELECT 
    username,
    SUM(acctinputoctets + acctoutputoctets) as total_bytes,
    COUNT(*) as session_count,
    MAX(acctstarttime) as last_session
FROM radacct 
WHERE username = 'john.smith'
GROUP BY username;
```

## Part 6: Billing Management

### Step 1: Generate Invoices

```sql
-- View pending invoices
SELECT 
    cb.invoice_number,
    c.first_name || ' ' || c.last_name as customer_name,
    cb.amount,
    cb.due_date,
    cb.status
FROM customer_billing cb
JOIN customers c ON cb.customer_id = c.customer_id
WHERE cb.status = 'pending'
ORDER BY cb.due_date;
```

### Step 2: Process Payments

```sql
-- Mark invoice as paid
UPDATE customer_billing 
SET status = 'paid', 
    paid_date = CURRENT_DATE,
    payment_method = 'credit_card'
WHERE invoice_number = 'INV-202509-001';
```

### Step 3: Handle Overdue Accounts

```sql
-- Find overdue accounts
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    cb.amount,
    cb.due_date,
    CURRENT_DATE - cb.due_date as days_overdue
FROM customer_billing cb
JOIN customers c ON cb.customer_id = c.customer_id
WHERE cb.status = 'pending' 
AND cb.due_date < CURRENT_DATE
ORDER BY days_overdue DESC;

-- Suspend overdue customers
UPDATE customers 
SET status = 'suspended'
WHERE customer_id IN (
    SELECT customer_id 
    FROM customer_billing 
    WHERE status = 'pending' 
    AND due_date < CURRENT_DATE - INTERVAL '30 days'
);
```

## Part 7: Web Interface Workflow

### Complete Customer Onboarding Process:

1. **Customer Information Entry**
   - Navigate to Users → Add User
   - Fill customer details form
   - Select appropriate service profile
   - Set account expiration date

2. **Service Configuration**
   - Go to Profiles section
   - Verify bandwidth settings
   - Configure any special attributes
   - Set data quotas if applicable

3. **Billing Setup**
   - Navigate to Billing section
   - Create initial invoice
   - Set payment terms
   - Configure automatic billing

4. **Account Activation**
   - Test RADIUS authentication
   - Verify bandwidth limits
   - Confirm billing cycle
   - Send welcome email to customer

### Monitoring and Management:

1. **Dashboard Overview**
   - Monitor active users
   - Track revenue metrics
   - View system health

2. **User Management**
   - Search and filter customers
   - Bulk operations for updates
   - Status management

3. **Billing Operations**
   - Generate invoices
   - Process payments
   - Handle disputes

4. **Reports and Analytics**
   - Usage reports
   - Revenue analysis
   - Customer analytics

## Part 8: Best Practices

### Security Considerations:
- Use strong passwords for all accounts
- Implement regular password changes
- Monitor for unusual usage patterns
- Keep audit logs of all changes

### Billing Best Practices:
- Send invoices 15 days before due date
- Offer multiple payment methods
- Implement grace periods for late payments
- Automate suspension/reactivation processes

### Customer Service:
- Maintain detailed customer notes
- Track support interactions
- Monitor service quality metrics
- Implement customer feedback systems

This comprehensive guide provides everything you need to add customers and manage billing in your ISP RADIUS system. The combination of database operations and web interface provides flexibility for both automated and manual processes.

