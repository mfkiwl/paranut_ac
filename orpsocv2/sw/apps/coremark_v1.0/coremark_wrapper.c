void dispatch(int cpu_id)
{
}

int main(void)
{
    if (cpu_id != 0) {
        //wait_for_cpu(cpu_id-1);
    } else
		ee_printf("Running CoreMark with %d core(s)...\n", pn_get_ncpus());

    real_main(cpu_id);

    pn_sync_set(cpu_id);
    // Do not leave before all is done...
    wait_for_cpu(pn_get_ncpus()-1);

    return 0;
}
