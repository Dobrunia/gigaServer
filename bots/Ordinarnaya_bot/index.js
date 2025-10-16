const TelegramBot = require('node-telegram-bot-api');
require('dotenv').config();

// Импорты обработчиков
const { startHandler, messageHandler } = require('./handlers');

// Создаем экземпляр бота
const bot = new TelegramBot(process.env.BOT_TOKEN, { polling: true });

// Регистрируем обработчики
startHandler(bot);
messageHandler(bot);

// Обработчик ошибок
bot.on('polling_error', (error) => {
  console.error('Polling error:', error);
});

// Обработчик завершения процесса
process.on('SIGINT', () => {
  bot.stopPolling();
  process.exit(0);
});

// Обработчик необработанных исключений
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

// Обработчик необработанных отклонений промисов
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

console.log('🤖 Бот запущен!');
