class i2cmb_environment extends ncsu_component;

  i2cmb_env_configuration i2cmb_config;
  i2c_agent         i2c_agen;
  wb_agent          wb_agen;
  i2c_configuration i2c_config;
  wb_configuration wb_config;
  i2cmb_predictor         pred;
  i2cmb_scoreboard        scbd;
  i2cmb_coverage          cov_i2cmb;


  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction 

  function void set_configuration(i2cmb_env_configuration cfg);
    i2cmb_config = cfg;
  endfunction

  virtual function void build();
    i2c_agen = new("i2c_agen",this);
    i2c_agen.set_configuration(i2c_config);
    i2c_agen.build();
    wb_agen = new("wb_agen",this);
    wb_agen.set_configuration(wb_config);
    wb_agen.build();
    pred  = new("pred", this);
    pred.set_configuration(i2cmb_config);
    pred.build();
    scbd  = new("scbd", this);
    scbd.build();
    cov_i2cmb = new("cov_i2cmb", this);
    cov_i2cmb.set_configuration(i2cmb_config);
    cov_i2cmb.build();
    //cov_wb = new("cov_wb", this);
    //cov_wb.set_configuration(i2cmb_config_wb);
    //cov_wb.build();
    wb_agen.connect_subscriber(cov_i2cmb);
    wb_agen.connect_subscriber(pred);
    pred.set_scoreboard(scbd);
    i2c_agen.connect_subscriber(scbd);
    //i2c_agen.connect_subscriber(cov_i2c);
  endfunction

  function ncsu_component#(i2c_transaction) get_i2c_agent();
    return i2c_agen;
  endfunction

  function ncsu_component#(wb_transaction) get_wb_agent();
    return wb_agen;
  endfunction

  virtual task run();
     i2c_agen.run();
     wb_agen.run();
  endtask

endclass