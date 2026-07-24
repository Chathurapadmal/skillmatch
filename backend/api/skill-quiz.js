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
      res.statusCode = 500;
      return res.end(JSON.stringify({ error: 'Failed to generate quiz questions' }));
    }

    res.statusCode = 200;
    res.end(JSON.stringify({ questions }));
  } catch (error) {
    const errorMsg = error?.message || error?.error?.message || String(error);
    console.error('Skill Quiz API Error:', errorMsg);
    res.statusCode = 500;
    res.end(JSON.stringify({ error: errorMsg || 'Failed to generate skill quiz' }));
  }
}
