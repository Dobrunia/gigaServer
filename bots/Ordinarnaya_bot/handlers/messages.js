const userStorage = require('../utils/userStorage');

const messageHandler = (bot) => {
  bot.on('message', (msg) => {
    const chatId = msg.chat.id;
    const senderId = msg.from.id;

    // Игнорируем команды
    if (msg.text && msg.text.startsWith('/')) {
      return;
    }

    // Игнорируем кнопки
    if (
      msg.text &&
      (msg.text === '👥 Посмотреть онлайн' ||
        msg.text === '🔗 Подключиться' ||
        msg.text === '❌ Отключиться')
    ) {
      return;
    }

    // Проверяем, что пользователь зарегистрирован
    if (!userStorage.isUserRegistered(chatId)) {
      bot.sendMessage(chatId, 'Сначала нажми /start для подключения к чату!');
      return;
    }

    // Получаем всех пользователей кроме отправителя
    const allUsers = userStorage.getAllUsers();
    const otherUsers = allUsers.filter((user) => user.chatId !== chatId);

    if (otherUsers.length === 0) {
      bot.sendMessage(chatId, 'Пока что ты один в чате. Пригласи друзей! 👥');
      return;
    }

    // Отправляем сообщение всем остальным пользователям
    otherUsers.forEach((user) => {
      try {
        if (msg.text) {
          bot.sendMessage(user.chatId, `💬 Анонимное сообщение:\n\n${msg.text}`);
        } else if (msg.sticker) {
          bot.sendMessage(user.chatId, '💬 Анонимный стикер:');
          bot.sendSticker(user.chatId, msg.sticker.file_id);
        } else if (msg.photo) {
          bot.sendMessage(user.chatId, '💬 Анонимное фото:');
          bot.sendPhoto(user.chatId, msg.photo[msg.photo.length - 1].file_id);
        } else if (msg.document) {
          // Не отправляем файлы другим пользователям
          return;
        } else if (msg.voice) {
          bot.sendMessage(user.chatId, '💬 Анонимное голосовое сообщение:');
          bot.sendVoice(user.chatId, msg.voice.file_id);
        } else if (msg.video) {
          bot.sendMessage(user.chatId, '💬 Анонимное видео:');
          bot.sendVideo(user.chatId, msg.video.file_id);
        }
      } catch (error) {
        console.error(`Ошибка отправки сообщения пользователю ${user.chatId}:`, error);
      }
    });

    // Подтверждаем отправителю
    if (msg.document) {
      bot.sendMessage(chatId, '❌ Файлы запрещены в анонимном чате!');
    } else {
      bot.sendMessage(chatId, `✅ Сообщение отправлено ${otherUsers.length} участникам!`);
    }
  });
};

module.exports = messageHandler;
