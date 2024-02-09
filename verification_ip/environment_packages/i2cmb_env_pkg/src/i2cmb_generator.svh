class i2cmb_generator extends ncsu_component;

  i2c_transaction i2c_w_trans, i2c_r_trans,i2c_read_trans1, i2c_read_trans_arr2[64];
  wb_transaction  cmd_write_trans1[32],cmd_write_trans2[64];
  ncsu_component #(i2c_transaction) i2c_agent;
  ncsu_component #(wb_transaction) wb_agent;

  wb_transaction trans_read[reg_off];
  wb_transaction trans_write[reg_off];



  bit [i2c_data_wid-1:0] i2c_data [$];


  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    for(int i=3;i>=0;i--) begin 
      automatic reg_off addr_offset = reg_off'(i);
      $cast(trans_read[addr_offset],ncsu_object_factory::create("wb_transaction"));
      $cast(trans_write[addr_offset],ncsu_object_factory::create("wb_transaction"));
      void'(trans_read[addr_offset].set_addr(addr_offset));
      void'(trans_read[addr_offset].set_op(WB_Read));
      void'(trans_write[addr_offset].set_addr(addr_offset));
      void'(trans_write[addr_offset].set_op(WB_Write));
    end
    //$cast(i2c_w_trans, ncsu_object_factory::create("i2c_transaction_i2c_w_trans"));
    i2c_w_trans = new("i2c_w_trans");
    //$cast(i2c_r_trans, ncsu_object_factory::create("i2c_transaction_i2c_r_trans"));
    i2c_r_trans = new("i2c_r_trans");
    void'(i2c_w_trans.set_op(I2C_WRITE));
    void'(i2c_r_trans.set_op(I2C_READ));

    foreach(cmd_write_trans1[i]) begin
      $cast(cmd_write_trans1[i], ncsu_object_factory::create("wb_transaction"));
      void'(cmd_write_trans1[i].set_addr(DPR));
      void'(cmd_write_trans1[i].set_op(WB_Write));
    end

    foreach(cmd_write_trans2[i]) begin
      $cast(cmd_write_trans2[i], ncsu_object_factory::create("wb_transaction"));
      void'(cmd_write_trans2[i].set_addr(DPR));
      void'(cmd_write_trans2[i].set_op(WB_Write));
    end

    //$cast(i2c_read_trans1, ncsu_object_factory::create("i2c_transaction_i2c_read_trans1"));
    i2c_read_trans1 = new("i2c_read_trans1");
    void'(i2c_read_trans1.set_op(I2C_READ));

    for(int i=0;i<64;i++) begin
       //$cast(i2c_read_trans_arr2[i], ncsu_object_factory::create("i2c_transaction_i2c_read_trans2"));
       i2c_read_trans_arr2[i] = new("i2c_read_trans_arr2[i]");
       void'(i2c_read_trans_arr2[i].set_op(I2C_READ));
    end

    //if ( !$value$plusargs("GEN_TRANS_TYPE=%s", trans_name)) begin
    //  $display("FATAL: +GEN_TRANS_TYPE plusarg not found on command line");
    //  $fatal;
    //end
    //$display("%m found +GEN_TRANS_TYPE=%s", trans_name);
  endfunction

  function void set_wb_agent(ncsu_component #(wb_transaction) wb_agent);
     this.wb_agent = wb_agent;
  endfunction

  function void set_i2c_agent(ncsu_component #(i2c_transaction) i2c_agent);
     this.i2c_agent = i2c_agent;
  endfunction

  virtual task write_wb_addr(input bit [6:0] _slave_addr_,input i2c_op_t i2c_op);
     wb_agent.bl_put(trans_write[DPR].set_data({1'b0,_slave_addr_}<<1|bit'(i2c_op)));
     //Write Command
     wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_WRITE}));
  endtask

  task write_WB_data(input wb_transaction trans); 
     wb_agent.bl_put(trans);
     wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_WRITE}));
  endtask

  task read_wb_data(input logic last = 1);
     wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_READ_W_AK^last}));
     wb_agent.bl_put(trans_read[DPR]);
  endtask

  

  virtual task run();

     foreach(cmd_write_trans1[i]) begin
        void'(cmd_write_trans1[i].set_data(i));
     end

     for(int i=0;i<32;i++) begin
        i2c_data.push_back(100+i);
     end
     void'(i2c_read_trans1.set_data(i2c_data));

     for(int i=0;i<64;i++) begin 
        void'(cmd_write_trans2[i].set_data(64+i));
        i2c_data.delete;
        i2c_data.push_back(63-i);
        void'(i2c_read_trans_arr2[i].set_data(i2c_data));
     end

     fork
        begin
            i2c_agent.bl_put(i2c_w_trans);
            i2c_agent.bl_put(i2c_read_trans1);
            for(int i=0;i<64;i++) begin
                i2c_agent.bl_put(i2c_w_trans);
                i2c_agent.bl_put(i2c_read_trans_arr2[i]);
            end
        end
        begin
            //enable core
            wb_agent.bl_put(trans_write[CSR].set_data(8'b11000000));
            //Set bus id
            wb_agent.bl_put(trans_write[DPR].set_data(8'h05));
            //Set bus
            wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_SET_BUS}));

            $display("Write 32 writes from 0-31");
            //Start Command
            wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_START}));
            //$display("aaaaa");
            write_wb_addr(7'h22,I2C_WRITE);
            //$display("bbbbb");
            for(int i=0;i<32;i++) begin 
               write_WB_data(cmd_write_trans1[i]);
            end
            // Stop Command
            wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_STOP}));

            $display("Read 32 values from 100-131");

            wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_START}));
            write_wb_addr(7'h22,I2C_READ);
            for(int i=0;i<32;i++) begin 
               read_wb_data(i==31);
            end       
            wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_STOP}));

            $display("Aleternate read and writes");

            for(int i=0;i<64;i++) begin
               wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_START}));
               write_wb_addr(7'h22,I2C_WRITE);
               write_WB_data(cmd_write_trans2[i]);
               wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_START}));
               write_wb_addr(7'h22,I2C_READ);
               read_wb_data(i==63); 
            end

            wb_agent.bl_put(trans_write[CMDR].set_data({5'b0,CMDR_STOP}));

        end
     join_any
     $display("Project 2 finish");

  endtask


endclass