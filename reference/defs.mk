SHELL = /bin/bash

# Init flags
CPPFLAGS        :=
CXXFLAGS        :=
LDFLAGS         :=
INSTALL_FILES   :=
LIBS            :=
INC_FLAGS       :=
LN_FLAGS        :=
PREREQ          :=

# include personal overrides
sinclude $(HOME)/.make

HOST_PLATFORM   := $(shell uname -p)-linux-gnu
TARGET_PLATFORM ?= $(HOST_PLATFORM)
TARGET_ROOT     ?= /
PROJECT_NAME    ?= DWProject

sinclude $(TOPDIR)/make.conf
sinclude $(DWMAKE)/platforms/$(TARGET_PLATFORM).mk

ROOT ?= $(TARGET_ROOT)

INC_FLAGS       += -I$(TARGET_ROOT)/usr/include/
INC_FLAGS       += -I$(TOPDIR)/include/

# set defaults if not overriden by personal overrides
QUIET           ?= 1
J               ?= 1
BUILD_FLAVOR    ?= debug
DO_STRIP        ?= 1

ifeq ($(BUILD_FLAVOR),debug)
  DO_STRIP := 0
endif

ifeq ($(QUIET),1)
  Q:=@
else
  Q:=
endif

DEF_FLAGS   :=

ifeq ($(WARNINGS_AS_ERRORS),1)
  DEF_FLAGS += -Werror
  ifeq ($(USE_CLANG),1)
    DEF_FLAGS += -Wno-error=deprecated-register
  endif
endif

ifdef ERROR_LIMIT
  ifeq ($(USE_CLANG),1)
    CXXFLAGS += -ferror-limit=$(ERROR_LIMIT)
    else
    CXXFLAGS += -fmax-errors=$(ERROR_LIMIT)
  endif
endif

NVCC := $(CUDA_PATH)/bin/nvcc -ccbin 

CLANG   := clang
CLANGXX := clang++

ifeq ($(USE_CLANG),1)
  CC           = $(CROSSBIN)$(CLANG)
  CXX          = $(CROSSBIN)$(CLANGXX)
else
  CC           = $(CROSSBIN)gcc
  CXX          = $(CROSSBIN)g++
endif

CPP         := $(CROSSBIN)cpp
AR          := $(CROSSBIN)ar
LD          := $(CROSSBIN)ld
RANLIB      := $(CROSSBIN)ranlib
STRIP       := $(CROSSBIN)strip
OBJDUMP     := $(CROSSBIN)objdump
PKGCONFIG   := PKG_CONFIG_SYSROOT_DIR=$(TARGET_ROOT) pkg-config

MACHINE     := $(shell $(CROSSBIN)gcc -dumpmachine)
ARCH        ?= $(MACHINE)

GXXVERSION = $(shell g++ --version | head -1 | sed 's/(.*)//' | awk '{print $$2}' | cut -f1 -d".")

ifeq ($(shell test $(GXXVERSION) -ge 7; echo $$? ),0)
    STD_FLAGS   ?= -std=c++17
else
    ifeq ($(shell test $(GXXVERSION) -ge 5; echo $$? ),0)
        STD_FLAGS   ?= -std=c++14
    else
        STD_FLAGS   ?= -std=c++0x
    endif
endif

PIC_FLAGS   := -fPIC
WARN_FLAGS  ?= -Wall

ifeq ($(BUILD_FLAVOR),debug)
  O_FLAGS   ?= -g3 -ggdb
else
  O_FLAGS   ?= -O3
endif

DYNAMIC_LIB_ARGS  := -shared -Bsymbolic

OUT_PLATFORM      := $(strip $(TARGET_PLATFORM))
ifeq ($(TARGET_PLATFORM),$(HOST_PLATFORM))
    ifeq ($(BUILD_32BIT),1)
        CC           := gcc -m32
        CXX          := g++ -m32
        OUT_PLATFORM := $(strip i686)
    endif
endif

STAGE_DIR         ?= $(TOPDIR)/staging/$(OUT_PLATFORM)
STAGE_LIB_DIR      = $(STAGE_DIR)/usr/lib/
STAGE_PLUGIN_DIR   = $(STAGE_LIB_DIR)/plugins/
STAGE_BIN_DIR      = $(STAGE_DIR)/usr/bin/
STAGE_ETC_DIR      = $(STAGE_DIR)/etc/
STAGE_LDCONF_DIR   = $(STAGE_DIR)/etc/ld.so.conf.d/
STAGE_SHARE_DIR    = $(STAGE_DIR)/usr/share/
STAGE_VAR_DIR      = $(STAGE_DIR)/var/

LDCONF_DIR       = $(TARGET_ROOT)etc/ld.so.conf.d/
LDCONF_FILE      = $(PROJECT_NAME).conf
LDCONF_STAGE     = $(STAGE_ETC_DIR)/ld.so.conf.d/$(LDCONF_FILE)
LDCONF_INSTALL   = $(LDCONF_DIR)/$(LDCONF_FILE)

LN_FLAGS          += -L$(STAGE_LIB_DIR)\
                     -Wl,-rpath-link=$(STAGE_LIB_DIR)

LIBPREFIX ?= lib
PLUGIN_PREFIX ?= $(LIBPREFIX)uc3d-plugin

ifeq ($(BUILD_FLAVOR),debug)
  DEF_FLAGS       += -DDEBUG -D_DEBUG
  outdir_suffix=debug
else
  outdir_suffix=release
endif

BUILD_DIR   := $(TOPDIR)/build/$(OUT_PLATFORM)
ifeq ($(DGPU),1)
    BUILD_DIR := $(BUILD_DIR)-dgpu
endif
OUTDIR      := $(BUILD_DIR).$(outdir_suffix)/$(subst $(TOPDIR),,$(realpath .))

INSTALL     ?= install -D
SHAR        ?= shar
LN          ?= ln -sf
GLC         ?= $(TOPDIR)/staging/$(HOST_PLATFORM)/usr/bin/uc3d_glc
TOUCH       ?= touch
SUDO        ?= sudo

GLC_INC     ?= $(INC_FLAGS)

