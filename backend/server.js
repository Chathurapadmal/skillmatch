import dotenv from 'dotenv';
import OpenAI from 'openai';
import nodemailer from 'nodemailer';
import * as admin from 'firebase-admin';
import http from 'node:http';
import { readFileSync } from 'node:fs';
import { URL } from 'node:url';

dotenv.config();

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';

    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > 1_000_000) {
        reject(new Error('Request body too large'));
        req.destroy();
      }
    });

    req.on('end', () => {
      if (!raw.trim()) {
        resolve({});
        return;
      }

      try {
        resolve(JSON.parse(raw));
      } catch (error) {
        reject(error);
      }
    });

    req.on('error', reject);
  });
}

function createApp() {
  const routes = [];

  const register = (method, path, handler) => {
    routes.push({ method, path, handler });
  };

  return {
    use() {},
    get(path, handler) {
      register('GET', path, handler);
    },
    post(path, handler) {
      register('POST', path, handler);
    },
    listen(port, host, callback) {
      const server = http.createServer(async (req, res) => {
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
        res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');

        res.status = (code) => {
          res.statusCode = code;
          return res;
        };

        res.json = (payload) => {
          if (!res.headersSent) {
            res.setHeader('Content-Type', 'application/json');
          }
          res.end(JSON.stringify(payload));
          return res;
        };

        if (req.method === 'OPTIONS') {
          res.statusCode = 204;
          res.end();
          return;
        }

        const requestUrl = new URL(req.url || '/', `http://${req.headers.host || host}`);
        req.query = Object.fromEntries(requestUrl.searchParams.entries());

        if (req.method !== 'GET' && req.method !== 'HEAD') {
          try {
            req.body = await readJsonBody(req);
          } catch (error) {
            res.status(400).json({ error: 'Invalid JSON body' });
            return;
          }
        }

        const route = routes.find(
          (entry) => entry.method === req.method && entry.path === requestUrl.pathname
        );

        if (!route) {
          res.status(404).json({ error: 'Not found' });
          return;
        }

        try {
          await route.handler(req, res);
        } catch (error) {
          console.error('Unhandled route error:', error);
          if (!res.headersSent) {
            res.status(500).json({ error: 'Internal server error' });
          }
        }
      });

      let currentPort = port;
      let attempts = 0;
      const maxAttempts = 20;

      const start = () => {
        server.once('error', onError);
        server.listen(currentPort, host, () => {
          if (typeof callback === 'function') {
            callback(currentPort);
          }
        });
      };

      function onError(error) {
        server.off('error', onError);

        if (error?.code === 'EADDRINUSE' && attempts < maxAttempts) {
          attempts += 1;
          const nextPort = currentPort + 1;
          console.warn(`Port ${currentPort} is busy, trying ${nextPort}...`);
          currentPort = nextPort;
          setImmediate(start);
          return;
        }

        throw error;
      }

      start();
      return server;
    },
  };
}

const app = createApp();

const apiKey = process.env.OPENAI_API_KEY;

// Email configuration
const GMAIL_EMAIL = process.env.GMAIL_EMAIL || 'contact.skillmatchteam@gmail.com';
const GMAIL_PASSWORD = process.env.GMAIL_APP_PASSWORD || '';

let transporter = null;

if (GMAIL_EMAIL && GMAIL_PASSWORD) {
  transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: GMAIL_EMAIL,
      pass: GMAIL_PASSWORD,
    },
  });
} else {
  console.warn('Email configuration not complete. Email sending will be disabled.');
}

const openai = apiKey ? new OpenAI({ apiKey }) : null;

let firebaseAdminApp = null;

function getFirebaseAdminApp() {
  if (firebaseAdminApp) return firebaseAdminApp;

  try {
    let serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

    if (!serviceAccountJson) {
      const candidateFiles = [
        './serviceAccountKey.json',
        './firebase-service-account.json',
        './service-account.json',
        './skillmatch-b37cd-firebase-adminsdk-fbsvc-36fce512ed.json',
      ];

      for (const filePath of candidateFiles) {
        try {
          serviceAccountJson = readFileSync(filePath, 'utf8');
          if (serviceAccountJson?.trim()) break;
        } catch (_) {
          // try next file
        }
      }
    }

    if (!serviceAccountJson) return null;

    const serviceAccount = JSON.parse(serviceAccountJson);
    firebaseAdminApp = admin.apps.length
      ? admin.app()
      : admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
    return firebaseAdminApp;
  } catch (error) {
    console.error('Failed to initialize Firebase Admin:', error);
    return null;
  }
}

