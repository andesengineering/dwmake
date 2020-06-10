# For staging, the STAGE_FILES variable will have the format
#   <source files>, <destination directory>, [ <permisions>, ] [ <ownership ] :
# e.g.
#   STAGE_FILES += $(EXECUTABLES), $(STAGE_EXEC_DIR), +rx,nvidia:
#
# This approach allows customization of stage sources and stage directories
# and specification of multiple tuples.
#  EXECUTABLES, DYNAMIC_LIBRARY, PLUGIN and UNIT_TEST will predefine STAGE_FILES
# but local Makefiles may append by specifying
#    STAGE_FILES += $(MY_FILES), $(MY_DIRECTORY), +rw, nvidia:
#
# Note each line should end with a colon (':').  While not needed for
# single line STAGE_FILE definitions, subsequent concatenizations of the
# variable depend on it.

STAGEDIRS := \
             $(STAGE_LIB_DIR)\
             $(STAGE_BIN_DIR)\
             $(STAGE_PLUGIN_DIR)\
             $(STAGE_ETC_DIR)\
             $(STAGE_LDCONF_DIR)\
             $(STAGE_SHARE_DIR)\
             $(STAGE_VAR_DIR)\


comma := ,

.PHONY: stage stage_files

stage: $(STAGEDIRS) $(DYNAMIC_LIB:=.stage) $(EXEC:=.stage) $(PLUGIN:=.stage)  stage_files
	$(Q) $(POSTSTAGE)


$(DYNAMIC_LIB:=.stage):
	$(eval $@_SRC := $(subst .stage,,$@))
	$(eval $@_DST := $(STAGE_LIB_DIR)/$(notdir $($@_SRC)))
	@echo staging $($@_DST)
	$(Q) rm -f $(basename $($@_DST)).*
	$(Q)$(INSTALL) $($@_SRC) $($@_DST)
	$(Q)$(LN) $(SONAME) $(STAGE_LIB_DIR)/$(subst $(REV),,$(SONAME))
	$(Q)$(LN) $(notdir $($@_DST)) $(STAGE_LIB_DIR)/$(SONAME)

$(EXEC:=.stage):
	$(eval $@_SRC := $(subst .stage,,$@))
	$(eval $@_DST := $(STAGE_BIN_DIR)/$(notdir $($@_SRC)))
	@echo staging $($@_DST)
	$(Q) $(INSTALL) $($@_SRC) $($@_DST)
	@$(Q) $(LN) $(notdir $($@_DST)) $(subst $(REV).$(BUILD_FLAVOR),,$($@_DST))

$(PLUGIN:=.stage):
	$(eval $@_SRC := $(subst .stage,,$@))
	$(eval $@_DST := $(STAGE_PLUGIN_DIR)/$(notdir $($@_SRC)))
	@echo staging $($@_DST)
	$(Q) rm -f $(basename $($@_DST)).*
	$(Q)$(INSTALL) $($@_SRC) $($@_DST)
	$(Q)echo LINK $(notdir $($@_DST)) $(STAGE_PLUGIN_DIR)/$(SONAME)
	$(Q)$(LN) $(notdir $($@_DST)) $(STAGE_PLUGIN_DIR)/$(SONAME)

cleanstaging:
	$(Q)LIB_DIR=$(STAGE_LIB_DIR) \
        VERSION=$(VERSION) \
        BUILD_DIR=$(BUILD_DIR).$(outdir_suffix)\
        TOP_DIR=$(TOPDIR)\
        $(DWMAKE)/scripts/cleanstaging.sh


stage_files:
	$(Q)[ -z "$(STAGE_FILES)" ] || echo staging $(notdir $(firstword $(subst $(comma),,$(STAGE_FILES))))
	@a() { array=( "`echo $$1 | cut -f1 -d','`" "`echo $$1 | cut -f2 -d','`" "`echo $$1 | cut -f3 -d','`" "`echo $$1 | cut -f4 -d','`" );\
    if [ ! -z "$${array[2]}" ]; then\
        if [ ! -z "$${array[3]}" ]; then\
            for f in $${array[0]}; do\
               $(SUDO) $(INSTALL) -D $${f} -m $${array[2]} -o $${array[3]} $${array[1]}/`basename $${f}`; \
             done\
        else\
            for f in $${array[0]}; do\
                $(SUDO) $(INSTALL) -D $${f} -m $${array[2]} $${array[1]}/`basename $${f}`;\
            done\
        fi\
    else\
        for f in $${array[0]}; do\
            $(SUDO) $(INSTALL) -D $${f} $${array[1]}/`basename $${f}`;\
       done\
    fi };\
        b() { N=1; while [ 1 ]; do S=`echo $$1|cut -f$${N} -d':'`; [ -z "$${S}" ] && break;  a "$${S}" ; let N++; done }; b "$(STAGE_FILES)"


$(STAGEDIRS):
	mkdir -p $@


