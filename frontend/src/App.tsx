import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { Box } from '@mui/material';
import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import UsersList from './pages/UsersList';
import OnlineUsers from './pages/OnlineUsers';
import NASList from './pages/NASList';
import Profiles from './pages/Profiles';
import Billing from './pages/Billing';
import Reports from './pages/Reports';
import Settings from './pages/Settings';
import Login from './pages/Login';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#3498db',
    },
    secondary: {
      main: '#e74c3c',
    },
    background: {
      default: '#2c3e50',
      paper: '#34495e',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
  },
});

function App() {
  const [isAuthenticated, setIsAuthenticated] = React.useState(false);

  React.useEffect(() => {
    // Check if user is logged in (you can implement proper authentication logic here)
    const token = localStorage.getItem('authToken');
    setIsAuthenticated(!!token);
  }, []);

  if (!isAuthenticated) {
    return (
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <Login onLogin={() => setIsAuthenticated(true)} />
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Box sx={{ display: 'flex' }}>
          <Sidebar />
          <Box component="main" sx={{ flexGrow: 1, p: 3, ml: '240px' }}>
            <Routes>
              <Route path="/" element={<Navigate to="/dashboard" replace />} />
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/users" element={<UsersList />} />
              <Route path="/online-users" element={<OnlineUsers />} />
              <Route path="/nas" element={<NASList />} />
              <Route path="/profiles" element={<Profiles />} />
              <Route path="/billing" element={<Billing />} />
              <Route path="/reports" element={<Reports />} />
              <Route path="/settings" element={<Settings />} />
            </Routes>
          </Box>
        </Box>
      </Router>
    </ThemeProvider>
  );
}

export default App;
