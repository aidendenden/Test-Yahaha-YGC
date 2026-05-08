class OpenAIProvider {
  constructor(apiKey) {
    this.apiKey = apiKey;
    this.baseUrl = 'https://api.openai.com/v1';
  }

  async chatCompletion(messages, model, options = {}) {
    const url = `${this.baseUrl}/chat/completions`;
    
    const body = {
      model,
      messages,
      ...options
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();

    if (!response.ok) {
      throw {
        status: response.status,
        error: data.error || { message: 'OpenAI API error' }
      };
    }

    return {
      provider: 'openai',
      model: data.model,
      usage: {
        inputTokens: data.usage?.prompt_tokens || 0,
        outputTokens: data.usage?.completion_tokens || 0
      },
      response: data
    };
  }

  async embeddings(text, model = 'text-embedding-ada-002') {
    const url = `${this.baseUrl}/embeddings`;
    
    const body = {
      input: text,
      model
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`
      },
      body: JSON.stringify(body)
    });

    const data = await response.json();

    if (!response.ok) {
      throw {
        status: response.status,
        error: data.error || { message: 'OpenAI API error' }
      };
    }

    return {
      provider: 'openai',
      model: data.model,
      usage: {
        inputTokens: data.usage?.total_tokens || 0,
        outputTokens: 0
      },
      response: data
    };
  }

  async listModels() {
    const url = `${this.baseUrl}/models`;
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`
      }
    });

    const data = await response.json();

    if (!response.ok) {
      throw {
        status: response.status,
        error: data.error || { message: 'OpenAI API error' }
      };
    }

    return data.models.filter(m => m.id.startsWith('gpt-') || m.id.includes('embedding'));
  }
}

module.exports = OpenAIProvider;
