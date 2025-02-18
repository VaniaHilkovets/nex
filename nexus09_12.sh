#!/bin/bash
set -e

# Проверка наличия curl и установка, если не установлен
if ! command -v curl >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y curl
fi

sleep 1

# Проверка версии Ubuntu
REQUIRED_VERSION="22.04"
UBUNTU_VERSION=$(lsb_release -rs)
if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo "Для этой ноды нужна минимальная версия Ubuntu $REQUIRED_VERSION"
    exit 1
fi

echo "Устанавливаем ноду Nexus..."

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых компонентов
sudo apt install -y build-essential pkg-config libssl-dev git-all protobuf-compiler cargo screen

# Установка Rust (без интерактивного подтверждения)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
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

echo "Нода запущена в screen-сессии 'nexus'. Подключение к сессии..."
sleep 1

# Переход в сессию
screen -r nexus
