# Node.js CORS Server

Сервер на порту 3003 с поддержкой CORS для задания.

## Установка

```bash
cd servers/nodejs
npm install
```

## Запуск

```bash
npm start
# или
node server.js
```

## API

### GET/POST/PUT/DELETE `/result4/`

Возвращает JSON объект с:

- `message`: "dbe14467-cf9f-4f6d-844e-35d284ae4d2d"
- `x-result`: значение заголовка `x-test` из запроса
- `x-body`: значение тела запроса

### CORS заголовки

- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Methods: GET,POST,PUT,DELETE,OPTIONS`
- `Access-Control-Allow-Headers: x-test,ngrok-skip-browser-warning,Content-Type,Accept,Access-Control-Allow-Headers`

## Тестирование

```bash
# Тест с заголовком x-test
curl -H "x-test: test-value" -H "Content-Type: application/json" -d '{"test": "body"}' http://localhost:3003/result4/

# Ожидаемый ответ:
# {"message":"dbe14467-cf9f-4f6d-844e-35d284ae4d2d","x-result":"test-value","x-body":"{\"test\": \"body\"}"}
```
