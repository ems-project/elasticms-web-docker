#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export BATS_ROOT_DB_USER="${BATS_ROOT_DB_USER:-root}"
export BATS_ROOT_DB_PASSWORD="${BATS_ROOT_DB_PASSWORD:-password}"
export BATS_ROOT_DB_NAME="${BATS_ROOT_DB_PASSWORD:-root}"

export BATS_DB_DRIVER="${BATS_DB_DRIVER:-pgsql}"
export BATS_DB_HOST="${BATS_DB_HOST:-postgresql}"
export BATS_DB_PORT="${BATS_DB_PORT:-5432}"
export BATS_DB_USER="${BATS_DB_USER:-example_adm}"
export BATS_DB_PASSWORD="${BATS_DB_PASSWORD:-example}"
export BATS_DB_NAME="${BATS_DB_NAME:-example}"

export BATS_S3_EMS_CONFIG_BUCKET_NAME="s3bucket-ems-config/example/config/elasticms"
export BATS_S3_EMSCH_CONFIG_BUCKET_NAME="s3bucket-ems-config/example/config/skeleton"
export BATS_S3_STORAGE_BUCKET_NAME="s3bucket-example-ems-storage"
export BATS_S3_ENDPOINT_URL="http://localhost:4572"
export BATS_S3_ACCESS_KEY_ID="mock"
export BATS_S3_SECRET_ACCESS_KEY="mock"
export BATS_S3_DEFAULT_REGION="us-east-1"

export BATS_PHP_FPM_MAX_CHILDREN="${BATS_PHP_FPM_MAX_CHILDREN:-4}"
export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES="${BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-128}"
export BATS_CONTAINER_HEAP_PERCENT="${BATS_CONTAINER_HEAP_PERCENT:-0.80}"

export BATS_STORAGE_SERVICE_NAME="postgresql"

export BATS_ELASTICMS_WEBSITE_SKELETON_DOCKER_IMAGE_NAME="${ELASTICMS_WEBSITE_SKELETON_DOCKER_IMAGE_NAME:-docker.io/elasticms/website-skeleton:rc}"

export AWS_ACCESS_KEY_ID="${BATS_S3_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${BATS_S3_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${BATS_S3_DEFAULT_REGION}"

export BATS_HTPASSWD_USERNAME="bats"
export BATS_HTPASSWD_PASSWORD="bats"

@test "[$TEST_FILE] Starting Elasticms Storage Services (S3, PostgreSQL, Elasticsearch)" {
  command docker-compose -f docker-compose-s3.yml up -d s3 postgresql elasticsearch_1 elasticsearch_2 
  docker_wait_for_log postgresql 240 "LOG:  autovacuum launcher started"
  docker_wait_for_log elasticsearch_1 240 "\[INFO \]\[o.e.n.Node.*\] \[.*\] started"
  docker_wait_for_log elasticsearch_2 240 "\[INFO \]\[o.e.n.Node.*\] \[.*\] started"
  docker_wait_for_log s3 240 "Ready."
}

@test "[$TEST_FILE] Loading Config files in Configuration S3 Bucket (EMS)" {
  run aws s3 mb s3://${BATS_S3_EMS_CONFIG_BUCKET_NAME%/} --endpoint-url ${BATS_S3_ENDPOINT_URL}
  assert_output -l -r "make_bucket: ${BATS_S3_EMS_CONFIG_BUCKET_NAME%%/*}"

  run aws s3api put-bucket-acl --bucket s3://${BATS_S3_EMS_CONFIG_BUCKET_NAME%/} --acl public-read --endpoint-url ${BATS_S3_ENDPOINT_URL}

  for file in ${BATS_TEST_DIRNAME%/}/config/s3/elasticms/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    run init_ems_config_s3bucket $file ${BATS_S3_EMS_CONFIG_BUCKET_NAME%/}/ $BATS_S3_ENDPOINT_URL 
    assert_output -l -r 'S3 EMS CONFIG COPY OK'

  done
}

