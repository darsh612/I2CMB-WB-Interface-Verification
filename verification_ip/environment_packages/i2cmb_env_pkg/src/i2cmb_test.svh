class i2cmb_test extends ncsu_component;
  
    i2cmb_env_configuration i2cmb_config;
    i2cmb_environment i2cmb_env;
    i2cmb_generator i2cmb_gen;

    function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);
    i2cmb_config = new("i2cmb_config");
    //i2cmb_config.sample_coverage();
    i2cmb_env = new("i2cmb_env",this);
    i2cmb_env.set_configuration(i2cmb_config);
    i2cmb_env.build();
    i2cmb_gen = new("i2cmb_gen",this);
    i2cmb_gen.set_i2c_agent(i2cmb_env.get_i2c_agent());
    i2cmb_gen.set_wb_agent(i2cmb_env.get_wb_agent());
  endfunction

  virtual task run();
     i2cmb_env.run();
     i2cmb_gen.run();
  endtask

endclass
