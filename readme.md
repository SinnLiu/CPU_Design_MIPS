# CPU设计实战

支持的指令

| 指令类别 | 指令 |
| --- | --- |
| 运算指令 | ADDU,ADDIU,SUBU,ADD,ADDI,SUB,SLTI,SLTIU,ANDI,ORI,XORI,SLLV,SRLV,SRAV |
| 转移指令 |  |
| 访存指令 |  |

# 带有Inst RAM和Data RAM的仿真流程
# 片外DDR流程
# TODO List
- [x] 流水线前递解决相关冲突
  - [x] 加入各级dest信号到译码级，增加有效位判断
  - [x] 译码级进行bypass逻辑处理
  - [x] top模块连线
  - [x] 实验验证
- [x] 添加算术逻辑运算类指令ADD,ADDI,SUB,SLTI,SLTIU,ANDI,ORI,XORI,SLLV,SRLV,SRAV
  - [x] ADD
  - [x] ADDI
  - [x] SUB
  - [x] SLTI
  - [x] SLTIU
  - [x] ANDI
  - [x] ORI
  - [x] XORI
  - [x] SLLV
  - [x] SRLV
  - [x] SRAV
- [ ] 添加乘除法指令
  - [ ] booth 定点乘法器
- [ ] 添加转移指令
  - [x] BGEZ
  - [x] BGTZ
  - [ ] BLTZ
  - [ ] J
  - [ ] BLTZAL
  - [ ] BGEZAL
  - [ ] JALR
- [ ] 添加例外和中断的支持

# 更新日志
## 2023.08.23
1. 探索了store buffer机制，发现目前的架构不适合将store操作移动到wb stage，代码进行回滚
2. 修改`ID stage`中的`br_taken`为`br_token`
3. 添加了`BGEZ`指令和`BGTZ`指令
   - 在`ID stage`中添加`inst_bgez`和`inst_bgtz`信号，增加对指令的判断
   - 添加`rs_gr_eq_zero`和`rs_gr_zero`信号，添加分支指令跳转的判断逻辑
   - 添加`inst_no_dest`信号的无目的地址判断
   - 添加`gr_we`信号非写通用寄存器判断
   - 在跳转指示信号`br_token`中增加`inst_bgez`和`inst_bgtz`
   - 在`br_target`中增加`inst_bgez`和`inst_bgtz`的转移地址，逻辑与`BEQ`相同

## 2023.06.15
1. 添加了SLLV指令
   - 添加`inst_sllv`信号线
   - 解码`inst_sllv`信号线
   - 复用`inst_sll`信号对ALU的控制
2. 添加了SRLV指令
3. 添加了SRAV指令

## 2023.05.28
1. 添加了ORI指令
   - 添加`inst_ori`信号线
   - 解析`inst_ori`信号，其opcode为0x0d
   - 在立即数指令控制信号`src2_no_rt`、`src2_is_imm`、`dst_is_rt`上添加信号
   - 在`src2_is_zero`信号上添加信号以实现零扩展
   - alu控制信号`alu_op[ 6]`添加信号，复用OR指令在exe阶段的数据通路，调用ALU
2. 添加了XORI指令
   - 解析`inst_ori`信号，其opcode为0x0e
   - alu控制信号`alu_op[ 7]`添加信号，复用XOR指令在exe阶段的数据通路，调用ALU
   - 其余同上

## 2023.04.07
1. 添加了SLTIU指令
   - 添加`inst_sltiu`信号线
   - alu控制信号`alu_op[ 2]`添加`inst_sltiu`信号
   - 在立即数指令控制信号`src2_no_rt`、`src2_is_imm`、`dst_is_rt`上添加`inst_sltiu`信号
2. 添加了ANDI指令
   - 在***ID_stage***增加了`src2_is_zero`信号判断零扩展，并在`ds_to_es_bus`添加
   - 修改`define DS_TO_ES_BUS_WD 136`为`define DS_TO_ES_BUS_WD 137`
   - 添加`inst_andi`信号线
   - 读取`inst_andi`信号
   - alu控制信号`alu_op[ 4]`添加`inst_andi`信号
   - 在立即数指令控制信号`src2_no_rt`、`src2_is_imm`、`dst_is_rt`上添加`inst_andi`信号
   - 在`src2_is_zero`信号上添加`inst_andi`信号
   - 在***EXE_stage***中添加`es_src2_is_zero`信号
   - 在***EXE_stage***中添加零扩展逻辑`es_src2_is_zero? {{16'd0}, es_imm[15:0]}:`


## 2023.04.06
添加了SLTI指令：
- 添加`inst_slti`信号线
- alu控制信号`alu_op[ 2]`添加`inst_slti`信号
- 在立即数指令控制信号`src2_no_rt`、`src2_is_imm`、`dst_is_rt`上添加`inst_slti`信号

## 2023.04.05
1. 添加了SUB指令
2. 分析了`decoder_6_64`解码器的原理
3. 发现SUB与SUBU指令对`alu_op[ 1]`产生作用，后续需要关注
