const providerService = require('../providers');
const billingService = require('../services/billingService');

class ProxyController {
  async chatCompletion(req, res) {
    try {
      const { model, messages, ...options } = req.body;
      const apiKey = req.apiKey;
      const user = req.user;

      if (!model || !messages) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'Model and messages are required'
        });
      }

      if (!Array.isArray(messages) || messages.length === 0) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'Messages must be a non-empty array'
        });
      }

      let result;
      try {
        result = await providerService.chatCompletion(messages, model, options);
      } catch (error) {
        console.error('Provider error:', error);
        return res.status(error.status || 500).json({
          error: 'AI Provider Error',
          message: error.error?.message || error.message || 'AI provider request failed'
        });
      }

      const { cost } = billingService.calculateCost(
        model,
        result.usage.inputTokens,
        result.usage.outputTokens
      );

      try {
        await billingService.recordUsage(
          apiKey.id,
          user.id,
          model,
          result.provider,
          result.usage.inputTokens,
          result.usage.outputTokens,
          cost
        );
        await billingService.deductBalance(user.id, cost);
      } catch (billingError) {
        console.error('Billing error:', billingError.message);
      }

      res.json(result.response);
    } catch (error) {
      console.error('Chat completion error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Chat completion failed'
      });
    }
  }

  async embeddings(req, res) {
    try {
      const { input, model } = req.body;
      const apiKey = req.apiKey;
      const user = req.user;

      if (!input) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'Input is required'
        });
      }

      let result;
      try {
        result = await providerService.embeddings(input, model);
      } catch (error) {
        console.error('Provider error:', error);
        return res.status(error.status || 500).json({
          error: 'AI Provider Error',
          message: error.error?.message || error.message || 'AI provider request failed'
        });
      }

      const { cost } = billingService.calculateCost(
        model || 'text-embedding-ada-002',
        result.usage.inputTokens,
        0
      );

      try {
        await billingService.recordUsage(
          apiKey.id,
          user.id,
          model || 'text-embedding-ada-002',
          result.provider,
          result.usage.inputTokens,
          0,
          cost
        );
        await billingService.deductBalance(user.id, cost);
      } catch (billingError) {
        console.error('Billing error:', billingError.message);
      }

      res.json(result.response);
    } catch (error) {
      console.error('Embeddings error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Embeddings failed'
      });
    }
  }

  async listModels(req, res) {
    try {
      const models = await providerService.listModels();
      res.json({ models });
    } catch (error) {
      console.error('List models error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to list models'
      });
    }
  }
}

module.exports = new ProxyController();
