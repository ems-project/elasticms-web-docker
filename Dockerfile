FROM docker.io/elasticms/base-php-dev:8.1 as builder

ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

ENV ELASTICMS_VERSION=${VERSION_ARG:-3.2.3} \
    ELASTICMS_DOWNLOAD_URL="https://github.com/ems-project/elasticms-web/archive" 

RUN echo "Download and install ElastiCMS ..." \
    && mkdir -p /opt/src \
    && curl -sSfLk ${ELASTICMS_DOWNLOAD_URL}/${ELASTICMS_VERSION}.tar.gz \
       | tar -xzC /opt/src --strip-components=1 \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv install --no-interaction --no-suggest --no-scripts --working-dir /opt/src -o  \
    && rm -rf /opt/src/bootstrap/cache/* /opt/src/.env /opt/src/.env.dist 

FROM docker.io/elasticms/base-apache-fpm:8.1 AS emsch-prod

ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

LABEL eu.elasticms.skeleton.build-date=$BUILD_DATE_ARG \
      eu.elasticms.skeleton.name="ElasticMS - Website Skeleton." \
      eu.elasticms.skeleton.description="A minimal CMS to manage generic content in order to publish it in several Elasticsearch index." \
      eu.elasticms.skeleton.url="https://www.elasticms.eu/" \
      eu.elasticms.skeleton.vcs-ref=$VCS_REF_ARG \
      eu.elasticms.skeleton.vcs-url="https://github.com/ems-project/elasticms-web" \
      eu.elasticms.skeleton.vendor="sebastian.molle@gmail.com" \
      eu.elasticms.skeleton.version="$VERSION_ARG" \
      eu.elasticms.skeleton.release="$RELEASE_ARG" \
      eu.elasticms.skeleton.schema-version="1.0" \
      eu.elasticms.skeleton.docker-image="all-in-one"

USER root

COPY bin/ /opt/bin/container-entrypoint.d/
COPY etc/ /usr/local/etc/
COPY --from=builder /opt/src /opt/src

ENV APP_DISABLE_DOTENV=true
ENV EMS_METRIC_PORT="9090"

RUN echo -e "\nListen ${EMS_METRIC_PORT}\n" >> /etc/apache2/httpd.conf \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chmod -Rf +x /opt/bin \ 
    && chown -Rf ${PUID:-1001}:0 /opt \
    && chmod -R ug+rw /opt \
    && find /opt -type d -exec chmod ug+x {} \; 

USER ${PUID:-1001}

EXPOSE ${EMS_METRIC_PORT}/tcp

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1

FROM docker.io/elasticms/base-apache-dev:7.4 AS emsch-dev

ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

LABEL eu.elasticms.skeleton.build-date=$BUILD_DATE_ARG \
      eu.elasticms.skeleton.name="ElasticMS - Website Skeleton. (DEV)" \
      eu.elasticms.skeleton.description="A minimal CMS to manage generic content in order to publish it in several Elasticsearch index." \
      eu.elasticms.skeleton.url="https://www.elasticms.eu/" \
      eu.elasticms.skeleton.vcs-ref=$VCS_REF_ARG \
      eu.elasticms.skeleton.vcs-url="https://github.com/ems-project/elasticms-web" \
      eu.elasticms.skeleton.vendor="sebastian.molle@gmail.com" \
      eu.elasticms.skeleton.version="$VERSION_ARG" \
      eu.elasticms.skeleton.release="$RELEASE_ARG" \
      eu.elasticms.skeleton.schema-version="1.0" \
      eu.elasticms.skeleton.docker-image="all-in-one-dev"

USER root

COPY bin/ /opt/bin/container-entrypoint.d/
COPY etc/ /usr/local/etc/
COPY --from=builder /opt/src /opt/src

ENV APP_DISABLE_DOTENV=true
ENV EMS_METRIC_PORT="9090"

RUN echo -e "\nListen ${EMS_METRIC_PORT}\n" >> /etc/apache2/httpd.conf \
    && echo "Setup permissions on filesystem for non-privileged user ..." \
    && chmod -Rf +x /opt/bin \ 
    && chown -Rf 1001:0 /opt \
    && chmod -R ug+rw /opt \
    && find /opt -type d -exec chmod ug+x {} \; 

USER 1001

EXPOSE ${EMS_METRIC_PORT}/tcp

HEALTHCHECK --start-period=10s --interval=1m --timeout=5s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1
