# website-skeleton-docker ![Continuous Docker Image Build](https://github.com/ems-project/website-skeleton-docker/workflows/Continuous%20Docker%20Image%20Build/badge.svg)

ElasticMS Website Frontend in Docker containers

## Environment Variables

| Variable Name | Description | Default | Example |
| - | - | - | - |
| APACHE_ACCESS_CONTROL_ALLOW_ORIGIN | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) authorization [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin).  | - | `*.example.com` |
| APACHE_ACCESS_CONTROL_ALLOW_METHODS | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) allowed methods [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods). (applied only when ALLOW_ORIGIN is present). | `GET` | `GET` |
| APACHE_ACCESS_CONTROL_ALLOW_HEADERS | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) allowed headers [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/fr/docs/Web/HTTP/Headers/Access-Control-Allow-Headers). (applied only when ALLOW_ORIGIN is present).  | `application/json` | `*` |
| APACHE_CACHE_CONTROL | Define Cache-Control header for static files directly served by Apache (i.e. from bundles and asset archives) [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/fr/docs/Web/HTTP/Headers/Cache-Control).  | `max-age=86400, public` | `immutable, max-age=31536000, public` |