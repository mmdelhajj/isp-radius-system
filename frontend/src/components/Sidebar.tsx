import React from 'react';
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
  Box,
  Divider,
  Collapse,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  People as PeopleIcon,
  PersonOnline as OnlineIcon,
  Router as RouterIcon,
  AccountTree as ProfilesIcon,
  Receipt as BillingIcon,
  Assessment as ReportsIcon,
  Settings as SettingsIcon,
  ExpandLess,
  ExpandMore,
  Group as GroupIcon,
  CreditCard as CardIcon,
  History as LogIcon,
  Build as ToolsIcon,
  NetworkCheck as IPPoolIcon,
  Info as AboutIcon,
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';

const drawerWidth = 240;

interface MenuItem {
  text: string;
  icon: React.ReactElement;
  path?: string;
  children?: MenuItem[];
}

const menuItems: MenuItem[] = [
  {
    text: 'Dashboard',
    icon: <DashboardIcon />,
    path: '/dashboard',
  },
  {
    text: 'Users',
    icon: <PeopleIcon />,
    children: [
      { text: 'Users List', icon: <PeopleIcon />, path: '/users' },
      { text: 'Online Users', icon: <OnlineIcon />, path: '/online-users' },
      { text: 'Compensations', icon: <CreditCard />, path: '/compensations' },
      { text: 'Support Tickets', icon: <CardIcon />, path: '/support-tickets' },
    ],
  },
  {
    text: 'Managers',
    icon: <GroupIcon />,
    path: '/managers',
  },
  {
    text: 'Groups',
    icon: <GroupIcon />,
    path: '/groups',
  },
  {
    text: 'NAS',
    icon: <RouterIcon />,
    path: '/nas',
  },
  {
    text: 'Profiles',
    icon: <ProfilesIcon />,
    path: '/profiles',
  },
  {
    text: 'Cards System',
    icon: <CreditCard />,
    path: '/cards',
  },
  {
    text: 'Billing',
    icon: <BillingIcon />,
    children: [
      { text: 'User Invoices', icon: <BillingIcon />, path: '/billing' },
      { text: 'Issue Invoice', icon: <BillingIcon />, path: '/issue-invoice' },
    ],
  },
  {
    text: 'Reports',
    icon: <ReportsIcon />,
    path: '/reports',
  },
  {
    text: 'Log',
    icon: <LogIcon />,
    path: '/log',
  },
  {
    text: 'Tools',
    icon: <ToolsIcon />,
    path: '/tools',
  },
  {
    text: 'IP Pools',
    icon: <IPPoolIcon />,
    path: '/ip-pools',
  },
  {
    text: 'Settings',
    icon: <SettingsIcon />,
    path: '/settings',
  },
  {
    text: 'About',
    icon: <AboutIcon />,
    path: '/about',
  },
];

const Sidebar: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [openItems, setOpenItems] = React.useState<{ [key: string]: boolean }>({});

  const handleItemClick = (item: MenuItem) => {
    if (item.children) {
      setOpenItems(prev => ({
        ...prev,
        [item.text]: !prev[item.text],
      }));
    } else if (item.path) {
      navigate(item.path);
    }
  };

  const isActive = (path: string) => location.pathname === path;

  const renderMenuItem = (item: MenuItem, level: number = 0) => (
    <React.Fragment key={item.text}>
      <ListItem disablePadding>
        <ListItemButton
          onClick={() => handleItemClick(item)}
          selected={item.path ? isActive(item.path) : false}
          sx={{
            pl: 2 + level * 2,
            '&.Mui-selected': {
              backgroundColor: 'primary.main',
              '&:hover': {
                backgroundColor: 'primary.dark',
              },
            },
          }}
        >
          <ListItemIcon sx={{ color: 'inherit', minWidth: 40 }}>
            {item.icon}
          </ListItemIcon>
          <ListItemText primary={item.text} />
          {item.children && (
            openItems[item.text] ? <ExpandLess /> : <ExpandMore />
          )}
        </ListItemButton>
      </ListItem>
      {item.children && (
        <Collapse in={openItems[item.text]} timeout="auto" unmountOnExit>
          <List component="div" disablePadding>
            {item.children.map(child => renderMenuItem(child, level + 1))}
          </List>
        </Collapse>
      )}
    </React.Fragment>
  );

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: drawerWidth,
          boxSizing: 'border-box',
          backgroundColor: 'background.paper',
        },
      }}
    >
      <Box sx={{ p: 2, textAlign: 'center' }}>
        <Typography variant="h6" component="div" sx={{ color: 'primary.main', fontWeight: 'bold' }}>
          ISP RADIUS
        </Typography>
        <Typography variant="caption" sx={{ color: 'text.secondary' }}>
          Management System
        </Typography>
      </Box>
      <Divider />
      <List>
        {menuItems.map(item => renderMenuItem(item))}
      </List>
    </Drawer>
  );
};

export default Sidebar;

