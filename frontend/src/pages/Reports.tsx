import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  Tabs,
  Tab,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
} from '@mui/material';
import {
  GetApp as DownloadIcon,
  TrendingUp as TrendingUpIcon,
  People as PeopleIcon,
  AttachMoney as MoneyIcon,
  DataUsage as DataIcon,
} from '@mui/icons-material';
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';

// Mock data for charts
const revenueData = [
  { month: 'Jan', revenue: 12500, users: 150 },
  { month: 'Feb', revenue: 13200, users: 165 },
  { month: 'Mar', revenue: 14800, users: 180 },
  { month: 'Apr', revenue: 15600, users: 195 },
  { month: 'May', revenue: 16200, users: 210 },
  { month: 'Jun', revenue: 17800, users: 225 },
  { month: 'Jul', revenue: 18500, users: 240 },
  { month: 'Aug', revenue: 19200, users: 255 },
  { month: 'Sep', revenue: 20100, users: 270 },
];

const userGrowthData = [
  { month: 'Jan', active: 120, expired: 30, new: 25 },
  { month: 'Feb', active: 135, expired: 30, new: 40 },
  { month: 'Mar', active: 155, expired: 25, new: 45 },
  { month: 'Apr', active: 175, expired: 20, new: 35 },
  { month: 'May', active: 190, expired: 20, new: 30 },
  { month: 'Jun', active: 205, expired: 20, new: 35 },
  { month: 'Jul', active: 220, expired: 20, new: 40 },
  { month: 'Aug', active: 235, expired: 20, new: 35 },
  { month: 'Sep', active: 250, expired: 20, new: 30 },
];

const planDistribution = [
  { name: 'Basic', value: 45, color: '#8884d8' },
  { name: 'Standard', value: 78, color: '#82ca9d' },
  { name: 'Premium', value: 32, color: '#ffc658' },
  { name: 'Enterprise', value: 15, color: '#ff7300' },
];

const dataUsageData = [
  { day: 'Mon', upload: 120, download: 480 },
  { day: 'Tue', upload: 135, download: 520 },
  { day: 'Wed', upload: 145, download: 580 },
  { day: 'Thu', upload: 155, download: 620 },
  { day: 'Fri', upload: 165, download: 660 },
  { day: 'Sat', upload: 180, download: 720 },
  { day: 'Sun', upload: 170, download: 680 },
];

const topUsersData = [
  { username: 'user001', dataUsed: '45.2 GB', revenue: '$99.99', plan: 'Premium' },
  { username: 'user002', dataUsed: '38.7 GB', revenue: '$99.99', plan: 'Premium' },
  { username: 'user003', dataUsed: '32.1 GB', revenue: '$49.99', plan: 'Standard' },
  { username: 'user004', dataUsed: '28.9 GB', revenue: '$49.99', plan: 'Standard' },
  { username: 'user005', dataUsed: '25.3 GB', revenue: '$29.99', plan: 'Basic' },
];

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`reports-tabpanel-${index}`}
      aria-labelledby={`reports-tab-${index}`}
      {...other}
    >
      {value === index && <Box>{children}</Box>}
    </div>
  );
}

