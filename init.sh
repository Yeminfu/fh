#!/bin/bash

# set -e

# === обновление пакетов
sudo apt update && sudo apt upgrade -y

# === установка docker
# Run the following command to uninstall all conflicting packages:
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" 2>/dev/null || true
done

sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# install
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# === Настройки MySQL ===
MYSQL_ROOT_PASSWORD=rootpass123
MYSQL_USER=nextuser
MYSQL_PASSWORD=nextpass123
MYSQL_DATABASE=nextdb
MYSQL_PORT=3306

# === Настройки Next.js ===
NEXT_PORT=3000
NEXT_NAME=fh-web-client

# === Имена контейнеров и сети ===
NETWORK_NAME=nextjs-mysql-net
MYSQL_CONTAINER_NAME=mysql-db
NEXTJS_CONTAINER_NAME=nextjs-app

# Создаём сеть Docker для связи контейнеров
docker network create "$NETWORK_NAME" 2>/dev/null || true

# Запускаем MySQL-контейнер
echo "🚀 Запуск MySQL..."
docker run -d \
  --name "$MYSQL_CONTAINER_NAME" \
  --network "$NETWORK_NAME" \
  -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  -e MYSQL_USER="$MYSQL_USER" \
  -e MYSQL_PASSWORD="$MYSQL_PASSWORD" \
  -e MYSQL_DATABASE="$MYSQL_DATABASE" \
  -p "$MYSQL_PORT:3306" \
  --health-cmd='mysqladmin ping -h localhost' \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=3 \
  mysql:8.0

# Ждём, пока MySQL станет готов
echo "⏳ Ожидание готовности MySQL..."
while ! docker exec "$MYSQL_CONTAINER_NAME" mysqladmin ping -h localhost --silent; do
    sleep 2
done
echo "✅ MySQL готов."

# Создаём Next.js приложение
echo "📦 Создание Next.js приложения: $NEXT_NAME"
npx create-next-app@latest "$NEXT_NAME" --use-npm --typescript --tailwind --eslint --app --src-dir

# Создаём .env.local в папке проекта
cat > "$NEXT_NAME/.env.local" <<EOF
DB_HOST=$MYSQL_CONTAINER_NAME
DB_PORT=$MYSQL_PORT
DB_USER=$MYSQL_USER
DB_PASS=$MYSQL_PASSWORD
DB_NAME=$MYSQL_DATABASE
EOF

echo "✅ Файл .env.local создан в $NEXT_NAME/"

# Запускаем Next.js
cd "$NEXT_NAME"
npm install
echo "🚀 Запуск Next.js приложения на http://localhost:$NEXT_PORT"
# npm run dev

