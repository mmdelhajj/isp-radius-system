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
  InputAdornment,
} from '@mui/material';
import {
  Add as AddIcon,
  MoreVert as MoreIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Speed as SpeedIcon,
  DataUsage as DataIcon,
  AttachMoney as MoneyIcon,
  Group as GroupIcon,
} from '@mui/icons-material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';

interface Profile {
  id: number;
  name: string;
  downloadSpeed: string;
  uploadSpeed: string;
  dataLimit: string;
  price: number;
  billingCycle: string;
  activeUsers: number;
  status: 'active' | 'inactive';
  description?: string;
  simultaneousUse: number;
  sessionTimeout: string;
}

// Mock data
const mockProfiles: Profile[] = [
  {
    id: 1,
    name: 'Basic Plan',
    downloadSpeed: '10 Mbps',
    uploadSpeed: '2 Mbps',
    dataLimit: '50 GB',
    price: 29.99,
    billingCycle: 'Monthly',
    activeUsers: 45,
    status: 'active',
    description: 'Basic internet plan for light users',
    simultaneousUse: 1,
    sessionTimeout: '24 hours',
  },
  {
    id: 2,
    name: 'Standard Plan',
    downloadSpeed: '25 Mbps',
    uploadSpeed: '5 Mbps',
    dataLimit: '100 GB',
    price: 49.99,
    billingCycle: 'Monthly',
    activeUsers: 78,
    status: 'active',
    description: 'Standard plan for regular users',
    simultaneousUse: 2,
    sessionTimeout: '24 hours',
  },
  {
    id: 3,
    name: 'Premium Plan',
    downloadSpeed: '100 Mbps',
    uploadSpeed: '20 Mbps',
    dataLimit: 'Unlimited',
    price: 99.99,
    billingCycle: 'Monthly',
    activeUsers: 32,
    status: 'active',
    description: 'Premium high-speed unlimited plan',
    simultaneousUse: 3,
    sessionTimeout: 'Unlimited',
  },
  {
    id: 4,
    name: 'Legacy Plan',
    downloadSpeed: '5 Mbps',
    uploadSpeed: '1 Mbps',
    dataLimit: '25 GB',
    price: 19.99,
    billingCycle: 'Monthly',
    activeUsers: 12,
    status: 'inactive',
    description: 'Legacy plan - no longer offered',
    simultaneousUse: 1,
    sessionTimeout: '12 hours',
  },
];

const getStatusColor = (status: string) => {
  switch (status) {
    case 'active':
      return 'success';
    case 'inactive':
      return 'default';
    default:
      return 'default';
  }
};

