const OpenAIProvider = require('./openai');
const AnthropicProvider = require('./anthropic');
const GeminiProvider = require('./gemini');

class ProviderService {
  constructor() {
    this.providers = {
      openai: new OpenAIProvider(process.env.OPENAI_API_KEY),
      anthropic: new AnthropicProvider(process.env.ANTHROPIC_API_KEY),
      google: new GeminiProvider(process.env.GEMINI_API_KEY)
    };

    this.modelMap = {
      'gpt-4': 'openai',
      'gpt-4-turbo': 'openai',
      'gpt-4o': 'openai',
      'gpt-4o-mini': 'openai',
      'gpt-3.5-turbo': 'openai',
      'text-embedding-ada-002': 'openai',
      'claude-3-5-sonnet': 'anthropic',
      'claude-3-5-sonnet-20241022': 'anthropic',
      'claude-3-5-sonnet-20240620': 'anthropic',
      'claude-3-opus': 'anthropic',
      'claude-3-haiku': 'anthropic',
      'gemini-1.5-pro': 'google',
      'gemini-1.5-flash': 'google',
      'gemini-1.0-pro': 'google'
    };

    this.supportedModels = [
      { provider: 'openai', model: 'gpt-4o', name: 'GPT-4o' },
      { provider: 'openai', model: 'gpt-4o-mini', name: 'GPT-4o Mini' },
      { provider: 'openai', model: 'gpt-4-turbo', name: 'GPT-4 Turbo' },
      { provider: 'openai', model: 'gpt-3.5-turbo', name: 'GPT-3.5 Turbo' },
      { provider: 'anthropic', model: 'claude-3-5-sonnet-20241022', name: 'Claude 3.5 Sonnet' },
      { provider: 'anthropic', model: 'claude-3-opus-20240229', name: 'Claude 3 Opus' },
      { provider: 'anthropic', model: 'claude-3-haiku-20240307', name: 'Claude 3 Haiku' },
      { provider: 'google', model: 'gemini-1.5-pro', name: 'Gemini 1.5 Pro' },
      { provider: 'google', model: 'gemini-1.5-flash', name: 'Gemini 1.5 Flash' }
    ];
  }

  getProvider(model) {
    const normalizedModel = model.toLowerCase();
    let providerName = this.modelMap[normalizedModel];

    if (!providerName) {
      if (normalizedModel.startsWith('gpt') || normalizedModel.includes('embedding')) {
        providerName = 'openai';
      } else if (normalizedModel.startsWith('claude')) {
        providerName = 'anthropic';
      } else if (normalizedModel.startsWith('gemini')) {
        providerName = 'google';
      }
    }

    if (!providerName || !this.providers[providerName]) {
      throw new Error(`Unsupported model: ${model}`);
    }

    return {
      provider: this.providers[providerName],
      providerName
    };
  }

  async chatCompletion(messages, model, options = {}) {
    const { provider } = this.getProvider(model);
    return await provider.chatCompletion(messages, model, options);
  }

  async embeddings(text, model) {
    const { provider } = this.getProvider(model || 'text-embedding-ada-002');
    return await provider.embeddings(text, model || 'text-embedding-ada-002');
  }

  async listModels() {
    return this.supportedModels;
  }
}

module.exports = new ProviderService();
