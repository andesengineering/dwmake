
%.vert.spv:%.vert
	$(SPIR_V_COMPILER) $< -o $@

%.frag.spv:%.frag
	$(SPIR_V_COMPILER) $< -o $@
