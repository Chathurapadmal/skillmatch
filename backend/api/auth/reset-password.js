import { sanitizeText, requireFirebaseAdminConfig } from '../_utils.js';
import * as admin from 'firebase-admin';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'POST');
  res.setHeader('Content-Type', 'application/json');

  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.end();
    return;
  }

  if (req.method !== 'POST') {
    res.statusCode = 405;
    res.end(JSON.stringify({ error: 'Method not allowed' }));
    return;
  }

  const { email, newPassword } = req.body ?? {};

  if (!email || !newPassword) {
    res.statusCode = 400;
    return res.end(JSON.stringify({
      error: 'email and newPassword are required',
    }));
  }

  const appInstance = requireFirebaseAdminConfig(res);
  if (!appInstance) return;

  try {
    const user = await admin.auth().getUserByEmail(String(email).trim());
    await admin.auth().updateUser(user.uid, {
      password: String(newPassword),
    });

    res.statusCode = 200;
    res.end(JSON.stringify({ ok: true, message: 'Password updated successfully' }));
  } catch (error) {
    const errorMsg = error?.message || String(error);
    console.error('Password reset error:', errorMsg);
    res.statusCode = 500;
    res.end(JSON.stringify({ error: `Failed to update password: ${errorMsg}` }));
  }
}
