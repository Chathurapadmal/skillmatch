import nodemailer from 'nodemailer';

// Load local .env in development (no-op on Vercel)
try {
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  await import('dotenv/config');
} catch (_) {}

function jsonResponse(res, code, payload) {
  res.setHeader('Content-Type', 'application/json');
  res.statusCode = code;
  res.end(JSON.stringify(payload));
}

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    return jsonResponse(res, 204, {});
  }

  if (req.method !== 'POST') {
    return jsonResponse(res, 405, { error: 'Method not allowed' });
  }

  let body = '';
  try {
    for await (const chunk of req) {
      body += chunk;
    }
    if (!body.trim()) body = '{}';
    body = JSON.parse(body);
  } catch (err) {
    return jsonResponse(res, 400, { error: 'Invalid JSON body' });
  }

  const { to, subject, text, html } = body ?? {};
  if (!to || !subject || (!text && !html)) {
    return jsonResponse(res, 400, { error: 'to, subject, and text or html are required' });
  }

  const GMAIL_EMAIL = process.env.GMAIL_EMAIL || '';
  const GMAIL_PASSWORD = process.env.GMAIL_APP_PASSWORD || '';

  if (!GMAIL_EMAIL || !GMAIL_PASSWORD) {
    return jsonResponse(res, 500, { error: 'Email service is not configured' });
  }

  try {
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: GMAIL_EMAIL, pass: GMAIL_PASSWORD },
    });

    await transporter.sendMail({
      from: GMAIL_EMAIL,
      to: to.trim(),
      subject: subject.trim(),
      text: text?.trim(),
      html: html?.trim(),
    });

    return jsonResponse(res, 200, { ok: true, message: 'Email sent successfully' });
  } catch (error) {
    const msg = error?.message || String(error);
    console.error('Email sending error:', msg);
    return jsonResponse(res, 500, { error: `Failed to send email: ${msg}` });
  }
}
