/Including design files
`include "Register_file.sv"
`include "Instruction_Memory.sv"
`include "Data_Memory.sv"
`include "Control_Unit.sv"
`include "ALU.sv"
`include "PC.sv"
`include "Pipeline_Stages.sv"
`include "Logic_blocks.sv"
`include "Hazard_Unit.sv"
`include "cache.sv"
`include "floating_point_unit.sv"
`include "signal_list.sv"

/*----------------Pipelined Data Path---------------- */

module Core(input clk, [31:0] pc);
  
 import signals:: *; 
 assign jump_ext = Instr[25:0] << 2; //to store shifted bits
 //Instantiating components
  
  mux PC_branch_mux(.a(pc_plus_4), .b(adder_to_pc), .sel(PCSrcD), .out(mux_to_pc)); //MUX to select next PC
  
  
  //updating instance for RISC-V
  mux jump_link_mux(.a(alu_to_reg_out), .b(({{12{jump_link[19]}},jump_ext} + pc_out)), .sel(Jump), .out(jal_mux)); //MUX to select next PC 
  
  PC PC_Inst (.clk(clk), .PC_NEXT(pc), .PC_CRNT(pc_out)); //PC instance
  
  PC_Adder PC_Plus__4 (.PC_instr(pc_out), .PC_nxt_instr(pc_plus_4)); //PC Adder Instance
  
  
  Instruction_Memory Instr_Mem(.PCF(pc_out), .instruction(Instr));  //Instruction Memory instance
  
  //first pipeline register : Fetch to Decode
  
  IF_ID IF_ID_Stage(.CLK(clk), .EN(StallF), .CLR(PCSrcD), .RD_IN(Instr), .PCPlus4F(pc_plus_4), .InstrD(InstrD), .PCPlus4D(PCPlus4D));
  
  //Control Unit instance
  
  Control_Unit cntrl_unit(.Instruction(InstrD), .Mem_to_reg(mem_to_reg), .MemWrite(mem_write), .Branch(BranchD), .ALUSrc(ALUsrc), .RegDst(reg_dest), .RegWrite(RegWrite), .ALUCtl(alu_control), .Jump(Jump), .shamt(shamt), .imm_select(immediate_select_control), .load_store_op(load_store_sig), .sel_fp_srcae(sel_fp_srcae), .sel_mx_offset(sel_mx_offset), .fp_load_store(fp_load_store), .fp_ld_rf_dmx(mem_dmx_sel)); 
  
  //Updated this control unit instance according to RISC-V 32I base format
  
  //Register file instance
  
  REGISTER_FILE RegFile(.CLK(clk), .A1(InstrD[19:15]), .RD1(rd_1), .RD2(rd_2), .A2(InstrD[24:20]), .A3(WriteRegW), .WD3(jal_mux), .WE3(RegWriteW)); //RegFile Instance
  
  //Sign Extension instance for I-type instruction format
  
  SignExtend SigExtd (.IMM(InstrD[31:20]), .SignImm(sign_imm)); //Sign Immediate instance
  
  //Sign Extension for B-type instruction
  wire [31:0] branch_sig_exd;
  
  SignExtend Br_ext(.IMM({InstrD[31], InstrD[7], InstrD[30:25], InstrD[11:8]}), .SignImm(branch_sig_exd));
  
  
  //Sign Extension for U-type instruction
  wire [31:0] u_sign_extd;
  
  SignExtend U_extd(.IMM(InstrD[31:12]), .SignImm(u_sign_extd));
  defparam U_extd.size = 20;
  
  //muxes for branch instruction..
  wire Forward_AD, Forward_BD;
  wire [31:0] r_1_out, r_2_out;
  
  mux r_1_mx(.a(rd_1), .b(ALUOutM), .sel(Forward_AD), .out(r_1_out)); //forwardAD as sel
  mux r_2_mx(.a(rd_2), .b(ALUOutM), .sel(Forward_BD), .out(r_2_out)); //forwardBD as sel
  
             
  assign EqualID = (r_1_out == r_2_out);
             
  //ANDing for branch operation to be fed to 0 for PC_branch_MUX
  and(PCSrcD, branch_out, EqualID); 
  
  //assign branch_out = (BranchD[0] == 1'b0) ? (BranchD[1] == 1'b1) ? (BranchD[2] == 1'b1) ? branch_greater_than_u : branch_not_equal : (BranchD[2]) ? branch_greater_than : 1'b0 : (BranchD[1] == 1'b0)? (BranchD[2]) ? branch_less_than_u : branch_equal : branch_less_than;
  
  //instantiated branch select mux to select the branch..Hope this works well for synthesis
  
  branch_select_mux bran_sel_mux(.beq(branch_equal), .bne(branch_not_equal), .blt(branch_less_than), .bge(branch_greater_than), .bltu(branch_less_than_u), .bgeu(branch_greater_than_u),.branch_sel(BranchD), .branch_taken(branch_out));
  
  Adder PC_Branch_Adder(.a_1((sign_imm<<2)), .a_2(PCPlus4D), .adder_out(adder_to_pc)); //Adder: PC + 4 + SignImm*4
  
  
  //second pipeleline stage : Decode to Execute 
  
  ID_EX ID_EX_Stage(.CLK(clk), .EN(StallD), .RegWriteD(RegWrite), .RegDstD(reg_dest), .shamt(shamt), .MemtoRegD(mem_to_reg), .MemWriteD(mem_write), .ALUSrcD(ALUsrc), .ALUControlD(alu_control), .RD1(rd_1), .RD2(rd_2), .RsD(InstrD[19:15]), .RtD(InstrD[24:20]), .RdD(InstrD[11:7]), .RegWriteE(RegWriteE), .RegDstE(RegDstE), .MemtoRegE(MemtoRegE), .MemWriteE(MemWriteE), .ALUSrcE(ALUSrcE), .ALUControlE(ALUControlE), .RD1E(RD1E), .RD2E(RD2E), .RtE(RtE), .RdE(RdE), .RsE(RsE), .shamt_out(shamt_out));
  
  
  assign i_u_select = immediate_select_control ? u_sign_extd : SignImmE;
  
  mux regfile_to_alu (.a(SrcBE), .b(i_u_select), .sel(ALUSrcE), .out(mx_to_alu)); 
  //MUX connecting to ALU. This is needed to map the register file output directly for R-type instructions. for I-type, ALUsrc will be set to 1
  
  //this mux takes forward AE as select for rs1
  hazard_mux hmux_rs1(.a(RD1E), .b(alu_to_reg_out), .c(ALUOutM), .sel(Forward_AE), .res(SrcAE));
  
  
  //this mux takes forward AE as select for rs2
  hazard_mux hmux_rs2(.a(RD2E), .b(alu_to_reg_out), .c(ALUOutM), .sel(Forward_BE), .res(SrcBE));
  
  
  //FLoating Point Unit instance
  wire [31:0] fp_base, fp_offset, fp_load_mem, fp_store_mem;
  
  floating_point_unit fp_unit(.clk(clk), .lw_st(fp_load_store), .floating_point_instr(InstrD), .memory_load(fp_load_mem), .base_out(fp_base), .memory_store(fp_store_mem), .memory_offset(fp_offset));
  
  //mux to select between normal datapath input and floating point input
  
  
  
  assign inp_alu_1 = sel_fp_srcae ? fp_base : SrcAE;
  assign inp_alu_2 = sel_mx_offset ? fp_offset : mx_to_alu;
  
  //ALU Instance
  ALU ALU_Inst (.SrcA(inp_alu_1), .SrcB(inp_alu_2), .ALU_Control(ALUControlE), .Zero(zero_flag), .ALU_Result(alu_result), .shamt(shamt_out), .BNE(branch_not_equal), .BLT(branch_less_than), .BGE(branch_greater_than), .BLT_U(branch_less_than_u), .BGE_U(branch_greater_than_u)); //ALU Instance
  
  
  mux register_dest(.a(RtE), .b(RdE), .sel(RegDstE), .out(write_reg)); 
  //MUX to select register destination
  defparam register_dest.width = 5;
  
  
  //third pipeline register : EXECUTE to MEMORY
  
  EX_MEM EX_MEM_Stage(.CLK(clk), .CLR(FlushE), .RegWriteE(RegWriteE), .MemtoRegE(MemtoRegE), .MemWriteE(MemWriteE), .Zero_ALU_E(zero_flag), .WriteRegE(write_reg), .ALUOut_E(alu_result), .WriteDataE(SrcBE), .RegWriteM(RegWriteM), .MemtoRegM(MemtoRegM), .MemWriteM(MemWriteM), .Zero_ALU_M(ZeroM), .WriteRegM(WriteRegM), .ALUOut_M(ALUOutM), .WriteDataM(WriteDataM));
  
 
  //cache instance
  
  cache_mem cache_mem_inst(.w_e(MemWriteM), .clk(clk), .cpu_address(ALUOutM), .cpu_data(WriteDataM), .mem_to_cache_data(mem_to_cache_data), .cache_data_out(read_data_bus), .cache_to_mem_data(cache_to_mem_data), .cache_to_mem_address(cache_to_mem_address), .wr_mem(cache_mem_wr_en));
  
  Data_Memory Data_Mem (.CLK(clk), .address_port_1(cache_to_mem_address), .data_port_1(cache_to_mem_data), .read_port_1(mem_to_cache_data), .wr_en_1(cache_mem_wr_en), .load_store_sel(load_store_sig), .data_port_2(fp_store_mem), .address_port_2(alu_result), .wr_en_2(fp_load_store), .read_port_2(fp_load_mem)); //Data Memory Instance
  
  
 
 //fourth pipeline register : MEMORY to WRITE BACK
  
  
  MEM_WB MEM_WB_Stage(.CLK(clk), .RegWriteM(RegWriteM), .MemtoRegM(MemtoRegM), .WriteRegM(WriteRegM), .ReadDataM(read_data_bus), .ALUOutM(ALUOutM), .RegWriteW(RegWriteW), .MemtoRegW(MemtoRegW), .ALUOutW(ALUOutW), .ReadDataW(ReadDataW), .WriteRegW(WriteRegW));
  
  
  mux alu_to_reg (.a(ALUOutW), .b(ReadDataW), .sel(MemtoRegW), .out(alu_to_reg_out));       //MUX connecting ALUResult and ReadData of Data Memory as input and proagating the desired value to register file for writeback based on mem_to_reg signal
  
  
/*----------------------------HAZARD UNIT------------------------------*/
  
  Hazard_Unit hazard_control_unit(.WriteRegM(WriteRegM), .RegWriteM(RegWriteM), .RsD(InstrD[19:15]), .RsE(RsE), .RtD(InstrD[24:20]), .RtE(RtE), .RegWriteW(RegWriteW), .WriteRegW(WriteRegW), .BranchD(BranchD), .MemtoRegE(MemtoRegE), .Forward_AE(Forward_AE), .Forward_BE(Forward_BE), .StallF(StallF), .StallD(StallD), .FlushE(FlushE), .ForwardAD(Forward_AD), .ForwardBD(Forward_BD), .WriteRegE(write_reg), .MemtoRegM(MemtoRegM), .RegWriteE(RegWriteE));
  
  
  
endmodule
