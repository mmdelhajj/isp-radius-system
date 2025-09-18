import React, { useState } from 'react';
import {
  Box,
  Typography,
  Button,
  TextField,
  Chip,
  IconButton,
  Menu,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  Card,
  CardContent,
  Grid,
  Tabs,
  Tab,
  Divider,
} from '@mui/material';
import {
  Add as AddIcon,
  MoreVert as MoreIcon,
  Visibility as ViewIcon,
  GetApp as DownloadIcon,
  Send as SendIcon,
  Search as SearchIcon,
  Receipt as InvoiceIcon,
  AttachMoney as MoneyIcon,
  CreditCard as PaymentIcon,
  TrendingUp as RevenueIcon,
} from '@mui/icons-material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';

interface Invoice {
  id: number;
  invoiceNumber: string;
  username: string;
  amount: number;
  status: 'paid' | 'pending' | 'overdue' | 'cancelled';
  issueDate: string;
  dueDate: string;
  paidDate?: string;
  description: string;
  paymentMethod?: string;
}

interface Payment {
  id: number;
  username: string;
  amount: number;
  method: string;
  status: 'completed' | 'pending' | 'failed';
  date: string;
  transactionId: string;
  gateway: string;
}

// Mock data
const mockInvoices: Invoice[] = [
  {
    id: 1,
    invoiceNumber: 'INV-2025-001',
    username: 'user001',
    amount: 49.99,
    status: 'paid',
    issueDate: '2025-09-01',
    dueDate: '2025-09-15',
    paidDate: '2025-09-10',
    description: 'Monthly subscription - Standard Plan',
    paymentMethod: 'Credit Card',
  },
  {
    id: 2,
    invoiceNumber: 'INV-2025-002',
    username: 'user002',
    amount: 99.99,
    status: 'pending',
    issueDate: '2025-09-15',
    dueDate: '2025-09-30',
    description: 'Monthly subscription - Premium Plan',
  },
  {
    id: 3,
    invoiceNumber: 'INV-2025-003',
    username: 'user003',
    amount: 29.99,
    status: 'overdue',
    issueDate: '2025-08-01',
    dueDate: '2025-08-15',
    description: 'Monthly subscription - Basic Plan',
  },
];

const mockPayments: Payment[] = [
  {
    id: 1,
    username: 'user001',
    amount: 49.99,
    method: 'Credit Card',
    status: 'completed',
    date: '2025-09-10',
    transactionId: 'TXN-123456789',
    gateway: 'Stripe',
  },
  {
    id: 2,
    username: 'user004',
    amount: 99.99,
    method: 'PayPal',
    status: 'completed',
    date: '2025-09-12',
    transactionId: 'TXN-987654321',
    gateway: 'PayPal',
  },
  {
    id: 3,
    username: 'user005',
    amount: 29.99,
    method: 'Bank Transfer',
    status: 'pending',
    date: '2025-09-18',
    transactionId: 'TXN-456789123',
    gateway: 'Bank',
  },
];

