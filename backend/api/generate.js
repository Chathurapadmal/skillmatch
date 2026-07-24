import { openai } from './_utils.js';

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

  const { prompt, history = [] } = req.body ?? {};

  if (!prompt || typeof prompt !== 'string') {
    res.statusCode = 400;
    return res.end(JSON.stringify({ error: 'prompt is required' }));
  }

  if (!openai) {
    res.statusCode = 500;
    return res.end(JSON.stringify({ error: 'Missing OPENAI_API_KEY' }));
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

    res.statusCode = 200;
    res.end(JSON.stringify({ text: generatedText }));
  } catch (error) {
    const errorMsg = error?.message || error?.error?.message || String(error);
    console.error('OpenAI Error:', errorMsg);
    console.error('Full error:', error);
    res.statusCode = 500;
    res.end(JSON.stringify({ error: errorMsg || 'Failed to generate text' }));
  }
}
