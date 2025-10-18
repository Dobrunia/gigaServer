const fs = require('fs');
const path = require('path');
const AI_User = require('../AI/AI_User');
const { AI_CONFIG_FIRST } = require('../AI/config');
const { MESSAGES } = require('../texts');
class UserStorage {
  constructor() {
    // В памяти держим только online пользователей
    this.users = new Map(); // chatId -> userData (status === 'online')
    this.jsonFile = path.join(__dirname, '../data/users.json');
    this.ensureDataDir();
    this.loadFromJson();

    //AI
    this.messages = [];
    this.aiInstances = new Map(); // chatId -> AI_User instance
    this.lastAITrigger = 0; // Время последнего триггера AI
    this.AI_COOLDOWN = 5 * 60 * 1000; // 5 минут в миллисекундах
    this.initializeAI(AI_CONFIG_FIRST);
  }

  /**
   * Создает директорию data/ если она не существует
   */
  ensureDataDir() {
    const dataDir = path.dirname(this.jsonFile);
    if (!fs.existsSync(dataDir)) {
      fs.mkdirSync(dataDir, { recursive: true });
    }
  }

  /**
   * Загружает пользователей из JSON файла
   * В память поднимает только пользователей со статусом 'online'
   */
  loadFromJson() {
    try {
      if (fs.existsSync(this.jsonFile)) {
        const data = fs.readFileSync(this.jsonFile, 'utf8');
        const usersArray = JSON.parse(data);

        // В память поднимаем только online
        this.users.clear();
        usersArray.forEach((user) => {
          if (user.status === 'online') {
            this.users.set(user.chatId, user);
          }
        });

        console.log(`Загружено из JSON: всего=${usersArray.length}, онлайн=${this.users.size}`);
      } else {
        // Инициализируем пустой файл
        fs.writeFileSync(this.jsonFile, JSON.stringify([], null, 2));
        console.log('Создан пустой users.json');
      }
    } catch (error) {
      console.error('Ошибка загрузки пользователей из JSON:', error);
    }
  }

  /**
   * Читает полный реестр пользователей из JSON файла
   * @returns {Array} Массив всех пользователей (online и offline)
   */
  readRegistry() {
    try {
      const data = fs.readFileSync(this.jsonFile, 'utf8');
      return JSON.parse(data);
    } catch (_) {
      return [];
    }
  }

  /**
   * Записывает полный реестр пользователей в JSON файл
   * @param {Array} array - Массив всех пользователей
   */
  writeRegistry(array) {
    try {
      fs.writeFileSync(this.jsonFile, JSON.stringify(array, null, 2));
    } catch (error) {
      console.error('Ошибка сохранения пользователей в JSON:', error);
    }
  }

  /**
   * Добавляет пользователя в чат или обновляет его статус на 'online'
   * @param {string} chatId - ID чата пользователя
   * @param {Object} userData - Данные пользователя
   */
  addUser(chatId, userData) {
    const registry = this.readRegistry();
    const nowISO = new Date().toISOString();
    const idx = registry.findIndex((u) => u.chatId === chatId);
    const record = {
      chatId,
      userId: userData.id,
      firstName: userData.first_name,
      lastName: userData.last_name,
      username: userData.username,
      joinedAt: idx >= 0 ? registry[idx].joinedAt : nowISO,
      status: 'online',
    };

    if (idx >= 0) registry[idx] = record;
    else registry.push(record);
    this.writeRegistry(registry);

    // В память кладем только online
    this.users.set(chatId, record);

    console.log(`Пользователь онлайн: ${record.firstName} (${chatId})`);
    console.log(`Онлайн: ${this.getRealUserCount()} пользователей, ${this.getAICount()} AI`);
  }

  /**
   * Удаляет пользователя из чата (устанавливает статус 'offline')
   * @param {string} chatId - ID чата пользователя
   */
  removeUser(chatId) {
    const registry = this.readRegistry();
    const idx = registry.findIndex((u) => u.chatId === chatId);
    if (idx >= 0) {
      registry[idx] = { ...registry[idx], status: 'offline' };
      this.writeRegistry(registry);
    }

    const user = this.users.get(chatId);
    if (user) {
      this.users.delete(chatId);
      console.log(`Пользователь офлайн: ${user.firstName} (${chatId})`);
      console.log(`Онлайн: ${this.getRealUserCount()} пользователей, ${this.getAICount()} AI`);
    }
  }

  /**
   * Проверяет, зарегистрирован ли пользователь в чате
   * @param {string} chatId - ID чата пользователя
   * @returns {boolean} true если пользователь онлайн
   */
  isUserRegistered(chatId) {
    return this.users.has(chatId);
  }

