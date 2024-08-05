/*--------------SIGN IMMEDIATE--------------- */

module SignExtend #(parameter size = 12)(input [(size-1):0] IMM, output[31:0] SignImm);
  
  assign SignImm = {{(32-size){IMM[11]}} , IMM}; //32 bits..MSB of IMM copied to upper 20 bits
  
endmodule

/*-----------MUX LOGIC---------------- */

module mux #(parameter width = 32)(input [(width-1):0]a, b, wire sel, output [(width-1):0]out);
  assign out = sel? b : a;
endmodule


/*-----------ADDER--------------------- */

module Adder #(parameter width = 32)(input [(width-1): 0] a_1, a_2, output [(width-1):0]adder_out);
  
  assign adder_out = a_1 + a_2;

endmodule

/*------HAZARD MUX------------ */

module hazard_mux #(parameter width = 32)(input [1:0] sel, [(width-1):0] a, b, c, output [(width-1):0] res);
  
  reg [(width-1):0] val;
  assign res = val;
  
  always @(a, b, c, sel) begin
    case(sel)
      2'b00 : val = a;
      2'b01 : val = b;
      2'b10: val = c;
    endcase
  end
  
endmodule

/*----- BRANCH  SELECT MUX---- */

module branch_select_mux(input beq, bne, blt, bge, bltu, bgeu, [2:0] branch_sel, output reg branch_taken);
  
  always @ (branch_sel, beq, bne, blt, bge, bltu, bgeu) begin
    
  	case(branch_sel)
    	3'b001 : branch_taken = beq;
      	3'b010 : branch_taken = bne;
      	3'b011 : branch_taken = blt;
      	3'b100 : branch_taken = bge;
      	3'b101 : branch_taken = bltu;
      	3'b110 : branch_taken = bgeu;
    endcase
    
  end
  
endmodule

/* Demultiplexor to select loading to integer register or floating point register */

module demux (input sel, [31:0] dat_sig, output reg [31:0] dat_out_1, reg [31:0] dat_out_2);
  
  always @(sel)begin
    if(sel)begin
    	dat_out_1 = dat_sig;
    	dat_out_2 = 'b0;
    end
    else begin
      dat_out_1 = 'b0;
      dat_out_2 = dat_sig;
    end
  end
  
