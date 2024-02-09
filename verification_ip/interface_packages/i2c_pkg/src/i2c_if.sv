interface i2c_if   #(
      int i2c_addr_wid = 7,
      int i2c_data_wid = 8,
      int NUM_I2C_BUSSES = 1)
(
    inout scl_s,
    inout triand sda_s);

import i2c_pkg::*;

logic sda_oe = 1'b1;
bit ack_flag = 1'b0;
assign sda_s = sda_oe ? 1'bz:ack_flag;


bit start_flg = 1'b0; 
bit stp_flg = 1'b0;
bit data_flag = 1'b0;

bit start_flg1 = 1'b0;
bit stp_flg1 = 1'b0;
bit data_flg1 = 1'b0;

i2c_op_t op;

task wait_for_i2c_transfer(output i2c_op_t op, output bit [i2c_data_wid-1:0] write_data[]);
    automatic bit [i2c_addr_wid-1:0] slave_addr;
    automatic bit [i2c_data_wid-1:0] data_from_master;
    automatic bit [i2c_data_wid-1:0] dynamic_data [$];
    start(start_flg);
    //$display("Executed start flg 1");
    read_addr(op,slave_addr);
    //$display("Address read 1");
    send_ack();
    //$display("Ack flag set 1");
    if(sda_oe) begin
        stop(stp_flg);
        //$display("Stop set 1");
    end
    else if(op == I2C_WRITE) begin
        @(negedge scl_s) sda_oe = 1;
        read_data_from_master(data_from_master);
        dynamic_data.push_back(data_from_master);
        send_ack();
        @(negedge scl_s) sda_oe = 1;
        do begin 
            data_flag = 0;
            fork : fork1
                begin 
                    start(start_flg); 
                    start_flg = 1;
                end
                begin 
                    stop(stp_flg); 
                end
                begin 
                    read_data_from_master(data_from_master);
                    dynamic_data.push_back(data_from_master);
                    data_flag = 1;
                    send_ack();
                    @(negedge scl_s) sda_oe =1;
                end
            join_any
            disable fork1;
        end while(data_flag);
        write_data = new [dynamic_data.size()];
        write_data = {>>{dynamic_data}};
    end
endtask

task provide_read_data(input bit [i2c_data_wid-1:0] read_data[],output bit transfer_complete);
    automatic bit nack=1;                       // Ack =1, Nack =0
    foreach(read_data[i]) begin 
        databyte_by_slave(read_data[i]);
        @(negedge scl_s) sda_oe <=1;           // Stops slave bus by pulling sda high
        @(posedge scl_s) nack = sda_s;
        if(nack) begin                        // If nack then try to complete the the transfer by detecting start or stop
            fork 
                begin 
                    start(start_flg);
                    start_flg=1;
                    //$display("Executed start flg 1 provide_read");
                end
                begin 
                    stop(stp_flg);
                    //$display("Executed stop flg 1 provide read");
                end
            join_any
            disable fork;
            break; 
        end
    end
    transfer_complete = nack;
endtask

task monitor(output bit [i2c_addr_wid-1:0]addr,output i2c_op_t op, output bit[i2c_data_wid-1:0] data[]);
    automatic bit [i2c_data_wid-1:0] data_1;
    automatic bit [i2c_data_wid-1:0] dynamic_data [$];
    automatic bit ack =0;
    start(start_flg1);
    read_addr(op, addr);
    send_ack();
    if(sda_oe) begin 
        stop(stp_flg1);
    end
    else begin
        automatic bit stall = 0;
        do begin 
            data_flg1=0;
            fork : fork1
                begin 
                    //wait(stall);
                    start(start_flg1);
                    start_flg1 = 1;
                end
                begin 
                    //wait(stall);
                    stop(stp_flg1);
                end
                begin 
                    read_data_from_master(data_1);
                    dynamic_data.push_back(data_1);
                    @(posedge scl_s);
                    data_flg1 = 1;
                end
            join_any
            disable fork1;
            //stall = 1;
        end while(data_flg1);
    end
    data = new [dynamic_data.size()];
    data = {>>{dynamic_data}};
endtask

//////////////////////////////////////////////////////////////////////////////
///////////////////////// Task for Above tasks ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////
task automatic start(ref bit ref_start);
    while(!ref_start) begin 
        @(negedge sda_s);
         if(scl_s) begin 
            ref_start =1'b1; 
        end 
    end
    ref_start = 1'b0;
endtask
task automatic stop(ref bit ref_stop);
    while(!ref_stop) begin 
        @(posedge sda_s);
        if(scl_s) begin 
            ref_stop =1'b1; 
        end 
    end;
    ref_stop = 1'b0;
endtask
task automatic read_addr(output i2c_op_t ref_op, output bit [i2c_addr_wid-1:0] _slave_addr_);
    automatic bit buffer[$];
    repeat(i2c_addr_wid) begin
        @(posedge scl_s); 
        buffer.push_back(sda_s); 
    end 
    //foreach(buffer[i]) begin 
    //    _slave_addr_[i] = buffer[i];
    //end
    _slave_addr_ = {>>{buffer}};
    @(posedge scl_s); 
    ref_op = i2c_op_t'(sda_s);
endtask

task automatic read_data_from_master(output bit [i2c_data_wid-1:0] data_from_master);
    automatic bit buffer[$];
    repeat(i2c_data_wid) begin 
       @(posedge scl_s); 
       buffer.push_back(sda_s);
    end
    //foreach(buffer[i]) begin 
    //    data_from_master[i] = buffer[i];
    //end
    data_from_master = {>>{buffer}};
endtask

task automatic send_ack();
   @(negedge scl_s);
   begin
    sda_oe <= 0;
    ack_flag <= 0;
   end
   @(posedge scl_s);
endtask

task databyte_by_slave(input bit [i2c_data_wid-1:0] _read_data_);
    foreach(_read_data_[j])begin 
        @(negedge scl_s) sda_oe <=0;
        ack_flag <= _read_data_[j];
    end
endtask

endinterface