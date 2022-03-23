#!/bin/bash

# If a command fails, make the whole script exit
set -e
# Use return code for any command errors in part of a pipe
set -o pipefail # Bashism

DIST="parrot"
VERSION="1.0"
VARIANT="default"
IMAGE_TYPE="live"
TARGET_DIR="$(dirname $0)/images"
TARGET_SUBDIR=""
SUDO="sudo"
VERBOSE=""
DEBUG=""
HOST_ARCH=$(dpkg --print-architecture)

image_name() {
	case "$IMAGE_TYPE" in
		live)
			live_image_name
		;;
	esac
}

live_image_name() {
	case "$ARCH" in
		i386|amd64|arm64)
			echo "live-image-$ARCH.hybrid.iso"
		;;
		armel|armhf)
			echo "live-image-$ARCH.img"
		;;
	esac
}

installer_image_name() {
	echo "architect/images/PlagueSecurity-$VERSION-$ARCH-DVD-1.iso"
}

target_image_name() {
	local arch=$1

	IMAGE_NAME="$(image_name $arch)"
	IMAGE_EXT="${IMAGE_NAME##*.}"
	if [ "$IMAGE_EXT" = "$IMAGE_NAME" ]; then
		IMAGE_EXT="img"
	fi
	if [ "$IMAGE_TYPE" = "live" ]; then
		if [ "$VARIANT" = "default" ]; then
			echo "${TARGET_SUBDIR:+$TARGET_SUBDIR/}PlagueSecurity-${VERSION}_$ARCH.$IMAGE_EXT"
		else
			echo "${TARGET_SUBDIR:+$TARGET_SUBDIR/}PlagueSecurity-$VARIANT-${VERSION}_$ARCH.$IMAGE_EXT"
		fi
	else
		if [ "$VARIANT" = "default" ]; then
			echo "${TARGET_SUBDIR:+$TARGET_SUBDIR/}PlagueSecurity-architect-DVD-${VERSION}_$ARCH.$IMAGE_EXT"
		else
			echo "${TARGET_SUBDIR:+$TARGET_SUBDIR/}PlagueSecurity-architect-$VARIANT-${VERSION}_$ARCH.$IMAGE_EXT"
		fi
	fi
}

target_build_log() {
	TARGET_IMAGE_NAME=$(target_image_name $1)
	echo ${TARGET_IMAGE_NAME%.*}.log
}

default_version() {
	case "$1" in
		parrot-*)
			echo "${1#parrot-}"
		;;
		*)
			echo "$1"
		;;
	esac
}

failure() {
	echo "Build of $DIST/$VARIANT/$ARCH $IMAGE_TYPE image failed (see build.log for details)" >&2
	echo "Log: $BUILD_LOG" >&2
    less "$BUILD_LOG" >&2
	exit 2
}

log() {
	if [ -n "$VERBOSE" ] || [ -n "$DEBUG" ]; then
		echo "RUNNING: $@" >&2
		"$@" 2>&1 | tee -a "$BUILD_LOG"
	else
		"$@" >>"$BUILD_LOG" 2>&1
	fi
	return $?
}

debug() {
	if [ -n "$DEBUG" ]; then
		echo "DEBUG: $*" >&2
	fi
}

clean() {
	debug "Cleaning"

	# Live
	log $SUDO lb clean --purge

	# Architect
	log $SUDO rm -rf "$(pwd)/architect/tmp"
	log $SUDO rm -rf "$(pwd)/architect/debian-cd"
}

print_help() {
	echo "Usage: $0 [<option>...]"
	echo
	for x in $(echo "${BUILD_OPTS_LONG}" | sed 's_,_ _g'); do
		x=$(echo $x | sed 's/:$/ <arg>/')
		echo "  --${x}"
	done
	exit 0
}

# Allowed command line options
. $(dirname $0)/.getopt.sh
BUILD_LOG="$(pwd)/build.log"
debug "BUILD_LOG: $BUILD_LOG"
# Create empty file
: > "$BUILD_LOG"

# Parsing command line options (see .getopt.sh)
temp=$(getopt -o "$BUILD_OPTS_SHORT" -l "$BUILD_OPTS_LONG,get-image-path" -- "$@")
eval set -- "$temp"
while true; do
	case "$1" in
		-d|--distribution) DIST="$2"; shift 2; ;;
		-p|--proposed-updates) OPT_pu="1"; shift 1; ;;
		-a|--arch) ARCH="$2"; shift 2; ;;
		-v|--verbose) VERBOSE="1"; shift 1; ;;
		-D|--debug) DEBUG="1"; shift 1; ;;
		-s|--salt) shift; ;;
		-h|--help) print_help; ;;
		--installer) IMAGE_TYPE="installer"; shift 1 ;;
		--live) IMAGE_TYPE="live"; shift 1 ;;
		--rootfs) IMAGE_TYPE="rootfs"; shift 1 ;;
		--iot) IMAGE_TYPE="iot"; shift 1 ;;
		--variant) VARIANT="$2"; shift 2; ;;
		--version) VERSION="$2"; shift 2; ;;
		--subdir) TARGET_SUBDIR="$2"; shift 2; ;;
		--get-image-path) ACTION="get-image-path"; shift 1; ;;
		--clean) ACTION="clean"; shift 1; ;;
		--no-clean) NO_CLEAN="1"; shift 1 ;;
		--) shift; break; ;;
		*) echo "ERROR: Invalid command-line option: $1" >&2; exit 1; ;;
	esac
done

# Set default values
ARCH=${ARCH:-$HOST_ARCH}
if [ "$ARCH" = "x64" ]; then
	ARCH="amd64"
