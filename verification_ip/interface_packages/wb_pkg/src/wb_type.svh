parameter int wb_addr_wid = 2;
parameter int wb_data_wid = 8;

typedef enum bit [1:0] {
  CSR=2'd0,
  DPR=2'd1,
  CMDR=2'd2,
  FSMR=2'd3
}reg_off;

typedef enum bit{
    WB_Read  = 0,
    WB_Write = 1
} wb_op_t;

typedef enum bit[2:0]{
  
  CMDR_WAIT = 3'b000,         //0
  CMDR_WRITE = 3'b001,        //1
  CMDR_READ_W_AK = 3'b010,    //2
  CMDR_READ_W_NAK = 3'b011,
  CMDR_START = 3'b100,
  CMDR_STOP = 3'b101,
  CMDR_SET_BUS = 3'b110,
  CMDR_NOT_USED = 3'b111
} cmdr_cmd;

string  map_reg_ofst_name [ reg_off ] = '{
    CSR             :   "CSR" ,
    DPR             :   "DPR" ,
    CMDR            :   "CMDR",
    FSMR            :   "FSMR"
};
string  map_cmd_name [ cmdr_cmd ] = '{
    CMDR_SET_BUS     :   "CMD_SET_BUS",
    CMDR_START       :   "CMD_START",
    CMDR_WRITE       :   "CMD_WRITE",
    CMDR_STOP        :   "CMD_STOP",
    CMDR_READ_W_NAK  :   "CMD_READ_W_NAK",
    CMDR_READ_W_AK   :   "CMD_READ_W_AK",
    CMDR_WAIT        :   "CMD_WAIT"
};

string map_we_name [wb_op_t] = '{
    WB_Read  :"Read",
    WB_Write :"Write"
};