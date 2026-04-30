# Running Backend on Different Machines

## Quick Start: Connect Your Friend's Laptop to Your Backend

### Step 1: Start the Backend Server

On the machine where you want to host the backend:

```bash
cd backend
npm install  # (first time only)
npm start
```

The server will start on:
```
http://0.0.0.0:5000
```

Look for this output:
```
Server running on http://0.0.0.0:5000
```

### Step 2: Find Your Machine's IP Address

**On Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" under your network adapter (usually something like `192.168.x.x`)

**On Mac/Linux:**
```bash
hostname -I
```
or
```bash
ifconfig
```
Look for "inet" address (not 127.0.0.1)

### Step 3: Configure the Frontend on Friend's Device

On your friend's device running the Flutter app:

1. Open the menu (top-right corner)
2. Tap **"Backend Server"**
3. Enter the backend URL: `http://YOUR_MACHINE_IP:5000`
   - Example: `http://192.168.1.100:5000`
4. Tap **"Test Connection"** - you should see ✓ Connection successful!
5. Tap **"Save URL"**
6. Restart the app

### Step 4: Verify Connection

The app should now connect to your backend. If it still doesn't work:

- ✓ Both machines must be on the **same WiFi network**
- ✓ Check that no firewall is blocking port 5000
- ✓ Verify the correct IP address (not localhost or 127.0.0.1)

## Firewall Configuration

### Windows Firewall
1. Go to Windows Defender Firewall → Advanced Settings
2. Select "Inbound Rules" → "New Rule"
3. Choose "Port" → Next
4. Select "TCP" and enter port **5000**
5. Allow the connection

### Mac Firewall
1. System Preferences → Security & Privacy → Firewall Options
2. Add your Node.js to allowed apps

### Linux Firewall (ufw)
```bash
sudo ufw allow 5000/tcp
```

## Environment Variables

Create a `.env` file in the `backend/` directory:

```env
PORT=5000
# Optional: specify a specific IP to bind to
# HOST=0.0.0.0

# Firebase
FIREBASE_SERVICE_ACCOUNT_JSON=./skillmatch-b37cd-firebase-adminsdk-fbsvc-36fce512ed.json

# Email (Gmail)
GMAIL_EMAIL=your-email@gmail.com
GMAIL_APP_PASSWORD=your-app-specific-password

# AI
OPENAI_API_KEY=sk-...
```

## Troubleshooting

### "Cannot reach API" Error
1. Verify backend is running: `npm start`
2. Check firewall isn't blocking port 5000
3. Use correct IP address (not localhost)
4. Both devices must be on same WiFi

### Connection TimeOut
- Increase timeout in Backend Settings dialog
- Check for network issues between devices

### Backend Running but App Says Not Found
1. Tap "Test Connection" in Backend Server settings
2. If test fails, check that the URL format is correct: `http://IP:PORT`
3. Ensure no trailing slashes

## Environment-Specific URLs

The app automatically tries these URLs in order:
1. User-specified URL (from Backend Settings)
2. Environment variable `API_BASE_URL`
3. Android/iOS candidates: `10.0.2.2:5000`, local IPs from your network
4. Production: `https://skillmatch-ed2u.vercel.app`

## Docker (Advanced)

To run the backend in Docker and make it accessible:

```bash
docker build -t skillmatch-backend ./backend
docker run -p 5000:5000 \
  -e FIREBASE_SERVICE_ACCOUNT_JSON="$(cat backend/skillmatch-b37cd-firebase-adminsdk-fbsvc-36fce512ed.json)" \
  skillmatch-backend
```

Then use your host machine's IP: `http://HOST_IP:5000`
