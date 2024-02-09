class wb_agent extends ncsu_component#(.T(wb_transaction));

  wb_configuration wb_config;
  wb_driver        wb_drv;
  wb_monitor       wb_mon;
  wb_coverage      coverage;
  ncsu_component #(T) subscribers[$];
  virtual wb_if#(.ADDR_WIDTH(wb_addr_wid),.DATA_WIDTH(wb_data_wid)) wb_bus;

  
  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    if ( !(ncsu_config_db#(virtual wb_if#(.ADDR_WIDTH(wb_addr_wid),.DATA_WIDTH(wb_data_wid)))::get(get_full_name(), this.wb_bus))) begin;
      $display("wb_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
      //$finish;
      ncsu_fatal("wb_agent::new()",$sformatf("ncsu_config_db::get() call failed"));
    end
  endfunction


  function void set_configuration(wb_configuration cfg);
    wb_config = cfg;
  endfunction

  virtual function void build();
    wb_drv = new("wb_drv",this);
    wb_drv.set_configuration(wb_config);
    wb_drv.build();
    wb_drv.wb_bus = this.wb_bus;
    //if ( wb_config.collect_coverage) begin
      coverage = new("coverage",this);
      coverage.set_configuration(wb_config);
      coverage.build();
      connect_subscriber(coverage);
    //end
    wb_mon = new("wb_mon",this);
    wb_mon.set_configuration(wb_config);
    wb_mon.set_agent(this);
    //wb_mon.enable_transaction_viewing = 1;
    wb_mon.build();
    wb_mon.wb_bus = this.wb_bus;
  endfunction

  virtual function void nb_put(T trans);
    foreach (subscribers[i]) subscribers[i].nb_put(trans);
  endfunction

  virtual task bl_put(T trans);
    wb_drv.bl_put(trans);
  endtask

//virtual task bl_put_ref(ref T trans);
//	wb_drv.bl_put_ref(trans);
//endtask

  //virtual task wait_for_interrupt();
  //	wb_drv.wait_for_interrupt();
  //endtask

  virtual function void connect_subscriber(ncsu_component#(T) subscriber);
    subscribers.push_back(subscriber);
  endfunction

  virtual task run();
     fork wb_mon.run(); join_none
  endtask

endclass
