`include "mycpu.h"

module CP0(
    input                           clk           ,
    input                           reset         ,
    input                           db_flag       ,
    input         [31:0]            pc            ,
    input         [4 :0]            excode        ,
    input         [31:0]            cp0_wdata     ,
    input         [31:0]            cp0_addr      ,
    output                          pipeline_flush,
    output        [31:0]            cpo_status    ,
    output        [31:0]            exception_pc
);

// regsiter about Status, Cause, EPC

wire mtc0_we;               // signal of CP0 write enable
wire cp0_status_bev;
reg [7:0] cp0_status_im;
reg cp0_status_exl;
wire wb_ex;
wire eret_flush;
reg cp0_status_ie;
reg [31:0] cp0_epc;

always @(posedge clk) begin
    if (reset) begin
        pipeline_flush <= 1'b0;
    end
    else if(wb_ex) begin
        pipeline_flush <= 1'b1;
    end
    else begin
        pipeline_flush <= 1'b0;
    end
end

always @(posedge clk) begin
    if (reset) begin
        cp0_status_exl <= 1'b0;
        cp0_status_ie <= 1'b0;
    end
    else if(wb_ex) begin
        // wb stage call exception
        if(cp0_status_exl == 1'b0) begin
            cp0_epc <= (db_flag == 1'b0) ? pc : pc - 4;
            exception_pc <= 32'hBFC00380;
        end
        cp0_status_exl <= 1'b1;
        
    end
    else if(eret_flush) begin
        // ERET inst 
        cp0_status_exl <= 1'b0;
    end
    else if(mtc0_we && cp0_addr == `CR_STATUS) begin
        cp0_status_im <= cp0_wdata[15:8];
        cp0_status_ie <= cp0_wdata[0];
    end
end

assign cp0_status_bev = 1'b1;
assign mtc0_we = 1'b1;

endmodule