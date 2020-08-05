SHELL := /bin/bash

sinclude .dwmake

ARCH                ?= $(shell uname -p)
TARGET_ROOT         ?= /

TARGET_PLATFORM     := $(ARCH)-linux-gnu
TOOLROOT            := /usr/bin

ifneq ($(ARCH),$(shell uname -p))
    CROSSBIN := $(TOOLROOT)/$(TARGET_PLATFORM)-
endif

CC                  := $(CROSSBIN)gcc
CXX                 := $(CROSSBIN)g++
CPP                 := $(CROSSBIN)cpp
AR                  := $(CROSSBIN)ar
LD                  := $(CROSSBIN)ld
RANLIB              := $(CROSSBIN)ranlib
STRIP               := $(CROSSBIN)strip
OBJDUMP             := $(CROSSBIN)objdump

TARGET_INCLUDES     := -I$(TARGET_ROOT)/usr/include\
                       -I$(TARGET_ROOT)/usr/include/$(TARGET_PLATFORM)\
                        -I$(TARGET_ROOT)/usr/local/include

TARGET_LIB          := $(TARGET_ROOT)/lib/$(TARGET_PLATFORM)
TARGET_ULIB         := $(TARGET_ROOT)/usr/lib/$(TARGET_PLATFORM)
TARGET_LINKER       := $(TARGET_LIB)/ld-linux-$(ARCH)

CXXFLAGS            := --sysroot=$(TARGET_ROOT)

BUILDDIR            := .dwbuild
OUTDIR              := $(BUILDDIR)/$(TARGET_PLATFORM)

DEPFLAGS            = -MT $@ -MMD -MP -MF $(OUTDIR)/$*.d

ifneq ($(ARCH),$(shell uname -p))
LDFLAGS             := --sysroot=$(TARGET_ROOT) \
                       -Wl,--dynamic-linker=/lib/ld-linux-$(ARCH).so.1\
                       -L$(TARGET_LIB)\
                       -Wl,-rpath-link=$(TARGET_LIB)\
                       -Wl,-rpath-link=$(TARGET_ULIB)
endif

DYNAMIC_LIB_ARGS  := -shared -Bsymbolic


BUILD_MODE      ?= release
DO_STRIP  ?= 1
ifeq ($(BUILD_MODE),release)
  O_FLAGS       := -O3
else
  O_FLAGS       := -g3 -ggdb
  DO_STRIP  := 0
endif

PIC_FLAGS   := -fPIC
WARN_FLAGS  ?= -Wall


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

QUIET     ?= 1
ifeq ($(QUIET),1)
    Q     := @
else
    Q     :=
endif

INC_FLAGS += $(TARGET_INCLUDES)
CXXFLAGS  += $(STD_FLAGS) $(INC_FLAGS) $(DEF_FLAGS) $(O_FLAGS) $(PIC_FLAGS) $(WARN_FLAGS)
LDFLAGS   += $(O_FLAGS)
CXXFILES  ?= $(wildcard *.cpp)

PLUGIN_PREFIX ?= dwmake-plugin

ifdef ERROR_LIMIT
  ifeq ($(USE_CLANG),1)
    CXXFLAGS += -ferror-limit=$(ERROR_LIMIT)
  else
    CXXFLAGS += -fmax-errors=$(ERROR_LIMIT)
  endif
endif

OBJS := $(addprefix $(OUTDIR)/,$(CXXFILES:.cpp=.o))

ifdef SHADER_FILES
include ${DWMAKE}/spirv_defs.mk
endif

PRELINK = $(OBJS)

ifdef SUBDIRS
include $(DWMAKE)/subdirs.mk
endif

CLOBBER_FILES = $(BUILDDIR)

ifdef PLUGIN_NAME
    PLUGIN = $(OUTDIR)/lib$(PLUGIN_PREFIX)-$(strip $(PLUGIN_NAME)).so
    SONAME = lib$(PLUGIN_PREFIX)-$(strip $(PLUGIN_NAME)).so$(REV)
    LDFLAGS += -Wl,-soname,$(SONAME)
    CLOBBER_FILES += $(notdir $(PLUGIN))
