import React from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  LinearProgress,
  Chip,
} from '@mui/material';
import {
  People as PeopleIcon,
  PersonOnline as OnlineIcon,
  CheckCircle as ActiveIcon,
  Cancel as ExpiredIcon,
  Warning as ExpiringIcon,
  AttachMoney as MoneyIcon,
  Computer as SystemIcon,
  Storage as StorageIcon,
  Memory as MemoryIcon,
  Speed as SpeedIcon,
} from '@mui/icons-material';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

// Mock data
const subscribersData = {
  total: 30,
  online: 0,
  active: 10,
  expired: 20,
  expiringToday: 2,
  aboutToExpire: 0,
  onlineFUP: 0,
  managers: 16,
};

const financeData = {
  balance: 33355421628.00,
  rewardPoints: 0,
  activationsToday: 0,
  registrationsToday: 2,
  outstandingDebts: 0.00,
  outstandingClaims: 0.00,
};

const systemHealth = {
  uptime: '1321 days 5 hours 4 min',
  backupDisk: 'None, using system disk',
  networkStatus: 'Internet Reachable',
  databaseTime: '2025-09-18 04:14:05',
  timeZone: 'Asia/Baghdad',
  systemVersion: '4.54.2',
  licenseStatus: 'active',
};

const onlineUsersData = [
  { time: '00:00', users: 15 },
  { time: '04:00', users: 12 },
  { time: '08:00', users: 18 },
  { time: '12:00', users: 25 },
  { time: '16:00', users: 22 },
  { time: '20:00', users: 20 },
  { time: '24:00', users: 15 },
];

const systemUsageData = [
  { name: 'CPU', value: 35, color: '#3498db' },
  { name: 'Memory', value: 68, color: '#e74c3c' },
  { name: 'Disk', value: 45, color: '#f39c12' },
];

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ReactElement;
  color: string;
  subtitle?: string;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, icon, color, subtitle }) => (
  <Card sx={{ height: '100%' }}>
    <CardContent>
      <Box display="flex" alignItems="center" justifyContent="space-between">
        <Box>
          <Typography color="textSecondary" gutterBottom variant="h6">
            {title}
          </Typography>
          <Typography variant="h4" component="div" sx={{ color }}>
            {typeof value === 'number' ? value.toLocaleString() : value}
          </Typography>
          {subtitle && (
            <Typography variant="body2" color="textSecondary">
              {subtitle}
            </Typography>
          )}
        </Box>
        <Box sx={{ color, fontSize: 40 }}>
          {icon}
        </Box>
      </Box>
    </CardContent>
  </Card>
);

const Dashboard: React.FC = () => {
  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>
      
      <Grid container spacing={3}>
        {/* Subscribers Overview */}
        <Grid item xs={12}>
          <Typography variant="h6" gutterBottom sx={{ mt: 2 }}>
            Subscribers Overview
          </Typography>
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Users"
            value={subscribersData.total}
            icon={<PeopleIcon />}
            color="#3498db"
          />
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Online Users"
            value={subscribersData.online}
            icon={<OnlineIcon />}
            color="#2ecc71"
          />
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Active Users"
            value={subscribersData.active}
            icon={<ActiveIcon />}
            color="#27ae60"
          />
        </Grid>
        
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Expired Users"
            value={subscribersData.expired}
            icon={<ExpiredIcon />}
            color="#e74c3c"
          />
        </Grid>

        {/* Finance & Sales */}
        <Grid item xs={12}>
          <Typography variant="h6" gutterBottom sx={{ mt: 3 }}>
            Finance & Sales
          </Typography>
        </Grid>
        
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Balance"
            value={`$${financeData.balance.toLocaleString()}`}
            icon={<MoneyIcon />}
            color="#f39c12"
          />
        </Grid>
        
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Activations Today"
            value={financeData.activationsToday}
            icon={<ActiveIcon />}
            color="#9b59b6"
          />
        </Grid>
        
        <Grid item xs={12} sm={6} md={4}>
          <StatCard
            title="Registrations Today"
            value={financeData.registrationsToday}
            icon={<PeopleIcon />}
            color="#1abc9c"
          />
        </Grid>

        {/* Online Users Chart */}
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Online Users Trend
              </Typography>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={onlineUsersData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="time" />
                  <YAxis />
                  <Tooltip />
                  <Line type="monotone" dataKey="users" stroke="#3498db" strokeWidth={2} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>
        </Grid>

        {/* System Health */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                System Health
              </Typography>
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="textSecondary">
                  Uptime
                </Typography>
                <Typography variant="body1">
                  {systemHealth.uptime}
                </Typography>
              </Box>
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="textSecondary">
                  Network Status
                </Typography>
                <Chip 
                  label={systemHealth.networkStatus} 
                  color="success" 
                  size="small" 
                />
              </Box>
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" color="textSecondary">
                  License Status
                </Typography>
                <Chip 
                  label={systemHealth.licenseStatus} 
                  color="success" 
                  size="small" 
                />
              </Box>
              <Box>
                <Typography variant="body2" color="textSecondary">
                  System Version
                </Typography>
                <Typography variant="body1">
                  {systemHealth.systemVersion}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* System Usage */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                CPU Load
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <SpeedIcon sx={{ mr: 1, color: '#3498db' }} />
                <Typography variant="body2">35%</Typography>
              </Box>
              <LinearProgress variant="determinate" value={35} sx={{ mb: 2 }} />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Memory Usage
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <MemoryIcon sx={{ mr: 1, color: '#e74c3c' }} />
                <Typography variant="body2">68%</Typography>
              </Box>
              <LinearProgress 
                variant="determinate" 
                value={68} 
                sx={{ mb: 2, '& .MuiLinearProgress-bar': { backgroundColor: '#e74c3c' } }} 
              />
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Disk Usage
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <StorageIcon sx={{ mr: 1, color: '#f39c12' }} />
                <Typography variant="body2">45%</Typography>
              </Box>
              <LinearProgress 
                variant="determinate" 
                value={45} 
                sx={{ mb: 2, '& .MuiLinearProgress-bar': { backgroundColor: '#f39c12' } }} 
              />
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;

