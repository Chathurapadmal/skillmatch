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
      res.statusCode = 500;
      return res.end(JSON.stringify({ error: 'Failed to generate trends' }));
    }

    res.statusCode = 200;
    res.end(JSON.stringify({
      industry: sanitizeText(payload.industry, field),
      overview: sanitizeText(
        payload.overview,
        `AI trend model indicates demand is increasing for practical, tool-based skills in ${field} roles.`
      ),
      trends,
    }));
  } catch (error) {
    const errorMsg = error?.message || error?.error?.message || String(error);
    console.error('Trends API Error:', errorMsg);
    res.statusCode = 500;
    res.end(JSON.stringify({ error: errorMsg || 'Failed to generate trends' }));
  }
}
