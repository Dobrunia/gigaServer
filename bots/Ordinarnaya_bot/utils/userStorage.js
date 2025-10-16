const fs = require('fs');
const path = require('path');

class UserStorage {
  constructor() {
    this.users = new Map(); // chatId -> userData
    this.jsonFile = path.join(__dirname, '../data/users.json');
    this.ensureDataDir();
    this.loadFromJson();
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

        // Загружаем пользователей в Map
        usersArray.forEach((user) => {
          this.users.set(user.chatId, user);
        });

        console.log(`Загружено ${usersArray.length} пользователей из JSON`);
      }
    } catch (error) {
      console.error('Ошибка загрузки пользователей из JSON:', error);
    }
  }

  saveToJson() {
    try {
      const usersArray = Array.from(this.users.values());
      fs.writeFileSync(this.jsonFile, JSON.stringify(usersArray, null, 2));
    } catch (error) {
      console.error('Ошибка сохранения пользователей в JSON:', error);
    }
  }

  addUser(chatId, userData) {
    this.users.set(chatId, {
      chatId,
      userId: userData.id,
      firstName: userData.first_name,
      lastName: userData.last_name,
      username: userData.username,
      joinedAt: new Date().toISOString(),
    });

    // Сохраняем в JSON
    this.saveToJson();

    console.log(`Пользователь добавлен: ${userData.first_name} (${chatId})`);
    console.log(`Всего пользователей: ${this.users.size}`);
  }

  removeUser(chatId) {
    const user = this.users.get(chatId);
    if (user) {
      this.users.delete(chatId);

      // НЕ сохраняем в JSON - пользователь остается в файле
      // this.saveToJson();

      console.log(`Пользователь удален: ${user.firstName} (${chatId})`);
      console.log(`Всего пользователей: ${this.users.size}`);
    }
  }

  isUserRegistered(chatId) {
    return this.users.has(chatId);
  }

  getUser(chatId) {
    return this.users.get(chatId);
  }

  getAllUsers() {
    return Array.from(this.users.values());
  }

  getUserCount() {
    return this.users.size;
  }

  // Очистка неактивных пользователей (можно вызывать периодически)
  cleanupInactiveUsers() {
    // Здесь можно добавить логику очистки неактивных пользователей
    // Например, по времени последней активности
    console.log('Очистка неактивных пользователей...');
  }
}

module.exports = new UserStorage();
