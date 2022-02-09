# website-skeleton-docker ![Continuous Docker Image Build](https://github.com/ems-project/website-skeleton-docker/workflows/Continuous%20Docker%20Image%20Build/badge.svg)

ElasticMS Website Frontend in Docker containers

## Environment Variables

| Variable Name | Description | Default | Example |
| - | - | - | - |
| APACHE_ACCESS_CONTROL_ALLOW_ORIGIN | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) authorization [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin).  | - | `*.example.com` |
| APACHE_ACCESS_CONTROL_ALLOW_METHODS | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) allowed methods [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods). (applied only when ALLOW_ORIGIN is present). | `GET` | `GET` |
| APACHE_ACCESS_CONTROL_ALLOW_HEADERS | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) allowed headers [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/fr/docs/Web/HTTP/Headers/Access-Control-Allow-Headers). (applied only when ALLOW_ORIGIN is present).  | `application/json` | `*` |
| APACHE_CACHE_CONTROL | Define Cache-Control header for static files directly served by Apache (i.e. from bundles and asset archives) [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/fr/docs/Web/HTTP/Headers/Cache-Control).  | `max-age=86400, public` | `immutable, max-age=31536000, public` |
| PUID | Define the user identifier  | `1001` | `1000` |
| APACHE_CUSTOM_ASSETS_RC | Rewrite condition that prevent request to be treated by PHP, typically bundles or assets | `^\"+.alias+\"/bundles` | `/bundles/` |

## Varnish

TODO

### Environment Variables

VCL Specific env vars.

| Variable Name | Description | Default |
| - | - | - |
| VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_METHOD_CUSTOM | [doc](https://varnish-cache.org/docs/trunk/reference/vcl-probe.html#attribute-request) | `HEAD` | 
| VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_URI_CUSTOM | [doc](https://varnish-cache.org/docs/trunk/reference/vcl-probe.html#attribute-request) | `/index.php?varnish` | 
| VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_VERSION_CUSTOM |[doc](https://varnish-cache.org/docs/trunk/reference/vcl-probe.html#attribute-request)  | `HTTP/1.1` | 
| VARNISH_VCL_BACKEND_PROBE_REQUEST_HOST_CUSTOM | [doc](https://varnish-cache.org/docs/trunk/reference/vcl-probe.html#attribute-request) | `default.localhost` | 
| VARNISH_VCL_BACKEND_PROBE_TIMEOUT_CUSTOM | [doc](https://varnish-cache.org/docs/trunk/reference/vcl-probe.html#attribute-timeout) | `1s` | 
| VARNISH_VCL_BACKEND_PROBE_INTERVAL_CUSTOM | [doc](https://varnish-cache.org/docs/trunk/reference/vcl-probe.html#attribute-interval) | `5s` | 
| VARNISH_VCL_BACKEND_PROBE_WINDOW_CUSTOM | [doc](https://varnish-cache.org/docs/trunk/reference/vcl-probe.html#the-backend-health-shift-register) | `5` | 
| VARNISH_VCL_BACKEND_PROBE_THRESHOLD_CUSTOM | [doc](https://varnish-cache.org/docs/trunk/reference/vcl-probe.html#the-backend-health-shift-register) | `3` | 
| VARNISH_VCL_RECV_REQUEST_X_FORWARDED_PROTO_HEADER_NAME_CUSTOM | [doc](https://varnish-cache.org/docs/trunk/users-guide/vcl-built-in-subs.html?highlight=recv#vcl-recv) | `X-Forwarded-Proto` | 
| VARNISH_VCL_BACKEND_RESPONSE_TTL_CUSTOM | [doc](https://varnish-cache.org/docs/trunk/users-guide/vcl-example-manipulating-responses.html?highlight=response#altering-the-backend-response) | `10s` | 
| VARNISH_VCL_BACKEND_RESPONSE_GRACE_CUSTOM | [doc](https://varnish-cache.org/docs/trunk/users-guide/vcl-example-manipulating-responses.html?highlight=response#altering-the-backend-response) | `24h` | 