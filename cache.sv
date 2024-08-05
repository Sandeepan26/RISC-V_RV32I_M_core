package cache_ram;

typedef struct {	
  	bit valid;
  	bit [19:0] tag;
    bit [31:0] data;
} cache_block;

endpackage

//-------------- 8-Way Set Associative CACHE ------------------------------


module cache_mem#(parameter n = 8)(input w_e, clk, [31:0] cpu_address, [31:0] cpu_data, [31:0] mem_to_cache_data, output reg [31:0] cache_data_out, cache_to_mem_data, wire[31:0] cache_to_mem_address, wire wr_mem);
  
  assign cache_to_mem_address = cpu_address;
  assign wr_mem = w_e ? 1'b1 : 1'b0;
    
  import cache_ram :: cache_block;  //importing the structure to this scope only
  
  enum bit [1:0] {idle = 2'b00, compare_tag = 2'b01, allocate = 2'b10, write_through = 2'b11} operation;
  
  
    //operation for FSM implementation. value of operation will be used to decide currrent and next operation
  
  
  
  cache_block cache_blk [0:1023];  //1024 cache blocks
  
  //Following is an implemenation of 8-way set associative cache
  
 typedef struct{
   cache_block cache_block_line[0:127]; //128 cache blocks each set
 } cache_set;
  
  cache_set cache_block_set[0:n]; //8 sets
  
  //cache_block [127:0][127:0] cache_set;
  
 initial begin
   $display("bits : %d ", $bits(cache_block_set[0].cache_block_line[0]));
 end
  
  /*cache_blk has packed values, they can be accessed either via dot(.) reference or index slice. cache_blk[31:0] represents 32 bit address, [51:32] represents tag, and [52] represents valid bit, [53] represents dirty bit */
  

  
  
  //w_e is write enable : w_e 0 for read, 1 for write
  
  
bit hit, miss;
reg [31:0] req_address;
  
  
  always @(posedge clk)
    begin
    case(operation)
      idle: operation = compare_tag;
      
      compare_tag : 
        begin
          if(cache_block_set[cpu_address[4:2]].cache_block_line[(cpu_address[11:5])].tag == cpu_address[31:12])  //tags compared
           begin
             if(cache_block_set[cpu_address[4:2]].cache_block_line[cpu_address[11:5]].valid == 1'b1) begin //checked valid bit
               cache_data_out = cache_block_set[cpu_address[4:2]].cache_block_line[cpu_address[11:5]].data;
               hit = ((cache_block_set[cpu_address[4:2]].cache_block_line[cpu_address[11:5]].data == cpu_address[31:12]) && cache_block_set[cpu_address[4:2]].cache_block_line[cpu_address[11:5]].valid);
      			operation = idle;
          	end
        	else begin //valid bit not set, no data found, it's a miss
            	miss = 1'b1;
        		operation = allocate;
            end
          end
          else begin
            cache_block_set[cpu_address[4:2]].cache_block_line[cpu_address[11:5]].tag = cpu_address[31:12]; //storing tag
            operation = allocate;
          end
        end 
      allocate:
          begin
            if(w_e == 1'b0) begin  // w_e == 0 ? write else read..
        		//req_address <= cpu_address;   //storing requested cpu_address
        		//cache_to_mem_address = cpu_address; //sending address to main memory
            	//wr_mem = 1'b0;  //0 for read, 1 for write : for main memory
                cache_data_out = mem_to_cache_data;
              cache_block_set[cpu_address[4:2]].cache_block_line[cpu_address[11:5]].data = mem_to_cache_data;
        		cache_block_set[cpu_address[4:2]].cache_block_line[cpu_address[11:5]].valid = 1'b1; //valid bit set for data available
              operation = (cache_block_set[cpu_address[4:2]].cache_block_line[cpu_address[11:5]].valid == 1'b1) ? compare_tag : allocate;
      		end
      		else  //write enable, cache should take the address and data and write it to the main memory 
        		operation = write_through; 
          end
      write_through:
      begin 
      	req_address = cpu_address;
      	//cache_to_mem_address = req_address;
        cache_block_set[cpu_address[4:2]].cache_block_line[cpu_address[11:5]].data = cpu_data;  //storing cpu data as a write back buffer 
      	//wr_mem = 'b1;  //for writing to the main memory
        cache_to_mem_data = cache_block_set[cpu_address[4:2]].cache_block_line[cpu_address[11:5]].data;  //sending data to main memory for update
    
        operation = idle;
      end
      
    endcase
    
  end
  
  
endmodule
