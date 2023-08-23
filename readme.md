# CPU���ʵս

֧�ֵ�ָ��

| ָ����� | ָ�� |
| --- | --- |
| ����ָ�� | ADDU,ADDIU,SUBU,ADD,ADDI,SUB,SLTI,SLTIU,ANDI,ORI,XORI,SLLV,SRLV,SRAV |
| ת��ָ�� |  |
| �ô�ָ�� |  |

# ����Inst RAM��Data RAM�ķ�������
# Ƭ��DDR����
# TODO List
- [x] ��ˮ��ǰ�ݽ����س�ͻ
  - [x] �������dest�źŵ����뼶��������Чλ�ж�
  - [x] ���뼶����bypass�߼�����
  - [x] topģ������
  - [x] ʵ����֤
- [x] ��������߼�������ָ��ADD,ADDI,SUB,SLTI,SLTIU,ANDI,ORI,XORI,SLLV,SRLV,SRAV
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
- [ ] ��ӳ˳���ָ��
  - [ ] booth ����˷���
- [ ] ���ת��ָ��
  - [x] BGEZ
  - [x] BGTZ
  - [ ] BLTZ
  - [ ] J
  - [ ] BLTZAL
  - [ ] BGEZAL
  - [ ] JALR
- [ ] ���������жϵ�֧��

# ������־
## 2023.08.23
1. ̽����store buffer���ƣ�����Ŀǰ�ļܹ����ʺϽ�store�����ƶ���wb stage��������лع�
2. �޸�`ID stage`�е�`br_taken`Ϊ`br_token`
3. �����`BGEZ`ָ���`BGTZ`ָ��
   - ��`ID stage`�����`inst_bgez`��`inst_bgtz`�źţ����Ӷ�ָ����ж�
   - ���`rs_gr_eq_zero`��`rs_gr_zero`�źţ���ӷ�ָ֧����ת���ж��߼�
   - ���`inst_no_dest`�źŵ���Ŀ�ĵ�ַ�ж�
   - ���`gr_we`�źŷ�дͨ�üĴ����ж�
   - ����תָʾ�ź�`br_token`������`inst_bgez`��`inst_bgtz`
   - ��`br_target`������`inst_bgez`��`inst_bgtz`��ת�Ƶ�ַ���߼���`BEQ`��ͬ

## 2023.06.15
1. �����SLLVָ��
   - ���`inst_sllv`�ź���
   - ����`inst_sllv`�ź���
   - ����`inst_sll`�źŶ�ALU�Ŀ���
2. �����SRLVָ��
3. �����SRAVָ��

## 2023.05.28
1. �����ORIָ��
   - ���`inst_ori`�ź���
   - ����`inst_ori`�źţ���opcodeΪ0x0d
   - ��������ָ������ź�`src2_no_rt`��`src2_is_imm`��`dst_is_rt`������ź�
   - ��`src2_is_zero`�ź�������ź���ʵ������չ
   - alu�����ź�`alu_op[ 6]`����źţ�����ORָ����exe�׶ε�����ͨ·������ALU
2. �����XORIָ��
   - ����`inst_ori`�źţ���opcodeΪ0x0e
   - alu�����ź�`alu_op[ 7]`����źţ�����XORָ����exe�׶ε�����ͨ·������ALU
   - ����ͬ��

## 2023.04.07
1. �����SLTIUָ��
   - ���`inst_sltiu`�ź���
   - alu�����ź�`alu_op[ 2]`���`inst_sltiu`�ź�
   - ��������ָ������ź�`src2_no_rt`��`src2_is_imm`��`dst_is_rt`�����`inst_sltiu`�ź�
2. �����ANDIָ��
   - ��***ID_stage***������`src2_is_zero`�ź��ж�����չ������`ds_to_es_bus`���
   - �޸�`define DS_TO_ES_BUS_WD 136`Ϊ`define DS_TO_ES_BUS_WD 137`
   - ���`inst_andi`�ź���
   - ��ȡ`inst_andi`�ź�
   - alu�����ź�`alu_op[ 4]`���`inst_andi`�ź�
   - ��������ָ������ź�`src2_no_rt`��`src2_is_imm`��`dst_is_rt`�����`inst_andi`�ź�
   - ��`src2_is_zero`�ź������`inst_andi`�ź�
   - ��***EXE_stage***�����`es_src2_is_zero`�ź�
   - ��***EXE_stage***���������չ�߼�`es_src2_is_zero? {{16'd0}, es_imm[15:0]}:`


## 2023.04.06
�����SLTIָ�
- ���`inst_slti`�ź���
- alu�����ź�`alu_op[ 2]`���`inst_slti`�ź�
- ��������ָ������ź�`src2_no_rt`��`src2_is_imm`��`dst_is_rt`�����`inst_slti`�ź�

## 2023.04.05
1. �����SUBָ��
2. ������`decoder_6_64`��������ԭ��
3. ����SUB��SUBUָ���`alu_op[ 1]`�������ã�������Ҫ��ע