endif

ifdef DYNAMIC_LIBNAME
    DYNAMIC_LIB = $(OUTDIR)/lib$(DYNAMIC_LIBNAME).so
    SONAME = lib$(DYNAMIC_LIBNAME).so$(REV)
    LDFLAGS += -Wl,-soname,$(SONAME)
    CLOBBER_FILES += $(notdir $(DYNAMIC_LIB))
endif

ifdef STATIC_LIBNAME
    STATIC_LIB = $(OUTDIR)/lib$(STATIC_LIBNAME).a
endif


ifdef EXEC
  EXEC := $(OUTDIR)/$(EXEC)
  CLOBBER_FILES += $(notdir $(EXEC))
endif

ifdef INSTALL_FILES
$(info INSTALL_FILES is ==$(INSTALL_FILES)==)
  TARGET = $(INSTALL_FILES)
else
  TARGET = $(EXEC) $(DYNAMIC_LIB) $(STATIC_LIB) $(PLUGIN)
  INSTALL_FILES ?= $(TARGET)
endif

ifeq ($(TARGET),)
  $(error TARGET not defined)
endif

target: $(PREREQUISITES) $(TARGET) stage

$(DYNAMIC_LIB) $(PLUGIN) : $(PRELINK)
	@echo linking $(notdir $@) ...
	$(Q)$(CXX) $(LDFLAGS) $(DYNAMIC_LIB_ARGS) $(OBJS) $(LIBS) -o $@
ifeq ($(DO_STRIP),1)
	$(Q)$(STRIP) $@
endif

$(STATIC_LIB) : $(PRELINK)
	@echo creating static library $(notdir $@) ...
	$(Q)ar rcs $@ $(OBJS)
	$(Q)ranlib $@
	$(Q)ln -sf $@ .

$(EXEC): $(PRELINK)
	@echo linking $(notdir $@) ...
	$(Q)$(CXX) $(LDFLAGS) $(OBJS) $(LIBS) -o $@
ifeq ($(BUILD_MODE),release)
	$(Q)$(STRIP) $(EXEC)
endif
	$(Q)ln -sf $(EXEC) .

clean:
	$(Q)echo cleaning $(OBJS)
	$(Q)rm -f $(OBJS)

clobber:  clean
	$(Q)rm -rf $(CLOBBER_FILES)

cleantarget:
	$(Q)rm -f $(TARGET)

install: $(TARGET)  $(INSTALL_FILES:=.install)

$(INSTALL_FILES:=.install):
ifdef INSTALL_LOCATION
	$(Q)echo installing $(basename $@) ...
	$(Q)[ -f $(basename $@) ] && \
        install -D $(basename $@) $(INSTALL_LOCATION)/$(notdir $(basename $@)) ||\
            $(foreach f,$(shell find $(basename $@) -type f), install -D $f $(INSTALL_LOCATION)/$f; )
endif

$(OBJS) : | $(OUTDIR)

%.o: %.cpp
$(OUTDIR)/%.o: %.cpp $(OUTDIR)/%.d | $(OUTDIR)
	@echo compiling $(notdir $<)
	$(Q)$(CXX) $(O_FLAGS) $(DEPFLAGS) $(CXXFLAGS) $(CPPFLAGS) -c $< -o $@

ifdef SPIR_V_SHADERS
include ${DWMAKE}/spirv_rules.mk
endif

$(OUTDIR) $(MKDIRS):
	$(Q)mkdir -p $@

stage:
ifdef STAGE_DIR
	@ln -sf `pwd`/$(strip $(TARGET)) $(STAGE_DIR)/$(notdir $(strip $(TARGET)))
endif
	@$(Q)$(POSTSTAGE)

DEPFILES := $(CXXFILES:%.cpp=$(OUTDIR)/%.d)

$(DEPFILES):

include $(wildcard $(DEPFILES))

