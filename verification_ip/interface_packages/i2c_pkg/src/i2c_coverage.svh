class i2c_coverage extends ncsu_component#(.T(i2c_transaction));

    i2c_configuration cfg0;


   function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2c_configuration cfg);
    cfg0 = cfg;
  endfunction

  endclass