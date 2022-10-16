
LOCAL_PATH := $(call my-dir)

# $(1): module name; required
# $(2): module stem name if non-empty
# $(3): source file name 
# $(4): relative install dir
# $(5): create symbolic links
# $(6): depend modules
define define-redroid-prebuilt-lib
include $$(CLEAR_VARS)
LOCAL_MODULE := $1
ifneq ($2,)
LOCAL_INSTALLED_MODULE_STEM := $2
endif

ifneq ($3,)
src := $3
else
src := $1
endif
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES_$$(TARGET_ARCH) := prebuilts/$$(TARGET_ARCH)/lib/$$(src)
ifneq ($$(TARGET_2ND_ARCH),)
LOCAL_SRC_FILES_$$(TARGET_2ND_ARCH) := prebuilts/$$(TARGET_2ND_ARCH)/lib/$$(src)
endif
#LOCAL_STRIP_MODULE := false
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_RELATIVE_PATH := $4
LOCAL_MULTILIB := both
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_SYMLINKS := $5
LOCAL_CHECK_ELF_FILES := false
LOCAL_REQUIRED_MODULES := $6
include $$(BUILD_PREBUILT)
endef


# $(1): module name; required
# $(2): module stem name if non-empty
# $(3): source file name 
# $(4): relative install dir
# $(5): create symbolic links
# $(6): depend modules
define define-redroid-prebuilt-etc
include $$(CLEAR_VARS)
LOCAL_MODULE := $1
ifneq ($2,)
LOCAL_INSTALLED_MODULE_STEM := $2
endif

ifneq ($3,)
src := $3
else
src := $1
endif
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := prebuilts/$$(TARGET_ARCH)/share/$$(src)
LOCAL_MODULE_RELATIVE_PATH := $4
LOCAL_PROPRIETARY_MODULE := true
LOCAL_MODULE_SYMLINKS := $5
LOCAL_REQUIRED_MODULES := $6
include $$(BUILD_PREBUILT)
endef


# NDK libs
ndk_libs_cxx := libc++_shared
ndk_libs_media := libcamera2ndk libandroid libmediandk
libs := $(ndk_libs_cxx) $(ndk_libs_media)
$(foreach lib,$(libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib)_p,$(lib).so,$(lib).so)))


# DRI
dri_libs := libgallium_dri
drv_libs := libgallium_drv_video
ifeq ($(TARGET_ARCH),$(filter $(TARGET_ARCH),x86 x86_64))
$(eval $(call define-redroid-prebuilt-lib,libigdgmm,,libigdgmm.so))
drv_libs_intel := i965_drv_video iHD_drv_video
$(foreach lib,$(drv_libs_intel),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),,dri/$(lib).so,dri,,libigdgmm)))

drv_libs += $(drv_libs_intel)
endif
dri_links := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib/dri && find * -name '*_dri.so' -type l)
drv_links := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib/dri && find * -name '*_drv_video.so' -type l)
$(eval $(call define-redroid-prebuilt-lib,libgallium_dri,,dri/libgallium_dri.so,dri,$(dri_links)))
$(eval $(call define-redroid-prebuilt-lib,libgallium_drv_video,,dri/libgallium_drv_video.so,dri,$(drv_links)))


## amdgpu.ids
$(eval $(call define-redroid-prebuilt-etc,amdgpu.ids.redroid,,libdrm/amdgpu.ids,hwdata))


# libs with SOVERSION
gbm_libs := libgbm.so.1
glapi_libs := libglapi.so.0
expat_libs := libexpat.so.1
libs = $(gbm_libs) $(glapi_libs) $(expat_libs)
drm_libs := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib && find * -name 'libdrm*.so.*' -type l)
libs += $(drm_libs)
x264_libs := libx264.so.164
libs += $(x264_libs)
$(foreach lib,$(libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),$(lib))))


## VA
va_libs := libva.so.2 libva-drm.so.2
$(foreach lib,$(va_libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),$(lib),,,,$(drv_libs) $(drm_libs))))


## LLVM
llvm_libs := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib && find * -name 'libLLVM*' -type f)
llvm_libs := $(llvm_libs:.so=)
$(foreach lib,$(llvm_libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),,$(lib).so)))


## FFMPEG
ffmpeg_libs := libavcodec libavdevice libavfilter libavformat libavutil libpostproc libswresample libswscale
$(foreach lib,$(ffmpeg_libs),\
	$(eval $(call define-redroid-prebuilt-lib,$(lib),,$(lib).so,,,$(ndk_libs_media:%=%_p))))


# GLES
libs := libEGL_mesa libGLESv1_CM_mesa libGLESv2_mesa
$(foreach lib,$(libs),\
    $(eval $(call define-redroid-prebuilt-lib,$(lib),,egl/$(lib).so,egl,,\
		$(dri_libs) $(llvm_libs) $(glapi_libs) $(drm_libs) $(expat_libs))))


# Vulkan
vulkan_libs := $(shell cd $(LOCAL_PATH)/prebuilts/$(TARGET_ARCH)/lib/hw && find * -name 'libvulkan_*.so' -type f)
$(foreach lib,$(vulkan_libs),\
	$(eval $(call define-redroid-prebuilt-lib,$(lib:libvulkan_%.so=vulkan.%),,hw/$(lib),hw,,$(ndk_libs_cxx:%=%_p))))


# minigbm gralloc
$(eval $(call define-redroid-prebuilt-lib,gralloc.cros,,hw/gralloc.cros.so,hw))


# gbm gralloc
$(eval $(call define-redroid-prebuilt-lib,gralloc.gbm,,hw/gralloc.gbm.so,hw,,$(gbm_libs)))


## libmedia_codec
$(eval $(call define-redroid-prebuilt-lib,libmedia_codec,,libmedia_codec.so, , ,$(va_libs) $(ffmpeg_libs) $(x264_libs)))


# $(1): module name (and file name)
# $(2): depended modules
define define-redroid-prebuilt-bin
include $$(CLEAR_VARS)
LOCAL_MODULE := $1
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_SRC_FILES_$$(TARGET_ARCH) := prebuilts/$$(TARGET_ARCH)/bin/$1
#LOCAL_STRIP_MODULE := false
LOCAL_MULTILIB := first
LOCAL_MODULE_TAGS := optional
LOCAL_PROPRIETARY_MODULE := true
LOCAL_CHECK_ELF_FILES := false
LOCAL_REQUIRED_MODULES := $2
include $$(BUILD_PREBUILT)
endef

# vaapi
bins:=avcenc h264encode hevcencode jpegenc vp8enc vp9enc vainfo
$(foreach i,$(bins),\
    $(eval $(call define-redroid-prebuilt-bin,$(i),$(va_libs))))

# ffmpeg
bins:=ffmpeg ffprobe
$(foreach i,$(bins),\
    $(eval $(call define-redroid-prebuilt-bin,$(i),$(ffmpeg_libs))))
