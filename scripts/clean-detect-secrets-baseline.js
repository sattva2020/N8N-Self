const fs = require('fs');
const path = require('path');

const BASELINE = path.resolve(__dirname, '..', '.secrets.baseline');

function loadBaseline() {
  const raw = fs.readFileSync(BASELINE, 'utf8');
  return JSON.parse(raw);
}

function saveBaseline(json) {
  json.generated_at = new Date().toISOString();
  fs.writeFileSync(BASELINE, JSON.stringify(json, null, 2));
}

function shouldKeep(filename) {
  const normalized = filename.replace(/\\/g, '/');
  // drop vendor noise
  if (/node_modules\//i.test(normalized)) return false;
  if (/^lightrag/i.test(normalized)) return false;
  if (/^lightrag_conf/i.test(normalized)) return false;
  return true;
}

function clean() {
  const baseline = loadBaseline();
  if (!baseline.results) {
    console.log('No results to clean');
    return;
  }
  const results = baseline.results;
  const cleaned = {};
  for (const key of Object.keys(results)) {
    if (shouldKeep(key)) cleaned[key] = results[key];
  }
  baseline.results = cleaned;
  saveBaseline(baseline);
  console.log('Cleaned baseline. Entries before:', Object.keys(results).length, 'after:', Object.keys(cleaned).length);
}

clean();
