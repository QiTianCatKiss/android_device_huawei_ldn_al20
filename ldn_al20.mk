#
# ldn_al20.mk —— 华为畅享 8 (LDN-AL20) 产品定义
#
# 继承 TWRP 官方 recovery 基线, 仅覆盖与本机强相关的部分。
#

# ============ 继承 ============
$(call inherit-product, product/twrp/twrp.mk)

# ============ 产品标识 ============
PRODUCT_NAME := ldn_al20
PRODUCT_DEVICE := ldn_al20
PRODUCT_BRAND := huawei
PRODUCT_MODEL := LDN-AL20
PRODUCT_MANUFACTURER := Huawei
PRODUCT_VERSION := ldn_al20

# ============ recovery 必备组件 ============
PRODUCT_USE_DRM_BASED_DECODER := false
PRODUCT_BUILD_PROP_OVERRIDES += \
    TARGET_DEVICE=ldn_al20 \
    PRODUCT_NAME=msm8937_64 \
    ro.product.name=msm8937_64 \
    ro.product.device=msm8937_64 \
    ro.product.board=msm8937_64 \
    ro.board.platform=msm8937 \
    ro.build.version.sdk=26 \
    ro.build.version.release=8.0.0 \
    TARGET_USES_MMCUTILS

# ============ 语言 ============
PRODUCT_LOCALES := en_US zh_CN

# ============ CPU / ABI ============
PRODUCT_ARCH := arm64
PRODUCT_CHARACTERISTICS := nosdcard