function requireFirebaseAdminConfig(res) {
  const app = getFirebaseAdminApp();
  if (!app) {
    res.status(500).json({
      error:
        'Firebase Admin is not configured. Set FIREBASE_SERVICE_ACCOUNT_JSON in the backend environment.',
    });
    return null;
  }

  return app;
}

function sanitizeText(value, fallback = '') {
  const text = String(value ?? '').trim();
  return text || fallback;
}

function sanitizeSkills(input) {
  if (!Array.isArray(input)) return [];
  return input
    .map((item) => String(item ?? '').trim())
    .filter(Boolean)
    .slice(0, 20);
}

function extractJsonObject(raw) {
  const text = String(raw ?? '').trim();
  if (!text) throw new Error('Empty model response');

  try {
    return JSON.parse(text);
  } catch (_) {
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    if (start === -1 || end === -1 || end <= start) {
      throw new Error('Model did not return JSON object');
    }
    return JSON.parse(text.slice(start, end + 1));
  }
}

async function generateJson({ systemPrompt, userPrompt }) {
  if (!openai) {
    throw new Error('Missing OPENAI_API_KEY');
  }

  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    temperature: 0.5,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ],
  });

  return extractJsonObject(response.choices?.[0]?.message?.content ?? '');
}

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

// Email sending endpoint
app.post('/api/send-email', async (req, res) => {
  const { to, subject, text, html } = req.body ?? {};

  if (!to || !subject || (!text && !html)) {
    return res.status(400).json({ error: 'to, subject, and text or html are required' });
  }

  if (!transporter) {
    return res.status(500).json({ error: 'Email service is not configured' });
  }

  try {
    await transporter.sendMail({
      from: GMAIL_EMAIL,
      to: to.trim(),
      subject: subject.trim(),
      text: text?.trim(),
      html: html?.trim(),
    });

    res.json({ ok: true, message: 'Email sent successfully' });
  } catch (error) {
    const errorMsg = error?.message || String(error);
    console.error('Email sending error:', errorMsg);
    res.status(500).json({ error: `Failed to send email: ${errorMsg}` });
  }
});

app.post('/api/auth/reset-password', async (req, res) => {
  const { email, newPassword } = req.body ?? {};

  if (!email || !newPassword) {
    return res.status(400).json({
      error: 'email and newPassword are required',
    });
  }

  const appInstance = requireFirebaseAdminConfig(res);
  if (!appInstance) return;

  try {
    const user = await admin.auth().getUserByEmail(String(email).trim());
    await admin.auth().updateUser(user.uid, {
      password: String(newPassword),
    });

    res.json({ ok: true, message: 'Password updated successfully' });
  } catch (error) {
    const errorMsg = error?.message || String(error);
    console.error('Password reset error:', errorMsg);
    res.status(500).json({ error: `Failed to update password: ${errorMsg}` });
  }
});

app.post('/api/auth/verify-email', async (req, res) => {
  const { email } = req.body ?? {};

  if (!email) {
    return res.status(400).json({ error: 'email is required' });
  }

  const appInstance = requireFirebaseAdminConfig(res);
  if (!appInstance) return;

  try {
    const user = await admin.auth().getUserByEmail(String(email).trim());
    await admin.auth().updateUser(user.uid, {
      emailVerified: true,
    });

    try {
      await admin.firestore().collection('users').doc(user.uid).set(
        {
          emailVerified: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    } catch (firestoreError) {
      console.warn('Firestore update failed while verifying email:', firestoreError);
    }

    res.json({ ok: true, message: 'Email verified successfully' });
  } catch (error) {
    const errorMsg = error?.message || String(error);
    console.error('Email verification error:', errorMsg);
    res.status(500).json({ error: `Failed to verify email: ${errorMsg}` });
  }
});

// Route
app.post('/api/generate', async (req, res) => {
  const { prompt, history = [] } = req.body ?? {};

  if (!prompt || typeof prompt !== 'string') {
    return res.status(400).json({ error: 'prompt is required' });
  }

  if (!openai) {
    return res.status(500).json({ error: 'Missing OPENAI_API_KEY' });
  }

  const safeHistory = Array.isArray(history)
    ? history
        .slice(-6)
        .map((item) => String(item ?? '').trim())
        .filter(Boolean)
    : [];

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content:
            'You are SkillMatch AI Support. Give concise, practical, friendly help for student careers, internships, profiles, and app support.',
        },
        ...safeHistory.map((entry) => ({ role: 'user', content: entry })),
        { role: 'user', content: prompt },
      ],
    });

    const generatedText = response.choices[0].message.content;

    res.json({ text: generatedText });
  } catch (error) {
    const errorMsg = error?.message || error?.error?.message || String(error);
    console.error('OpenAI Error:', errorMsg);
    console.error('Full error:', error);
    res.status(500).json({ error: errorMsg || 'Failed to generate text' });
  }
});

