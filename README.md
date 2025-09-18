# ISP RADIUS & Billing Management System

A complete, production-ready ISP RADIUS authentication and billing management system built with modern web technologies.

## 🌟 Features

### Core Functionality
- **RADIUS Authentication Server** - FreeRADIUS with PostgreSQL integration
- **Customer Management** - Complete customer lifecycle management
- **Billing System** - Automated invoicing and payment tracking
- **Service Plans** - Flexible bandwidth and pricing tiers
- **Web Interface** - Modern React-based management dashboard
- **Real-time Monitoring** - System health and customer usage tracking

### Technical Stack
- **Backend**: PostgreSQL 15, FreeRADIUS 3.0, Redis 6.0
- **Frontend**: React 18, TypeScript, Material-UI
- **Server**: Node.js 18, Nginx, Ubuntu 22.04 LTS
- **Security**: SSL/TLS, UFW Firewall, Encrypted passwords

## 🚀 Quick Start

### One-Command Installation
```bash
wget https://raw.githubusercontent.com/mmdelhajj/isp-radius-system/main/quick_install.sh && chmod +x quick_install.sh && ./quick_install.sh
```

### Manual Installation
See [Installation Guide](docs/installation-guide.md) for detailed step-by-step instructions.

## 📋 System Requirements

### Minimum Requirements
- **OS**: Ubuntu Server 22.04 LTS
- **CPU**: 2 cores
- **RAM**: 4GB
- **Storage**: 50GB SSD
- **Network**: Static IP recommended

### Recommended Requirements
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Storage**: 100GB+ SSD
- **Network**: 1Gbps with static IP

## 🎯 Service Plans

The system comes with 5 pre-configured service plans:

| Plan | Speed | Data Quota | Price | Target |
|------|-------|------------|-------|---------|
| Student | 15/3 Mbps | 75GB | $19.99 | Students & light users |
| Basic | 10/2 Mbps | 50GB | $29.99 | Essential internet |
| Standard | 25/5 Mbps | 150GB | $49.99 | Families & streaming |
| Premium | 50/10 Mbps | 300GB | $79.99 | Power users |
| Business | 100/20 Mbps | Unlimited | $149.99 | Business grade |

## 🖥️ Web Interface

### Customer Management
- Add, edit, and manage customer accounts
- Real-time service status monitoring
- Automated billing and invoicing
- Usage tracking and reporting

### Dashboard Features
- Customer overview and statistics
- Revenue tracking and analytics
- System health monitoring
- Service plan management

### Screenshots
![Dashboard](docs/images/dashboard.png)
![Customer Management](docs/images/customer-management.png)

## 📚 Documentation

- [Installation Guide](docs/installation-guide.md) - Complete setup instructions
- [Configuration Guide](docs/configuration-guide.md) - System configuration
- [User Manual](docs/user-manual.md) - Web interface usage
- [API Documentation](docs/api-documentation.md) - Backend API reference
- [Troubleshooting](docs/troubleshooting.md) - Common issues and solutions

## 🔧 Configuration

### Network Equipment Setup
Configure your routers/switches to use the RADIUS server:

```bash
# Example for MikroTik RouterOS
/radius add service=ppp address=YOUR_RADIUS_SERVER_IP secret=testing123
/ppp profile set default use-radius=yes

# Example for Cisco
aaa new-model
radius-server host YOUR_RADIUS_SERVER_IP auth-port 1812 acct-port 1813 key testing123
aaa authentication ppp default group radius local
```

### Adding RADIUS Clients
```sql
INSERT INTO nas (nasname, shortname, type, ports, secret, server, community, description) VALUES
('192.168.1.1', 'main-router', 'other', NULL, 'testing123', NULL, NULL, 'Main ISP Router');
```

## 🧪 Testing

### RADIUS Authentication Test
```bash
echo "User-Name = testuser, User-Password = testpass" | radclient localhost:1812 auth testing123
```

### Service Status Check
```bash
sudo systemctl status postgresql freeradius redis-server nginx
```

## 🔐 Security Features

- **Encrypted Passwords** - Secure password storage
- **Firewall Configuration** - UFW with minimal required ports
- **SSL/TLS Support** - HTTPS encryption for web interface
- **Database Security** - PostgreSQL with restricted access
- **Session Management** - Redis-based session handling

## 📊 Monitoring & Analytics

### Real-time Metrics
- Active customer sessions
- Bandwidth usage statistics
- Revenue tracking
- System performance monitoring

### Reporting Features
- Customer usage reports
- Financial analytics
- Service performance metrics
- Custom report generation

## 🔄 Backup & Recovery

Automated daily backups include:
- PostgreSQL database dumps
- Configuration files
- System logs
- 30-day retention policy

## 🚀 Deployment Options

### Development Environment
```bash
cd frontend
npm install
npm start

cd ../backend
npm install
npm run dev
```

### Production Deployment
- Automated installation script
- Docker containerization support
- Nginx reverse proxy configuration
- SSL certificate automation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check the [docs](docs/) directory
- **Issues**: Report bugs via [GitHub Issues](https://github.com/mmdelhajj/isp-radius-system/issues)
- **Discussions**: Join [GitHub Discussions](https://github.com/mmdelhajj/isp-radius-system/discussions)

## 🎯 Roadmap

### Version 2.0 (Planned)
- [ ] Customer self-service portal
- [ ] Mobile application
- [ ] Advanced analytics dashboard
- [ ] Multi-tenant support
- [ ] API rate limiting
- [ ] Automated network provisioning

### Version 1.1 (Current)
- [x] Complete RADIUS authentication
- [x] Customer management system
- [x] Billing and invoicing
- [x] Web-based administration
- [x] Service plan management
- [x] Real-time monitoring

## 🏆 Acknowledgments

- FreeRADIUS community for the robust authentication server
- PostgreSQL team for the reliable database system
- React community for the modern frontend framework
- Material-UI for the professional component library

## 📈 Business Benefits

### For ISP Operators
- **Reduced Costs**: No monthly licensing fees
- **Complete Control**: Full system ownership and customization
- **Scalability**: Handle thousands of customers
- **Professional Image**: Modern, competitive interface

### For Customers
- **Reliable Service**: Industry-standard RADIUS authentication
- **Transparent Billing**: Clear invoicing and usage tracking
- **Self-Service**: Account management capabilities
- **Quality Support**: Integrated ticketing system

---

**Built with ❤️ for ISP operators worldwide**

*Transform your ISP business with professional-grade customer management and billing automation.*

