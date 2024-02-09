export ECE745_PROJECT_HOME ?= $(PWD)/../../..

GEN_TRANS_TYPE ?= wb_transaction
SEED ?= 23
CLI_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    run -all; \
					coverage attribute -name TESTNAME -value $(GEN_TRANS_TYPE);\
	 	            coverage save $(GEN_TRANS_TYPE).$(TEST_SEED).ucdb;\
                    quit -f;" 

DEBUG_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    do wave.do;\
                    run -a;"\

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile

clean: 
	rm -rf work *.wlf transcript

clean_ucdb: 
	rm -f *.ucdb

clean_coverage: 
	rm -rf covhtmlreport

comp_I2C_MB:
	vcom -cover sbcefx ../rtl/iicmb_int_pkg.vhd
	vcom -cover sbcefx ../rtl/iicmb_pkg.vhd
	vcom -cover sbcefx ../rtl/mbyte.vhd
	vcom -cover sbcefx ../rtl/mbit.vhd
	vcom -cover sbcefx ../rtl/bus_state.vhd
	vcom -cover sbcefx ../rtl/filter.vhd
	vcom -cover sbcefx ../rtl/conditioner.vhd
	vcom -cover sbcefx ../rtl/conditioner_mux.vhd
	vcom -cover sbcefx ../rtl/iicmb_m.vhd
	vcom -cover sbcefx ../rtl/regblock.vhd
	vcom -cover sbcefx ../rtl/wishbone.vhd
	vcom -cover sbcefx ../rtl/iicmb_m_wb.vhd


comp_bench: comp_ncsu_pkg comp_wb_pkg comp_i2c_pkg comp_i2cmb_env_pkg
	vlog -cover sbcefx ../testbench/top.sv

optimize:
	vopt +cover=bcefsx  +acc top -o optimized_debug_top_tb

run_cli:
	vsim  -coverage -c -sv_seed $(SEED) $(CLI_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

run_gui:
	vsim  -coverage -sv_seed $(SEED) $(DEBUG_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile optimize run_cli

merge_coverage:
	xml2ucdb -format Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 

regress:
	./regress.sh
	

view_coverage:
	vsim -viewcov ./sim_and_testplan_merged.ucdb

compile: comp_I2C_MB comp_bench optimize

simulate:
	vsim -coverage -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb 

debug: clean compile simulate 



