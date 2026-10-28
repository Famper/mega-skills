# mega-skills

Скиллы для Claude Code и Google Antigravity: ревью PR с вердиктом, ревью безопасности, ответы клиентам, проверка локального окружения и фичи в нескольких репозиториях.

Репозиторий универсален и поддерживает как Claude Code, так и Google Antigravity.

## Скиллы

| Скилл | Вызов | Что делает |
|---|---|---|
| security-review | `/mega-skills:security-review 2989` | Ревью PR без правок: общее ревью кода (корректность, производительность, обработка ошибок, качество тестов, совместимость миграций и API) и безопасность (authz/IDOR, XSS, open redirect, сессии, rate limits). Тесты в Docker, прогон на свежем main, градация находок, отчёт в PR. |
| review-pr | `/mega-skills:review-pr 2989` | Исправить блокеры и довести PR до зелёного CI: фикс с регрессионным тестом, пуш в ветку PR, ожидание CI, вердикт. Запускается только по явной просьбе менять код. |
| customer-reply | `/mega-skills:customer-reply` | Ответ клиенту обычным текстом без Markdown, с проверенным именем адресата. |
| preflight | `/mega-skills:preflight` | Проверка и починка окружения перед тестами: Docker/OrbStack, APP_URL в .env, смонтированный worktree, изоляция тестовой БД. |
| multi-repo-feature | `/mega-skills:multi-repo-feature <описание>` | План фичи на backend, gateway и frontend, согласованные PR, проверка, что всё дошло до main. |

## Хуки

Репозиторий включает два хука, адаптированных как для Claude Code, так и для Antigravity:

| Хук | Когда | Что делает |
|---|---|---|
| docker-check | Начало сессии (`SessionStart`) | Если в проекте есть docker-compose, а Docker/OrbStack не отвечает, предупреждает агента, и тот сразу сообщает вам. |
| php-lint | После правки `.php` (`PostToolUse`) | Прогоняет phpcs по изменённому файлу (стандарт `App/Standards/Laravel.xml` или `phpcs.xml` проекта) и возвращает ошибки агенту, чтобы он исправил их до пуша. Предупреждения не показывает, только ошибки. |

Хукам нужны `jq` и `php` на машине. Если phpcs в проекте не установлен, php-lint молчит.

Вызывать скиллы вручную не обязательно: агент сам подключает скилл, когда запрос подходит под его описание. Например, «проверь PR 2989 и дай вердикт» запустит `security-review` — ревью только на чтение. Правки в ветке PR делает `review-pr`, и только если вы прямо попросили исправить и запушить.

---

## Установка в Google Antigravity

### Способ 1. Симлинками в глобальные скиллы (рекомендуется)

Скиллы будут доступны во всех ваших проектах, а изменения после `git pull` подхватятся сразу без перезагрузок:

```bash
mkdir -p ~/.gemini/config/skills
for d in ~/PhpstormProjects/mega-skills/plugins/mega-skills/skills/*/; do
  ln -sfn "$d" ~/.gemini/config/skills/"$(basename "$d")"
done
```

### Способ 2. Через глобальный `skills.json`

Добавьте путь к папке скиллов в `~/.gemini/config/skills.json`:

```json
{
  "entries": [
    {
      "path": "~/PhpstormProjects/mega-skills/plugins/mega-skills/skills"
    }
  ]
}
```

### Способ 3. Как плагин Antigravity (включая хуки)

Залинкуйте плагин в каталог плагинов Antigravity:

```bash
mkdir -p ~/.gemini/config/plugins
ln -sfn ~/PhpstormProjects/mega-skills/plugins/mega-skills ~/.gemini/config/plugins/mega-skills
```

### Способ 4. Только для одного проекта

Скопируйте нужные папки в `.agents/skills/` репозитория проекта:

```bash
mkdir -p <путь_к_проекту>/.agents/skills
cp -R ~/PhpstormProjects/mega-skills/plugins/mega-skills/skills/* <путь_к_проекту>/.agents/skills/
```

---

## Установка в Claude Code

### Способ 1. Как плагин (рекомендуется)

Подключить маркетплейс и установить плагин:

```bash
claude plugin marketplace add Famper/mega-skills
claude plugin install mega-skills@mega-skills
```

То же самое можно сделать внутри сессии `claude` в терминале:

```
/plugin marketplace add Famper/mega-skills
/plugin install mega-skills@mega-skills
```

Перезапустите Claude Code. Скиллы будут доступны во всех проектах с префиксом `mega-skills:`.

Обновление после изменений в репозитории:

```bash
claude plugin marketplace update mega-skills
claude plugin update mega-skills@mega-skills
```

Удаление:

```bash
claude plugin uninstall mega-skills@mega-skills
```

### Способ 2. Ссылками в личные скиллы (для разработки)

```bash
git clone git@github.com:Famper/mega-skills.git ~/PhpstormProjects/mega-skills
mkdir -p ~/.claude/skills
for d in ~/PhpstormProjects/mega-skills/plugins/mega-skills/skills/*/; do
  ln -sfn "$d" ~/.claude/skills/"$(basename "$d")"
done
```

### Только для одного проекта

Скопируйте нужные папки в `.claude/skills/` этого проекта и закоммитьте их.

---

## Теги в GitHub

- **`v1.4.0-claude`** — релиз для Claude Code.
- **`v1.4.0-antigravity`** — релиз с универсальной поддержкой Google Antigravity и Claude Code.

---

## Структура

```
mega-skills/
├── .claude-plugin/
│   └── marketplace.json          # описание маркетплейса Claude Code
└── plugins/
    └── mega-skills/
        ├── .claude-plugin/
        │   └── plugin.json       # манифест плагина для Claude Code
        ├── plugin.json           # манифест плагина для Google Antigravity
        ├── hooks.json            # хуки для Google Antigravity
        ├── skills/
        │   ├── security-review/SKILL.md
        │   ├── review-pr/SKILL.md
        │   ├── customer-reply/SKILL.md
        │   ├── preflight/SKILL.md
        │   └── multi-repo-feature/SKILL.md
        └── hooks/
            ├── hooks.json        # хуки для Claude Code
            ├── docker-check.sh   # универсальный скрипт проверки Docker
            └── php-lint.sh       # универсальный скрипт линтинга PHP
```

## Как добавить свой скилл

1. Создайте папку `plugins/mega-skills/skills/<имя>/` с файлом `SKILL.md`:

   ```markdown
   ---
   name: <имя>
   description: Что делает скилл и когда его использовать. Агент выбирает скилл по этому тексту.
   ---

   Инструкции для агента.
   ```

2. Рядом можно положить скрипты, шаблоны и примеры, на которые ссылается `SKILL.md`.
3. Для Claude Code проверьте, что плагин валиден:

   ```bash
   claude plugin validate .
   claude --plugin-dir ./plugins/mega-skills plugin details mega-skills
   ```

4. Поднимите `version` в `plugins/mega-skills/.claude-plugin/plugin.json` и `plugins/mega-skills/plugin.json`.
5. Закоммитьте и запушьте изменения.
