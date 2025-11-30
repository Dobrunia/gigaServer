# ChatGPT Proxy Server

Прокси-сервер для ChatGPT. Передаешь свой API ключ в запросе — получаешь ответ от ChatGPT.

## Быстрый старт

```bash
# Установка зависимостей
pnpm install

# Запуск сервера
pnpm start
```

Сервер работает на `http://localhost:3000`

## Как использовать

### Простой запрос

Отправляешь вопрос ChatGPT и получаешь ответ:

```bash
curl -X POST http://localhost:3000/v1/chat/completions \
  -H "Authorization: Bearer sk-твой-api-ключ" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Привет! Как дела?"}]
  }'
```

**Ответ:**

```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Привет! У меня всё отлично, спасибо..."
      }
    }
  ]
}
```

### Потоковая выдача (streaming)

Чтобы получать ответ по частям, добавь `"stream": true`:

```bash
curl -X POST http://localhost:3000/v1/chat/completions \
  -H "Authorization: Bearer sk-твой-api-ключ" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [{"role": "user", "content": "Расскажи про JavaScript"}],
    "stream": true
  }'
```

Ответ придет потоком — текст будет появляться постепенно.

### Диалог с историей

Можешь отправлять несколько сообщений подряд:

```bash
curl -X POST http://localhost:3000/v1/chat/completions \
  -H "Authorization: Bearer sk-твой-api-ключ" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "user", "content": "Как зовут столицу Франции?"},
      {"role": "assistant", "content": "Столица Франции — Париж."},
      {"role": "user", "content": "А какая там погода?"}
    ]
  }'
```

## Что нужно знать

1. **API ключ** — берешь свой ключ от OpenAI и передаешь в заголовке `Authorization: Bearer <ключ>`
2. **Модель** — можешь использовать `gpt-3.5-turbo` (дешевле) или `gpt-4` (дороже, но умнее)
3. **Streaming** — если хочешь видеть ответ по частям, ставь `"stream": true`

## Другие endpoints

**Проверка работы сервера:**

```bash
curl http://localhost:3000/health
```

**Информация о сервере:**

```bash
curl http://localhost:3000/
```

## Ошибки

- `401` — не указан API ключ
- `403` — неверный API ключ
- `429` — слишком много запросов (лимит OpenAI)
- `500` — ошибка сервера
