// Пример обмена code -> access token для Miro OAuth
// Используйте node 18+

import fetch from 'node-fetch';

async function exchangeCode({ clientId, clientSecret, code, redirectUri }) {
  const tokenUrl = 'https://api.miro.com/v1/oauth/token';
  const params = new URLSearchParams();
  params.append('grant_type', 'authorization_code');
  params.append('code', code);
  params.append('redirect_uri', redirectUri);
  params.append('client_id', clientId);
  params.append('client_secret', clientSecret);

  const res = await fetch(tokenUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token exchange failed: ${res.status} ${text}`);
  }

  const data = await res.json();
  return data; // { access_token, refresh_token, expires_in, token_type }
}

// CLI support
if (process.argv.length >= 6) {
  const [,, clientId, clientSecret, code, redirectUri] = process.argv;
  exchangeCode({ clientId, clientSecret, code, redirectUri })
    .then(d => console.log(JSON.stringify(d, null, 2)))
    .catch(err => {
      console.error(err);
      process.exit(1);
    });
} else {
  console.log('Usage: node miro-oauth-exchange.js <CLIENT_ID> <CLIENT_SECRET> <CODE> <REDIRECT_URI>');
}
