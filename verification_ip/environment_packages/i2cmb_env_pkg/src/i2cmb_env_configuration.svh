class i2cmb_env_configuration extends ncsu_configuration;

i2c_configuration i2c_config;
wb_configuration wb_config;

bit       loopback;
bit       invert;
bit [3:0] port_delay;

covergroup i2cmb_env_configuration_cg;
option.per_instance = 1;
option.name = name;
coverpoint loopback;
coverpoint invert;
coverpoint port_delay;
endgroup

function new(string name="");
    super.new(name);
    i2c_config = new("i2c_config");
    wb_config = new("wb_config");
endfunction

function void sample_coverage();
	i2cmb_env_configuration_cg.sample();
endfunction

endclass