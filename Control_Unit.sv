/*------ Control Unit-------------------- */

module Control_Unit(input [31:0] Instruction, output reg Mem_to_reg, MemWrite, reg [2:0] Branch, reg ALUSrc, RegDst, Jump, RegWrite, reg [4:0] ALUCtl, reg [4:0] shamt, reg imm_select, reg [2:0] load_store_op, reg sel_fp_srcae, reg sel_mx_offset, reg fp_load_store, reg fp_ld_rf_dmx);

  
  reg [1:0]ALUop; //register to store ALU Operation
  reg [2:0] instr_op; //register to store operation for instruction 
  
  /*-----instruction map------
  000 : R-type
  001 : I-type, S-type
  010 : U-type
  011 : B-type
  100 : J -type : JAL
  101 : JALR ; I-type encoded format
  */
  
  
  always @(Instruction) begin
    case(Instruction[6:0])
      7'b0110011 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op} = {1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 3'b000}; //R-type instruction
      
      7'b0010011 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op, Jump} = {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 3'b001, 1'b0}; //I-type 
      
      7'b1100011 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op} = {1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 3'b011}; //B-type
      
      7'b1101111 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op, Jump} = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 3'b011, 1'b1}; //J-type
      
      7'b0000011 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op} = {1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 3'b100}; //LOAD
      
      7'b0100011 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op} = {1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 3'b101};  //STORE
      
      7'b0110111 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op} = {1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 3'b010};  //LUI
      
      7'b0010111 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op} = {1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 3'b010}; //AUIPC
      
      7'b1100111 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op, Jump} = {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 3'b101, 1'b0}; //JALR
      7'b0000111 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op, Jump, sel_fp_srcae, sel_mx_offset, fp_ld_rf_dmx} = {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 3'b110, 1'b0, 1'b1, 1'b1, 1'b1}; //Floating Point for FLW
      
      7'b0100111 : {Mem_to_reg, MemWrite, Branch, ALUSrc, RegDst, RegWrite, instr_op, Jump, sel_fp_srcae, sel_mx_offset, fp_ld_rf_dmx} = {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 3'b111, 1'b0, 1'b0, 1'b0, 1'b0}; //Floating Point for FSW
    endcase
    
  end
  
  
 //ALU and Instruction Decoder
  
  always @(instr_op)begin
    case(instr_op)
     	3'b000 :
        begin
          case({Instruction[31:25],Instruction[14:12]})  //funct7, funct3
            
            10'b0000000000 : ALUCtl = 5'b00000; //ADD 0
            10'b0100000000 : ALUCtl = 5'b00001; //SUB 1
            10'b0000000001 : ALUCtl = 5'b00010; //SLL 2
            10'b0000000010 : ALUCtl = 5'b00011; //SLT 3 
            10'b0000000011 : ALUCtl = 5'b00100; //SLTU 4
            10'b0000000100 : ALUCtl = 5'b00101; //XOR 5
            10'b0000000101 : ALUCtl = 5'b00110; //SRL 6
            10'b0100000101 : ALUCtl = 5'b00111; //SRA 7
            10'b0000000110 : ALUCtl = 5'b01000; //OR 8
            10'b0000000111 : ALUCtl = 5'b01001; //AND 9
            10'b0000001000 : ALUCtl = 5'b01010; //MUL 10
            10'b0000001001 : ALUCtl = 5'b01011; //MULH 11
            10'b0000001010 : ALUCtl = 5'b01100; //MULHSU 12
            10'b0000001011 : ALUCtl = 5'b01101; //MULHU 13
            10'b0000001100 : ALUCtl = 5'b01110; //DIV 14
            10'b0000001101 : ALUCtl = 5'b01111; //DIVU 15
            10'b0000001110 : ALUCtl = 5'b10000; //REM 16
            10'b0000001111 : ALUCtl = 5'b10001; //REMU 17
            
          endcase  //funct7, funct3, R-type
        end
      3'b001 :     //I-type
        begin
          case(Instruction[14:12])        //funct3 for I -type
            3'b000 : ALUCtl = 5'b00000;   //add operation between register value and immediate value
            3'b001 : begin
              if(Instruction[31:25] == 7'b0000000) begin
                ALUCtl = 5'b10010;  //18 for SLLI
                shamt = Instruction[24:20]; // shamt is shift amount to be used by ALU
              end
            end
            3'b010 : ALUCtl = 5'b00011;   //SLT with I
            3'b011 : ALUCtl = 5'b00100;   //SLTU with I
            3'b100 : ALUCtl = 5'b00101;   //XOR for I-type
            3'b101 : begin
              case(Instruction[31:25])
                
                7'b0000000 : begin
                  shamt = Instruction[24:20];
                  ALUCtl = 5'b10011; //19 for SRLI
                end
                
                7'b0100000 : {ALUCtl, shamt} = {5'b10100, Instruction[24:20]};  //20 for SRAI
                
                default : ALUCtl = 5'b00000;
              endcase
            end //case 101
            3'b110 : ALUCtl = 5'b01000;   //OR for I
            3'b111 : ALUCtl = 5'b01001;   //AND for I
            
         endcase  //funct3 for I-type
        end //case 001
      3'b010 : ALUCtl = 5'b10101;    //to store the immediate value in the register destination ..code : 21
      
      3'b011 : begin
        case(Instruction[14:12])
          3'b000 : Branch = 3'b001;
          3'b001 : Branch = 3'b010;
          3'b100 : Branch = 3'b011;
          3'b101 : Branch = 3'b100;
          3'b110 : Branch = 3'b101;
          3'b111 : Branch = 3'b110;
        endcase
      end
      
      3'b100 : begin
        case(Instruction[14:12])
          3'b000 : {ALUCtl, load_store_op} = 'b0;  //ADD and LB
          3'b001 : {ALUCtl, load_store_op} = {5'b00000, 3'b001}; //ADD, LH
          3'b010 : {ALUCtl, load_store_op} = {5'b00000, 3'b010}; //ADD, LW
          3'b100 : {ALUCtl, load_store_op} = {5'b00000, 3'b100}; //ADD, LBU
          3'b101 : {ALUCtl, load_store_op} = {5'b00000, 3'b101}; //ADD, LHU
        endcase
      end
      
      3'b101 : begin
        if(Instruction[14:12] == 3'b000)
          ALUCtl = 5'b00000;
      end
      
      3'b110 : {ALUCtl, fp_load_store} = {5'b00000, 1'b1};
      
      3'b111 : {ALUCtl, fp_load_store} = {5'b00000, 1'b0};
      
      default : ALUCtl = 5'b00000; //add operation set as default instr_op
    endcase //instr_op
  end //always block
   
  
endmodule
