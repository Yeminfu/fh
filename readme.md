sudo apt upgrade; sudo apt update;

apt install nodejs;
apt install npm;

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash;

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

nvm install --lts;

sudo ufw allow 3000/tcp;

git clone https://github.com/Yeminfu/fh.git;

cd fh;
chmod u+x ./init.sh;
./init.sh


docker exec -it mysql-db mysql -uroot -prootpass123;


-- Используем базу данных
USE `nextdb`;

-- Создаём таблицу cash_transactions
CREATE TABLE IF NOT EXISTS `cash_transactions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `amount` DECIMAL(15,2) NOT NULL COMMENT 'Сумма транзакции',
  `description` VARCHAR(255) NOT NULL COMMENT 'Описание транзакции',
  `is_profit` BIT(1) NOT NULL COMMENT '1 = приход, 0 = расход', 
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Время создания',
  PRIMARY KEY (`id`),
  INDEX `idx_created_at` (`created_at`)
);
exit;