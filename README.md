# ISP RADIUS & Billing Management System

A complete, production-ready ISP RADIUS authentication and billing management system with professional web interface.

## 🎯 Features

- **Complete RADIUS Authentication** - FreeRADIUS with PostgreSQL integration
- **Professional Admin Dashboard** - Modern web interface for complete system management
- **Customer Management** - Full CRUD operations with service plan assignments
- **Real-time Monitoring** - Online user tracking and session management
- **Billing System** - Automated invoicing and revenue tracking
- **NAS Management** - Network device configuration and monitoring
- **Service Profiles** - Bandwidth control and pricing management
- **Reports & Analytics** - Business intelligence and performance metrics
- **System Settings** - Complete configuration management

## 🚀 One-Command Installation

**Complete System Installation (Everything Included):**
```bash
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/scripts/complete_fresh_install.sh && chmod +x complete_fresh_install.sh && ./complete_fresh_install.sh
```

**Alternative Installation Commands:**

**RADIUS System Only:**
```bash
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/scripts/fresh_install_v2.sh && chmod +x fresh_install_v2.sh && ./fresh_install_v2.sh
```

**Admin Dashboard Only:**
```bash
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/scripts/create_admin_dashboard.sh && chmod +x create_admin_dashboard.sh && ./create_admin_dashboard.sh
```

**Fix Installation Issues:**
```bash
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/scripts/fix_current_installation.sh && chmod +x fix_current_installation.sh && ./fix_current_installation.sh
```

## 📋 System Requirements

- **OS**: Ubuntu Server 22.04 LTS
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 50GB minimum
- **User**: Non-root user with sudo privileges

## 🎯 What You Get

### Core System
- **PostgreSQL Database** - Customer and authentication data
- **FreeRADIUS Server** - Authentication on ports 1812/1813
- **Redis Cache** - Performance optimization
- **Nginx Web Server** - Professional web interface

### Admin Dashboard
- **Dashboard Overview** - Real-time business metrics
- **User Management** - Complete customer lifecycle management
- **Online Users** - Real-time session monitoring with disconnect control
- **NAS Management** - Network device configuration and health monitoring
- **Service Profiles** - Bandwidth plans and pricing management
- **Billing Management** - Invoice generation and revenue tracking
- **Reports & Analytics** - Business intelligence and usage statistics
- **System Settings** - RADIUS and database configuration
- **System Logs** - Real-time monitoring and troubleshooting

### Service Plans (Pre-configured)
1. **Student**: 15/3 Mbps, 75GB, $19.99/month
2. **Basic**: 10/2 Mbps, 50GB, $29.99/month
3. **Standard**: 25/5 Mbps, 150GB, $49.99/month
4. **Premium**: 50/10 Mbps, 300GB, $79.99/month
5. **Business**: 100/20 Mbps, Unlimited, $149.99/month

## 🌐 Access Points

- **Admin Dashboard**: `http://your-server-ip:8080`
- **RADIUS Server**: `your-server-ip:1812` (Authentication)
- **RADIUS Accounting**: `your-server-ip:1813` (Accounting)
- **Database**: `localhost:5432` (PostgreSQL)

## 📚 Documentation

- [Admin Dashboard Guide](docs/admin-dashboard-guide.md) - Complete dashboard documentation
- [Installation Issues Resolved](docs/installation-issues-resolved.md) - Troubleshooting guide
- [Common Errors Guide](docs/common-errors.md) - Specific error solutions

## 🔧 Installation Scripts

- `fresh_install_v2.sh` - Latest complete installation (Recommended)
- `create_admin_dashboard.sh` - Install professional admin interface
- `fix_current_installation.sh` - Fix common installation issues
- `manual_schema_import.sh` - Alternative database setup

## 🎯 Business Benefits

### Operational Efficiency
- **Automated Processes** - Reduce manual billing and provisioning
- **Real-time Monitoring** - Immediate visibility into system status
- **Professional Interface** - Modern dashboard builds customer confidence
- **Scalable Architecture** - Handle thousands of customers

### Revenue Optimization
- **Flexible Pricing** - Multiple service tiers and billing cycles
- **Automated Billing** - Reduced collection costs and errors
- **Upselling Tools** - Easy plan upgrades and add-ons
- **Financial Reporting** - Comprehensive revenue analytics

### Customer Experience
- **Reliable Service** - Guaranteed bandwidth allocation
- **Transparent Billing** - Clear invoices and usage tracking
- **Quick Support** - Integrated monitoring and troubleshooting
- **Professional Image** - Competitive advantage in the market

## 🛠️ Technical Stack

- **Backend**: FreeRADIUS 3.0, PostgreSQL 15, Redis 6.0
- **Frontend**: HTML5, CSS3, JavaScript, Font Awesome
- **Web Server**: Nginx with security headers
- **Languages**: Python 3.11, Bash scripting
- **Security**: XSS protection, CSRF prevention, secure headers

## 📊 Performance

- **Authentication**: Sub-second RADIUS response times
- **Dashboard**: < 2 second load times
- **Concurrent Users**: 100+ simultaneous admin sessions
- **Database**: Optimized queries for real-time updates
- **Scalability**: Supports thousands of customers

## 🔒 Security Features

- **Secure Authentication** - RADIUS with shared secrets
- **Database Security** - Encrypted connections and user isolation
- **Web Security** - XSS protection, content security policy
- **Network Security** - Firewall rules and access control
- **Data Protection** - Secure password handling and storage

## 📈 Business Model

This system supports multiple ISP business models:
- **Residential ISP** - Home internet service provider
- **Business ISP** - Corporate internet solutions
- **WISP** - Wireless internet service provider
- **Hotspot Provider** - Public WiFi and access control
- **Campus Network** - University or corporate campus internet

## 🎯 Next Steps After Installation

1. **Configure Network Equipment** - Point routers/switches to RADIUS server
2. **Add Customers** - Use admin dashboard to create user accounts
3. **Monitor Performance** - Use dashboard for business insights
4. **Customize Branding** - Modify interface to match your ISP brand
5. **Scale Operations** - Add more NAS devices and service plans

## 📞 Support

For technical support, customization requests, or business inquiries:
- **GitHub Issues**: https://github.com/mmdelhajj/isp-radius-system/issues
- **Documentation**: Complete guides available in `/docs` directory
- **Community**: Share experiences and get help from other ISP operators

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🎉 Success Stories

This system is production-ready and provides everything needed to:
- Start a new ISP business
- Upgrade from manual customer management
- Replace expensive commercial solutions
- Scale operations efficiently
- Provide professional customer service

**Ready to transform your ISP business? Install now and start managing customers professionally!**

