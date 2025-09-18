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
} from '@mui/material';
import {
  Add as AddIcon,
  MoreVert as MoreIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
  Router as RouterIcon,
  SignalWifi4Bar as SignalIcon,
  Speed as SpeedIcon,
  Error as ErrorIcon,
} from '@mui/icons-material';
import { DataGrid, GridColDef } from '@mui/x-data-grid';

interface NAS {
  id: number;
  name: string;
  ipAddress: string;
  type: string;
  secret: string;
  onlineUsers: number;
  rtt: string;
  packetLoss: number;
  status: 'online' | 'offline' | 'warning';
  description?: string;
  ports?: string;
}

// Mock data
const mockNAS: NAS[] = [
  {
    id: 1,
    name: 'Main Router',
    ipAddress: '192.168.1.1',
    type: 'Mikrotik',
    secret: 'secret123',
    onlineUsers: 15,
    rtt: '2ms',
    packetLoss: 0,
    status: 'online',
    description: 'Main office router',
    ports: '1812,1813',
  },
  {
    id: 2,
    name: 'Branch Router',
    ipAddress: '192.168.2.1',
    type: 'Cisco',
    secret: 'secret456',
    onlineUsers: 8,
    rtt: '5ms',
    packetLoss: 0.1,
    status: 'online',
    description: 'Branch office router',
    ports: '1812,1813',
  },
  {
    id: 3,
    name: 'Backup Router',
    ipAddress: '192.168.3.1',
    type: 'Ubiquiti',
    secret: 'secret789',
    onlineUsers: 0,
    rtt: 'N/A',
    packetLoss: 100,
    status: 'offline',
    description: 'Backup router - currently offline',
    ports: '1812,1813',
  },
];

const getStatusColor = (status: string) => {
  switch (status) {
    case 'online':
      return 'success';
    case 'offline':
      return 'error';
    case 'warning':
      return 'warning';
    default:
      return 'default';
  }
};

const getStatusIcon = (status: string) => {
  switch (status) {
    case 'online':
      return <SignalIcon />;
    case 'offline':
      return <ErrorIcon />;
    case 'warning':
      return <SpeedIcon />;
    default:
      return <RouterIcon />;
  }
};

const NASList: React.FC = () => {
  const [nasList, setNasList] = useState<NAS[]>(mockNAS);
  const [searchTerm, setSearchTerm] = useState('');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedNAS, setSelectedNAS] = useState<NAS | null>(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [dialogType, setDialogType] = useState<'add' | 'edit'>('add');

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>, nas: NAS) => {
    setAnchorEl(event.currentTarget);
    setSelectedNAS(nas);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedNAS(null);
  };

  const handleEdit = () => {
    setDialogType('edit');
    setOpenDialog(true);
    handleMenuClose();
  };

  const handleDelete = () => {
    if (selectedNAS) {
      setNasList(nasList.filter(nas => nas.id !== selectedNAS.id));
    }
    handleMenuClose();
  };

  const filteredNAS = nasList.filter(nas =>
    nas.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    nas.ipAddress.includes(searchTerm) ||
    nas.type.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const columns: GridColDef[] = [
    {
      field: 'status',
      headerName: 'Status',
      width: 100,
      renderCell: (params) => (
        <Chip
          icon={getStatusIcon(params.value as string)}
          label={params.value}
          color={getStatusColor(params.value as string) as any}
          size="small"
        />
      ),
    },
    { field: 'name', headerName: 'Name', width: 150 },
    { field: 'ipAddress', headerName: 'IP Address', width: 130 },
    { field: 'type', headerName: 'Type', width: 120 },
    { 
      field: 'secret', 
      headerName: 'Secret', 
      width: 120,
      renderCell: (params) => '••••••••'
    },
    { field: 'onlineUsers', headerName: 'Online Users', width: 120 },
    { field: 'rtt', headerName: 'RTT', width: 80 },
    { 
      field: 'packetLoss', 
      headerName: 'Packet Loss %', 
      width: 130,
      renderCell: (params) => (
        <Typography color={params.value > 5 ? 'error' : 'inherit'}>
          {params.value}%
        </Typography>
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
          onClick={(e) => handleMenuClick(e, params.row as NAS)}
        >
          <MoreIcon />
        </IconButton>
      ),
    },
  ];

  const totalOnlineUsers = nasList.reduce((total, nas) => total + nas.onlineUsers, 0);
  const onlineNAS = nasList.filter(nas => nas.status === 'online').length;
  const offlineNAS = nasList.filter(nas => nas.status === 'offline').length;

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">NAS Management</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => {
            setDialogType('add');
            setOpenDialog(true);
          }}
        >
          Add NAS
        </Button>
      </Box>

      {/* Summary Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center">
                <RouterIcon color="primary" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">{nasList.length}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total NAS
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
                <SignalIcon color="success" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">{onlineNAS}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Online NAS
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
                <ErrorIcon color="error" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">{offlineNAS}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Offline NAS
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
                <SignalIcon color="info" sx={{ mr: 2 }} />
                <Box>
                  <Typography variant="h6">{totalOnlineUsers}</Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Online Users
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      <Box display="flex" gap={2} mb={3}>
        <TextField
          placeholder="Search NAS..."
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
          rows={filteredNAS}
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
        <MenuItem onClick={handleDelete} sx={{ color: 'error.main' }}>
          <DeleteIcon sx={{ mr: 1 }} />
          Delete
        </MenuItem>
      </Menu>

      {/* Add/Edit Dialog */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {dialogType === 'add' ? 'Add New NAS' : 'Edit NAS'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            <TextField
              fullWidth
              label="Name"
              margin="normal"
              defaultValue={dialogType === 'edit' ? selectedNAS?.name : ''}
            />
            <TextField
              fullWidth
              label="IP Address"
              margin="normal"
              defaultValue={dialogType === 'edit' ? selectedNAS?.ipAddress : ''}
            />
            <FormControl fullWidth margin="normal">
              <InputLabel>Type</InputLabel>
              <Select
                defaultValue={dialogType === 'edit' ? selectedNAS?.type : ''}
                label="Type"
              >
                <MenuItem value="Mikrotik">Mikrotik</MenuItem>
                <MenuItem value="Cisco">Cisco</MenuItem>
                <MenuItem value="Ubiquiti">Ubiquiti</MenuItem>
                <MenuItem value="TP-Link">TP-Link</MenuItem>
                <MenuItem value="Other">Other</MenuItem>
              </Select>
            </FormControl>
            <TextField
              fullWidth
              label="Secret"
              type="password"
              margin="normal"
              defaultValue={dialogType === 'edit' ? selectedNAS?.secret : ''}
            />
            <TextField
              fullWidth
              label="Ports"
              margin="normal"
              placeholder="1812,1813"
              defaultValue={dialogType === 'edit' ? selectedNAS?.ports : '1812,1813'}
            />
            <TextField
              fullWidth
              label="Description"
              margin="normal"
              multiline
              rows={3}
              defaultValue={dialogType === 'edit' ? selectedNAS?.description : ''}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => setOpenDialog(false)}>
            {dialogType === 'add' ? 'Add NAS' : 'Save Changes'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default NASList;

