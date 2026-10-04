LOCAL_PATH := device/huawei/ldn_al20

ifeq ($(TARGET_DEVICE),ldn_al20)

include $(LOCAL_PATH)/recovery.mk
include $(call all-makefiles-under,$(LOCAL_PATH))

endif
