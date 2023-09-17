`include "mycpu.h"

module CP0(
    input                           clk           ,
    input                           reset         ,
);

wire cp0_status_bev;
assign cp0_status_bev = 1'b1;

endmodule