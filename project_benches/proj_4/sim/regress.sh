
make clean_ucdb
make clean_coverage
make cli GEN_TRANS_TYPE=wb_transaction
make run_cli GEN_TRANS_TYPE =wb_random_transaction TEST_SEED=51
#make run_cli GEN_TRANS_TYPE=i2c_generator_register_testing
#make run_cli GEN_TRANS_TYPE =i2cmb_generator_random TEST_SEED=100
make merge_coverage
make view_coverage
