require('dotenv').config();

module.exports = {
  port: process.env.PORT || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  
  database: {
    url: process.env.DATABASE_URL
  },
  
  redis: {
    url: process.env.REDIS_URL
  },
  
  jwt: {
    secret: process.env.JWT_SECRET || 'default-secret-change-me',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  },
  
  apiKey: {
    prefix: process.env.API_KEY_PREFIX || 'sk-aitoken'
  }
};
