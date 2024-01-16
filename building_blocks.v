
`timescale 1ns/10ps

//========================================================== 
//					Instruction Memory
//========================================================== 
module inst_mem(
	input [31:0] address0,
    input [31:0] address1,
    input [31:0] address2,
	input [31:0] address3,
	output [31:0] read_data0,
	output [31:0] read_data1,
	output [31:0] read_data2,
	output [31:0] read_data3
);
	
	reg [31:0] mem_data [0:(1<<16)-1];				// Main memory's capacity is 64KB
			
	assign	read_data0 = mem_data[address0[17:2]];  	// asynch. aligned read mem
	assign	read_data1 = mem_data[address1[17:2]];  	// asynch. aligned read mem	
	assign	read_data2 = mem_data[address2[17:2]];  	// asynch. aligned read mem
	assign	read_data3 = mem_data[address3[17:2]];  	// asynch. aligned read mem
	
endmodule

//========================================================== 
//					Data Memory
//========================================================== 
module async_mem(
   input clk,
   input write,
   input [31:0] read_addr,
   input [31:0] write_addr,
   input [31:0] write_data,
   output [31:0] read_data
);

	reg [31:0] mem_data [0:(1<<16)-1];

   assign read_data = ((read_addr == write_addr) && write) ? write_data : mem_data[ read_addr[17:2] ];  // zero delay, address to read data
					
   always @( posedge clk )
      if ( write )
         mem_data[ write_addr[17:2] ] <= write_data;

endmodule

//========================================================== 
//						Register File
//========================================================== 

module reg_file(
	input  clk,
	input  write0,
	input  write1,
	input  write2,	
	input  [ 4:0] WR0,
	input  [ 4:0] WR1,
	input  [ 4:0] WR2,
	input  [31:0] WD0,	
	input  [31:0] WD1,	
	input  [31:0] WD2,	
	input  [ 4:0] RR01,
	input  [ 4:0] RR02,	
	input  [ 4:0] RR11,
	input  [ 4:0] RR12,	
	input  [ 4:0] RR21,
	input  [ 4:0] RR22,	
	input  [ 4:0] RR31,
	input  [ 4:0] RR32,	
	output reg [31:0] RD01,
	output reg [31:0] RD02,	
	output reg [31:0] RD11,
	output reg [31:0] RD12,	
	output reg [31:0] RD21,
	output reg [31:0] RD22,	
	output reg [31:0] RD31,
	output reg [31:0] RD32
	);

	reg [31:0] reg_data [0:31];

	always @(*) begin			
		// Data Forwarding inside the Register File 
		if (write0 && RR01 && (RR01 == WR0)) 
			RD01=WD0;
		else if (write1 && RR01 && (RR01 == WR1)) 
			RD01=WD1;
		else if (write2 && RR01 && (RR01 == WR2)) 
			RD01=WD2;
		else
			RD01 = reg_data[RR01];
							
		if (write0 && RR02 && (RR02 == WR0)) 
			RD02=WD0;
		else if (write1 && RR02 && (RR02 == WR1)) 
			RD02=WD1;
		else if (write2 && RR02 && (RR02 == WR2)) 
			RD02=WD2;	
		else
			RD02 = reg_data[RR02];	
		
		if (write0 && RR11 && (RR11 == WR0)) 
			RD11=WD0;
		else if (write1 && RR11 && (RR11 == WR1)) 
			RD11=WD1;
		else if (write2 && RR11 && (RR11 == WR2)) 
			RD11=WD2;
		else
			RD11 = reg_data[RR11];
		
		if (write0 && RR12 && (RR12 == WR0)) 
			RD12=WD0;
		else if (write1 && RR12 && (RR12 == WR1)) 
			RD12=WD1;		
		else if (write2 && RR12 && (RR12 == WR2)) 
			RD12=WD2;
		else 	
			RD12 = reg_data[RR12];	

		if (write0 && RR21 && (RR21 == WR0)) 
			RD21=WD0;			
		else if (write1 && RR21 && (RR21 == WR1)) 
			RD21=WD1;
		else if (write2 && RR21 && (RR21 == WR2)) 
			RD21=WD2;
		else 
			RD21 = reg_data[RR21];
			
		if (write0 && RR22 && (RR22 == WR0)) 
			RD22=WD0;	
		else if (write1 && RR22 && (RR22 == WR1)) 
			RD22=WD1;	
		else if (write2 && RR22 && (RR22 == WR2)) 
			RD22=WD2;
		else
			RD22 = reg_data[RR22];
						
		if (write0 && RR31 && (RR31 == WR0)) 
			RD31=WD0;
		else if (write1 && RR31 && (RR31 == WR1)) 
			RD31=WD1;		
		else if (write2 && RR31 && (RR31 == WR2)) 
			RD31=WD2;
		else 	
			RD31 = reg_data[RR31];
			
		if (write0 && RR32 && (RR32 == WR0)) 
			RD32=WD0;	
		else if (write1 && RR32 && (RR32 == WR1)) 
			RD32=WD1;	
		else if (write2 && RR32 && (RR32 == WR2)) 
			RD32=WD2;
		else 
			RD32 = reg_data[RR32];		
	end
	
	always @(posedge clk) begin
		if(write0) 
			reg_data[WR0] <= WD0;
		if(write1) 
			reg_data[WR1] <= WD1;	
		if(write2) 
			reg_data[WR2] <= WD2;		
		reg_data[0] <= 32'h00000000;
	end

endmodule



