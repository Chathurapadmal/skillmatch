import express from 'express';
import cors from 'cors';
import fetch from 'node-fetch';
import dotenv from 'dotenv';
import OpenAI from 'openai';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const apiKey = process.env.OPENAI_API_KEY;

if (!apiKey) {
  console.error('Missing OPENAI_API_KEY in backside/.env');
  process.exit(1);
}

const openai = new OpenAI({ apiKey });

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

// Route
app.post('/api/generate', async (req, res) => {
  const { prompt, history = [] } = req.body ?? {};

  if (!prompt || typeof prompt !== 'string') {
    return res.status(400).json({ error: 'prompt is required' });
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

app.listen(port, host, () => {
  console.log(`Server running on http://${host}:${port}`);
});