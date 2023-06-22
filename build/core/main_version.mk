# Build fingerprint
ifneq ($(BUILD_FINGERPRINT),)
ADDITIONAL_SYSTEM_PROPERTIES += \
    ro.build.fingerprint=$(BUILD_FINGERPRINT)
endif

# PixelBlaster System Version
ADDITIONAL_SYSTEM_PROPERTIES += \
    ro.blaster.version=$(BLASTER_VERSION) \

