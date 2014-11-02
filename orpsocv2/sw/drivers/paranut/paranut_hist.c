#include "paranut.h"
#include <or1k-support.h>
#include <spr-defs.h>

#include <stdio.h>

#define SPR_GRP_HIST 0xc800

#define SPR_REG_CTL     0
#define SPR_REG_ALU     64
#define SPR_REG_SHIFT   128
#define SPR_REG_MUL     192
#define SPR_REG_LOAD    256
#define SPR_REG_STORE   320
#define SPR_REG_JUMP    384
#define SPR_REG_OTHER   448
#define SPR_REG_IFU     512
#define SPR_REG_CLF     576
#define SPR_REG_CLWB    640
#define SPR_REG_CRHIFU  704
#define SPR_REG_CRMIFU  768
#define SPR_REG_CRHLSU  832
#define SPR_REG_CRMLSU  896
#define SPR_REG_CWHLSU  960
#define SPR_REG_CWMLSU  1024
#define SPR_REG_LSU_BUF 1088
#define SPR_REG_IFU_BUF 1152

#define MAX_CPUS 8

typedef struct statistics {
    unsigned int cnt;
    unsigned int min;
    float avg;
    unsigned int max;
    unsigned int tot;
} sstats;

static sstats alu_stats[MAX_CPUS+1];
static sstats shift_stats[MAX_CPUS+1];
static sstats mul_stats[MAX_CPUS+1];
static sstats load_stats[MAX_CPUS+1];
static sstats store_stats[MAX_CPUS+1];
static sstats jump_stats[MAX_CPUS+1];
static sstats other_stats[MAX_CPUS+1];
static sstats allinsn_stats[MAX_CPUS+1];
static sstats ifu_stats[MAX_CPUS+1];
static sstats clf_stats[MAX_CPUS+1];
static sstats clwb_stats[MAX_CPUS+1];
static sstats crhifu_stats[MAX_CPUS+1];
static sstats crmifu_stats[MAX_CPUS+1];
static sstats crhlsu_stats[MAX_CPUS+1];
static sstats crmlsu_stats[MAX_CPUS+1];
static sstats cwhlsu_stats[MAX_CPUS+1];
static sstats cwmlsu_stats[MAX_CPUS+1];

void pn_hist_enable()
{
    or1k_mtspr(SPR_GRP_HIST, 1);
}

void pn_hist_disable()
{
    or1k_mtspr(SPR_GRP_HIST, 0);
}

void fill_stats(sstats *stats, int reg_ofs)
{
   stats->cnt = or1k_mfspr(SPR_GRP_HIST+reg_ofs+64-2);
   stats->min = or1k_mfspr(SPR_GRP_HIST+reg_ofs+64-4)+1;
   stats->max = or1k_mfspr(SPR_GRP_HIST+reg_ofs+64-3)+1;
   stats->tot = or1k_mfspr(SPR_GRP_HIST+reg_ofs+64-1);
   stats->avg = (float)stats->tot/(float)stats->cnt;
}

void pn_stats_collect()
{
    int cpu_id = pn_get_cpuid();
    
    fill_stats(&alu_stats[cpu_id], SPR_REG_ALU);
    fill_stats(&shift_stats[cpu_id], SPR_REG_SHIFT);
    fill_stats(&mul_stats[cpu_id], SPR_REG_MUL);
    fill_stats(&load_stats[cpu_id], SPR_REG_LOAD);
    fill_stats(&store_stats[cpu_id], SPR_REG_STORE);
    fill_stats(&jump_stats[cpu_id], SPR_REG_JUMP);
    fill_stats(&other_stats[cpu_id], SPR_REG_OTHER);
    fill_stats(&ifu_stats[cpu_id], SPR_REG_IFU);
    fill_stats(&clf_stats[cpu_id], SPR_REG_CLF);
    fill_stats(&clwb_stats[cpu_id], SPR_REG_CLWB);
    fill_stats(&crhifu_stats[cpu_id], SPR_REG_CRHIFU);
    fill_stats(&crmifu_stats[cpu_id], SPR_REG_CRMIFU);
    fill_stats(&crhlsu_stats[cpu_id], SPR_REG_CRHLSU);
    fill_stats(&crmlsu_stats[cpu_id], SPR_REG_CRMLSU);
    fill_stats(&cwhlsu_stats[cpu_id], SPR_REG_CWHLSU);
    fill_stats(&cwmlsu_stats[cpu_id], SPR_REG_CWMLSU);
    allinsn_stats[cpu_id].tot = alu_stats[cpu_id].tot + shift_stats[cpu_id].tot + mul_stats[cpu_id].tot + load_stats[cpu_id].tot + store_stats[cpu_id].tot + jump_stats[cpu_id].tot + other_stats[cpu_id].tot;
    allinsn_stats[cpu_id].cnt = alu_stats[cpu_id].cnt + shift_stats[cpu_id].cnt + mul_stats[cpu_id].cnt + load_stats[cpu_id].cnt + store_stats[cpu_id].cnt + jump_stats[cpu_id].cnt + other_stats[cpu_id].cnt;
    allinsn_stats[cpu_id].avg = (float)allinsn_stats[cpu_id].tot/(float)allinsn_stats[cpu_id].cnt;
}

