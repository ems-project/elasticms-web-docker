#!/bin/bash
function create-metrics-vhost {
  local -r _name=$1
  local -r METRICS_VHOST_SERVER_NAME_DEFAULT=$(hostname -i)

  local METRICS_VHOST_SERVER_NAME=${METRICS_VHOST_SERVER_NAME_CUSTOM:-"${METRICS_VHOST_SERVER_NAME_DEFAULT}"}

  echo "Configure Metrics Apache Virtual Host for [ ${_name} ] ..."

  if [ -f /etc/apache2/conf.d/__metrics.conf ] ; then
    echo "  Metrics Apache Virtual Host already configured ... Skip."
    return 0
  fi

  cat > /etc/apache2/conf.d/__metrics.conf <<EOL
<VirtualHost *:9090>
    ServerName ${METRICS_VHOST_SERVER_NAME}
    ServerAlias *
    LimitRequestLine 16384

    # Uncomment the following line to force Apache to pass the Authorization
    # header to PHP: required for "basic_auth" under PHP-FPM and FastCGI
    #
    # SetEnvIfNoCase ^Authorization$ "(.+)" HTTP_AUTHORIZATION=\$1

    # For Apache 2.4.9 or higher
    # Using SetHandler avoids issues with using ProxyPassMatch in combination
    # with mod_rewrite or mod_autoindex
    <FilesMatch \.php\$>
        SetHandler "proxy:unix:/var/run/php-fpm/php-fpm.sock|fcgi://localhost/"
    </FilesMatch>

    DocumentRoot /opt/src/public
    <Directory /opt/src/public >
        AllowOverride None
        Require all granted
        FallbackResource /index.php
    </Directory>

    <Directory /opt/src/project/public/bundles>
        FallbackResource disabled
    </Directory>

    ErrorLog /dev/stderr
    CustomLog /dev/stdout common
    Header set Cache-Control "${APACHE_CACHE_CONTROL:-"max-age=86400, public"}"
    RewriteEngine On
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

EOL

  echo "Configure Apache Environment Variables ..."
  cat /tmp/${_name} | sed '/^\s*$/d' | grep  -v '^#' | sed "s/\([a-zA-Z0-9_]*\)\=\(.*\)/    SetEnv \1 \2/g" >> /etc/apache2/conf.d/__metrics.conf

  cat >> /etc/apache2/conf.d/__metrics.conf << EOL
</VirtualHost>
EOL

  echo "Apache Metrics Virtual Host for [ ${_name} ] configured successfully ..."

}

# fork a subprocess
function configure (
  local -r _name=$1

  source /tmp/${_name}

  if [ -z ${EMS_METRIC_ENABLED} ] || [ "${EMS_METRIC_ENABLED}" != "true" ]; then
    echo "No Prometheus Metrics is requiered for [ ${_name} ].  Skip ..."
  else
    echo "Configure Apache Prometheus Metrics Vhost for [ ${_name} ] ..."
    create-metrics-vhost "${_name}"
  fi

)

function install {

  if [ ! -z "$AWS_S3_CONFIG_BUCKET_NAME" ]; then
    echo "Found AWS_S3_CONFIG_BUCKET_NAME environment variable.  Reading properties files ..."

    export AWS_S3_CONFIG_BUCKET_NAME=${AWS_S3_CONFIG_BUCKET_NAME#s3://}

    list=(`aws s3 ls ${AWS_S3_CONFIG_BUCKET_NAME%/}/ ${AWS_CLI_EXTRA_ARGS} | awk '{print $4}'`)

    for config in ${list[@]};
    do

      name=${config%.*}

      echo "Install [ $name ] Skeleton Domain from S3 Bucket [ $config ] file ..."

      aws s3 cp s3://${AWS_S3_CONFIG_BUCKET_NAME%/}/$config ${AWS_CLI_EXTRA_ARGS} - | envsubst > /tmp/$name

      configure "${name}"

      echo "Install [ $name ] Skeleton Domain from S3 Bucket [ $config ] file successfully ..."

    done

  elif [ "$(ls -A /opt/secrets)" ]; then

    echo "Found '/opt/secrets' folder with files.  Reading properties files ..."

    for file in /opt/secrets/*; do

      filename=$(basename $file)
      name=${filename%.*}

      echo "Install [ $name ] Skeleton Domain from FS Folder /opt/secrets/ [ $filename ] file ..."

      envsubst < $file > /tmp/$name

      configure "${name}"

      echo "Install [ $name ] Skeleton Domain from FS Folder /opt/secrets/ [ $filename ] file successfully ..."

    done

  elif [ "$(ls -A /opt/configs)" ]; then

    echo "Found '/opt/configs' folder with files.  Reading properties files ..."

    for file in /opt/configs/*; do

      filename=$(basename $file)
      name=${filename%.*}

      echo "Install [ $name ] Skeleton Domain from FS Folder /opt/configs/ [ $filename ] file ..."

      envsubst < $file > /tmp/$name

      configure "${name}"

      echo "Install [ $name ] Skeleton Domain from FS Folder /opt/configs/ [ $filename ] file successfully ..."

    done

  else

    echo "Install [ default ] Skeleton Domain from Environment variables ..."

    env | envsubst > /tmp/default

    configure "default"

    echo "Install [ default ] Skeleton Domain from Environment variables successfully ..."

  fi

}

if [ -z ${METRICS_ENABLED} ] || [ "${METRICS_ENABLED}" != "true" ]; then

  echo "Disable Prometheus Metrics ..."

else

  echo "Configure Prometheus Metrics ..."

  if [ ! -z "$AWS_S3_ENDPOINT_URL" ]; then
    echo "Found AWS_S3_ENDPOINT_URL environment variable.  Add --endpoint-run argument to AWS CLI"
    AWS_CLI_EXTRA_ARGS="--endpoint-url ${AWS_S3_ENDPOINT_URL}"
  fi
  
  install
  
fi

