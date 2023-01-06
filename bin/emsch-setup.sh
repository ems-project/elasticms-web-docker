#!/bin/bash

function create-wrapper-script {
  local -r _instance_name=$1

  mkdir -p /opt/bin

  cat >/opt/bin/$_instance_name <<EOL
#!/bin/bash
# This script is autogenerated by the container startup script
set -o allexport
source /tmp/$_instance_name
set +o allexport

php /opt/src/bin/console \$@

EOL

  chmod a+x /opt/bin/$_instance_name

}

function setup-multi-alias {

  if ! [ -z ${APACHE_ENVIRONMENTS+x} ]; then
    echo "Multiple environment aliases are defined: ${APACHE_ENVIRONMENTS}" | jq -c '.[]'
    echo "caution do not add an alias that exists somewhere in a ems route (i.e. admin)"

    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
      $(echo ${APACHE_ENVIRONMENTS} | jq -r 'map("Alias "+.alias+"/bundles/emsch_assets /opt/src/public/bundles/"+.env) | join("\n")')
      $(echo ${APACHE_ENVIRONMENTS} | jq -r 'map("Alias "+.alias+" /opt/src/public") | join("\n")')
      $(echo ${APACHE_ENVIRONMENTS} | jq -r 'map(["RewriteEngine on", "RewriteCond %{REQUEST_URI} !^"+.alias+"/index.php", "RewriteCond %{REQUEST_URI} !'${APACHE_CUSTOM_ASSETS_RC:-^\"+.alias+\"/bundles}'", "RewriteCond %{REQUEST_URI} !^"+.alias+"/favicon.ico$", "RewriteCond %{REQUEST_URI} !^"+.alias+"/apple-touch-icon.png$", "RewriteCond %{REQUEST_URI} !^"+.alias+"/robots.txt$", "RewriteRule ^"+.alias+" "+.alias+"/index.php$1 [PT]"])' | jq -r '.[] | join("\n")')
EOL

  fi

}

