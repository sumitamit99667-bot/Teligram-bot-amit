#!/bin/bash
mkdir -p /app/logs
if [ ! -L /logs ]; then
    rm -rf /logs 2>/dev/null || true
    ln -sfn /app/logs /logs 2>/dev/null || true
fi
mkdir -p /logs /app/logs
touch /logs/output.log /logs/error.log /app/logs/output.log /app/logs/error.log 2>/dev/null || true

_crash_logged=0

while true; do
  ENTRY=""
  if [ -f /app/bot.py ]; then
    ENTRY="/app/bot.py"
  elif [ -f /app/main.py ]; then
    ENTRY="/app/main.py"
  elif [ -f /app/app.py ]; then
    ENTRY="/app/app.py"
  fi

  if [ -z "$ENTRY" ]; then
    if [ "$_crash_logged" = "0" ]; then
      echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ Main entry file (bot.py or main.py) not found in /app. Please upload your bot files." | tee -a /logs/output.log /app/logs/output.log
      _crash_logged=1
    fi
    sleep 2
    continue
  fi

  _crash_logged=0
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] 🚀 Starting $ENTRY..." | tee -a /logs/output.log /app/logs/output.log
  export PYTHONUNBUFFERED=1
  export PYTHONDONTWRITEBYTECODE=1
  python -u "$ENTRY" >> /logs/output.log 2>> /logs/error.log
  _exit_code=$?

  if [ "$_exit_code" != "0" ] && [ "$_crash_logged" = "0" ]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️ Bot process exited (code $_exit_code)." | tee -a /logs/output.log /app/logs/output.log
    _crash_logged=1
  fi

  sleep 1
done
