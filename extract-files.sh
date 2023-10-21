#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
	echo "Unable to find helper script at ${HELPER}"
	exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_TARGET=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
	case "${1}" in
		--only-common )
			ONLY_COMMON=true
			;;
		--only-target )
			ONLY_TARGET=true
			;;
		-n | --no-cleanup )
			CLEAN_VENDOR=false
			;;
		-k | --kang )
			KANG="--kang"
			;;
		-s | --section )
			SECTION="${2}"; shift
			CLEAN_VENDOR=false
			;;
		* )
			SRC="${1}"
			;;
	esac
	shift
done

if [ -z "${SRC}" ]; then
	SRC="adb"
fi

function blob_fixup {
	case "$1" in
		system/lib*/libsink.so)
			grep -q "libshim_sink.so" "${2}" || \
			"${PATCHELF}" --add-needed "libshim_sink.so" "${2}"
			;;
		vendor/bin/hw/android.hardware.gnss-service.mediatek | \
		vendor/lib*/hw/android.hardware.gnss-impl-mediatek.so)
			grep -q "android.hardware.gnss-V1-ndk_platform.so" "${2}" && \
			"${PATCHELF}" --replace-needed "android.hardware.gnss-V1-ndk_platform.so" "android.hardware.gnss-V1-ndk.so" "${2}"
			;;
		vendor/bin/hw/android.hardware.media.c2@1.2-mediatek)
			grep -q "libavservices_minijail_vendor.so" "${2}" && \
			"${PATCHELF}" --replace-needed "libavservices_minijail_vendor.so" "libavservices_minijail.so" "${2}"
			;;
		vendor/bin/hw/vendor.mediatek.hardware.mtkpower@1.0-service)
			grep -q "android.hardware.power-V2-ndk_platform.so" "${2}" && \
			"${PATCHELF}" --replace-needed "android.hardware.power-V2-ndk_platform.so" "android.hardware.power-V2-ndk.so" "${2}"
			;;
		vendor/etc/init/android.hardware.neuralnetworks@1.3-service-mtk-neuron.rc)
			sed -i 's/start/enable/' "${2}"
			;;
		vendor/etc/init/vendor.mediatek.hardware.mtkpower@1.0-service.rc)
			echo "$(cat ${2}) input" > "${2}"
			;;
		vendor/lib*/hw/vendor.mediatek.hardware.pq@*-impl.so)
			grep -q "libutils.so" "${2}" && \
			"${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
			;;
		vendor/lib*/libmtkcam_stdutils.so)
			grep -q "libutils.so" "${2}" && \
			"${PATCHELF}" --replace-needed "libutils.so" "libutils-v32.so" "${2}"
			;;
	esac
}

if [ -z "${ONLY_TARGET}" ]; then
	# Initialize the helper for common device
	setup_vendor "${DEVICE_COMMON}" "${VENDOR_COMMON:-$VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

	extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

if [ -z "${ONLY_COMMON}" ] && [ -s "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" ]; then
	# Reinitialize the helper for device
	source "${MY_DIR}/../../${VENDOR}/${DEVICE}/extract-files.sh"
	setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

	extract "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"
fi

"${MY_DIR}/setup-makefiles.sh"
