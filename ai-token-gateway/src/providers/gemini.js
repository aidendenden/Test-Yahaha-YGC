class GeminiProvider {
  constructor(apiKey) {
    this.apiKey = apiKey;
    this.baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  }

  async chatCompletion(messages, model, options = {}) {
    const modelName = model.replace('gemini-', '');
    const url = `${this.baseUrl}/models/${model}:generateContent?key=${this.apiKey}`;

    const contents = messages.map(msg => ({
      role: msg.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: msg.content }]
    }));

    const body = {
      contents,
      generationConfig: {
        maxOutputTokens: options.max_tokens || 2048,
        temperature: options.temperature || 0.9,
        topP: options.top_p || 0.95,
        ...options
      }
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();

    if (!response.ok) {
      throw {
        status: response.status,
        error: data.error || { message: 'Gemini API error' }
      };
    }

    const responseText = data.candidates?.[0]?.content?.parts?.[0]?.text || '';

    const openaiFormat = {
      id: `chatcmpl-${Date.now()}`,
      object: 'chat.completion',
      created: Math.floor(Date.now() / 1000),
      model: model,
      choices: [{
        index: 0,
        message: {
          role: 'assistant',
          content: responseText
        },
        finish_reason: 'stop'
      }],
      usage: {
        prompt_tokens: data.usageMetadata?.promptTokenCount || 0,
        completion_tokens: data.usageMetadata?.candidatesTokenCount || 0,
        total_tokens: data.usageMetadata?.totalTokenCount || 0
      }
    };

    return {
      provider: 'google',
      model: model,
      usage: {
        inputTokens: data.usageMetadata?.promptTokenCount || 0,
        outputTokens: data.usageMetadata?.candidatesTokenCount || 0
      },
      response: openaiFormat
    };
  }

  async listModels() {
    return [
      { id: 'gemini-1.5-pro', name: 'Gemini 1.5 Pro' },
      { id: 'gemini-1.5-flash', name: 'Gemini 1.5 Flash' },
      { id: 'gemini-1.0-pro', name: 'Gemini 1.0 Pro' }
    ];
  }
}

module.exports = GeminiProvider;
