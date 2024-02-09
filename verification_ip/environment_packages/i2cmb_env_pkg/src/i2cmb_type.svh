typedef enum bit [2:0]{
    S_IDLE      =        3'd0,
    S_Bus_taken =        3'd1,
    S_str_pend  =        3'd2,
    S_str       =        3'd3,
    S_stp       =        3'd4,
    S_write_byte=        3'd5,
    S_read_byte =        3'd6,
    S_wait      =        3'd7
} Byte_fsm;

typedef enum bit [0:3]{
    idle        =        4'd0,
    start_A        =        4'd1,
    start_B        =        4'd2,
    start_C        =        4'd3,
    r_w_A        =        4'd4,
    r_w_B        =        4'd5,
    r_w_C        =        4'd6,
    r_w_D        =        4'd7,
    r_w_E        =        4'd8,
    stp_A        =        4'd9,
    stp_B        =        4'd10,
    stp_C        =        4'd11,
    rst_A        =        4'd12,
    rst_B        =        4'd13,
    rst_C        =        4'd14
}Bit_fsm;

typedef struct{
    bit don;
    bit nak;
    bit al;
    bit err;
    bit r;
    cmdr_cmd cmd;
}CMDR_reg;

typedef struct{
    bit e;
    bit ie;
    bit bb;
    bit bc;
    bit [3:0] bus_id;
} CSR_reg;

typedef struct{
    Byte_fsm fsm_byte;
    bit [3:0] fsm_bit;
} FSMR_reg;