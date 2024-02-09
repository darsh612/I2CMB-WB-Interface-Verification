class i2c_driver extends ncsu_component#(.T(i2c_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual i2c_if #(.i2c_addr_wid(i2c_addr_wid),.i2c_data_wid(i2c_data_wid),.NUM_I2C_BUSSES(NUM_I2C_BUSSES))    i2c_bus;
  i2c_configuration i2c_config;
  i2c_transaction i2c_trans;
  bit transfer_complete;

  function void set_configuration(i2c_configuration cfg);
    i2c_config = cfg;
  endfunction

  virtual task bl_put(T trans);
    automatic bit [i2c_data_wid-1:0] temp[];
    if(trans.i2c_op == I2C_WRITE) begin 
      i2c_bus.wait_for_i2c_transfer(trans.i2c_op, trans.i2c_data);
    end
    else if (trans.i2c_op == I2C_READ) begin 
      i2c_bus.wait_for_i2c_transfer(trans.i2c_op, temp);
      i2c_bus.provide_read_data(trans.get_data(), transfer_complete);
    end
  endtask : bl_put

endclass

