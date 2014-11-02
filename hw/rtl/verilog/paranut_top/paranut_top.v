module paranut_top(
	// System
	clk_i, rst_i,

	// WISHBONE INTERFACE
	wb_clk_i, wb_rst_i, wb_ack_i, wb_err_i, wb_rty_i, wb_dat_i,
	wb_cyc_o, wb_adr_o, wb_stb_o, wb_we_o, wb_sel_o, wb_dat_o,
	wb_cti_o, wb_bte_o,

	// External Debug Interface
	dbg_stall_i, dbg_ewt_i,	dbg_lss_o, dbg_is_o, dbg_wp_o, dbg_bp_o,
	dbg_stb_i, dbg_we_i, dbg_adr_i, dbg_dat_i, dbg_dat_o, dbg_ack_o
	
);

`define PARANUT_OPERAND_WIDTH		32
parameter dw = `PARANUT_OPERAND_WIDTH;
parameter aw = `PARANUT_OPERAND_WIDTH;

//
// System
//
input			clk_i;
input			rst_i;

//
// WISHBONE interface
//
input			    wb_clk_i;   // clock input
input			    wb_rst_i;   // reset input
input			    wb_ack_i;   // normal termination
input			    wb_err_i;   // termination w/ error
input			    wb_rty_i;   // termination w/ retry
input	[dw-1:0]	wb_dat_i;   // input data bus
output			    wb_cyc_o;   // cycle valid output
output	[aw-1:0]	wb_adr_o;   // address bus outputs
output			    wb_stb_o;   // strobe output
output			    wb_we_o;    // indicates write transfer
output	[3:0]		wb_sel_o;   // byte select outputs
output	[dw-1:0]    wb_dat_o;   // output data bus
output	[2:0]		wb_cti_o;   // cycle type identifier
output	[1:0]		wb_bte_o;   // burst type extension

//
// External Debug Interface
//
input			    dbg_stall_i; // External Stall Input
input			    dbg_ewt_i;	 // External Watchpoint Trigger Input
output	[3:0]		dbg_lss_o;	 // External Load/Store Unit Status
output	[1:0]		dbg_is_o;	 // External Insn Fetch Status
output	[10:0]		dbg_wp_o;	 // Watchpoints Outputs
output			    dbg_bp_o;	 // Breakpoint Output
input			    dbg_stb_i;   // External Address/Data Strobe
input			    dbg_we_i;    // External Write Enable
input	[aw-1:0]	dbg_adr_i;	 // External Address Input
input	[dw-1:0]	dbg_dat_i;	 // External Data Input
output	[dw-1:0]	dbg_dat_o;	 // External Data Output
output			    dbg_ack_o;	 // External Data Acknowledge (not WB compatible)

//
// Internal wires and regs
//
   
//
// Debug port and caches/MMUs
//
wire			du_stall;

// Instantiation of ParaNut
mparanut nut(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .ack_i(wb_ack_i),
    .err_i(wb_err_i),
    .rty_i(wb_rty_i),
    .dat_i(wb_dat_i),
    .cyc_o(wb_cyc_o),
    .stb_o(wb_stb_o),
    .we_o(wb_we_o),
    .sel_o(wb_sel_o),
    .adr_o(wb_adr_o),
    .dat_o(wb_dat_o),
    .cti_o(wb_cti_o),
    .bte_o(wb_bte_o),
    .du_stall(du_stall)
);

//
// Instantiation of Debug Unit
//
or1200_du or1200_du(
	// RISC Internal Interface
	.clk(clk_i),
	.rst(rst_i),

	// DU's access to SPR unit
	.du_stall(du_stall),

	// External Debug Interface
	.dbg_stall_i(dbg_stall_i),
	.dbg_ewt_i(dbg_ewt_i),
	.dbg_lss_o(dbg_lss_o),
	.dbg_is_o(dbg_is_o),
	.dbg_wp_o(dbg_wp_o),
	.dbg_bp_o(dbg_bp_o),
	.dbg_stb_i(dbg_stb_i),
	.dbg_we_i(dbg_we_i),
	.dbg_adr_i(dbg_adr_i),
	.dbg_dat_i(dbg_dat_i),
	.dbg_dat_o(dbg_dat_o),
	.dbg_ack_o(dbg_ack_o)
);

endmodule
