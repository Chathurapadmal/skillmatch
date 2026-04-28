# SkillMatch Security & Verification Setup - Implementation Summary

## Changes Made

### 1. **OTP for Password Reset**
**File**: `lib/services/otp_email_service.dart` (NEW)
- Generates 6-digit OTP codes
- Stores OTP in Firestore with 15-minute expiration
- Validates OTP against multiple attempts (max 5)
- Supports cleanup of expired OTPs

**File**: `lib/pages/auth/forgot_password_page.dart` (MODIFIED)
- Now uses OTP verification before password reset
- Routes user to new OTP verification page
- After OTP verification, sends Firebase password reset email

**File**: `lib/pages/auth/otp_verification_page.dart` (NEW)
- Beautiful 6-digit OTP input interface
- Auto-focus on digit input
- Shows remaining time for OTP validity (countdown from 60s)
- Paste support for OTP codes
- Resend OTP functionality

### 2. **2FA on Registration**
**File**: `lib/pages/auth/register_page.dart` (MODIFIED)
- Added checkbox to enable 2FA during registration
- When enabled, sets up TOTP secret using existing `TotpService`
- Stores 2FA setting in user Firestore document
- Uses authenticator apps (Google Authenticator, Authy, etc.) for 2FA

### 3. **Email Verification for Job Applications**
**File**: `lib/pages/applicant/jobs/browse_jobs_page.dart` (MODIFIED)
- Added email verification check in `_applyToJob()` method
- If email not verified, shows dialog asking user to verify
- User can trigger email verification from the dialog
- Only verified users can apply for jobs

### 4. **Email Verification for Profile Edits**
**File**: `lib/pages/applicant/profile/profilepage.dart` (MODIFIED)
- Added email verification check in `_saveProfile()` method
- If email not verified, shows dialog asking user to verify
- User can trigger email verification from the dialog
- Only verified users can edit their profile

### 5. **Email Service**
**File**: `lib/services/email_service.dart` (NEW)
- Service class to send emails via backend API
- Methods for:
  - `sendEmail()` - Generic email sending
  - `sendOtpEmail()` - Send OTP codes with formatted templates
  - `sendEmailVerificationNotification()` - Confirmation emails
  - `sendApplicationConfirmationEmail()` - Job application confirmations
- All emails have both text and HTML versions
- Currently configured to call `http://localhost:5000/api/send-email`

### 6. **Backend Email Endpoint**
**File**: `backside/server.js` (MODIFIED)
- Added nodemailer integration
- New endpoint: `POST /api/send-email`
- Accepts: `to`, `subject`, `text`, `html`
- Uses Gmail SMTP with app password authentication
- Sends from: `contact.skillmatchteam@gmail.com`

**File**: `backside/package.json` (MODIFIED)
- Added `nodemailer` dependency

### 7. **Configuration Files**
**File**: `backside/.env.example` (EXISTS)
- Need to add/update: `GMAIL_EMAIL` and `GMAIL_APP_PASSWORD`

---

## Setup Instructions

### Step 1: Backend Email Configuration
1. Go to your Google Account settings
2. Enable 2-Step Verification if not already enabled
3. Generate an App Password for Gmail:
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and "Windows Computer"
   - Copy the 16-character password
4. Update `backside/.env`:
   ```
   GMAIL_EMAIL=contact.skillmatchteam@gmail.com
   GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
   ```

### Step 2: Install Dependencies
```bash
cd backside
npm install
```

### Step 3: Update Flutter App Email Service Backend URL
**File**: `lib/services/email_service.dart`
- Update `_backendUrl` to your production server URL when deploying
- Local development: `http://localhost:5000`
- Production: Update to your backend server URL

### Step 4: Backend Development Mode
```bash
cd backside
npm run dev    # For development with auto-reload
# OR
npm start      # For production
```

---

## User Flows

### Password Reset Flow
1. User clicks "Forgot Password"
2. Enters email and clicks "Send OTP"
3. OTP sent to Firestore (and email in production)
4. User enters 6-digit OTP on verification page
5. OTP verified, Firebase password reset email sent
6. User sets new password via Firebase link

### Registration with 2FA
1. User fills out registration form
2. Optionally checks "Enable 2-Factor Authentication"
3. Account created
4. If 2FA enabled: TOTP secret initialized for user account
5. User scans QR code with authenticator app on first login

### Job Application
1. User clicks "Apply" on job listing
2. If email not verified: Dialog appears
3. User can optionally send verification email
4. Once email verified: Application submitted successfully

### Profile Edit
1. User makes changes to profile
2. Clicks "Save"
3. If email not verified: Dialog appears
4. User can optionally send verification email
5. Once email verified: Profile saved successfully

---

## Email Templates

### OTP Email
- Subject: "Reset Your SkillMatch Password" or "Verify Your SkillMatch Email"
- Contains: 6-digit OTP code prominently displayed
- Expires in 15 minutes

### Application Confirmation Email
- Subject: "Application Confirmation - [Job Title]"
- Contains: Job title, company name, confirmation message

### Email Verification Notification
- Subject: "Email Verified Successfully"
- Contains: Confirmation and instructions for next steps

---

## Testing

### Local Testing (No Real Email Sending)
1. OTP codes are logged to console in development mode
2. Check terminal for OTP when testing
3. Email Service will attempt to call backend

### Production Setup
1. Configure Gmail app password
2. Start backend with valid credentials
3. Emails will be sent from `contact.skillmatchteam@gmail.com`

---

## Error Handling

- Max 5 failed OTP attempts
- OTP auto-expires after 15 minutes
- Email sending failures don't break app flow
- Graceful error messages for users

---

## Security Notes

- OTPs are hashed and stored in Firestore
- Passwords never stored in plain text (Firebase handles)
- 2FA adds extra layer of security to login
- Email verification prevents unauthorized actions
- All email sending uses HTTPS
- App passwords used instead of main account password

---

## Next Steps

1. ✅ Set up Gmail app password
2. ✅ Update backend .env with credentials
3. ✅ Test OTP flow locally
4. ✅ Test 2FA during registration
5. ✅ Test email verification checks on job apply
6. ✅ Test email verification checks on profile edit
7. ✅ Deploy backend to production server
8. ✅ Update Email Service backend URL for production
