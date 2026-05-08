const billingService = require('../services/billingService');

class BillingController {
  async getUsageSummary(req, res) {
    try {
      const userId = req.user.userId;
      const { startDate, endDate } = req.query;

      const summary = await billingService.getUsageSummary(userId, startDate, endDate);

      res.json({ summary });
    } catch (error) {
      console.error('Get usage summary error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to get usage summary'
      });
    }
  }

  async getUsageDetails(req, res) {
    try {
      const userId = req.user.userId;
      const { page = 1, pageSize = 20, startDate, endDate } = req.query;

      const details = await billingService.getUsageDetails(
        userId,
        parseInt(page),
        parseInt(pageSize),
        startDate,
        endDate
      );

      res.json(details);
    } catch (error) {
      console.error('Get usage details error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to get usage details'
      });
    }
  }

  async getBalance(req, res) {
    try {
      const userId = req.user.userId;
      const balance = await billingService.getBalance(userId);

      res.json({ balance: parseFloat(balance) });
    } catch (error) {
      console.error('Get balance error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to get balance'
      });
    }
  }

  async recharge(req, res) {
    try {
      const userId = req.user.userId;
      const { amount } = req.body;

      if (!amount || amount <= 0) {
        return res.status(400).json({
          error: 'Bad Request',
          message: 'Invalid recharge amount'
        });
      }

      const rechargeLog = await billingService.recharge(userId, parseFloat(amount));

      res.json({
        message: 'Recharge successful',
        recharge: rechargeLog
      });
    } catch (error) {
      console.error('Recharge error:', error);
      res.status(500).json({
        error: 'Internal Server Error',
        message: 'Failed to recharge'
      });
    }
  }
}

module.exports = new BillingController();