@test "[$TEST_FILE] Loading Test Data files in Elasticms Storage services (S3 / DB)" {
  run aws s3 mb s3://${BATS_S3_STORAGE_BUCKET_NAME%/} --endpoint-url ${BATS_S3_ENDPOINT_URL}
  assert_output -l -r "make_bucket: $BATS_S3_STORAGE_BUCKET_NAME"

  run aws s3api put-bucket-acl --bucket s3://${BATS_S3_STORAGE_BUCKET_NAME%/} --acl public-read --endpoint-url ${BATS_S3_ENDPOINT_URL}

  for file in ${BATS_TEST_DIRNAME%/}/config/s3/elasticms/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    envsubst < $file > /tmp/$_name
    source /tmp/$_name

    run load_database $BATS_STORAGE_SERVICE_NAME $file ${BATS_DB_DRIVER} $BATS_ROOT_DB_USER $BATS_ROOT_DB_PASSWORD $BATS_ROOT_DB_NAME $BATS_DB_PORT $BATS_DB_HOST $BATS_DB_USER $BATS_DB_PASSWORD $BATS_DB_NAME
    assert_output -l -r "${BATS_DB_DRIVER} OK"

    run init_ems_data_s3bucket $file $BATS_S3_STORAGE_BUCKET_NAME $BATS_S3_ENDPOINT_URL 
    assert_output -l -r 'S3 EMS DATA COPY OK'

    rm /tmp/$_name

  done
}

@test "[$TEST_FILE] Starting Elasticms services (webserver, php-fpm) configured for AWS S3" {
  export BATS_ES_LOCAL_ENDPOINT_URL=http://$(docker_ip elasticsearch_1):9200
  export BATS_S3_ENDPOINT_URL=http://$(docker_ip s3):4572
  export BATS_TIKA_LOCAL_ENDPOINT_URL=http://$(docker_ip tika):9998

  command docker-compose -f docker-compose-s3.yml up -d elasticms
}

@test "[$TEST_FILE] Check for Elasticms startup messages in containers logs (S3)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/s3/elasticms/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}
    docker_wait_for_log ems 15 "Install \[ ${_name} \] CMS Domain from S3 Bucket \[ ${_basename} \] file successfully ..."
    docker_wait_for_log ems 15 "Doctrine database migration for \[ ${_name} \] CMS Domain run successfully ..."
    docker_wait_for_log ems 15 "Elasticms assets installation for \[ ${_name} \] CMS Domain run successfully ..."
    docker_wait_for_log ems 15 "Elasticms warming up for \[ ${_name} \] CMS Domain run successfully ..."
  done

  docker_wait_for_log ems 15 "NOTICE: ready to handle connections"
  docker_wait_for_log ems 15 "AH00292: Apache/.* \(Unix\) OpenSSL/.* configured -- resuming normal operations"
}

@test "[$TEST_FILE] Create Elasticms Super Admin user in running container for all configured domains (S3)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/s3/elasticms/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    envsubst < $file > /tmp/$_name
    source /tmp/$_name

    run docker exec ems sh -c "/opt/bin/$_name fos:user:create --super-admin ${_name}-bats ${_name}.admin.s3.bats@example.com bats"
    assert_output -l 0 "Created user ${_name}-bats"

    rm /tmp/$_name

  done
}

@test "[$TEST_FILE] Rebuild Elasticms Environments for all configured domains (S3)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/s3/elasticms/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    environments=(`docker exec ems sh -c "/opt/bin/$_name ems:environment:list"`)

    for environment in ${environments[@]}; do

      run docker exec ems sh -c "/opt/bin/$_name ems:environment:rebuild $environment --yellow-ok"
      #
      # Comment as long as we don't want to continue to made tests based on content loaded from a db dump.
      #      
      # assert_output -l -r "The alias ${environment} is now pointing to"

    done

  done
}

