import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Chip,
  IconButton,
  Menu,
  MenuItem,
  TextField,
  Card,
  CardContent,
  Grid,
} from '@mui/material';
import {
  MoreVert as MoreIcon,
  Block as DisconnectIcon,
  Refresh as RefreshIcon,
  Search as SearchIcon,
  SignalWifi4Bar as SignalIcon,
  AccessTime as TimeIcon,
  DataUsage as DataIcon,
} from '@mui/icons-material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';

interface OnlineUser {
  id: number;
  username: string;
  nasIP: string;
  nasPort: string;
  sessionTime: string;
  ipAddress: string;
  downloadSpeed: string;
  uploadSpeed: string;
  bytesIn: string;
  bytesOut: string;
  profile: string;
  connectionType: string;
  startTime: string;
}

// Mock data for online users
const mockOnlineUsers: OnlineUser[] = [
  {
    id: 1,
    username: 'user001',
    nasIP: '192.168.1.1',
    nasPort: '2048',
    sessionTime: '02:45:30',
    ipAddress: '10.0.1.100',
    downloadSpeed: '50 Mbps',
    uploadSpeed: '10 Mbps',
    bytesIn: '1.2 GB',
    bytesOut: '350 MB',
    profile: 'Premium',
    connectionType: 'PPPoE',
    startTime: '2025-09-18 01:30:00',
  },
  {
    id: 2,
    username: 'user005',
    nasIP: '192.168.1.2',
    nasPort: '1024',
    sessionTime: '01:15:22',
    ipAddress: '10.0.1.101',
    downloadSpeed: '25 Mbps',
    uploadSpeed: '5 Mbps',
    bytesIn: '800 MB',
    bytesOut: '200 MB',
    profile: 'Standard',
    connectionType: 'Hotspot',
    startTime: '2025-09-18 03:00:00',
  },
];

const OnlineUsers: React.FC = () => {
  const [users, setUsers] = useState<OnlineUser[]>(mockOnlineUsers);
  const [searchTerm, setSearchTerm] = useState('');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedUser, setSelectedUser] = useState<OnlineUser | null>(null);
  const [lastRefresh, setLastRefresh] = useState(new Date());

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>, user: OnlineUser) => {
    setAnchorEl(event.currentTarget);
    setSelectedUser(user);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedUser(null);
  };

  const handleDisconnect = () => {
    if (selectedUser) {
      setUsers(users.filter(user => user.id !== selectedUser.id));
    }
    handleMenuClose();
  };

  const handleRefresh = () => {
    setLastRefresh(new Date());
    // In a real app, this would fetch fresh data from the API
  };

  const filteredUsers = users.filter(user =>
    user.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.ipAddress.includes(searchTerm) ||
    user.nasIP.includes(searchTerm)
  );

  // Auto-refresh every 30 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      handleRefresh();
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  const columns: GridColDef[] = [
    { field: 'username', headerName: 'Username', width: 130 },
    { field: 'ipAddress', headerName: 'IP Address', width: 120 },
    { field: 'nasIP', headerName: 'NAS IP', width: 120 },
    { field: 'nasPort', headerName: 'NAS Port', width: 100 },
    { field: 'sessionTime', headerName: 'Session Time', width: 120 },
    { field: 'downloadSpeed', headerName: 'Download', width: 100 },
    { field: 'uploadSpeed', headerName: 'Upload', width: 100 },
    { field: 'bytesIn', headerName: 'Bytes In', width: 100 },
    { field: 'bytesOut', headerName: 'Bytes Out', width: 100 },
    { field: 'profile', headerName: 'Profile', width: 100 },
    {
      field: 'connectionType',
      headerName: 'Type',
      width: 100,
      renderCell: (params) => (
        <Chip
          label={params.value}
          size="small"
          color={params.value === 'PPPoE' ? 'primary' : 'secondary'}
        />
      ),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 80,
      sortable: false,
      renderCell: (params) => (
        <IconButton
          size="small"
          onClick={(e) => handleMenuClick(e, params.row as OnlineUser)}
        >
          <MoreIcon />
        </IconButton>
      ),
    },
  ];

  const totalBandwidth = users.reduce((total, user) => {
    const download = parseInt(user.downloadSpeed.split(' ')[0]);
    return total + download;
  }, 0);

  const totalData = users.reduce((total, user) => {
    const bytesIn = parseFloat(user.bytesIn.split(' ')[0]);
    const bytesOut = parseFloat(user.bytesOut.split(' ')[0]);
    return total + bytesIn + bytesOut;
  }, 0);

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Online Users</Typography>
        <Box display="flex" gap={2} alignItems="center">
          <Typography variant="body2" color="text.secondary">
            Last refresh: {lastRefresh.toLocaleTimeString()}
          </Typography>
          <IconButton onClick={handleRefresh} color="primary">
            <RefreshIcon />
          </IconButton>
        </Box>
      </Box>

      {/* Summary Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <SignalIcon color="primary" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">{users.length}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Online Users
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
                  <Typography variant="h6">{totalBandwidth} Mbps</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Bandwidth
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
                  <Typography variant="h6">{totalData.toFixed(1)} GB</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Data Usage
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
                <TimeIcon color="info" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">
                    {users.length > 0 ? '02:00:26' : '00:00:00'}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Avg Session Time
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Box display="flex" gap={2} mb={3}>
        <TextField
          placeholder="Search by username, IP address..."
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
          rows={filteredUsers}
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
        <MenuItem onClick={handleDisconnect} sx={{ color: 'error.main' }}>
          <DisconnectIcon sx={{ mr: 1 }} />
          Disconnect User
        </MenuItem>
      </Menu>
    </Box>
  );
};

export default OnlineUsers;

