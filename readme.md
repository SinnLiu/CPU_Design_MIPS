# CPU设计实战

支持的指令

| 指令类别 | 指令 |
| --- | --- |
| 运算指令 | ADDU,ADDIU,SUBU,ADD,ADDI,SUB |
| 转移指令 |  |
| 访存指令 |  |

# 带有Inst RAM和Data RAM的仿真流程
# 片外DDR流程
# TODO List
- [ ] 流水线前递解决相关冲突
  - [x] 加入各级dest信号到译码级，增加有效位判断
  - [x] 译码级进行bypass逻辑处理
  - [x] top模块连线
  - [x] 实验验证
- [ ] 添加算术逻辑运算类指令ADD,ADDI,SUB