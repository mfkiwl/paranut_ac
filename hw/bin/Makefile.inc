export
default: ghdl-cl

VPATH = $(VHDL_SRC_PATH): \
        $(WORKLIB): \
		$(UNISIM): \
		$(XCL)

# ghdl simulation
ghdl-%:
	@$(MAKE) -f $(SCRIPTS_DIR)/ghdl.mk $@
# xilinx isim simulation
isim-%:
	@$(MAKE) -f $(SCRIPTS_DIR)/isim.mk $@
# xilinx xst synthesis
xst-%:
	@$(MAKE) -f $(SCRIPTS_DIR)/xst.mk $@

##### Clean #####
clean:
	@$(MAKE) -f $(SCRIPTS_DIR)/ghdl.mk ghdl-$@
	@$(MAKE) -f $(SCRIPTS_DIR)/isim.mk isim-$@
	@$(MAKE) -f $(SCRIPTS_DIR)/xst.mk xst-$@
