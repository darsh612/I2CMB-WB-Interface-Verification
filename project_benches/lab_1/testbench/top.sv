`timescale 1ns / 10ps

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

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
logic [WB_ADDR_WIDTH-1:0] addr_p;
logic [WB_DATA_WIDTH-1:0] data_p;
logic we_p;

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
    wb_bus.master_monitor(addr_p,data_p,we_p);
    $display("addr :- %h, data :- %h, we :- %b",addr_p, data_p, we_p);
    //$display("data %h",data_p);
    //$display("we %b",we_p);
  end
  end
// ****************************************************************************
// Define the flow of the simulation

task wait_for_irq();
  wait(irq);
  //reading CMDR clears interrupt
  wb_bus.master_read(CMDR,data_p);
endtask

initial begin: test_flow
  @(negedge rst);
  repeat(3) @(posedge clk);

  wb_bus.master_write(CSR,8'b11000000);
  wb_bus.master_write (DPR, 8'h05);
  wb_bus.master_write (CMDR, 8'bxxxxx110);
  wait_for_irq();
  //while(!irq || data[7]!=1) begin:
  //   wait();
  //end
  wb_bus.master_write(CMDR, 8'bxxxxx100);
  //wb_bus.master_read(.addr('h02), .data('bxxxxx100));
  wait_for_irq();
  wb_bus.master_write(DPR, 8'h44);
  wb_bus.master_write(CMDR, 8'bxxxxx001);
  wait_for_irq();
  wb_bus.master_write(DPR, 8'h78);
  wb_bus.master_write(CMDR, 8'bxxxxx001);
  wait_for_irq();
  wb_bus.master_write(CMDR,8'bxxxxx101);
  wait_for_irq();
  $finish;

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
