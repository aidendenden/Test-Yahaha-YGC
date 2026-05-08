const { prisma } = require('../config/database');
const { generateApiKey, hashApiKey, getApiKeyPrefix, maskApiKey } = require('../utils/keyGenerator');

class ApiKeyController {
  async create(req, res) {
    try {
      const userId = req.user.userId;
      const { name } = req.body;

      const rawApiKey = generateApiKey();
      const keyHash = hashApiKey(rawApiKey);
      const keyPrefix = getApiKeyPrefix(rawApiKey);

      const apiKey = await prisma.apiKey.create({
        data: {
          userId,
          keyHash,
          keyPrefix,
          name: name || `Key-${Date.now()}`
        }
      });

      res.status(201).json({
        message: 'API Key created successfully',
        apiKey: {
          id: apiKey.id,
          key: rawApiKey,
          prefix: apiKey.keyPrefix,
          name: apiKey.name,
          isActive: apiKey.isActive,
          createdAt: apiKey.createdAt
        },
        warning: 'This is the only time you will see the full API key. Please save it securely.'
      });
    } catch (error) {
      console.error('Create API key error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to create API key'
      });
    }
  }

  async list(req, res) {
    try {
      const userId = req.user.userId;

      const apiKeys = await prisma.apiKey.findMany({
        where: { userId },
        select: {
          id: true,
          keyPrefix: true,
          name: true,
          isActive: true,
          lastUsedAt: true,
          createdAt: true
        },
        orderBy: { createdAt: 'desc' }
      });

      const maskedKeys = apiKeys.map(key => ({
        ...key,
        keyPrefix: maskApiKey(key.keyPrefix)
      }));

      res.json({ apiKeys: maskedKeys });
    } catch (error) {
      console.error('List API keys error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to list API keys'
      });
    }
  }

  async delete(req, res) {
    try {
      const userId = req.user.userId;
      const { id } = req.params;

      const apiKey = await prisma.apiKey.findFirst({
        where: { id, userId }
      });

      if (!apiKey) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'API key not found'
        });
      }

      await prisma.apiKey.delete({
        where: { id }
      });

      res.json({ message: 'API key deleted successfully' });
    } catch (error) {
      console.error('Delete API key error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to delete API key'
      });
    }
  }

  async updateStatus(req, res) {
    try {
      const userId = req.user.userId;
      const { id } = req.params;
      const { isActive } = req.body;

      if (typeof isActive !== 'boolean') {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'isActive must be a boolean'
        });
      }

      const apiKey = await prisma.apiKey.findFirst({
        where: { id, userId }
      });

      if (!apiKey) {
        return res.status(404).json({
          error: 'Not Found',
          message: 'API key not found'
        });
      }

      const updatedKey = await prisma.apiKey.update({
        where: { id },
        data: { isActive },
        select: {
          id: true,
          keyPrefix: true,
          name: true,
          isActive: true,
          createdAt: true
        }
      });

      res.json({
        message: `API key ${isActive ? 'enabled' : 'disabled'} successfully`,
        apiKey: {
          ...updatedKey,
          keyPrefix: maskApiKey(updatedKey.keyPrefix)
        }
      });
    } catch (error) {
      console.error('Update API key status error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to update API key status'
      });
    }
  }
}

module.exports = new ApiKeyController();
