# Complete ISP RADIUS System Installation Guide

## Overview

This guide covers the complete installation of the ISP RADIUS & Billing Management System using the all-in-one installer script. This single command installs everything you need to run a professional ISP business.

## What Gets Installed

### Core System Components
- **PostgreSQL Database** - Customer data and authentication storage
- **FreeRADIUS Server** - Authentication and accounting on ports 1812/1813
- **Redis Cache** - Performance optimization and session management
- **Nginx Web Server** - Professional web interface hosting

### Admin Dashboard
- **Professional Interface** - Modern web-based management on port 8080
- **User Management** - Complete customer lifecycle management
- **Real-time Monitoring** - Online user tracking and system health
- **NAS Management** - Network device configuration and monitoring
- **Service Profiles** - Bandwidth plans and pricing management
- **Billing System** - Automated invoicing and revenue tracking
- **Reports & Analytics** - Business intelligence and usage statistics
- **System Settings** - Complete configuration management

### Pre-configured Data
- **5 Service Plans** - Student, Basic, Standard, Premium, Business
- **Sample Customers** - 3 test customer accounts
- **Bandwidth Controls** - Speed limits for each service plan
- **Test User** - For RADIUS authentication testing

## Installation Command

```bash
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/scripts/complete_fresh_install.sh && chmod +x complete_fresh_install.sh && ./complete_fresh_install.sh
```

## Installation Process

### 1. System Preparation
- Updates Ubuntu packages
- Installs required dependencies
- Configures firewall rules
- Sets up system users and permissions

### 2. Database Setup
- Installs and configures PostgreSQL
- Creates `radiusdb` database
- Creates `radiususer` with secure password
- Imports FreeRADIUS schema with multiple fallback methods
- Creates ISP management tables (customers, billing, service_profiles, nas_devices)

### 3. RADIUS Configuration
- Installs and configures FreeRADIUS
- Sets up PostgreSQL integration
- Configures authentication and accounting
- Creates bandwidth control groups
- Sets up test users and sample customers

### 4. Web Interface Setup
- Installs and configures Nginx
- Creates professional admin dashboard
- Sets up security headers and SSL support
- Configures responsive design for all devices

### 5. Service Integration
- Starts and enables all services
- Configures automatic startup
- Tests system connectivity
- Validates RADIUS authentication

## Installation Prompts

During installation, you'll be prompted for:

1. **Database Password** - Secure password for the RADIUS database user
2. **Domain Name** (Optional) - For SSL certificate configuration
3. **Email Address** (Optional) - For SSL certificate registration

## Post-Installation Access

### Admin Dashboard
- **URL**: `http://your-server-ip:8080`
- **Features**: Complete ISP management interface
- **Mobile**: Responsive design works on all devices

### RADIUS Server
- **Authentication**: `your-server-ip:1812`
- **Accounting**: `your-server-ip:1813`
- **Database**: `localhost:5432` (radiusdb)

### Test Credentials
- **Username**: testuser
- **Password**: testpass

## Sample Data Included

### Service Plans
1. **Student**: 15/3 Mbps, 75GB, $19.99/month
2. **Basic**: 10/2 Mbps, 50GB, $29.99/month
3. **Standard**: 25/5 Mbps, 150GB, $49.99/month
4. **Premium**: 50/10 Mbps, 300GB, $79.99/month
5. **Business**: 100/20 Mbps, Unlimited, $149.99/month

### Sample Customers
1. **john.smith** - Standard Plan
2. **jane.doe** - Premium Plan
3. **tech.solutions** - Business Plan

## Testing Your Installation

### 1. RADIUS Authentication Test
```bash
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123
```
Expected result: `Access-Accept`

### 2. Database Connection Test
```bash
sudo -u postgres psql radiusdb -c "SELECT COUNT(*) FROM service_profiles;"
```
Expected result: `5` (service profiles)

### 3. Web Interface Test
Open browser to `http://your-server-ip:8080`
Expected result: Professional admin dashboard

