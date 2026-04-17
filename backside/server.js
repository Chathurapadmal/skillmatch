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