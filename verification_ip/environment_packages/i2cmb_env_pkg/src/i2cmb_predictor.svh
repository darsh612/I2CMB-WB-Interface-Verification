class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));

  ncsu_component #(i2c_transaction) scbd;
  i2cmb_env_configuration i2cmb_env_config;
  i2c_transaction i2c_pred,empty_trans;
  
  Byte_fsm curr_state;
  Byte_fsm next_state;

  logic [7:0] dpr_reg;
  CMDR_reg cmdr_reg;
  CSR_reg csr_reg;
  FSMR_reg fsmr_reg;
  bit [3:0] bus_id;
  bit cmd_w_flg [reg_off];
  bit cmd_r_flg [reg_off];
  bit ack_flg;
  bit en_flg;
  bit str_flg;
  bit rd_flg;
  reg_off wb_addr;
  cmdr_cmd wb_cmd;
  bit [wb_data_wid-1:0] wb_data;
  wb_op_t wb_op;
  bit [i2c_data_wid-1:0] data_buf[$];
  bit i2c_addr_flg;

  function new(string name = "", ncsu_component_base parent = null);
      super.new(name,parent);
      curr_state = S_IDLE;
      en_flg = 0;
      str_flg =0;
      bus_id =0;
      i2c_addr_flg =0;
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
      i2cmb_env_config = cfg;
  endfunction

  virtual function void set_scoreboard(ncsu_component#(i2c_transaction) scoreboard);
      this.scbd = scoreboard;
  endfunction

  function void set_cmd_flg(wb_op_t op, reg_off addr);
     cmd_w_flg[CSR] = (op == WB_Write) && (addr == CSR);
     cmd_w_flg[CMDR] = (op == WB_Write) && (addr == CMDR);
     cmd_w_flg[DPR] = (op == WB_Write) && (addr == DPR);
     cmd_w_flg[FSMR] = (op == WB_Write) && (addr == FSMR);
     cmd_r_flg[CSR] = (op == WB_Read) && (addr == CSR);
     cmd_r_flg[CMDR] = (op == WB_Read) && (addr == CMDR);
     cmd_r_flg[DPR] = (op == WB_Read) && (addr == DPR);
     cmd_r_flg[FSMR] = (op == WB_Read) && (addr == FSMR);
  endfunction

  virtual function void nb_put(T trans);
     //if(i2cmb_env_config.get_name() == "i2cmb_generator_fsm_sunctionality_test") return;
     if(trans.get_type_handle() == wb_transaction::get_type()) begin
        $cast(wb_op,trans.get_op());
        $cast(wb_addr,trans.get_addr());
        $cast(wb_data,trans.get_data_0());
        if(wb_addr==CMDR) wb_cmd = cmdr_cmd'(wb_data[2:0]);
        set_cmd_flg(wb_op, wb_addr);
    end
    if(trans.get_type_handle() == wb_transaction::get_type())begin
        if(cmd_w_flg[CSR])begin
            if(!wb_data[7]) begin
                next_state = S_IDLE;
            end
        end
        if(curr_state == S_IDLE) begin
            if(cmd_w_flg[CMDR]) begin
                if(wb_cmd == CMDR_START) begin
                    next_state = S_Bus_taken;
                end
            end
        end
        else if(curr_state == S_Bus_taken) begin
            if(cmd_w_flg[CMDR])begin
                if(wb_cmd==CMDR_SET_BUS) begin
                    next_state = S_Bus_taken;
                end
                if(wb_cmd==CMDR_WAIT) begin
                    next_state = S_Bus_taken;
                end
                if(wb_cmd==CMDR_STOP) begin
                    next_state = S_IDLE;
                end
                if(wb_cmd==CMDR_START) begin
                    next_state = S_Bus_taken;
                end
                if(wb_cmd==CMDR_WRITE) begin
                    next_state = S_write_byte;
                end
                if(wb_cmd==CMDR_READ_W_AK) begin
                    next_state = S_read_byte;
                end
                if(wb_cmd==CMDR_READ_W_NAK) begin
                    next_state = S_read_byte;
                end
            end
        end
    end
    else if(trans.get_type_handle() == wb_irq_transaction::get_type()) begin
        if(curr_state == S_write_byte) begin
            next_state = S_Bus_taken;
        end
        if(curr_state == S_read_byte) begin
            next_state = S_Bus_taken;
        end
    end
    //// DUT register simulator////////
    if(trans.get_type_handle() == wb_transaction::get_type()) begin
        if(cmd_w_flg[DPR]) begin
            dpr_reg = wb_data;
        end
        if(cmd_w_flg[CMDR]) begin
            cmdr_reg.cmd = wb_cmd;
        end
        if(cmd_w_flg[CMDR] && (wb_data[2:0] == 3'd7)) begin
            cmdr_reg.err = 1'b1;
        end
        if(cmd_w_flg[CSR]) begin
            csr_reg.e = wb_data[7];
            csr_reg.ie = wb_data[6];
        end
        if(curr_state == S_IDLE) begin
            if(cmd_w_flg[CMDR])begin
                if(wb_cmd == CMDR_STOP) begin
                    cmdr_reg.err = 1'b1;
                end
                if(wb_cmd == CMDR_WRITE) begin
                    cmdr_reg.err = 1'b1;
                end
                if(wb_cmd == CMDR_READ_W_AK) begin
                    cmdr_reg.err = 1'b1;
                end
                if(wb_cmd == CMDR_READ_W_NAK) begin
                    cmdr_reg.err = 1'b1;
                end
                if(wb_cmd == CMDR_SET_BUS && dpr_reg >= NUM_I2C_BUSSES) begin
                    cmdr_reg.err = 1'b1;
                end
            end
        end
        else if(curr_state == S_Bus_taken)begin
            if(cmd_w_flg[CMDR])begin
                if(wb_cmd==CMDR_SET_BUS) begin
                    cmdr_reg.err = 1'b1;
                end
                if(wb_cmd==CMDR_WAIT) begin
                    cmdr_reg.err = 1'b1;
                end
            end
        end
    end
    fsmr_reg.fsm_byte = next_state;
    //$display({get_full_name()," ",trans.convert2string()});
    //scoreboard.nb_transport(trans, transport_trans);

    //i2c trasaction predictor
    if(trans.get_type_handle() == wb_transaction::get_type()) begin
        if(csr_reg.e && (curr_state == S_Bus_taken)) begin
            if(cmd_w_flg[CMDR]) begin
                if(wb_cmd == CMDR_WRITE) begin
                    assert ((!i2c_addr_flg) ||(i2c_addr_flg &&(i2c_pred.i2c_op == I2C_WRITE))); 
                end
                if(!i2c_addr_flg) begin
                    //$cast(i2c_pred, ncsu_object_factory::create("i2c transaction_i2c_pred"));
                    i2c_pred = new("i2c_pred");
                    $cast(i2c_pred.i2c_op, dpr_reg[0]);
                    i2c_addr_flg = 1;
                    i2c_pred.i2c_addr = dpr_reg[7];
                end
                else if(i2c_pred.i2c_op == I2C_WRITE) begin
                    data_buf.push_back(dpr_reg);
                end
            end
            if(wb_cmd == CMDR_READ_W_AK || wb_cmd == CMDR_READ_W_NAK) begin
                assert(i2c_addr_flg && (i2c_pred.i2c_op == I2C_READ));
                rd_flg = 1;
            end
            if(wb_cmd == CMDR_START || wb_cmd == CMDR_STOP) begin
                if(i2c_addr_flg) begin
                    void'(i2c_pred.set_data(data_buf));
                    scbd.nb_transport(i2c_pred, empty_trans);
                    data_buf.delete;
                end
            end
            else if(cmd_r_flg[DPR]) begin
                if(rd_flg) data_buf.push_back(wb_data);
                rd_flg = 0;
            end
            if(cmd_w_flg[CMDR] && wb_cmd == CMDR_START) begin
                i2c_addr_flg = 0;
            end
            if(cmd_w_flg[CMDR] && wb_cmd == CMDR_STOP) begin
                i2c_addr_flg = 0;
            end
        end
    end
    curr_state = next_state;
    if(trans.get_type_handle() == wb_irq_transaction::get_type()) begin
        ack_flg = 0;
    end
  endfunction
endclass