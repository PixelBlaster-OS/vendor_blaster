# Gapps
ifeq ($(USE_GAPPS),true)
$(call inherit-product, vendor/gms/gms_full.mk)

# Common Overlay
DEVICE_PACKAGE_OVERLAYS += \
    vendor/aosp/overlay-gapps/common

# Exclude RRO Enforcement
PRODUCT_ENFORCE_RRO_EXCLUDED_OVERLAYS +=  \
    vendor/aosp/overlay-gapps

$(call inherit-product, vendor/aosp/config/rro_overlays.mk)
else
$(call inherit-product, packages/apps/Lawnchair/lawnchair.mk)
endif
