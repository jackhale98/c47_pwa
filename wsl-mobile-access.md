# WSL2 Mobile Access Setup for C47 Calculator

## The Issue
WSL2 uses a virtual network that isn't directly accessible from your local network. The IP address shown (172.30.144.96) is internal to WSL2.

## Solution: Windows Port Forwarding

### Step 1: Find Your Windows IP Address
On Windows (not in WSL), open Command Prompt or PowerShell and run:
```
ipconfig
```

Look for your active network adapter (WiFi or Ethernet). Find the IPv4 Address, it will look like:
- 192.168.1.xxx
- 192.168.0.xxx  
- 10.0.0.xxx

### Step 2: Set Up Port Forwarding
In Windows PowerShell (Run as Administrator), execute these commands:

```powershell
# Replace 172.30.144.96 with your WSL2 IP if different
netsh interface portproxy add v4tov4 listenport=3000 listenaddress=0.0.0.0 connectport=3000 connectaddress=172.30.144.96
netsh interface portproxy add v4tov4 listenport=8080 listenaddress=0.0.0.0 connectport=8080 connectaddress=172.30.144.96

# To view current port forwards:
netsh interface portproxy show all

# To remove port forwards later:
netsh interface portproxy delete v4tov4 listenport=3000 listenaddress=0.0.0.0
netsh interface portproxy delete v4tov4 listenport=8080 listenaddress=0.0.0.0
```

### Step 3: Allow Through Windows Firewall
Still in PowerShell (Administrator):

```powershell
# Create firewall rules
New-NetFirewallRule -DisplayName "C47 PWA Port 3000" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
New-NetFirewallRule -DisplayName "C47 Broadway Port 8080" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow
```

### Step 4: Update PWA Configuration
The PWA needs to use your Windows IP for the Broadway iframe. In WSL, run:

```bash
# Update the iframe source to use Windows IP
# Replace 192.168.1.100 with your actual Windows IP
sed -i 's/172.30.144.96/192.168.1.100/g' /home/jhale/projects/c47_v2/c47-pwa/public/index.html
```

### Step 5: Access from Mobile
On your mobile device, use your Windows computer's IP:
- **http://[YOUR-WINDOWS-IP]:3000**

For example:
- http://192.168.1.100:3000

## Alternative: Using localhost.run or ngrok

If port forwarding is complex, you can use tunneling services:

### Using localhost.run (no installation needed):
```bash
# In WSL, for the PWA:
ssh -R 80:localhost:3000 localhost.run

# You'll get a public URL like: https://abc123.localhost.run
```

### Using ngrok (requires installation):
```bash
# Install ngrok first
# Then run:
ngrok http 3000

# You'll get a public URL like: https://abc123.ngrok.io
```

## Troubleshooting

1. **Check Windows Firewall**: Make sure ports 3000 and 8080 are allowed
2. **Check WSL2 IP**: It can change on restart. Run `ip addr | grep eth0` in WSL
3. **Restart Services**: After port forwarding, restart the C47 services
4. **Test Locally First**: Try accessing http://localhost:3000 on Windows browser

## Quick Test Commands

In Windows PowerShell:
```powershell
# Test if ports are listening
Test-NetConnection -ComputerName localhost -Port 3000
Test-NetConnection -ComputerName localhost -Port 8080
```

In WSL:
```bash
# Check services are running
ss -tuln | grep -E "3000|8080"
```