void pn_stats_print()
{
    int cpu_id = pn_get_cpuid();

    printf("(cpuid #%d) --------------------------------------------------------------\n", cpu_id);
    printf("(cpuid #%d) Performance statistics\n", cpu_id);
    printf("(cpuid #%d) %7s%11s%4s%8s%8s%12s%10s\n", cpu_id, "Event", "Count", "min", "avg", "max", "Total", "Rate");
    printf("(cpuid #%d) --------------------------------------------------------------\n", cpu_id);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "ALU"   , alu_stats[cpu_id].cnt, alu_stats[cpu_id].min, alu_stats[cpu_id].avg, alu_stats[cpu_id].max, alu_stats[cpu_id].tot, (float)alu_stats[cpu_id].tot/(float)allinsn_stats[cpu_id].tot);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "SHIFT" , shift_stats[cpu_id].cnt, shift_stats[cpu_id].min, shift_stats[cpu_id].avg, shift_stats[cpu_id].max, shift_stats[cpu_id].tot, (float)shift_stats[cpu_id].tot/(float)allinsn_stats[cpu_id].tot);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "MUL"   , mul_stats[cpu_id].cnt, mul_stats[cpu_id].min, mul_stats[cpu_id].avg, mul_stats[cpu_id].max, mul_stats[cpu_id].tot, (float)mul_stats[cpu_id].tot/(float)allinsn_stats[cpu_id].tot);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "LOAD"  , load_stats[cpu_id].cnt, load_stats[cpu_id].min, load_stats[cpu_id].avg, load_stats[cpu_id].max, load_stats[cpu_id].tot, (float)load_stats[cpu_id].tot/(float)allinsn_stats[cpu_id].tot);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "STORE" , store_stats[cpu_id].cnt, store_stats[cpu_id].min, store_stats[cpu_id].avg, store_stats[cpu_id].max, store_stats[cpu_id].tot, (float)store_stats[cpu_id].tot/(float)allinsn_stats[cpu_id].tot);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "JUMP"  , jump_stats[cpu_id].cnt, jump_stats[cpu_id].min, jump_stats[cpu_id].avg, jump_stats[cpu_id].max, jump_stats[cpu_id].tot, (float)jump_stats[cpu_id].tot/(float)allinsn_stats[cpu_id].tot);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "OTHER" , other_stats[cpu_id].cnt, other_stats[cpu_id].min, other_stats[cpu_id].avg, other_stats[cpu_id].max, other_stats[cpu_id].tot, (float)other_stats[cpu_id].tot/(float)allinsn_stats[cpu_id].tot);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u\n"      , cpu_id, "ALL"   , allinsn_stats[cpu_id].cnt, allinsn_stats[cpu_id].min, allinsn_stats[cpu_id].avg, allinsn_stats[cpu_id].max, allinsn_stats[cpu_id].tot);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u\n"      , cpu_id, "IFU"   , ifu_stats[cpu_id].cnt, ifu_stats[cpu_id].min, ifu_stats[cpu_id].avg, ifu_stats[cpu_id].max, ifu_stats[cpu_id].tot);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "CRHIFU", crhifu_stats[cpu_id].cnt, crhifu_stats[cpu_id].min, crhifu_stats[cpu_id].avg, crhifu_stats[cpu_id].max, crhifu_stats[cpu_id].tot, (float)crhifu_stats[cpu_id].cnt/(float)ifu_stats[cpu_id].cnt);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "CRMIFU", crmifu_stats[cpu_id].cnt, crmifu_stats[cpu_id].min, crmifu_stats[cpu_id].avg, crmifu_stats[cpu_id].max, crmifu_stats[cpu_id].tot, (float)crmifu_stats[cpu_id].cnt/(float)ifu_stats[cpu_id].cnt);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "CRHLSU", crhlsu_stats[cpu_id].cnt, crhlsu_stats[cpu_id].min, crhlsu_stats[cpu_id].avg, crhlsu_stats[cpu_id].max, crhlsu_stats[cpu_id].tot, (float)crhlsu_stats[cpu_id].cnt/(float)load_stats[cpu_id].cnt);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "CRMLSU", crmlsu_stats[cpu_id].cnt, crmlsu_stats[cpu_id].min, crmlsu_stats[cpu_id].avg, crmlsu_stats[cpu_id].max, crmlsu_stats[cpu_id].tot, (float)crmlsu_stats[cpu_id].cnt/(float)load_stats[cpu_id].cnt);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "CWHLSU", cwhlsu_stats[cpu_id].cnt, cwhlsu_stats[cpu_id].min, cwhlsu_stats[cpu_id].avg, cwhlsu_stats[cpu_id].max, cwhlsu_stats[cpu_id].tot, (float)cwhlsu_stats[cpu_id].cnt/(float)store_stats[cpu_id].cnt);
    printf("(cpuid #%d) %7s%11u%4u%8.2f%8u%12u%10.5f\n", cpu_id, "CWMLSU", cwmlsu_stats[cpu_id].cnt, cwmlsu_stats[cpu_id].min, cwmlsu_stats[cpu_id].avg, cwmlsu_stats[cpu_id].max, cwmlsu_stats[cpu_id].tot, (float)cwmlsu_stats[cpu_id].cnt/(float)store_stats[cpu_id].cnt);
}

