
FROM php:7.4-fpm
ARG ENVIRONMENT=production

ARG NAMESERVER
ARG SOURCEMIRROR
ARG TIMEZONE

ENV DEBIAN_FRONTEND noninteractive

# change name server
RUN set -eux; \
    if [ $NAMESERVER ]; then \
        echo "nameserver $NAMESERVER" > /etc/resolv.conf; \
    fi;

# change source mirror
RUN set -eux; \
    if [ $SOURCEMIRROR ]; then \
        sed -i "s/\(deb\|security\).debian.org/$SOURCEMIRROR/g" /etc/apt/sources.list; \
    fi;

# update apt && pecl
RUN set -eux; \
    apt-get update && apt upgrade -y; \
    pecl channel-update pecl.php.net;

# change time zone
RUN set -eux; \
    if [ $TIMEZONE ]; then \
        cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone; \
    fi;

# change php ini
RUN set -eux; \
    cp "$PHP_INI_DIR/php.ini-$ENVIRONMENT" "$PHP_INI_DIR/php.ini"

# install tools
RUN set -eux; \
    apt-get install -y git;

# install tools(development)
RUN set -eux; \
    if [ "$ENVIRONMENT" = "development" ]; then \
        apt-get install -y \
            iputils-ping \
            net-tools \
            dnsutils \
            telnet \
            procps \
            wget \
            vim; \
    fi;

# install extension
RUN set -eux; \
    pecl install redis && docker-php-ext-enable redis; \
    # install gd
    apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
        && docker-php-ext-configure gd --with-freetype --with-jpeg \
        && docker-php-ext-install -j$(nproc) gd; \
    # install zip
    apt-get install -y libzip-dev && docker-php-ext-install zip; \
    # install other
    docker-php-ext-install \
        bcmath \
        mysqli \
        opcache \
        pdo_mysql;

# install extension(development)
RUN set -eux; \
    if [ "$ENVIRONMENT" = "development" ]; then \
        # install xdebug
        pecl install xdebug && docker-php-ext-enable xdebug; \
    fi;

# clean extension
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && apt-get autoclean \
    && apt-get clean;

# install composer
RUN set -eux; \
    curl -o /usr/bin/composer https://mirrors.aliyun.com/composer/composer.phar; \
    chmod +x /usr/bin/composer; \
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

WORKDIR /var/www

EXPOSE 9000