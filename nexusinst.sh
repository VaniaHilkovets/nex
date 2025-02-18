#!/bin/bash
set -e

# Проверка версии Ubuntu
REQUIRED_VERSION=22.04
UBUNTU_VERSION=$(lsb_release -rs)
if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo "Для этой ноды нужна минимальная версия Ubuntu $REQUIRED_VERSION"
    exit 1
fi

echo "Устанавливаем необходимые пакеты и Rust..."

# Обновление системы и установка зависимостей (добавлен пакет bc)
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl build-essential pkg-config libssl-dev git-all protobuf-compiler cargo screen bc

# Установка Rust (если ещё не установлен)
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    rustup update
fi

# Завершение предыдущих screen-сессий с именем nexus
SESSION_IDS=$(screen -ls | grep "nexus" | awk '{print $1}' | cut -d '.' -f 1)
if [ -n "$SESSION_IDS" ]; then
    echo "Завершаем ранее запущенные сессии screen: $SESSION_IDS"
    for SESSION_ID in $SESSION_IDS; do
        screen -S "$SESSION_ID" -X quit
    done
fi

# Создание и запуск новой screen-сессии, где будет установлена нода Nexus
screen -dmS nexus bash -c "
  echo 'Скачиваем и устанавливаем Nexus...'
  # Скачиваем инсталлятор Nexus во временный файл
  curl -s https://cli.nexus.xyz/ -o /tmp/nexus_installer.sh
  chmod +x /tmp/nexus_installer.sh
  # Автоматически подтверждаем (Yes) условия, которые запрашивает инсталлятор
  yes Y | /tmp/nexus_installer.sh
  echo 'Nexus установлен. Сессия остаётся открытой. Нажмите Enter или Ctrl+C для выхода.'
  read
"

echo "Нода Nexus запущена в screen-сессии 'nexus'."

# Подключаемся к созданной screen-сессии, если скрипт запущен из интерактивного терминала
if [ -t 0 ]; then
    echo "Переходим в screen-сессию..."
    screen -r nexus
else
    echo "Неинтерактивная оболочка: screen-сессия запущена, но не подключаемся."
fi
