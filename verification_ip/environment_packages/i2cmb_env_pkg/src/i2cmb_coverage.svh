class i2cmb_coverage extends ncsu_component#(.T(wb_transaction));

  i2cmb_env_configuration     i2cmb_config;
  //abc_transaction_base  covergae_transaction;
  //header_type_t         header_type;
  bit [1:0] wb_addr_temp;
  bit cmd_err_flg;
  bit wb_op_temp;
  wb_op_t wb_op_type;
  cmdr_cmd cmdr_cmd_type;
  Byte_fsm level_fsm_byte;
  Bit_fsm level_fsm_bit;
  bit [7:0] rst_data;
  bit [31:0] ValidAddr;
  bit [31:0] InvalAddr;
  reg_off nor_reg;
  reg_off acc_reg;
  reg_off reg_type;
  wb_op_t wb_we_t;
  bit [1:0] wb_addr;
  bit [7:0] wb_data;
  bit wb_op;
  Byte_fsm byte_fsm_type;
  cmdr_cmd cmdr_commands;

  //////////////////Covergroup for Register Block test/////////////////////
  covergroup block_reg;
  option.per_instance = 1;
  option.name = get_full_name();

  ValidAddr : coverpoint ValidAddr{
    bins val_addr ={['d0:'d3]};
  }

  cmdr_err_flg : coverpoint cmd_err_flg{
    bins err_cmdr ={'b1};
  }

  acc_reg : coverpoint acc_reg {
    bins CSR ={CSR};
    bins DPR ={DPR};
    bins CMDR = {CMDR};
    bins FSMR = {FSMR};
  }

  nor_reg : coverpoint nor_reg{
    bins rst_csr = {'b11000000};
    bins rst_dpr = {'b00000000};
    bins rst_cmdr = {'b10000000};
    bins rst_fsmr = {'b00000000};
  }

  wb_op_type : coverpoint wb_op_type {
    bins wb_read = {'b0};
    bins wb_write = {'b1};
  }

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

  bit_access_aliasing: cross wb_addr,wb_data,wb_op;

  endgroup

  ////////////////////////////////////////Covergroup for Bit level FSM////////////////////////////////////////

  covergroup cg_fsm_bit;
  
  option.per_instance = 1;
  option.name = get_full_name();

  cmdr_cmd_inval: coverpoint cmdr_cmd_type{
    bins CMDR_WAIT = {CMDR_WAIT};
    bins CMDR_WRITE = {CMDR_WRITE};
    bins CMDR_READ_W_AK = {CMDR_READ_W_AK};
    bins CMDR_READ_W_NAK = {CMDR_READ_W_NAK};
    bins CMDR_START = {CMDR_START};
    bins CMDR_STOP = {CMDR_STOP};
    bins CMDR_SET_BUS = {CMDR_SET_BUS};
    bins CMDR_NOT_USED = default;
  }

  fsm_bit_level_valid : coverpoint level_fsm_bit{
    bins idle = {idle};
    bins start_A = {start_A};
    bins start_B = {start_B};
    bins start_C = {start_C};
    bins r_w_A = {r_w_A};
    bins r_w_B = {r_w_B};
    bins r_w_C = {r_w_C};
    bins r_w_D = {r_w_D};
    bins r_w_E = {r_w_E};
    bins stp_A = {stp_A};
    bins stp_B = {stp_B};
    bins stp_C = {stp_C};
    bins rst_A = {rst_A};
    bins rst_B = {rst_B};
    bins rst_C = {rst_C};
  }

  fsm_bit_level_invalid: coverpoint level_fsm_bit
   {
     //illegal_bins INVAILD_FSM_BIT = default;
   }

  fsm_addr_bit : coverpoint wb_addr_temp{
    bins Addr_trans = {2'b11,2'b10};
  }

  fsm_op_bit : coverpoint wb_op_temp{
    bins write_enb_trans = {1'b1,1'b0};
  }

  fsm_valid_bit: cross fsm_op_bit, fsm_addr_bit;

  endgroup

  ////////////////////////////////////////Covergroup for FSM Byte level///////////////////////////////////////////
  covergroup fsm_byte_cg;
  
  option.per_instance = 1;
  option.name = get_full_name();

  wb_cmds: coverpoint cmdr_commands{
    bins invalid = {CMDR_NOT_USED};
  }

  fsm_state : coverpoint byte_fsm_type{
    bins idle_state = {S_IDLE};
    bins bus_taken_state = {S_Bus_taken};
    bins str_pend_state = {S_str_pend};
    bins str_state = {S_str};
    bins stp_state = {S_stp};
    bins write_byte_state = {S_write_byte};
    bins read_byte_state = {S_read_byte};
    bins wait_state = {S_wait};
  }

  fsm_idle_state : coverpoint byte_fsm_type{
    bins idle_wait = (S_IDLE => S_wait);
    bins idle_str = (S_IDLE => S_str_pend);
    illegal_bins invalid_idle = (S_IDLE => S_Bus_taken, S_IDLE => S_str, S_IDLE => S_stp, S_IDLE => S_write_byte, S_IDLE => S_read_byte);
  }

  fsm_bus_taken_state : coverpoint byte_fsm_type{
    bins write_bus_taken = (S_Bus_taken => S_write_byte);
    bins read_bus_taken = (S_Bus_taken => S_read_byte);
    bins str_bus_taken = (S_Bus_taken => S_str);
    bins stp_bus_taken = (S_Bus_taken => S_stp);
  }

  fsm_str_state : coverpoint byte_fsm_type{
    bins str_done = (S_str => S_Bus_taken);
    illegal_bins invalid_str = (S_str => S_IDLE,S_str => S_stp, S_str => S_str_pend, S_str => S_read_byte,S_str => S_write_byte, S_str => S_wait);
  }

  fsm_stp_state : coverpoint byte_fsm_type{
    bins stp_done = (S_stp => S_IDLE);
    illegal_bins invalid_stp = (S_stp => S_str,S_stp =>S_str_pend,S_stp=>S_read_byte, S_stp =>S_write_byte, S_stp => S_wait, S_Bus_taken);
  }

  fsm_wait_state : coverpoint byte_fsm_type{
    bins wait_done = (S_wait => S_IDLE);
    illegal_bins invalid_wait = (S_wait => S_stp, S_wait => S_str_pend, S_wait =>S_read_byte, S_wait => S_write_byte, S_wait => S_str,S_wait => S_Bus_taken);
  }

	fsm_write_state : coverpoint byte_fsm_type
         {          
		        bins done_with_ack   = (S_write_byte => S_Bus_taken);
		       	       }

	fsm_read_state : coverpoint byte_fsm_type
         {           
		        bins nack_read   = (S_read_byte => S_Bus_taken);
		      	       }

  endgroup
  

  function void set_configuration(i2cmb_env_configuration cfg);
  	i2cmb_config = cfg;
  endfunction

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    block_reg =new;
    fsm_byte_cg = new;
    cg_fsm_bit = new;
  endfunction

  virtual function void nb_put(T trans);

    if(trans.wb_addr == CMDR) begin
      cmdr_cmd_type = cmdr_cmd'(trans.wb_data[2:0]);
      cmd_err_flg = (trans.wb_data[4]);
      cmdr_commands = cmdr_cmd'(trans.wb_data);
    end
  
    if(trans.wb_addr == FSMR) begin
      byte_fsm_type = Byte_fsm'(trans.wb_data[7:4]);
      level_fsm_bit = Bit_fsm'(trans.wb_data[3:0]);
    end
  
    wb_op_type = wb_op_t'(trans.wb_op);
    wb_addr_temp = trans.wb_addr;
    acc_reg = reg_off'(trans.wb_addr);
    reg_type = reg_off'(trans.wb_addr);
    wb_we_t = wb_op_t'(trans.wb_op);
    ValidAddr = trans.wb_addr;
    InvalAddr = trans.wb_addr;
    byte_fsm_type = Byte_fsm'(trans.wb_data[7:4]);
    level_fsm_bit = Bit_fsm'(trans.wb_data[3:0]);
    wb_addr = trans.wb_addr;
    wb_data = wb_data;
    wb_op = trans.wb_op;
  
    block_reg.sample();
    cg_fsm_bit.sample();
    fsm_byte_cg.sample();

  endfunction

endclass