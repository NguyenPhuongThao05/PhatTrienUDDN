const express = require('express');
const app = express();
const port = 8080;

app.use(express.json());

app.post('/webhook/:type?', (req, res) => {
  const alertType = req.params.type || 'general';
  console.log(`\n=== ${alertType.toUpperCase()} ALERT RECEIVED ===`);
  console.log('Timestamp:', new Date().toISOString());
  console.log('Headers:', req.headers);
  console.log('Body:', JSON.stringify(req.body, null, 2));
  
  // Ghi log vào file
  const fs = require('fs');
  const logData = {
    timestamp: new Date().toISOString(),
    type: alertType,
    headers: req.headers,
    body: req.body
  };
  fs.appendFileSync('alerts.log', JSON.stringify(logData) + '\n');
  
  res.status(200).json({ 
    message: `Alert received successfully`,
    type: alertType,
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'healthy', uptime: process.uptime() });
});

app.listen(port, () => {
  console.log(`Webhook server listening at http://localhost:${port}`);
  console.log('Endpoints:');
  console.log('  POST /webhook - General alerts');
  console.log('  POST /webhook/critical - Critical alerts');
  console.log('  POST /webhook/warning - Warning alerts');
  console.log('  GET /health - Health check');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('Webhook server shutting down...');
  process.exit(0);
});