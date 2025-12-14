# Answerly

Answerly — вебзастосунок на Ruby on Rails для проведення “інтерв'ю-тренажера”: система генерує питання (OpenAI), створює відео-питання з аватаром (HeyGen), приймає відео-відповіді користувача, транскрибує їх (ElevenLabs) і формує загальний фідбек (OpenAI). Фонові задачі виконує Sidekiq (Redis).

## Стек

- Ruby on Rails 7.2
- PostgreSQL
- Redis + Sidekiq
- Devise (автентифікація)
- Hotwire (Turbo/Stimulus) + TailwindCSS
- Інтеграції: OpenAI, HeyGen, ElevenLabs STT

## Вимоги

- Linux/macOS/WSL
- Ruby `3.4.2` (див. `.ruby-version`)
- PostgreSQL 13+
- Redis 6+

## Швидкий старт (development)

### 1) Системні пакети (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install -y git curl build-essential libpq-dev postgresql postgresql-contrib redis-server
sudo systemctl enable --now postgresql redis-server
```

### 2) Встановити Ruby 3.4.2

Рекомендовано через `rbenv`.

```bash
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer | bash
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - bash)"

rbenv install 3.4.2
rbenv local 3.4.2
gem install bundler
```

### 3) Налаштувати PostgreSQL доступ (щоб `rails db:create` працював)

Якщо у тебе немає ролі з іменем поточного користувача ОС:

```bash
sudo -u postgres createuser -s "$USER"
```

### 4) Змінні середовища (`.env`)

Проєкт використовує `dotenv-rails`, тому достатньо створити файл `.env` у корені.

```bash
cp .env.example.erb .env
```

Відкрий `.env` та заповни ключі:

- `OPENAI_API_KEY` — API key OpenAI
- `HEYGEN_API_KEY` — API key HeyGen
- `ELEVENLABS_API_KEY` — API key ElevenLabs (Speech-to-Text)
- `HOST` — базова URL-адреса застосунку (важливо для callback URL webhooks HeyGen)
- `REDIS_URL` — URL Redis (за замовчуванням `redis://localhost:6379/0`)

### 5) Встановити залежності та підняти БД

```bash
bundle install
bin/rails db:prepare
```

Альтернатива (робить приблизно те саме):

```bash
bin/setup
```

### 6) Запуск застосунку

Найзручніше — через `bin/dev` (піднімає Rails + Tailwind watcher + Sidekiq через `Procfile.dev`).

```bash
bin/dev
```

Відкрий у браузері:

- `http://localhost:3000`

Sidekiq Web UI (у dev без захисту):

- `http://localhost:3000/sidekiq`

## Ngrok і webhooks HeyGen (важливо)

HeyGen має “достукатись” до твого `/heygen/webhook`. Для локальної розробки потрібна публічна HTTPS-адреса.

### 1) Запустити ngrok

```bash
ngrok http 3000
```

Скопіюй HTTPS URL (наприклад `https://xxxx.ngrok-free.app`).

### 2) Виставити `HOST`

У `.env`:

```bash
HOST=https://xxxx.ngrok-free.app
```

Перезапусти процеси (особливо Sidekiq), і створюй нову сесію/генеруй відео заново — callback URL підставляється під час запиту генерації відео.

### 3) Як перевірити webhook вручну

```bash
curl -sS -X POST "$HOST/heygen/webhook" \
	-H 'Content-Type: application/json' \
	-d '{"event_type":"avatar_video.success","event_data":{"video_id":"test","url":"https://example.com/video"}}'
```

Примітка: у реальному сценарії `video_id` має збігатись із `Question.video_id`, який зберігається після запиту до HeyGen.

## Як користуватись (коротко)

1) Зареєструйся / увійди.
2) Створи `Interview Session` (за потреби прикріпи резюме).
3) Дочекайся генерації питань і відео (виконується у фоні Sidekiq).
4) Відкрий інтерв'ю, дозволь доступ до камери/мікрофона, запиши відповіді.
5) Після завершення переглянь сторінку фідбеку.

## Тести

```bash
bin/rails test
```

## Troubleshooting

### `bundle exec rails db:create` падає

Найчастіше причина — PostgreSQL не запущений або немає ролі користувача.

```bash
sudo systemctl status postgresql
sudo -u postgres createuser -s "$USER"
```

Якщо у тебе інші креденшіали/порт — задай `DATABASE_URL` у `.env`.

### Sidekiq не стартує

Перевір Redis:

```bash
redis-cli ping
```

За потреби задай `REDIS_URL` у `.env`.

## Production / Docker (опційно)

У репозиторії є `Dockerfile` для production-збірки. Для локальної розробки рекомендовано стандартний dev-режим (`bin/dev`).