@test "[$TEST_FILE] Check for Elasticms Default Index page response code 200" {
  retry 12 5 curl_container ems :9000/index.php -H 'Host: default.localhost' -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Elasticms status page response code 200 for all configured domains (S3)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/s3/elasticms/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    envsubst < $file > /tmp/$_name
    source /tmp/$_name

    retry 12 5 curl_container ems :9000/status/ -H "'Host: ${SERVER_NAME}'" -s -w %{http_code} -o /dev/null
    assert_output -l 0 $'401'

    retry 12 5 curl_container ems :9000/cluster/ -H "'Host: ${SERVER_NAME}'" -s -w %{http_code} -o /dev/null
    assert_output -l 0 $'200'

    retry 12 5 curl_container ems :9000/health_check.json -H "'Host: ${SERVER_NAME}'" -s -w %{http_code} -o /dev/null
    assert_output -l 0 $'200'

    rm /tmp/$_name

  done
}

@test "[$TEST_FILE] Loading Config files in Configuration S3 Bucket (EMSCH)" {
  run aws s3 mb s3://${BATS_S3_EMSCH_CONFIG_BUCKET_NAME%/} --endpoint-url ${BATS_S3_ENDPOINT_URL}
  assert_output -l -r "make_bucket: ${BATS_S3_EMSCH_CONFIG_BUCKET_NAME%%/*}"

  run aws s3api put-bucket-acl --bucket s3://${BATS_S3_EMSCH_CONFIG_BUCKET_NAME%/} --acl public-read --endpoint-url ${BATS_S3_ENDPOINT_URL}

  for file in ${BATS_TEST_DIRNAME%/}/config/s3/skeleton/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    run init_ems_config_s3bucket $file ${BATS_S3_EMSCH_CONFIG_BUCKET_NAME%/}/ $BATS_S3_ENDPOINT_URL 
    assert_output -l -r 'S3 EMS CONFIG COPY OK'

  done
}

@test "[$TEST_FILE] Starting Website Skeleton (webserver, php-fpm) configured with AWS S3" {
  export BATS_ES_LOCAL_ENDPOINT_URL=http://$(docker_ip elasticsearch_1):9200
  export BATS_S3_ENDPOINT_URL=http://$(docker_ip s3):4572
  export BATS_EMS_LOCAL_ENDPOINT_URL=http://$(docker_ip ems):9000
  export BATS_APACHE_ACCESS_CONTROL_ALLOW_ORIGIN="*"

  command docker-compose -f docker-compose-s3.yml up -d skeleton
}

@test "[$TEST_FILE] Check for Website Skeleton Default Index page response code 200" {
  retry 12 5 curl_container emsch :9000/index.php -H 'Host: default.localhost' -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Website Skeleton startup messages in containers logs (S3)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/s3/skeleton/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}
    docker_wait_for_log emsch 15 "Install \[ ${_name} \] Skeleton Domain from S3 Bucket \[ ${_basename} \] file successfully ..."
    docker_wait_for_log emsch 15 "Access-Control-Allow-Origin ${BATS_APACHE_ACCESS_CONTROL_ALLOW_ORIGIN}"
    docker_wait_for_log emsch 15 "Elasticms assets installation for \[ ${_name} \] Skeleton Domain run successfully ..."
    docker_wait_for_log emsch 15 "Elasticms warming up for \[ ${_name} \] Skeleton Domain run successfully ..."
  done

  docker_wait_for_log emsch 15 "NOTICE: ready to handle connections"
  docker_wait_for_log emsch 15 "AH00292: Apache/.* \(Unix\) OpenSSL/.* configured -- resuming normal operations"
}

@test "[$TEST_FILE] Check for Website Skeleton response code 200 for all configured domains (S3)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/s3/skeleton/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    envsubst < $file > /tmp/$_name
    source /tmp/$_name

    #
    # Comment as long as we don't want to continue to made tests based on content loaded from a db dump.
    #
    # retry 12 5 curl_container emsch :9000/ -u ${BATS_HTPASSWD_USERNAME}:${BATS_HTPASSWD_PASSWORD} -H "'Host: ${SERVER_NAME}'" -L -s -w %{http_code} -o /dev/null
    # assert_output -l 0 $'200'

    rm /tmp/$_name

  done
}

@test "[$TEST_FILE] Stop all and delete test containers" {
  command docker-compose -f docker-compose-s3.yml stop
  command docker-compose -f docker-compose-s3.yml rm -v -f  
}

