# Набор штук на разных языках

## 🚀 Быстрый запуск

### Все серверы одновременно:

```bash
# Вариант 1: Отдельные терминалы
make start

# Вариант 2: В tmux (рекомендуется)
make start-tmux
```

### Отдельные серверы:

```bash
make perl  # Perl сервер на порту 3000
make rust  # Rust сервер на порту 3001
make go    # Go сервер на порту 3002
```

## 📡 Доступные серверы

- **Perl** http://127.0.0.1:3000
- **Rust** http://127.0.0.1:3001
- **Go** http://127.0.0.1:3002

## 🛠 Управление

```bash
make help    # Показать все команды
make stop    # Остановить tmux сессию
make clean    # Очистить временные файлы
```

## 📁 Структура проекта

```
servers/
├── perl-mojolicious/  # Perl + Mojolicious
├── rust/              # Rust + Axum
└── go/                # Go + net/http
```
