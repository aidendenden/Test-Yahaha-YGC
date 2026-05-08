const { prisma } = require('../config/database');

const MODEL_PRICING = {
  'gpt-4o': { input: 0.000005, output: 0.000015, provider: 'openai' },
  'gpt-4o-mini': { input: 0.00000015, output: 0.0000006, provider: 'openai' },
  'gpt-4-turbo': { input: 0.00001, output: 0.00003, provider: 'openai' },
  'gpt-3.5-turbo': { input: 0.0000005, output: 0.0000015, provider: 'openai' },
  'claude-3-5-sonnet-20241022': { input: 0.000003, output: 0.000015, provider: 'anthropic' },
  'claude-3-opus-20240229': { input: 0.000015, output: 0.000075, provider: 'anthropic' },
  'claude-3-haiku-20240307': { input: 0.0000008, output: 0.000004, provider: 'anthropic' },
  'gemini-1.5-pro': { input: 0.00000125, output: 0.000005, provider: 'google' },
  'gemini-1.5-flash': { input: 0.000000035, output: 0.00000014, provider: 'google' }
};

class BillingService {
  calculateCost(model, inputTokens, outputTokens) {
    const pricing = MODEL_PRICING[model];
    if (!pricing) {
      const defaultPricing = { input: 0.000001, output: 0.000003, provider: 'unknown' };
      return {
        cost: (inputTokens * defaultPricing.input) + (outputTokens * defaultPricing.output),
        pricing: defaultPricing
      };
    }
    
    return {
      cost: (inputTokens * pricing.input) + (outputTokens * pricing.output),
      pricing
    };
  }

  async recordUsage(apiKeyId, userId, model, provider, inputTokens, outputTokens, cost) {
    const usageLog = await prisma.usageLog.create({
      data: {
        apiKeyId,
        userId,
        model,
        provider,
        inputTokens,
        outputTokens,
        cost
      }
    });
    return usageLog;
  }

  async deductBalance(userId, amount) {
    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      throw new Error('User not found');
    }

    if (parseFloat(user.balance) < amount) {
      throw new Error('Insufficient balance');
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        balance: {
          decrement: amount
        }
      }
    });

    return updatedUser;
  }

  async getUsageSummary(userId, startDate, endDate) {
    const where = { userId };
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.gte = new Date(startDate);
      if (endDate) where.createdAt.lte = new Date(endDate);
    }

    const usageLogs = await prisma.usageLog.findMany({
      where,
      select: {
        provider: true,
        model: true,
        inputTokens: true,
        outputTokens: true,
        cost: true,
        createdAt: true
      }
    });

    const summary = {
      totalRequests: usageLogs.length,
      totalInputTokens: 0,
      totalOutputTokens: 0,
      totalCost: 0,
      byProvider: {},
      byModel: {}
    };

    usageLogs.forEach(log => {
      summary.totalInputTokens += log.inputTokens;
      summary.totalOutputTokens += log.outputTokens;
      summary.totalCost += parseFloat(log.cost);

      if (!summary.byProvider[log.provider]) {
        summary.byProvider[log.provider] = {
          requests: 0,
          inputTokens: 0,
          outputTokens: 0,
          cost: 0
        };
      }
      summary.byProvider[log.provider].requests++;
      summary.byProvider[log.provider].inputTokens += log.inputTokens;
      summary.byProvider[log.provider].outputTokens += log.outputTokens;
      summary.byProvider[log.provider].cost += parseFloat(log.cost);

      if (!summary.byModel[log.model]) {
        summary.byModel[log.model] = {
          requests: 0,
          inputTokens: 0,
          outputTokens: 0,
          cost: 0
        };
      }
      summary.byModel[log.model].requests++;
      summary.byModel[log.model].inputTokens += log.inputTokens;
      summary.byModel[log.model].outputTokens += log.outputTokens;
      summary.byModel[log.model].cost += parseFloat(log.cost);
    });

    summary.totalCost = parseFloat(summary.totalCost.toFixed(4));
    return summary;
  }

  async getUsageDetails(userId, page = 1, pageSize = 20, startDate, endDate) {
    const where = { userId };
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.gte = new Date(startDate);
      if (endDate) where.createdAt.lte = new Date(endDate);
    }

    const [total, logs] = await Promise.all([
      prisma.usageLog.count({ where }),
      prisma.usageLog.findMany({
        where,
        select: {
          id: true,
          model: true,
          provider: true,
          inputTokens: true,
          outputTokens: true,
          cost: true,
          createdAt: true
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize
      })
    ]);

    return {
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
      logs
    };
  }

  async recharge(userId, amount) {
    if (amount <= 0) {
      throw new Error('Recharge amount must be positive');
    }

    const rechargeLog = await prisma.rechargeLog.create({
      data: {
        userId,
        amount,
        status: 'completed'
      }
    });

    await prisma.user.update({
      where: { id: userId },
      data: {
        balance: {
          increment: amount
        }
      }
    });

    return rechargeLog;
  }

  async getBalance(userId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { balance: true }
    });
    return user?.balance || 0;
  }
}

module.exports = new BillingService();
