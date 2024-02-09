`timescale 1ns / 10ps

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

//***********************************************************************
//My parameters
//***********************************************************************
parameter int i2c_addr_wid = 7;
parameter int i2c_data_wid = 8;
parameter int PERIOD = 10;
parameter int reset_per = 113;

typedef enum logic [1:0] {
  CSR=2'd0,
  DPR=2'd1,
  CMDR=2'd2,
  FSMR=2'd3
}reg_off;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
reg we;
tri1 ack;
reg [WB_ADDR_WIDTH-1:0] adr;
reg [WB_DATA_WIDTH-1:0] dat_wr_o;
reg [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

// temporary variables 
logic [WB_DATA_WIDTH-1:0] local_rd_data = 0;

// temporary variable wishbone 
logic [WB_ADDR_WIDTH-1:0] wb_mon_addr;
logic [WB_DATA_WIDTH-1:0] wb_mon_data;
logic we_p;

//temporary variable in i2c
bit [i2c_addr_wid-1:0] i2c_addr;
bit op;
bit [i2c_data_wid-1:0] read_data_i2c [];

// ****************************************************************************
// Clock generator
initial begin : clk_gen
      clk = 1'b0;
      forever #5 clk = ~clk;
  end


// ****************************************************************************
// Reset generator
initial begin : rst_gen
      #reset_per rst = 1'b0;
  end


// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
initial begin : wb_monitoring
  forever begin
    @(posedge clk)
    wb_bus.master_monitor(wb_mon_addr,wb_mon_data,we_p);
    $display("addr :- %h, data :- %h, we :- %b ",wb_mon_addr,wb_mon_data,we_p);
    //$display("data %h",wb_mon_data);
    //$display("we %b",we_p);
  end
end

// ****************************************************************************
// Define the flow of the simulation

task wait_for_irq();
  wait(irq);
  //reading CMDR clears interrupt
  wb_bus.master_read(CMDR,local_rd_data);
  $display(" %b ",local_rd_data );
endtask


initial begin: test_flow
  @(negedge rst);
  repeat(3) @(posedge clk);
//--------------------------------------------------------------------
//Writing 32 values
//--------------------------------------------------------------------
  //WRITE BYTE '11XXXXXX' to CSR register
  //Enable core and interrupt
  wb_bus.master_write(CSR,8'b11000000);
// Store bus ID of SLAVE bus ID=5
  wb_bus.master_write (DPR, 8'h05);
//Set bus command
  wb_bus.master_write (CMDR, 8'bxxxxx110);
  wait_for_irq();
// Start command
  wb_bus.master_write(CMDR, 8'bxxxxx100);
  wait_for_irq();
//Write byte 44 in DPR, This is Slave address (0x22)+ 1 bit shifted to left (0) which means writing
  wb_bus.master_write(DPR, 8'h44);
  //Write command
  wb_bus.master_write(CMDR, 8'bxxxxx001);
  wait_for_irq();
//Write data to the SLAVE
for(byte i=0;i<32;i++) begin 
  wb_bus.master_write(DPR, i);
    //Write command
  wb_bus.master_write(CMDR, 8'bxxxxx001);
    //$display("WB Bus Write Transfer [%0t]\n\
    //data : %d\n\
    //---------------------------------",$time,8'h78);
  wait_for_irq();
  end

  wb_bus.master_write(CMDR,8'bxxxxx101);
  wait_for_irq();

/////////////////////////////////////////////////////////
//-------------------------------------------------------
//Reading 32 values
//-------------------------------------------------------

  wb_bus.master_write(CMDR,8'bxxxxx100);
  wait_for_irq();
  wb_bus.master_write(DPR, 8'h45);
  wb_bus.master_write(CMDR,8'bxxxxx001);
  wait_for_irq();
  
  for(int i=0;i<32;i++) begin 
    automatic bit [i2c_data_wid-1:0] data;
    automatic bit last = 1'b0;
    if(i==31) begin
      last = 1'b1;
    end
    wb_bus.master_write(CMDR,{5'bx,3'b010^last});            //Read with ACK/NACK bit
    wait_for_irq();
    wb_bus.master_read(DPR, data);
    //$display("data = %d ",data);
    assert (data == (8'd100+i)) begin end 
    else   $fatal("wrong data = %d, ans = %d",data,(8'd100+i));
  end

  wb_bus.master_write(CMDR,8'bxxxxx101);
  wait_for_irq();

//-------------------------------------------------------------------
//Alternate read 0-63/ write 64-127
//-------------------------------------------------------------------

  for(int i=0;i<64;i++) begin 
    automatic bit [i2c_data_wid-1:0] data;
    automatic bit last =1'b0;
    //Start Command
    wb_bus.master_write(CMDR,8'bxxxxx100);
    //$display("Started Bus");
    wait_for_irq();

    //Set bus command
    //wb_bus.master_write (CMDR, 8'bxxxxx110);
    //wait_for_irq();
    //Start bus command
    //wb_bus.master_write(CMDR, 8'bxxxxx100);
    //wait_for_irq();    

    wb_bus.master_write(DPR,8'h44);
    // Write Command
    wb_bus.master_write(CMDR,8'bxxxxx001);
    wait_for_irq();

    wb_bus.master_write(DPR, 8'd64+i);
    //$display("WB Bus Write Transfer [%0t]\n\
    //data : %d\n\
    //---------------------------------",$time,8'd64+i);
    //alt_write_value = alt_write_value+1;
    wb_bus.master_write(CMDR,8'bxxxxx001);
    wait_for_irq();
    //Stop command
    //wb_bus.master_write(CMDR, 8'bxxxxx101);
    //wait_for_irq();
//-----------------------------------------------------------
//read values
    //Start Command
    wb_bus.master_write(CMDR,8'bxxxxx100);
    //$display("Start command of read part in alt read/write");
    wait_for_irq();

    wb_bus.master_write(DPR,8'h45);
    wb_bus.master_write(CMDR,8'bxxxxx001);
    //$display("Error part maybe");
    wait_for_irq();
    if(i==63) begin 
      last = 1'b1;
    end
    wb_bus.master_write(CMDR,{5'bx,3'b010^last});
    wait_for_irq();
    wb_bus.master_read(DPR,data);
    assert (data == (8'd63-i)) begin end 
    else   $fatal("wrong data = %d, ans = %d",data,(8'd63-i));

  end
  wb_bus.master_write(CMDR,8'bxxxxx101);
  wait_for_irq();
  #1000 $finish;
end

// ****************************************************************************
//Monitor I2C bus and display transfers in transcript
// temporary variables for i2c 

initial begin : i2c_testflow
   #113 forever begin 
   i2c_bus.monitor(i2c_addr,op,read_data_i2c);
    if(op == 1'b0) begin 
      $display("I2C_BUS Write transfer :- addr - %x, data - %d",i2c_addr,read_data_i2c);
    end
    else begin 
      $display("I2C_BUS Read transfer :-addr - %x, data - %p",i2c_addr,read_data_i2c);
      //foreach(read_data_i2c[i]) begin
      //  $display ("addr - %x, data - %d",i2c_addr,read_data_i2c[i]);
      //end
    end
   end
end  

// ****************************************************************************
// Define the flow of the simulation
//i2c flow
initial begin : i2c_flow
    bit i2c_op;
    bit [i2c_data_wid-1:0] write_data[];
    bit [i2c_data_wid-1:0] read_data[];
    bit transfer_complete;
    //transfer_complete=1'b0;
    i2c_bus.wait_for_i2c_transfer(i2c_op,write_data);
    foreach(write_data[i]) begin 
      if(i<32) begin 
        assert (i == write_data[i]) begin end 
        else   $fatal("wrong write data!");
      end
    end

  i2c_bus.wait_for_i2c_transfer(i2c_op,write_data);
  if(i2c_op) begin 
    read_data = new[1];
    read_data[0]=8'd100;
    do begin 
      i2c_bus.provide_read_data(read_data,transfer_complete);
      read_data[0] = read_data[0]+1;
    end while(!transfer_complete);
  end

  read_data = new[1];
  for(int i=0;i<64;i=i+1) begin 
    i2c_bus.wait_for_i2c_transfer(i2c_op,write_data);
    //$display("write data = ", write_data[0]);
    assert(i2c_op == 1'b0) begin end 
    else   $fatal("I2C op is not write");
    assert (write_data[0] == (signed'(8'd64)+i)) begin end 
    else   $fatal("Write data does not match");
    i2c_bus.wait_for_i2c_transfer(i2c_op,write_data);
    assert (i2c_op == 1) begin end 
    else   $fatal("i2c pp is not read");
    read_data[0] = 8'd63 - i ;
    i2c_bus.provide_read_data(read_data, transfer_complete);
  end
end


//// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

i2c_if #(
    .i2c_addr_wid(i2c_addr_wid),
    .i2c_data_wid(i2c_data_wid),
    .NUM_I2C_BUSSES(NUM_I2C_BUSSES))
i2c_bus(
    .scl_s(scl[0]),
    .sda_s(sda[0]));

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );


endmodule