elif [ "$ARCH" = "x86" ]; then
	ARCH="i386"
fi
debug "ARCHITECTURE: $ARCH"

if [ -z "$VERSION" ]; then
	VERSION="$(default_version $DIST)"
fi
debug "VERSION: $VERSION"

# Check parameters
debug "HOST_ARCH: $HOST_ARCH"
if [ "$HOST_ARCH" != "$ARCH" ] && [ "$IMAGE_TYPE" != "installer" ]; then
	case "$HOST_ARCH/$ARCH" in
		amd64/i386|i386/amd64)
		;;
		*)
			echo "Can't build $ARCH image on $HOST_ARCH system." >&2
		;;
	esac
fi

# Build parameters for lb config
CONFIG_OPTS="--distribution $DIST -- --variant $VARIANT"
CODENAME=$DIST # for architect/debian-cd
if [ -n "$OPT_pu" ]; then
	CONFIG_OPTS="$CONFIG_OPTS --proposed-updates"
	DIST="$DIST+pu"
fi
debug "CONFIG_OPTS: $CONFIG_OPTS"
debug "CODENAME: $CODENAME"
debug "DISTRIBUTION: $DIST"

# Set sane PATH (cron seems to lack /sbin/ dirs)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
debug "PATH: $PATH"

# Check if the Builder is based on Debian OS 
if grep -q -e "^ID=debian" -e "^ID_LIKE=debian" /usr/lib/os-release; then
	debug "OS: $( . /usr/lib/os-release && echo $NAME $VERSION )"
elif [ -e /etc/debian_version ]; then
	debug "OS: $( cat /etc/debian_version )"
else
	echo "ERROR: Non Debian-based OS" >&2
fi

debug "IMAGE_TYPE: $IMAGE_TYPE"
case "$IMAGE_TYPE" in
	live)
		if [ ! -d "$(dirname $0)/templates/variant-$VARIANT" ]; then
			echo "ERROR: Unknown variant of PlagueSecurity live configuration: $VARIANT" >&2
		fi

		ver_live_build=$(dpkg-query -f '${Version}' -W live-build)
		if dpkg --compare-versions "$ver_live_build" lt 1:20151215; then
			echo "ERROR: You need live-build (>= 1:20151215), you have $ver_live_build" >&2
			exit 1
		fi
		debug "ver_live_build: $ver_live_build"

		ver_debootstrap=$(dpkg-query -f '${Version}' -W debootstrap)
		if dpkg --compare-versions "$ver_debootstrap" lt "1.0.97"; then
			echo "ERROR: You need debootstrap (>= 1.0.97), you have $ver_debootstrap" >&2
			exit 1
		fi
		debug "ver_debootstrap: $ver_debootstrap"
	;;
	installer)
		if [ ! -d "$(dirname $0)/templates/installer-$VARIANT" ]; then
			echo "ERROR: Unknown variant of PlagueSecurity installer configuration: $VARIANT" >&2
		fi

		ver_debian_cd=$(dpkg-query -f '${Version}' -W debian-cd)
		if dpkg --compare-versions "$ver_debian_cd" lt 3.1.28; then
			echo "ERROR: You need debian-cd (>= 3.1.28), you have $ver_debian_cd" >&2
			exit 1
		fi
		debug "ver_debian_cd: $ver_debian_cd"

		ver_simple_cdd=$(dpkg-query -f '${Version}' -W simple-cdd)
		if dpkg --compare-versions "$ver_simple_cdd" lt 0.6.8; then
			echo "ERROR: You need simple-cdd (>= 0.6.8), you have $ver_simple_cdd" >&2
			exit 1
		fi
		debug "ver_simple_cdd: $ver_simple_cdd"
	;;
	*)
		echo "ERROR: Unsupported IMAGE_TYPE selected ($IMAGE_TYPE)" >&2
		exit 1
	;;
esac

# Set ROOT
if [ "$(whoami)" != "root" ]; then
	if ! which $SUDO >/dev/null; then
		echo "ERROR: $0 is not run as root and $SUDO is not available" >&2
		exit 1
	fi
else
	SUDO="" # We're already root
fi
debug "SUDO: $SUDO"

IMAGE_NAME="$(image_name $ARCH)"
debug "IMAGE_NAME: $IMAGE_NAME"

debug "ACTION: $ACTION"
if [ "$ACTION" = "get-image-path" ]; then
	echo $(target_image_name $ARCH)
	exit 0
fi

if [ "$NO_CLEAN" = "" ]; then
	clean
fi
if [ "$ACTION" = "clean" ]; then
	exit 0
fi

cd $(dirname $0)
mkdir -p $TARGET_DIR/$TARGET_SUBDIR

# Don't quit on any errors now
set +e

case "$IMAGE_TYPE" in
	live)
		debug "Stage 1/2 - Config"
		log lb config -a $ARCH $CONFIG_OPTS "$@"
		[ $? -eq 0 ] || failure

		debug "Stage 2/2 - Build"
		log $SUDO lb build
		if [ $? -ne 0 ] || [ ! -e $IMAGE_NAME ]; then
			failure
		fi
	;;
esac

# If a command fails, make the whole script exit
set -e

debug "Moving files"
log mv -f $IMAGE_NAME $TARGET_DIR/$(target_image_name $ARCH)
log mv -f "$BUILD_LOG" $TARGET_DIR/$(target_build_log $ARCH)
log echo -e "GENERATED IMAGE: $TARGET_DIR/$(target_image_name $ARCH)"
