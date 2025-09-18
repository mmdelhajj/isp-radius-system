import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Alert,
} from '@mui/material';
import { styled } from '@mui/material/styles';

const LoginContainer = styled(Box)(({ theme }) => ({
  minHeight: '100vh',
  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  padding: theme.spacing(2),
}));

const LoginCard = styled(Card)(({ theme }) => ({
  maxWidth: 400,
  width: '100%',
  padding: theme.spacing(2),
  backgroundColor: 'rgba(255, 255, 255, 0.95)',
  backdropFilter: 'blur(10px)',
  borderRadius: theme.spacing(2),
  boxShadow: '0 8px 32px rgba(0, 0, 0, 0.1)',
}));

const Logo = styled(Typography)(({ theme }) => ({
  textAlign: 'center',
  marginBottom: theme.spacing(3),
  background: 'linear-gradient(45deg, #3498db, #2980b9)',
  backgroundClip: 'text',
  WebkitBackgroundClip: 'text',
  WebkitTextFillColor: 'transparent',
  fontWeight: 'bold',
  fontSize: '2rem',
}));

interface LoginProps {
  onLogin: () => void;
}

const Login: React.FC<LoginProps> = ({ onLogin }) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [language, setLanguage] = useState('English');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    // Simulate login API call
    try {
      if (username === 'admin' && password === 'admin') {
        localStorage.setItem('authToken', 'demo-token');
        localStorage.setItem('username', username);
        onLogin();
      } else {
        setError('Invalid username or password');
      }
    } catch (err) {
      setError('Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <LoginContainer>
      <LoginCard>
        <CardContent>
          <Logo variant="h4">
            ISP RADIUS
          </Logo>
          <Typography variant="subtitle1" align="center" color="textSecondary" gutterBottom>
            Management System
          </Typography>
          
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 2 }}>
            <TextField
              fullWidth
              label="Username"
              variant="outlined"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              margin="normal"
              required
              autoFocus
            />
            
            <TextField
              fullWidth
              label="Password"
              type="password"
              variant="outlined"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              margin="normal"
              required
            />
            
            <FormControl fullWidth margin="normal">
              <InputLabel>Language</InputLabel>
              <Select
                value={language}
                label="Language"
                onChange={(e) => setLanguage(e.target.value)}
              >
                <MenuItem value="English">English</MenuItem>
                <MenuItem value="Arabic">Arabic</MenuItem>
                <MenuItem value="Kurdish">Kurdish</MenuItem>
                <MenuItem value="Portuguese">Português</MenuItem>
                <MenuItem value="Turkish">Turkish</MenuItem>
              </Select>
            </FormControl>
            
            <Button
              type="submit"
              fullWidth
              variant="contained"
              size="large"
              disabled={loading}
              sx={{
                mt: 3,
                mb: 2,
                py: 1.5,
                background: 'linear-gradient(45deg, #3498db, #2980b9)',
                '&:hover': {
                  background: 'linear-gradient(45deg, #2980b9, #1f5f8b)',
                },
              }}
            >
              {loading ? 'Signing In...' : 'Sign In'}
            </Button>
          </Box>
          
          <Typography variant="caption" align="center" display="block" color="textSecondary">
            Demo credentials: admin / admin
          </Typography>
        </CardContent>
      </LoginCard>
    </LoginContainer>
  );
};

export default Login;