### 4. Service Status Check
```bash
sudo systemctl status postgresql freeradius redis-server nginx
```
Expected result: All services active (running)

## Next Steps After Installation

### 1. Configure Network Equipment
- Add your routers/switches as NAS clients
- Configure shared secrets for authentication
- Point devices to your RADIUS server

### 2. Add Real Customers
- Use the admin dashboard to create customer accounts
- Assign appropriate service plans
- Generate usernames and passwords

### 3. Monitor System Performance
- Use the dashboard for real-time monitoring
- Check system health indicators
- Monitor revenue and usage statistics

### 4. Customize for Your Business
- Modify service plans and pricing
- Update branding and colors
- Configure SSL certificates for security

## Troubleshooting

### Common Issues

#### Database Connection Failed
```bash
sudo systemctl restart postgresql
sudo -u postgres psql radiusdb -c "\dt"
```

#### RADIUS Authentication Failed
```bash
sudo systemctl restart freeradius
sudo freeradius -X  # Debug mode
```

#### Web Interface Not Accessible
```bash
sudo systemctl restart nginx
sudo nginx -t  # Test configuration
```

#### Firewall Blocking Access
```bash
sudo ufw status
sudo ufw allow 8080/tcp
```

### Log Files
- **Installation**: `/var/log/isp-radius-install.log`
- **FreeRADIUS**: `/var/log/freeradius/radius.log`
- **Nginx**: `/var/log/nginx/access.log`
- **PostgreSQL**: `/var/log/postgresql/postgresql-*.log`

## Security Considerations

### Default Security Features
- **Firewall**: UFW enabled with specific port access
- **Database**: Isolated user with limited privileges
- **Web**: Security headers and XSS protection
- **RADIUS**: Shared secret authentication

### Recommended Security Enhancements
1. **Change Default Passwords** - Update all default credentials
2. **SSL Certificates** - Enable HTTPS for web interface
3. **Network Segmentation** - Isolate RADIUS traffic
4. **Regular Updates** - Keep system packages current
5. **Backup Strategy** - Regular database and configuration backups

## Performance Optimization

### Database Optimization
- Regular VACUUM and ANALYZE operations
- Index optimization for large customer bases
- Connection pooling for high traffic

### RADIUS Optimization
- Tune SQL connection pools
- Optimize authentication queries
- Monitor response times

### Web Interface Optimization
- Enable Nginx caching
- Compress static assets
- Use CDN for external resources

## Scaling Your ISP Business

### Customer Growth
- System supports thousands of customers
- Database can handle millions of authentication requests
- Web interface scales with concurrent admin users

### Geographic Expansion
- Add multiple NAS devices across locations
- Implement redundant RADIUS servers
- Use database replication for high availability

### Service Expansion
- Add new service plans easily
- Implement usage-based billing
- Integrate with external payment systems

## Support and Maintenance

### Regular Maintenance Tasks
1. **Database Cleanup** - Remove old accounting records
2. **Log Rotation** - Manage log file sizes
3. **Security Updates** - Apply system patches
4. **Backup Verification** - Test restore procedures

### Monitoring Recommendations
- Set up automated health checks
- Monitor disk space and memory usage
- Track authentication success rates
- Monitor customer growth and revenue

## Business Benefits

### Operational Efficiency
- **Automated Processes** - Reduce manual work
- **Real-time Monitoring** - Immediate issue detection
- **Professional Interface** - Improved customer confidence
- **Scalable Architecture** - Grow without system changes

### Revenue Optimization
- **Flexible Pricing** - Multiple service tiers
- **Automated Billing** - Reduce collection costs
- **Usage Analytics** - Optimize service offerings
- **Customer Insights** - Improve retention

### Competitive Advantage
- **Professional Image** - Modern management tools
- **Reliable Service** - Guaranteed bandwidth allocation
- **Quick Support** - Integrated monitoring and troubleshooting
- **Cost Effective** - No licensing fees or vendor lock-in

This complete installation provides everything needed to run a professional ISP business with modern management tools and scalable architecture.

