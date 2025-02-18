#!/bin/bash
set -e

# Обновление системы и установка необходимых пакетов
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y build-essential pkg-config libssl-dev git-all protobuf-compiler cargo tmux expect curl

# Установка Rust, если он не установлен
if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
fi
rustup update

# Завершение существующей tmux-сессии с именем nexus, если она существует
tmux kill-session -t nexus 2>/dev/null || true

# Создание временного Expect-скрипта для автоматического ответа "Y"
cat > ~/install_nexus.expect << 'EOF'
#!/usr/bin/expect -f
# Запускаем установку через curl, ожидая приглашения и отвечая Y
spawn curl https://cli.nexus.xyz/ | sh
expect {
    -re "Do you want to continue.*" {
        send "Y\r"
        exp_continue
    }
    eof
}
EOF

chmod +x ~/install_nexus.expect

# Создание новой tmux-сессии с именем nexus в фоновом режиме
tmux new-session -d -s nexus

# Запуск Expect-скрипта внутри tmux-сессии
tmux send-keys -t nexus "~/install_nexus.expect" C-m

# Переход в созданную tmux-сессию
tmux attach-session -t nexus
