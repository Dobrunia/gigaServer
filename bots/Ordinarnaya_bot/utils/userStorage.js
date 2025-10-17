const fs = require('fs');
const path = require('path');
const AI_User = require('../AI/AI_User');
const { AI_CONFIG_FIRST } = require('../AI/config');
class UserStorage {
  constructor() {
    // В памяти держим только online пользователей
    this.users = new Map(); // chatId -> userData (status === 'online')
    this.jsonFile = path.join(__dirname, '../data/users.json');
    this.ensureDataDir();
    this.loadFromJson();

    //AI
    this.messages = [];
    this.initializeAI(AI_CONFIG_FIRST);
  }

  ensureDataDir() {
    const dataDir = path.dirname(this.jsonFile);
    if (!fs.existsSync(dataDir)) {
      fs.mkdirSync(dataDir, { recursive: true });
    }
  }

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

  // Реестр храним целиком на диске
  readRegistry() {
    try {
      const data = fs.readFileSync(this.jsonFile, 'utf8');
      return JSON.parse(data);
    } catch (_) {
      return [];
    }
  }

  writeRegistry(array) {
    try {
      fs.writeFileSync(this.jsonFile, JSON.stringify(array, null, 2));
    } catch (error) {
      console.error('Ошибка сохранения пользователей в JSON:', error);
    }
  }

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
    console.log(`Онлайн пользователей: ${this.getUserCount()}`);
  }

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
      console.log(`Онлайн пользователей: ${this.getUserCount()}`);
    }
  }

  isUserRegistered(chatId) {
    return this.users.has(chatId);
  }

  getUser(chatId) {
    return this.users.get(chatId);
  }

  getAllUsers() {
    // В памяти только online
    return Array.from(this.users.values());
  }

  getUserCount() {
    return this.users.size;
  }

  // Инициализация AI пользователя
  initializeAI(config) {
    try {
      const aiUser = new AI_User(config);
      this.addUser(aiUser.user.chatId, aiUser.user);
      console.log('✅ AI пользователь добавлен в чат ' + config.username);
    } catch (error) {
      console.error('❌ Ошибка инициализации AI пользователя:', error.message);
    }
  }
}

module.exports = new UserStorage();
