######################################################################3
ifdef SUBDIRS

ALL_SUBDIRS = \
            $(SUBDIRS)\
            $(SUBDIRS:=.objs)\
            $(SUBDIRS:=.clean)\
            $(SUBDIRS:=.cleandeps)\
            $(SUBDIRS:=.clobber)\
            $(SUBDIRS:=.stage)\
            $(SUBDIRS:=.cleantarget)\
            $(SUBDIRS:=.cleant)\

.PHONY: subdirs  $(ALL_SUBDIRS)

subdirs: $(SUBDIRS)

objs: $(SUBDIRS:=.objs)

clean: $(SUBDIRS:=.clean)

cleandeps: $(SUBDIRS:=.cleandeps)

clobber: $(SUBDIRS:=.clobber)

stage: $(SUBDIRS:=.stage)

cleantarget: $(SUBDIRS:=.cleantarget)

cleant: $(SUBDIRS:=.cleant)

$(ALL_SUBDIRS): $(PREDECESSORS)
	echo ${MAKE} "-C" $(basename $@) $(subst opt,,$(subst .,,$(suffix $@)))
	${MAKE} -C $(basename $@) $(subst opt,,$(subst .,,$(suffix $@)))

endif
######################################################################3

#include QT_rules.mk here
ifeq ($(USE_QT),1)
    QT_IBASE ?= $(TARGET_ROOT)/usr/include/$(TARGET_PLATFORM)/qt5/
    QINC_FILES = -I$(QT_IBASE) $(addprefix -I$(QT_IBASE),$(foreach f,$(QT_INCLUDE),$f))
    INC_FLAGS += $(QINC_FILES)

    LN_FLAGS += $(QT_LN_FLAGS)

    CXXFILES += $(MOC_CPP_FILES) $(QRC_CPP_FILES)
endif

ifeq ($(USE_CUDA),1)
    # CUDA code generation flags
    GENCODE_SM53 := -gencode arch=compute_53,code=sm_53
    GENCODE_SM62 := -gencode arch=compute_62,code=sm_62
    GENCODE_SM72 := -gencode arch=compute_72,code=sm_72
    GENCODE_SM_PTX := -gencode arch=compute_72,code=compute_72
#    GENCODE_FLAGS := $(GENCODE_SM53) $(GENCODE_SM62) $(GENCODE_SM72) $(GENCODE_SM_PTX)
    NVCCFLAGS := -shared -Xcompiler -fPIC
    LDFLAGS += -L$(TARGET_ROOT)/usr/local/cuda/lib64
endif

CPPFLAGS += $(DEF_FLAGS) $(INC_FLAGS) $(STD_FLAGS)
CXXFLAGS += $(O_FLAGS) $(PIC_FLAGS) $(CPPFLAGS)
LDFLAGS  += $(O_FLAGS) $(LN_FLAGS)
CFLAGS    = $(subst -std=c++17,,$(CXXFLAGS))

ifneq ($(VERSION),)
    REV := .$(VERSION)
endif

ifeq ($(UC3D_USE_COMPILED_SHADERS),1)
    CXXFILES += $(GLSL_GENERATED_CXXFILES)
endif


ifdef DYNAMIC_LIBNAME
    DYNAMIC_LIB = $(OUTDIR)/lib$(DYNAMIC_LIBNAME).so$(REV).$(BUILD_FLAVOR)
    SONAME = lib$(DYNAMIC_LIBNAME).so$(REV)
    LDFLAGS += -Wl,-soname,$(SONAME)
endif

ifdef EXEC
  LEXEC := $(EXEC)
  EXEC := $(OUTDIR)/$(EXEC)$(REV).$(BUILD_FLAVOR)
endif

ifdef PLUGIN_NAME
  PLUGIN = $(OUTDIR)/$(PLUGIN_PREFIX)-$(PLUGIN_NAME).so$(REV).$(BUILD_FLAVOR)
  SONAME = $(PLUGIN_PREFIX)-$(PLUGIN_NAME).so
  LDFLAGS += -Wl,-soname,$(SONAME)
endif

ifeq ($(USE_CUDA),1)
OBJS += $(addprefix $(OUTDIR)/,$(CXXFILES:.cpp=.o)) $(addprefix $(OUTDIR)/,$(CFILES:.c=.o)) $(addprefix $(OUTDIR)/,$(CUDA_FILES:.cu=.o))
else
OBJS += $(addprefix $(OUTDIR)/,$(CXXFILES:.cpp=.o)) $(addprefix $(OUTDIR)/,$(CFILES:.c=.o))
endif
DEPS := $(addprefix $(OUTDIR)/,$(CXXFILES:.cpp=.d))

TARGET = $(EXEC) $(DYNAMIC_LIB) $(PLUGIN)

.PHONY: default stage

default: $(TARGET) stage

#	$(Q)$(MAKE) stage

.PHONY: all-platforms all-platforms-quick all-flavors

all-flavors-quick:
	make BUILD_FLAVOR=release quick
	make BUILD_FLAVOR=debug quick

all-flavors:
	make BUILD_FLAVOR=release
	make BUILD_FLAVOR=debug

all-platforms-quick:
	$(Q)$(MAKE) ALL_PLATFORMS_TARGET=quick all-platforms

all-platforms:
ifeq ($(LINUX_PLATFORM), )
	$(error LINUX_PLATFORM is not defined!)
endif
ifeq ($(LINUX_TOOLROOT), )
	$(error LINUX_TOOLROOT is not defined!)
