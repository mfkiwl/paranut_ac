library ieee;
use ieee.std_logic_1164.all;

package paranut_config is

    -- Do not edit
    constant KB : natural := 1024;
    constant MB : natural := 1024*1024;
    constant GB : natural := 1024*1024*1024;

    ------------------------------------------------------
    -- Debug options (simulation only)
    ------------------------------------------------------

    constant CFG_DBG_INSN_TRACE_CPU_MASK : integer := 16#0#;
    constant CFG_DBG_LSU_TRACE           : boolean := false;
    constant CFG_DBG_BUS_TRACE           : boolean := false;
    constant CFG_DBG_TRAM_TRACE          : boolean := false;
    constant CFG_DBG_BRAM_TRACE          : boolean := false;

    ------------------------------------------------------
    -- ParaNut options
    ------------------------------------------------------

    -- Number of CPU cores (ld)
    constant CFG_NUT_CPU_CORES_LD       : natural := 0;

    -- - For simulation, values too high (e.g. > 8MB) may result in a non-working simulation for various simulation tools
    -- - For synthesis, this must exactly match your board's main memory size
    constant CFG_NUT_MEM_SIZE           : natural := 8 * MB;

    -- Bus Interface is Little/Big Endian 
    constant CFG_NUT_LITTLE_ENDIAN      : boolean := false;

    -- Generate histograms for evaluation
    constant CFG_NUT_HISTOGRAM          : boolean := false;

    -- Do not edit
    constant CFG_NUT_CPU_CORES          : natural := 2 ** CFG_NUT_CPU_CORES_LD;

    ------------------------------------------------------
    -- MEMU
    ------------------------------------------------------

    -- Number of cache banks (ld)
    constant CFG_MEMU_CACHE_BANKS_LD    : natural range 1 to 8 := 1;
    -- Number of cache sets (ld)
    constant CFG_MEMU_CACHE_SETS_LD     : natural range 1 to 13 := 10;
    -- Number of cache ways (ld)
    constant CFG_MEMU_CACHE_WAYS_LD     : natural range 0 to 2 := 2;
    -- Number of ports per bank. Since every bank is implemented as one Block
    -- RAM, for maximum performance this should be set to the maximum number of
    -- Block RAM ports supported by the target device (i.e. 2) but can be
    -- reduced in order to save some area.
    constant CFG_MEMU_BANK_RAM_PORTS : natural range 1 to 2 := 2;

    -- 0 : random replacement, 1 : LRU replacement
    constant CFG_MEMU_CACHE_REPLACE_LRU : natural range 0 to 1 := 1;

    -- > 0: round-robin arbitration, switches every (1 << CFG_MEMU_ARBITER_METHOD) clocks
    -- < 0: pseudo-random arbitration (LFSR-based)
    constant CFG_MEMU_ARBITER_METHOD    : integer range -1 to 15 := 7;
    
    -- Do not edit
    constant CFG_MEMU_CACHE_BANKS       : natural := 2 ** CFG_MEMU_CACHE_BANKS_LD;
    constant CFG_MEMU_CACHE_SETS        : natural := 2 ** CFG_MEMU_CACHE_SETS_LD;
    constant CFG_MEMU_CACHE_WAYS        : natural := 2 ** CFG_MEMU_CACHE_WAYS_LD;
    constant CFG_MEMU_CACHE_SIZE        : natural := CFG_MEMU_CACHE_SETS * CFG_MEMU_CACHE_WAYS * CFG_MEMU_CACHE_BANKS * 4;

    ------------------------------------------------------
    -- IFU
    ------------------------------------------------------

    -- Build bit-slice implementation of IFU
    constant CFG_IFU_BS_IMPL            : boolean := false;
    -- Size of instruction buffer (must be at least 4)
    -- (Note: The normal implementation of the IFU only supports buffer sizes
    -- in powers of two. If CFG_IFU_IBUF_SIZE is not a power of two a buffer
    -- with size 2**ceil(log2(CFG_IFU_IBUF_SIZE)) will be generated
    constant CFG_IFU_IBUF_SIZE          : natural range 4 to 16 := 4;

    ------------------------------------------------------
    -- LSU
    ------------------------------------------------------

    -- Build a simple LSU with no write buffer
    constant CFG_LSU_SIMPLE             : boolean := false;
    -- Size of write buffer (ld)
    constant CFG_LSU_WBUF_SIZE_LD       : natural := 2;

    ------------------------------------------------------
    -- EXU
    ------------------------------------------------------

    -- 0 : serial shift, 1 : generic shifter, 2 barrell shifter
    constant CFG_EXU_SHIFT_IMPL         : integer range 0 to 2 := 2;
    -- Number of pipeline stages for embedded multiplier
    constant CFG_EXU_MUL_PIPE_STAGES    : integer range 1 to 5 := 3;

end package;

