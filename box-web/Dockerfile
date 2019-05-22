FROM docker.io/alpine:3.8

ARG FRONTEND_VERSION_ARG=""
ARG BUILD_DATE_ARG=""
ARG VCS_REF_ARG=""

USER root

ENV FRONTEND_VERSION=${FRONTEND_VERSION_ARG}                                                                                       \
    FRONTEND_DOWNLOAD_URL="https://github.com/ems-project/elasticms/archive"                                                       \
    HOME=/opt

LABEL org.label-schema.build-date=$BUILD_DATE_ARG \
      org.label-schema.name="Website Skeleton - WebServer Docker Image." \
      org.label-schema.description="A preconfigured ElasticMS website." \
      org.label-schema.url="http://www.elasticms.eu" \
      org.label-schema.vcs-ref=$VCS_REF_ARG \
      org.label-schema.vcs-url="https://github.com/ems-project/website-skeleton" \
      org.label-schema.vendor="sebastian.molle@gmail.com" \
      org.label-schema.version=$FRONTEND_VERSION_ARG \
      org.label-schema.schema-version="1.0"

WORKDIR ${HOME}

COPY etc/apache2 /etc/apache2
COPY bin/apk-list /usr/local/bin/apk-list
COPY bin/usage /usr/local/bin/usage
COPY bin/container-entrypoint-web /usr/local/bin/container-entrypoint
COPY bin/dynamic_resources /usr/local/bin/dynamic_resources
COPY bin/func_fill_in_template_file_using_env /usr/local/bin/func_fill_in_template_file_using_env
COPY bin/run-web /usr/local/bin/run-web

RUN apk add --update tzdata bash coreutils apache2 apache2-utils apache2-proxy curl                                             && \
    echo "Setup timezone ..."                                                                                                   && \
    cp /usr/share/zoneinfo/Europe/Brussels /etc/localtime                                                                       && \
    echo "Europe/Brussels" > /etc/timezone                                                                                      && \
    echo "Cleanup Alpine packages ..."                                                                                          && \
    apk del tzdata                                                                                                              && \
    rm -rf /var/cache/apk/*                                                                                                     && \
    echo "Add non-privileged user ..."                                                                                          && \
    adduser -D -u 1001 -g default -s /sbin/nologin default                                                                      && \
    echo "Setup permissions on filesystem for non-privileged user ..."                                                          && \
    mkdir -p /opt/src /run/apache2 /var/run/apache2 /var/log/apache2                                                            && \
    chown -R 1001:0 /run/apache2 /var/run/apache2 /var/log/apache2 /opt/src /etc/apache2                                        && \
    chmod -R a+rwx /run/apache2 /var/run/apache2 /var/log/apache2 /opt/src                                                      && \
    chmod +x /usr/local/bin/apk-list                                                                                               \
             /usr/local/bin/container-entrypoint                                                                                   \
             /usr/local/bin/run-web                                                                                                \
             /usr/local/bin/usage                                                                                               && \
    chown 1001:0 -Rf /etc/apache2                                                                                               && \
    chmod -R ug+rw /etc/apache2                                                                                                 && \
    find /etc/apache2 -type d -exec chmod ug+x {} \;                                                                            && \
    touch /var/log/apache2/error.log                                                                                            && \
    touch /var/log/apache2/access.log                                                                                           && \
    ln -sf /dev/stdout /var/log/apache2/access.log                                                                              && \
    ln -sf /dev/stderr /var/log/apache2/error.log

USER 1001

ENTRYPOINT ["container-entrypoint"]

EXPOSE 8080

CMD ["run-web"]
