#!/bin/bash

# set -e


# === обновление пакетов
sudo apt upgrade; sudo apt update;


# === установка doker
# Run the following command to uninstall all conflicting packages:
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# sudo apt-get update
sudo apt-get install ca-certificates curl
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
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin



# === Настройки MySQL ===
MYSQL_ROOT_PASSWORD=rootpass123
MYSQL_USER=nextuser
MYSQL_PASSWORD=nextpass123
MYSQL_DATABASE=nextdb
MYSQL_PORT=3306

# === Настройки Next.js ===
# NEXT_PORT=3000

# === Имена контейнеров и сети ===
NETWORK_NAME=nextjs-mysql-net
MYSQL_CONTAINER_NAME=mysql-db
NEXTJS_CONTAINER_NAME=nextjs-app

# Создаём сеть Docker для связи контейнеров
docker network create $NETWORK_NAME 2>/dev/null || true

# Запускаем MySQL-контейнер
echo "🚀 Запуск MySQL..."
docker run -d \
  --name $MYSQL_CONTAINER_NAME \
  --network $NETWORK_NAME \
  -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
  -e MYSQL_USER=$MYSQL_USER \
  -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
  -e MYSQL_DATABASE=$MYSQL_DATABASE \
  -p $MYSQL_PORT:3306 \
  --health-cmd='mysqladmin ping -h localhost' \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=3 \
  mysql:8.0

# Ждём, пока MySQL станет готов
echo "⏳ Ожидание готовности MySQL..."
while ! docker exec $MYSQL_CONTAINER_NAME mysqladmin ping -h localhost --silent; do
    sleep 2
done
echo "✅ MySQL готов."

# Собираем Docker-образ для Next.js
echo "📦 Сборка Next.js приложения..."
docker build -t nextjs-app .

# Запускаем Next.js-контейнер
echo "🚀 Запуск Next.js приложения..."
docker run -d \
  --name $NEXTJS_CONTAINER_NAME \
  --network $NETWORK_NAME \
  -p $NEXT_PORT:3000 \
  -e DB_HOST=$MYSQL_CONTAINER_NAME \
  -e DB_USER=$MYSQL_USER \
  -e DB_PASS=$MYSQL_PASSWORD \
  -e DB_NAME=$MYSQL_DATABASE \
  nextjs-app

echo "✅ Next.js приложение запущено на http://localhost:$NEXT_PORT"
echo "📝 Подключение к MySQL через: $MYSQL_USER:$MYSQL_PASSWORD@localhost:$MYSQL_PORT/$MYSQL_DATABASE"