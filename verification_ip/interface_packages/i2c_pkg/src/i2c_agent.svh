class i2c_agent extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration i2c_config;
  i2c_driver        i2c_drv;
  i2c_monitor       i2c_mon;
  //i2c_coverage      coverage;
  ncsu_component #(T) subscribers[$];
  
  virtual i2c_if #(.i2c_addr_wid(i2c_addr_wid),.i2c_data_wid(i2c_data_wid),.NUM_I2C_BUSSES(NUM_I2C_BUSSES))    i2c_bus;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    if ( !(ncsu_config_db#(virtual i2c_if #(.i2c_addr_wid(i2c_addr_wid),.i2c_data_wid(i2c_data_wid),.NUM_I2C_BUSSES(NUM_I2C_BUSSES)))::get(get_full_name(), this.i2c_bus))) begin;
      $display("i2c_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
      //$finish;
      //ncsu_fatal("i2c_agent::new()",$sformatf("ncsu_config_db::get() call failed"));
    end
  endfunction

  function void set_configuration(i2c_configuration cfg);
    i2c_config = cfg;
  endfunction

  virtual function void build();
    i2c_drv = new("i2c_drv",this);
    i2c_drv.set_configuration(i2c_config);
    i2c_drv.build();
    i2c_drv.i2c_bus = this.i2c_bus;
    //if ( configuration.collect_coverage) begin
    //  coverage = new("coverage",this);
    //  coverage.set_configuration(configuration);
    //  coverage.build();
    //  connect_subscriber(coverage);
    //end
    i2c_mon = new("i2c_mon",this);
    i2c_mon.set_configuration(i2c_config);
    i2c_mon.set_agent(this);
    //i2c_mon.enable_transaction_viewing = 1;
    i2c_mon.build();
    i2c_mon.i2c_bus = this.i2c_bus;
  endfunction

  virtual function void nb_put(T trans);
    foreach (subscribers[i]) subscribers[i].nb_put(trans);
  endfunction

  virtual task bl_put(T trans);
    i2c_drv.bl_put(trans);
  endtask

  virtual function void connect_subscriber(ncsu_component#(T) subscriber);
    subscribers.push_back(subscriber);
  endfunction

  virtual task run();
     fork i2c_mon.run(); join_none
  endtask 

  endclass