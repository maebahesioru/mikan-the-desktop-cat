#!/bin/bash
# petwork.sh — send a Hackatime heartbeat for the desktop-pet project.
# Usage: ./petwork.sh [path]   (defaults to main.gd)
# The terminal-wakatime shell hooks don't fire in non-TTY command runners
# (like the agent's terminal), so we send heartbeats explicitly while working.
KEY="f178a39b-1ed5-4629-8439-d8cab6028aff"
ENTITY="${1:-/home/maebahesioru/ダウンロード/sushi_money_research/実行/240_hackclub/playground/pet/main.gd}"
NOW=$(date +%s)
curl -s -m 20 -X POST "https://hackatime.hackclub.com/api/hackatime/v1/users/current/heartbeats" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d "{\"entity\":\"$ENTITY\",\"type\":\"file\",\"time\":$NOW,\"language\":\"GDScript\",\"category\":\"coding\",\"project\":\"desktop-pet\",\"editor\":\"terminal-wakatime\",\"operating_system\":\"Linux\",\"machine\":\"cachyos-mainpc\"}" \
  -o /dev/null -w "heartbeat: %{http_code}\n"
