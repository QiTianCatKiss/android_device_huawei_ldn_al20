#
# recovery.mk —— 把原厂 HAL blobs 打进 recovery.img
#
# blobs 来源: 原厂固件 UPDATE_f8c83bfc 的 sparse 分区镜像
#   system.img (2336MB) -> system.raw -> debugfs rdump /lib/hw  /lib64/hw
#   vendor.img (552MB)  -> vendor.raw  -> debugfs rdump /lib/hw  /lib64/hw  /etc
#   product.img (168MB) -> product.raw -> debugfs rdump /hw_oem
#   odm.img (32MB)      -> odm.raw     -> debugfs rdump /hw_odm  /etc
#
# 提取工具链:
#   ~/simg2img.py              纯 Python Android sparse 解包 (magic 0xED26FF3A)
#   e2fsprogs debugfs -R rdump 只读导出, 无需 root mount
#
# !! 注意 debugfs rdump 会丢掉 "rdump 源目录" 这一层之外的部分层级:
#    rdump /hw_oem/LDN-AL20 导出后只剩 hw_oem/          (LDN-AL20 层被压掉)
#    rdump /hw_odm            导出后只剩 LDN-L01/ LDN-TL10/
#    rdump /lib/hw            导出后只剩 *.so (hw/ 层被压掉, 靠 fix_blobs_layout.sh 还原)
#   因此 recovery.mk 里的源路径必须与 prebuilt/ 实际结构一致, 且一律用
#   `cp -a src/. dst/` 整树复制 —— lib/{Alipay,BaiduMap,...}、xml/5x6/ 等
#   二级目录用 `cp *` 无法递归。
#
# 架构对应 (readelf 实测):
#   prebuilt/vendor/lib/hw/*.so    ELF32 ARM     -> 32 位 HAL
#   prebuilt/vendor/lib64/hw/*.so  ELF64 AArch64 -> 64 位 HAL
#
# 目标机为 arm64 (TARGET_ARCH := arm64), TWRP 以 64 位为主,
# 因此 lib64 的 HAL 是关键路径; lib (32位) 保留给未重编的 vendor 服务。
#
LOCAL_PATH := device/huawei/ldn_al20
PREB       := $(LOCAL_PATH)/prebuilt

# ==================================================================
#  7. 内核 —— 安装到 $(PRODUCT_OUT)/kernel
#
#  AOSP 8.1 的 build/make/core/Makefile:574 只做变量定义:
#      INSTALLED_KERNEL_TARGET := $(PRODUCT_OUT)/kernel
#  真正的拷贝规则必须由设备树提供（高通/MTK 树都是这么做的）。
#  没有它 -> "ninja: error: out/target/product/ldn_al20/kernel missing
#             and no known rule to make it"，boot.img 与 recoveryimage 一起失败。
#
#  内核来源: device/huawei/ldn_al20/prebuilt/kernel
#            (= /mnt/e/111/ldn-al20/out/kernel_with_dtb.img)
#            11918772 字节, MD5 23cb61b3c8c9daf32441fc1d8a3b2dbe, gzip magic 1f 8b 08 00
#
#  LDN-AL20 是华为 eROS 三段式 recovery，实际启动的是 erecovery_kernel 分区，
#  此处装出的 kernel 用于 recovery.img 的 boot header（base/tags/page 来自 BoardConfig）。
# ==================================================================

KERNEL_SRC := $(LOCAL_PATH)/prebuilt/kernel
KERNEL_DST := $(PRODUCT_OUT)/kernel

$(KERNEL_DST): $(KERNEL_SRC)
	@mkdir -p $(dir $@)
	@echo "Install kernel: $(KERNEL_SRC) -> $@"
	@cp -f $< $@
	@chmod 644 $@

# 注意：此处不能再写 $(INSTALLED_RECOVERYIMAGE_TARGET): $(KERNEL_DST)
# Android.mk 解析发生在 build/make/core/Makefile 之前，该变量尚未定义，
# 会退化成空目标规则。recoveryimage 通过 mkbootimg --kernel 天然依赖它。