void fill_global_stats(sstats *stats)
{
    unsigned int i, min, max, avg;
    int n_cpus = pn_get_ncpus();

    min = 0xfffffff;
    max = 0;
    for (i = 0; i < n_cpus; i++) {
        if (stats[i].min < min)
            min = stats[i].min;
        if (stats[i].max > max)
            max = stats[i].max;
    }
    stats[MAX_CPUS].min = min;
    stats[MAX_CPUS].max = max;

    for (i = 0; i < n_cpus; i++) {
        stats[MAX_CPUS].tot += stats[i].tot;
        stats[MAX_CPUS].cnt += stats[i].cnt;
    }
    stats[MAX_CPUS].avg = (float)stats[MAX_CPUS].tot/(float)stats[MAX_CPUS].cnt;
}

void pn_global_stats_collect()
{
    fill_global_stats(alu_stats);
    fill_global_stats(shift_stats);
    fill_global_stats(mul_stats);
    fill_global_stats(load_stats);
    fill_global_stats(store_stats);
    fill_global_stats(jump_stats);
    fill_global_stats(other_stats);
    fill_global_stats(ifu_stats);
    fill_global_stats(clf_stats);
    fill_global_stats(clwb_stats);
    fill_global_stats(crhifu_stats);
    fill_global_stats(crmifu_stats);
    fill_global_stats(crhlsu_stats);
    fill_global_stats(crmlsu_stats);
    fill_global_stats(cwhlsu_stats);
    fill_global_stats(cwmlsu_stats);
    allinsn_stats[MAX_CPUS].tot = alu_stats[MAX_CPUS].tot + shift_stats[MAX_CPUS].tot + mul_stats[MAX_CPUS].tot + load_stats[MAX_CPUS].tot + store_stats[MAX_CPUS].tot + jump_stats[MAX_CPUS].tot + other_stats[MAX_CPUS].tot;
    allinsn_stats[MAX_CPUS].cnt = alu_stats[MAX_CPUS].cnt + shift_stats[MAX_CPUS].cnt + mul_stats[MAX_CPUS].cnt + load_stats[MAX_CPUS].cnt + store_stats[MAX_CPUS].cnt + jump_stats[MAX_CPUS].cnt + other_stats[MAX_CPUS].cnt;
    allinsn_stats[MAX_CPUS].avg = (float)allinsn_stats[MAX_CPUS].tot/(float)allinsn_stats[MAX_CPUS].cnt;
}