endif
	echo $@
	$(Q)unset TARGET_PLATFORM
	$(Q)unset TOOLROOT
	$(Q)$(MAKE) BUILD_FLAVOR=debug $(ALL_PLATFORMS_TARGET)
	$(Q)$(MAKE) BUILD_FLAVOR=release $(ALL_PLATFORMS_TARGET)
	$(Q)$(MAKE) BUILD_FLAVOR=debug TARGET_PLATFORM=$(LINUX_PLATFORM) TOOLROOT=$(LINUX_TOOLROOT) $(ALL_PLATFORMS_TARGET)
	$(Q)$(MAKE) BUILD_FLAVOR=release TARGET_PLATFORM=$(LINUX_PLATFORM) TOOLROOT=$(LINUX_TOOLROOT) $(ALL_PLATFORMS_TARGET)

objs: $(DEPS) $(OBJS)

$(DYNAMIC_LIB) : $(PREREQ) $(OBJS)
	@echo linking $(notdir $@) ...
	$(Q)$(CXX) $(LDFLAGS) $(DYNAMIC_LIB_ARGS) $(OBJS) $(LIBS) -o $@
ifeq ($(DO_STRIP),1)
	$(Q)$(STRIP) $@
endif

$(PLUGIN) : $(PREREQ) $(OBJS)
	@echo linking $(notdir $@) ...
	$(Q)$(CXX) $(LDFLAGS) $(DYNAMIC_LIB_ARGS) $(OBJS) $(LIBS) -o $@
ifeq ($(DO_STRIP),1)
	$(Q)$(STRIP) $@
endif

$(EXEC): $(PREREQ) $(OBJS)
	@echo linking $(notdir $@) ...
	$(Q)$(CXX) $(LDFLAGS) $(OBJS) $(LIBS) -o $@
ifeq ($(DO_STRIP),1)
	$(Q)$(STRIP) $@
endif

$(OUTDIR)/%.o : %.cpp
	@echo compiling $< ...
	$(Q)$(CXX) $(CXXFLAGS) -c $< -o $@

$(OUTDIR)/%.d: %.cpp
	$(Q)$(CXX) $(CPPFLAGS) -fPIC -MM $< | sed 's,\($*\)\.o[ :]*,$(OUTDIR)/\1.o: ,g' > $(subst .o,.d,$@)

$(OUTDIR)/%.o: %.c
	@echo compiling $< ...
	$(Q)$(CC) $(CFLAGS) -c $< -o $@

$(OUTDIR)/%.d: %.c
	@echo creating dependency $< ...
	$(Q)$(CC) $(subst -std=c++0x,,$(CPPFLAGS)) -MM $< | sed 's,\($*\)\.o[ :]*,$(OUTDIR)/\1.o: ,g' > $(subst .o,.d,$@)

$(OUTDIR)/glc_%.cpp : $(GLSL_FILES_DIR)%.glsl
	@echo generating cpp files from $< ...
	$(Q)$(GLC) $(GLC_INC) $? $@

ifeq ($(USE_CUDA),1)
$(OUTDIR)/%.o: %.cu
	@echo compiling $< ...
	$(Q)$(NVCC) $(CXX) $(NVCCFLAGS) $(GENCODE_FLAGS) -c $< -o $@
endif

%.glsl.h : %.glsl
	$(Q)$(GLC) -s $?

ifeq ($(USE_QT),1)

ui_%.h : %.ui
	$(Q)$(UIC) $? -o $@

moc_%.cpp: $(MOC_DIR)%.h
	$(MOC) $< > $@

qrc_%.cpp: %.qrc
	$(RCC) -name $(subst .qrc,,$<) $< -o $@

endif

$(DEPS) : | $(OUTDIR) $(MKDIRS)

$(OBJS) : | $(OUTDIR) $(MKDIRS)

$(OUTDIR) $(MKDIRS):
	$(Q)mkdir -p $@

######################################################################3

.PHONY: clean cleandeps cleant cleantarget clobber

CLEAN_FILES     += $(OBJS) $(DEPS)
CLOBBER_FILES   += $(TARGET)

cleandeps:
	@echo cleaning dependencies...
	$(Q)rm -f $(DEPS)

clean:
ifneq ($(strip $(CLEAN_FILES)),)
	@echo cleaning ...
	$(Q)rm -rf $(CLEAN_FILES)
	$(Q)$(POSTCLEAN)
endif

cleant: cleantarget

cleantarget:
ifneq ($(strip $(TARGET)),)
	@echo removing $(notdir $(TARGET))
	$(Q)rm -f $(TARGET)
endif

clobber: clean
ifneq ($(strip $(CLOBBER_FILES)),)
	@echo removing $(notdir $(CLOBBER_FILES))
	$(Q)rm -rf $(CLOBBER_FILES)
	$(Q)$(POSTCLOBBER)
endif

quick: $(PREDECESSORS)
	$(MAKE) -j $(J) core
	$(MAKE)

include $(DWMAKE)/stage.mk

-include $(DEPS)

help:
	@awk '!/^#/' $(DWMAKE)/help.txt

release:
	$(MAKE) BUILD_FLAVOR=release

debug:
	$(MAKE) BUILD_FLAVOR=debug

version:
	@echo $(VERSION)

all: release debug

ifdef PREDECESSORS

predecessors: $(PREDECESSORS)

$(PREDECESSORS):
	${MAKE} -C $(basename $@) $(subst opt,,$(subst .,,$(suffix $@)))

.PHONY: predecessors $(PREDECESSORS)

endif

