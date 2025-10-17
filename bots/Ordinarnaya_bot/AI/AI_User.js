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
      userId: 'ai_user',
      firstName: 'AI',
      username: 'ai_user',
      joinedAt: new Date().toISOString(),
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

  // // Добавление сообщения в историю
  // addMessage(messageData) {
  //   this.messages.push({
  //     ...messageData,
  //     timestamp: new Date().toISOString(),
  //   });

  //   // Ограничиваем до 20 сообщений
  //   if (this.messages.length > 20) {
  //     this.messages = this.messages.slice(-20);
  //   }
  // }

  // // Получение последних сообщений
  // getMessages() {
  //   return this.messages;
  // }

  // // Получение пользователя
  // getUser() {
  //   return this.user;
  // }

  // // Проверка, является ли пользователь AI
  // isAIUser(chatId) {
  //   return chatId === 'ai_user';
  // }

  // // Установка промпта
  // setPrompt(newPrompt) {
  //   this.prompt = newPrompt;
  // }

  // // Получение промпта
  // getPrompt() {
  //   return this.prompt;
  // }
}

module.exports = AI_User;
