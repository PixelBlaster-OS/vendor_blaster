ifeq ($(BOARD_USES_QCOM_HARDWARE),true)
include vendor/blaster/config/BoardConfigQcom.mk
endif

include vendor/blaster/config/BoardConfigSoong.mk
