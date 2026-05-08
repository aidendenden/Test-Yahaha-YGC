const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config');
const { prisma } = require('../config/database');

async function authenticateApiKey(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Missing or invalid authorization header'
      });
    }

    const apiKey = authHeader.substring(7);
    const keyHash = require('../utils/keyGenerator').hashApiKey(apiKey);

    const keyRecord = await prisma.apiKey.findUnique({
      where: { keyHash },
      include: { user: true }
    });

    if (!keyRecord) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid API key'
      });
    }

    if (!keyRecord.isActive) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'API key is disabled'
      });
    }

    if (!keyRecord.user.isActive) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'User account is disabled'
      });
    }

    await prisma.apiKey.update({
      where: { id: keyRecord.id },
      data: { lastUsedAt: new Date() }
    });

    req.apiKey = keyRecord;
    req.user = keyRecord.user;
    next();
  } catch (error) {
    console.error('API Key authentication error:', error);
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Authentication failed'
    });
  }
}

function authenticateJwt(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Missing or invalid authorization header'
      });
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, jwtSecret);

    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({
      error: 'Unauthorized',
      message: 'Invalid or expired token'
    });
  }
}

function requireAdmin(req, res, next) {
  if (!req.user || !req.user.isAdmin) {
    return res.status(403).json({
      error: 'Forbidden',
      message: 'Admin access required'
    });
  }
  next();
}

module.exports = {
  authenticateApiKey,
  authenticateJwt,
  requireAdmin
};
