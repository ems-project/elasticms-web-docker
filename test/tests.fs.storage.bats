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

export BATS_EMS_CONFIG_VOLUME_NAME=${BATS_EMS_CONFIG_VOLUME_NAME:-ems_configmap}
export BATS_EMS_STORAGE_VOLUME_NAME=${BATS_EMS_STORAGE_VOLUME_NAME:-ems_storage}
export BATS_EMSCH_CONFIG_VOLUME_NAME=${BATS_EMSCH_CONFIG_VOLUME_NAME:-skeleton_config}
export BATS_PHP_FPM_MAX_CHILDREN="${BATS_PHP_FPM_MAX_CHILDREN:-4}"
export BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES="${BATS_PHP_FPM_REQUEST_MAX_MEMORY_IN_MEGABYTES:-128}"
export BATS_CONTAINER_HEAP_PERCENT="${BATS_CONTAINER_HEAP_PERCENT:-0.80}"

export BATS_STORAGE_SERVICE_NAME="postgresql"

export BATS_ELASTICMS_WEBSITE_SKELETON_DOCKER_IMAGE_NAME="${ELASTICMS_WEBSITE_SKELETON_DOCKER_IMAGE_NAME:-docker.io/elasticms/website-skeleton:rc}"

export BATS_HTPASSWD_USERNAME="bats"
export BATS_HTPASSWD_PASSWORD="bats"

@test "[$TEST_FILE] Create Docker external volumes (local)" {
  command docker volume create -d local ${BATS_EMSCH_CONFIG_VOLUME_NAME}
  command docker volume create -d local ${BATS_EMS_STORAGE_VOLUME_NAME}
  command docker volume create -d local ${BATS_EMS_CONFIG_VOLUME_NAME}
}

@test "[$TEST_FILE] Configure EMS Storage Volume (/var/lib/ems)" {
  run configure_ems_storage_volume $BATS_EMS_STORAGE_VOLUME_NAME
  assert_output -l -r 'CONFIGURATION OK'
}
 
@test "[$TEST_FILE] Starting Elasticms Storage Services (PostgreSQL, Elasticsearch)" {
  command docker-compose -f docker-compose-fs.yml up -d postgresql elasticsearch_1 elasticsearch_2
  docker_wait_for_log postgresql 120 "LOG:  autovacuum launcher started"
  docker_wait_for_log elasticsearch_1 120 "\[INFO \]\[o.e.n.Node.*\] \[.*\] started"
  docker_wait_for_log elasticsearch_2 120 "\[INFO \]\[o.e.n.Node.*\] \[.*\] started"
}

@test "[$TEST_FILE] Starting Tika Service" {
  command docker-compose -f docker-compose-fs.yml up -d tika
  docker_wait_for_log tika 120 ".*Started Apache Tika server.*"
}

@test "[$TEST_FILE] Loading Config files in Elasticms Configuration FS Docker Volume" {

  for file in ${BATS_TEST_DIRNAME%/}/config/fs/elasticms/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    run init_ems_config_volume $BATS_EMS_CONFIG_VOLUME_NAME $file
    assert_output -l -r 'FS-VOLUME EMS CONFIG COPY OK'

  done
}
 
@test "[$TEST_FILE] Loading Test Data files in Elasticms Storage services (Volume / DB)" {

  for file in ${BATS_TEST_DIRNAME%/}/config/fs/elasticms/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    envsubst < $file > /tmp/$_name
    source /tmp/$_name

    run load_database $BATS_STORAGE_SERVICE_NAME $file ${BATS_DB_DRIVER} $BATS_ROOT_DB_USER $BATS_ROOT_DB_PASSWORD $BATS_ROOT_DB_NAME $BATS_DB_PORT $BATS_DB_HOST $BATS_DB_USER $BATS_DB_PASSWORD $BATS_DB_NAME
    assert_output -l -r "${BATS_DB_DRIVER} OK"

    run init_ems_data_volume $BATS_EMS_STORAGE_VOLUME_NAME $file
    assert_output -l -r 'FS-VOLUME EMS DATA COPY OK'

    rm /tmp/$_name

  done
}
 
@test "[$TEST_FILE] Starting Elasticms service configured for Volume mount" {
  export BATS_ES_LOCAL_ENDPOINT_URL=http://$(docker_ip elasticsearch_1):9200
  export BATS_TIKA_LOCAL_ENDPOINT_URL=http://$(docker_ip tika):9998

  command docker-compose -f docker-compose-fs.yml up -d elasticms
}