function setup-only-one-alias {

  if ! [ -z ${ENVIRONMENT_ALIAS+x} ]; then
    echo "Configure Apache Alias (/bundles/emsch_assets) [ ${ENVIRONMENT_ALIAS} ] ..."
    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    Alias /bundles/emsch_assets /opt/src/public/bundles/$ENVIRONMENT_ALIAS
EOL
  fi

  if ! [ -z ${ALIAS+x} ]; then
    echo "Configure Apache Alias (/opt/src/public) [ ${ALIAS} ] ..."
    echo "Caution do not add an alias that exists somewhere in a ems route (i.e. admin)"
    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    Alias $ALIAS /opt/src/public
    Alias $ALIAS/bundles/emsch_assets /opt/src/public/bundles/${ENVIRONMENT_ALIAS:-emsch_assets}

    RewriteCond %{REQUEST_URI} !^$ALIAS/index.php
    RewriteCond %{REQUEST_URI} !^$ALIAS/bundles
    RewriteCond %{REQUEST_URI} !^$ALIAS/favicon.ico\$
    RewriteCond %{REQUEST_URI} !^$ALIAS/apple-touch-icon.png\$
    RewriteCond %{REQUEST_URI} !^$ALIAS/robots.txt\$
    RewriteRule "^$ALIAS" "$ALIAS/index.php\$1" [PT]

EOL
  fi

}
function create-apache-vhost {
  local -r _name=$1

  echo "Configure Apache Virtual Host for [ $_name ] Skeleton Domains [ ${SERVER_NAME} ] ..."

  if [ -f /etc/apache2/conf.d/${_name}-app.conf ] ; then
    rm /etc/apache2/conf.d/${_name}-app.conf
  fi

  cat > /etc/apache2/conf.d/${_name}-app.conf <<EOL
<VirtualHost *:9000>
    ServerName $SERVER_NAME
EOL

  if ! [ -z ${SERVER_ALIASES+x} ]; then
    echo "Configure Apache ServerAlias [ ${SERVER_ALIASES} ] ..."
    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    ServerAlias $SERVER_ALIASES
EOL
  fi

  cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
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

    Header setifempty Cache-Control "${APACHE_CACHE_CONTROL:-"max-age=86400, public"}"
    Header setifempty X-Frame-Options "${APACHE_X_FRAME_OPTIONS:-"SAMEORIGIN"}"
    Header setifempty X-XSS-Protection "${APACHE_X_XSS_PROTECTION:-"1"}"
    Header setifempty X-Content-Type-Options "${APACHE_X_CONTENT_TYPE_OPTIONS:-"nosniff"}"
EOL

  if ! [ -z ${APACHE_STRICT_TRANSPORT_SECURITY+x} ]; then
  cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    Header setifempty Strict-Transport-Security "${APACHE_STRICT_TRANSPORT_SECURITY}"
EOL
  fi;

  if ! [ -z ${APACHE_CONTENT_SECURITY_POLICY+x} ]; then
  cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    Header setifempty Content-Security-Policy "${APACHE_CONTENT_SECURITY_POLICY}"
EOL
  fi;

  if ! [ -z ${APACHE_REFERRER_POLICY+x} ]; then
  cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    Header setifempty Referrer-Policy "${APACHE_REFERRER_POLICY}"
EOL
  fi;

  if ! [ -z ${APACHE_PERMISSIONS_POLICY+x} ]; then
  cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    Header setifempty Permissions-Policy "${APACHE_PERMISSIONS_POLICY}"
EOL
  fi;

  cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    RewriteEngine On
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

EOL

  # APACHE_ACCESS_CONTROL_ALLOW_ORIGIN is not unset AND APACHE_ACCESS_CONTROL_ALLOW_ORIGIN.length > 0
  if [ ! -z ${APACHE_ACCESS_CONTROL_ALLOW_ORIGIN+x} ] && [ -n "${APACHE_ACCESS_CONTROL_ALLOW_ORIGIN}" ]; then
    export APACHE_ACCESS_CONTROL_ALLOW_METHODS=${APACHE_ACCESS_CONTROL_ALLOW_METHODS:-"GET"}
    export APACHE_ACCESS_CONTROL_ALLOW_HEADERS=${APACHE_ACCESS_CONTROL_ALLOW_HEADERS:-"application/json"}

    echo "Configure Apache CORS Headers ..."
    echo "  -> Access-Control-Allow-Origin ${APACHE_ACCESS_CONTROL_ALLOW_ORIGIN}"
    echo "  -> Access-Control-Allow-Methods ${APACHE_ACCESS_CONTROL_ALLOW_METHODS}"
    echo "  -> Access-Control-Allow-Headers ${APACHE_ACCESS_CONTROL_ALLOW_HEADERS}"

    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    Header set Access-Control-Allow-Origin "${APACHE_ACCESS_CONTROL_ALLOW_ORIGIN}"
    Header set Access-Control-Allow-Methods "${APACHE_ACCESS_CONTROL_ALLOW_METHODS}"
    Header set Access-Control-Allow-Headers "${APACHE_ACCESS_CONTROL_ALLOW_HEADERS}"

EOL
  fi

  if [ -z ${APACHE_ENVIRONMENTS+x} ]; then
    #APACHE_ENVIRONMENTS is not set, apply old code for backward compatibility
    setup-only-one-alias
  else
    setup-multi-alias
  fi

  if ! [ -z ${PROTECTED_URL+x} ]; then
    echo "Configure Apache Location (PROTECTED_URL) [ ${PROTECTED_URL} ] ..."
    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    <Location "$PROTECTED_URL">
        AuthType Basic
        AuthName "protected area"
        # (La ligne suivante est facultative)
        AuthBasicProvider file
        AuthUserFile /opt/src/.htpasswd
        Require valid-user
    </Location>

EOL

    if ! [ -w /opt/src/.htpasswd ]; then
      HTPASSWD_USERNAME=${HTPASSWD_USERNAME:-default}
      HTPASSWD_PASSWORD=${HTPASSWD_PASSWORD:-password}
      htpasswd -bc /opt/src/.htpasswd ${HTPASSWD_USERNAME} ${HTPASSWD_PASSWORD}
      if [ $? -ne 0 ]; then
        echo "Something was wrong when we create .htpasswd file !"
      fi
    else
      echo "htpasswd file already exist.  We use it to protect '${PROTECTED_URL}'"
    fi
  fi

  echo "Configure Apache Environment Variables ..."
  cat /tmp/$_name | sed '/^\s*$/d' | grep  -v '^#' | sed "s/\([a-zA-Z0-9_]*\)\=\(.*\)/    SetEnv \1 \2/g" >> /etc/apache2/conf.d/${_name}-app.conf

  if ! [ -z ${BASE_URL+x} ]; then
    echo "Configure Apache Proxy Load Balancer for Elasticsearch Cluster [ ${EMSCH_ELASTICSEARCH_CLUSTER} ] ..."
    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL

    ProxyRequests On

    <Proxy balancer://myset>
EOL
    echo $EMSCH_ELASTICSEARCH_CLUSTER | sed "s/,/\n/g" | sed "s/[\s\[\"]*\([^\"]*\)\".*/      BalancerMember \1/"  >> /etc/apache2/conf.d/${_name}-app.conf
    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
      #ProxySet lbmethod=byrequests
    </Proxy>

EOL

    echo $ELASTICSEARCH_CLUSTER | sed "s/,/\n/g" | sed "s/[\s\[\"]*\([^\"]*\)\".*/\1/" | grep ".*https.*" && echo "        SSLProxyEngine On" >> /etc/apache2/conf.d/${_name}-app.conf

    echo "Configure Apache Location for [ ${BASE_URL} ] ..."
    cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
    <Location $BASE_URL/>
        ProxyPass "balancer://myset/"
        ProxyPassReverse "balancer://myset/"
        AllowMethods GET
    </Location>

EOL
  fi;

  cat >> /etc/apache2/conf.d/${_name}-app.conf << EOL
</VirtualHost>
EOL

  echo "Apache Virtual Host for [ $_name ] Skeleton Domains [ ${SERVER_NAME} ] configured successfully ..."

}

