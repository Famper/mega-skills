#!/bin/sh
# SessionStart: предупредить, если проект живёт в Docker, а Docker не отвечает.
# Вывод попадает в контекст сессии. Молчит, если в проекте нет docker-compose
# или Docker в порядке.
# Поддерживает Claude Code и Google Antigravity.

input=$(cat)
is_antigravity=no
if echo "$input" | jq -e '.conversationId // .workspacePaths' >/dev/null 2>&1; then
    is_antigravity=yes
fi

cwd=$(echo "$input" | jq -r '.cwd // .workspacePaths[0] // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd=$(pwd)
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")

uses_docker=no
for f in "$root"/docker-compose*.yml "$root"/docker-compose*.yaml "$root"/compose*.yml "$root"/compose*.yaml; do
    [ -f "$f" ] && uses_docker=yes && break
done

if [ "$uses_docker" != yes ]; then
    [ "$is_antigravity" = yes ] && echo "{}"
    exit 0
fi

if docker info >/dev/null 2>&1; then
    [ "$is_antigravity" = yes ] && echo "{}"
    exit 0
fi

msg="ВНИМАНИЕ: Docker/OrbStack не отвечает, а проект запускается в Docker. Локальные тесты и pre-commit хуки упадут. Сообщи пользователю сразу и предложи запустить OrbStack (open -a OrbStack), не пытайся обходить это."

if [ "$is_antigravity" = yes ]; then
    jq -n --arg msg "$msg" '{"injectSteps": [{"systemMessage": {"systemMessage": $msg}}]}'
else
    echo "$msg"
fi
exit 0
