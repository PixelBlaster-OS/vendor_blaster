# Inherit common PixelBlaster stuff
$(call inherit-product, vendor/aosp/config/common.mk)

PRODUCT_SIZE := full

# Include {Lato,Rubik} fonts
$(call inherit-product-if-exists, external/google-fonts/lato/fonts.mk)
$(call inherit-product-if-exists, external/google-fonts/rubik/fonts.mk)

# Recorder
PRODUCT_PACKAGES += \
    Recorder
