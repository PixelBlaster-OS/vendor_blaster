
BLASTER_BUILD_DATE := $(shell date -u +%Y%m%d_%H%M%S)

BLASTER_BUILDTYPE ?= UNOFFICIAL

BLASTER_BUILD_VERSION := 6.3

BLASTER_VERSION := ${BLASTER_BUILD_VERSION}-$(BLASTER_BUILDTYPE)-$(BLASTER_BUILD)
