ALL_SUBDIRS = \
            $(SUBDIRS)\
            $(SUBDIRS:=.clean)\
            $(SUBDIRS:=.clobber)\
            $(SUBDIRS:=.install)\

.PHONY: subdirs  $(ALL_SUBDIRS)

subdirs: $(SUBDIRS)

clean: $(SUBDIRS:=.clean)

clobber: $(SUBDIRS:=.clobber)

install: $(SUBDIRS:=.install)

$(ALL_SUBDIRS): $(PREDECESSORS)
	$(MAKE) -C $(basename $@) --makefile=$(DWMAKE)/dwmake.mk $(subst .,,$(suffix $@))