@test "[$TEST_FILE] Check for Elasticms Default Index page response code 200" {
  retry 12 5 curl_container ems :9000/index.php -H 'Host: default.localhost' -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Elasticms startup messages in containers logs (Volume)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/fs/elasticms/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}
     docker_wait_for_log ems 15 "Install \[ ${_name} \] CMS Domain from FS Folder /opt/configs/ \[ ${_basename} \] file successfully ..."
     docker_wait_for_log ems 15 "Doctrine database migration for \[ ${_name} \] CMS Domain run successfully ..."
     docker_wait_for_log ems 15 "Elasticms assets installation for \[ ${_name} \] CMS Domain run successfully ..."
     docker_wait_for_log ems 15 "Elasticms warming up for \[ ${_name} \] CMS Domain run successfully ..."
  done

  docker_wait_for_log ems 15 "NOTICE: ready to handle connections"
  docker_wait_for_log ems 15 "AH00292: Apache/.* \(Unix\) OpenSSL/.* configured -- resuming normal operations"
}
 
@test "[$TEST_FILE] Create Elasticms Super Admin user in running container for all configured domains (Volume)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/fs/elasticms/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    envsubst < $file > /tmp/$_name
    source /tmp/$_name

    run docker exec ems sh -c "/opt/bin/$_name fos:user:create --super-admin ${_name}-bats ${_name}.admin@example.com bats"
    assert_output -l 0 "Created user ${_name}-bats"

    rm /tmp/$_name

  done
}
 
@test "[$TEST_FILE] Rebuild Elasticms Environments for all configured domains (Volume)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/fs/elasticms/*.properties ; do
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
 
@test "[$TEST_FILE] Check for Elasticms status page response code 200 for all configured domains (Volume)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/fs/elasticms/*.properties ; do
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
 
@test "[$TEST_FILE] Loading Config files in Elasticms Skeleton Configuration FS Docker Volume" {

  for file in ${BATS_TEST_DIRNAME%/}/config/fs/skeleton/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}

    run init_ems_config_volume $BATS_EMSCH_CONFIG_VOLUME_NAME $file
    assert_output -l -r 'FS-VOLUME EMS CONFIG COPY OK'

  done
}

@test "[$TEST_FILE] Starting Website Skeleton (webserver, php-fpm)" {
  export BATS_ES_LOCAL_ENDPOINT_URL=http://$(docker_ip elasticsearch_1):9200
  export BATS_APACHE_ACCESS_CONTROL_ALLOW_ORIGIN="*"

  command docker-compose -f docker-compose-fs.yml up -d skeleton
}

@test "[$TEST_FILE] Check for Website Skeleton Default Index page response code 200" {
  retry 12 5 curl_container emsch :9000/index.php -H 'Host: default.localhost' -s -w %{http_code} -o /dev/null
  assert_output -l 0 $'200'
}

@test "[$TEST_FILE] Check for Website Skeleton startup messages in containers logs (Volume)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/fs/skeleton/*.properties ; do
    _basename=$(basename $file)
    _name=${_basename%.*}
    docker_wait_for_log emsch 15 "Install \[ ${_name} \] Skeleton Domain from FS Folder /opt/configs/ \[ ${_basename} \] file successfully ..."
    docker_wait_for_log emsch 15 "Access-Control-Allow-Origin ${BATS_APACHE_ACCESS_CONTROL_ALLOW_ORIGIN}"
    docker_wait_for_log emsch 15 "Elasticms assets installation for \[ ${_name} \] Skeleton Domain run successfully ..."
    docker_wait_for_log emsch 15 "Elasticms warming up for \[ ${_name} \] Skeleton Domain run successfully ..."
  done

  docker_wait_for_log emsch 15 "NOTICE: ready to handle connections"
  docker_wait_for_log emsch 15 "AH00292: Apache/.* \(Unix\) OpenSSL/.* configured -- resuming normal operations"
}

@test "[$TEST_FILE] Check for Website Skeleton response code 200 for all configured domains (Volume)" {
  for file in ${BATS_TEST_DIRNAME%/}/config/fs/skeleton/*.properties ; do
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
  command docker-compose -f docker-compose-fs.yml stop
  command docker-compose -f docker-compose-fs.yml rm -v -f  
}

@test "[$TEST_FILE] Cleanup Docker external volumes (local)" {
  command docker volume rm ${BATS_EMS_STORAGE_VOLUME_NAME}
  command docker volume rm ${BATS_EMS_CONFIG_VOLUME_NAME}
  command docker volume rm ${BATS_EMSCH_CONFIG_VOLUME_NAME}
}