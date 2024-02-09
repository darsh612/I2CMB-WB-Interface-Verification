class wb_coverage extends ncsu_component#(.T(wb_transaction));

   wb_configuration cfg0;
   bit [1:0] wb_addr;
   bit [7:0] wb_data;
   bit [31:0] addr_valid;
   bit wb_op;

  covergroup block_reg;
  option.per_instance = 1;
  option.name = get_full_name();

  wb_data : coverpoint wb_data{
    bins csr_alias = {'hC0,'hC0,'h0};
    bins dpr_alias = {'hFF,'hFF, 'hFF};
    bins cmdr_alias = {'h04, 'h04, 'h04};
    bins fsmr_alias = {'h0, 'hFF, 'h0};
  }

  wb_addr : coverpoint wb_addr {
    bins csr_addr_alias = {'b00};
    bins dpr_addr_alias = {'b01};
    bins cmdr_addr_alias = {'b10};
    bins fsmr_addr_alias = {'b11};
  }

  wb_op: coverpoint wb_op{
    bins csr_op_al = {'d1,'d0};
    bins dpr_op_al = {'d1,'d0};
    bins cmdr_op_al = {'d1,'d0};
    bins fsmr_op_al = {'d1,'d0};
  }

  //bit_access_aliasing: cross wb_addr,wb_data,wb_op;

  endgroup

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    block_reg = new;
  endfunction

  function void set_configuration(wb_configuration cfg);
    cfg0 = cfg;
  endfunction

  virtual function void nb_put(T trans);
    //assignments to all the local variables here
    addr_valid = trans.wb_addr;
    wb_addr = trans.wb_addr;
    wb_data = trans.wb_data;
    wb_op = trans.wb_op;
    block_reg.sample();
  endfunction

endclass 