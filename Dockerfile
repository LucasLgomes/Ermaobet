# ==============================================================================
# Stage 1: build do frontend (Vite) com Node 20
# ==============================================================================
FROM node:20-alpine AS frontend

WORKDIR /app

# ARGs com os valores que o Vite inlinha no bundle client-side.
# Definir via "Build Args" no EasyPanel ou via docker build --build-arg ...
ARG APP_NAME=Ermaobet
ARG APP_URL=https://localhost
ARG VITE_BASE_URL=/
ARG VITE_PUSHER_APP_KEY=
ARG VITE_PUSHER_HOST=
ARG VITE_PUSHER_PORT=443
ARG VITE_PUSHER_SCHEME=https
ARG VITE_PUSHER_APP_CLUSTER=mt1
ARG VITE_STRIPE_KEY=

ENV APP_NAME=${APP_NAME} \
    APP_URL=${APP_URL} \
    VITE_APP_NAME=${APP_NAME} \
    VITE_BASE_URL=${VITE_BASE_URL} \
    VITE_PUSHER_APP_KEY=${VITE_PUSHER_APP_KEY} \
    VITE_PUSHER_HOST=${VITE_PUSHER_HOST} \
    VITE_PUSHER_PORT=${VITE_PUSHER_PORT} \
    VITE_PUSHER_SCHEME=${VITE_PUSHER_SCHEME} \
    VITE_PUSHER_APP_CLUSTER=${VITE_PUSHER_APP_CLUSTER} \
    VITE_STRIPE_KEY=${VITE_STRIPE_KEY}

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY vite.config.js tailwind.config.cjs tailwind.config.js postcss.config.js vite-module-loader.js jsconfig.json ./
COPY resources ./resources
COPY public ./public

RUN npm run build

# ==============================================================================
# Stage 2: PHP 8.2 + Apache (runtime)
# ==============================================================================
FROM php:8.2-apache AS runtime

ARG DEBIAN_FRONTEND=noninteractive

# Extensoes PHP exigidas pelo composer.json (+ pdo_mysql, gd, bcmath)
RUN apt-get update && apt-get install -y --no-install-recommends \
        libicu-dev \
        libxml2-dev \
        libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libonig-dev \
        zip \
        unzip \
        git \
        curl \
        default-mysql-client \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        pdo_mysql \
        mysqli \
        intl \
        zip \
        bcmath \
        gd \
        exif \
        pcntl \
        mbstring \
        xml \
    && rm -rf /var/lib/apt/lists/*

# Apache: mod_rewrite + headers, DocumentRoot em /public
RUN a2enmod rewrite headers
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# php.ini para producao
RUN { \
        echo 'upload_max_filesize=500M'; \
        echo 'post_max_size=550M'; \
        echo 'memory_limit=1024M'; \
        echo 'max_execution_time=300'; \
        echo 'max_input_vars=5000'; \
        echo 'expose_php=Off'; \
        echo 'date.timezone=America/Sao_Paulo'; \
    } > /usr/local/etc/php/conf.d/app.ini

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Cache de layer: instala dependencias PHP antes de copiar o app inteiro
COPY composer.json composer.lock ./
RUN composer install \
        --no-dev \
        --no-interaction \
        --prefer-dist \
        --optimize-autoloader \
        --no-scripts

# Codigo da aplicacao
COPY . /var/www/html

# Substitui public/build pelo que foi gerado no stage frontend
RUN rm -rf /var/www/html/public/build
COPY --from=frontend /app/public/build /var/www/html/public/build

# Finaliza autoload (roda scripts do composer agora com app completo)
RUN composer dump-autoload --optimize --no-dev \
    && php artisan package:discover --ansi || true

# Permissoes
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 80

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
