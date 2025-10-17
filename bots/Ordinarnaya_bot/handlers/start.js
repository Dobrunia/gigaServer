const userStorage = require('../utils/userStorage');
const { BUTTONS, START } = require('../texts');

const startHandler = (bot) => {
  // Обработчик команды /start
  bot.onText(/\/start/, (msg) => {
    const chatId = msg.chat.id;
    const stats = userStorage.getStats();
    const helpText = START.helpText(stats.users, stats.ai);

    const keyboard = {
      keyboard: [
        [{ text: BUTTONS.online }],
        [{ text: BUTTONS.connect }, { text: BUTTONS.disconnect }],
      ],
      resize_keyboard: true,
    };

    try {
      bot.sendMessage(chatId, helpText, {
        parse_mode: 'Markdown',
        reply_markup: keyboard,
      });
    } catch (error) {
      console.error(`Ошибка отправки helpText пользователю ${chatId}:`, error.message);
    }
  });

  // Обработчик нажатия кнопки "Посмотреть онлайн"
  bot.onText(new RegExp(`${BUTTONS.online}`), (msg) => {
    const chatId = msg.chat.id;
    const stats = userStorage.getStats();
    const onlineText = START.onlineText(stats.users, stats.ai);
    try {
      bot.sendMessage(chatId, onlineText, { parse_mode: 'Markdown' });
    } catch (error) {
      console.error(`Ошибка отправки onlineText пользователю ${chatId}:`, error.message);
    }
  });

  // Обработчик кнопки "Подключиться"
  bot.onText(new RegExp(`${BUTTONS.connect}`), (msg) => {
    const chatId = msg.chat.id;
    const user = msg.from;

    // Проверяем, не подключен ли уже пользователь
    if (userStorage.isUserRegistered(chatId)) {
      try {
        bot.sendMessage(chatId, START.alreadyConnected);
      } catch (error) {
        console.error(`Ошибка отправки alreadyConnected пользователю ${chatId}:`, error.message);
      }
      return;
    }

    // Подключаем пользователя
    userStorage.addUser(chatId, user);

    // Уведомляем всех остальных пользователей (исключая AI)
    const allUsers = userStorage.getAllUsers();
    const otherUsers = allUsers.filter((u) => u.chatId !== chatId && u.userId !== 'ai_user');

    otherUsers.forEach((otherUser) => {
      try {
        const stats = userStorage.getStats();
        bot.sendMessage(otherUser.chatId, START.userJoinedBroadcast(stats.users, stats.ai));
      } catch (error) {
        console.error(`Ошибка отправки уведомления пользователю ${otherUser.chatId}:`, error);
      }
    });

    try {
      bot.sendMessage(chatId, START.connectSuccess);
    } catch (error) {
      console.error(`Ошибка отправки connectSuccess пользователю ${chatId}:`, error.message);
    }
  });

  // Обработчик кнопки "Отключиться"
  bot.onText(new RegExp(`${BUTTONS.disconnect}`), (msg) => {
    const chatId = msg.chat.id;

    // Проверяем, подключен ли пользователь
    if (!userStorage.isUserRegistered(chatId)) {
      try {
        bot.sendMessage(chatId, START.notConnected);
      } catch (error) {
        console.error(`Ошибка отправки notConnected пользователю ${chatId}:`, error.message);
      }
      return;
    }

    // Отключаем пользователя
    userStorage.removeUser(chatId);

    // Уведомляем всех остальных пользователей (исключая AI)
    const allUsers = userStorage.getAllUsers();
    const otherUsers = allUsers.filter((u) => u.userId !== 'ai_user');

    otherUsers.forEach((otherUser) => {
      try {
        const stats = userStorage.getStats();
        bot.sendMessage(otherUser.chatId, START.userLeftBroadcast(stats.users, stats.ai));
      } catch (error) {
        console.error(`Ошибка отправки уведомления пользователю ${otherUser.chatId}:`, error);
      }
    });

    try {
      bot.sendMessage(chatId, START.disconnectSuccess);
    } catch (error) {
      console.error(`Ошибка отправки disconnectSuccess пользователю ${chatId}:`, error.message);
    }
  });
};

module.exports = startHandler;
