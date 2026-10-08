#!/bin/sh
# SessionStart: предупредить, если проект живёт в Docker, а Docker не отвечает.
# Вывод попадает в контекст сессии. Молчит, если в проекте нет docker-compose
# или Docker в порядке.
cwd=$(jq -r '.cwd // empty' 2>/dev/null)
[ -n "$cwd" ] || cwd=$(pwd)
root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || echo "$cwd")

uses_docker=no
for f in "$root"/docker-compose*.yml "$root"/docker-compose*.yaml "$root"/compose*.yml "$root"/compose*.yaml; do
    [ -f "$f" ] && uses_docker=yes && break
done
[ "$uses_docker" = yes ] || exit 0
docker info >/dev/null 2>&1 && exit 0

echo "ВНИМАНИЕ: Docker/OrbStack не отвечает, а проект запускается в Docker. Локальные тесты и pre-commit хуки упадут. Сообщи пользователю сразу и предложи запустить OrbStack (open -a OrbStack), не пытайся обходить это."
exit 0
