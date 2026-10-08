# mega-skills

Скиллы для Claude Code: ревью PR с вердиктом, ответы клиентам, проверка локального окружения и фичи в нескольких репозиториях.

Репозиторий устроен как маркетплейс плагинов Claude Code: в нём один плагин `mega-skills`, внутри которого лежат все скиллы.

## Скиллы

| Скилл | Вызов | Что делает |
|---|---|---|
| review-pr | `/mega-skills:review-pr 2989` | Ревью PR, фикс блокеров с регрессионными тестами, пуш, ожидание зелёного CI, вердикт по мержу. Добавьте `security`, чтобы проверить только безопасность. |
| customer-reply | `/mega-skills:customer-reply` | Ответ клиенту обычным текстом без Markdown, с проверенным именем адресата. |
| preflight | `/mega-skills:preflight` | Проверка и починка окружения перед тестами: Docker/OrbStack, APP_URL в .env, смонтированный worktree, изоляция тестовой БД. |
| multi-repo-feature | `/mega-skills:multi-repo-feature <описание>` | План фичи на backend, gateway и frontend, согласованные PR, проверка, что всё дошло до main. |

Вызывать вручную не обязательно: Claude сам подключает скилл, когда запрос подходит под его описание. Например, «проверь PR 2989 и дай вердикт» запустит `review-pr`.

## Установка

Нужен Claude Code и доступ к репозиторию `Famper/mega-skills` на GitHub.

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

Подходит, если вы правите скиллы и хотите видеть изменения сразу, без обновления плагина. Скиллы будут вызываться без префикса: `/review-pr`, `/preflight`.

```bash
git clone git@github.com:Famper/mega-skills.git ~/PhpstormProjects/mega-skills
mkdir -p ~/.claude/skills
for d in ~/PhpstormProjects/mega-skills/plugins/mega-skills/skills/*/; do
  ln -sfn "$d" ~/.claude/skills/"$(basename "$d")"
done
```

Не используйте оба способа одновременно, иначе каждый скилл появится дважды.

### Только для одного проекта

Чтобы скиллы работали только в конкретном репозитории, скопируйте нужные папки в `.claude/skills/` этого проекта и закоммитьте их.

## Проверка

В новой сессии Claude Code спросите «какие скиллы тебе доступны?» или введите `/` и найдите `review-pr` в списке.

## Структура

```
mega-skills/
├── .claude-plugin/
│   └── marketplace.json          # описание маркетплейса
└── plugins/
    └── mega-skills/
        ├── .claude-plugin/
        │   └── plugin.json       # описание плагина
        └── skills/
            ├── review-pr/SKILL.md
            ├── customer-reply/SKILL.md
            ├── preflight/SKILL.md
            └── multi-repo-feature/SKILL.md
```

## Как добавить свой скилл

1. Создайте папку `plugins/mega-skills/skills/<имя>/` с файлом `SKILL.md`:

   ```markdown
   ---
   name: <имя>
   description: Что делает скилл и когда его использовать. Claude выбирает скилл по этому тексту.
   ---

   Инструкции для Claude.
   ```

2. Рядом можно положить скрипты, шаблоны и примеры, на которые ссылается `SKILL.md`.
3. Проверьте, что всё собирается и скилл виден:

   ```bash
   claude plugin validate .
   claude --plugin-dir ./plugins/mega-skills plugin details mega-skills
   ```

4. Поднимите `version` в `plugins/mega-skills/.claude-plugin/plugin.json`.
5. Закоммитьте и запушьте. Тем, кто установил плагин, нужно выполнить команды из раздела «Обновление».
