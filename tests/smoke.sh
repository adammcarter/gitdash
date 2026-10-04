#!/usr/bin/env bash
# Starts gitdash on a throwaway repo and checks the page, the live feed and a diff.
set -euo pipefail
GITDASH="$(cd "$(dirname "$0")/.." && pwd)/gitdash"
PY="${PYTHON:-python3}"
PORT="${PORT:-47911}"
work="$(mktemp -d)"
trap 'kill "$pid" 2>/dev/null || true; rm -rf "$work" "$work.log"' EXIT

cd "$work"
git init -q
git config user.email ci@example.com
git config user.name ci
printf 'one\ntwo\n' > kept.txt
git add kept.txt
git commit -qm init
printf 'one\nTWO\n' > kept.txt
printf 'new\n' > added.txt

"$PY" "$GITDASH" --no-open --port "$PORT" >"$work.log" 2>&1 &
pid=$!
for _ in $(seq 50); do curl -fs "http://127.0.0.1:$PORT/" >/dev/null && break; sleep 0.2; done

page="$(curl -fsS "http://127.0.0.1:$PORT/")"
grep -q "<title>" <<<"$page" || { echo "page did not load"; cat "$work.log"; exit 1; }
event="$(curl -s -N --max-time 3 "http://127.0.0.1:$PORT/events" | grep -m1 '^data:' || true)"
echo "$event" | grep -q '"added.txt"' || { echo "added.txt missing from the feed"; exit 1; }
echo "$event" | grep -q '"kept.txt"' || { echo "kept.txt missing from the feed"; exit 1; }
diff="$(curl -fsS "http://127.0.0.1:$PORT/api/diff?path=kept.txt")"
grep -q '^+TWO' <<<"$diff" || { echo "diff is wrong"; exit 1; }

git commit -qam "commit it"
sleep 1.5
event="$(curl -s -N --max-time 3 "http://127.0.0.1:$PORT/events" | grep -m1 '^data:' || true)"
echo "$event" | grep -q '"Committed"' || { echo "commit event missing"; exit 1; }

echo "smoke test passed ($("$PY" --version 2>&1))"
