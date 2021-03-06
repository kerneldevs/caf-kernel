#Android makefile to build kernel as a part of Android Build

ifeq ($(TARGET_PREBUILT_KERNEL),)

KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_CONFIG := $(KERNEL_OUT)/.config
TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/arm/boot/zImage
KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
KERNEL_MODULES_INSTALL := system
KERNEL_MODULES_OUT := $(TARGET_OUT)/lib/modules

ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
$(info Using uncompressed kernel)
TARGET_PREBUILT_KERNEL := $(KERNEL_OUT)/piggy
else
TARGET_PREBUILT_KERNEL := $(TARGET_PREBUILT_INT_KERNEL)
endif
#LGE_CHANGE_S, [jisung.yang@lge.com], 2010-04-24, <cp wireless.ko to system/lib/modules>
KERNEL_MODULES_OUT := $(TARGET_OUT)/lib/modules
#LGE_CHANGE_E, [jisung.yang@lge.com], 2010-04-24, <cp wireless.ko to system/lib/modules>

define mv-modules
mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`;\
ko=`find $$mpath/kernel -type f -name *.ko`;\
for i in $$ko; do mv $$i $(KERNEL_MODULES_OUT)/; done;\
fi
endef

define clean-module-folder
mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.dep`;\
if [ "$$mdpath" != "" ];then\
mpath=`dirname $$mdpath`; rm -rf $$mpath;\
fi
endef

$(KERNEL_OUT):
	mkdir -p $(KERNEL_OUT)

$(KERNEL_MODULES_OUT):
	mkdir -p $(KERNEL_MODULES_OUT)

$(KERNEL_CONFIG): $(KERNEL_OUT)
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- $(KERNEL_DEFCONFIG)

$(KERNEL_OUT)/piggy : $(TARGET_PREBUILT_INT_KERNEL)
	$(hide) gunzip -c $(KERNEL_OUT)/arch/arm/boot/compressed/piggy.gzip > $(KERNEL_OUT)/piggy

$(TARGET_PREBUILT_INT_KERNEL): $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi-
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- modules
	$(MAKE) -C kernel O=../$(KERNEL_OUT) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) ARCH=arm CROSS_COMPILE=arm-eabi- modules_install
	$(mv-modules)
	$(clean-module-folder)

#LGE_CHANGE_S, [jongpil.yoon@lge.com], 2011-02-09, <cp wireless.ko to system/lib/modules>
	mkdir -p $(TARGET_OUT)/lib
	mkdir -p $(KERNEL_MODULES_OUT) 
ifeq ($(TARGET_PRODUCT), lge_gelato)
	-cp  -f $(KERNEL_OUT)/drivers/net/wireless/bcm4330/wireless.ko $(KERNEL_MODULES_OUT)
else ifeq ($(TARGET_PRODUCT), lge_gelato_nfc)
	-cp  -f $(KERNEL_OUT)/drivers/net/wireless/bcm4330/wireless.ko $(KERNEL_MODULES_OUT)
endif

ifeq ($(TARGET_PRODUCT), muscat)
	-cp  -f $(KERNEL_OUT)/drivers/net/wireless/bcm4329/wireless.ko $(KERNEL_MODULES_OUT)
endif
	
ifeq ($(TARGET_PRODUCT), lge_univa)
	-cp  -f $(KERNEL_OUT)/drivers/net/wireless/bcm4330/wireless.ko $(KERNEL_MODULES_OUT)
endif
#LGE_CHANGE_E, [jongpil.yoon@lge.com], 2011-02-09, <cp wireless.ko to system/lib/modules>

# [LGE_UPDATE_S] DMS_SYSTEM hyunwook.choo 2011-06-09
	mkdir -p $(TARGET_OUT)/../system/etc/fota
# [LGE_UPDATE_E] DMS_SYSTEM hyunwook.choo 

$(KERNEL_HEADERS_INSTALL): $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- headers_install

kerneltags: $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- tags

kernelconfig: $(KERNEL_OUT) $(KERNEL_CONFIG)
	env KCONFIG_NOTIMESTAMP=true \
	     $(MAKE) -C kernel O=../$(KERNEL_OUT) ARCH=arm CROSS_COMPILE=arm-eabi- menuconfig
	cp $(KERNEL_OUT)/.config kernel/arch/arm/configs/$(KERNEL_DEFCONFIG)

endif
