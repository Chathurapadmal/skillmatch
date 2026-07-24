# SkillMatch - Local Development Setup

This guide shows how to run the entire SkillMatch project **locally** on your machine without Vercel.

## Prerequisites

- **Flutter SDK** (for the mobile/web app)
- **Node.js 18+** (for the backend server)
- **npm** (comes with Node.js)

## Quick Start (3 Steps)

### Step 1: Start the Backend Server

```bash
cd backend
npm install          # First time only
npm start
```

Expected output:
```
Server running on http://0.0.0.0:5000
```

✅ **Backend is now live on** `http://localhost:5000`

### Step 2: Run the Flutter App

In a **new terminal**, from the project root:

```bash
cd .                 # Make sure you're in /skillmatch
flutter pub get      # First time only
flutter run
```

Select your target device when prompted:
- Android emulator
- iOS simulator
- Web browser
- Physical device

### Step 3: That's It!

The app will **auto-detect** your local backend at `http://localhost:5000` ✨

---

## How the App Finds Your Backend

The app tries to connect in this order:
1. ✅ `http://127.0.0.1:5000` (localhost)
2. ✅ `http://10.0.2.2:5000` (Android emulator default)
3. ✅ `http://192.168.x.x:5000` (other local IPs)
4. ⚠️ `https://skillmatch-ed2u.vercel.app` (fallback only if nothing else works)

**You don't need to configure anything!** The app will automatically find your backend.

---

## Backend System Requirements

All backend features work locally if you have the environment variables set:

### Required (Already Set in .env)
- `OPENAI_API_KEY` ✅ - For AI features (roadmap, trends, quiz)
- `ADZUNA_APP_ID` + `ADZUNA_APP_KEY` ✅ - For job search
- `GMAIL_EMAIL` + `GMAIL_APP_PASSWORD` ✅ - For email sending

### Optional (Will notify if missing)
- `FIREBASE_SERVICE_ACCOUNT_JSON` - Firebase/Firestore features

If a feature requires Firebase, the backend will show an error message. You can:
1. Add the Firebase service account key to `backend/.env`
2. Or skip that feature during testing

---

## Backend API Endpoints

Once running locally, all endpoints are available at `http://localhost:5000`:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Health check |
| `/api/send-email` | POST | Send emails |
| `/api/generate` | POST | AI chat/text generation |
| `/api/roadmap` | POST | Career roadmap generation |
| `/api/trends` | POST | Industry trend analysis |
| `/api/skill-quiz` | POST | Skill quiz questions |
| `/api/jobs` | GET | Job search (Adzuna) |
| `/api/auth/reset-password` | POST | Reset user password |
| `/api/auth/verify-email` | POST | Verify email address |

### Test an Endpoint

```bash
# Test health endpoint
curl http://localhost:5000/health

# Should return:
# {"ok":true}
```

---

## Troubleshooting

### "Backend not reachable" Error
1. ✅ Make sure backend is running: `npm start` in `backend/` folder
2. ✅ Check the port is 5000 (or update in `.env`)
3. ✅ Try opening `http://localhost:5000/health` in browser - should show `{"ok":true}`

### "Cannot resolve OpenAI API"
- Make sure `OPENAI_API_KEY` is in `backend/.env`
- The key is already set, so this shouldn't happen

### "Adzuna API keys missing"
- Job search won't work, but app won't crash
- Add `ADZUNA_APP_ID` and `ADZUNA_APP_KEY` to `backend/.env`
- Already set, so should work fine

### "Email service not configured"
- Email sending won't work, but app won't crash
- Add `GMAIL_EMAIL` and `GMAIL_APP_PASSWORD` to `backend/.env`
- Already set, so should work fine

### Firebase Error
- Firebase features are optional
- Add `FIREBASE_SERVICE_ACCOUNT_JSON` to `backend/.env` if needed
- Or just use the app without Firebase features

---

## Development Tips

### Hot Reload the Backend
If you change backend code, the server auto-reloads on save. No restart needed!

### Hot Reload the Flutter App
```bash
# Press 'r' in terminal while flutter run is active
```

### Debug Backend
```bash
# Run with debug logs
npm start
```

Check the terminal output for errors and API call logs.

### Check Backend Status
```bash
curl -s http://localhost:5000/health | jq .
```

Should output: `{ "ok": true, "status": "healthy" }`

---

## Using Menu Backend Settings

If you need to change the backend URL:

1. **Open the app menu** (top-right corner)
2. Tap **"Backend Server"**
3. Change the URL if needed (or leave it to auto-detect)
4. Tap **"Test Connection"**
5. Tap **"Save URL"**

The app will remember this setting even after restart.

---

## Environment File (.env)

Located at: `backend/.env`

```dotenv
# AI
OPENAI_API_KEY=your-key-here

# Server
PORT=5000
HOST=0.0.0.0

# Jobs
ADZUNA_APP_ID=...
ADZUNA_APP_KEY=...

# Email
GMAIL_EMAIL=...
GMAIL_APP_PASSWORD=...

# Firebase (optional)
FIREBASE_SERVICE_ACCOUNT_JSON=
```

⚠️ **NEVER commit this file to Git** (it's already in `.gitignore`)

---

## Next Steps

- **Deploy to Vercel**: Follow `BACKEND_SETUP_GUIDE.md` for cloud deployment
- **Share with others**: Use the **Backend Server** menu option to point to your machine's IP
- **Debug backends**: Use the test connection feature in the Backend Server dialog

---

## Quick Commands Reference

```bash
# Start backend
cd backend && npm start

# Start Flutter app (web)
flutter run -d chrome

# Start Flutter app (Android emulator)
flutter run -d emulator-5554

# Test backend health
curl http://localhost:5000/health

# View backend logs
... check terminal where npm start is running
```

---

**Local development is ready!** 🚀
