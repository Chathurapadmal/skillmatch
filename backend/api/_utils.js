// Shared utilities for API endpoints
import dotenv from 'dotenv';
import OpenAI from 'openai';
import nodemailer from 'nodemailer';
import * as admin from 'firebase-admin';
import { readFileSync } from 'node:fs';

dotenv.config();

export const apiKey = process.env.OPENAI_API_KEY;

export const GMAIL_EMAIL = process.env.GMAIL_EMAIL || 'contact.skillmatchteam@gmail.com';
export const GMAIL_PASSWORD = process.env.GMAIL_APP_PASSWORD || '';

let transporter = null;

export function getTransporter() {
  if (transporter) return transporter;
  
  if (GMAIL_EMAIL && GMAIL_PASSWORD) {
    transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: GMAIL_EMAIL,
        pass: GMAIL_PASSWORD,
      },
    });
  }
  return transporter;
}

export const openai = apiKey ? new OpenAI({ apiKey }) : null;

let firebaseAdminApp = null;

export function getFirebaseAdminApp() {
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

export function requireFirebaseAdminConfig(res) {
  const app = getFirebaseAdminApp();
  if (!app) {
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({
      error: 'Firebase Admin is not configured. Set FIREBASE_SERVICE_ACCOUNT_JSON in the environment.',
    }));
    return null;
  }
  return app;
}

export function sanitizeText(value, fallback = '') {
  const text = String(value ?? '').trim();
  return text || fallback;
}

export function sanitizeSkills(input) {
  if (!Array.isArray(input)) return [];
  return input
    .map((item) => String(item ?? '').trim())
    .filter(Boolean)
    .slice(0, 20);
}

export function extractJsonObject(raw) {
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

export async function generateJson({ systemPrompt, userPrompt }) {
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

export function setCorsHeaders(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Content-Type', 'application/json');
}

export function readJsonBody(req) {
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
