// Centralized text constants for the bot UI and messages

const BUTTONS = {
  online: '👥 Посмотреть онлайн',
  connect: '🔗 Подключиться',
  disconnect: '❌ Отключиться',
  restart: '🔄 Перезагрузить бота',
};

const MESSAGES = {
  onlyYouInChat: 'Пока что ты один в чате. Пригласи друзей! 👥',
  needStart: 'Сначала нажми /start для подключения к чату!',
  filesForbidden: '❌ Файлы запрещены в анонимном чате!',
  sentToNParticipants: (n) => `✅ Сообщение отправлено ${n} участникам!`,
  anonTextPrefix: (text) => `💬 Анонимное сообщение:\n${text}`,
  anonSticker: '💬 Анонимный стикер:',
  anonPhoto: '💬 Анонимное фото:',
  anonVoice: '💬 Анонимное голосовое сообщение:',
  anonVideo: '💬 Анонимное видео:',
};

const START = {
  helpText: (userCount, aiCount) =>
    `💬 *Анонимный чат*\nДобро пожаловать! Здесь ты можешь общаться анонимно с другими участниками.\n\n*Как пользоваться:*\n• Нажми "${
      BUTTONS.connect
    }" чтобы присоединиться к чату\n• Напиши любое сообщение - оно отправится всем участникам анонимно\n• Нажми "${
      BUTTONS.disconnect
    }" чтобы выйти из чата\n• Используй "${
      BUTTONS.online
    }" чтобы узнать количество участников\n\n*Что можно отправлять:*\n✅ Текст, стикеры, фото, голосовые, видео\n❌ Файлы запрещены\n\n*Сейчас онлайн: ${userCount} пользователей${
      aiCount > 0 ? `, и ${aiCount} нейросетей` : ''
    }*`,
  onlineText: (userCount, aiCount) => {
    return `👥 *Онлайн в анонимном чате: ${userCount} пользователей${
      aiCount > 0 ? `, и ${aiCount} нейросетей` : ''
    }*\nНажми "${BUTTONS.connect}" чтобы присоединиться! или Пригласи друзей! 👤`;
  },
  connectSuccess: `✅ Подключение успешно!\nТеперь ты в анонимном чате. Просто напиши сообщение, и оно будет отправлено всем участникам.`,
  alreadyConnected: '✅ Ты уже подключен к анонимному чату!',
  notConnected: '❌ Ты не подключен к анонимному чату!',
  userJoinedBroadcast: (userCount, aiCount) =>
    `🆕 Новый участник присоединился к анонимному чату!\n👥 Всего: ${userCount} пользователей${
      aiCount > 0 ? `, и ${aiCount} нейросетей` : ''
    }`,
  userLeftBroadcast: (userCount, aiCount) =>
    `👋 Участник покинул анонимный чат!\n👥 Осталось: ${userCount} пользователей${
      aiCount > 0 ? `, и ${aiCount} нейросетей` : ''
    }`,
  disconnectSuccess: `👋 Отключение успешно!\nТы больше не получаешь сообщения из анонимного чата.`,
  restartSuccess: `🔄 Бот перезагружен!`,
};

module.exports = {
  BUTTONS,
  MESSAGES,
  START,
};
