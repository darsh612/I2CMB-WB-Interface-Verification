class i2cmb_generator_register_test extends i2cmb_generator;
`ncsu_register_object(i2cmb_generator_register_test)

bit [7:0] reset_value[reg_off];
bit [7:0] mask_value[reg_off]; // access permission of each register

function new(string name="", ncsu_component_base parent=null);
	super.new(name, parent);

	reset_value[CSR] = 8'h00;
	reset_value[DPR] = 8'h00;
	reset_value[CMDR] = 8'h80;
	reset_value[FSMR] = 8'h00;
	// access permission of each register
	mask_value[CSR] = 8'hc0;
	mask_value[DPR] = 8'h00; // !!! refer to description in line 52
	mask_value[CMDR] = 8'h17;
	// write 8'h07 to CMDR will assert error bit( bit offset 4).
	// Thus I add error bit into CMDR mask to simplify testing logic.
	mask_value[FSMR] = 8'h00;

endfunction

virtual task run();
    for(int i=3; i>=0 ;i--)begin
        automatic reg_off addr_ofst = reg_off'(i);
        super.wb_agent.bl_put(trans_read[addr_ofst]);
        assert(trans_read[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_read[addr_ofst].wb_data);
    	else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_read[addr_ofst].wb_data);
    end
    void'(trans_write[CSR].set_data( 8'b10000000 | 8'b01000000));
	super.wb_agent.bl_put(trans_write[CSR]);

    for(int i=3; i>=0 ;i--)begin
        automatic reg_off addr_ofst = reg_off'(i);
        super.wb_agent.bl_put(trans_read[addr_ofst]);
        if(addr_ofst == CSR)begin
            assert(trans_read[addr_ofst].wb_data == mask_value[CSR] )  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[reg_off'(addr_ofst)], trans_read[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} INCORRECT :%b", map_reg_ofst_name[reg_off'(addr_ofst)],trans_read[addr_ofst].wb_data);
        end else begin
            assert(trans_read[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[reg_off'(addr_ofst)], trans_read[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[reg_off'(addr_ofst)],trans_read[addr_ofst].wb_data);
        end
    end

    void'(trans_write[CSR].set_data( (~(8'b10000000)) & (~(8'b01000000)) ));
    super.wb_agent.bl_put(trans_write[CSR]);

    for(int i=3; i>=0 ;i--)begin
        automatic reg_off addr_ofst = reg_off'(i);
        void'(trans_write[addr_ofst].set_data( 8'hff ));
        super.wb_agent.bl_put(trans_write[addr_ofst]);
        super.wb_agent.bl_put(trans_read[addr_ofst]);
        if(addr_ofst == CSR)begin
            assert(trans_read[addr_ofst].wb_data == mask_value[CSR] )  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_read[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_read[addr_ofst].wb_data);
        end else begin
            assert(trans_read[addr_ofst].wb_data == reset_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_read[addr_ofst].wb_data);
            else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_read[addr_ofst].wb_data);
        end
    end

    void'(trans_write[CSR].set_data( 8'b10000000 | 8'b01000000));
    super.wb_agent.bl_put(trans_write[CSR]);

    for(int i=3; i>=0 ;i--)begin
        automatic reg_off addr_ofst = reg_off'(i);
        void'(trans_write[addr_ofst].set_data( 8'hff ));
        super.wb_agent.bl_put(trans_write[addr_ofst]);

        super.wb_agent.bl_put(trans_read[addr_ofst]);
        assert(trans_read[addr_ofst].wb_data == mask_value[addr_ofst])  $display("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b CORRECT", map_reg_ofst_name[addr_ofst], trans_read[addr_ofst].wb_data);
        else $fatal("{%s REGISTER DEFAULT VALUE AFTER RESET CORE} : %b INCORRECT", map_reg_ofst_name[addr_ofst],trans_read[addr_ofst].wb_data);
    end

    for(int i=0; i<4 ;i++)begin
        automatic reg_off addr_ofst_1 = reg_off'(i);
        automatic reg_off addr_ofst_2;

        void'(trans_write[addr_ofst_1].set_data( 8'hff ));
        super.wb_agent.bl_put(trans_write[addr_ofst_1]);
        // test order: CSR(0) -> DPR(1) -> CMDR(2) -> FSMR(3)
        for(int k=0; k<4 ;k++)begin
            if( k == i ) continue;
            addr_ofst_2 = reg_off'(k);
            assert(trans_read[addr_ofst_2].wb_data == mask_value[addr_ofst_2])  $display("{%s UNCHANGED WHEN WRITING TO %s} PASSED ", map_reg_ofst_name[addr_ofst_2],map_reg_ofst_name[addr_ofst_1] );
            else $fatal("{%s ALIASED WHEN WRITING TO %s} FAILED ", map_reg_ofst_name[addr_ofst_2],map_reg_ofst_name[addr_ofst_1] );
        end
    end

    $display("--------------------------------------------------------");
    $display("        REGISTER BLOCK TEST PASS          ");
    $display("--------------------------------------------------------");

endtask




endclass