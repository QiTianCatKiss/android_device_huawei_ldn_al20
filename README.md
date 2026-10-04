# android_device_huawei_ldn_al20

华为畅享 8 / LDN-AL20（含 LDN-AL00、LDN-AL10、LDN-TL10、LDN-L01 等同平台变体）的 TWRP Recovery 设备树，基于 TWRP 3.2.3 与 AOSP 8.1.0（OPM1 / OPM4.171019.021.P1）源码树。

- **SoC**：Qualcomm Snapdragon 430 (MSM8937)，arm64 (AArch64)
- **Android**：8.1.0 / EMUI 8.0 基线
- **产品代号**：`ldn_al20`
- **目标平台版本**：`OPM1`

## 目录结构

| 文件 | 作用 |
| --- | --- |
| `AndroidProducts.mk` | 注册 `ldn_al20` 产品，供 `lunch ldn_al20-eng` 使用 |
| `ldn_al20.mk` | 产品继承配置（继承 TWRP 基线产品） |
| `ldn_al20.prop` | 产品属性（构建类型、版本等） |
| `BoardConfig.mk` | 分区表、CPU/ABI、内核基址、屏幕参数、TWRP 特性开关 |
| `Android.mk` | 设备树入口，引入 `recovery.mk` 及全部子模块 makefile |
| `recovery.mk` | 通过 `BOARD_COPY_FILES` 注入原厂 vendor / system / product / odm HAL blob |
| `recovery.fstab` | recovery 阶段的分区挂载表 |
| `prebuilt/` | 原厂预编译文件（kernel、NFC 配置文件等） |
| `.gitignore` | 排除 `.bak` / `.o` / `.log` 等构建中间产物 |

## 本分支相对上游的改动

1. **启用 FBE 解密支持**
   在 `BoardConfig.mk` 中 `TW_INCLUDE_CRYPTO := true` 之后补充：

   ```makefile
   TW_INCLUDE_CRYPTO_FBE := true
   ```

   该开关使 TWRP 编入 `crypto/ext4crypt` 下的 FBE 消费端 —— `libe4crypt`、`twrpfbe`、`e4policyget`、`keystore_auth`，用于解密 Android 8 的用户数据（`/data`）。

2. **修正 `Android.mk` 缺失包含**
   原文件使用 `$(call all-makefiles-under,...)`，该宏**不包含同目录的同级 makefile**，导致 `recovery.mk` 未被包含、`BOARD_COPY_FILES` 注入的 HAL blob 全部失效。现改为显式包含：

   ```makefile
   LOCAL_PATH := device/huawei/ldn_al20
   ifeq ($(TARGET_DEVICE),ldn_al20)
   include $(LOCAL_PATH)/recovery.mk
   include $(call all-makefiles-under,$(LOCAL_PATH))
   endif
   ```

3. **修正 `BoardConfig.mk` 字体转义引号**
   `BOARD_USE_CUSTOM_RECOVERY_FONT := \"roboto_23x41.h\"` 中的转义引号非法，已改为：

   ```makefile
   BOARD_USE_CUSTOM_RECOVERY_FONT := roboto_23x41.h
   ```

## 编译方法

TWRP 3.x / AOSP 8.1 **必须使用 JDK 8**，且需要已同步完整的 TWRP 源码树（`bootable/recovery` 须为 TWRP 源码而非 AOSP 原版）：

```bash
export JAVA_HOME=/path/to/jdk8
export PATH="$JAVA_HOME/bin:$PATH"

cd <aosp-root>
source build/envsetup.sh
lunch ldn_al20-eng
make recoveryimage
```

产物输出在：

```
out/target/product/ldn_al20/recovery.img
```

刷入方式（recovery 模式）：

```bash
fastboot flash recovery recovery.img
```

> 若要解密 `/data`，需确保设备已刷入与该机型匹配的 **TWRP 3.x + Android 8.1 官方版本**。跨大版本（Android 9+/TWRP 4.x）解密 FBE 用户数据需要额外处理 keymaster / gatekeeper HAL 兼容性。

## 设备树补丁说明

`bootable/recovery` 下的 TWRP 顶层 `Android.mk` 重建、`libaosprecovery` 补定义、fb2png 的 `libpng` 预编译改名（避免与 Soong `libpng` 冲突）等构建侧修复属于源码树层面的改动，**不属于本设备树仓库的范畴**，需在 TWRP 源码树侧另行应用。

## License

设备树配置与脚本遵循所引用的 TWRP / AOSP 许可（Apache-2.0 / GPL-2.0 等，见各文件头部声明）。`prebuilt/` 下的原厂二进制文件为华为所有，仅用于个人研究与设备定制，请遵守对应厂商的开源许可与使用条款。
