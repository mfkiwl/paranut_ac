library ieee;
use ieee.std_logic_1164.all;

package paranut_config is

    constant CFG_DBG_ITRACE : boolean := false;
    constant CFG_DBG_WBTRACE : boolean := false;

    constant CFG_LITTLE_ENDIAN : boolean := false;

    -- Memory
    constant KB : natural := 1024;
    constant MB : natural := 1024*1024;
    constant GB : natural := 1024*1024*1024;

    constant MEM_SIZE     : natural := 8 * MB;

    -- General options
    constant CPU_CORES_LD : natural := 0;
    constant CPU_CORES    : natural := 2 ** CPU_CORES_LD;

    -- MemU
    constant CACHE_BANKS_LD : natural range 1 to 8 := 2;
    constant CACHE_BANKS    : natural := 2 ** CACHE_BANKS_LD;
    
    constant CACHE_SETS_LD  : natural range 1 to 12 := 9;
    constant CACHE_SETS     : natural := 2 ** CACHE_SETS_LD;
    
    constant CACHE_WAYS_LD  : natural range 0 to 2 := 2;
    constant CACHE_WAYS     : natural := 2 ** CACHE_WAYS_LD;

    constant CACHE_REPLACE_LRU : natural range 0 to 1 := 1; -- 0 = random replacement, 1 = LRU replacement

    constant ARBITER_METHOD : integer range -1 to 15 := 7; -- > 0: round-robin arbitration, switches every (1 << ARBITER_METHOD) clocks
                                                         -- < 0: pseudo-random arbitration (LFSR-based)
    
    constant CACHE_SIZE : natural := CACHE_SETS * CACHE_WAYS * CACHE_BANKS * 4;

    -- Integer unit options
    constant SHIFT_IMPL      : integer := 0;
    constant MUL_PIPE_STAGES : integer := 3;

end package;