void pn_global_stats_print()
{
    printf("( global ) --------------------------------------------------------------\n");
    printf("( global ) Global performance statistics\n");
    printf("( global ) %7s%11s%4s%8s%8s%12s%10s\n", "Event", "Count", "min", "avg", "max", "Total", "Rate");
    printf("( global ) --------------------------------------------------------------\n");
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "ALU"   , alu_stats[MAX_CPUS].cnt, alu_stats[MAX_CPUS].min, alu_stats[MAX_CPUS].avg, alu_stats[MAX_CPUS].max, alu_stats[MAX_CPUS].tot, (float)alu_stats[MAX_CPUS].tot/(float)allinsn_stats[MAX_CPUS].tot);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "SHIFT" , shift_stats[MAX_CPUS].cnt, shift_stats[MAX_CPUS].min, shift_stats[MAX_CPUS].avg, shift_stats[MAX_CPUS].max, shift_stats[MAX_CPUS].tot, (float)shift_stats[MAX_CPUS].tot/(float)allinsn_stats[MAX_CPUS].tot);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "MUL"   , mul_stats[MAX_CPUS].cnt, mul_stats[MAX_CPUS].min, mul_stats[MAX_CPUS].avg, mul_stats[MAX_CPUS].max, mul_stats[MAX_CPUS].tot, (float)mul_stats[MAX_CPUS].tot/(float)allinsn_stats[MAX_CPUS].tot);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "LOAD"  , load_stats[MAX_CPUS].cnt, load_stats[MAX_CPUS].min, load_stats[MAX_CPUS].avg, load_stats[MAX_CPUS].max, load_stats[MAX_CPUS].tot, (float)load_stats[MAX_CPUS].tot/(float)allinsn_stats[MAX_CPUS].tot);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "STORE" , store_stats[MAX_CPUS].cnt, store_stats[MAX_CPUS].min, store_stats[MAX_CPUS].avg, store_stats[MAX_CPUS].max, store_stats[MAX_CPUS].tot, (float)store_stats[MAX_CPUS].tot/(float)allinsn_stats[MAX_CPUS].tot);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "JUMP"  , jump_stats[MAX_CPUS].cnt, jump_stats[MAX_CPUS].min, jump_stats[MAX_CPUS].avg, jump_stats[MAX_CPUS].max, jump_stats[MAX_CPUS].tot, (float)jump_stats[MAX_CPUS].tot/(float)allinsn_stats[MAX_CPUS].tot);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "OTHER" , other_stats[MAX_CPUS].cnt, other_stats[MAX_CPUS].min, other_stats[MAX_CPUS].avg, other_stats[MAX_CPUS].max, other_stats[MAX_CPUS].tot, (float)other_stats[MAX_CPUS].tot/(float)allinsn_stats[MAX_CPUS].tot);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u\n"      , "ALL"   , allinsn_stats[MAX_CPUS].cnt, allinsn_stats[MAX_CPUS].min, allinsn_stats[MAX_CPUS].avg, allinsn_stats[MAX_CPUS].max, allinsn_stats[MAX_CPUS].tot);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u\n"      , "IFU"   , ifu_stats[MAX_CPUS].cnt, ifu_stats[MAX_CPUS].min, ifu_stats[MAX_CPUS].avg, ifu_stats[MAX_CPUS].max, ifu_stats[MAX_CPUS].tot);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "CRHIFU", crhifu_stats[MAX_CPUS].cnt, crhifu_stats[MAX_CPUS].min, crhifu_stats[MAX_CPUS].avg, crhifu_stats[MAX_CPUS].max, crhifu_stats[MAX_CPUS].tot, (float)crhifu_stats[MAX_CPUS].cnt/(float)ifu_stats[MAX_CPUS].cnt);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "CRMIFU", crmifu_stats[MAX_CPUS].cnt, crmifu_stats[MAX_CPUS].min, crmifu_stats[MAX_CPUS].avg, crmifu_stats[MAX_CPUS].max, crmifu_stats[MAX_CPUS].tot, (float)crmifu_stats[MAX_CPUS].cnt/(float)ifu_stats[MAX_CPUS].cnt);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "CRHLSU", crhlsu_stats[MAX_CPUS].cnt, crhlsu_stats[MAX_CPUS].min, crhlsu_stats[MAX_CPUS].avg, crhlsu_stats[MAX_CPUS].max, crhlsu_stats[MAX_CPUS].tot, (float)crhlsu_stats[MAX_CPUS].cnt/(float)load_stats[MAX_CPUS].cnt);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "CRMLSU", crmlsu_stats[MAX_CPUS].cnt, crmlsu_stats[MAX_CPUS].min, crmlsu_stats[MAX_CPUS].avg, crmlsu_stats[MAX_CPUS].max, crmlsu_stats[MAX_CPUS].tot, (float)crmlsu_stats[MAX_CPUS].cnt/(float)load_stats[MAX_CPUS].cnt);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "CWHLSU", cwhlsu_stats[MAX_CPUS].cnt, cwhlsu_stats[MAX_CPUS].min, cwhlsu_stats[MAX_CPUS].avg, cwhlsu_stats[MAX_CPUS].max, cwhlsu_stats[MAX_CPUS].tot, (float)cwhlsu_stats[MAX_CPUS].cnt/(float)store_stats[MAX_CPUS].cnt);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u%10.5f\n", "CWMLSU", cwmlsu_stats[MAX_CPUS].cnt, cwmlsu_stats[MAX_CPUS].min, cwmlsu_stats[MAX_CPUS].avg, cwmlsu_stats[MAX_CPUS].max, cwmlsu_stats[MAX_CPUS].tot, (float)cwmlsu_stats[MAX_CPUS].cnt/(float)store_stats[MAX_CPUS].cnt);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u\n"      , "CLF"   , clf_stats[0].cnt, clf_stats[0].min, clf_stats[0].avg, clf_stats[0].max, clf_stats[0].tot);
    printf("( global ) %7s%11u%4u%8.2f%8u%12u\n"      , "CLWB"  , clwb_stats[0].cnt, clwb_stats[0].min, clwb_stats[0].avg, clwb_stats[0].max, clwb_stats[0].tot);
}

