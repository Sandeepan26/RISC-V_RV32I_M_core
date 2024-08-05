/*--------DATA MEMORY------------------ */


module Data_Memory (
  input [31:0] data_port_1,      //data for writing
  input [31:0] data_port_2,
  input [31:0] address_port_1,      //address for memory
  input [31:0] address_port_2,
  input  CLK,          // synchronous clock
  input wr_en_1,    //decides read/write
  input wr_en_2,
  input [2:0] load_store_sel,
  output reg [31:0] read_port_1,
  output reg [31:0] read_port_2
);

  reg [31:0] Data_Mem [(2**22 - 1):0];   //4M x 32 data memory
   
  
  function bit [31:0] load_store_output(input [2:0] load_store_select, [31:0] address);
    begin
      case(load_store_select)
        3'b000 : load_store_output = {{24{Data_Mem[address][31]}}, Data_Mem[address][7:0]}; //LB
        3'b001 : load_store_output = {{16{Data_Mem[address][31]}}, Data_Mem[address][15:0]}; //LH
        3'b010 : load_store_output = Data_Mem[address];  //LW
        3'b100 : load_store_output = {{24{1'b0}}, Data_Mem[address][7:0]};  //LBU
        3'b101 : load_store_output = {{16{1'b0}}, Data_Mem[address][15:0]}; //LHU
        default : load_store_output = Data_Mem[address];  //default for case and other operations
      endcase
    end
  endfunction
  
  
  always @(posedge CLK) 
    begin
      if(wr_en_1) //MemWriteM = 1 for write
        Data_Mem[address_port_1] <= data_port_1; 
    else
      read_port_1 <= load_store_output(load_store_sel, address_port_1);  //read data from function call
    end
    
  
   always @(posedge CLK) 
    begin
      if(wr_en_2) //MemWriteM = 1 for write
        Data_Mem[address_port_2] <= data_port_2; 
    else
      read_port_2 <= load_store_output(load_store_sel, address_port_2); 
    end
  
endmodule