const getStatusColor = (status: string) => {
  switch (status) {
    case 'paid':
    case 'completed':
      return 'success';
    case 'pending':
      return 'warning';
    case 'overdue':
    case 'failed':
      return 'error';
    case 'cancelled':
      return 'default';
    default:
      return 'default';
  }
};

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
      id={`billing-tabpanel-${index}`}
      aria-labelledby={`billing-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 3 }}>{children}</Box>}
    </div>
  );
}

const Billing: React.FC = () => {
  const [tabValue, setTabValue] = useState(0);
  const [invoices, setInvoices] = useState<Invoice[]>(mockInvoices);
  const [payments, setPayments] = useState<Payment[]>(mockPayments);
  const [searchTerm, setSearchTerm] = useState('');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedItem, setSelectedItem] = useState<Invoice | Payment | null>(null);
  const [openDialog, setOpenDialog] = useState(false);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>, item: Invoice | Payment) => {
    setAnchorEl(event.currentTarget);
    setSelectedItem(item);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedItem(null);
  };

  const filteredInvoices = invoices.filter(invoice =>
    invoice.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
    invoice.invoiceNumber.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredPayments = payments.filter(payment =>
    payment.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
    payment.transactionId.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const invoiceColumns: GridColDef[] = [
    { field: 'invoiceNumber', headerName: 'Invoice #', width: 130 },
    { field: 'username', headerName: 'Customer', width: 120 },
    { 
      field: 'amount', 
      headerName: 'Amount', 
      width: 100,
      renderCell: (params) => `$${params.value}`
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 100,
      renderCell: (params) => (
        <Chip
          label={params.value}
          color={getStatusColor(params.value as string) as any}
          size="small"
        />
      ),
    },
    { field: 'issueDate', headerName: 'Issue Date', width: 120 },
    { field: 'dueDate', headerName: 'Due Date', width: 120 },
    { field: 'paidDate', headerName: 'Paid Date', width: 120 },
    { field: 'description', headerName: 'Description', width: 200 },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 80,
      sortable: false,
      renderCell: (params) => (
        <IconButton
          size="small"
          onClick={(e) => handleMenuClick(e, params.row as Invoice)}
        >
          <MoreIcon />
        </IconButton>
      ),
    },
  ];

  const paymentColumns: GridColDef[] = [
    { field: 'transactionId', headerName: 'Transaction ID', width: 150 },
    { field: 'username', headerName: 'Customer', width: 120 },
    { 
      field: 'amount', 
      headerName: 'Amount', 
      width: 100,
      renderCell: (params) => `$${params.value}`
    },
    { field: 'method', headerName: 'Method', width: 120 },
    { field: 'gateway', headerName: 'Gateway', width: 100 },
    {
      field: 'status',
      headerName: 'Status',
      width: 100,
      renderCell: (params) => (
        <Chip
          label={params.value}
          color={getStatusColor(params.value as string) as any}
          size="small"
        />
      ),
    },
    { field: 'date', headerName: 'Date', width: 120 },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 80,
      sortable: false,
      renderCell: (params) => (
        <IconButton
          size="small"
          onClick={(e) => handleMenuClick(e, params.row as Payment)}
        >
          <MoreIcon />
        </IconButton>
      ),
    },
  ];

  // Calculate summary statistics
  const totalRevenue = invoices.filter(inv => inv.status === 'paid').reduce((sum, inv) => sum + inv.amount, 0);
  const pendingAmount = invoices.filter(inv => inv.status === 'pending').reduce((sum, inv) => sum + inv.amount, 0);
  const overdueAmount = invoices.filter(inv => inv.status === 'overdue').reduce((sum, inv) => sum + inv.amount, 0);
  const totalInvoices = invoices.length;

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Billing Management</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setOpenDialog(true)}
        >
          Issue Invoice
        </Button>
      </Box>

      {/* Summary Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <RevenueIcon color="success" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">${totalRevenue.toLocaleString()}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Revenue
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
                  <Typography variant="h6">${pendingAmount.toLocaleString()}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Pending Amount
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
                <PaymentIcon color="error" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">${overdueAmount.toLocaleString()}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Overdue Amount
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
                <InvoiceIcon color="primary" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">{totalInvoices}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Invoices
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tabs value={tabValue} onChange={handleTabChange}>
          <Tab label="Invoices" />
          <Tab label="Payments" />
        </Tabs>
      </Box>

      <TabPanel value={tabValue} index={0}>
        <Box display="flex" gap={2} mb={3}>
          <TextField
            placeholder="Search invoices..."
            variant="outlined"
            size="small"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
            }}
            sx={{ minWidth: 300 }}
          />
        </Box>

        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={filteredInvoices}
            columns={invoiceColumns}
            pageSize={10}
            rowsPerPageOptions={[5, 10, 25, 50]}
            checkboxSelection
            disableSelectionOnClick
          />
        </Box>
      </TabPanel>

      <TabPanel value={tabValue} index={1}>
        <Box display="flex" gap={2} mb={3}>
          <TextField
            placeholder="Search payments..."
            variant="outlined"
            size="small"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />,
            }}
            sx={{ minWidth: 300 }}
          />
        </Box>

        <Box sx={{ height: 600, width: '100%' }}>
          <DataGrid
            rows={filteredPayments}
            columns={paymentColumns}
            pageSize={10}
            rowsPerPageOptions={[5, 10, 25, 50]}
            checkboxSelection
            disableSelectionOnClick
          />
        </Box>
      </TabPanel>

      {/* Context Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={handleMenuClose}>
          <ViewIcon sx={{ mr: 1 }} />
          View Details
        </MenuItem>
        <MenuItem onClick={handleMenuClose}>
          <DownloadIcon sx={{ mr: 1 }} />
          Download PDF
        </MenuItem>
        {tabValue === 0 && (
          <MenuItem onClick={handleMenuClose}>
            <SendIcon sx={{ mr: 1 }} />
            Send Reminder
          </MenuItem>
        )}
      </Menu>

      {/* Issue Invoice Dialog */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Issue New Invoice</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            <TextField
              fullWidth
              label="Customer Username"
              margin="normal"
            />
            <TextField
              fullWidth
              label="Amount"
              type="number"
              margin="normal"
            />
            <TextField
              fullWidth
              label="Description"
              margin="normal"
              multiline
              rows={3}
            />
            <TextField
              fullWidth
              label="Due Date"
              type="date"
              margin="normal"
              InputLabelProps={{ shrink: true }}
            />
            <FormControl fullWidth margin="normal">
              <InputLabel>Service Plan</InputLabel>
              <Select label="Service Plan">
                <MenuItem value="basic">Basic Plan</MenuItem>
                <MenuItem value="standard">Standard Plan</MenuItem>
                <MenuItem value="premium">Premium Plan</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => setOpenDialog(false)}>
            Issue Invoice
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Billing;

