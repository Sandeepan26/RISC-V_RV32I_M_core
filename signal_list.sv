package signals; 
	wire [31:0] pc_out;
    wire [31:0] pc_plus_4, pc_next_instr;
  //assign pc_out  = pc;
   wire [31:0] Instr;
   wire [31:0] rd_1, rd_2;
   wire RegWrite;
   wire [31:0] sign_imm;
   wire [31:0] alu_result;
   wire zero_flag;
   wire [31:0] read_data_bus;
   wire [31:0] alu_to_reg_out;
   wire mem_to_reg; // this value is 0 for R-type instructrions
   wire ALUsrc; //0 for R-type instructions
   wire [31:0] mx_to_alu;
   wire reg_dest; //1 for R-type instruction
   wire [4:0] write_reg;
   wire branch_sel; wire [2:0] BranchD; wire PCSrcD;
   wire [31:0] mux_to_pc;
   wire [31:0] adder_to_pc;
   wire mem_write;
   wire [4:0] alu_control;
   wire Jump;
   wire [19:0] jump_link;  //**for jump and link signal..changed jump extension
   wire [31:0] InstrD, PCPlus4D; 
   wire RegWriteE, RegDstE; wire [2:0] BranchE; wire MemtoRegE, MemWriteE, ALUSrcE;
   wire [4:0] ALUControlE;
   wire [31:0] RD1E, RD2E, SignImmE, PCPlus4E;
   wire [4:0] RtE, RdE, RsE;
   wire RegWriteM, MemtoRegM, MemWriteM, BranchM;
   wire ZeroM;
   wire [4:0] WriteRegM;
   wire [31:0] ALUOutM;
   wire [31:0] WriteDataM, PCBranchM;
   wire RegWriteW, MemtoRegW;
   wire [31:0] ALUOutW, ReadDataW;
   wire [4:0] WriteRegW;
   wire [1:0] Forward_AE, Forward_BE;
   wire[31:0] SrcAE, SrcBE;
   wire StallD, StallF, FlushE;
   wire EqualID;
   wire [31:0] mem_to_cache_data, cache_to_mem_data, cache_to_mem_address;
   wire cache_mem_wr_en;
   wire [4:0] shamt, shamt_out;
   wire [31:0] jal_mux;
   wire immediate_select_control;   //signal from controller which acts as a multiplexor to switch between I-tye and U-type instruction 
  
  wire [31:0] i_u_select;

  //branching signals
  
  wire branch_equal, branch_less_than, branch_greater_than, branch_not_equal, branch_less_than_u, branch_greater_than_u;
  
  wire branch_out;
  
  
  //load_store signal
  
  wire [2:0] load_store_sig;
  
  //signals for floating point parallel operation
  wire sel_fp_srcae, sel_mx_offset, fp_load_store;
  
  wire mem_dmx_sel, data_mem_fp, data_mem_rf;
  
  wire [31:0] inp_alu_1, inp_alu_2;
  
endpackage
