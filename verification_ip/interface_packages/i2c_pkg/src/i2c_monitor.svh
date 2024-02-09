class i2c_monitor extends ncsu_component#(.T(i2c_transaction));

  i2c_configuration  i2c_config;
  virtual i2c_if #(.i2c_addr_wid(i2c_addr_wid),.i2c_data_wid(i2c_data_wid),.NUM_I2C_BUSSES(NUM_I2C_BUSSES))    i2c_bus;

  T monitored_trans;
  T i2c_byte_trans;
  ncsu_component #(T) agent;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2c_configuration cfg);
    i2c_config = cfg;
  endfunction

  function void set_agent(ncsu_component#(T) agent);
    this.agent = agent;
  endfunction

  virtual task run();
    forever begin
        monitored_trans = new("monitored_trans");
        i2c_bus.monitor(monitored_trans.i2c_addr, monitored_trans.i2c_op,monitored_trans.i2c_data);
        this.agent.nb_put(monitored_trans);
    end
    //$cast(monitored_trans,ncsu_object_factory::create("i2c_transaction"));
    
  endtask

  endclass