import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  TextField,
  Button,
  Switch,
  FormControlLabel,
  Tabs,
  Tab,
  Divider,
} from '@mui/material';

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
      id={`settings-tabpanel-${index}`}
      aria-labelledby={`settings-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ p: 3 }}>
          {children}
        </Box>
      )}
    </div>
  );
}

const Settings: React.FC = () => {
  const [tabValue, setTabValue] = useState(0);

  const handleTabChange = (event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        System Settings
      </Typography>

      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tabs value={tabValue} onChange={handleTabChange}>
          <Tab label="General" />
          <Tab label="System" />
          <Tab label="Security" />
          <Tab label="Notifications" />
          <Tab label="RADIUS" />
        </Tabs>
      </Box>

      <TabPanel value={tabValue} index={0}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              General Settings
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <TextField
                label="Company Name"
                defaultValue="ISP Company"
                fullWidth
              />
              <TextField
                label="Admin Email"
                defaultValue="admin@isp.com"
                fullWidth
              />
              <TextField
                label="Timezone"
                defaultValue="UTC"
                fullWidth
              />
              <TextField
                label="Currency"
                defaultValue="USD"
                fullWidth
              />
              <Button variant="contained" sx={{ alignSelf: 'flex-start' }}>
                Save Changes
              </Button>
            </Box>
          </CardContent>
        </Card>
      </TabPanel>

      <TabPanel value={tabValue} index={1}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              System Configuration
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <TextField
                label="Session Timeout (minutes)"
                defaultValue="30"
                type="number"
                fullWidth
              />
              <TextField
                label="Max Users"
                defaultValue="1000"
                type="number"
                fullWidth
              />
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Enable Auto Backup"
              />
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Enable Logging"
              />
              <Button variant="contained" sx={{ alignSelf: 'flex-start' }}>
                Save Changes
              </Button>
            </Box>
          </CardContent>
        </Card>
      </TabPanel>

      <TabPanel value={tabValue} index={2}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Security Settings
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <FormControlLabel
                control={<Switch />}
                label="Enable Two-Factor Authentication"
              />
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Force Strong Passwords"
              />
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Enable Audit Logging"
              />
              <TextField
                label="Password Min Length"
                defaultValue="8"
                type="number"
                fullWidth
              />
              <Button variant="contained" sx={{ alignSelf: 'flex-start' }}>
                Save Changes
              </Button>
            </Box>
          </CardContent>
        </Card>
      </TabPanel>

      <TabPanel value={tabValue} index={3}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Notification Settings
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Email Notifications"
              />
              <FormControlLabel
                control={<Switch />}
                label="SMS Notifications"
              />
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="System Alerts"
              />
              <TextField
                label="SMTP Server"
                defaultValue="smtp.gmail.com"
                fullWidth
              />
              <Button variant="contained" sx={{ alignSelf: 'flex-start' }}>
                Save Changes
              </Button>
            </Box>
          </CardContent>
        </Card>
      </TabPanel>

      <TabPanel value={tabValue} index={4}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              RADIUS Configuration
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <TextField
                label="Auth Port"
                defaultValue="1812"
                type="number"
                fullWidth
              />
              <TextField
                label="Accounting Port"
                defaultValue="1813"
                type="number"
                fullWidth
              />
              <TextField
                label="Shared Secret"
                defaultValue="testing123"
                type="password"
                fullWidth
              />
              <TextField
                label="Session Timeout"
                defaultValue="3600"
                type="number"
                fullWidth
              />
              <Button variant="contained" sx={{ alignSelf: 'flex-start' }}>
                Save Changes
              </Button>
            </Box>
          </CardContent>
        </Card>
      </TabPanel>
    </Box>
  );
};

export default Settings;