app.post('/api/roadmap', async (req, res) => {
  const field = sanitizeText(req.body?.field, 'IT & Software');
  const skills = sanitizeSkills(req.body?.skills);

  try {
    const payload = await generateJson({
      systemPrompt:
        'You generate concise, practical career learning roadmaps for internship applicants. Return JSON only.',
      userPrompt: `Create a roadmap for field "${field}".
Known user skills: ${skills.length ? skills.join(', ') : 'Not provided'}.

Return ONLY valid JSON with this exact shape:
{
  "targetRole": "string",
  "targetCompany": "string",
  "currentMatch": 0,
  "targetMatch": 100,
  "missingSkills": ["string"],
  "steps": [
    {"title": "string", "description": "string", "weeks": 2}
  ]
}

Rules:
- 3 to 6 steps.
- weeks should be an integer between 1 and 8.
- currentMatch between 35 and 80.
- targetMatch between 85 and 100.
- missingSkills should include 4 to 8 practical skills.
- Keep text short and student-friendly.`,
    });

    const stepsRaw = Array.isArray(payload.steps) ? payload.steps : [];
    const steps = stepsRaw
      .map((step) => ({
        title: sanitizeText(step?.title, 'Learning Step'),
        description: sanitizeText(
          step?.description,
          'Build practical knowledge and portfolio strength.'
        ),
        weeks: Math.min(8, Math.max(1, Number(step?.weeks) || 2)),
      }))
      .slice(0, 6);

    const missingSkills = sanitizeSkills(payload.missingSkills).slice(0, 8);

    if (!steps.length) {
      return res.status(500).json({ error: 'Failed to generate roadmap steps' });
    }

    res.json({
      targetRole: sanitizeText(payload.targetRole, `Junior ${field} Specialist`),
      targetCompany: sanitizeText(payload.targetCompany, 'Top internship-ready teams'),
      currentMatch: Math.min(100, Math.max(0, Number(payload.currentMatch) || 58)),
      targetMatch: Math.min(100, Math.max(0, Number(payload.targetMatch) || 90)),
      missingSkills,
      steps,
    });
  } catch (error) {
    const errorMsg = error?.message || error?.error?.message || String(error);
    console.error('Roadmap API Error:', errorMsg);
    res.status(500).json({ error: errorMsg || 'Failed to generate roadmap' });
  }
});

app.post('/api/trends', async (req, res) => {
  const field = sanitizeText(req.body?.field, 'IT & Software');
  const skills = sanitizeSkills(req.body?.skills);

  try {
    const payload = await generateJson({
      systemPrompt:
        'You generate concise industry trend summaries and skill demand forecasts. Return JSON only.',
      userPrompt: `Create industry trend insights for field "${field}".
Candidate current skills: ${skills.length ? skills.join(', ') : 'Not provided'}.

Return ONLY valid JSON with this exact shape:
{
  "industry": "string",
  "overview": "string",
  "trends": [
    {"skill": "string", "demandPct": 75, "yoy": "+6% YoY", "direction": "up"}
  ]
}

Rules:
- Include 5 to 8 trend items.
- demandPct between 35 and 98.
- direction must be one of: up, down, flat.
- overview max 40 words.
- skills should be relevant for entry-level roles.`,
    });

    const trendsRaw = Array.isArray(payload.trends) ? payload.trends : [];
    const trends = trendsRaw
      .map((item) => {
        const directionRaw = sanitizeText(item?.direction, 'up').toLowerCase();
        const direction = ['up', 'down', 'flat'].includes(directionRaw)
          ? directionRaw
          : 'up';
        return {
          skill: sanitizeText(item?.skill, 'Skill'),
          demandPct: Math.min(100, Math.max(0, Number(item?.demandPct) || 50)),
          yoy: sanitizeText(item?.yoy, '+0% YoY'),
          direction,
        };
      })
      .slice(0, 8);

    if (!trends.length) {
      return res.status(500).json({ error: 'Failed to generate trends' });
    }

    res.json({
      industry: sanitizeText(payload.industry, field),
      overview: sanitizeText(
        payload.overview,
        `AI trend model indicates demand is increasing for practical, tool-based skills in ${field} roles.`
      ),
      trends,
    });
  } catch (error) {
    const errorMsg = error?.message || error?.error?.message || String(error);
    console.error('Trends API Error:', errorMsg);
    res.status(500).json({ error: errorMsg || 'Failed to generate trends' });
  }
});