const Reports: React.FC = () => {
  const [tabValue, setTabValue] = useState(0);
  const [timeRange, setTimeRange] = useState('monthly');
  const [reportType, setReportType] = useState('revenue');

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleExport = (format: string) => {
    // In a real app, this would trigger the export functionality
    console.log(`Exporting report as ${format}`);
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Reports & Analytics</Typography>
        <Box display="flex" gap={2}>
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Time Range</InputLabel>
            <Select
              value={timeRange}
              label="Time Range"
              onChange={(e) => setTimeRange(e.target.value)}
            >
              <MenuItem value="daily">Daily</MenuItem>
              <MenuItem value="weekly">Weekly</MenuItem>
              <MenuItem value="monthly">Monthly</MenuItem>
              <MenuItem value="yearly">Yearly</MenuItem>
            </Select>
          </FormControl>
          <Button
            variant="outlined"
            startIcon={<DownloadIcon />}
            onClick={() => handleExport('pdf')}
          >
            Export PDF
          </Button>
          <Button
            variant="outlined"
            startIcon={<DownloadIcon />}
            onClick={() => handleExport('excel')}
          >
            Export Excel
          </Button>
        </Box>
      </Box>

      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={tabValue} onChange={handleTabChange}>
          <Tab label="Revenue Analytics" />
          <Tab label="User Analytics" />
          <Tab label="Usage Reports" />
          <Tab label="Performance" />
        </Tabs>
      </Box>

      <TabPanel value={tabValue} index={0}>
        <Grid container spacing={3}>
          {/* Revenue Summary Cards */}
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center">
                  <MoneyIcon color="success" sx={{ mr: 2 }} />
                  <Box>
                    <Typography variant="h6">$20,100</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Monthly Revenue
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center">
                  <TrendingUpIcon color="primary" sx={{ mr: 2 }} />
                  <Box>
                    <Typography variant="h6">+12.5%</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Growth Rate
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center">
                  <MoneyIcon color="warning" sx={{ mr: 2 }} />
                  <Box>
                    <Typography variant="h6">$74.44</Typography>
                    <Typography variant="body2" color="text.secondary">
                      ARPU
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center">
                  <PeopleIcon color="info" sx={{ mr: 2 }} />
                  <Box>
                    <Typography variant="h6">270</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Paying Customers
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          {/* Revenue Trend Chart */}
          <Grid item xs={12} md={8}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Revenue Trend
                </Typography>
                <ResponsiveContainer width="100%" height={300}>
                  <AreaChart data={revenueData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="month" />
                    <YAxis />
                    <Tooltip formatter={(value) => [`$${value}`, 'Revenue']} />
                    <Area type="monotone" dataKey="revenue" stroke="#3498db" fill="#3498db" fillOpacity={0.3} />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </Grid>

          {/* Plan Distribution */}
          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Plan Distribution
                </Typography>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={planDistribution}
                      cx="50%"
                      cy="50%"
                      outerRadius={80}
                      dataKey="value"
                      label={({ name, value }) => `${name}: ${value}`}
                    >
                      {planDistribution.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </TabPanel>

      <TabPanel value={tabValue} index={1}>
        <Grid container spacing={3}>
          {/* User Growth Chart */}
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  User Growth Analysis
                </Typography>
                <ResponsiveContainer width="100%" height={400}>
                  <BarChart data={userGrowthData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="month" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Bar dataKey="active" fill="#2ecc71" name="Active Users" />
                    <Bar dataKey="new" fill="#3498db" name="New Users" />
                    <Bar dataKey="expired" fill="#e74c3c" name="Expired Users" />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </Grid>

          {/* Top Users Table */}
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Top Users by Data Usage
                </Typography>
                <TableContainer component={Paper} elevation={0}>
                  <Table>
                    <TableHead>
                      <TableRow>
                        <TableCell>Username</TableCell>
                        <TableCell>Data Used</TableCell>
                        <TableCell>Plan</TableCell>
                        <TableCell>Revenue</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {topUsersData.map((user, index) => (
                        <TableRow key={index}>
                          <TableCell>{user.username}</TableCell>
                          <TableCell>{user.dataUsed}</TableCell>
                          <TableCell>{user.plan}</TableCell>
                          <TableCell>{user.revenue}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </TabPanel>

      <TabPanel value={tabValue} index={2}>
        <Grid container spacing={3}>
          {/* Data Usage Chart */}
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Weekly Data Usage
                </Typography>
                <ResponsiveContainer width="100%" height={400}>
                  <BarChart data={dataUsageData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="day" />
                    <YAxis />
                    <Tooltip formatter={(value) => [`${value} GB`, '']} />
                    <Legend />
                    <Bar dataKey="download" fill="#3498db" name="Download (GB)" />
                    <Bar dataKey="upload" fill="#e74c3c" name="Upload (GB)" />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          </Grid>

          {/* Usage Summary Cards */}
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center">
                  <DataIcon color="primary" sx={{ mr: 2 }} />
                  <Box>
                    <Typography variant="h6">4.2 TB</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Total Download
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center">
                  <DataIcon color="secondary" sx={{ mr: 2 }} />
                  <Box>
                    <Typography variant="h6">1.1 TB</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Total Upload
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center">
                  <TrendingUpIcon color="success" sx={{ mr: 2 }} />
                  <Box>
                    <Typography variant="h6">15.6 GB</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Avg per User
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <Card>
              <CardContent>
                <Box display="flex" alignItems="center">
                  <DataIcon color="warning" sx={{ mr: 2 }} />
                  <Box>
                    <Typography variant="h6">85%</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Peak Usage
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </TabPanel>

      <TabPanel value={tabValue} index={3}>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  System Performance Metrics
                </Typography>
                <Typography variant="body1" color="text.secondary">
                  Performance reports and system health metrics will be displayed here.
                  This includes server uptime, response times, error rates, and other
                  key performance indicators.
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </TabPanel>
    </Box>
  );
};

export default Reports;

