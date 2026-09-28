#!/bin/bash
# SessionEnd hook: oturum kapaninca ham transkript yazicisini arka plana atip hemen cikar.
# LLM cagrisi yok — bu yuzden ozyineleme korumasi da gerekmiyor.
input=$(cat)

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  exit 0
fi

mkdir -p "$HOME/.claude/obsidian-dump"
nohup /usr/bin/env python3 "$HOME/.claude/hooks/obsidian_transcript.py" \
  "$session_id" "$transcript" "$cwd" \
  >> "$HOME/.claude/obsidian-dump/dump.log" 2>&1 &

exit 0
