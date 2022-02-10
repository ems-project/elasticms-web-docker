#!/usr/bin/env bats
load "helpers/tests"
load "helpers/docker"
load "helpers/dataloaders"

load "lib/batslib"
load "lib/output"

export BATS_ELASTICMS_WEBSITE_SKELETON_VERSION=${ELASTICMS_WEBSITE_SKELETON_VERSION:-3.8.3}
export BATS_RELEASE_NUMBER=${RELEASE_NUMBER:-snapshot}
export BATS_BUILD_DATE=${BUILD_DATE:-snapshot}
export BATS_VCS_REF=${VCS_REF:-snapshot}
export BATS_GITHUB_TOKEN_ARG=${GITHUB_TOKEN:-0}

export BATS_STORAGE_SERVICE_NAME="postgresql"

export BATS_ELASTICMS_WEBSITE_SKELETON_DOCKER_IMAGE_NAME="${ELASTICMS_WEBSITE_SKELETON_DOCKER_IMAGE_NAME:-docker.io/elasticms/website-skeleton:rc}"

command docker-compose -f docker-compose-fs.yml build --compress --pull skeleton >&2

@test "[$TEST_FILE] Check Website Skeleton (WebTech) Docker images build" {
  run docker inspect --type=image ${BATS_ELASTICMS_WEBSITE_SKELETON_DOCKER_IMAGE_NAME}
  [ "$status" -eq 0 ]
}
