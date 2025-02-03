LABEL be.fgov.elasticms.web.build-date=$BUILD_DATE_ARG \
      be.fgov.elasticms.web.name="elasticms-web" \
      be.fgov.elasticms.web.description="Website Skeleton of the ElasticMS suite." \
      be.fgov.elasticms.web.url="https://hub.docker.com/repository/docker/elasticms/website-skeleton" \
      be.fgov.elasticms.web.vcs-ref=$VCS_REF_ARG \
      be.fgov.elasticms.web.vcs-url="https://github.com/ems-project/elasticms-web-docker" \
      be.fgov.elasticms.web.vendor="sebastian.molle@gmail.com" \
      be.fgov.elasticms.web.version="$VERSION_ARG" \
      be.fgov.elasticms.web.release="$RELEASE_ARG" \
      be.fgov.elasticms.web.schema-version="1.0"

USER root

COPY --chmod=775 --chown=${PUID:-1001}:0 bin/ /app/bin/
COPY --chmod=664 --chown=${PUID:-1001}:0 config/ /app/config/

COPY --chmod=664 --chown=${PUID:-1001}:0 --from=builder /app/src/elasticms /app/src/elasticms

ENV APP_DISABLE_DOTENV=true \
    EMS_METRIC_PORT="9090" \
    PATH=/app/bin:/app/sbin:/usr/local/bin:/usr/bin:$PATH

RUN find /app -type d -exec chmod ugo+x {} \;

USER ${PUID:-1001}

EXPOSE ${EMS_METRIC_PORT}/tcp

HEALTHCHECK --start-period=5s --interval=1m --timeout=2s --retries=5 \
        CMD curl --fail --header "Host: default.localhost" http://localhost:9000/index.php || exit 1