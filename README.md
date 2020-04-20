# website-skeleton-docker [![Build Status](https://travis-ci.com/ems-project/website-skeleton-docker.svg?branch=master)](https://travis-ci.com/ems-project/website-skeleton-docker)

ElasticMS Website Frontend in Docker containers

## Environment Variables

| Variable Name | Description | Default | Example |
| - | - | - | - |
| APACHE_ACCESS_CONTROL_ALLOW_ORIGIN | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) authorization [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin).  | - | `*.example.com` |
| APACHE_ACCESS_CONTROL_ALLOW_METHODS | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) allowed methods [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods). (applied only when ALLOW_ORIGIN is present). | `GET` | `GET` |
| APACHE_ACCESS_CONTROL_ALLOW_HEADERS | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) allowed headers [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/fr/docs/Web/HTTP/Headers/Access-Control-Allow-Headers). (applied only when ALLOW_ORIGIN is present).  | `application/json` | `*` |