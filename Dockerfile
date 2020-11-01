ARG TAG=latest
FROM php:${TAG}

# change dns
RUN echo 'nameserver 223.5.5.5' > /etc/resolv.conf \
    && echo 'nameserver 8.8.8.8' >> /etc/resolv.conf

# change source
RUN sed -i 's/\(deb\|security\).debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list

# install extension
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libssl-dev \
        libmemcached-dev \
        libzip-dev \
        git \
    && apt-get autoclean && apt-get clean \
    && pecl channel-update pecl.php.net \
    && pecl install redis \
    && pecl install xdebug \
    && docker-php-ext-configure \
        gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        -j$(nproc) gd \
    && docker-php-ext-enable \
        redis \
        xdebug \
    && docker-php-ext-install \
        bcmath \
        mysqli \
        opcache \
        pdo_mysql \
        zip \
    # php.ini 文件
    && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# install composer
RUN curl -o /usr/bin/composer https://mirrors.aliyun.com/composer/composer.phar \
    && chmod +x /usr/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# change timezone
RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezone

WORKDIR /var/www

EXPOSE 9000