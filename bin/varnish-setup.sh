#!/bin/bash

function generate-emsch-vcl {
  local -r VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_METHOD_DEFAULT="HEAD"
  local -r VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_URI_DEFAULT="/index.php?varnish"
  local -r VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_VERSION_DEFAULT="HTTP/1.1"
  local -r VARNISH_VCL_BACKEND_PROBE_REQUEST_HOST_DEFAULT="default.localhost"
  local -r VARNISH_VCL_BACKEND_PROBE_TIMEOUT_DEFAULT="1s"
  local -r VARNISH_VCL_BACKEND_PROBE_INTERVAL_DEFAULT="5s"
  local -r VARNISH_VCL_BACKEND_PROBE_WINDOW_DEFAULT="5"
  local -r VARNISH_VCL_BACKEND_PROBE_THRESHOLD_DEFAULT="3"

  local -r VARNISH_VCL_RECV_REQUEST_X_FORWARDED_PROTO_HEADER_NAME_DEFAULT="X-Forwarded-Proto"

  local -r VARNISH_VCL_BACKEND_RESPONSE_TTL_DEFAULT="10s"
  local -r VARNISH_VCL_BACKEND_RESPONSE_GRACE_DEFAULT="24h"

  local VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_METHOD=${VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_METHOD_CUSTOM:-"${VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_METHOD_DEFAULT}"}
  local VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_URI=${VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_URI_CUSTOM:-"${VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_URI_DEFAULT}"}
  local VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_VERSION=${VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_VERSION_CUSTOM:-"${VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_VERSION_DEFAULT}"}
  local VARNISH_VCL_BACKEND_PROBE_REQUEST_HOST=${VARNISH_VCL_BACKEND_PROBE_REQUEST_HOST_CUSTOM:-"${VARNISH_VCL_BACKEND_PROBE_REQUEST_HOST_DEFAULT}"}
  local VARNISH_VCL_BACKEND_PROBE_TIMEOUT=${VARNISH_VCL_BACKEND_PROBE_TIMEOUT_CUSTOM:-"${VARNISH_VCL_BACKEND_PROBE_TIMEOUT_DEFAULT}"}
  local VARNISH_VCL_BACKEND_PROBE_INTERVAL=${VARNISH_VCL_BACKEND_PROBE_INTERVAL_CUSTOM:-"${VARNISH_VCL_BACKEND_PROBE_INTERVAL_DEFAULT}"}
  local VARNISH_VCL_BACKEND_PROBE_WINDOW=${VARNISH_VCL_BACKEND_PROBE_WINDOW_CUSTOM:-"${VARNISH_VCL_BACKEND_PROBE_WINDOW_DEFAULT}"}
  local VARNISH_VCL_BACKEND_PROBE_THRESHOLD=${VARNISH_VCL_BACKEND_PROBE_THRESHOLD_CUSTOM:-"${VARNISH_VCL_BACKEND_PROBE_THRESHOLD_DEFAULT}"}

  local VARNISH_VCL_RECV_REQUEST_X_FORWARDED_PROTO_HEADER_NAME=${VARNISH_VCL_RECV_REQUEST_X_FORWARDED_PROTO_HEADER_NAME_CUSTOM:-"${VARNISH_VCL_RECV_REQUEST_X_FORWARDED_PROTO_HEADER_NAME_DEFAULT}"}

  local VARNISH_VCL_BACKEND_RESPONSE_TTL=${VARNISH_VCL_BACKEND_RESPONSE_TTL_CUSTOM:-"${VARNISH_VCL_BACKEND_RESPONSE_TTL_DEFAULT}"}
  local VARNISH_VCL_BACKEND_RESPONSE_GRACE=${VARNISH_VCL_BACKEND_RESPONSE_GRACE_CUSTOM:-"${VARNISH_VCL_BACKEND_RESPONSE_GRACE_DEFAULT}"}

  echo "    Configure Varnish VCL ${VARNISH_VCL_CONF} file ..."

  # VCL config Based on:
  # Based on: https://github.com/theus77/my_blog/blob/master/configs/varnish.vcl

  cat > ${VARNISH_VCL_CONF} << EOF
vcl 4.0;

import std;

backend default {
  .host = "127.0.0.1";
  .port = "9000";
  .probe = {
      .request =
        "${VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_METHOD} ${VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_URI} ${VARNISH_VCL_BACKEND_PROBE_REQUEST_HTTP_VERSION}"
        "Host: ${VARNISH_VCL_BACKEND_PROBE_REQUEST_HOST}"
        "Connection: close"
        "User-Agent: Varnish Health Probe";
      .timeout = ${VARNISH_VCL_BACKEND_PROBE_TIMEOUT};
      .interval = ${VARNISH_VCL_BACKEND_PROBE_INTERVAL};
      .window = ${VARNISH_VCL_BACKEND_PROBE_WINDOW};
      .threshold = ${VARNISH_VCL_BACKEND_PROBE_THRESHOLD};
  }
}

sub vcl_recv {

  if (req.http.${VARNISH_VCL_RECV_REQUEST_X_FORWARDED_PROTO_HEADER_NAME} == "https" ) {
    set req.http.X-Forwarded-Port = "443";
  } else {
    set req.http.X-Forwarded-Port = "80";
  }

  //activate the render_esi responses
  set req.http.Surrogate-Capability = "ESI/1.0";

  if (std.healthy(default)) {
    // change the behavior for healthy backends: Cap grace to 10s
    set req.grace = 10s;
  }


  // Remove all cookies except the session ID.
  if (req.http.Cookie) {
    set req.http.Cookie = ";" + req.http.Cookie;
    set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
    set req.http.Cookie = regsuball(req.http.Cookie, ";(PHPSESSID)=", "; \1=");
    set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");

    if (req.http.Cookie == "") {
      // If there are no more cookies, remove the header to get page cached.
      unset req.http.Cookie;
    }
  }
  unset req.http.x-cache;
}

sub vcl_backend_response {
  set beresp.ttl = ${VARNISH_VCL_BACKEND_RESPONSE_TTL};
  set beresp.grace = ${VARNISH_VCL_BACKEND_RESPONSE_GRACE};

  // Check for ESI acknowledgement and remove Surrogate-Control header
  if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
    unset beresp.http.Surrogate-Control;
    set beresp.do_esi = true;
  }
}

sub vcl_hit {
  set req.http.x-cache = "hit";
}

sub vcl_miss {
  set req.http.x-cache = "miss";
}

sub vcl_pass {
  set req.http.x-cache = "pass";
}

sub vcl_pipe {
  set req.http.x-cache = "pipe uncacheable";
}

sub vcl_synth {
  set resp.http.x-cache = "synth synth";
}

sub vcl_deliver {
  if (obj.uncacheable) {
    set req.http.x-cache = req.http.x-cache + " uncacheable" ;
  } else {
    set req.http.x-cache = req.http.x-cache + " cached" ;
  }
  # (un)comment the following line to show the information in the response
  set resp.http.x-cache = req.http.x-cache;

  #For monitoring
  if (std.healthy(default)) {
    set resp.http.x-healthy = "true";
  }
  else {
    set resp.http.x-healthy = "false";
  }
}
EOF

}

if [[ "${VARNISH_ENABLED}" == "true" ]]; then

  if [[ -f ${VARNISH_VCL_CONF} ]]; then
    echo "    Varnish VCL file ${VARNISH_VCL_CONF} exist.  Using this VCL with Varnish ..."
  else
    echo "    Varnish VCL file ${VARNISH_VCL_CONF} not exist.  Generation of the VCL dynamically ..."
    generate-emsch-vcl
  fi
  
fi
