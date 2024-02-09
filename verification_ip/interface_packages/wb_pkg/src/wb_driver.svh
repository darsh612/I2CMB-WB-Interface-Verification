class wb_driver extends ncsu_component#(.T(wb_transaction));

  virtual wb_if#(.ADDR_WIDTH(wb_addr_wid),.DATA_WIDTH(wb_data_wid)) wb_bus;
  wb_configuration wb_config;
  wb_transaction wb_trans;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(wb_configuration cfg);
    wb_config = cfg;
  endfunction

  virtual task bl_put(T trans);
    //wb_bus.wait_for_reset();
    if(trans.wb_op == WB_Write) begin
        wb_bus.master_write(trans.wb_addr,trans.get_data_0());
      end
    if(trans.wb_op == WB_Read) begin
      wb_bus.master_read(trans.wb_addr,trans.wb_data);
    end
    if((trans.wb_op == WB_Write) && (trans.wb_addr == CMDR)) begin
      //$display("aaaaa");
      //$display("%d", trans.wb_addr);
      wb_bus.wait_for_interrupt();
      //$display("bbbbb");
      wb_bus.master_read(CMDR, trans.cmd_data);
      //$display("Contents of CMDR is %b", trans.cmd_data);
    end
  endtask

  //virtual task bl_put_ref(ref T trans);
  //    //ncsu_info("wb_driver::bl_put() ",{ " ", trans.convert2string()},NCSU_NONE);
  //    if(trans.wb_op==WB_Write)    wb_bus.master_write(trans.wb_addr, trans.get_data_0());
  //    if(trans.wb_op==WB_Read)     wb_bus.master_read(trans.wb_addr, trans.wb_data);
  //	  if((trans.wb_op==WB_Write) && (trans.wb_addr==CMDR) && (trans.wb_data[2:0]!= CMDR_NOT_USED)) begin
  //        wb_bus.wait_for_interrupt();
  //        wb_bus.master_read(CMDR, trans.cmd_data);
  //    end
  //    //ncsu_info("wb_driver::bl_put() ",{ " END ", trans.convert2string()},NCSU_NONE);
  //endtask

  //virtual task wait_for_interrupt();
  //    wb_bus.wait_for_interrupt();
  //    //wb_bus.master_read(CMDR,trans.cmd_data);
  //    //$display("Contents of CMDR is %b", trans.cmd_data);
  //endtask


endclass