#!/bin/bash
set -e

# Обновление системы и установка необходимых пакетов
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y build-essential pkg-config libssl-dev git-all protobuf-compiler cargo tmux expect curl

# Установка Rust, если он не установлен
if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # Подгружаем окружение для текущей сессии
    source "$HOME/.cargo/env"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
fi
rustup update

# Завершаем существующую tmux-сессию "nexus", если она есть
tmux kill-session -t nexus 2>/dev/null || true

# Создаём новую tmux-сессию "nexus" в фоновом режиме
tmux new-session -d -s nexus

# Отправляем команду установки Nexus в сессию.
# Используем expect для автоматического ответа "Y" при появлении запроса.
tmux send-keys -t nexus "expect -c 'set timeout -1; \
  spawn curl https://cli.nexus.xyz/ | sh; \
  expect { -re \"Do you want to continue.*\" { send \"Y\r\"; exp_continue } eof { exit } }'" C-m
