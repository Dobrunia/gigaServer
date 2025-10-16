// Экспорт всех обработчиков
const startHandler = require('./start');
const messageHandler = require('./messages');

module.exports = {
  startHandler,
  messageHandler,
};
