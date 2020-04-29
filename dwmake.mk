SHELL := /bin/bash

sinclude $(WD)/.dwmake

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

OUTDIR              := .build/$(TARGET_PLATFORM)

DEPFLAGS            = -MT $@ -MMD -MP -MF $(OUTDIR)/$*.d

ifneq ($(ARCH),$(shell uname -p))
LDFLAGS             := --sysroot=$(TARGET_ROOT) \
                       -Wl,--dynamic-linker=/lib/ld-linux-$(ARCH).so.1\
                       -L$(TARGET_LIB)\
                       -Wl,-rpath-link=$(TARGET_LIB)\
                       -Wl,-rpath-link=$(TARGET_ULIB)
endif

BUILD_MODE      ?= release
ifeq ($(BUILD_MODE),release)
  O_FLAGS       := -O3
else
  O_FLAGS       := -g3
endif

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

INC_FLAGS += $(TARGET_INCLUDES)

CXXFLAGS += $(STD_FLAGS) $(INC_FLAGS) $(DEF_FLAGS) $(O_FLAGS)

CXXFILES = $(wildcard *.cpp)

OBJS := $(addprefix $(OUTDIR)/,$(CXXFILES:.cpp=.o))

PRELINK = $(OBJS)

ifdef EXEC
  EXEC := $(OUTDIR)/$(EXEC)
  TARGET := $(EXEC)
  CLOBBER_FILES += $(EXEC) $(notdir $(EXEC))
endif

ifeq ($(TARGET),)
    $(error TARGET not defined)
endif

target: $(OUTDIR) $(PREREQUISITES) $(TARGET)

$(EXEC): $(PRELINK) 
	$(CXX) $(LDFLAGS) $(OBJS) $(LIBS) -o $@
	$(STRIP) $(EXEC)
	ln -sf $(EXEC) .

clean: 
	rm -f $(OBJS)

clobber:  clean
	rm -f $(CLOBBER_FILES)

%.o: %.cpp
$(OUTDIR)/%.o: %.cpp $(OUTDIR)/%.d | $(OUTDIR)
	$(CXX) $(DEPFLAGS) $(CXXFLAGS) $(CPPFLAGS) -c $< -o $@

$(OUTDIR) $(MKDIRS):
	mkdir -p $@

DEPFILES := $(CXXFILES:%.cpp=$(OUTDIR)/%.d)

$(DEPFILES): 

include $(wildcard $(DEPFILES))

