FROM docker.io/elasticms/base-php:8.1-apache-dev as builder

ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

ENV ELASTICMS_VERSION=${VERSION_ARG:-5.0.1} \
    ELASTICMS_DOWNLOAD_URL="https://github.com/ems-project/elasticms-web/archive" 

RUN echo "Download and install ElastiCMS ..." \
    && mkdir -p /opt/src \
    && curl -sSfLk ${ELASTICMS_DOWNLOAD_URL}/${ELASTICMS_VERSION}.tar.gz \
       | tar -xzC /opt/src --strip-components=1 \
    && COMPOSER_MEMORY_LIMIT=-1 composer -vvvv install --no-interaction --no-suggest --no-scripts --working-dir /opt/src -o  \
    && rm -rf /opt/src/bootstrap/cache/* /opt/src/.env /opt/src/.env.dist 

FROM docker.io/elasticms/base-php:8.1-apache as prd

ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

LABEL be.fgov.elasticms.web.build-date=$BUILD_DATE_ARG \
      be.fgov.elasticms.web.name="elasticms-web" \
      be.fgov.elasticms.web.description="Website Skeleton of the ElasticMS suite." \
      be.fgov.elasticms.web.url="https://hub.docker.com/repository/docker/elasticms/website-skeleton" \
      be.fgov.elasticms.web.vcs-ref=$VCS_REF_ARG \
      be.fgov.elasticms.web.vcs-url="https://github.com/ems-project/elasticms-web-docker" \
      be.fgov.elasticms.web.vendor="sebastian.molle@gmail.com" \
      be.fgov.elasticms.web.version="$VERSION_ARG" \
      be.fgov.elasticms.web.release="$RELEASE_ARG" \
      be.fgov.elasticms.web.environment="prd" \
      be.fgov.elasticms.web.schema-version="1.0"

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

FROM docker.io/elasticms/base-php:8.1-apache-dev as dev

ARG VERSION_ARG=""
ARG RELEASE_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

LABEL be.fgov.elasticms.web.build-date=$BUILD_DATE_ARG \
      be.fgov.elasticms.web.name="elasticms-web" \
      be.fgov.elasticms.web.description="Website Skeleton of the ElasticMS suite." \
      be.fgov.elasticms.web.url="https://hub.docker.com/repository/docker/elasticms/website-skeleton" \
      be.fgov.elasticms.web.vcs-ref=$VCS_REF_ARG \
      be.fgov.elasticms.web.vcs-url="https://github.com/ems-project/elasticms-web-docker" \
      be.fgov.elasticms.web.vendor="sebastian.molle@gmail.com" \
      be.fgov.elasticms.web.version="$VERSION_ARG" \
      be.fgov.elasticms.web.release="$RELEASE_ARG" \
      be.fgov.elasticms.web.environment="dev" \
      be.fgov.elasticms.web.schema-version="1.0"

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
