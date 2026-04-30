import {
  sanitizeText,
  sanitizeSkills,
  generateJson,
} from './_utils.js';

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

  const field = sanitizeText(req.body?.field || req.query?.field, 'IT & Software');
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
      res.statusCode = 500;
      return res.end(JSON.stringify({ error: 'Failed to generate roadmap steps' }));
    }

    res.statusCode = 200;
    res.end(JSON.stringify({
      targetRole: sanitizeText(payload.targetRole, `Junior ${field} Specialist`),
      targetCompany: sanitizeText(payload.targetCompany, 'Top internship-ready teams'),
      currentMatch: Math.min(100, Math.max(0, Number(payload.currentMatch) || 58)),
      targetMatch: Math.min(100, Math.max(0, Number(payload.targetMatch) || 90)),
      missingSkills,
      steps,
    }));
  } catch (error) {
    const errorMsg = error?.message || error?.error?.message || String(error);
    console.error('Roadmap API Error:', errorMsg);
    res.statusCode = 500;
    res.end(JSON.stringify({ error: errorMsg || 'Failed to generate roadmap' }));
  }
}
