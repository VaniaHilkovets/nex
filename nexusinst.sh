#!/bin/bash
set -e

# Обновление системы и установка необходимых пакетов
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y build-essential pkg-config libssl-dev git-all protobuf-compiler cargo tmux expect curl

# Установка Rust, если он не установлен
if ! command -v rustup >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # Обновляем текущую сессию
    source "$HOME/.cargo/env"
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
fi
rustup update

# Завершаем существующую tmux-сессию "nexus", если такая есть
tmux kill-session -t nexus 2>/dev/null || true

# Создаём временный Expect-скрипт для автоматического подтверждения установки Nexus
cat > /tmp/install_nexus.expect << 'EOF'
#!/usr/bin/expect -f
set timeout -1
# Запускаем установку Nexus через curl
spawn curl https://cli.nexus.xyz/ | sh
# Если появится запрос подтверждения, отвечаем "Y"
expect {
    -re {Do you want to continue.*} {
        send "Y\r"
        exp_continue
    }
    eof
}
EOF
chmod +x /tmp/install_nexus.expect

# Создаём новую tmux-сессию "nexus" в фоновом режиме
tmux new-session -d -s nexus

# Запускаем Expect-скрипт внутри tmux-сессии
tmux send-keys -t nexus "/tmp/install_nexus.expect" C-m

# Переключаемся в созданную tmux-сессию
tmux attach-session -t nexus
