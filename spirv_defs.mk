ifeq ($(VULKAN_SDK),)
    $(error VULKAN_SDK environmental variable not defined.  Please run setup-env.sh in the Vulkan SDK package available from https://vulkan.lunarg.com/)
endif

SPIR_V_COMPILER := glslc

SPIR_V_SHADERS = $(foreach f,$(SHADER_FILES),$(addsuffix .spv,$(f)))

PREREQUISITES += $(SPIR_V_SHADERS)
CLOBBER_FILES += $(SPIR_V_SHADERS)


