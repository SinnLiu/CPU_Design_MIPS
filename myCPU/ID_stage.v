`include "mycpu.h"

module id_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          es_allowin    ,
    output                         ds_allowin    ,
    //from fs
    input                          fs_to_ds_valid,
    input  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus  ,
    //to es
    output                         ds_to_es_valid,
    output [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to fs
    output [`BR_BUS_WD       -1:0] br_bus        ,
    //to rf: for write back
    input  [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus  ,
    //pipeline-bypass
    input                          es_load_op,      // 执行级是否为load指令
    input  [31:0]                  es_to_ds_result,
    input  [31:0]                  ms_to_ds_result,
    input  [31:0]                  ws_to_ds_result,
    input  [4:0]                   ES_dest,         // 执行级目的寄存器号
    input  [4:0]                   MS_dest,         // 访存级目的寄存器号
    input  [4:0]                   WS_dest          // 写回级目的寄存器号
);

reg         ds_valid   ;
wire        ds_ready_go;

wire [31                 :0] fs_pc;
reg  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus_r;
assign fs_pc = fs_to_ds_bus[31:0];

wire [31:0] ds_inst;
wire [31:0] ds_pc  ;
assign {ds_inst,
        ds_pc  } = fs_to_ds_bus_r;

wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;
assign {rf_we   ,  //37:37
        rf_waddr,  //36:32
        rf_wdata   //31:0
       } = ws_to_rf_bus;

wire        br_taken;
wire [31:0] br_target;

wire [11:0] alu_op;
wire        load_op;
wire        src1_is_sa;
wire        src1_is_pc;
wire        src2_is_imm;
wire        src2_is_8;
wire        src2_is_zero;
wire        res_from_mem;
wire        gr_we;
wire        mem_we;
wire [ 4:0] dest;
wire [15:0] imm;
wire [31:0] rs_value;
wire [31:0] rt_value;

wire [ 5:0] op;
wire [ 4:0] rs;
wire [ 4:0] rt;
wire [ 4:0] rd;
wire [ 4:0] sa;
wire [ 5:0] func;
wire [25:0] jidx;
wire [63:0] op_d;
wire [31:0] rs_d;
wire [31:0] rt_d;
wire [31:0] rd_d;
wire [31:0] sa_d;
wire [63:0] func_d;

wire        inst_add;
wire        inst_addu;
wire        inst_sub;  
wire        inst_subu;
wire        inst_slt;
wire        inst_sltu;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_nor;
wire        inst_sll;
wire        inst_srl;
wire        inst_sra;
wire        inst_sllv;
wire        inst_srlv;
wire        inst_srav;
wire        inst_addi;
wire        inst_addiu;
wire        inst_slti;
wire        inst_sltiu;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_lui;
wire        inst_lw;
wire        inst_sw;
wire        inst_beq;
wire        inst_bne;
wire        inst_bgez;
wire        inst_bgtz;
wire        inst_bltz;
wire        inst_bltzal;
wire        inst_bgezal;
wire        inst_jal;
wire        inst_jr;
wire        inst_j;
wire        inst_jalr;

wire        dst_is_r31;  
wire        dst_is_rt;   

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;

wire        rs_eq_rt;
wire        rs_gr_eq_zero;
wire        rs_gr_zero;
wire        rs_le_zero;

wire load_stall;                        // 发生转移计算未完成的标志
wire br_stall;                          // 向取指级进行信息传递

// 这段代码在bypass或者阻塞技术上都需要
// 需要判断出是否有相关冲突产生：判断rs和rt是否存在，若存在，是否和各个dest冲突
wire src1_no_rs;    //指令 rs 域非 0，且不是从寄存器堆读 rs 的数据
wire src2_no_rt;    //指令 rt 域非 0，且不是从寄存器堆读 rt 的数据
assign src1_no_rs = 1'b0;
assign src2_no_rt = inst_addi | inst_addiu | load_op | inst_slti| inst_sltiu | inst_andi | inst_jal 
                    | inst_lui | inst_ori | inst_xori;
