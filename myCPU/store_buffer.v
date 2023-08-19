module store_buffer(
    input                          clk           ,
    input                          reset         ,
    input          from_wb_stroe_inst,
    // data sram interface in
    input        data_sram_en_in    ,
    input [ 3:0] data_sram_wen_in   ,
    input [31:0] data_sram_addr_in  ,
    input [31:0] data_sram_wdata_in ,

    // data sram interface out
    output        data_sram_en_out    ,
    output [ 3:0] data_sram_wen_out   ,
    output [31:0] data_sram_addr_out  ,
    output [31:0] data_sram_wdata_out ,
);
reg [31:0] data_buffer [15:0];
reg [31:0] addr_buffer [15:0];
reg [3:0] wen_buffer  [15:0];
reg [3:0] fifo_head;
reg [3:0] fifo_tail;
wire is_store_inst;

always @(posedge clk) begin
    if (reset) begin
        fifo_tail <= 4'h0;
    end 
    else if(data_sram_en) begin
        data_buffer[fifo_tail] <= data_sram_wdata_in;
        addr_buffer[fifo_tail] <= data_sram_addr_in;
        wen_buffer[fifo_tail] <= data_sram_wen_out;
        fifo_tail <= fifo_tail + 4'h1;
    end
end

always @(posedge clk) begin
    if (reset) begin
        fifo_head <= 4'h0;
    end 
    else if(from_wb_stroe_inst) begin
        fifo_head <= fifo_head + 4'h1;
    end
end
assign data_sram_en_out   =  from_wb_stroe_inst;
assign data_sram_wen_out  =  data_buffer [fifo_head];
assign data_sram_addr_out =  addr_buffer [fifo_head];
assign data_sram_wen_out  =  wen_buffer  [fifo_head];
endmodule