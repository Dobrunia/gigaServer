// To run this code you need to install the following dependencies:
// npm install @google/genai mime
// npm install -D @types/node

const { GoogleGenAI } = require('@google/genai');
class AI_User {
  constructor(config) {
    if (!config) {
      throw new Error('AI_User requires config parameter');
    }
    if (!process.env.GEMINI_API_KEY) {
      console.error('❌ GEMINI_API_KEY не найден в переменных окружения!');
      throw new Error('GEMINI_API_KEY is required');
    }

    this.ai = new GoogleGenAI({
      apiKey: process.env.GEMINI_API_KEY,
    });
    this.config = config; // Сохраняем весь конфиг
    this.model = config.model;
    this.user = {
      chatId: config.chatId,
      id: config.id,
      first_name: config.first_name,
      last_name: config.last_name,
      username: config.username,
    };
    this.prompt = config.prompt;
    this.isProcessing = false; // Флаг обработки
  }

  /**
   * Генерирует ответ AI на основе истории сообщений
   * @param {Array} messages - Массив сообщений из чата
   * @returns {Promise<string>} Ответ AI
   */
  async generateResponse(messages) {
    if (this.isProcessing) {
      console.log('🤖 AI уже обрабатывает запрос, пропускаем...');
      return null;
    }

    this.isProcessing = true;
    console.log('🤖 AI начал обработку...');

    try {
      const fullPrompt = `${this.prompt}\n${messages.join('\n')}`;

      const result = await this.ai.models.generateContent({
        model: this.model,
        contents: [{ role: 'user', parts: [{ text: fullPrompt }] }],
      });

      // 1) Попробовать стандартную форму SDK (если присутствует)
      try {
        if (result && result.response && typeof result.response.text === 'function') {
          const t = result.response.text();
          if (t) return String(t).trim();
        }
      } catch (e) {
        // игнорируем и пробуем альтернативы
      }

      // 2) Явная обработка структуры, которую ты показал:
      // result.candidates[0].content.parts[*].text
      if (Array.isArray(result?.candidates) && result.candidates.length > 0) {
        const cand = result.candidates[0];
        // поддерживаем вариант: cand.content.parts -> [{text: "..."}]
        const parts =
          cand?.content?.parts ??
          cand?.message?.parts ?? // возможный альтернативный путь
          null;

        if (Array.isArray(parts) && parts.length > 0) {
          const text = parts
            .map((p) => p && (p.text ?? p.content ?? ''))
            .filter(Boolean)
            .join('');
          if (text) return String(text).trim();
        }

        // fallback: cand.content может быть объект с .text
        if (typeof cand?.content?.text === 'string') {
          return cand.content.text.trim();
        }
        if (typeof cand?.text === 'string') {
          return cand.text.trim();
        }
      }

      // 3) Ещё один возможный путь: result.output / result.outputs
      if (Array.isArray(result?.output) && result.output.length > 0) {
        const out = result.output[0];
        if (Array.isArray(out?.content)) {
          const text = out.content
            .map((c) => c.text ?? '')
            .filter(Boolean)
            .join('');
          if (text) return text.trim();
        }
        if (typeof out?.text === 'string') return out.text.trim();
      }

      // 4) Логируем структуру для дебага — сделай это один раз при проблеме
      console.error(
        '⚠️ Не удалось извлечь текст из ответа Google GenAI SDK. Полная структура:\n',
        console.log(result, { depth: 4 })
      );

      return null;
    } catch (error) {
      console.error('❌ Ошибка генерации ответа AI:', error);
      return null;
    } finally {
      this.isProcessing = false;
    }
  }
}

module.exports = AI_User;
