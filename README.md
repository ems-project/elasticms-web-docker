# elasticms-web-docker ![Continuous Docker Image Build](https://github.com/ems-project/elasticms-web-docker/workflows/Continuous%20Docker%20Image%20Build/badge.svg)

ElasticMS Website Frontend in Docker containers

## Prerequisite
Before launching the bats commands you must defined the following environment variables:  

```dotenv  
ELASTICMS_WEBSITE_SKELETON_VERSION=3.9.2 # The Website Skeleton version you want to test  
ELASTICMS_WEBSITE_SKELETON_DOCKER_IMAGE_NAME=docker.io/elasticms/website-skeleton:rc # The ElasticMS Docker image name  
```

You must also install `bats`.  

# Build

```sh
docker build --build-arg VERSION_ARG=${ELASTICMS_WEBSITE_SKELETON_VERSION} \
             --build-arg RELEASE_ARG=snapshot \
             --build-arg BUILD_DATE_ARG=snapshot \
             --build-arg VCS_REF_ARG=snapshot \
             --build-arg GITHUB_TOKEN_ARG=${GITHUB_TOKEN} \
             --target emsch-prod \
             --tag ${ELASTICMS_WEBSITE_SKELETON_DOCKER_IMAGE_NAME} .
```

# Test

```sh
bats test/tests.bats
```

## Environment Variables

| Variable Name | Description | Default | Example |
| - | - | - | - |
| APACHE_ACCESS_CONTROL_ALLOW_ORIGIN | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) authorization [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin).  | - | `*.example.com` |
| APACHE_ACCESS_CONTROL_ALLOW_METHODS | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) allowed methods [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods). (applied only when ALLOW_ORIGIN is present). | `GET` | `GET` |
| APACHE_ACCESS_CONTROL_ALLOW_HEADERS | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) allowed headers [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/fr/docs/Web/HTTP/Headers/Access-Control-Allow-Headers). (applied only when ALLOW_ORIGIN is present).  | `application/json` | `*` |
| APACHE_CACHE_CONTROL | Define Cache-Control header for static files directly served by Apache (i.e. from bundles and asset archives) [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/fr/docs/Web/HTTP/Headers/Cache-Control).  | `max-age=86400, public` | `immutable, max-age=31536000, public` |
| PUID | Define the user identifier  | `1001` | `1000` |
| APACHE_CUSTOM_ASSETS_RC | Rewrite condition that prevent request to be treated by PHP, typically bundles or assets | `^\"+.alias+\"/bundles` | `/bundles/` |
| APACHE_X_FRAME_OPTIONS | The X-Frame-Options HTTP response header can be used to indicate whether or not a browser should be allowed to render a page in a <frame>, <iframe>, <embed> or <object>. | `SAMEORIGIN` | `DENY` |
| APACHE_X_XSS_PROTECTION | The HTTP X-XSS-Protection response header is a feature of Internet Explorer, Chrome and Safari that stops pages from loading when they detect reflected cross-site scripting (XSS) attacks. | `1` | `1; mode=block`, `0` |
| APACHE_X_CONTENT_TYPE_OPTIONS | The X-Content-Type-Options response HTTP header is a marker used by the server to indicate that the MIME types advertised in the Content-Type headers should be followed and not be changed. | `nosniff` |  |
| APACHE_STRICT_TRANSPORT_SECURITY | [HTTP Strict Transport Security](https://scotthelme.co.uk/hsts-the-missing-link-in-tls/) is an excellent feature to support on your site and strengthens your implementation of TLS by getting the User Agent to enforce the use of HTTPS. | N/A | `max-age=31536000; includeSubDomains` |
| APACHE_CONTENT_SECURITY_POLICY | [Content Security Policy](https://scotthelme.co.uk/content-security-policy-an-introduction/) is an effective measure to protect your site from XSS attacks. By whitelisting sources of approved content, you can prevent the browser from loading malicious assets. | N/A | `default-src https:`, `default-src 'self'; script-src 'self' cdnjs.cloudflare.com static.cloudflareinsights.com; img-src 'self'; style-src 'self' 'unsafe-inline' fonts.googleapis.com cdnjs.cloudflare.com; font-src 'self' fonts.gstatic.com cdnjs.cloudflare.com; form-action 'self'; report-uri https://scotthelme.report-uri.com/r/d/csp/enforce; report-to default` |
| APACHE_REFERRER_POLICY | [Referrer Policy](https://scotthelme.co.uk/a-new-security-header-referrer-policy/) is a new header that allows a site to control how much information the browser includes with navigations away from a document and should be set by all sites. | N/A | `no-referrer-when-downgrade`, `Strict-origin-when-cross-origi` |
| APACHE_PERMISSIONS_POLICY | [Permissions Policy](https://scotthelme.co.uk/goodbye-feature-policy-and-hello-permissions-policy/) is a new header that allows a site to control which features and APIs can be used in the browser. | N/A | `accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=(), interest-cohort=()` |

You can test your security headers at [Security Headers](https://securityheaders.com/).

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

## Prometheus Metrics

Return WebSite Skeleton Prometheus metrics.  

### Environment Variables

| Variable Name | Description | Default |
| - | - | - |
| METRICS_ENABLED | Add metrics dedicated vhost running on a specific port (9090). | `empty` |
| METRICS_VHOST_SERVER_NAME_CUSTOM | Apache ServerName directive used for dedicated vhost. | `$(hostname -i)` |