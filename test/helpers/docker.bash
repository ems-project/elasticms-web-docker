## functions to help deal with docker

# Removes container $1
function docker_clean {
	docker kill $1 &>/dev/null ||:
	sleep .25s
	docker rm -vf $1 &>/dev/null ||:
	sleep .25s
}

# get the ip of docker container $1
function docker_ip {
	docker inspect --format '{{ .NetworkSettings.Networks.docker_default.IPAddress }}' $1
}

# get the id of docker container $1
function docker_id {
	docker inspect --format '{{ .ID }}' $1
}

# get the running state of container $1
# → true/false
# fails if the container does not exist
function docker_running_state {
	docker inspect --format '{{ .State.Running }}' $1
}

# get the health state of container $1
# fails if the container does not exist
function docker_health_state() {
	docker inspect --format '{{ .State.Health.Status }}' $1
}

# get the docker container $1 PID
function docker_pid {
	docker inspect --format {{.State.Pid}} $1
}

# asserts state from container $1 contains healthy
function docker_assert_healthy {
	local -r container=$1
	shift
	docker_health_state $container
	assert_output -l "healthy"
}

# asserts logs from container $1 contains $2
function docker_assert_log {
	local -r container=$1
	shift
	run docker logs $container
	#assert_output -p "$*"
	assert_output -r "$*"
}

# asserts command $2 output from container $1 contains $3
function docker_assert_command {
	local -r container=$1
	local -r command_to_exec=$2
	shift 2
	run docker exec $container $command_to_exec
	#assert_output -p "$*"
	assert_output -r "$*"
}

# wait for a container to produce a given text in its log
# $1 container
# $2 timeout in second
# $* text to wait for
function docker_wait_for_log {
	local -r container=$1
	local -ir timeout_sec=$2
	shift 2
	retry $(( $timeout_sec * 2 )) .5s docker_assert_log $container "$*"
}

# wait for a container healthy state
# $1 container
# $2 timeout in second
function docker_wait_for_healthy {
	local -r container=$1
	local -ir timeout_sec=$2
	shift 2
	retry $(( $timeout_sec * 2 )) .5s docker_assert_healthy $container
}

# Create a docker container named $1 which exposes the docker host unix
# socket over tcp on port 2375.
#
# $1 container name
function docker_tcp {
	local container_name="$1"
	docker_clean $container_name
	docker run -d \
		--label bats-type="socat" \
		--name $container_name \
		--expose 2375 \
		-v /var/run/docker.sock:/var/run/docker.sock \
		rancher/socat-docker
	docker run --label bats-type="docker" --link "$container_name:docker" docker:1.10 version
}
