export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'GET');
  res.setHeader('Content-Type', 'application/json');

  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    res.end();
    return;
  }

  if (req.method !== 'GET') {
    res.statusCode = 405;
    res.end(JSON.stringify({ error: 'Method not allowed' }));
    return;
  }

  const { query, location = 'remote', page = 1 } = req.query;

  if (!query) {
    res.statusCode = 400;
    return res.end(JSON.stringify({ error: 'query is required' }));
  }

  try {
    const APP_ID = process.env.ADZUNA_APP_ID;
    const APP_KEY = process.env.ADZUNA_APP_KEY;

    if (!APP_ID || !APP_KEY) {
      res.statusCode = 500;
      return res.end(JSON.stringify({ error: 'Missing Adzuna API keys' }));
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

    res.statusCode = 200;
    res.end(JSON.stringify({
      count: data.count,
      jobs,
    }));
  } catch (error) {
    console.error('Job API Error:', error);
    res.statusCode = 500;
    res.end(JSON.stringify({ error: 'Failed to fetch jobs' }));
  }
}