const Profiles: React.FC = () => {
  const [profiles, setProfiles] = useState<Profile[]>(mockProfiles);
  const [searchTerm, setSearchTerm] = useState('');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedProfile, setSelectedProfile] = useState<Profile | null>(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [dialogType, setDialogType] = useState<'add' | 'edit'>('add');

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>, profile: Profile) => {
    setAnchorEl(event.currentTarget);
    setSelectedProfile(profile);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedProfile(null);
  };

  const handleEdit = () => {
    setDialogType('edit');
    setOpenDialog(true);
    handleMenuClose();
  };

  const handleDelete = () => {
    if (selectedProfile) {
      setProfiles(profiles.filter(profile => profile.id !== selectedProfile.id));
    }
    handleMenuClose();
  };

  const handleStatusToggle = () => {
    if (selectedProfile) {
      setProfiles(profiles.map(profile => 
        profile.id === selectedProfile.id 
          ? { ...profile, status: profile.status === 'active' ? 'inactive' : 'active' }
          : profile
      ));
    }
    handleMenuClose();
  };

  const filteredProfiles = profiles.filter(profile =>
    profile.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    profile.description?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const columns: GridColDef[] = [
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
    { field: 'name', headerName: 'Profile Name', width: 150 },
    { field: 'downloadSpeed', headerName: 'Download', width: 100 },
    { field: 'uploadSpeed', headerName: 'Upload', width: 100 },
    { field: 'dataLimit', headerName: 'Data Limit', width: 100 },
    { 
      field: 'price', 
      headerName: 'Price', 
      width: 100,
      renderCell: (params) => `$${params.value}`
    },
    { field: 'billingCycle', headerName: 'Billing', width: 100 },
    { field: 'activeUsers', headerName: 'Active Users', width: 120 },
    { field: 'simultaneousUse', headerName: 'Simultaneous', width: 120 },
    { field: 'sessionTimeout', headerName: 'Session Timeout', width: 130 },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 80,
      sortable: false,
      renderCell: (params) => (
        <IconButton
          size="small"
          onClick={(e) => handleMenuClick(e, params.row as Profile)}
        >
          <MoreIcon />
        </IconButton>
      ),
    },
  ];

  const totalActiveUsers = profiles.reduce((total, profile) => total + profile.activeUsers, 0);
  const activeProfiles = profiles.filter(profile => profile.status === 'active').length;
  const totalRevenue = profiles.reduce((total, profile) => total + (profile.price * profile.activeUsers), 0);

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Service Profiles</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => {
            setDialogType('add');
            setOpenDialog(true);
          }}
        >
          Add Profile
        </Button>
      </Box>

      {/* Summary Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <SpeedIcon color="primary" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">{profiles.length}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Profiles
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
                <DataIcon color="success" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">{activeProfiles}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Active Profiles
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
                <GroupIcon color="info" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">{totalActiveUsers}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Subscribers
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
                  <Typography variant="h6">${totalRevenue.toLocaleString()}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Monthly Revenue
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Box display="flex" gap={2} mb={3}>
        <TextField
          placeholder="Search profiles..."
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
          rows={filteredProfiles}
          columns={columns}
          pageSize={10}
          rowsPerPageOptions={[5, 10, 25, 50]}
          checkboxSelection
          disableSelectionOnClick
          sx={{
            '& .MuiDataGrid-cell': {
              borderBottom: '1px solid rgba(224, 224, 224, 0.3)',
            },
            '& .MuiDataGrid-columnHeaders': {
              backgroundColor: 'background.paper',
              borderBottom: '2px solid rgba(224, 224, 224, 0.5)',
            },
          }}
        />
      </Box>

      {/* Context Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={handleEdit}>
          <EditIcon sx={{ mr: 1 }} />
          Edit
        </MenuItem>
        <MenuItem onClick={handleStatusToggle}>
          <SpeedIcon sx={{ mr: 1 }} />
          {selectedProfile?.status === 'active' ? 'Deactivate' : 'Activate'}
        </MenuItem>
        <MenuItem onClick={handleDelete} sx={{ color: 'error.main' }}>
          <DeleteIcon sx={{ mr: 1 }} />
          Delete
        </MenuItem>
      </Menu>

      {/* Add/Edit Dialog */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          {dialogType === 'add' ? 'Add New Profile' : 'Edit Profile'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ pt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Profile Name"
                margin="normal"
                defaultValue={dialogType === 'edit' ? selectedProfile?.name : ''}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Description"
                margin="normal"
                defaultValue={dialogType === 'edit' ? selectedProfile?.description : ''}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Download Speed"
                margin="normal"
                InputProps={{
                  endAdornment: <InputAdornment position="end">Mbps</InputAdornment>,
                }}
                defaultValue={dialogType === 'edit' ? selectedProfile?.downloadSpeed.split(' ')[0] : ''}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Upload Speed"
                margin="normal"
                InputProps={{
                  endAdornment: <InputAdornment position="end">Mbps</InputAdornment>,
                }}
                defaultValue={dialogType === 'edit' ? selectedProfile?.uploadSpeed.split(' ')[0] : ''}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Data Limit"
                margin="normal"
                InputProps={{
                  endAdornment: <InputAdornment position="end">GB</InputAdornment>,
                }}
                defaultValue={dialogType === 'edit' ? selectedProfile?.dataLimit.split(' ')[0] : ''}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Price"
                type="number"
                margin="normal"
                InputProps={{
                  startAdornment: <InputAdornment position="start">$</InputAdornment>,
                }}
                defaultValue={dialogType === 'edit' ? selectedProfile?.price : ''}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth margin="normal">
                <InputLabel>Billing Cycle</InputLabel>
                <Select
                  defaultValue={dialogType === 'edit' ? selectedProfile?.billingCycle : 'Monthly'}
                  label="Billing Cycle"
                >
                  <MenuItem value="Daily">Daily</MenuItem>
                  <MenuItem value="Weekly">Weekly</MenuItem>
                  <MenuItem value="Monthly">Monthly</MenuItem>
                  <MenuItem value="Quarterly">Quarterly</MenuItem>
                  <MenuItem value="Yearly">Yearly</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Simultaneous Use"
                type="number"
                margin="normal"
                defaultValue={dialogType === 'edit' ? selectedProfile?.simultaneousUse : 1}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Session Timeout"
                margin="normal"
                placeholder="e.g., 24 hours, Unlimited"
                defaultValue={dialogType === 'edit' ? selectedProfile?.sessionTimeout : ''}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth margin="normal">
                <InputLabel>Status</InputLabel>
                <Select
                  defaultValue={dialogType === 'edit' ? selectedProfile?.status : 'active'}
                  label="Status"
                >
                  <MenuItem value="active">Active</MenuItem>
                  <MenuItem value="inactive">Inactive</MenuItem>
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => setOpenDialog(false)}>
            {dialogType === 'add' ? 'Add Profile' : 'Save Changes'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Profiles;

