const userStorage = require('../utils/userStorage');
const { BUTTONS, MESSAGES, START } = require('../texts');

const messageHandler = (bot) => {
  bot.on('message', (msg) => {
    const chatId = msg.chat.id;
    const isAI = msg.from.id === 'ai_user';

    // Игнорируем команды и кнопки
    if (
      msg.text &&
      (msg.text.startsWith('/') ||
        msg.text === BUTTONS.online ||
        msg.text === BUTTONS.connect ||
        msg.text === BUTTONS.disconnect ||
        msg.text === BUTTONS.restart)
    ) {
      return;
    }

    // Проверяем, что пользователь зарегистрирован
    if (!userStorage.isUserRegistered(chatId)) {
      bot.sendMessage(chatId, START.notConnected);
      return;
    }

    // Получаем всех пользователей кроме отправителя и AI
    const allUsers = userStorage.getAllUsers();
    const otherUsers = allUsers.filter(
      (user) => user.chatId !== chatId && user.userId !== 'ai_user'
    );

    // if (otherUsers.length === 0) {
    //   bot.sendMessage(chatId, MESSAGES.onlyYouInChat);
    //   return;
    // }

    // Отправляем сообщение всем остальным пользователям (исключая AI)
    otherUsers.forEach((user) => {
      try {
        if (msg.text) {
          bot.sendMessage(user.chatId, MESSAGES.anonTextPrefix(msg.text));
        } else if (msg.sticker) {
          bot.sendMessage(user.chatId, MESSAGES.anonSticker);
          bot.sendSticker(user.chatId, msg.sticker.file_id);
        } else if (msg.photo) {
          bot.sendMessage(user.chatId, MESSAGES.anonPhoto);
          bot.sendPhoto(user.chatId, msg.photo[msg.photo.length - 1].file_id);
        } else if (msg.document) {
          // Не отправляем файлы другим пользователям
          return;
        } else if (msg.voice) {
          bot.sendMessage(user.chatId, MESSAGES.anonVoice);
          bot.sendVoice(user.chatId, msg.voice.file_id);
        } else if (msg.video) {
          bot.sendMessage(user.chatId, MESSAGES.anonVideo);
          bot.sendVideo(user.chatId, msg.video.file_id);
        }
      } catch (error) {
        console.error(`Ошибка отправки сообщения пользователю ${user.chatId}:`, error);
      }
    });

    if (msg.text) {
      // Добавляем сообщение в историю
      userStorage.addMessage(msg.text);

      if (!isAI) {
        // Если сообщение не от AI
        // Триггер AI ответа (только для текстовых сообщений)
        userStorage.triggerAIResponse(bot);
      }
    }

    // Подтверждаем отправителю
    if (msg.document) {
      bot.sendMessage(chatId, MESSAGES.filesForbidden);
    }
    // else {
    //   bot.sendMessage(chatId, MESSAGES.sentToNParticipants(otherUsers.length));
    // }
  });
};

module.exports = messageHandler;
