class wb_monitor extends ncsu_component#(.T(wb_transaction));

  wb_configuration  wb_config;
  virtual wb_if#(.ADDR_WIDTH(wb_addr_wid),.DATA_WIDTH(wb_data_wid)) wb_bus;

  T monitored_trans;
  T wait_irq_trans;

  ncsu_component #(T) agent;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(wb_configuration cfg);
    wb_config = cfg;
  endfunction

  function void set_agent(ncsu_component#(wb_transaction) agent);
    this.agent = agent;
  endfunction
  
  virtual task run ();
    wb_bus.wait_for_reset();
    forever begin
      monitored_trans = new("monitored_trans");
      wb_bus.master_monitor(monitored_trans.wb_addr,
                  monitored_trans.wb_data,
                  monitored_trans.wb_op
                  );
      //$display("wb_monitor Addr:%h Data:%h We:%h",
      //         monitored_trans.wb_addr, 
      //         monitored_trans.wb_data, 
      //         monitored_trans.wb_op
      //         );
      this.agent.nb_put(monitored_trans);
    end 
  endtask

endclass