# elasticms-web-docker [![Docker Build](https://github.com/ems-project/elasticms-web-docker/actions/workflows/docker-build.yml/badge.svg?branch=5.x)](https://github.com/ems-project/elasticms-web-docker/actions/workflows/docker-build.yml) 

ElasticMS Website Skeleton in Docker containers

# Build

To automate the build and testing of this image, we rely on a Makefile that facilitates the construction and testing of a container image for ElasticMS Website Skeleton.  The Makefile supports both Docker and Podman with Buildah as options for building and testing the image.  Additionally, the Dockerfile used for image creation is templated using m4.  

## Prerequisites

To use this Makefile, you need to have the following installed on your system:

- [Docker](https://docs.docker.com/get-docker/) or [Podman](https://podman.io/getting-started/installation) with [Buildah](https://buildah.io/install) (for building and managing containers)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) (for version control)
- [Make](https://www.gnu.org/software/make/) (for running the Makefile commands)
- [M4](https://www.gnu.org/software/m4/) (for generating the Dockerfile from templates)

Make sure to follow the links provided to install the required tools according to your operating system and platform.

## Getting Started

1. Clone the repository containing the Makefile and navigate to its directory:

   ```bash
   git clone <repository_url>
   cd <repository_directory>
   ```

2. (Optional) If you want to customize the build process, create a `.build.env` file in the repository directory. This file can define the following environment variables:

   - `ELASTICMS_WEB_VERSION`: The version of ElasticMS Website Skeleton to build (default: 5.0.0)
   - `DOCKER_IMAGE_NAME`: The name of the Docker image to build (default: docker.io/elasticms/website-skeleton)

   Make sure to define these variables in the `.build.env` file using the `KEY=VALUE` format.

## Usage

To use the Makefile, you can run the following commands:

- `make build`: Build the Docker image for the production (`prd`) variant of ElasticMS Website Skeleton.
- `make build-dev`: Build the Docker image for the development (`dev`) variant of ElasticMS Website Skeleton.
- `make build-all`: Build Docker images for both the production and development variants of ElasticMS Website Skeleton.
- `make test`: Test the Docker image for the production (`prd`) variant of ElasticMS Website Skeleton.
- `make test-dev`: Test the Docker image for the development (`dev`) variant of ElasticMS Website Skeleton.
- `make test-all`: Test Docker images for both the production and development variants of ElasticMS Website Skeleton.
- `make Dockerfile`: Generate the Dockerfile from the provided templates.

You can also run `make help` to see a list of available commands.

**Note:** By default, the Makefile uses Docker as the container engine. If you want to use Podman with Buildah instead, you have two options:

1. Set the `CONTAINER_ENGINE` variable in the `.build.env` file. Create a `.build.env` file in the repository directory and define `CONTAINER_ENGINE=podman` in the file.
2. Set the `CONTAINER_ENGINE` environment variable directly when running the Makefile commands:

   ```bash
   make build CONTAINER_ENGINE=podman
   ```

Using an environment variable allows you to dynamically switch between Docker and Podman with Buildah without modifying the `.build.env` file.

Additionally, if you are using Podman as the container engine, you can specify the `CONTAINER_TARGET_IMAGE_FORMAT` environment variable to choose the image format. By default, the image format is Docker. To create the image in the OCI format, use the following command:

   ```bash
   make build CONTAINER_ENGINE=podman CONTAINER_TARGET_IMAGE_FORMAT=oci
   ```

To customize the Docker image name and ElasticMS Website Skeleton version, you have two options:

1. Set the `DOCKER_IMAGE_NAME` and `ELASTICMS_WEB_VERSION` variables in the `.build.env` file. Create a `.build.env` file in the repository directory and define the desired values for these variables.
2. Set the `DOCKER_IMAGE_NAME` and `ELASTICMS_WEB_VERSION` environment variables directly when running the Makefile commands:

   ```bash
   make build DOCKER_IMAGE_NAME=my-custom-image ELASTICMS_WEB_VERSION=6.0.0
   ```

Setting these variables allows you to customize the image name and ElasticMS Website Skeleton version without modifying the `.build.env` file.

Please ensure that you have the necessary dependencies installed as mentioned earlier in the documentation.

## Customizing the Build

If you want to customize the build process further, you can modify the `.build.env` file to set the desired values for the environment variables mentioned earlier. Additionally, you can modify the Dockerfile templates located in the `Dockerfiles` directory. The Makefile uses `m4` to generate the final Dockerfile from the templates.

To regenerate the Dockerfile after modifying the templates, run the following command:

```bash
make Dockerfile
```

## Testing

The Makefile uses Bats (Bash Automated Testing System) to test the Docker images. The test cases are defined in the `test/tests.bats` file. Before running the tests, make sure you have the following dependencies installed:

- Bats: Bats is a TAP-compliant testing framework for Bash. Install Bats by following the instructions in the [Bats documentation](https://github.com/bats-core/bats-core#installation).  
- AWS CLI: The AWS CLI is required to execute certain tests. Install the AWS CLI by following the instructions in the [AWS CLI user guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).  
- npm: npm is the package manager for JavaScript. Install npm by following the instructions in the [npm documentation](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm).  
- gettext: gettext is a package that provides internationalization (i18n) support. Install gettext by following the instructions for your specific operating system.  
- Docker: If you're using Docker as the container engine, you need to have Docker installed. Follow the instructions in the [Docker documentation](https://docs.docker.com/get-docker/) to install Docker.  
- Docker Compose: Docker Compose is required for certain tests that use Docker Compose functionality. Install Docker Compose by following the instructions in the [Docker Compose documentation](https://docs.docker.com/compose/install/).  
- Podman (with Podman Compose): If you're using Podman as the container engine, you need to have Podman and Podman Compose installed. Install Podman by following the instructions in the [Podman documentation](https://podman.io/getting-started/installation). Install Podman Compose by following the instructions in the [Podman Compose documentation](https://github.com/containers/podman-compose#installation).  

To run the tests, make sure to configure the desired container engine (Docker or Podman) using the CONTAINER_ENGINE environment variable. The Makefile will execute the tests accordingly.

To run the tests, use the following commands:

- `make test`: Test the Docker image for the production (`prd`) variant of ElasticMS Website Skeleton using the configured container engine.
- `make test-dev`: Test the Docker image for the development (`dev`) variant of ElasticMS Website Skeleton using the configured container engine.
- `make test-all`: Test Docker images for both the production and development variants of ElasticMS Website Skeleton using the configured container engine.

You can also specify the `DOCKER_IMAGE_NAME` and `ELASTICMS_WEB_VERSION` variables to customize the image name and version used for testing. For example:

```shell
make test DOCKER_IMAGE_NAME=my-custom-image ELASTICMS_WEB_VERSION=6.0.0 CONTAINER_ENGINE=podman
```

The Bats test suite includes multiple test cases that validate the functionality and behavior of the ElasticMS Website Skeleton container image. It covers various aspects of the image, including its configuration, dependencies, and expected output. The test suite ensures the integrity and correctness of the container image.  

# Releases

Releases are done via GitHub actions and uploaded on Docker Hub.

# Supported tags and respective Dockerfile links

- [`5.x.y`, `5.x`, `5`, `5.x.y-prd`, `5.x-prd`, `5-prd`, `5.x.y-dev`, `5.x-dev`, `5-dev`](Dockerfiles/Dockerfile.in)

# Image Variants

The elasticms/admin images come in many flavors, each designed for a specific use case.

## `docker.io/elasticms/website-skeleton:<version>[-prd]`  

This variant contains the [ElasticMS Web](https://github.com/ems-project/elasticms-web) installed in a Production PHP environment.  

## `docker.io/elasticms/website-skeleton:<version>-dev`

This variant contains the [ElasticMS Web](https://github.com/ems-project/elasticms-web) installed in a Development PHP environment.  

# Configuration

## Environment variables

| Variable Name | Description | Default | Example |
| - | - | - | - |
| APACHE_ACCESS_CONTROL_ALLOW_ORIGIN | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) authorization [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin).  | - | `*.example.com` |
| APACHE_ACCESS_CONTROL_ALLOW_METHODS | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) allowed methods [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Methods). (applied only when ALLOW_ORIGIN is present). | `GET` | `GET` |
| APACHE_ACCESS_CONTROL_ALLOW_HEADERS | Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)(Cross-Origin Resource Sharing) allowed headers [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/fr/docs/Web/HTTP/Headers/Access-Control-Allow-Headers). (applied only when ALLOW_ORIGIN is present).  | `application/json` | `*` |
| APACHE_CACHE_CONTROL | Define Cache-Control header for static files directly served by Apache (i.e. from bundles and asset archives) [Apache](https://httpd.apache.org/docs/2.4/en/mod/mod_headers.html) [Header](https://developer.mozilla.org/fr/docs/Web/HTTP/Headers/Cache-Control).  | `max-age=86400, public` | `immutable, max-age=31536000, public` |
| PUID | Define the user identifier  | `1001` | `1000` |
| APACHE_CUSTOM_ASSETS_RC | Rewrite condition that prevent request to be treated by PHP, typically bundles or assets | `^\"+.alias+\"/bundles` | `/bundles/` |
| APACHE_X_FRAME_OPTIONS | The X-Frame-Options HTTP response header can be used to indicate whether or not a browser should be allowed to render a page in a `<frame>`, `<iframe>`, `<embed>` or `<object>`. | `SAMEORIGIN` | `DENY` |
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