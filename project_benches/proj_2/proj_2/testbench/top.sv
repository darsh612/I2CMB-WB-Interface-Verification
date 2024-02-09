`timescale 1ns / 10ps

module top();

import ncsu_pkg::*;
import wb_pkg::*;
import i2c_pkg::*;
import i2cmb_env_pkg::*;

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

//***********************************************************************
//My parameters
//***********************************************************************

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



// ****************************************************************************


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
  .irq_i(irq),
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
  

  i2cmb_test tst;
  
  initial begin : test_flow
  
  
      ncsu_config_db#(virtual wb_if#(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)))::set("tst.i2cmb_env.wb_agen", wb_bus);
      ncsu_config_db#(virtual i2c_if#(.I2C_ADDR_WIDTH(i2c_addr_wid), .I2C_DATA_WIDTH(i2c_data_wid), .NUM_I2C_BUSSES(NUM_I2C_BUSSES)))::set("tst.i2cmb_env.i2c_agen", i2c_bus);
  
      tst = new("tst", null);
      wait( rst==0 );
      tst.run();
      #1000ns $finish;
  end


endmodule
