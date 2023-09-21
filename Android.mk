#
# Copyright (C) 2023 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifneq ($(filter camellia everpal light,$(TARGET_DEVICE)),)

subdir_makefiles=$(call first-makefiles-under,$(LOCAL_PATH))
$(foreach mk,$(subdir_makefiles),$(info including $(mk) ...)$(eval include $(mk)))

VENDOR_SYMLINKS := \
	$(TARGET_OUT_VENDOR)/etc

$(VENDOR_SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	$(hide) echo "Making vendor symlinks"
	@mkdir -p $(TARGET_OUT_VENDOR)/etc
	@ln -sf /vendor/etc/audio_param $(TARGET_OUT_VENDOR)/etc/audio_param_global
	$(hide) touch $@

ALL_DEFAULT_INSTALLED_MODULES += $(VENDOR_SYMLINKS)

endif
