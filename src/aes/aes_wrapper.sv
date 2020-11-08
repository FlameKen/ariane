

module aes_wrapper #(
    parameter int ADDR_WIDTH         = 32,   // width of external address bus
    parameter int DATA_WIDTH         = 32   // width of external data bus
)(
           clk_i,
           rst_ni,
           reglk_ctrl_i,
           key_in,
           testCycle,
           external_bus_io
       );

    input  logic                   clk_i;
    input  logic                   rst_ni;
    input logic [7 :0]             reglk_ctrl_i; // register lock values
    input  logic    [191:0]        key_in;
    input  logic    [191:0]        testCycle;
    REG_BUS.in                     external_bus_io;

// internal logics

logic start;
logic [31:0] p_c [0:3];
logic [31:0] state [0:3];
logic [31:0] key0 [0:5]; 
logic [31:0] key1 [0:5]; 
logic [31:0] key2 [0:5]; 

logic [1:0] key_sel; 

logic   [127:0] p_c_big   ;  
logic   [127:0] state_big ;  
logic   [191:0] key_big ;  
logic   [191:0] key_big0, key_big1, key_big2 ;  
logic   [127:0] ct;
logic           ct_valid;
logic  [3:0]clock;

assign external_bus_io.ready = 1'b1;
assign external_bus_io.error = 1'b0;

assign p_c_big    = {p_c[0], p_c[1], p_c[2], p_c[3]};
assign state_big  = {state[0], state[1], state[2], state[3]};
assign key_big0    = {key0[0], key0[1], key0[2], key0[3], key0[4], key0[5]}; 
assign key_big1    = {key1[0], key1[1], key1[2], key1[3], key1[4], key1[5]}; 
assign key_big2    = {key2[0], key2[1], key2[2], key2[3], key2[4], key2[5]}; 
///////////////////////////////////////////////////////////////////////////
logic t_clk;     
logic t_reset;   
logic [31:0]t_i_addr;
logic t_i_write ; // 0=read, 1=write
logic [31:0]t_i_rdata;
logic [31:0]t_i_wdata;
logic [3:0]t_i_wstrb ; //// byte-wise strobe
logic t_i_error ; // 0=ok, 1=error
logic t_i_valid ;
logic t_i_ready ;
logic [31:0]t_o_addr ;
logic t_o_write ;
logic [31:0]t_o_rdata ;
logic [31:0]t_o_wdata ;
logic [3:0]t_o_wstrb ;
logic t_o_error ;
logic t_o_valid ;
logic t_o_ready ;
logic t_alarm   ;
logic t_ext_wr   ;
logic [10:0]t_ext_data_in ;
logic [19:0]t_ext_act_in ;
logic [3:0]t_ext_addr ;
logic test;
///////////////////////////////////////////////////////////////////////////
assign t_clk = clk_i;
assign t_reset = ~rst_ni;
assign t_i_addr = external_bus_io.addr;
assign t_i_write = external_bus_io.write;
assign t_i_rdata = external_bus_io.rdata;
assign t_i_ready = external_bus_io.ready;
assign t_i_wdata = external_bus_io.wdata;
assign t_i_valid = external_bus_io.valid;
assign t_i_wstrb = external_bus_io.wstrb;
assign test = t_i_valid+t_i_write;
///////////////////////////////////////////////////////////////////////////
// Implement APB I/O map to AES interface
always @(posedge clk_i)
    begin
        if(~rst_ni)
            begin
                start <= 0;
                p_c[0] <= 0;
                p_c[1] <= 0;
                p_c[2] <= 0;
                clock <=0;
                p_c[3] <= 0;
                state[0] <= 0;
                state[1] <= 0;
                state[2] <= 0;
                state[3] <= 0;
                // clock <= 0;
                // $display("start at : %d, clock %b\n",testCycle,clk_i);
            end
        else if(external_bus_io.write)begin
            case(external_bus_io.addr[8:2])
                0:
                    start  <= reglk_ctrl_i[1] ? start  : external_bus_io.wdata[0];
                1:
                    p_c[3] <= reglk_ctrl_i[3] ? p_c[3] : external_bus_io.wdata;
                2:
                    p_c[2] <= reglk_ctrl_i[3] ? p_c[2] : external_bus_io.wdata;
                3:
                    p_c[1] <= reglk_ctrl_i[3] ? p_c[1] : external_bus_io.wdata;
                4:
                    p_c[0] <= reglk_ctrl_i[3] ? p_c[0] : external_bus_io.wdata;
                5:   
                    key0[5] <= reglk_ctrl_i[5] ? key0[5] : external_bus_io.wdata;
                6:                                        
                    key0[4] <= reglk_ctrl_i[5] ? key0[4] : external_bus_io.wdata;
                7:                                        
                    key0[3] <= reglk_ctrl_i[5] ? key0[3] : external_bus_io.wdata;
                8:                                        
                    key0[2] <= reglk_ctrl_i[5] ? key0[2] : external_bus_io.wdata;
                9:                                        
                    key0[1] <= reglk_ctrl_i[5] ? key0[1] : external_bus_io.wdata;
                10:
                    key0[0] <= reglk_ctrl_i[5] ? key0[0] : external_bus_io.wdata;
                16:
                    state[3] <= reglk_ctrl_i[7] ? state[3] : external_bus_io.wdata;
                17:                                        
                    state[2] <= reglk_ctrl_i[7] ? state[2] : external_bus_io.wdata;
                18:                                        
                    state[1] <= reglk_ctrl_i[7] ? state[1] : external_bus_io.wdata;
                19:                                        
                    state[0] <= reglk_ctrl_i[7] ? state[0] : external_bus_io.wdata;
                20:
                    key1[5] <= reglk_ctrl_i[5] ? key1[5] : external_bus_io.wdata;
                21:                                       
                    key1[4] <= reglk_ctrl_i[5] ? key1[4] : external_bus_io.wdata;
                22:                                       
                    key1[3] <= reglk_ctrl_i[5] ? key1[3] : external_bus_io.wdata;
                23:                                       
                    key1[2] <= reglk_ctrl_i[5] ? key1[2] : external_bus_io.wdata;
                24:                                       
                    key1[1] <= reglk_ctrl_i[5] ? key1[1] : external_bus_io.wdata;
                25:                                        
                    key1[0] <= reglk_ctrl_i[5] ? key1[0] : external_bus_io.wdata;
                26:
                    key2[5] <= reglk_ctrl_i[5] ? key2[5] : external_bus_io.wdata;
                27:                                       
                    key2[4] <= reglk_ctrl_i[5] ? key2[4] : external_bus_io.wdata;
                28:                                       
                    key2[3] <= reglk_ctrl_i[5] ? key2[3] : external_bus_io.wdata;
                29:                                       
                    key2[2] <= reglk_ctrl_i[5] ? key2[2] : external_bus_io.wdata;
                30:                                       
                    key2[1] <= reglk_ctrl_i[5] ? key2[1] : external_bus_io.wdata;
                31:                                        
                    key2[0] <= reglk_ctrl_i[5] ? key2[0] : external_bus_io.wdata;
                32: 
                    key_sel <= reglk_ctrl_i[5] ? key_sel : external_bus_io.wdata;
                33:
                    $display("clock : %d\n",testCycle);
                default:
                    ;
            endcase
        end
    end // always @ (posedge wb_clk_i)

