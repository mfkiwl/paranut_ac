export
SCRIPTS_DIR=../../../../bin
ENTITY_NAME=or1200_top
WORKLIB=work
#NEED_UNISIM=1

VHDL_SRC_PATH=../../../../../orpsocv2/rtl/verilog/or1200
# Synthesis...
XST_MODULE_SRC = $(ENTITY_NAME).v or1200_defines.v or1200_alu.v or1200_amultp2_32x32.v or1200_cfgr.v or1200_cpu.v or1200_ctrl.v or1200_dc_fsm.v or1200_dc_ram.v or1200_dc_tag.v or1200_dc_top.v or1200_dmmu_tlb.v or1200_dmmu_top.v or1200_dpram_256x32.v or1200_dpram_32x32.v or1200_dpram.v or1200_du.v or1200_except.v or1200_fpu_addsub.v or1200_fpu_arith.v or1200_fpu_div.v or1200_fpu_fcmp.v or1200_fpu_intfloat_conv_except.v or1200_fpu_intfloat_conv.v or1200_fpu_mul.v or1200_fpu_post_norm_addsub.v or1200_fpu_post_norm_div.v or1200_fpu_post_norm_intfloat_conv.v or1200_fpu_post_norm_mul.v or1200_fpu_pre_norm_addsub.v or1200_fpu_pre_norm_div.v or1200_fpu_pre_norm_mul.v or1200_fpu.v or1200_freeze.v or1200_genpc.v or1200_gmultp2_32x32.v or1200_ic_fsm.v or1200_ic_ram.v or1200_ic_tag.v or1200_ic_top.v or1200_if.v or1200_immu_tlb.v or1200_immu_top.v or1200_iwb_biu.v or1200_lsu.v or1200_mem2reg.v or1200_mult_mac.v or1200_operandmuxes.v or1200_pic.v or1200_pm.v or1200_qmem_top.v or1200_reg2mem.v or1200_rfram_generic.v or1200_rf.v or1200_sb_fifo.v or1200_sb.v or1200_spram_1024x32_bw.v or1200_spram_1024x32.v or1200_spram_1024x8.v or1200_spram_128x32.v or1200_spram_2048x32_bw.v or1200_spram_2048x32.v or1200_spram_2048x8.v or1200_spram_256x21.v or1200_spram_32_bw.v or1200_spram_32x24.v or1200_spram_512x20.v or1200_spram_64x14.v or1200_spram_64x22.v or1200_spram_64x24.v or1200_spram.v or1200_sprs.v or1200_top.v or1200_tpram_32x32.v or1200_tt.v or1200_wb_biu.v or1200_wbmux.v or1200_xcv_ram32x8d.v

IOBUF="no"
XILINX_DEVICE_PART=xc5vlx110t-ff1136-1
#XILINX_DEVICE_PART=xc3s700a-fg484-4

################################################################################
include $(SCRIPTS_DIR)/Makefile.inc