# fork a subprocess
function configure (
  local -r _name=$1

  source /tmp/${_name}

  create-apache-vhost "${_name}"
  create-wrapper-script "${_name}"

  echo "Running Elasticms assets installation to /opt/src/public folder for [ $_name ] Skeleton Domain ..."
  /opt/bin/$_name asset:install /opt/src/public --symlink --no-interaction
  if [ $? -eq 0 ]; then
    echo "Elasticms assets installation for [ $_name ] Skeleton Domain run successfully ..."
  else
    echo "Warning: something doesn't work with Elasticms assets installation !"
  fi

  echo "Running Elasticms cache warming up for [ $_name ] Skeleton Domain ..."
  /opt/bin/$_name cache:warm --no-interaction
  if [ $? -eq 0 ]; then
    echo "Elasticms warming up for [ $_name ] Skeleton Domain run successfully ..."
  else
    echo "Warning: something doesn't work with Elasticms cache warming up !"
  fi

  #if [ ! -z "${ENVIRONMENT_ALIAS}" ]; then
  #  echo "Found ENVIRONMENT_ALIAS environment variable."
  #  echo "Made simlink /opt/src/public/bundles/${ENVIRONMENT_ALIAS} to /opt/src/public/bundles/emsch_assets ..."
  #  ln -s /opt/src/public/bundles/${ENVIRONMENT_ALIAS} /opt/src/public/bundles/emsch_assets
  #fi

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

if [ ! -z "$AWS_S3_ENDPOINT_URL" ]; then
  echo "Found AWS_S3_ENDPOINT_URL environment variable.  Add --endpoint-run argument to AWS CLI"
  AWS_CLI_EXTRA_ARGS="--endpoint-url ${AWS_S3_ENDPOINT_URL}"
fi

install