// Implement MD5 I/O memory map interface
// Read side
//always @(~external_bus_io.write)
always @(*)
    begin
        case(external_bus_io.addr[8:2])
            0:
                external_bus_io.rdata = reglk_ctrl_i[0] ? 'b0 : {31'b0, start};
            1:
                external_bus_io.rdata = reglk_ctrl_i[2] ? 'b0 : p_c[3];
            2:
                external_bus_io.rdata = reglk_ctrl_i[2] ? 'b0 : p_c[2];
            3:
                external_bus_io.rdata = reglk_ctrl_i[2] ? 'b0 : p_c[1];
            4:
                external_bus_io.rdata = reglk_ctrl_i[2] ? 'b0 : p_c[0];
            11:
                external_bus_io.rdata = reglk_ctrl_i[6] ? 'b0 : {31'b0, ct_valid};
            12:
                external_bus_io.rdata = reglk_ctrl_i[4] ? 'b0 : ct[31:0];
            13:                                                 
                external_bus_io.rdata = reglk_ctrl_i[4] ? 'b0 : ct[63:32];
            14:                                                 
                external_bus_io.rdata = reglk_ctrl_i[4] ? 'b0 : ct[95:64];
            15:                                                 
                external_bus_io.rdata = reglk_ctrl_i[4] ? 'b0 : ct[127:96];
            default:
                external_bus_io.rdata = 32'b0;
        endcase
    end // always @ (*)


// select the proper key

assign key_big = key_sel[1] ? key_big2 : ( key_sel[0] ? key_big1 : key_big0 );  

// newmop_4 mop (   
//                 .clk(t_clk),
//                 .reset(t_reset),
//                 .i_addr(t_i_addr),
//                 .i_write(t_i_write),
//                 .i_rdata(t_i_rdata),
//                 .i_wdata(t_i_wdata),
//                 .i_wstrb(t_i_wstrb),
//                 .i_valid(t_i_valid),
//                 .i_ready(t_i_ready),
//                 .i_error(t_i_error),
//                 .o_addr(t_o_addr),
//                 .o_write(t_o_write),
//                 .o_rdata(t_o_rdata),
//                 .o_wdata(t_o_wdata),
//                 .o_valid(t_o_valid),
//                 .o_ready(t_o_ready)
//             );
aes_192_sed aes(
            .clk(clk_i),
            .state(state_big),
            .p_c_text(p_c_big),
            .key(key_big),
            .start(start),
            .out(ct),
            .out_valid(ct_valid)
        );
// aes_192_sed aes(
//             .clk(clk_i),
//             .state(state_big),
//             .p_c_text(p_c_big),
//             .key(key_big),
//             .start(start),
//             .out(ct),
//             .out_valid(ct_valid)
//         );

endmodule
