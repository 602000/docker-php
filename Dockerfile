ARG PHPVERSION=7.4
FROM php:$PHPVERSION-fpm

ARG ENVIRONMENT=production
ARG NAMESERVER
ARG SOURCEMIRROR
ARG TIMEZONE

ENV DEBIAN_FRONTEND noninteractive

# change name server
RUN set -ex; \
    if [ $NAMESERVER ]; then \
        echo "nameserver $NAMESERVER" > /etc/resolv.conf; \
    fi;

# change source mirror
RUN set -ex; \
    if [ $SOURCEMIRROR ]; then \
        sed -i "s/\(deb\|security\).debian.org/$SOURCEMIRROR/g" /etc/apt/sources.list; \
    fi;

# update apt && pecl
RUN set -ex; \
    apt-get update && apt upgrade -y; \
    pecl channel-update pecl.php.net;

# change time zone
RUN set -ex; \
    if [ $TIMEZONE ]; then \
        cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone; \
    fi;

# change php ini
RUN set -ex; \
    cp "$PHP_INI_DIR/php.ini-$ENVIRONMENT" "$PHP_INI_DIR/php.ini"

# install tools
RUN set -ex; \
    apt-get install -y \
        supervisor \
        rsyslog \
        cron \
        git;

# install tools(development)
RUN set -ex; \
    if [ "$ENVIRONMENT" = "development" ]; then \
        apt-get install -y \
            iputils-ping \
            net-tools \
            dnsutils \
            telnet \
            procps \
            mycli \
            wget \
            vim \
            jq; \
    fi;

# install extension
RUN set -ex; \
    # install inotify
    pecl install https://pecl.php.net/get/inotify-2.0.0.tgz && docker-php-ext-enable inotify; \
    # install redis
    pecl install redis && docker-php-ext-enable redis; \
    # install gd
    apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
        && docker-php-ext-configure gd --with-freetype --with-jpeg \
        && docker-php-ext-install -j$(nproc) gd; \
    # install zip
    apt-get install -y libzip-dev && docker-php-ext-install zip; \
    # install pcntl
    docker-php-ext-configure pcntl --enable-pcntl && docker-php-ext-install pcntl; \
    # install swoole
    pecl install swoole && docker-php-ext-enable swoole; \
    # install other
    docker-php-ext-install \
        bcmath \
        mysqli \
        opcache \
        pdo_mysql;

# install extension(development)
RUN set -ex; \
    if [ "$ENVIRONMENT" = "development" ]; then \
        # install xdebug
        pecl install xdebug && docker-php-ext-enable xdebug; \
    fi;

# clean extension
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && apt-get autoclean \
    && apt-get clean;

# install composer
RUN set -ex; \
    curl -o /usr/bin/composer https://mirrors.aliyun.com/composer/composer.phar; \
    chmod +x /usr/bin/composer; \
    composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# install crontab
RUN set -ex; \
    touch /var/spool/cron/crontabs/root; \
    chown -R root:crontab /var/spool/cron/crontabs/root; \
    chmod 600 /var/spool/cron/crontabs/root;

WORKDIR /var/www

EXPOSE 9000