  /**
   * Получает данные пользователя по chatId
   * @param {string} chatId - ID чата пользователя
   * @returns {Object|null} Данные пользователя или null
   */
  getUser(chatId) {
    return this.users.get(chatId);
  }

  /**
   * Получает всех онлайн пользователей
   * @returns {Array} Массив онлайн пользователей
   */
  getAllUsers() {
    // В памяти только online
    return Array.from(this.users.values());
  }

  /**
   * Получает количество онлайн пользователей
   * @returns {number} Количество онлайн пользователей
   */
  getUserCount() {
    return this.users.size;
  }

  /**
   * Получает количество реальных пользователей (исключая AI)
   * @returns {number} Количество реальных пользователей
   */
  getRealUserCount() {
    return Array.from(this.users.values()).filter((user) => user.userId !== 'ai_user').length;
  }

  /**
   * Получает количество AI пользователей
   * @returns {number} Количество AI пользователей
   */
  getAICount() {
    return Array.from(this.users.values()).filter((user) => user.userId === 'ai_user').length;
  }

  /**
   * Получает статистику пользователей
   * @returns {Object} Объект с количеством пользователей и AI
   */
  getStats() {
    return {
      users: this.getRealUserCount(),
      ai: this.getAICount(),
      total: this.getUserCount(),
    };
  }

  /**
   * Инициализирует AI пользователя в чате
   * @param {Object} config - Конфигурация AI пользователя
   */
  initializeAI(config) {
    try {
      const aiUser = new AI_User(config);
      this.addUser(aiUser.user.chatId, aiUser.user);
      this.aiInstances.set(aiUser.user.chatId, aiUser);
      console.log('✅ AI пользователь добавлен в чат: ' + config.chatId);
      console.log(`Онлайн: ${this.getRealUserCount()} пользователей, ${this.getAICount()} AI`);
    } catch (error) {
      console.error('❌ Ошибка инициализации AI пользователя:', error.message);
    }
  }

  /**
   * Добавляет сообщение в историю (максимум 20 сообщений)
   * @param {string} messageText - Текст сообщения
   */
  addMessage(messageText) {
    this.messages.push(messageText);
    // Ограничиваем до 20 сообщений
    if (this.messages.length > 20) {
      this.messages = this.messages.slice(-20);
    }
  }

  /**
   * Планирует приветственное сообщение с таймаутом 5 секунд
   * @param {string} chatId - ID чата пользователя
   * @param {Object} bot - Экземпляр бота
   */
  scheduleWelcomeMessage(chatId, bot) {
    setTimeout(() => {
      try {
        // Отправляем "Привет)" как обычное сообщение в чат
        bot.sendMessage(chatId, 'Привет)');
        // console.log(`Приветственное сообщение отправлено пользователю ${chatId}`);
      } catch (error) {
        console.error(`Ошибка отправки приветственного сообщения пользователю ${chatId}:`, error);
      }
    }, 5000); // 5 секунд
  }

  /**
   * Триггер для AI ответа на сообщение пользователя
   * @param {Object} bot - Экземпляр бота
   */
  async triggerAIResponse(bot) {
    const now = Date.now();

    // Проверяем кулдаун (5 минут)
    if (now - this.lastAITrigger < this.AI_COOLDOWN) {
      const remainingTime = Math.ceil((this.AI_COOLDOWN - (now - this.lastAITrigger)) / 1000 / 60);
      console.log(`🤖 AI на кулдауне, осталось ${remainingTime} мин`);
      return;
    }

    // Случайный шанс ответа (30%)
    // if (Math.random() > 0.3) return;

    try {
      // Получаем первый доступный AI экземпляр
      const aiInstance = this.aiInstances.get('first');
      if (!aiInstance) return;

      // Обновляем время последнего триггера
      this.lastAITrigger = now;

      const response = await aiInstance.generateResponse(this.messages);
      if (response) {
        // Отправляем ответ всем пользователям кроме AI
        const allUsers = this.getAllUsers();
        allUsers.forEach((user) => {
          if (user.userId !== 'ai_user') {
            try {
              bot.sendMessage(user.chatId, MESSAGES.anonTextPrefix(response));
            } catch (error) {
              console.error(
                `Ошибка отправки AI ответа пользователю ${user.chatId}:`,
                error.message
              );
            }
          }
        });

        // Добавляем ответ AI в историю
        this.addMessage(response);
        console.log('🤖 AI ответил в чат');
      }
    } catch (error) {
      console.error('❌ Ошибка триггера AI:', error);
    }
  }
}

module.exports = new UserStorage();
