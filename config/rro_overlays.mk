# Google Overlays
PRODUCT_PACKAGES += \
    PixelDocumentsUIGoogleOverlay \
    BuiltInPrintServiceOverlay \
    GooglePermissionControllerOverlay \
    PixelConfigOverlayCommon \
    TeleServiceOverlay \
    CaptivePortalLoginOverlay \
    GoogleWebViewOverlay \
    TelecomOverlay \
    CellBroadcastServiceOverlay \
    TelephonyProviderOverlay \
    ContactsProviderOverlay \
    PixelConfigOverlay2018 \
    TraceurOverlay \
    PixelConfigOverlay2019 \
    PixelConfigOverlay2019Midyear \
    PixelConfigOverlay2021 \
    PixelSetupWizardOverlay \
    PixelSetupWizardOverlay2019 \
    PixelSetupWizardOverlayActiveEdge \
    PixelFwResOverlay \
    GoogleConfigOverlay \
    SystemUIGoogleOverlay \
    SettingsGoogleOverlayAosp

ifeq ($(TARGET_INCLUDE_LIVE_WALLPAPERS),true)
PRODUCT_PACKAGES += \
    PixelLiveWallpapersOverlay
endif
