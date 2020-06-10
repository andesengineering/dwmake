
UI_GENERATED_HFILES =  $(notdir $(addsuffix .h,$(addprefix ui_,$(basename $(notdir $(UI_FILES))))))
PREREQ += $(UI_GENERATED_HFILES)
CLOBBER_FILES += $(UI_GENERATED_FILES)

MOC_CPP_FILES = $(foreach f,$(MOC_FILES),moc_$(subst .h,.cpp,$(notdir $(f))))
QRC_CPP_FILES = $(foreach f,$(QRC_FILES),qrc_$(subst .qrc,.cpp,$(f)))
CLOBBER_FILES += $(MOC_CPP_FILES) $(QRC_CPP_FILES)

UIC ?= $(shell which uic)
MOC ?= $(shell which moc)
RCC ?= $(shell which rcc)

ifneq ($(QT_SELECT),)
    UIC := QT_SELECT=$(QT_SELECT) $(UIC)
    MOC := QT_SELECT=$(QT_SELECT) $(MOC)
    RCC := QT_SELECT=$(QT_SELECT) $(RCC)
endif
