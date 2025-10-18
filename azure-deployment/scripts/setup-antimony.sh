#!/bin/bash


set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

log_info "Starting Antimony GUI setup..."


log_info "Installing Node.js..."

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

log_success "Node.js $(node --version) installed"


log_info "Setting up Antimony..."

ANTIMONY_DIR="/opt/antimony"
mkdir -p $ANTIMONY_DIR
cd $ANTIMONY_DIR

cat > package.json <<'EOF'
{
  "name": "antimony-gui",
  "version": "1.0.0",
  "description": "Antimony GUI for ContainerLab",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "body-parser": "^1.20.2",
    "cors": "^2.8.5",
    "js-yaml": "^4.1.0",
    "child_process": "^1.0.2"
  }
}
EOF

# Install dependencies
npm install

cat > server.js <<'EOF'
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const yaml = require('js-yaml');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 8080;

app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// API Routes

// Get all labs
app.get('/api/labs', (req, res) => {
    exec('containerlab inspect --all --format json', (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: stderr });
        }
        try {
            const labs = JSON.parse(stdout);
            res.json(labs);
        } catch (e) {
            res.json([]);
        }
    });
});

// Get lab details
app.get('/api/labs/:name', (req, res) => {
    const labName = req.params.name;
    exec(`containerlab inspect --name ${labName} --format json`, (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: stderr });
        }
        res.json(JSON.parse(stdout));
    });
});

// Deploy lab
app.post('/api/labs/deploy', (req, res) => {
    const { topology } = req.body;
    const labFile = `/tmp/lab-${Date.now()}.clab.yml`;
    
    fs.writeFileSync(labFile, yaml.dump(topology));
    
    exec(`containerlab deploy -t ${labFile}`, (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: stderr, output: stdout });
        }
        res.json({ success: true, output: stdout });
    });
});

// Destroy lab
app.delete('/api/labs/:name', (req, res) => {
    const labName = req.params.name;
    exec(`containerlab destroy --name ${labName}`, (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: stderr });
        }
        res.json({ success: true, output: stdout });
    });
});

// Get container logs
app.get('/api/containers/:name/logs', (req, res) => {
    const containerName = req.params.name;
    exec(`docker logs --tail 100 ${containerName}`, (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: stderr });
        }
        res.json({ logs: stdout });
    });
});

// Execute command in container
app.post('/api/containers/:name/exec', (req, res) => {
    const containerName = req.params.name;
    const { command } = req.body;
    
    exec(`docker exec ${containerName} ${command}`, (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: stderr, output: stdout });
        }
        res.json({ output: stdout });
    });
});

// Get available images
app.get('/api/images', (req, res) => {
    exec('docker images --format json', (error, stdout, stderr) => {
        if (error) {
            return res.status(500).json({ error: stderr });
        }
        const images = stdout.trim().split('\n').map(line => JSON.parse(line));
        res.json(images);
    });
});

// List lab files
app.get('/api/lab-files', (req, res) => {
    const labsDir = '/data/labs';
    fs.readdir(labsDir, (err, files) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        const labFiles = files.filter(f => f.endsWith('.clab.yml'));
        res.json(labFiles);
    });
});

// Get lab file content
app.get('/api/lab-files/:filename', (req, res) => {
    const filename = req.params.filename;
    const filepath = path.join('/data/labs', filename);
    
    fs.readFile(filepath, 'utf8', (err, data) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        try {
            const topology = yaml.load(data);
            res.json({ filename, content: data, topology });
        } catch (e) {
            res.status(500).json({ error: 'Invalid YAML' });
        }
    });
});

