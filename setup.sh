#!/bin/bash

function is_container_available()
{
	echo Checking for Docker Container...
	if docker container inspect code-signing-server > /dev/null 2>&1; then
		echo "--> Container is available"
		return 0
	else
		echo "--> Container is not available"
		return 1
	fi
}

function is_image_available()
{
	echo Checking for Docker Image...
	if docker image inspect code-signing-server:devel > /dev/null 2>&1; then
		echo "--> Image is available"
		return 0
	else
		echo "--> Image is not available"
		return 1
	fi
}

function is_container_running()
{
	echo "Check if container is running"
	if [ "$(docker container inspect -f '{{.State.Running}}' code-signing-server)" = "true" ]; then
		echo "--> Container is running"
		return 0
	else
		echo "--> Container is not running"
		return 1
	fi
}

function build()
{
	echo "Building Container. This can take a while..."
	cd docker > /dev/null 2>&1
	docker build -t code-signing-server:devel . > build.log 2>&1
	if [ $? -ne 0 ]; then
		echo "--> Building failed, please see the log at $(pwd)/build.log"
		exit
	fi
	cd - > /dev/null 2>&1
	echo "--> Container build has been finished"
}

function start_container()
{
	echo "Boot up Container"
	docker container start code-signing-server  > /dev/null 2>&1
	echo "--> Container is booted"
}

function stop_container()
{
	echo "Stop Container"
	docker container stop code-signing-server  > /dev/null 2>&1
	echo "--> Container is stoped"
}

function run()
{
	echo "Create container from Image"
	docker run -d --name code-signing-server -p 2222:22 code-signing-server:devel > /dev/null 2>&1
	#docker run -d --name code-signing-server --hostname signing-server -p 2222:22 code-signing-server:devel > /dev/null 2>&1
	echo "--> Container has been created"

}

function remove_container()
{
	echo "Removing Container"
	docker container rm code-signing-server  > /dev/null 2>&1
	echo "--> Container removed"
}

function remove_image()
{
	echo "Removing Image"
	docker image rm code-signing-server:devel  > /dev/null 2>&1
	echo "Image removed"
}

function start()
{
	if ! is_container_available; then
		if ! is_image_available; then
			fetch_sources
			check_sources
			build
		fi
		run
	fi

	if ! is_container_running; then
		start_container
	fi
}

function stop()
{
	if is_container_available; then
		if is_container_running; then
			stop_container
		fi
	fi
}

function delete()
{
	stop
	if is_container_available; then
		remove_container
	fi

	if is_image_available; then
		remove_image
	fi
}

function usage() 
{
	echo "Usage: ./signing-server-setup-devel.sh <start|stop|delete|usage>"
}

function process_debug()
{
	shift

	#default values
	arg1=arg1
	arg2=arg2
	arg3=arg3

	while [ $# -ne 0 ]; do
		case $1 in
			arg1)
				shift
				arg1=$1
				shift
				;;
			arg2)
				shift
				arg2=$1
				shift
				;;
			arg3)
				shift
				arg3=$1
				shift
				;;
			*)
				echo Unknown option $1... exiting
				exit 1
				;;
		esac
	done
}

function process_start()
{
	shift

	#default values
	cst_dir=
	fs_sb_tool_dir=
	ssh_pub_key_dir=

	while [ $# -ne 0 ]; do
		case $1 in
			cst-dir)
				shift
				cst_dir=$1
				shift
				;;
			fs-sb-tool-dir)
				shift
				fs_sb_tool_dir=$1
				shift
				;;
			ssh-pub-key)
				shift
				ssh_pub_key=$1
				shift
				;;
			*)
				echo Unknown option $1... exiting
				exit 1
				;;
		esac
	done
}

function fetch_sources()
{
	mkdir -p docker/tools
	if [[ $cst_dir != "" ]]; then
		if [[ -d docker/tools/imx-code-signing-tool ]]; then
			rm -rf docker/tools/imx-code-signing-tool
		fi
		cp -r $cst_dir docker/tools/imx-code-signing-tool
	fi
	if [[ $fs_sb_tool_dir != "" ]]; then
		if [[ -d docker/tools/fs-secure-boot-tool ]]; then
			rm -rf docker/tools/fs-secure-boot-tool
		fi
		cp -r $fs_sb_tool_dir docker/tools/fs-secure-boot-tool
	fi
	if [[ $ssh_pub_key != "" ]]; then
		if [[ -f docker/tools/id_ed25519.pub ]]; then
			rm -f docker/tools/id_ed25519.pub
		fi
		cp $ssh_pub_key docker/tools/id_ed25519.pub
	fi
}

function check_sources()
{
if ! [[ -d docker/tools/imx-code-signing-tool ]]; then
	echo Missing imx-code-signing-tool. Exiting...
	exit 1
fi
if ! [[ -d docker/tools/fs-secure-boot-tool ]]; then
	echo Missing fs-secure-boot-tool Exiting...
	exit 1
fi
if ! [[ -f docker/tools/id_ed25519.pub ]]; then
	echo Missing ssh public key. Exiting...
	exit 1
fi
}

case $1 in
	--start)
		process_start $@
		start
		printf "\e[1mImportant Note: This Code Signing Server Example project is only meant for demonstration purposes, not to be used in a production environment.\e[0m\n"
		;;
	--stop)
		stop
		;;
	--delete)
		delete
		;;
	--usage)
		usage
		;;
	--debug)
		process_debug $@
		;;
	*)
		echo "Invalid call $1"
		usage
		;;
esac

exit 0