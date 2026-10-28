#!/bin/sh
# PostToolUse (Edit/Write / edit_file/write_file): phpcs по только что изменённому PHP-файлу.
# Нарушения возвращаются агенту, чтобы он исправил их до пуша, а не
# после падения CI. Молчит, если файл не PHP, в проекте нет phpcs или
# непонятно, по какому стандарту проверять.
# Поддерживает Claude Code и Google Antigravity.

input=$(cat)
is_antigravity=no
if echo "$input" | jq -e '.conversationId // .toolCall' >/dev/null 2>&1; then
    is_antigravity=yes
fi

file=$(echo "$input" | jq -r '.toolCall.args.Path // .tool_input.file_path // empty' 2>/dev/null)
case "$file" in *.php) ;; *) [ "$is_antigravity" = yes ] && echo "{}"; exit 0 ;; esac
[ -f "$file" ] || { [ "$is_antigravity" = yes ] && echo "{}"; exit 0; }
command -v php >/dev/null 2>&1 || { [ "$is_antigravity" = yes ] && echo "{}"; exit 0; }

dir=$(dirname "$file")
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || { [ "$is_antigravity" = yes ] && echo "{}"; exit 0; }

# Ближайший vendor/bin/phpcs от файла вверх до корня репозитория.
phpcs=""
d="$dir"
while :; do
    if [ -x "$d/vendor/bin/phpcs" ]; then phpcs="$d/vendor/bin/phpcs"; break; fi
    [ "$d" = "$root" ] || [ "$d" = "/" ] && break
    d=$(dirname "$d")
done
[ -n "$phpcs" ] || { [ "$is_antigravity" = yes ] && echo "{}"; exit 0; }

# Стандарт: App/Standards/Laravel.xml (CRM_AGENT), иначе конфиг проекта.
base=$(dirname "$(dirname "$(dirname "$phpcs")")")
if [ -f "$base/Standards/Laravel.xml" ]; then
    standard="--standard=$base/Standards/Laravel.xml"
else
    standard=""
    for c in phpcs.xml phpcs.xml.dist .phpcs.xml .phpcs.xml.dist; do
        [ -f "$base/$c" ] && standard="--standard=$base/$c" && break
    done
    [ -n "$standard" ] || { [ "$is_antigravity" = yes ] && echo "{}"; exit 0; }
fi

# -n: только ошибки, без предупреждений — их в старых файлах много.
# shellcheck disable=SC2086
out=$("$phpcs" -q -n --report=emacs $standard "$file" 2>&1) && { [ "$is_antigravity" = yes ] && echo "{}"; exit 0; }
[ -n "$out" ] || { [ "$is_antigravity" = yes ] && echo "{}"; exit 0; }

{
    echo "phpcs нашёл ошибки стиля в $file:"
    echo "$out" | head -30
    echo "Исправь те, что в твоих изменениях (часть может быть старой). Автоисправление: $(dirname "$phpcs")/phpcbf $standard \"$file\""
} >&2

if [ "$is_antigravity" = yes ]; then
    echo "{}"
fi
exit 2
