#include <or1k-support.h>
#include <spr-defs.h>

#define SPR_GRP_PN 0xc000

#define SPR_REG_PNCPUS 0
#define SPR_REG_PNM2CAP 1
#define SPR_REG_PNCPUID 2
#define SPR_REG_PNCE 4
#define SPR_REG_PNLM 5
#define SPR_REG_PNX 8
#define SPR_REG_XID0 32

static volatile int sync = 0;

int pn_get_ncpus()
{
    return or1k_mfspr(SPR_GRP_PN+SPR_REG_PNCPUS);
}

int pn_get_cpuid()
{
    return or1k_mfspr(SPR_GRP_PN+SPR_REG_PNCPUID);
}

void wait_for_cpu(int cpu_id)
{
    while ((sync & (0x1 << cpu_id)) == 0);
}

void pn_sync_set(int cpu_id)
{
    sync |= 0x1 << cpu_id;
}

void pn_sync_unset(int cpu_id)
{
    sync &= ~(0x1 << cpu_id);
}

void pn_sync_clear()
{
    sync = 0;
}

void pn_sync_set_all()
{
    sync = 0xffffffff;
}
