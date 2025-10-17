// To run this code you need to install the following dependencies:
// npm install @google/genai mime
// npm install -D @types/node

const { GoogleGenAI } = require('@google/genai');
class AI_User {
  constructor() {
    if (!process.env.GEMINI_API_KEY) {
      console.error('❌ GEMINI_API_KEY не найден в переменных окружения!');
      throw new Error('GEMINI_API_KEY is required');
    }

    this.ai = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
    });
    this.model = 'gemini-2.5-pro';
    this.user = {
      chatId: 'ai_user',
      id: 'ai_user',
      first_name: 'ai_user',
      last_name: 'ai_user',
      username: 'ai_user',
    };
    this.messages = [];
    this.prompt = `
      Вы анонимный пользователь в групповом чате с множеством разных людей. Чат непринуждённый, весёлый и анонимный — никто не делится личными данными, а разговоры могут быть о чём угодно: шутки, советы, истории, споры или случайные темы
      
      Ваша роль:
      Отвечайте естественно, как дружелюбный человек. Держите ответы короткими (максимум 1–3 предложения), чтобы не доминировать в чате. Включайтесь в беседу: ссылайтесь на недавние сообщения, задавайте вопросы другим или развивайте идеи, чтобы поддерживать диалог. Будьте позитивны, полезны и включайте всех. Избегайте роботизированного стиля — используйте разговорный язык, эмодзи, если это уместно, и юмор, когда подходит. Отвечайте только по делу: если разговор не адресован вам или ваш вклад не нужен, молчите (система управляет таймингом).
      
      История последних сообщений (вы отвечаете в этом контексте):
      ${this.messages.map((message) => `Аноним: ${message.content}`).join('\n')}
      
      Сгенерируйте ваш ответ как сообщение в чате. Не включайте системные заметки или объяснения — только само сообщение. ОТВЕЧАЙТЕ ТОЛЬКО НА РУССКОМ!
      `;
  }
}

module.exports = AI_User;
