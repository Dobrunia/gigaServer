const userStorage = require('../utils/userStorage');

const startHandler = (bot) => {
  // Обработчик команды /start
  bot.onText(/\/start/, (msg) => {
    const chatId = msg.chat.id;
    const userCount = userStorage.getUserCount();

    const helpText = `
💬 *Анонимный чат*

Добро пожаловать! Здесь ты можешь общаться анонимно с другими участниками.

*Как пользоваться:*
• Нажми "🔗 Подключиться" чтобы присоединиться к чату
• Напиши любое сообщение - оно отправится всем участникам анонимно
• Нажми "❌ Отключиться" чтобы выйти из чата
• Используй "👥 Посмотреть онлайн" чтобы узнать количество участников

*Что можно отправлять:*
✅ Текст, стикеры, фото, голосовые, видео
❌ Файлы запрещены

*Сейчас онлайн: ${userCount} участников*
    `;

    const keyboard = {
      keyboard: [
        [{ text: '👥 Посмотреть онлайн' }],
        [{ text: '🔗 Подключиться' }, { text: '❌ Отключиться' }],
      ],
      resize_keyboard: true,
    };

    bot.sendMessage(chatId, helpText, {
      parse_mode: 'Markdown',
      reply_markup: keyboard,
    });
  });

  // Обработчик нажатия кнопки "Посмотреть онлайн"
  bot.onText(/👥 Посмотреть онлайн/, (msg) => {
    const chatId = msg.chat.id;
    const allUsers = userStorage.getAllUsers();
    const userCount = allUsers.length;

    let onlineText;

    if (userCount === 0) {
      onlineText = '👥 В анонимном чате пока никого нет.\n\nНажми /connect чтобы присоединиться!';
    } else if (userCount === 1) {
      onlineText = `👥 *Онлайн в анонимном чате: ${userCount}*\n\nТолько ты в чате. Пригласи друзей! 👤`;
    } else {
      onlineText = `👥 *Онлайн в анонимном чате: ${userCount}*\n\nАктивных участников: ${userCount}\n\n💬 Напиши сообщение, и оно отправится всем участникам анонимно!`;
    }

    bot.sendMessage(chatId, onlineText, { parse_mode: 'Markdown' });
  });

  // Обработчик кнопки "Подключиться"
  bot.onText(/🔗 Подключиться/, (msg) => {
    const chatId = msg.chat.id;
    const user = msg.from;

    // Проверяем, не подключен ли уже пользователь
    if (userStorage.isUserRegistered(chatId)) {
      bot.sendMessage(chatId, '✅ Ты уже подключен к анонимному чату!');
      return;
    }

    // Подключаем пользователя
    userStorage.addUser(chatId, user);

    // Уведомляем всех остальных пользователей
    const allUsers = userStorage.getAllUsers();
    const otherUsers = allUsers.filter((u) => u.chatId !== chatId);

    otherUsers.forEach((otherUser) => {
      try {
        bot.sendMessage(
          otherUser.chatId,
          `🆕 Новый участник присоединился к анонимному чату!\n\n👥 Всего участников: ${allUsers.length}`
        );
      } catch (error) {
        console.error(`Ошибка отправки уведомления пользователю ${otherUser.chatId}:`, error);
      }
    });

    bot.sendMessage(
      chatId,
      `✅ Подключение успешно!\n\nТеперь ты в анонимном чате. Просто напиши сообщение, и оно будет отправлено всем участникам.`
    );
  });

  // Обработчик кнопки "Отключиться"
  bot.onText(/❌ Отключиться/, (msg) => {
    const chatId = msg.chat.id;

    // Проверяем, подключен ли пользователь
    if (!userStorage.isUserRegistered(chatId)) {
      bot.sendMessage(chatId, '❌ Ты не подключен к анонимному чату!');
      return;
    }

    // Отключаем пользователя
    userStorage.removeUser(chatId);

    // Уведомляем всех остальных пользователей
    const allUsers = userStorage.getAllUsers();

    allUsers.forEach((otherUser) => {
      try {
        bot.sendMessage(
          otherUser.chatId,
          `👋 Участник покинул анонимный чат!\n\n👥 Осталось участников: ${allUsers.length}`
        );
      } catch (error) {
        console.error(`Ошибка отправки уведомления пользователю ${otherUser.chatId}:`, error);
      }
    });

    bot.sendMessage(
      chatId,
      `👋 Отключение успешно!\n\nТы больше не получаешь сообщения из анонимного чата.`
    );
  });
};

module.exports = startHandler;
