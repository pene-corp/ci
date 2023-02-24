#!/bin/bash

# Metadata
VERSION="3.2-dev"

# Variables
PENEOS_SOURCE="$PWD"
NOCOLOR=false
FORCE=false
IMAGE=false
BOOTLOADER_NAME=""
IMAGE_OUT="${PWD}/disk_image"
CDN=false

# Parse arguments
while getopts 'CifnSs:b:o:' flag; do
  case "${flag}" in
  s) PENEOS_SOURCE="${OPTARG}" ;;
  S) PENEOS_SOURCE="" ;;
  n) NOCOLOR=true ;;
  f) FORCE=true ;;
  i) IMAGE=true ;;
  b) BOOTLOADER_NAME="${OPTARG}" ;;
  o) IMAGE_OUT="${OPTARG}" ;;
  C) CDN=true ;;
  *) ;;
  esac
done

# Handle failures
handle() {
  err "$@"
  if [ "$FORCE" == false ]; then
    exit 1
  else
    warn "Ignoring errors due to force flag."
  fi
}

# Show welcome messgae
welcome() {
  out "$BWhite""########################"
  out "$BWhite""# PeneOS CI Script     #"
  out "$BWhite#$Color_Off"" Welcome!             $BWhite#"
  out "$BWhite""########################"
  out
  out "$BWhite""Version:""$Color_Off"" ""$VERSION"
  out
}

# Include Libraries
# shellcheck source=./script/lib.sh
source "./script/lib.sh"

welcome

if [ "$CDN" == true ]; then
  ORIGINAL_SRC="$PWD"
  cd "$PENEOS_SOURCE" || handle "$ERROR_CHWD"
  CURRENT_GIT_COMMIT="$(git log --format="%h" -n 1)"
  DATETIME="$(date -Iseconds)"
  cd "$PENEOS_SOURCE/Build/x86_64" || handle "$ERROR_CHWD"
  "$PENEOS_SOURCE/Meta/pene.sh" image
  ninja grub-image
  mv "$PENEOS_SOURCE/Build/x86_64/${BOOTLOADER_NAME}_disk_image" "$ORIGINAL_SRC/out/peneos-$VERSION-$CURRENT_GIT_COMMIT-$DATETIME-grub" || handle "$ERROR_IMGM"
  exit
fi

if [ -z "$PENEOS_SOURCE" ]; then
  printf "Please enter the source location: "
  read -r PENEOS_SOURCE
fi

if [ "$FORCE" = true ]; then
  warn "You are using the force (-f) flag. This might break the script and build system."
  warn "Use at your own risk!"
fi

out "${BCyan}Notice: ${Color_Off}Running with following arguments:"
out "${BWhite}PENEOS_SOURCE: ${Color_Off}$PENEOS_SOURCE"
out "${BWhite}NOCOLOR: ${Color_Off}$NOCOLOR"
out "${BWhite}IMAGE: ${Color_Off}$IMAGE"
if [ "$IMAGE" == true ]; then
  out "${BWhite}IMAGE_OUT: ${Color_Off}$IMAGE_OUT"
  out "${BWhite}BOOTLOADER_NAME: ${Color_Off}$BOOTLOADER_NAME"
fi
out

cd "$PENEOS_SOURCE" || handle "$ERROR_CHWD"

if [ ! -d "$PENEOS_SOURCE/Build" ]; then
  out "${BCyan}Info: ${Color_Off}Toolchain doesn't exist, or build folder has been deleted. Rebuilding."
  out "--- Meta/pene.sh rebuild-toolchain ---"
  "$PENEOS_SOURCE/Meta/pene.sh" rebuild-toolchain || handle "$ERROR_TOOL"
  out "--- --- ---"
fi

"$PENEOS_SOURCE/Meta/pene.sh" build || handle "$ERROR_BULD"

if [ "$IMAGE" == true ]; then
  cd "$PENEOS_SOURCE/Build/x86_64" || handle "$ERROR_CHWD"
  "$PENEOS_SOURCE/Meta/pene.sh" image
  if [ -n "$BOOTLOADER_NAME" ]; then
    case "$BOOTLOADER_NAME" in
    grub) ninja grub-image ;;
    *) handle "$ERROR_BTLD" ;;
    esac
    mv "$PENEOS_SOURCE/Build/x86_64/${BOOTLOADER_NAME}_disk_image" "$IMAGE_OUT" || handle "$ERROR_IMGM"
  fi
fi

out "$BGreen""Success: $Green""Build has been completed."
exit 0
