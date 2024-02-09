class wb_random_transaction extends wb_transaction;
  `ncsu_register_object(wb_random_transaction)

   rand bit [1:0] wb_addr;
   rand bit [7:0] wb_data;
   rand bit wb_we;
   rand bit op_RorW;
   rand bit wb_wait_for_irq;
   rand bit [wb_data_wid-1:0] wb_rand_data;

   function new(string name=""); 
     super.new(name);
   endfunction

   constraint C1_CMDR {
			 (wb_addr == 2'b10 && op_RorW == 1) -> wb_data inside {8'b00000001,8'b00000010,8'b00000011,8'b00000100,8'b00000101,8'b00000110,8'b00000000,8'b00000111, 8'b11111111};
			 }
   constraint C2_FSMR {
			 (wb_addr == 2'b11) -> op_RorW == 0;
			 }
   constraint C3_CSR {
			 wb_addr == 2'b00 -> wb_wait_for_irq == 1 && op_RorW == 0;
			 }

    //user defined function for conversion to string. Useful while displaying on console
    virtual function string convert2string();
        return {super.convert2string(),$sformatf("Address:0x%h Data:0x%h WE:0x%h ", wb_addr,wb_data,wb_we)};
    endfunction

    //user defined compare function to be used in scoreboard for transaction comparison
    function bit compare(wb_transaction rhs);
        return ((this.wb_addr  == rhs.wb_addr ) &&
                (this.wb_data == rhs.wb_data) &&
                (this.wb_op == rhs.wb_op) );
    endfunction

endclass
