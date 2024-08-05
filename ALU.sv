/*-------ARITHMETIC LOGIC UNIT--------------------- */

module ALU (input [4:0] shamt, [31:0] SrcA, [31:0] SrcB, [4:0] ALU_Control, output  Zero, BNE, BLT, BGE, BLT_U, BGE_U, reg [31:0] ALU_Result);
  
 
  //function to compute signed and unsigned comparison : SLTI and SLTIU
  
  function bit compare_less_than ([31:0] a, [31:0] b);
    if(b[31] == 1'b1)
      compare_less_than = (signed'(a) < b);
    else
      compare_less_than = a < b;
  endfunction
  
  
  function bit compare_greater_than ([31:0] a, [31:0] b);
    if(b[31] == 1'b1)
      compare_greater_than = (signed'(a) > b);
    else
      compare_greater_than = a > b;
  endfunction
  
  
  //multiplier ---function 
  //mode is for the operation : 00 for MUL, 01 for MULH, 10 for MULHU, 11 for MULHSU
  
  function bit [31:0] multiply([1:0] mode, [31:0] a, [31:0] b);
    reg [63:0] res;
    
    case(mode)
      00 : {res,multiply} = {(a * b),res[31:0]}; //lower 32 bits of the product  : MUL
      01 : {res,multiply} = {(signed'(a) * signed'(b)),res[63:32]}; //upper 32 bits of the product : MULH
      10 : {res,multiply} = {(unsigned'(a) * unsigned'(b)),res[63:32]}; //upper 32 bits of unsigned x unsigned  product
      11 : {res,multiply} = {(signed'(a) * unsigned'(b)), res[63:32]};
    endcase
  endfunction
  
  //divider -- function
  
  /* code map
    00 : DIV
    01 : DIVU
    10 : REM
    11 : REMU
  */
  
  function [31:0] div_rem([1:0] mode, [31:0] a, [31:0] b);
    if(a != (2**($bits(a) -1) && b != -1))
    	case(mode)
      	00 : div_rem = (b == 'b0) ? -1 : (signed'(a) / signed'(b));
      	01 : div_rem = (b == 'b0) ? ((2**$bits(a)) - 1) : (a / unsigned'(b)); // since XLEN also equals the number of bits of the either of the operands
      	10 : div_rem = (b == 'b0) ? a : (signed'(a) % signed'(b));
      	11 : div_rem = (b == 'b0) ? a : (a % unsigned'(b));
    	endcase
    else //overflow 
      case(mode)
        00 : div_rem = -(2**($bits(a)) - 1);
      	01 : ;  //overflow cannot occur for unsigned operation
      	10 : div_rem = 0;
      	11 : ;
      endcase
  endfunction
  
  always @(ALU_Control, SrcA, SrcB, shamt) begin
    case(ALU_Control)
    	5'b00000 :  ALU_Result  = SrcA + SrcB;          //ADD 0
        5'b00001 :  ALU_Result  = SrcA - SrcB;          //SUB 1
        5'b00010 :  ALU_Result  = SrcA << SrcB[4:0];     //SLL 2
        5'b00011 :  ALU_Result  = compare_less_than(SrcA, SrcB);//SLT 3 signed
        5'b00100 :  ALU_Result  = compare_less_than(SrcA, SrcB);//SLTU 4
        5'b00101 :  ALU_Result  = SrcA ^ SrcB;//XOR 5
        5'b00110 :  ALU_Result  = SrcA >> SrcB[4:0];//SRL 6
        5'b00111 :  ALU_Result  = SrcA >>> SrcB[4:0];//SRA 7
        5'b01000 :  ALU_Result  = SrcA | SrcB;//OR 8
        5'b01001 :  ALU_Result  = SrcA & SrcB;//AND 9
        5'b01010 :  ALU_Result  = multiply(00, SrcA, SrcB);//MUL 10
        5'b01011 :  ALU_Result  = multiply(01, SrcA, SrcB);//MULH 11
        5'b01100 :  ALU_Result  = multiply(10, SrcA, SrcB);//MULHSU 12
        5'b01101 :  ALU_Result  = multiply(11, SrcA, SrcB);//MULHU 13
        5'b01110 :  ALU_Result  = div_rem(00, SrcA, SrcB);//DIV 14
        5'b01111 :  ALU_Result  = div_rem(01, SrcA, SrcB);//DIVU 15
        5'b10000 :  ALU_Result  = div_rem(10, SrcA, SrcB);//REM 16
        5'b10001 :  ALU_Result  = div_rem(11, SrcA, SrcB);//REMU 17
        5'b10010 :  ALU_Result = (SrcA << shamt);  //SLLI 18
        5'b10011 :  ALU_Result = (SrcA >> shamt);  //SRLI 19
        5'b10100 :  ALU_Result = (SrcA >>> shamt); //SRAI 20
        5'b10101 :  ALU_Result = {SrcB, {12{1'b0}}};
    endcase
  end
  
  assign Zero = (SrcA == SrcB);
  assign BNE = (SrcA != SrcB);
  assign BLT = compare_less_than(SrcA, SrcB);
  assign BGE = compare_greater_than(SrcA, SrcB);
  assign BLT_U = compare_less_than(SrcA, SrcB);
  assign BGE_U = compare_greater_than(SrcA, SrcB);
  
endmodule