// Save lab file
app.post('/api/lab-files', (req, res) => {
    const { filename, content } = req.body;
    const filepath = path.join('/data/labs', filename);
    
    fs.writeFile(filepath, content, 'utf8', (err) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        res.json({ success: true });
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Antimony GUI running on http://0.0.0.0:${PORT}`);
});
EOF

mkdir -p public

cat > public/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Antimony GUI - ContainerLab Manager</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        header p {
            font-size: 1.2em;
            opacity: 0.9;
        }
        
        .tabs {
            display: flex;
            background: #f5f5f5;
            border-bottom: 2px solid #ddd;
        }
        
        .tab {
            flex: 1;
            padding: 15px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
            border: none;
            background: transparent;
            font-size: 1.1em;
        }
        
        .tab:hover {
            background: #e0e0e0;
        }
        
        .tab.active {
            background: white;
            border-bottom: 3px solid #667eea;
            font-weight: bold;
        }
        
        .content {
            padding: 30px;
        }
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .lab-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .lab-card {
            border: 1px solid #ddd;
            border-radius: 10px;
            padding: 20px;
            background: #f9f9f9;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        
        .lab-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
        }
        
        .lab-card h3 {
            color: #667eea;
            margin-bottom: 10px;
        }
        
        .lab-card .status {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 5px;
            font-size: 0.9em;
            margin: 10px 0;
        }
        
        .status.running {
            background: #4caf50;
            color: white;
        }
        
        .status.stopped {
            background: #f44336;
            color: white;
        }
        
        button {
            background: #667eea;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            margin: 5px;
            transition: background 0.3s;
        }
        
        button:hover {
            background: #5568d3;
        }
        
        button.danger {
            background: #f44336;
        }
        
        button.danger:hover {
            background: #da190b;
        }
        
        .info-box {
            background: #e3f2fd;
            border-left: 4px solid #2196f3;
            padding: 15px;
            margin: 20px 0;
            border-radius: 5px;
        }
        
        textarea {
            width: 100%;
            min-height: 400px;
            font-family: 'Courier New', monospace;
            padding: 15px;
            border: 1px solid #ddd;
            border-radius: 5px;
            margin: 10px 0;
        }
        
        .file-list {
            list-style: none;
        }
        
        .file-list li {
            padding: 10px;
            border-bottom: 1px solid #ddd;
            cursor: pointer;
            transition: background 0.3s;
        }
        
        .file-list li:hover {
            background: #f5f5f5;
        }
        
        .loading {
            text-align: center;
            padding: 50px;
            font-size: 1.2em;
            color: #667eea;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🔬 Antimony GUI</h1>
            <p>ContainerLab Topology Manager</p>
        </header>
        
        <div class="tabs">
            <button class="tab active" onclick="showTab('labs')">Active Labs</button>
            <button class="tab" onclick="showTab('files')">Lab Files</button>
            <button class="tab" onclick="showTab('images')">Images</button>
            <button class="tab" onclick="showTab('editor')">Editor</button>
        </div>
        
        <div class="content">
            <div id="labs" class="tab-content active">
                <h2>Active Labs</h2>
                <div class="info-box">
                    <strong>Info:</strong> These are currently deployed ContainerLab topologies.
                </div>
                <button onclick="refreshLabs()">🔄 Refresh</button>
                <div id="labs-list" class="lab-grid">
                    <div class="loading">Loading labs...</div>
                </div>
            </div>
            
            <div id="files" class="tab-content">
                <h2>Lab Files</h2>
                <div class="info-box">
                    <strong>Info:</strong> Available lab topology files in /data/labs
                </div>
                <button onclick="refreshFiles()">🔄 Refresh</button>
                <ul id="files-list" class="file-list">
                    <li class="loading">Loading files...</li>
                </ul>
            </div>
            
            <div id="images" class="tab-content">
                <h2>Container Images</h2>
                <div class="info-box">
                    <strong>Info:</strong> Available Docker images for use in labs
                </div>
                <button onclick="refreshImages()">🔄 Refresh</button>
                <div id="images-list" class="lab-grid">
                    <div class="loading">Loading images...</div>
                </div>
            </div>
            
            <div id="editor" class="tab-content">
                <h2>Lab Editor</h2>
                <div class="info-box">
                    <strong>Info:</strong> Create or edit ContainerLab topology files
                </div>
                <input type="text" id="filename" placeholder="lab-name.clab.yml" style="width: 100%; padding: 10px; margin: 10px 0;">
                <textarea id="editor-content" placeholder="Enter YAML topology here..."></textarea>
                <button onclick="saveLab()">💾 Save Lab</button>
                <button onclick="deployFromEditor()">🚀 Deploy Lab</button>
            </div>
        </div>
    </div>
    
    <script>
        const API_BASE = '';
        
        function showTab(tabName) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            
            event.target.classList.add('active');
            document.getElementById(tabName).classList.add('active');
            
            if (tabName === 'labs') refreshLabs();
            if (tabName === 'files') refreshFiles();
            if (tabName === 'images') refreshImages();
        }
        
        async function refreshLabs() {
            const container = document.getElementById('labs-list');
            container.innerHTML = '<div class="loading">Loading labs...</div>';
            
            try {
                const response = await fetch(`${API_BASE}/api/labs`);
                const labs = await response.json();
                
                if (!labs || labs.length === 0) {
                    container.innerHTML = '<p>No active labs found</p>';
                    return;
                }
                
                container.innerHTML = '';
                labs.forEach(lab => {
                    const card = document.createElement('div');
                    card.className = 'lab-card';
                    card.innerHTML = `
                        <h3>${lab.name || 'Unknown'}</h3>
                        <span class="status running">Running</span>
                        <p><strong>Nodes:</strong> ${lab.containers?.length || 0}</p>
                        <button onclick="destroyLab('${lab.name}')">🗑️ Destroy</button>
                    `;
                    container.appendChild(card);
                });
            } catch (error) {
                container.innerHTML = '<p>Error loading labs</p>';
                console.error(error);
            }
        }
        
        async function refreshFiles() {
            const list = document.getElementById('files-list');
            list.innerHTML = '<li class="loading">Loading files...</li>';
            
            try {
                const response = await fetch(`${API_BASE}/api/lab-files`);
                const files = await response.json();
                
                list.innerHTML = '';
                files.forEach(file => {
                    const li = document.createElement('li');
                    li.textContent = file;
                    li.onclick = () => loadFile(file);
                    list.appendChild(li);
                });
            } catch (error) {
                list.innerHTML = '<li>Error loading files</li>';
                console.error(error);
            }
        }
        
        async function loadFile(filename) {
            try {
                const response = await fetch(`${API_BASE}/api/lab-files/${filename}`);
                const data = await response.json();
                
                document.getElementById('filename').value = filename;
                document.getElementById('editor-content').value = data.content;
                showTab('editor');
            } catch (error) {
                alert('Error loading file');
                console.error(error);
            }
        }
        
        async function refreshImages() {
            const container = document.getElementById('images-list');
            container.innerHTML = '<div class="loading">Loading images...</div>';
            
            try {
                const response = await fetch(`${API_BASE}/api/images`);
                const images = await response.json();
                
                container.innerHTML = '';
                images.forEach(image => {
                    const card = document.createElement('div');
                    card.className = 'lab-card';
                    card.innerHTML = `
                        <h3>${image.Repository}</h3>
                        <p><strong>Tag:</strong> ${image.Tag}</p>
                        <p><strong>Size:</strong> ${image.Size}</p>
                    `;
                    container.appendChild(card);
                });
            } catch (error) {
                container.innerHTML = '<p>Error loading images</p>';
                console.error(error);
            }
        }
        
        async function saveLab() {
            const filename = document.getElementById('filename').value;
            const content = document.getElementById('editor-content').value;
            
            if (!filename || !content) {
                alert('Please provide filename and content');
                return;
            }
            
            try {
                const response = await fetch(`${API_BASE}/api/lab-files`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ filename, content })
                });
                
                if (response.ok) {
                    alert('Lab saved successfully!');
                    refreshFiles();
                } else {
                    alert('Error saving lab');
                }
            } catch (error) {
                alert('Error saving lab');
                console.error(error);
            }
        }
        
        async function deployFromEditor() {
            const content = document.getElementById('editor-content').value;
            
            if (!content) {
                alert('Please provide topology content');
                return;
            }
            
            try {
                const topology = jsyaml.load(content);
                const response = await fetch(`${API_BASE}/api/labs/deploy`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ topology })
                });
                
                if (response.ok) {
                    alert('Lab deployed successfully!');
                    showTab('labs');
                    refreshLabs();
                } else {
                    const error = await response.json();
                    alert('Error deploying lab: ' + error.error);
                }
            } catch (error) {
                alert('Error deploying lab');
                console.error(error);
            }
        }
        
        async function destroyLab(labName) {
            if (!confirm(`Are you sure you want to destroy lab "${labName}"?`)) {
                return;
            }
            
            try {
                const response = await fetch(`${API_BASE}/api/labs/${labName}`, {
                    method: 'DELETE'
                });
                
                if (response.ok) {
                    alert('Lab destroyed successfully!');
                    refreshLabs();
                } else {
                    alert('Error destroying lab');
                }
            } catch (error) {
                alert('Error destroying lab');
                console.error(error);
            }
        }
        
        // Initial load
        refreshLabs();
    </script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/js-yaml/4.1.0/js-yaml.min.js"></script>
</body>
</html>
EOF

log_success "Antimony GUI files created"


log_info "Creating systemd service..."

cat > /etc/systemd/system/antimony-gui.service <<EOF
[Unit]
Description=Antimony GUI for ContainerLab
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=$ANTIMONY_DIR
ExecStart=/usr/bin/node $ANTIMONY_DIR/server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable antimony-gui.service
systemctl start antimony-gui.service

log_success "Antimony GUI service created and started"


log_info "Configuring firewall..."

if command -v ufw &> /dev/null; then
    ufw allow 8080/tcp
    log_success "Firewall configured"
fi

# Display summary

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║              Antimony GUI Installation Complete                  ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""
echo "✓ Antimony GUI installed at $ANTIMONY_DIR"
echo "✓ Service running on port 8080"
echo ""
echo "Access the GUI at:"
echo "  http://$(hostname -I | awk '{print $1}'):8080"
echo "  http://$(hostname -f):8080"
echo ""
echo "Service management:"
echo "  systemctl status antimony-gui"
echo "  systemctl restart antimony-gui"
echo "  systemctl stop antimony-gui"
echo ""
echo "Logs:"
echo "  journalctl -u antimony-gui -f"
echo ""

exit 0
