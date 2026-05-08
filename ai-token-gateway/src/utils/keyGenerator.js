const crypto = require('crypto');

function generateApiKey() {
  const prefix = 'sk-aitoken-';
  const randomBytes = crypto.randomBytes(32).toString('hex');
  return prefix + randomBytes;
}

function hashApiKey(apiKey) {
  return crypto.createHash('sha256').update(apiKey).digest('hex');
}

function getApiKeyPrefix(apiKey) {
  return apiKey.substring(0, 12);
}

function maskApiKey(apiKey) {
  if (!apiKey || apiKey.length < 12) return apiKey;
  return apiKey.substring(0, 8) + '****' + apiKey.substring(apiKey.length - 4);
}

module.exports = {
  generateApiKey,
  hashApiKey,
  getApiKeyPrefix,
  maskApiKey
};
