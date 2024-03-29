#!/bin/bash

set -e

function print_usage() {
    echo 'create-dmg-installer.sh --app BUILD_APP_PATH OUTPUT_BUNDLE.dmg

Create an disk image installer (.dmg) for Orange OSX application.

Options:
    -a --app PATH
        Path to a build Orange3.app to include in the disk image
        (default dist/Orange3.app)

    -h --help
        Print this help
'
}


DIRNAME=$(dirname "$0")

# Path to dmg resources (volume icon, background, ...)
RES="${DIRNAME}"/dmg-resources

APP=dist/Orange3.app

while [[ "${1:0:1}" = "-" ]]; do
    case "${1}" in
        -a|--app)
            APP=${2:?"BUILD_APP_PATH is missing"}
            shift 2 ;;
        -h|--help)
            print_usage
            exit 0 ;;
        -*)
            echo "Unknown option $1" >&2
            print_usage
            exit 1
            ;;
    esac
done

DMG=${1?"Output bundle dmg path not specified"}

if [[ ! -d "${APP}" ]]; then
    echo "$APP path does not exits or is not a directory."
    print_usage
    exit 1
fi

TMP_DIR=$(mktemp -d -t create-dmg-installer)
TMP_TEMPLATE="${TMP_DIR}"/source

echo "Preparing an image template in ${TMP_TEMPLATE}"
echo "============================================="

mkdir -p "${TMP_TEMPLATE}"/

BASENAME=$(basename $APP)
echo "Copying the app ${BASENAME}"

# Copy the .app directory in place
cp -a "${APP}" "${TMP_TEMPLATE}"/"${BASENAME}"

mkdir -p "$(dirname "${DMG}")"

EXTRA_DS_STORE=()
if [[ -n ${SKIP_JENKINS} ]]; then
  # When create-dmg cannot control Finder.app via oascript we instead just copy
  # a preexisting .DS_Store file in place
  EXTRA_DS_STORE+=(
    --skip-jenkins --add-file .DS_Store "${RES}/DS_Store" 0 0
  )
fi

create-dmg \
  --volname "Orange Installer" \
  --volicon "${RES}/VolumeIcon.icns" \
  --background "${RES}/background.png" \
  --window-pos 200 120 \
  --window-size 400 244 \
  --icon-size 75 \
  --text-size 12 \
  --hide-extension "${BASENAME}" \
  --icon "${BASENAME}" 95 125 \
  --app-drop-link 305 125 \
  ${EXTRA_DS_STORE[*]} \
  "${DMG}" \
  "${TMP_TEMPLATE}"

echo "Cleaning up."
rm -rf "${TMP_DIR}"