wire rs_wait;       //与源操作数rs对应的寄存器号一致
wire rt_wait;		//与源操作数rt对应的寄存器号一致
assign rs_wait = ~src1_no_rs & (rs!=5'd0) 
                 & ( (rs==ES_dest) | (rs==MS_dest) | (rs==WS_dest) );
assign rt_wait = ~src2_no_rt & (rt!=5'd0)
                 & ( (rt==ES_dest) | (rt==MS_dest) | (rt==WS_dest) );
                 
wire inst_no_dest;    //标记指令没有寄存器号
assign inst_no_dest = inst_beq | inst_bne | inst_bgez | inst_bgtz | inst_bltz | inst_jr | inst_j | inst_sw;

assign br_bus       = {br_stall,br_taken,br_target};

assign ds_to_es_bus = {src2_is_zero,  //137:136
                       alu_op      ,  //135:124
                       load_op     ,  //123:123
                       src1_is_sa  ,  //122:122
                       src1_is_pc  ,  //121:121
                       src2_is_imm ,  //120:120
                       src2_is_8   ,  //119:119
                       gr_we       ,  //118:118
                       mem_we      ,  //117:117
                       dest        ,  //116:112
                       imm         ,  //111:96
                       rs_value    ,  //95 :64
                       rt_value    ,  //63 :32
                       ds_pc          //31 :0
                      };

assign ds_ready_go    = ~load_stall;           // 内部状态表征信号
assign ds_allowin     = !ds_valid || ds_ready_go && es_allowin;
assign ds_to_es_valid = ds_valid && ds_ready_go;

assign load_stall = ((rs_wait & (rs == ES_dest))  || (rt_wait & (rt == ES_dest))) & es_load_op;
assign br_stall = br_taken & load_stall & {5{ds_valid}};

always @(posedge clk) begin
    if (reset) begin
        ds_valid <= 1'b0;
    end
    else if (ds_allowin) begin
        ds_valid <= fs_to_ds_valid;
    end

    if (fs_to_ds_valid && ds_allowin) begin
        fs_to_ds_bus_r <= fs_to_ds_bus;
    end
end

assign op   = ds_inst[31:26];
assign rs   = ds_inst[25:21];
assign rt   = ds_inst[20:16];
assign rd   = ds_inst[15:11];
assign sa   = ds_inst[10: 6];
assign func = ds_inst[ 5: 0];
assign imm  = ds_inst[15: 0];
assign jidx = ds_inst[25: 0];

decoder_6_64 u_dec0(.in(op  ), .out(op_d  ));
decoder_6_64 u_dec1(.in(func), .out(func_d));
decoder_5_32 u_dec2(.in(rs  ), .out(rs_d  ));
decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
decoder_5_32 u_dec5(.in(sa  ), .out(sa_d  ));

assign inst_add    = op_d[6'h00] & func_d[6'h20] & sa_d[5'h00];
assign inst_addu   = op_d[6'h00] & func_d[6'h21] & sa_d[5'h00];
assign inst_sub    = op_d[6'h00] & func_d[6'h22] & sa_d[5'h00];
assign inst_subu   = op_d[6'h00] & func_d[6'h23] & sa_d[5'h00];
assign inst_slt    = op_d[6'h00] & func_d[6'h2a] & sa_d[5'h00];
assign inst_sltu   = op_d[6'h00] & func_d[6'h2b] & sa_d[5'h00];
assign inst_and    = op_d[6'h00] & func_d[6'h24] & sa_d[5'h00];
assign inst_or     = op_d[6'h00] & func_d[6'h25] & sa_d[5'h00];
assign inst_xor    = op_d[6'h00] & func_d[6'h26] & sa_d[5'h00];
assign inst_nor    = op_d[6'h00] & func_d[6'h27] & sa_d[5'h00];
assign inst_sll    = op_d[6'h00] & func_d[6'h00] & rs_d[5'h00];
assign inst_srl    = op_d[6'h00] & func_d[6'h02] & rs_d[5'h00];
assign inst_sra    = op_d[6'h00] & func_d[6'h03] & rs_d[5'h00];
assign inst_sllv   = op_d[6'h00] & func_d[6'h04] & rs_d[5'h00];
assign inst_srlv   = op_d[6'h00] & func_d[6'h06] & rs_d[5'h00];
assign inst_srav   = op_d[6'h00] & func_d[6'h07] & rs_d[5'h00];
assign inst_addi  = op_d[6'h08];
assign inst_addiu  = op_d[6'h09];
assign inst_slti   = op_d[6'h0a];
assign inst_sltiu  = op_d[6'h0b];
assign inst_andi   = op_d[6'h0c];
assign inst_ori    = op_d[6'h0d];
assign inst_xori   = op_d[6'h0e]
assign inst_lui    = op_d[6'h0f] & rs_d[5'h00];
assign inst_lw     = op_d[6'h23];
assign inst_sw     = op_d[6'h2b];
assign inst_beq    = op_d[6'h04];
assign inst_bne    = op_d[6'h05];
assign inst_bgez   = op_d[6'h01] & rs_d[5'h01];
assign inst_bgtz   = op_d[6'h07];
assign inst_bltz   = op_d[6'h06];
assign inst_bltzal = op_d[6'h01] & rs_d[5'h10];
assign inst_bgezal = op_d[6'h01] & rs_d[5'h11];
assign inst_jal    = op_d[6'h03];
assign inst_jr     = op_d[6'h00] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];
assign inst_j      = op_d[6'h02];
assign inst_jalr   = op_d[6'h00] & func_d[6'h09];

assign alu_op[ 0] = inst_add | inst_addu | inst_addi | inst_addiu | inst_lw | inst_sw | inst_jal | inst_bltzal 
                    | inst_bgezal | inst_jalr;
assign alu_op[ 1] = inst_sub | inst_subu;
assign alu_op[ 2] = inst_slt | inst_slti | inst_sltiu;
assign alu_op[ 3] = inst_sltu;
assign alu_op[ 4] = inst_and | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or | inst_ori;
assign alu_op[ 7] = inst_xor | inst_xori;
assign alu_op[ 8] = inst_sll | inst_sllv;
assign alu_op[ 9] = inst_srl | inst_srlv;
assign alu_op[10] = inst_sra | inst_srav;
assign alu_op[11] = inst_lui;

assign load_op = inst_lw;

assign src1_is_sa   = inst_sll   | inst_srl | inst_sra;
assign src1_is_pc   = inst_jal;
assign src2_is_imm  = inst_addi | inst_addiu | inst_slti | inst_sltiu | inst_andi | inst_lui | inst_lw 
                    | inst_sw | inst_ori | inst_xori;
assign src2_is_8    = inst_jal | inst_bltzal | inst_bgezal | inst_jalr;
assign src2_is_zero = inst_andi | inst_ori | inst_xori;
assign res_from_mem = inst_lw;
assign dst_is_r31   = inst_jal | inst_bltzal | inst_bgezal;
assign dst_is_rt    = inst_addi | inst_addiu | inst_slti | inst_sltiu | inst_andi | inst_lui | inst_lw
                    | inst_ori | inst_xori;
// if inst is follow one, register file will not be writed
assign gr_we        = ~inst_sw & ~inst_beq & ~inst_bgez & ~inst_bgtz & ~inst_bne & ~inst_bltz & ~inst_jr & ~inst_j;
assign mem_we       = inst_sw;

assign dest         = dst_is_r31 ? 5'd31 :
                      dst_is_rt  ? rt    : 
                      inst_no_dest ? 5'd0: rd;

assign rf_raddr1 = rs;
assign rf_raddr2 = rt;
regfile u_regfile(
    .clk    (clk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

// 原始的读取方式
// assign rs_value = rf_rdata1;
// assign rt_value = rf_rdata2;
// 首先需要判断是否有dest和src的重合，再进行value的生成
assign rs_value = rs_wait ? ((rs==ES_dest) ? es_to_ds_result :
                  (rs==MS_dest) ? ms_to_ds_result : ws_to_ds_result) : rf_rdata1;
assign rt_value = rt_wait ? ((rt==ES_dest) ? es_to_ds_result :
                  (rt==MS_dest) ? ms_to_ds_result : ws_to_ds_result) : rf_rdata2;
// 译码级bypass处理结束
assign rs_eq_rt = (rs_value == rt_value);
assign rs_gr_eq_zero = (rs_gr_zero | (rs_value == 0)) ;
assign rs_gr_zero = (rs_value > 0);
assign rs_le_zero = (rs_value <= 0);
assign br_taken = (   inst_beq  &&  rs_eq_rt
                   || inst_bne  && !rs_eq_rt
                   || inst_bgez && rs_gr_eq_zero
                   || inst_bgtz && rs_gr_zero
                   || inst_bltz && rs_le_zero
                   || inst_jal
                   || inst_bltzal && rs_le_zero
                   || inst_bgezal && rs_gr_eq_zero
                   || inst_jr
                   || inst_j
                   || inst_jalr
                  ) && ds_valid;
assign br_target = (inst_beq || inst_bne || inst_bgez || inst_bgtz || inst_bltz || rs_le_zero) ? (fs_pc + {{14{imm[15]}}, imm[15:0], 2'b0}) :
                   (inst_jr || inst_jalr)              ? rs_value :
                  /*inst_jal || inst_j || inst_bltzal || inst_bgezal*/              
                   {fs_pc[31:28], jidx[25:0], 2'b0};

endmodule