void print_entry(int cpu_id, int hist_size, int reg_ofs, const char *descr)
{
    int i;
    for (i = 0; i < hist_size; i++) {
        printf("(cpuid #%d) %s[%2d]      : %d\n", cpu_id, descr, i+1, or1k_mfspr(SPR_GRP_HIST+reg_ofs+i));
    }
}

void pn_hist_print()
{
    int i;

    int cpu_id = pn_get_cpuid();

    //print_entry(cpu_id, 4, SPR_REG_ALU, "insn ALU");
    //print_entry(cpu_id, 4, SPR_REG_SHIFT, "insn SHIFT");
    //print_entry(cpu_id, 8, SPR_REG_MUL, "insn MUL");
    print_entry(cpu_id, 32, SPR_REG_LOAD, "insn LOAD");
    print_entry(cpu_id, 32, SPR_REG_STORE, "insn STORE");
    //print_entry(cpu_id, 2, SPR_REG_JUMP, "insn JUMP");
    //print_entry(cpu_id, 3, SPR_REG_OTHER, "insn OTHER");
    print_entry(cpu_id, 32, SPR_REG_IFU, "IFU");
    //print_entry(cpu_id, 32, SPR_REG_CLF, "CLF");
    //print_entry(cpu_id, 32, SPR_REG_CLWB, "CLWB");
    print_entry(cpu_id, 32, SPR_REG_CRHIFU, "CRHIFU");
    print_entry(cpu_id, 32, SPR_REG_CRMIFU, "CRMIFU");
    print_entry(cpu_id, 32, SPR_REG_CRHLSU, "CRHLSU");
    print_entry(cpu_id, 32, SPR_REG_CRMLSU, "CRMLSU");
    print_entry(cpu_id, 32, SPR_REG_CWHLSU, "CWHLSU");
    print_entry(cpu_id, 32, SPR_REG_CWMLSU, "CWMLSU");

    //for (i = 0; i < 16; i++) {
    //    printf("(cpuid #%d) LSU fill wbuf[%d]  : %d\n", cpu_id, i, or1k_mfspr(SPR_GRP_HIST+SPR_REG_LSU_BUF+i));
    //}
    //printf("(cpuid #%d) LSU wbuf full hits: %d\n", cpu_id, or1k_mfspr(SPR_GRP_HIST+SPR_REG_LSU_BUF+16));
    //printf("(cpuid #%d) LSU wbuf part hits: %d\n", cpu_id, or1k_mfspr(SPR_GRP_HIST+SPR_REG_LSU_BUF+16+1));

    //for (i = 0; i < 16; i++) {
    //    printf("(cpuid #%d) IFU fill ibuf[%d]  : %d\n", cpu_id, i, or1k_mfspr(SPR_GRP_HIST+SPR_REG_IFU_BUF+i));
    //}

}


