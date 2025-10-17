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
}

module.exports = AI_User;
