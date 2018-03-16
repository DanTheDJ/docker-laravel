FROM alpine

LABEL maintainer="Dan Coleman <dan@dancoleman.uk>"

#Variables
ENV php_conf /etc/php7/php-fpm.conf
ENV fpm_conf /etc/php7/php-fpm.d/www.conf
ENV php_vars /etc/php7/conf.d/docker-vars.ini

#Update, Upgrade
RUN apk update

#Install Main Dependencies
RUN apk add bash supervisor nginx php7 php7-fpm php7-opcache curl git nodejs libpng-dev autoconf automake build-base

#Install PHP Packages

RUN apk add php7-gd php7-mysqli php7-curl php7-json php7-mbstring php7-phar php7-zlib php7-pdo php7-simplexml php7-tokenizer php7-xml php7-xmlwriter php7-session

#Add supervisor config
RUN rm -Rf conf/supervisor.conf
ADD conf/supervisord.conf /etc/supervisord.conf

#Add nginx global config
RUN rm -Rf /etc/nginx/nginx.conf
ADD conf/nginx.conf /etc/nginx/nginx.conf

#Add custom php config
RUN rm -Rf /etc/php7/php.ini
ADD conf/php.ini /etc/php7/php.ini

#Install composer for PHP packages
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Add site config
RUN mkdir -p /etc/nginx/sites-available/ && \
mkdir -p /etc/nginx/sites-enabled/ && \
rm -Rf /var/www/* && \
mkdir /var/www/html/
ADD conf/nginx-site.conf /etc/nginx/sites-available/default.conf
RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

#Update PHP-FPM config
RUN echo "cgi.fix_pathinfo=0" > ${php_vars} &&\
    echo "upload_max_filesize = 100M"  >> ${php_vars} &&\
    echo "post_max_size = 100M"  >> ${php_vars} &&\
    echo "variables_order = \"EGPCS\""  >> ${php_vars} && \
    echo "memory_limit = 128M"  >> ${php_vars} && \
    sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/user = www-data/user = nginx/g" \
        -e "s/group = www-data/group = nginx/g" \
        -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
        -e "s/;listen.owner = www-data/listen.owner = nginx/g" \
        -e "s/;listen.group = www-data/listen.group = nginx/g" \
        -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        ${fpm_conf}

#Add startup script and make Executable
COPY scripts/start.sh /start.sh
RUN chmod +x /start.sh

#Expose ports
EXPOSE 443 80

# Startup
CMD ["/start.sh"]