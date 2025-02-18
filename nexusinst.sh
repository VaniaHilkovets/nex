#!/bin/bash
set -e

# Проверка наличия curl и установка, если не установлен
if ! command -v curl >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y curl
fi
sleep 1

# Проверка версии Ubuntu
REQUIRED_VERSION=22.04
UBUNTU_VERSION=$(lsb_release -rs)
if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo "Для этой ноды нужна минимальная версия Ubuntu $REQUIRED_VERSION"
    exit 1
fi

echo "Устанавливаем ноду Nexus..."

# Обновление системы и установка необходимых компонентов
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y build-essential pkg-config libssl-dev git-all protobuf-compiler cargo screen

# Установка Rust (без интерактивного подтверждения)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
rustup update

# Завершение предыдущих сессий screen с именем nexus, если они есть
SESSION_IDS=$(screen -ls | grep "nexus" | awk '{print $1}' | cut -d '.' -f 1)
if [ -n "$SESSION_IDS" ]; then
    echo "Завершаем ранее запущенные сессии screen: $SESSION_IDS"
    for SESSION_ID in $SESSION_IDS; do
        screen -S "$SESSION_ID" -X quit
    done
fi

# Создание новой screen-сессии с именем nexus
screen -dmS nexus

echo "Нода запущена в screen-сессии 'nexus'."
echo "Для перехода в сессию используйте:"
echo "screen -r nexus"

# Автоматический переход в сессию (если запуск из интерактивного терминала)
if [ -t 0 ]; then
    screen -r nexus
fi

