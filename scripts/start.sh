#!/bin/bash

# Register $_ENV global in PHP and pass environment variable who match with pattern
echo '' > /etc/nginx/env_params 
if [ ! -z "$ENV_PASS_PATTERN" ]; then
  for k in $(env | cut -d'=' -f1 | grep -v ^_$ | grep $ENV_PASS_PATTERN)
  do 
    v=$(eval "echo \$$k")
    v=${v/\'/\\\'}
    echo "fastcgi_param $k  '$v';" >> /etc/nginx/env_params
  done
  sed -i -e "s/variables_order =.*/variables_order = \"EGPCS\"/g" /etc/php5/fpm/php.ini
fi

exec /usr/bin/supervisord -n -c /etc/supervisord.conf