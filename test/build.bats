#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export WEBSITE_SKELETON_VERSION=${WEBSITE_SKELETON_VERSION:-3.1.1}
export RELEASE_NUMBER=${RELEASE_NUMBER:-snapshot}
export BUILD_DATE=${BUILD_DATE:-snapshot}
export VCS_REF=${VCS_REF:-snapshot}

export BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME=${BATS_CLAIR_LOCAL_SCANNER_CONFIG_VOLUME_NAME:-clair_local_scanner}
export BATS_PHP_SCRIPTS_VOLUME_NAME=${BATS_PHP_SCRIPTS_VOLUME_NAME:-php_scripts}

export BATS_STORAGE_SERVICE_NAME="postgresql"

export BATS_EMSCH_DOCKER_IMAGE_NAME="${EMSCH_DOCKER_IMAGE_NAME:-docker.io/elasticms/skeleton}:rc"

@test "[$TEST_FILE] Starting Website Skeleton Docker images build" {
  command docker-compose -f docker-compose-fs.yml build --no-cache --pull skeleton
}
