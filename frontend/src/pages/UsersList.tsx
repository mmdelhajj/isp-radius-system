import React, { useState } from 'react';
import {
  Box,
  Typography,
  Button,
  TextField,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Menu,
  MenuItem,
} from '@mui/material';
import {
  Add as AddIcon,
  MoreVert as MoreIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Search as SearchIcon,
} from '@mui/icons-material';

interface User {
  id: number;
  username: string;
  firstName: string;
  lastName: string;
  status: 'active' | 'expired' | 'disabled' | 'depleted';
  profile: string;
  expiration: string;
  dailyTraffic: string;
  remainingDays: number;
  debts: number;
  parent: string;
}

// Mock data
const mockUsers: User[] = [
  {
    id: 1,
    username: 'user001',
    firstName: 'John',
    lastName: 'Doe',
    status: 'active',
    profile: 'Premium',
    expiration: '2025-12-31',
    dailyTraffic: '2.5 GB',
    remainingDays: 104,
    debts: 0,
    parent: 'admin',
  },
  {
    id: 2,
    username: 'user002',
    firstName: 'Jane',
    lastName: 'Smith',
    status: 'expired',
    profile: 'Basic',
    expiration: '2025-01-15',
    dailyTraffic: '1.2 GB',
    remainingDays: -250,
    debts: 25.50,
    parent: 'admin',
  },
  {
    id: 3,
    username: 'user003',
    firstName: 'Bob',
    lastName: 'Johnson',
    status: 'disabled',
    profile: 'Standard',
    expiration: '2025-06-30',
    dailyTraffic: '0 GB',
    remainingDays: 0,
    debts: 0,
    parent: 'manager1',
  },
];

const getStatusColor = (status: string) => {
  switch (status) {
    case 'active':
      return 'success';
    case 'expired':
      return 'warning';
    case 'disabled':
      return 'error';
    case 'depleted':
      return 'info';
    default:
      return 'default';
  }
};

const UsersList: React.FC = () => {
  const [users, setUsers] = useState<User[]>(mockUsers);
  const [searchTerm, setSearchTerm] = useState('');
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  const handleMenuClick = (event: React.MouseEvent<HTMLElement>, user: User) => {
    setAnchorEl(event.currentTarget);
    setSelectedUser(user);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedUser(null);
  };

  const filteredUsers = users.filter(user =>
    user.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.lastName.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Users Management</Typography>
        <Button variant="contained" startIcon={<AddIcon />}>
          Add User
        </Button>
      </Box>

      <Box display="flex" gap={2} mb={3}>
        <TextField
          placeholder="Search users..."
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

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Status</TableCell>
              <TableCell>Username</TableCell>
              <TableCell>First Name</TableCell>
              <TableCell>Last Name</TableCell>
              <TableCell>Profile</TableCell>
              <TableCell>Expiration</TableCell>
              <TableCell>Daily Traffic</TableCell>
              <TableCell>Remaining Days</TableCell>
              <TableCell>Debts</TableCell>
              <TableCell>Parent</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredUsers.map((user) => (
              <TableRow key={user.id}>
                <TableCell>
                  <Chip
                    label={user.status}
                    color={getStatusColor(user.status) as any}
                    size="small"
                  />
                </TableCell>
                <TableCell>{user.username}</TableCell>
                <TableCell>{user.firstName}</TableCell>
                <TableCell>{user.lastName}</TableCell>
                <TableCell>{user.profile}</TableCell>
                <TableCell>{user.expiration}</TableCell>
                <TableCell>{user.dailyTraffic}</TableCell>
                <TableCell>{user.remainingDays}</TableCell>
                <TableCell>
                  <Typography color={user.debts > 0 ? 'error' : 'inherit'}>
                    ${user.debts}
                  </Typography>
                </TableCell>
                <TableCell>{user.parent}</TableCell>
                <TableCell>
                  <IconButton
                    size="small"
                    onClick={(e) => handleMenuClick(e, user)}
                  >
                    <MoreIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Context Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={handleMenuClose}>
          <EditIcon sx={{ mr: 1 }} />
          Edit
        </MenuItem>
        <MenuItem onClick={handleMenuClose} sx={{ color: 'error.main' }}>
          <DeleteIcon sx={{ mr: 1 }} />
          Delete
        </MenuItem>
      </Menu>
    </Box>
  );
};

export default UsersList;

