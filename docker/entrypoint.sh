#!/bin/bash
set -e

cd /var/www/html

echo "[entrypoint] iniciando container"

# Garante permissões mesmo que o volume persistente tenha chegado com root
mkdir -p storage/framework/cache/data \
         storage/framework/sessions \
         storage/framework/views \
         storage/logs \
         storage/app/public \
         bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache

# Gera APP_KEY apenas se estiver totalmente ausente.
# Em produção o correto é definir APP_KEY como env var fixa.
if [ -z "${APP_KEY}" ] && [ ! -s .env ]; then
    echo "[entrypoint] APP_KEY ausente, gerando nova (atenção: sessões antigas vão ser invalidadas)"
    php artisan key:generate --force
fi

# Cria symlink public/storage -> storage/app/public se ainda não existir
if [ ! -L public/storage ] && [ ! -e public/storage ]; then
    php artisan storage:link || true
fi

# Limpa caches antes de recriar para pegar novos valores de env var
php artisan optimize:clear || true

# config:cache é seguro; route:cache e view:cache podem ser habilitados depois
# que o app estiver estável (se habilitar, revisar closures em routes/*.php).
php artisan config:cache || true

echo "[entrypoint] pronto, executando: $*"
exec "$@"