# ==================================================================
#  8. 原厂 blobs 注入 —— BOARD_RECOVERY_IMAGE_PREPARE 钩子
#
#  为什么不用 PRODUCT_COPY_FILES：
#    build/make/core/Makefile:30 的 copy-one-file 规则会把目标文件安装到
#    $(PRODUCT_OUT) 体系下，而 recovery 的 root 是 $(TARGET_RECOVERY_ROOT_OUT)
#    = $(PRODUCT_OUT)/recovery/root。两者路径不同，PRODUCT_COPY_FILES 不会
#    自动落进 ramdisk（实测 vendor HAL 计数 = 0）。
#    PRODUCT_COPY_FILES 在 kati 中还是只读变量，在 Android.mk 赋值直接报错:
#      cannot assign to readonly variable: PRODUCT_COPY_FILES
#
#  官方注入点：build/make/core/Makefile:1238
#    $(BOARD_RECOVERY_IMAGE_PREPARE)   ← 在 mkbootfs 打包 ramdisk 之前执行
#    位置最合适：既晚于所有 recovery 模块安装完成，又早于 ramdisk 打包。
#
#  关于 vendor/etc/*.rc:
#    这些是 Android 侧的 HAL 启动脚本（service 段），TWRP 的 recovery root
#    下只 import /init.rc，不会执行它们，留存仅为调试与后续扩展
#    （例如按需手动 source vendor/etc/hw/init.recovery.qcom.rc）。
# ==================================================================

define ldn-al20-inject-stock-hals
$(hide) echo "Inject stock blobs into recovery root..."
$(hide) mkdir -p $(1)/vendor/lib/hw $(1)/vendor/lib64/hw
$(hide) mkdir -p $(1)/vendor/etc/hw $(1)/vendor/etc/hw_extra $(1)/vendor/etc/charger
$(hide) mkdir -p $(1)/system/lib/hw $(1)/system/lib64/hw
$(hide) mkdir -p $(1)/product/hw_oem/LDN-AL20
$(hide) mkdir -p $(1)/odm/hw_odm $(1)/odm/etc

# --- HAL 库 ---
$(hide) cp -a $(PREB)/vendor/lib/hw/.   $(1)/vendor/lib/hw/   2>/dev/null || true
$(hide) cp -a $(PREB)/vendor/lib64/hw/. $(1)/vendor/lib64/hw/ 2>/dev/null || true
$(hide) cp -a $(PREB)/system/lib/hw/.   $(1)/system/lib/hw/   2>/dev/null || true
$(hide) cp -a $(PREB)/system/lib64/hw/. $(1)/system/lib64/hw/ 2>/dev/null || true

# --- product: 整机差异化配置 (hw_oem 下含 etc/ lib/ prop/ xml/ 及两个 cfg) ---
$(hide) cp -a $(PREB)/product/hw_oem/. $(1)/product/hw_oem/LDN-AL20/ 2>/dev/null || true

# --- odm: NFC/指纹等共用平台配置 + init.odm.rc ---
#     注意 prebuilt/odm/ 下面是按机型分开的目录(LDN-L01 / LDN-TL10),
#     不是 hw_odm/LDN-AL10/, 不能整树 cp 否则会多出一层 odm/hw_odm/etc/
$(hide) cp -a $(PREB)/odm/LDN-L01  $(1)/odm/hw_odm/ 2>/dev/null || true
$(hide) cp -a $(PREB)/odm/LDN-TL10 $(1)/odm/hw_odm/ 2>/dev/null || true
$(hide) cp -a $(PREB)/odm/etc/.    $(1)/odm/etc/    2>/dev/null || true

# --- vendor init rc 整树 (含 hw/ hw_extra/ charger/ 子目录) ---
$(hide) cp -a $(PREB)/vendor/etc/. $(1)/vendor/etc/ 2>/dev/null || true

# --- 注入结果自检 ---
$(hide) echo "  vendor/lib/hwso   : `find $(1)/vendor/lib/hw   -name '*.so' | wc -l`"
$(hide) echo "  vendor/lib64/hw so : `find $(1)/vendor/lib64/hw -name '*.so' | wc -l`"
$(hide) echo "  system/lib/hw   so : `find $(1)/system/lib/hw   -name '*.so' | wc -l`"
$(hide) echo "  product/hw_oem files: `find $(1)/product -type f | wc -l`"
$(hide) echo "  odm files          : `find $(1)/odm -type f | wc -l`"
$(hide) echo "  vendor/etc    files : `find $(1)/vendor/etc -type f | wc -l`"
endef

BOARD_RECOVERY_IMAGE_PREPARE := $(call ldn-al20-inject-stock-hals,$(TARGET_RECOVERY_ROOT_OUT))