app.post('/api/skill-quiz', async (req, res) => {
  const field = sanitizeText(req.body?.field, 'IT & Software');
  const skill = sanitizeText(req.body?.skill, field);
  const questionCount = Math.min(8, Math.max(3, Number(req.body?.questionCount) || 5));
  const skills = sanitizeSkills(req.body?.skills);

  try {
    const payload = await generateJson({
      systemPrompt:
        'You create multiple-choice quiz questions for skill verification. Return JSON only.',
      userPrompt: `Create ${questionCount} quiz questions for skill "${skill}" in field "${field}".
Candidate skills context: ${skills.length ? skills.join(', ') : 'Not provided'}.

Return ONLY valid JSON with this exact shape:
{
  "questions": [
    {
      "q": "question text",
      "options": ["option1", "option2", "option3", "option4"],
      "correct": 0
    }
  ]
}

Rules:
- Exactly ${questionCount} questions.
- 4 options for each question.
- correct must be an integer index 0..3.
- Keep questions internship-level practical.
- Avoid ambiguous or trick wording.`,
    });

    const questionsRaw = Array.isArray(payload.questions) ? payload.questions : [];
    const questions = questionsRaw
      .map((item) => {
        const options = Array.isArray(item?.options)
          ? item.options.map((opt) => sanitizeText(opt)).filter(Boolean)
          : [];
        if (options.length < 4) return null;

        return {
          q: sanitizeText(item?.q, `What is a best practice in ${skill}?`),
          options: options.slice(0, 4),
          correct: Math.min(3, Math.max(0, Number(item?.correct) || 0)),
        };
      })
      .filter(Boolean)
      .slice(0, questionCount);

    if (questions.length < 3) {
      return res.status(500).json({ error: 'Failed to generate quiz questions' });
    }

    res.json({ questions });
  } catch (error) {
    const errorMsg = error?.message || error?.error?.message || String(error);
    console.error('Skill Quiz API Error:', errorMsg);
    res.status(500).json({ error: errorMsg || 'Failed to generate skill quiz' });
  }
});

app.get('/api/jobs', async (req, res) => {
  const { query, location = 'remote', page = 1 } = req.query;

  if (!query) {
    return res.status(400).json({ error: 'query is required' });
  }

  try {
    const APP_ID = process.env.ADZUNA_APP_ID;
    const APP_KEY = process.env.ADZUNA_APP_KEY;

    if (!APP_ID || !APP_KEY) {
      return res.status(500).json({ error: 'Missing Adzuna API keys' });
    }

    const url = `https://api.adzuna.com/v1/api/jobs/us/search/${page}?app_id=${APP_ID}&app_key=${APP_KEY}&what=${encodeURIComponent(query)}&where=${location}`;

    const response = await fetch(url);
    const data = await response.json();

    const jobs = (data.results || []).map(job => ({
      title: job.title,
      company: job.company?.display_name,
      location: job.location?.display_name,
      description: job.description?.slice(0, 150) + "...",
      salary: job.salary_min || "Not specified",
      url: job.redirect_url,
      source: "Adzuna"
    }));

    res.json({
      count: data.count,
      jobs,
    });
  } catch (error) {
    console.error('Job API Error:', error);
    res.status(500).json({ error: 'Failed to fetch jobs' });
  }
});

const port = Number(process.env.PORT || 5000);
const host = '0.0.0.0';

app.listen(port, host, (boundPort) => {
  console.log(`Server running on http://${host}:${boundPort}`);
});