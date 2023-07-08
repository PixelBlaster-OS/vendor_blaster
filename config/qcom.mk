ifeq ($(BOARD_USES_QCOM_HARDWARE),true)
PRODUCT_VENDOR_KERNEL_HEADERS += hardware/qcom-caf/$(QCOM_HARDWARE_VARIANT)/kernel-headers
endif