const userStorage = require('../utils/userStorage');
const { BUTTONS, START } = require('../texts');

const startHandler = (bot) => {
  // Обработчик команды /start
  bot.onText(/\/start/, (msg) => {
    const chatId = msg.chat.id;
    const userCount = userStorage.getUserCount();

    const helpText = START.helpText(userCount);

    const keyboard = {
      keyboard: [
        [{ text: BUTTONS.online }],
        [{ text: BUTTONS.connect }, { text: BUTTONS.disconnect }],
      ],
      resize_keyboard: true,
    };

    bot.sendMessage(chatId, helpText, {
      parse_mode: 'Markdown',
      reply_markup: keyboard,
    });
  });

  // Обработчик нажатия кнопки "Посмотреть онлайн"
  bot.onText(new RegExp(`${BUTTONS.online}`), (msg) => {
    const chatId = msg.chat.id;
    const allUsers = userStorage.getAllUsers();
    const userCount = allUsers.length;

    const onlineText = START.onlineText(userCount);
    bot.sendMessage(chatId, onlineText, { parse_mode: 'Markdown' });
  });

  // Обработчик кнопки "Подключиться"
  bot.onText(new RegExp(`${BUTTONS.connect}`), (msg) => {
    const chatId = msg.chat.id;
    const user = msg.from;

    // Проверяем, не подключен ли уже пользователь
    if (userStorage.isUserRegistered(chatId)) {
      bot.sendMessage(chatId, START.alreadyConnected);
      return;
    }

    // Подключаем пользователя
    userStorage.addUser(chatId, user);

    // Уведомляем всех остальных пользователей
    const allUsers = userStorage.getAllUsers();
    const otherUsers = allUsers.filter((u) => u.chatId !== chatId);

    otherUsers.forEach((otherUser) => {
      try {
        bot.sendMessage(otherUser.chatId, START.userJoinedBroadcast(allUsers.length));
      } catch (error) {
        console.error(`Ошибка отправки уведомления пользователю ${otherUser.chatId}:`, error);
      }
    });

    bot.sendMessage(chatId, START.connectSuccess);
  });

  // Обработчик кнопки "Отключиться"
  bot.onText(new RegExp(`${BUTTONS.disconnect}`), (msg) => {
    const chatId = msg.chat.id;

    // Проверяем, подключен ли пользователь
    if (!userStorage.isUserRegistered(chatId)) {
      bot.sendMessage(chatId, START.notConnected);
      return;
    }

    // Отключаем пользователя
    userStorage.removeUser(chatId);

    // Уведомляем всех остальных пользователей
    const allUsers = userStorage.getAllUsers();

    allUsers.forEach((otherUser) => {
      try {
        bot.sendMessage(otherUser.chatId, START.userLeftBroadcast(allUsers.length));
      } catch (error) {
        console.error(`Ошибка отправки уведомления пользователю ${otherUser.chatId}:`, error);
      }
    });

    bot.sendMessage(chatId, START.disconnectSuccess);
  });
};

module.exports = startHandler;
