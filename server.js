const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_FILE = process.env.DATA_FILE || '/data/shared-text.txt';

// Middleware
app.use(bodyParser.text({ limit: '10mb', type: 'text/plain' }));
app.use(express.static('public'));

// Ensure data directory exists
const dataDir = path.dirname(DATA_FILE);
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// Initialize file if it doesn't exist
if (!fs.existsSync(DATA_FILE)) {
  fs.writeFileSync(DATA_FILE, '', 'utf8');
}

// GET endpoint to retrieve the current text
app.get('/api/text', (req, res) => {
  try {
    const text = fs.readFileSync(DATA_FILE, 'utf8');
    res.setHeader('Content-Type', 'text/plain');
    res.send(text);
  } catch (error) {
    console.error('Error reading file:', error);
    res.status(500).send('Error reading text');
  }
});

// POST endpoint to update the text
app.post('/api/text', (req, res) => {
  try {
    const newText = req.body || '';
    
    // Validate size (10MB limit)
    if (Buffer.byteLength(newText, 'utf8') > 10 * 1024 * 1024) {
      return res.status(400).send('Text exceeds 10MB limit');
    }
    
    fs.writeFileSync(DATA_FILE, newText, 'utf8');
    res.send('Text updated successfully');
  } catch (error) {
    console.error('Error writing file:', error);
    res.status(500).send('Error updating text');
  }
});

// Serve the main page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Data file: ${DATA_FILE}`);
});

