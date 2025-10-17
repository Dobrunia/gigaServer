// To run this code you need to install the following dependencies:
// npm install @google/genai mime
// npm install -D @types/node

const { GoogleGenAI } = require('@google/genai');
class AI_User {
  constructor(config) {
    if (!config) {
      throw new Error('AI_User requires config parameter');
    }
    if (!process.env.GEMINI_API_KEY) {
      console.error('❌ GEMINI_API_KEY не найден в переменных окружения!');
      throw new Error('GEMINI_API_KEY is required');
    }

    this.ai = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
    });
    this.model = config.model;
    this.user = {
      chatId: config.chatId,
      id: config.id,
      first_name: config.first_name,
      last_name: config.last_name,
      username: config.username,
    };
    this.prompt = config.prompt;
  }

  /**
   * Генерирует ответ AI на основе истории сообщений
   * @param {Array} messages - Массив сообщений из чата
   * @returns {Promise<string>} Ответ AI
   */
  async generateResponse(messages) {
    try {
      const fullPrompt = `${this.prompt}\n${messages.join('\n')}`;

      const result = await this.ai.models.generateContent({
        model: this.model,
        contents: [{ role: 'user', parts: [{ text: fullPrompt }] }],
      });

      const response = result.response.text();
      return response.trim();
    } catch (error) {
      console.error('❌ Ошибка генерации ответа AI:', error);
      return null;
    }
  }
}

module.exports = AI_User;
