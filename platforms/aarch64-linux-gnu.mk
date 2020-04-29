TOOLROOT            := /usr/bin/
ARCH                := arm64
CROSSBIN            := $(TOOLROOT)/$(TARGET_PLATFORM)-

TARGET_INCLUDE      := -I$(TARGET_ROOT)/usr/include/aarch64-linux-gnu/
TARGET_LIB          := $(TARGET_ROOT)/usr/lib/aarch64-linux-gnu/
INC_FLAGS           := $(TARGET_INCLUDE)

CXXFLAGS            := --sysroot=$(TARGET_ROOT)

TARGET_LIB_DIR      := $(TARGET_ROOT)/lib/aarch64-linux-gnu/
TARGET_ULIB_DIR     := $(TARGET_ROOT)/usr/lib/aarch64-linux-gnu/
LN_FLAGS            := --sysroot=$(TARGET_ROOT) \
                       -Wl,--dynamic-linker=/lib/ld-linux-aarch64.so.1\
                       -L$(TARGET_LIB_DIR)\
                       -Wl,-rpath-link=$(TARGET_LIB_DIR)\
                       -Wl,-rpath-link=$(TARGET_ULIB_DIR)\
                       -Wl,-rpath-link=$(TARGET_ULIB_DIR)/tegra\


BUILD_PROCESSOR := aarch64
BUILD_DISTRIBUTION := $(shell cat $(TARGET_ROOT)/etc/issue.net)



