//===============================================
//									
//			Mehrdad Morsali - 400205606			                                             
//
//
// For best readability use Notepad++
// Tested and verified on Modelsim SE-64 2020.4 
// Ver 24.8; January,19,2022 - February,6, 2022																				           
//===============================================

`timescale 1ns/1ns

//========================================================== 
//						Top module
//========================================================== 
module pipelined_mips 
(
	input clk,
	input reset
);
 
	//++++++++++++++++++++++++++++++++++
	//			Definitions
	//++++++++++++++++++++++++++++++++++
	
	reg [31:0] PC;			//instruction pointer		
	wire [31:0] PCPlus4F;	//pointer to the instruction #0's next instruction in fetch stage
	wire [31:0] PCPlus8F;	//pointer to the instruction #1's next instruction in fetch stage
	wire [31:0] PCPlus12F;	//pointer to the instruction #2's next instruction in fetch stage
	wire [31:0] PCPlus16F;	//pointer to the instruction #3's next instruction in fetch stage
	
	wire [31:0] PCPlus4;	//pointer to the instruction #0's next instruction in fetch stage
	wire [31:0] PCPlus8;	//pointer to the instruction #1's next instruction in fetch stage
	wire [31:0] PCPlus12;	//pointer to the instruction #2's next instruction in fetch stage
	wire [31:0] PCPlus16;	//pointer to the instruction #3's next instruction in fetch stage
	
	
	wire [31:0] PCPlus4D;	//pointer to the instruction #0's next instruction in decode stage
	wire [31:0] PCPlus8D;	//pointer to the instruction #1's next instruction in decode stage
	wire [31:0] PCPlus12D;	//pointer to the instruction #2's next instruction in decode stage
	wire [31:0] PCPlus16D;	//pointer to the instruction #3's next instruction in decode stage	
	wire [31:0] NextPC;		//pointer to the next instruction
	wire [31:0] BrPC;		//pointer to the branch instruction in decode stage
	wire [31:0] BrPCE;		//pointer to the branch instruction in execution stage
	
	wire [31:0] Instr0;		//instruction #0 in fetch FIFO	
	wire [31:0] Instr1;		//instruction #1 in fetch FIFO	
	wire [31:0] Instr2;		//instruction #2 in fetch FIFO	
	wire [31:0] Instr3;		//instruction #3 in fetch FIFO
	
	wire [63:0] Instr0F;	//instruction,SC #0 in fetch stage	
	wire [63:0] Instr1F;	//instruction,SC #1 in fetch stage	
	wire [63:0] Instr2F;	//instruction,SC #2 in fetch stage	
	wire [63:0] Instr3F;	//instruction,SC #3 in fetch stage	
	
	wire [63:0] Instr0D;	//instruction,SC #0 in decode stage	
	wire [63:0] Instr1D;	//instruction,SC #1 in decode stage	
	wire [63:0] Instr2D;	//instruction,SC #2 in decode stage	
	wire [63:0] Instr3D;	//instruction,SC #3 in decode stage
	
	wire [63:0] Instr0ID;	//instruction,SC lane 0 candidate for execution in decode stage	
	wire [63:0] Instr1ID;	//instruction,SC lane 1 candidate for execution in decode stage	
	wire [63:0] Instr2ID;	//instruction,SC lane 2 candidate for execution in decode stage	
	wire [63:0] Instr3ID;	//instruction,SC lane 3 candidate for execution in decode stage	
	
	reg [31:0] SC;			//sequence counter for in-order instruction commit
	wire [31:0] NextSC;		//pointer to the next sequence
	wire [31:0] CurrentSC;	//pointer to the current sequence

	wire [31:0] SC1;		//instruction #1 sequence counter in fetch stage
	wire [31:0] SC2;		//instruction #2 sequence counter in fetch stage
	wire [31:0] SC3;		//instruction #3 sequence counter in fetch stage	
	wire [31:0] SC0D;		//instruction #0 sequence counter in decode stage
	wire [31:0] SC1D;		//instruction #1 sequence counter in decode stage
	wire [31:0] SC2D;		//instruction #2 sequence counter in decode stage
	wire [31:0] SC3D;		//instruction #3 sequence counter in decode stage
	wire [31:0] SC0E;		//lane 0 sequence counter in execution stage
	wire [31:0] SC1E;		//lane 1 sequence counter in execution stage
	wire [31:0] SC2E;		//lane 2 sequence counter in execution stage
	wire [31:0] SC3E;		//lane 3 sequence counter in execution stage
	
	wire FIFOEmpty;			//FIFO empty indicator in fetch stage
	wire FIFOEmptyD;		//FIFO empty indicator in decode stage	
	wire RSFull;			//Reservation Station full indicator
		
	wire [31:0] BrAddress;	//branch address pointed by branch instructions
	wire BrHappens;			//indicator of branch conditions' satisfaction 	
	wire [1:0] Branch0D;	//branch type indicator (00=no branch, 01=beq, 10=bne) in decode stage	
	wire [1:0] BranchE;		//branch type indicator (00=no branch, 01=beq, 10=bne) in execution stage	
	wire [31:0]	AlAddr;		//aligned address used by branch instructions
	
	wire StallF;			//Fetch Stall indicator
	
	wire RFWrite0D;			//lane 0's RF write enable in decode stage	
	wire RFWriteE;			//lane 0's RF write enable in execution stage
	wire Write0;			//RF's write port #0 write enable	
	wire Write1;			//RF's write port #1 write enable
	wire Write2;			//RF's write port #2 write enable 
	wire Write2E;			//RF's write port #2 write enable in execution stage	

	wire [4:0] WriteReg0D;	//instruction #0 RF's possible address of the written data in decode stage
	wire [4:0] WriteReg1D;	//instruction #1 RF's possible address of the written data in decode stage
	wire [4:0] WriteReg0E;	//destination register address of lane 0 instruction in execution stage
	wire [4:0] WriteReg1E;	//destination register address of lane 1 instruction in execution stage
	wire [4:0] WriteReg2E;	//destination register address of lane 2 instruction in execution stage
	wire [4:0] WR0;			//RF's write port #0 address of the written data	
	wire [4:0] WR1;			//RF's write port #1 address of the written data
	wire [4:0] WR2E;		//RF's write port #2  address of the written data in execution stage	
	wire [4:0] WR2;			//RF's write port #2 address of the written data
	wire [31:0] WD0;		//RF's write port #0 written data contents	
	wire [31:0] WD1;		//RF's write port #1 written data contents
	wire [31:0]	WD2;		//RF's write port #2 written data contents	
	wire [31:0]	RD01;		//RF's read port #0 first register's contents 
	wire [31:0]	RD02;		//RF's read port #0 second register's contents
	wire [31:0]	RD11;		//RF's read port #1 first register's contents 
	wire [31:0]	RD12;		//RF's read port #1 second register's contents
	wire [31:0]	RD21;		//RF's read port #2 first register's contents 
	wire [31:0]	RD22;		//RF's read port #2 second register's contents
	wire [31:0]	RD31;		//RF's read port #3 first register's contents 
	wire [31:0]	RD32;		//RF's read port #3 second register's contents	

	wire [31:0] ISequence2E;//SC of the finished instruction of lane 2 in execution stage 

	wire [31:0] ISequence0;	//SC of the finished instruction of lane 0
	wire [31:0] ISequence1;	//SC of the finished instruction of lane 1
	wire [31:0] ISequence2;	//SC of the finished instruction of lane 2
	wire [31:0] ISequence3;	//SC of the finished instruction of lane 3
	wire I2doneE;			//valid finishing of the instruction #2 indicator in execution stage 
	wire I0done;			//valid finishing of the instruction #0 indicator
	wire I1done;			//valid finishing of the instruction #1 indicator
	wire I2done;			//valid finishing of the instruction #2 indicator
	wire I3done;			//valid finishing of the instruction #3 indicator
		
	wire [3:0] ActiveLanes;	//valid instructions' issue indicator in decode stage 
	wire [3:0] ActiveLanesE;//valid instructions' issue indicator in execution stage 
	
	wire [31:0] VJ0;		//First parameter of lane 0 in decode stage 
	wire [31:0] VK0;		//Second parameter of lane 0 in decode stage 
	wire [31:0] VJ1;		//First parameter of lane 1 in decode stage 
	wire [31:0] VK1;		//Second parameter of lane 1 in decode stage 
	wire [31:0] VJ2;		//Parameter of lane 2 in decode stage 
	wire [31:0] VJ3;		//First parameter of lane 3 in decode stage 
	wire [31:0] VK3;		//Second parameter of lane 3 in decode stage 
	
	wire [31:0] VJ0E;		//First parameter of lane 0 in execution stage 
	wire [31:0] VK0E;		//Second parameter of lane 0 in execution stage 
	wire [31:0] VJ1E;		//First parameter of lane 1 in execution stage 
	wire [31:0] VK1E;		//Second parameter of lane 1 in execution stage 
	wire [31:0] VJ2E;		//Parameter of lane 2 in execution stage 
	wire [31:0] VJ3E;		//First parameter of lane 3 in execution stage 
	
	wire ImmSE0;			//instruction #0 immediate's extension type: 1=sign-extension, 0=zero-extension
	wire ImmSE1;			//instruction #1 immediate's extension type: 1=sign-extension, 0=zero-extension

	wire [2:0] ALUOp0D;		//instruction #0 ALU's operation id in decode stage
	wire [2:0] ALUOp1D;		//instruction #1 ALU's operation id in decode stage
	wire [2:0] ALUOp0E;		//instruction #0 ALU's operation id in execution stage
	wire [2:0] ALUOp1E;		//instruction #1 ALU's operation id in execution stage
	wire ALUSrc0D;			//instruction #0 ALU's second input's source in decode stage
	wire ALUSrc1D;			//instruction #1 ALU's second input's source in decode stage
	wire ALUSrc0E;			//instruction #0 ALU's second input's source in execution stage
	wire ALUSrc1E;			//instruction #1 ALU's second input's source in execution stage
	wire [31:0]	ALUSecIn0;	//instruction #0 ALU's second input		
	wire [31:0]	ALUSecIn1;	//instruction #1 ALU's second input
	wire [31:0]	ALUOut0E;	//instruction #0 ALU's operation result in execution stage	 
	wire [31:0]	ALUOut1E;	//instruction #1 ALU's operation result in execution stage	 
	wire ALUZero;			//ALU's branch occurrence ack. for beq and bne instructions
	
	wire RegDst0;			//instruction #0 controller's signal to determine the address of RF's write source
	wire RegDst1;			//instruction #1 controller's signal to determine the address of RF's write source

	wire LUI0D;				//instruction #0 controller's lui instruction indicator in decode stage 
	wire LUI1D;				//instruction #1 controller's lui instruction indicator in decode stage 
	wire LUI0E;				//instruction #0 controller's lui instruction indicator in execution stage 
	wire LUI1E;				//instruction #1 controller's lui instruction indicator in execution stage 
		
	wire [31:0]	ExtImm0D;	//instruction #0 extended immediate in decode stage
	wire [31:0]	ExtImm1D;	//instruction #1 extended immediate in decode stage
	wire [31:0]	ExtImm2D;	//instruction #2 extended immediate in decode stage
	wire [31:0]	ExtImm3D;	//instruction #3 extended immediate in decode stage

	wire [31:0] ExtImm0E;	//instruction #0 extended immediate in execution stage
	wire [31:0] ExtImm1E;	//instruction #1 extended immediate in execution stage
	wire [31:0] ExtImm2E;	//instruction #2 extended immediate in execution stage
	wire [31:0] ExtImm3E;	//instruction #3 extended immediate in execution stage

	wire [31:0]	ShImm0D;	//instruction #0 shifted immediate in decode stage
	wire [31:0]	ShImm1D;	//instruction #1 shifted immediate in decode stage
	wire [31:0]	ShImm0E;	//instruction #0 shifted immediate in execution stage
	wire [31:0]	ShImm1E;	//instruction #1 shifted immediate in execution stage

	wire [31:0] WriteDataE;	//data memory's write data in execution stage	
			
	wire [31:0]	LwAddr;		//the calculated load address 	
	wire [31:0]	SwAddr;		//the calculated store address
	wire [31:0]	LwAddrE;	//the calculated load address in execution stage	
	wire [31:0]	SwAddrE;	//the calculated store address in execution stage
	wire [31:0]	LwAddrM;	//the calculated load address in memory stage	
	wire [31:0]	SwAddrM;	//the calculated store address in memory stage

	wire [31:0] DMemDataE;	//data memory's write data in execution stage
	wire DMemWriteE;		//data memory's write enable in execution stage
	wire [31:0] DMemDataM;	//data memory's write data in memory stage
	wire DMemWriteM;		//data memory's write enable in memory stage
		
	//++++++++++++++++++++++++++++++++++
	//			Instantiations
	//++++++++++++++++++++++++++++++++++
	
	//Instruction Memory
	inst_mem imem			
	(	
		.address0	(PC),
		.address1	(PCPlus4),
		.address2	(PCPlus8),
		.address3	(PCPlus12),
		.read_data0	(Instr0),
		.read_data1	(Instr1),
		.read_data2	(Instr2),
		.read_data3	(Instr3)
	);	
	
	//PC Adders
	Adder32 PCAdder0
	(
		.In1		(PC),
		.In2		(32'h00000004),		
		.Out		(PCPlus4)
	);
	
	Adder32 PCAdder1
	(
		.In1		(PC),
		.In2		(32'h00000008),
		.Out		(PCPlus8)
	);
	
	Adder32 PCAdder2
	(
		.In1		(PC),
		.In2		(32'h0000000C),
		.Out		(PCPlus12)
	);
	
	Adder32 PCAdder3
	(
		.In1		(PC),
		.In2		(32'h00000010),
		.Out		(PCPlus16)
	);
		
	//NextPC MUX
	MUX32 PCMUX
	(
		.In0		(PCPlus16),
		.In1		(BrAddress),
		.Select		(BrHappens),	
		.Out		(NextPC)
	);
	
	//SC Adders
	Adder32 SCAdder1
	(
		.In1		(SC),
		.In2		(32'h00000001),
		.Out		(SC1)
	);
	
	Adder32 SCAdder2
	(
		.In1		(SC),
		.In2		(32'h00000002),
		.Out		(SC2)
	);
	
	Adder32 SCAdder3
	(
		.In1		(SC),
		.In2		(32'h00000003),
		.Out		(SC3)
	);
	
	//Next Sequence MUX
	MUX32 SCMUX
	(
		.In0		(SC3),
		.In1		(SC0E),
		.Select		(BrHappens),	
		.Out		(CurrentSC)
	);
		
	//Next SC Adder
	Adder32 NextSCAdder
	(
		.In1		(CurrentSC),
		.In2		(32'h00000001),
		.Out		(NextSC)
	);
	
	//Instruction FIFO
	OPFIFO FIFO
	(
		.clk		(clk),
		.clr		(reset),
		.enbar		(RSFull),
		.Instr0		(Instr0),
		.Instr1		(Instr1),
		.Instr2		(Instr2),
		.Instr3		(Instr3),
		.SC0		(SC),
		.SC1		(SC1),
		.SC2		(SC2),
		.SC3		(SC3),
		.BrHappens	(BrHappens),
		.BrSequence	(SC0E),
		.PCPlus4	(PCPlus4),
		.PCPlus8	(PCPlus8),
		.PCPlus12	(PCPlus12),
		.PCPlus16	(PCPlus16),
		.FIFOFull	(StallF),
		.FIFOEmpty	(FIFOEmpty),
		.Instr0F	(Instr0F),
		.Instr1F	(Instr1F),
		.Instr2F	(Instr2F),
		.Instr3F	(Instr3F),
		.PCPlus4F	(PCPlus4F),
		.PCPlus8F	(PCPlus8F),
		.PCPlus12F	(PCPlus12F),
		.PCPlus16F	(PCPlus16F)
	);
	
	//IF/ID Pipeline Register
	IFIDRegister IFIDReg
	(
		.clk		(clk),
		.clr		(reset),
		.stall		(RSFull),
		.Instr0F	(Instr0F),
		.Instr1F	(Instr1F),
		.Instr2F	(Instr2F),
		.Instr3F	(Instr3F),
		.PCPlus4F	(PCPlus4F),
		.PCPlus8F	(PCPlus8F),
		.PCPlus12F	(PCPlus12F),
		.PCPlus16F	(PCPlus16F),
		.FIFOEmpty	(FIFOEmpty),
		.Instr0D	(Instr0D),
		.Instr1D	(Instr1D),
		.Instr2D	(Instr2D),
		.Instr3D	(Instr3D),
		.PCPlus4D	(PCPlus4D),
		.PCPlus8D	(PCPlus8D),
		.PCPlus12D	(PCPlus12D),
		.PCPlus16D	(PCPlus16D),
		.FIFOEmptyD	(FIFOEmptyD)
	);
	
	//The Reservation Station
	ReservationStation RSUnit
	(
		.clk		(clk),
		.clr		(reset),
		.FIFOEmptyD	(FIFOEmptyD),
		.BrHappens	(BrHappens),
		.BrSequence	(SC0E),
		.Instr0D	(Instr0D),
		.Instr1D	(Instr1D),
		.Instr2D	(Instr2D),
		.Instr3D	(Instr3D),
		.RD01		(RD01),
		.RD02		(RD02),
		.RD11		(RD11),
		.RD12		(RD12),
		.RD21		(RD21),
		.RD22		(RD22),
		.RD31		(RD31),
		.RD32		(RD32),	
		.write0		(Write0),
		.write1		(Write1),
		.write2		(Write2),	
		.WR0		(WR0),
		.WR1		(WR1),
		.WR2		(WR2),			
		.WD0		(WD0),	
		.WD1		(WD1),	
		.WD2		(WD2),
		.ISequence0	(ISequence0),
		.ISequence1	(ISequence1),
		.ISequence2	(ISequence2),
		.ISequence3	(ISequence3),
		.I0done		(I0done),
		.I1done		(I1done),
		.I2done		(I2done),
		.I3done		(I3done),
		.PCPlus4D	(PCPlus4D),
		.PCPlus8D	(PCPlus8D),
		.PCPlus12D	(PCPlus12D),
		.PCPlus16D	(PCPlus16D),	
		.Instr0ID	(Instr0ID),
		.Instr1ID	(Instr1ID),
		.Instr2ID	(Instr2ID),
		.Instr3ID	(Instr3ID),	
		.RSFull		(RSFull),
		.ActiveLanes (ActiveLanes),
		.VJ0		(VJ0),
		.VK0		(VK0),
		.VJ1		(VJ1),
		.VK1		(VK1),
		.VJ2		(VJ2),
		.VJ3		(VJ3),
		.VK3		(VK3),
		.BrPC		(BrPC)
	);
	
	//Register File
	reg_file RF
	(
		.clk		(clk),
		.write0		(Write0),
		.write1		(Write1),
		.write2		(Write2),		
		.WR0		(WR0),
		.WR1		(WR1),
		.WR2		(WR2),			
		.WD0		(WD0),	
		.WD1		(WD1),	
		.WD2		(WD2),			
		.RR01		(Instr0D[57:53]),
		.RR02		(Instr0D[52:48]),		
		.RR11		(Instr1D[57:53]),
		.RR12		(Instr1D[52:48]),		
		.RR21		(Instr2D[57:53]),
		.RR22		(Instr2D[52:48]),	
		.RR31		(Instr3D[57:53]),
		.RR32		(Instr3D[52:48]),	
		.RD01		(RD01),
		.RD02		(RD02),
		.RD11		(RD11),
		.RD12		(RD12),
		.RD21		(RD21),
		.RD22		(RD22),
		.RD31		(RD31),
		.RD32		(RD32)		
	);
	
	//Control Logics
	control_unit controller0
	(
		.Inst		(Instr0ID[63:32]),	
		.ImmSE		(ImmSE0),
		.ALUOp		(ALUOp0D),	
		.RFWrite	(RFWrite0D),
		.Branch		(Branch0D),
		.RegDst		(RegDst0),
		.LUI		(LUI0D),
		.ALUSrc		(ALUSrc0D)
	);
	
	control_unit controller1
	(
		.Inst		(Instr1ID[63:32]),	
		.ImmSE		(ImmSE1),
		.ALUOp		(ALUOp1D),	
		.RFWrite	(),
		.Branch		(),
		.RegDst		(RegDst1),
		.LUI		(LUI1D),
		.ALUSrc		(ALUSrc1D)
	);
		
	//Register File's Write Address Selection MUXs
	MUX5 RFWRMUX0
	(
		.In0		(Instr0ID[52:48]),
		.In1		(Instr0ID[47:43]),
		.Select		(RegDst0),	
		.Out		(WriteReg0D)
	);
	
	MUX5 RFWRMUX1
	(
		.In0		(Instr1ID[52:48]),
		.In1		(Instr1ID[47:43]),
		.Select		(RegDst1),	
		.Out		(WriteReg1D)
	);
				
	//Immediate Extension Logic
	extension ExL0
	(
		.ImmSignEx	(ImmSE0),
		.Imm		(Instr0ID[47:32]),
		.ExtImm		(ExtImm0D)
	);
	
	extension ExL1
	(
		.ImmSignEx	(ImmSE1),
		.Imm		(Instr1ID[47:32]),
		.ExtImm		(ExtImm1D)
	);
	
	extension ExL2
	(
		.ImmSignEx	(1'b1),
		.Imm		(Instr2ID[47:32]),
		.ExtImm		(ExtImm2D)
	);
	
	extension ExL3
	(
		.ImmSignEx	(1'b1),
		.Imm		(Instr3ID[47:32]),
		.ExtImm		(ExtImm3D)
	);
		
	//Immediate Shift Logic
	Imm_Shifter IShL0
	(
		.Imm		(Instr0ID[47:32]),
		.ShImm		(ShImm0D)
	);
	
	Imm_Shifter IShL1
	(
		.Imm		(Instr1ID[47:32]),
		.ShImm		(ShImm1D)
	);
		
	//ID/EX Pipeline Register
	IDEXRegister IDEXReg
	(				
		.clk		(clk),	
		.clr		(reset),
		.ActiveLanes (ActiveLanes),	
		.VJ0		(VJ0),
		.VK0		(VK0),
		.VJ1		(VJ1),
		.VK1		(VK1),
		.VJ2		(VJ2),
		.VJ3		(VJ3),
		.VK3		(VK3),
		.SC0ID		(Instr0ID[31:0]),
		.SC1ID		(Instr1ID[31:0]),
		.SC2ID		(Instr2ID[31:0]),
		.SC3ID		(Instr3ID[31:0]),
		.WriteReg0D (WriteReg0D),
		.WriteReg1D (WriteReg1D),
		.WriteReg2D (Instr2ID[52:48]),			
		.ExtImm0D	(ExtImm0D),
		.ExtImm1D	(ExtImm1D),
		.ExtImm2D	(ExtImm2D),
		.ExtImm3D	(ExtImm3D),
		.LUI0D		(LUI0D),
		.LUI1D		(LUI1D),
		.ALUOp0D	(ALUOp0D),
		.ALUOp1D	(ALUOp1D),
		.ALUSrc0D	(ALUSrc0D),
		.ALUSrc1D	(ALUSrc1D),
		.ShImm0D	(ShImm0D),
		.ShImm1D	(ShImm1D),
		.Branch0D	(Branch0D),
		.RFWrite0D	(RFWrite0D),
		.BrPC		(BrPC),		
		.ActiveLanesE (ActiveLanesE),
		.VJ0E		(VJ0E),
		.VK0E		(VK0E),
		.VJ1E		(VJ1E),
		.VK1E		(VK1E),
		.VJ2E		(VJ2E),
		.VJ3E		(VJ3E),
		.WriteDataE	(WriteDataE),
		.SC0E		(SC0E),
		.SC1E		(SC1E),
        .SC2E		(SC2E),
		.SC3E		(SC3E),
		.WriteReg0E (WriteReg0E),
	    .WriteReg1E (WriteReg1E),
		.WriteReg2E (WriteReg2E),		
		.ExtImm0E	(ExtImm0E),
		.ExtImm1E	(ExtImm1E),
		.ExtImm2E	(ExtImm2E),
		.ExtImm3E	(ExtImm3E),
		.LUI0E		(LUI0E),
		.LUI1E		(LUI1E),
		.ALUOp0E	(ALUOp0E),
		.ALUOp1E	(ALUOp1E),
		.ALUSrc0E	(ALUSrc0E),
		.ALUSrc1E	(ALUSrc1E),
		.ShImm0E	(ShImm0E),
		.ShImm1E	(ShImm1E),
		.BranchE	(BranchE),
		.RFWriteE	(RFWriteE),
		.BrPCE	(BrPCE)		
	);
		
	//Address Alignment Logic
	Address_Alignment AAL
	(
		.Address	(ExtImm0E),
		.AlignedAdd	(AlAddr)
	);
	
	//Branch Adder
	Adder32 BrAdder
	(
		.In1		(BrPCE),
		.In2		(AlAddr),
		.Out		(BrAddress)
	);
	
	//ALU's Second input Logics
	MUX32 ALUMUX1
	(
		.In0		(VK0E),
		.In1		(ExtImm0E),
		.Select		(ALUSrc0E),	
		.Out		(ALUSecIn0)
	);
		
	MUX32 ALUMUX2
	(
		.In0		(VK1E),
		.In1		(ExtImm1E),
		.Select		(ALUSrc1E),	
		.Out		(ALUSecIn1)
	);	
					
	//Arithmetic & Logic Units
	MIPSALU ALU0
	(
		.IN1		(VJ0E),
		.IN2		(ALUSecIn0),
		.ALUOp		(ALUOp0E),
		.ALUResult	(ALUOut0E),
		.Zero		(ALUZero)
	);
	
	MIPSALU ALU1
	(
		.IN1		(VJ1E),
		.IN2		(ALUSecIn1),
		.ALUOp		(ALUOp1E),
		.ALUResult	(ALUOut1E),
		.Zero		()
	);
		
	//Branch Conditioning Logic
	Branch_Conditioner BCL
	(
		.Branch		(BranchE),
		.Zero		(ALUZero),
		.ActiveLanesE (ActiveLanesE),
		.BrHappens	(BrHappens)
	);
		
	//Load Address Calculation Adder
	Adder32 LwAdder
	(
		.In1		(VJ2E),
		.In2		(ExtImm2E),
		.Out		(LwAddr)
	);

	//Store Address Calculation Adder
	Adder32 SwAdder
	(
		.In1		(VJ3E),
		.In2		(ExtImm3E),
		.Out		(SwAddr)
	);

	//Reordering Buffer
	Reordering_Buffer ROB
	(
		.clk		(clk),
		.clr		(reset),
		.ActiveLanesE (ActiveLanesE),
		.SC0E		(SC0E),
		.SC1E		(SC1E),
        .SC2E		(SC2E),
		.SC3E		(SC3E),	
		.WriteDataE	(WriteDataE),	
		.SwAddr		(SwAddr),
		.WriteReg2E (WriteReg2E),
		.LwAddr		(LwAddr),	
	    .WriteReg1E (WriteReg1E),	
		.ALUOut1E	(ALUOut1E),
		.LUI1E		(LUI1E),
		.ShImm1E	(ShImm1E),	
		.WriteReg0E (WriteReg0E),	
		.ALUOut0E	(ALUOut0E),
		.LUI0E		(LUI0E),
		.ShImm0E	(ShImm0E),
		.RFWriteE	(RFWriteE),
		.BrHappens	(BrHappens),
		.write0		(Write0),
		.write1		(Write1),
		.write2		(Write2E),	
		.WR0		(WR0),
		.WR1		(WR1),
		.WR2E		(WR2E),
		.WD0		(WD0),	
		.WD1		(WD1),	
		.ISequence0 (ISequence0),
		.ISequence1 (ISequence1),
		.ISequence2E (ISequence2E),
		.ISequence3 (ISequence3),	
		.I0done		(I0done),		
		.I1done		(I1done),			
		.I2doneE	(I2doneE),		
		.I3done		(I3done),
		.LwAddrE	(LwAddrE),
		.SwAddrE	(SwAddrE),
		.DMemDataE	(DMemDataE),
		.DMemWriteE	(DMemWriteE)
	);
		
	//EX/MEM Pipeline Register
	EXMEMRegister EXMEMReg
	(
		.clk		(clk),	
		.clr		(reset),
		.ISequence2E (ISequence2E),			
		.I2doneE	(I2doneE),
		.Write2E	(Write2E),
		.WR2E		(WR2E),
		.LwAddrE	(LwAddrE),
		.SwAddrE	(SwAddrE),
		.DMemDataE	(DMemDataE),
		.DMemWriteE	(DMemWriteE),
		.ISequence2 (ISequence2),		
		.I2done		(I2done),
		.write2		(Write2),
		.WR2		(WR2),
		.LwAddrM	(LwAddrM),
		.SwAddrM	(SwAddrM),		
		.DMemDataM	(DMemDataM),
		.DMemWriteM	(DMemWriteM)		
	);
		
	//Data Memory
	async_mem dmem			
	(
		.clk		(clk),
		.write		(DMemWriteM),
		.read_addr	(LwAddrM),
		.write_addr	(SwAddrM),
		.write_data	(DMemDataM),
		.read_data	(WD2)
	);
	

	//++++++++++++++++++++++++++++++++++
	//			Always Blocks
	//++++++++++++++++++++++++++++++++++

	always @(posedge clk) begin	
		if(reset) begin
			PC <= 32'h00000000;			//clear PC on reset	
			SC <= 32'h00000000;			//clear SC on reset				
		end		
		else begin
			if (!StallF) begin
				PC <= NextPC;			//indicate to next instruction
				SC <= NextSC;			//indicate to next sequence	
			end					
		end		
	end

	//++++++++++++++++++++++++++++++++++
	//			Initial Blocks
	//++++++++++++++++++++++++++++++++++

	initial begin
		$display("Superscalar ACA-MIPS Implemention");
		$display("Mehrdad Morsali - 400205606");
	end

endmodule

//========================================================== 
//					32-bit 2 input adder
//========================================================== 

module Adder32(
	input [31:0] In1,
	input [31:0] In2,
	output [31:0] Out
);
	wire co;
	assign {co,Out} = In1 + In2;	
	
endmodule

//========================================================== 
//					32-bit 2-to-1 MUX
//========================================================== 

module MUX32(
	input [31:0] In0,
	input [31:0] In1,
	input  Select,	
	output [31:0] Out
);

	assign Out = (Select)? In1:In0;
	
endmodule

//========================================================== 
//					Operation FIFO
//========================================================== 

module OPFIFO(
	input clk,
	input clr,
	input enbar,
	input [31:0] Instr0,
	input [31:0] Instr1,
	input [31:0] Instr2,
	input [31:0] Instr3,
	input [31:0] SC0,
	input [31:0] SC1,
	input [31:0] SC2,
	input [31:0] SC3,
	input BrHappens,
	input [31:0] BrSequence,
	input [31:0] PCPlus4,
	input [31:0] PCPlus8,
	input [31:0] PCPlus12,
	input [31:0] PCPlus16,
	output FIFOFull,
	output FIFOEmpty,
	output reg [63:0] Instr0F,
	output reg [63:0] Instr1F,
	output reg [63:0] Instr2F,
	output reg [63:0] Instr3F,
	output reg  [31:0] PCPlus4F,
	output reg  [31:0] PCPlus8F,
	output reg  [31:0] PCPlus12F,
	output reg  [31:0] PCPlus16F
);

	reg [7:0] busy ;			//FIFO lines' busy indicator 
	reg [7:0] next_busy;		//FIFO lines' next state busy indicator
	
	reg[63:0] line[31:0];  		//FIFO lines: Instruction, Sequence
	reg[31:0] PC[31:0];  		//FIFO lines: branch instruction pointer
	
	reg [31:0] writeptr;		//FIFO write pointer 
    reg [31:0] next_writeptr;	//FIFO next state write pointer 
	
	reg [31:0] readptr;			//FIFO read pointer
	reg [31:0] next_readptr;	//FIFO next state read pointer
			
	assign FIFOEmpty= BrHappens;
	assign FIFOFull=(busy==8'hFF);
	
	always @(posedge clk) begin
		if(clr || BrHappens) begin 
			writeptr <= 32'h03020100;
			readptr <= 32'h03020100;
			busy = 8'h00;
		end
		else begin
			readptr <= next_readptr;
			writeptr <= next_writeptr;
			busy <= next_busy;		
		end
	end		
	always @(*) begin
		line[writeptr[7:0]] = {Instr0,SC0};
		line[writeptr[15:8]] = {Instr1,SC1};
		line[writeptr[23:16]] = {Instr2,SC2};
		line[writeptr[31:24]] = {Instr3,SC3};
		PC[writeptr[7:0]] = PCPlus4;
		PC[writeptr[15:8]] = PCPlus8;
		PC[writeptr[23:16]] = PCPlus12;
		PC[writeptr[31:24]] = PCPlus16;	
		
		next_busy[writeptr[4:2]] = 1'b1;
	
		case(writeptr)
			32'h03020100: next_writeptr = 32'h07060504;
			32'h07060504: next_writeptr = 32'h0B0A0908;
			32'h0B0A0908: next_writeptr = 32'h0F0E0D0C;
			32'h0F0E0D0C: next_writeptr = 32'h13121110;
			32'h13121110: next_writeptr = 32'h17161514;
			32'h17161514: next_writeptr = 32'h1B1A1918;
			32'h1B1A1918: next_writeptr = 32'h1F1E1D1C;
			32'h1F1E1D1C: next_writeptr = 32'h03020100;
		endcase
	
	
		next_busy[readptr[4:2]] = 1'b0;
		Instr0F = line[readptr[7:0]]; 
		Instr1F = line[readptr[15:8]]; 
		Instr2F = line[readptr[23:16]];
		Instr3F = line[readptr[31:24]];	
		
		PCPlus4F = PC[readptr[7:0]];
		PCPlus8F = PC[readptr[15:8]];
		PCPlus12F = PC[readptr[23:16]];
		PCPlus16F = PC[readptr[31:24]];
			

		case(readptr)
			32'h03020100: next_readptr = (enbar)? 32'h1F1E1D1C : 32'h07060504;
			32'h07060504: next_readptr = (enbar)? 32'h03020100 : 32'h0B0A0908;
			32'h0B0A0908: next_readptr = (enbar)? 32'h07060504 : 32'h0F0E0D0C;
			32'h0F0E0D0C: next_readptr = (enbar)? 32'h0B0A0908 : 32'h13121110;
			32'h13121110: next_readptr = (enbar)? 32'h0F0E0D0C : 32'h17161514;
			32'h17161514: next_readptr = (enbar)? 32'h13121110 : 32'h1B1A1918;
			32'h1B1A1918: next_readptr = (enbar)? 32'h17161514 : 32'h1F1E1D1C;
			32'h1F1E1D1C: next_readptr = (enbar)? 32'h1B1A1918 : 32'h03020100;				
		endcase	
		
	end
endmodule	

//========================================================== 
//					IF/ID Pipeline Register
//========================================================== 

module IFIDRegister(
	input clk,
	input clr,
	input stall,
	input [63:0] Instr0F,
	input [63:0] Instr1F,
	input [63:0] Instr2F,
	input [63:0] Instr3F,			
	input [31:0] PCPlus4F,
	input [31:0] PCPlus8F,
	input [31:0] PCPlus12F,
	input [31:0] PCPlus16F,
	input FIFOEmpty,
	output reg [63:0] Instr0D,
	output reg [63:0] Instr1D,
	output reg [63:0] Instr2D,
	output reg [63:0] Instr3D,
	output reg [31:0] PCPlus4D,
	output reg [31:0] PCPlus8D,
	output reg [31:0] PCPlus12D,
	output reg [31:0] PCPlus16D,	
	output reg FIFOEmptyD	
);
	
	always @(posedge clk) begin
		if (clr) begin
			Instr0D <=64'h0000000000000000;
			Instr1D <=64'h0000000000000000;
			Instr2D <=64'h0000000000000000;
			Instr3D <=64'h0000000000000000;		
			PCPlus4D <=32'h00000000;
			PCPlus8D <=32'h00000000;
			PCPlus12D <=32'h00000000;
			PCPlus16D <=32'h00000000;
			FIFOEmptyD <=1'b0;
		end 
		else begin 
			if(!stall) begin
				Instr0D <= Instr0F;
				Instr1D <= Instr1F;
				Instr2D <= Instr2F;
				Instr3D <= Instr3F;				
				PCPlus4D <= PCPlus4F;
				PCPlus8D <= PCPlus8F;
				PCPlus12D <= PCPlus12F;
				PCPlus16D <= PCPlus16F;
				FIFOEmptyD <= FIFOEmpty;
			end
		end			
	end
	
endmodule

//========================================================== 
//					Reservation Station
//========================================================== 

module ReservationStation(
	input clk,
	input clr,
	input FIFOEmptyD,
	input BrHappens,
	input [31:0] BrSequence,
	input [63:0] Instr0D,
	input [63:0] Instr1D,
	input [63:0] Instr2D,
	input [63:0] Instr3D,
	input [31:0] RD01,
	input [31:0] RD02,
	input [31:0] RD11,
	input [31:0] RD12,
	input [31:0] RD21,
	input [31:0] RD22,
	input [31:0] RD31,
	input [31:0] RD32,
	input  write0,
	input  write1,
	input  write2,	
	input  [ 4:0] WR0,
	input  [ 4:0] WR1,
	input  [ 4:0] WR2,
	input  [31:0] WD0,	
	input  [31:0] WD1,	
	input  [31:0] WD2,
	input [31:0] ISequence0,
	input [31:0] ISequence1,
	input [31:0] ISequence2,
	input [31:0] ISequence3,
	input I0done,
	input I1done,
	input I2done,
	input I3done,
	input [31:0] PCPlus4D,
	input [31:0] PCPlus8D,
	input [31:0] PCPlus12D,
	input [31:0] PCPlus16D,				
	output reg [63:0] Instr0ID,
	output reg [63:0] Instr1ID,
	output reg [63:0] Instr2ID,
	output reg [63:0] Instr3ID,
	output reg RSFull,
	output reg [3:0] ActiveLanes,
	output reg [31:0] VJ0,
	output reg [31:0] VK0,
	output reg [31:0] VJ1,
	output reg [31:0] VK1,
	output reg [31:0] VJ2,
	output reg [31:0] VJ3,
	output reg [31:0] VK3,
	output reg [31:0] BrPC
);
		
	reg [31:0] busy;			//busy=1: RS line is already taken
	reg valid_busy;				//the busy status of the lines has been successfully updated
	
	reg [31:0] writeptr;		//write pointer	
	reg valid_writeptr;			//ValidWritePtr=1: write pointer is valid
	
	reg [7:0] ptr0;				//partial write pointer #0
	reg [7:0] ptr1;				//partial write pointer #1
	reg [7:0] ptr2;				//partial write pointer #2
	reg [7:0] ptr3;				//partial write pointer #3
	
	reg [31:0] condition0;		//partial write pointer #0 priority conditioner
	reg [31:0] condition1;		//partial write pointer #1 priority conditioner
	reg [31:0] condition2;		//partial write pointer #2 priority conditioner
	reg [31:0] condition3;		//partial write pointer #3 priority conditioner
	
	reg ptr0failed;				//write pointer allocation for instruction #0 failed
	reg ptr1failed;				//write pointer allocation for instruction #1 failed
	reg ptr2failed;				//write pointer allocation for instruction #2 failed
	reg ptr3failed;				//write pointer allocation for instruction #3 failed

	reg	[31:0] Instr[0:31];  	//Instruction
	reg	[31:0] Seq[0:31];  		//Sequence
	reg	[31:0] RowDecoder;		//Temporary Row Decoder
	
	reg [1:0] FU  [0:31];		//Functional Unit of the instruction
	reg [31:0] IPC [0:31];		//PC of the instruction

	reg valid_line;				//new lines has been successfully added to the reservation station
	
	reg [31:0] active;			//the line is already issued and not done yet
	reg [31:0] next_active;		//the next state of lines' activity
	
	reg [31:0] VJ [0:31];		//VJ of the instruction
	reg [31:0] VK [0:31];		//VK of the instruction
	reg [7:0] QJ [0:31];		//QJ of the instruction
	reg [7:0] QK [0:31];		//QK of the instruction

	reg [31:0] valid_VJ;		//The VJ value is valid 
	reg [31:0] valid_VK;		//The VK value is valid 
		
	reg [7:0] RRS [0:31];		//register result status 
	reg [31:0] RRSTaken;		//The register's value is waiting for some process to get finished
				
	reg [31:0] candidatelist0;	//partial read pointer #0 priority conditioner
	reg [31:0] candidatelist1;	//partial read pointer #1 priority conditioner
	reg [31:0] candidatelist2;	//partial read pointer #2 priority conditioner
	reg [31:0] candidatelist3;	//partial read pointer #3 priority conditioner	
	
	reg	[31:0] OwnerSeq0;  		//Sequence read register #0
	reg	[31:0] OwnerSeq1;  		//Sequence read register #1
	reg	[31:0] OwnerSeq2;  		//Sequence read register #2
	reg	[31:0] OwnerSeq3;  		//Sequence read register #3
	
	reg [7:0] candidate0;		//the first candidate instruction for the execution
	reg [7:0] candidate1;		//the second candidate instruction for the execution
	reg [7:0] candidate2;		//the third candidate instruction for the execution
	reg [7:0] candidate3;		//the fourth candidate instruction for the execution

	reg candidateDone0;			//the first candidate instruction for the execution is selected
	reg candidateDone1;			//the second candidate instruction for the execution is selected
	reg candidateDone2;			//the third candidate instruction for the execution is selected
	reg candidateDone3;			//the fourth candidate instruction for the execution is selected
	
	reg Aux1;					//indicates that the instruction #1 uses an auxiliary lane for execution
	reg Aux2;					//indicates that the instruction #2 uses an auxiliary lane for execution
	reg Aux3;					//indicates that the instruction #3 uses an auxiliary lane for execution
	
	always @(posedge clk) begin
		if(clr) begin 
			condition0 <= 32'h00000000;
			active <= 32'h00000000;
		end
		else begin
			condition0 <= busy;
			active <=next_active;
		end
	end
	
	//busy	
	always @(*) begin
		if(clr) 
			busy = 32'h00000000;
		else begin
			valid_busy=1'b0;
			busy=condition0;
			if(valid_writeptr) begin
				busy[writeptr[7:0]]=1'b1;
				busy[writeptr[15:8]]=1'b1;
				busy[writeptr[23:16]]=1'b1;
				busy[writeptr[31:24]]=1'b1;
				valid_busy=1'b1;
			end
			
			if(BrHappens) begin
				if(Seq[0]>BrSequence)
					busy[0]=1'b0;	
				if(Seq[1]>BrSequence)
					busy[1]=1'b0;	
				if(Seq[2]>BrSequence)
					busy[2]=1'b0;
				if(Seq[3]>BrSequence)
					busy[3]=1'b0;
				if(Seq[4]>BrSequence)
					busy[4]=1'b0;	
				if(Seq[5]>BrSequence)
					busy[5]=1'b0;	
				if(Seq[6]>BrSequence)
					busy[6]=1'b0;
				if(Seq[7]>BrSequence)
					busy[7]=1'b0;
				if(Seq[8]>BrSequence)
					busy[8]=1'b0;	
				if(Seq[9]>BrSequence)
					busy[9]=1'b0;	
				if(Seq[10]>BrSequence)
					busy[10]=1'b0;
				if(Seq[11]>BrSequence)
					busy[11]=1'b0;
				if(Seq[12]>BrSequence)
					busy[12]=1'b0;	
				if(Seq[13]>BrSequence)
					busy[13]=1'b0;	
				if(Seq[14]>BrSequence)
					busy[14]=1'b0;
				if(Seq[15]>BrSequence)
					busy[15]=1'b0;	
				if(Seq[16]>BrSequence)
					busy[16]=1'b0;	
				if(Seq[17]>BrSequence)
					busy[17]=1'b0;	
				if(Seq[18]>BrSequence)
					busy[18]=1'b0;
				if(Seq[19]>BrSequence)
					busy[19]=1'b0;
				if(Seq[20]>BrSequence)
					busy[20]=1'b0;	
				if(Seq[21]>BrSequence)
					busy[21]=1'b0;	
				if(Seq[22]>BrSequence)
					busy[22]=1'b0;
				if(Seq[23]>BrSequence)
					busy[23]=1'b0;
				if(Seq[24]>BrSequence)
					busy[24]=1'b0;	
				if(Seq[25]>BrSequence)
					busy[25]=1'b0;	
				if(Seq[26]>BrSequence)
					busy[26]=1'b0;
				if(Seq[27]>BrSequence)
					busy[27]=1'b0;
				if(Seq[28]>BrSequence)
					busy[28]=1'b0;	
				if(Seq[29]>BrSequence)
					busy[29]=1'b0;	
				if(Seq[30]>BrSequence)
					busy[30]=1'b0;
				if(Seq[31]>BrSequence)
					busy[31]=1'b0;		
			end
						
			if(I0done) begin
				if(ISequence0==Seq[0]) 
					busy[0]=1'b0;					
				else if(ISequence0==Seq[1]) 				
					busy[1]=1'b0;
				else if(ISequence0==Seq[2]) 				
					busy[2]=1'b0;
				else if(ISequence0==Seq[3]) 				
					busy[3]=1'b0;			
				else if(ISequence0==Seq[4]) 				
					busy[4]=1'b0;			
				else if(ISequence0==Seq[5]) 				
					busy[5]=1'b0;
				else if(ISequence0==Seq[6]) 				
					busy[6]=1'b0;
				else if(ISequence0==Seq[7]) 				
					busy[7]=1'b0;			
				else if(ISequence0==Seq[8]) 				
					busy[8]=1'b0;
				else if(ISequence0==Seq[9]) 				
					busy[9]=1'b0;
				else if(ISequence0==Seq[10])						
					busy[10]=1'b0;
				else if(ISequence0==Seq[11])						
					busy[11]=1'b0;
				else if(ISequence0==Seq[12])						
					busy[12]=1'b0;
				else if(ISequence0==Seq[13])						
					busy[13]=1'b0;
				else if(ISequence0==Seq[14])						
					busy[14]=1'b0;
				else if(ISequence0==Seq[15])						
					busy[15]=1'b0;
				else if(ISequence0==Seq[16]) 				
					busy[16]=1'b0;
				else if(ISequence0==Seq[17]) 				
					busy[17]=1'b0;
				else if(ISequence0==Seq[18]) 				
					busy[18]=1'b0;			
				else if(ISequence0==Seq[19]) 				
					busy[19]=1'b0;			
				else if(ISequence0==Seq[20]) 				
					busy[20]=1'b0;
				else if(ISequence0==Seq[21]) 				
					busy[21]=1'b0;
				else if(ISequence0==Seq[22]) 				
					busy[22]=1'b0;			
				else if(ISequence0==Seq[23]) 				
					busy[23]=1'b0;
				else if(ISequence0==Seq[24]) 				
					busy[24]=1'b0;
				else if(ISequence0==Seq[25])						
					busy[25]=1'b0;
				else if(ISequence0==Seq[26])						
					busy[26]=1'b0;
				else if(ISequence0==Seq[27])						
					busy[27]=1'b0;
				else if(ISequence0==Seq[28])						
					busy[28]=1'b0;
				else if(ISequence0==Seq[29])						
					busy[29]=1'b0;
				else if(ISequence0==Seq[30])						
					busy[30]=1'b0;	
				else if(ISequence0==Seq[31])						
					busy[31]=1'b0;				
			end
			
			if(I1done) begin
				if(ISequence1==Seq[0]) 
					busy[0]=1'b0;					
				else if(ISequence1==Seq[1]) 				
					busy[1]=1'b0;
				else if(ISequence1==Seq[2]) 				
					busy[2]=1'b0;
				else if(ISequence1==Seq[3]) 				
					busy[3]=1'b0;			
				else if(ISequence1==Seq[4]) 				
					busy[4]=1'b0;			
				else if(ISequence1==Seq[5]) 				
					busy[5]=1'b0;
				else if(ISequence1==Seq[6]) 				
					busy[6]=1'b0;
				else if(ISequence1==Seq[7]) 				
					busy[7]=1'b0;			
				else if(ISequence1==Seq[8]) 				
					busy[8]=1'b0;
				else if(ISequence1==Seq[9]) 				
					busy[9]=1'b0;
				else if(ISequence1==Seq[10])						
					busy[10]=1'b0;
				else if(ISequence1==Seq[11])						
					busy[11]=1'b0;
				else if(ISequence1==Seq[12])						
					busy[12]=1'b0;
				else if(ISequence1==Seq[13])						
					busy[13]=1'b0;
				else if(ISequence1==Seq[14])						
					busy[14]=1'b0;
				else if(ISequence1==Seq[15])						
					busy[15]=1'b0;
				else if(ISequence1==Seq[16]) 				
					busy[16]=1'b0;
				else if(ISequence1==Seq[17]) 				
					busy[17]=1'b0;
				else if(ISequence1==Seq[18]) 				
					busy[18]=1'b0;			
				else if(ISequence1==Seq[19]) 				
					busy[19]=1'b0;			
				else if(ISequence1==Seq[20]) 				
					busy[20]=1'b0;
				else if(ISequence1==Seq[21]) 				
					busy[21]=1'b0;
				else if(ISequence1==Seq[22]) 				
					busy[22]=1'b0;			
				else if(ISequence1==Seq[23]) 				
					busy[23]=1'b0;
				else if(ISequence1==Seq[24]) 				
					busy[24]=1'b0;
				else if(ISequence1==Seq[25])						
					busy[25]=1'b0;
				else if(ISequence1==Seq[26])						
					busy[26]=1'b0;
				else if(ISequence1==Seq[27])						
					busy[27]=1'b0;
				else if(ISequence1==Seq[28])						
					busy[28]=1'b0;
				else if(ISequence1==Seq[29])						
					busy[29]=1'b0;
				else if(ISequence1==Seq[30])						
					busy[30]=1'b0;	
				else if(ISequence1==Seq[31])						
					busy[31]=1'b0;
			end
			
			if(I2done) begin
				if(ISequence2==Seq[0]) 
					busy[0]=1'b0;					
				else if(ISequence2==Seq[1]) 				
					busy[1]=1'b0;
				else if(ISequence2==Seq[2]) 				
					busy[2]=1'b0;
				else if(ISequence2==Seq[3]) 				
					busy[3]=1'b0;			
				else if(ISequence2==Seq[4]) 				
					busy[4]=1'b0;			
				else if(ISequence2==Seq[5]) 				
					busy[5]=1'b0;
				else if(ISequence2==Seq[6]) 				
					busy[6]=1'b0;
				else if(ISequence2==Seq[7]) 				
					busy[7]=1'b0;			
				else if(ISequence2==Seq[8]) 				
					busy[8]=1'b0;
				else if(ISequence2==Seq[9]) 				
					busy[9]=1'b0;
				else if(ISequence2==Seq[10])						
					busy[10]=1'b0;
				else if(ISequence2==Seq[11])						
					busy[11]=1'b0;
				else if(ISequence2==Seq[12])						
					busy[12]=1'b0;
				else if(ISequence2==Seq[13])						
					busy[13]=1'b0;
				else if(ISequence2==Seq[14])						
					busy[14]=1'b0;
				else if(ISequence2==Seq[15])						
					busy[15]=1'b0;
				else if(ISequence2==Seq[16]) 				
					busy[16]=1'b0;
				else if(ISequence2==Seq[17]) 				
					busy[17]=1'b0;
				else if(ISequence2==Seq[18]) 				
					busy[18]=1'b0;			
				else if(ISequence2==Seq[19]) 				
					busy[19]=1'b0;			
				else if(ISequence2==Seq[20]) 				
					busy[20]=1'b0;
				else if(ISequence2==Seq[21]) 				
					busy[21]=1'b0;
				else if(ISequence2==Seq[22]) 				
					busy[22]=1'b0;			
				else if(ISequence2==Seq[23]) 				
					busy[23]=1'b0;
				else if(ISequence2==Seq[24]) 				
					busy[24]=1'b0;
				else if(ISequence2==Seq[25])						
					busy[25]=1'b0;
				else if(ISequence2==Seq[26])						
					busy[26]=1'b0;
				else if(ISequence2==Seq[27])						
					busy[27]=1'b0;
				else if(ISequence2==Seq[28])						
					busy[28]=1'b0;
				else if(ISequence2==Seq[29])						
					busy[29]=1'b0;
				else if(ISequence2==Seq[30])						
					busy[30]=1'b0;	
				else if(ISequence2==Seq[31])						
					busy[31]=1'b0;
			end
			
			if(I3done) begin
				if(ISequence3==Seq[0]) 
					busy[0]=1'b0;					
				else if(ISequence3==Seq[1]) 				
					busy[1]=1'b0;
				else if(ISequence3==Seq[2]) 				
					busy[2]=1'b0;
				else if(ISequence3==Seq[3]) 				
					busy[3]=1'b0;			
				else if(ISequence3==Seq[4]) 				
					busy[4]=1'b0;			
				else if(ISequence3==Seq[5]) 				
					busy[5]=1'b0;
				else if(ISequence3==Seq[6]) 				
					busy[6]=1'b0;
				else if(ISequence3==Seq[7]) 				
					busy[7]=1'b0;			
				else if(ISequence3==Seq[8]) 				
					busy[8]=1'b0;
				else if(ISequence3==Seq[9]) 				
					busy[9]=1'b0;
				else if(ISequence3==Seq[10])						
					busy[10]=1'b0;
				else if(ISequence3==Seq[11])						
					busy[11]=1'b0;
				else if(ISequence3==Seq[12])						
					busy[12]=1'b0;
				else if(ISequence3==Seq[13])						
					busy[13]=1'b0;
				else if(ISequence3==Seq[14])						
					busy[14]=1'b0;
				else if(ISequence3==Seq[15])						
					busy[15]=1'b0;
				else if(ISequence3==Seq[16]) 				
					busy[16]=1'b0;
				else if(ISequence3==Seq[17]) 				
					busy[17]=1'b0;
				else if(ISequence3==Seq[18]) 				
					busy[18]=1'b0;			
				else if(ISequence3==Seq[19]) 				
					busy[19]=1'b0;			
				else if(ISequence3==Seq[20]) 				
					busy[20]=1'b0;
				else if(ISequence3==Seq[21]) 				
					busy[21]=1'b0;
				else if(ISequence3==Seq[22]) 				
					busy[22]=1'b0;			
				else if(ISequence3==Seq[23]) 				
					busy[23]=1'b0;
				else if(ISequence3==Seq[24]) 				
					busy[24]=1'b0;
				else if(ISequence3==Seq[25])						
					busy[25]=1'b0;
				else if(ISequence3==Seq[26])						
					busy[26]=1'b0;
				else if(ISequence3==Seq[27])						
					busy[27]=1'b0;
				else if(ISequence3==Seq[28])						
					busy[28]=1'b0;
				else if(ISequence3==Seq[29])						
					busy[29]=1'b0;
				else if(ISequence3==Seq[30])						
					busy[30]=1'b0;	
				else if(ISequence3==Seq[31])						
					busy[31]=1'b0;
			end
	
		end
	end
	
	//write pointer					
	always @(*) begin		
		RSFull=1'b0;
		valid_writeptr=1'b0;

		ptr0failed=1'b0;
		ptr1failed=1'b0;
		ptr2failed=1'b0;
		ptr3failed=1'b0;
			
		if(!FIFOEmptyD && Instr0D) begin		
			if(condition0[0]!=1'b1)
				ptr0=8'h00;	
			else if(condition0[1]!=1'b1)
				ptr0=8'h01;	
			else if(condition0[2]!=1'b1)
				ptr0=8'h02;	
			else if(condition0[3]!=1'b1)
				ptr0=8'h03;	
			else if(condition0[4]!=1'b1)
				ptr0=8'h04;
			else if(condition0[5]!=1'b1)
				ptr0=8'h05;	
			else if(condition0[6]!=1'b1)
				ptr0=8'h06;	
			else if(condition0[7]!=1'b1)
				ptr0=8'h07;	
			else if(condition0[8]!=1'b1)
				ptr0=8'h08;	
			else if(condition0[9]!=1'b1)
				ptr0=8'h09;	
			else if(condition0[10]!=1'b1)
				ptr0=8'h0A;	
			else if(condition0[11]!=1'b1)
				ptr0=8'h0B;	
			else if(condition0[12]!=1'b1)
				ptr0=8'h0C;				
			else if(condition0[13]!=1'b1)
				ptr0=8'h0D;	
			else if(condition0[14]!=1'b1)
				ptr0=8'h0E;	
			else if(condition0[15]!=1'b1)
				ptr0=8'h0F;							
			else if(condition0[16]!=1'b1)
				ptr0=8'h10;
			else if(condition0[17]!=1'b1)
				ptr0=8'h11;	
			else if(condition0[18]!=1'b1)
				ptr0=8'h12;	
			else if(condition0[19]!=1'b1)
				ptr0=8'h13;	
			else if(condition0[20]!=1'b1)
				ptr0=8'h14;	
			else if(condition0[21]!=1'b1)
				ptr0=8'h15;	
			else if(condition0[22]!=1'b1)
				ptr0=8'h16;	
			else if(condition0[23]!=1'b1)
				ptr0=8'h17;	
			else if(condition0[24]!=1'b1)
				ptr0=8'h18;
			else if(condition0[25]!=1'b1)
				ptr0=8'h19;
			else if(condition0[26]!=1'b1)			
				ptr0=8'h1A;	
			else if(condition0[27]!=1'b1)			
				ptr0=8'h1B;	
			else if(condition0[28]!=1'b1)
				ptr0=8'h1C;			
			else
				ptr0failed=1'b1;
			
			if(!ptr0failed) begin		
				condition1=condition0;
				condition1[ptr0]=1'b1;

				if(condition1[1]!=1'b1)
					ptr1=8'h01;	
				else if(condition1[2]!=1'b1)
					ptr1=8'h02;	
				else if(condition1[3]!=1'b1)
					ptr1=8'h03;	
				else if(condition1[4]!=1'b1)
					ptr1=8'h04;
				else if(condition1[5]!=1'b1)
					ptr1=8'h05;	
				else if(condition1[6]!=1'b1)
					ptr1=8'h06;	
				else if(condition1[7]!=1'b1)
					ptr1=8'h07;	
				else if(condition1[8]!=1'b1)
					ptr1=8'h08;	
				else if(condition1[9]!=1'b1)
					ptr1=8'h09;	
				else if(condition1[10]!=1'b1)
					ptr1=8'h0A;	
				else if(condition1[11]!=1'b1)
					ptr1=8'h0B;	
				else if(condition1[12]!=1'b1)
					ptr1=8'h0C;				
				else if(condition1[13]!=1'b1)
					ptr1=8'h0D;	
				else if(condition1[14]!=1'b1)
					ptr1=8'h0E;	
				else if(condition1[15]!=1'b1)
					ptr1=8'h0F;							
				else if(condition1[16]!=1'b1)
					ptr1=8'h10;
				else if(condition1[17]!=1'b1)
					ptr1=8'h11;	
				else if(condition1[18]!=1'b1)
					ptr1=8'h12;	
				else if(condition1[19]!=1'b1)
					ptr1=8'h13;	
				else if(condition1[20]!=1'b1)
					ptr1=8'h14;	
				else if(condition1[21]!=1'b1)
					ptr1=8'h15;	
				else if(condition1[22]!=1'b1)
					ptr1=8'h16;	
				else if(condition1[23]!=1'b1)
					ptr1=8'h17;	
				else if(condition1[24]!=1'b1)
					ptr1=8'h18;
				else if(condition1[25]!=1'b1)
					ptr1=8'h19;
				else if(condition1[26]!=1'b1)			
					ptr1=8'h1A;	
				else if(condition1[27]!=1'b1)			
					ptr1=8'h1B;	
				else if(condition1[28]!=1'b1)
					ptr1=8'h1C;	
				else if(condition1[29]!=1'b1)
					ptr1=8'h1D;	
				else
					ptr1failed=1'b1;
			end
			
			if(!ptr1failed) begin
				condition2=condition1;
				condition2[ptr1]=1'b1;

				if(condition2[2]!=1'b1)
					ptr2=8'h02;	
				else if(condition2[3]!=1'b1)
					ptr2=8'h03;	
				else if(condition2[4]!=1'b1)
					ptr2=8'h04;
				else if(condition2[5]!=1'b1)
					ptr2=8'h05;	
				else if(condition2[6]!=1'b1)
					ptr2=8'h06;	
				else if(condition2[7]!=1'b1)
					ptr2=8'h07;	
				else if(condition2[8]!=1'b1)
					ptr2=8'h08;	
				else if(condition2[9]!=1'b1)
					ptr2=8'h09;	
				else if(condition2[10]!=1'b1)
					ptr2=8'h0A;	
				else if(condition2[11]!=1'b1)
					ptr2=8'h0B;	
				else if(condition2[12]!=1'b1)
					ptr2=8'h0C;				
				else if(condition2[13]!=1'b1)
					ptr2=8'h0D;	
				else if(condition2[14]!=1'b1)
					ptr2=8'h0E;	
				else if(condition2[15]!=1'b1)
					ptr2=8'h0F;							
				else if(condition2[16]!=1'b1)
					ptr2=8'h10;
				else if(condition2[17]!=1'b1)
					ptr2=8'h11;	
				else if(condition2[18]!=1'b1)
					ptr2=8'h12;	
				else if(condition2[19]!=1'b1)
					ptr2=8'h13;	
				else if(condition2[20]!=1'b1)
					ptr2=8'h14;	
				else if(condition2[21]!=1'b1)
					ptr2=8'h15;	
				else if(condition2[22]!=1'b1)
					ptr2=8'h16;	
				else if(condition2[23]!=1'b1)
					ptr2=8'h17;	
				else if(condition2[24]!=1'b1)
					ptr2=8'h18;
				else if(condition2[25]!=1'b1)
					ptr2=8'h19;
				else if(condition2[26]!=1'b1)			
					ptr2=8'h1A;	
				else if(condition2[27]!=1'b1)			
					ptr2=8'h1B;	
				else if(condition2[28]!=1'b1)
					ptr2=8'h1C;	
				else if(condition2[29]!=1'b1)
					ptr2=8'h1D;	
				else if(condition2[30]!=1'b1)
					ptr2=8'h1E;		
				else
					ptr2failed=1'b1;
			end
			
			if(!ptr2failed) begin
				condition3=condition2;
				condition3[ptr2]=1'b1;
			
				if(condition3[3]!=1'b1)
					ptr3=8'h03;	
				else if(condition3[4]!=1'b1)
					ptr3=8'h04;
				else if(condition3[5]!=1'b1)
					ptr3=8'h05;	
				else if(condition3[6]!=1'b1)
					ptr3=8'h06;	
				else if(condition3[7]!=1'b1)
					ptr3=8'h07;	
				else if(condition3[8]!=1'b1)
					ptr3=8'h08;	
				else if(condition3[9]!=1'b1)
					ptr3=8'h09;	
				else if(condition3[10]!=1'b1)
					ptr3=8'h0A;	
				else if(condition3[11]!=1'b1)
					ptr3=8'h0B;	
				else if(condition3[12]!=1'b1)
					ptr3=8'h0C;				
				else if(condition3[13]!=1'b1)
					ptr3=8'h0D;	
				else if(condition3[14]!=1'b1)
					ptr3=8'h0E;	
				else if(condition3[15]!=1'b1)
					ptr3=8'h0F;							
				else if(condition3[16]!=1'b1)
					ptr3=8'h10;
				else if(condition3[17]!=1'b1)
					ptr3=8'h11;	
				else if(condition3[18]!=1'b1)
					ptr3=8'h12;	
				else if(condition3[19]!=1'b1)
					ptr3=8'h13;	
				else if(condition3[20]!=1'b1)
					ptr3=8'h14;	
				else if(condition3[21]!=1'b1)
					ptr3=8'h15;	
				else if(condition3[22]!=1'b1)
					ptr3=8'h16;	
				else if(condition3[23]!=1'b1)
					ptr3=8'h17;	
				else if(condition3[24]!=1'b1)
					ptr3=8'h18;
				else if(condition3[25]!=1'b1)
					ptr3=8'h19;
				else if(condition3[26]!=1'b1)			
					ptr3=8'h1A;	
				else if(condition3[27]!=1'b1)			
					ptr3=8'h1B;	
				else if(condition3[28]!=1'b1)
					ptr3=8'h1C;	
				else if(condition3[29]!=1'b1)
					ptr3=8'h1D;	
				else if(condition3[30]!=1'b1)
					ptr3=8'h1E;	
				else if(condition3[31]!=1'b1)
					ptr3=8'h1F;		
				else
					ptr3failed=1'b1;
			end	
			if( ptr0failed || ptr1failed || ptr2failed || ptr3failed) 
				RSFull=1'b1;
			else begin
				writeptr = {ptr3,ptr2,ptr1,ptr0};
				valid_writeptr=1'b1;		
			end 		
				
		end
		else
			valid_writeptr=1'b0;	
				
	end
		
	//V,Q, RRS
	always @(negedge clk) begin		
		if(clr) begin		
			RRSTaken[0]  = 1'b0;
			RRSTaken[1]  = 1'b0;
			RRSTaken[2]  = 1'b0;
			RRSTaken[3]  = 1'b0;
			RRSTaken[4]  = 1'b0;
			RRSTaken[5]  = 1'b0;
			RRSTaken[6]  = 1'b0;
			RRSTaken[7]  = 1'b0;
			RRSTaken[8]  = 1'b0;
			RRSTaken[9]  = 1'b0;
			RRSTaken[10] = 1'b0;
			RRSTaken[11] = 1'b0;
			RRSTaken[12] = 1'b0;
			RRSTaken[13] = 1'b0;
			RRSTaken[14] = 1'b0;
			RRSTaken[15] = 1'b0;
			RRSTaken[16] = 1'b0;
			RRSTaken[17] = 1'b0;
			RRSTaken[18] = 1'b0;
			RRSTaken[19] = 1'b0;
			RRSTaken[20] = 1'b0;
			RRSTaken[21] = 1'b0;
			RRSTaken[22] = 1'b0;
			RRSTaken[23] = 1'b0;
			RRSTaken[24] = 1'b0;
			RRSTaken[25] = 1'b0;
			RRSTaken[26] = 1'b0;
			RRSTaken[27] = 1'b0;
			RRSTaken[28] = 1'b0;
			RRSTaken[29] = 1'b0;
			RRSTaken[30] = 1'b0;
			RRSTaken[31] = 1'b0;
			valid_VJ = 32'hFFFFFFFF;
			valid_VK = 32'hFFFFFFFF;
		end 
		else begin		
			candidate0=8'h00;
			candidate1=8'h01;
			candidate2=8'h02;
			candidate3=8'h03;
			
			candidateDone0=1'b0;
			candidateDone1=1'b0;
			candidateDone2=1'b0;
			candidateDone3=1'b0;
			
			Aux1=1'b0;
			Aux2=1'b0;
			Aux3=1'b0;
			
			ActiveLanes=4'h0;
			Instr0ID=64'h00000000FFFFFFFF;
			Instr1ID=64'h00000000FFFFFFFF;
			Instr2ID=64'h00000000FFFFFFFF;
			Instr3ID=64'h00000000FFFFFFFF;
			VJ0=32'h00000000;
			VK0=32'hFFFFFFFF;
			VJ1=32'h00000000;
			VK1=32'hFFFFFFFF;
			VJ2=32'h00000000;
			VJ3=32'h00000000;
			VK3=32'hFFFFFFFF;
			
			valid_line=1'b0;
			if(valid_writeptr && valid_busy) begin
				Instr[writeptr[7:0]]= Instr0D[63:32];
				Instr[writeptr[15:8]]= Instr1D[63:32];
				Instr[writeptr[23:16]]= Instr2D[63:32];
				Instr[writeptr[31:24]]= Instr3D[63:32];
				
				Seq[writeptr[7:0]]= Instr0D[31:0];
				Seq[writeptr[15:8]]= Instr1D[31:0];
				Seq[writeptr[23:16]]= Instr2D[31:0];
				Seq[writeptr[31:24]]= Instr3D[31:0];
				
				
				IPC[writeptr[7:0]]=PCPlus4D;
				IPC[writeptr[15:8]]=PCPlus8D;
				IPC[writeptr[23:16]]=PCPlus12D;
				IPC[writeptr[31:24]]=PCPlus16D;
				
				case (Instr0D[63:58]) //op field of the instruction					
					6'b100_011: FU[writeptr[7:0]]=2'b10;				//load														
					6'b101_011: FU[writeptr[7:0]]=2'b11;				//store					
					6'b000_000: FU[writeptr[7:0]]=2'b01;				//R-Type					
					6'b001_111: FU[writeptr[7:0]]=2'b01;				//lui													
					6'b000_100, 6'b000_101: FU[writeptr[7:0]]=2'b00;	//branch					
					default: FU[writeptr[7:0]]=2'b01;					//I-Type
				endcase
				case (Instr1D[63:58]) //op field of the instruction					
					6'b100_011: FU[writeptr[15:8]]=2'b10;				//load														
					6'b101_011: FU[writeptr[15:8]]=2'b11;				//store					
					6'b000_000: FU[writeptr[15:8]]=2'b01;				//R-Type					
					6'b001_111: FU[writeptr[15:8]]=2'b01;				//lui													
					6'b000_100, 6'b000_101: FU[writeptr[15:8]]=2'b00;	//branch					
					default: FU[writeptr[15:8]]=2'b01;					//I-Type
				endcase
				case (Instr2D[63:58]) //op field of the instruction					
					6'b100_011: FU[writeptr[23:16]]=2'b10;				//load														
					6'b101_011: FU[writeptr[23:16]]=2'b11;				//store					
					6'b000_000: FU[writeptr[23:16]]=2'b01;				//R-Type					
					6'b001_111: FU[writeptr[23:16]]=2'b01;				//lui													
					6'b000_100, 6'b000_101: FU[writeptr[23:16]]=2'b00;	//branch					
					default: FU[writeptr[23:16]]=2'b01;					//I-Type
				endcase
				case (Instr3D[63:58]) //op field of the instruction					
					6'b100_011: FU[writeptr[31:24]]=2'b10;				//load														
					6'b101_011: FU[writeptr[31:24]]=2'b11;				//store					
					6'b000_000: FU[writeptr[31:24]]=2'b01;				//R-Type					
					6'b001_111: FU[writeptr[31:24]]=2'b01;				//lui													
					6'b000_100, 6'b000_101: FU[writeptr[31:24]]=2'b00;	//branch					
					default: FU[writeptr[31:24]]=2'b01;					//I-Type
				endcase	
				valid_line=1'b1;
			end
			
			if(BrHappens) begin
				if(Seq[0]>BrSequence) begin
					RowDecoder=Instr[0];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end	
				if(Seq[1]>BrSequence) begin
					RowDecoder=Instr[1];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end	
				if(Seq[2]>BrSequence) begin
					RowDecoder=Instr[2];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[3]>BrSequence) begin
					RowDecoder=Instr[3];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[4]>BrSequence) begin
					RowDecoder=Instr[4];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[5]>BrSequence) begin
					RowDecoder=Instr[5];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[6]>BrSequence) begin
					RowDecoder=Instr[6];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[7]>BrSequence) begin
					RowDecoder=Instr[7];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[8]>BrSequence) begin
					RowDecoder=Instr[8];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[9]>BrSequence) begin
					RowDecoder=Instr[9];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[10]>BrSequence) begin
					RowDecoder=Instr[10];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[11]>BrSequence) begin
					RowDecoder=Instr[11];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[12]>BrSequence) begin
					RowDecoder=Instr[12];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase	
				end
				if(Seq[13]>BrSequence) begin
					RowDecoder=Instr[13];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[14]>BrSequence) begin
					RowDecoder=Instr[14];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[15]>BrSequence) begin
					RowDecoder=Instr[15];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end				
				if(Seq[16]>BrSequence) begin
					RowDecoder=Instr[16];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end	
				if(Seq[17]>BrSequence) begin
					RowDecoder=Instr[17];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end	
				if(Seq[18]>BrSequence) begin
					RowDecoder=Instr[18];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[19]>BrSequence) begin
					RowDecoder=Instr[19];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[20]>BrSequence) begin
					RowDecoder=Instr[20];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[21]>BrSequence) begin
					RowDecoder=Instr[21];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[22]>BrSequence) begin
					RowDecoder=Instr[22];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[23]>BrSequence) begin
					RowDecoder=Instr[23];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[24]>BrSequence) begin
					RowDecoder=Instr[24];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[25]>BrSequence) begin
					RowDecoder=Instr[25];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[26]>BrSequence) begin
					RowDecoder=Instr[26];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[27]>BrSequence) begin
					RowDecoder=Instr[27];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[28]>BrSequence) begin
					RowDecoder=Instr[28];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase	
				end
				if(Seq[29]>BrSequence) begin
					RowDecoder=Instr[29];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[30]>BrSequence) begin
					RowDecoder=Instr[30];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[31]>BrSequence) begin
					RowDecoder=Instr[31];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end				
			end				
					
			if(valid_line && valid_busy && valid_writeptr) begin
				VJ[writeptr[7:0]]=RD01;
				VK[writeptr[7:0]]=RD02;
				VJ[writeptr[15:8]]=RD11;
				VK[writeptr[15:8]]=RD12;	
				VJ[writeptr[23:16]]=RD21;
				VK[writeptr[23:16]]=RD22;
				VJ[writeptr[31:24]]=RD31;
				VK[writeptr[31:24]]=RD32;
				valid_VJ[writeptr[7:0]]=1'b1;				
				valid_VK[writeptr[7:0]]=1'b1;	
				valid_VJ[writeptr[15:8]]=1'b1;				
				valid_VK[writeptr[15:8]]=1'b1;	
				valid_VJ[writeptr[23:16]]=1'b1;				
				valid_VK[writeptr[23:16]]=1'b1;	
				valid_VJ[writeptr[31:24]]=1'b1;				
				valid_VK[writeptr[31:24]]=1'b1;	
										
				case (Instr0D[63:58]) //op field of the instruction						
					//load
					6'b100_011: begin										
						if (RRSTaken[Instr0D[57:53]]) begin							
							valid_VJ[writeptr[7:0]]=1'b0;
							QJ[writeptr[7:0]]=RRS[Instr0D[57:53]];
						end	
						RRSTaken[Instr0D[52:48]]=1'b1;
						RRS[Instr0D[52:48]]=writeptr[7:0];
					end
					//store
					6'b101_011: begin
						if (RRSTaken[Instr0D[57:53]]) begin							
							valid_VJ[writeptr[7:0]]=1'b0;
							QJ[writeptr[7:0]]=RRS[Instr0D[57:53]];
						end	
						if (RRSTaken[Instr0D[52:48]]) begin							
							valid_VK[writeptr[7:0]]=1'b0;
							QK[writeptr[7:0]]=RRS[Instr0D[52:48]];
						end							
					end
					//R-Type
					6'b000_000: begin					
						if (RRSTaken[Instr0D[57:53]]) begin								
							valid_VJ[writeptr[7:0]]=1'b0;
							QJ[writeptr[7:0]]=RRS[Instr0D[57:53]];
						end
						if (RRSTaken[Instr0D[52:48]]) begin							
							valid_VK[writeptr[7:0]]=1'b0;
							QK[writeptr[7:0]]=RRS[Instr0D[52:48]];
						end	
						RRSTaken[Instr0D[47:43]]=1'b1;
						RRS[Instr0D[47:43]]=writeptr[7:0];
					end
					//lui
					6'b001_111: begin				
						RRSTaken[Instr0D[52:48]]=1'b1;
						RRS[Instr0D[52:48]]=writeptr[7:0];					
					end
					//branch
					6'b000_100, 6'b000_101: begin
						if (RRSTaken[Instr0D[57:53]]) begin							
							valid_VJ[writeptr[7:0]]=1'b0;
							QJ[writeptr[7:0]]=RRS[Instr0D[57:53]];
						end	
						if (RRSTaken[Instr0D[52:48]]) begin							
							valid_VK[writeptr[7:0]]=1'b0;
							QK[writeptr[7:0]]=RRS[Instr0D[52:48]];
						end
					end
					//I-Type
					6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin					
						if (RRSTaken[Instr0D[57:53]]) begin							
							valid_VJ[writeptr[7:0]]=1'b0;
							QJ[writeptr[7:0]]=RRS[Instr0D[57:53]];
						end
						RRSTaken[Instr0D[52:48]]=1'b1;
						RRS[Instr0D[52:48]]=writeptr[7:0];	
					end
				endcase	

				case (Instr1D[63:58]) //op field of the instruction						
					//load
					6'b100_011: begin															
						if (RRSTaken[Instr1D[57:53]]) begin							
							valid_VJ[writeptr[15:8]]=1'b0;
							QJ[writeptr[15:8]]=RRS[Instr1D[57:53]];
						end	
						RRSTaken[Instr1D[52:48]]=1'b1;
						RRS[Instr1D[52:48]]=writeptr[15:8];	
					end
					//store
					6'b101_011: begin
						if (RRSTaken[Instr1D[57:53]]) begin							
							valid_VJ[writeptr[15:8]]=1'b0;
							QJ[writeptr[15:8]]=RRS[Instr1D[57:53]];
						end	
						if (RRSTaken[Instr1D[52:48]]) begin							
							valid_VK[writeptr[15:8]]=1'b0;
							QK[writeptr[15:8]]=RRS[Instr1D[52:48]];
						end							
					end
					//R-Type
					6'b000_000: begin						
						if (RRSTaken[Instr1D[57:53]]) begin								
							valid_VJ[writeptr[15:8]]=1'b0;
							QJ[writeptr[15:8]]=RRS[Instr1D[57:53]];
						end
						if (RRSTaken[Instr1D[52:48]]) begin							
							valid_VK[writeptr[15:8]]=1'b0;
							QK[writeptr[15:8]]=RRS[Instr1D[52:48]];
						end
						RRSTaken[Instr1D[47:43]]=1'b1;
						RRS[Instr1D[47:43]]=writeptr[15:8];
					end
					//lui
					6'b001_111: begin				
						RRSTaken[Instr1D[52:48]]=1'b1;
						RRS[Instr1D[52:48]]=writeptr[15:8];					
					end
					//branch
					6'b000_100, 6'b000_101: begin
						if (RRSTaken[Instr1D[57:53]]) begin							
							valid_VJ[writeptr[15:8]]=1'b0;
							QJ[writeptr[15:8]]=RRS[Instr1D[57:53]];
						end	
						if (RRSTaken[Instr1D[52:48]]) begin							
							valid_VK[writeptr[15:8]]=1'b0;
							QK[writeptr[15:8]]=RRS[Instr1D[52:48]];
						end
					end
					//I-Type
					6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin											
						if (RRSTaken[Instr1D[57:53]]) begin							
							valid_VJ[writeptr[15:8]]=1'b0;
							QJ[writeptr[15:8]]=RRS[Instr1D[57:53]];
						end
						RRSTaken[Instr1D[52:48]]=1'b1;
						RRS[Instr1D[52:48]]=writeptr[15:8];
					end
				endcase	

				case (Instr2D[63:58]) //op field of the instruction						
					//load
					6'b100_011: begin																
						if (RRSTaken[Instr2D[57:53]]) begin							
							valid_VJ[writeptr[23:16]]=1'b0;
							QJ[writeptr[23:16]]=RRS[Instr2D[57:53]];
						end
						RRSTaken[Instr2D[52:48]]=1'b1;
						RRS[Instr2D[52:48]]=writeptr[23:16];
					end
					//store
					6'b101_011: begin
						if (RRSTaken[Instr2D[57:53]]) begin							
							valid_VJ[writeptr[23:16]]=1'b0;
							QJ[writeptr[23:16]]=RRS[Instr2D[57:53]];
						end	
						if (RRSTaken[Instr2D[52:48]]) begin							
							valid_VK[writeptr[23:16]]=1'b0;
							QK[writeptr[23:16]]=RRS[Instr2D[52:48]];
						end							
					end
					//R-Type
					6'b000_000: begin						
						if (RRSTaken[Instr2D[57:53]]) begin								
							valid_VJ[writeptr[23:16]]=1'b0;
							QJ[writeptr[23:16]]=RRS[Instr2D[57:53]];
						end
						if (RRSTaken[Instr2D[52:48]]) begin							
							valid_VK[writeptr[23:16]]=1'b0;
							QK[writeptr[23:16]]=RRS[Instr2D[52:48]];
						end	
						RRSTaken[Instr2D[47:43]]=1'b1;
						RRS[Instr2D[47:43]]=writeptr[23:16];
					end
					//lui
					6'b001_111: begin				
						RRSTaken[Instr2D[52:48]]=1'b1;
						RRS[Instr2D[52:48]]=writeptr[23:16];					
					end
					//branch
					6'b000_100, 6'b000_101: begin
						if (RRSTaken[Instr2D[57:53]]) begin							
							valid_VJ[writeptr[23:16]]=1'b0;
							QJ[writeptr[23:16]]=RRS[Instr2D[57:53]];
						end	
						if (RRSTaken[Instr2D[52:48]]) begin							
							valid_VK[writeptr[23:16]]=1'b0;
							QK[writeptr[23:16]]=RRS[Instr2D[52:48]];
						end
					end
					//I-Type
					6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin					
						if (RRSTaken[Instr2D[57:53]]) begin							
							valid_VJ[writeptr[23:16]]=1'b0;
							QJ[writeptr[23:16]]=RRS[Instr2D[57:53]];
						end
						RRSTaken[Instr2D[52:48]]=1'b1;
						RRS[Instr2D[52:48]]=writeptr[23:16];
					end
				endcase	
				
				case (Instr3D[63:58]) //op field of the instruction						
					//load
					6'b100_011: begin										
						if (RRSTaken[Instr3D[57:53]]) begin							
							valid_VJ[writeptr[31:24]]=1'b0;
							QJ[writeptr[31:24]]=RRS[Instr3D[57:53]];
						end
						RRSTaken[Instr3D[52:48]]=1'b1;
						RRS[Instr3D[52:48]]=writeptr[31:24];
					end
					//store
					6'b101_011: begin
						if (RRSTaken[Instr3D[57:53]]) begin							
							valid_VJ[writeptr[31:24]]=1'b0;
							QJ[writeptr[31:24]]=RRS[Instr3D[57:53]];
						end	
						if (RRSTaken[Instr3D[52:48]]) begin							
							valid_VK[writeptr[31:24]]=1'b0;
							QK[writeptr[31:24]]=RRS[Instr3D[52:48]];
						end							
					end
					//R-Type
					6'b000_000: begin						
						if (RRSTaken[Instr3D[57:53]]) begin								
							valid_VJ[writeptr[31:24]]=1'b0;
							QJ[writeptr[31:24]]=RRS[Instr3D[57:53]];
						end
						if (RRSTaken[Instr3D[52:48]]) begin							
							valid_VK[writeptr[31:24]]=1'b0;
							QK[writeptr[31:24]]=RRS[Instr3D[52:48]];
						end	
						RRSTaken[Instr3D[47:43]]=1'b1;
						RRS[Instr3D[47:43]]=writeptr[31:24];
					end
					//lui
					6'b001_111: begin				
						RRSTaken[Instr3D[52:48]]=1'b1;
						RRS[Instr3D[52:48]]=writeptr[31:24];					
					end
					//branch
					6'b000_100, 6'b000_101: begin
						if (RRSTaken[Instr3D[57:53]]) begin							
							valid_VJ[writeptr[31:24]]=1'b0;
							QJ[writeptr[31:24]]=RRS[Instr3D[57:53]];
						end	
						if (RRSTaken[Instr3D[52:48]]) begin							
							valid_VK[writeptr[31:24]]=1'b0;
							QK[writeptr[31:24]]=RRS[Instr3D[52:48]];
						end
					end
					//I-Type
					6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin											
						if (RRSTaken[Instr3D[57:53]]) begin							
							valid_VJ[writeptr[31:24]]=1'b0;
							QJ[writeptr[31:24]]=RRS[Instr3D[57:53]];
						end	
						RRSTaken[Instr3D[52:48]]=1'b1;
						RRS[Instr3D[52:48]]=writeptr[31:24];
					end
				endcase	

			end
	
			if(I0done) begin			
				if((!valid_VJ[0]) && (ISequence0==Seq[QJ[0]])) begin				
					RowDecoder=Instr[QJ[0]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[0]=WD0;
								valid_VJ[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[0]=WD1;
								valid_VJ[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[0]=WD2;
								valid_VJ[0]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[0]=WD0;
								valid_VJ[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[0]=WD1;
								valid_VJ[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[0]=WD2;
								valid_VJ[0]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[1]) && (ISequence0==Seq[QJ[1]])) begin				
					RowDecoder=Instr[QJ[1]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[1]=WD0;
								valid_VJ[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[1]=WD1;
								valid_VJ[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[1]=WD2;
								valid_VJ[1]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[1]=WD0;
								valid_VJ[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[1]=WD1;
								valid_VJ[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[1]=WD2;
								valid_VJ[1]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[2]) && (ISequence0==Seq[QJ[2]])) begin				
					RowDecoder=Instr[QJ[2]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[2]=WD0;
								valid_VJ[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[2]=WD1;
								valid_VJ[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[2]=WD2;
								valid_VJ[2]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[2]=WD0;
								valid_VJ[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[2]=WD1;
								valid_VJ[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[2]=WD2;
								valid_VJ[2]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[3]) && (ISequence0==Seq[QJ[3]])) begin				
					RowDecoder=Instr[QJ[3]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[3]=WD0;
								valid_VJ[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[3]=WD1;
								valid_VJ[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[3]=WD2;
								valid_VJ[3]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[3]=WD0;
								valid_VJ[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[3]=WD1;
								valid_VJ[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[3]=WD2;
								valid_VJ[3]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[4]) && (ISequence0==Seq[QJ[4]])) begin				
					RowDecoder=Instr[QJ[4]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[4]=WD0;
								valid_VJ[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[4]=WD1;
								valid_VJ[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[4]=WD2;
								valid_VJ[4]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[4]=WD0;
								valid_VJ[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[4]=WD1;
								valid_VJ[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[4]=WD2;
								valid_VJ[4]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[5]) && (ISequence0==Seq[QJ[5]])) begin				
					RowDecoder=Instr[QJ[5]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[5]=WD0;
								valid_VJ[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[5]=WD1;
								valid_VJ[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[5]=WD2;
								valid_VJ[5]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[5]=WD0;
								valid_VJ[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[5]=WD1;
								valid_VJ[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[5]=WD2;
								valid_VJ[5]=1'b1;
							end
						end
					endcase	
				end		
				if((!valid_VJ[6]) && (ISequence0==Seq[QJ[6]])) begin				
					RowDecoder=Instr[QJ[6]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[6]=WD0;
								valid_VJ[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[6]=WD1;
								valid_VJ[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[6]=WD2;
								valid_VJ[6]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[6]=WD0;
								valid_VJ[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[6]=WD1;
								valid_VJ[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[6]=WD2;
								valid_VJ[6]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[7]) && (ISequence0==Seq[QJ[7]])) begin				
					RowDecoder=Instr[QJ[7]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[7]=WD0;
								valid_VJ[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[7]=WD1;
								valid_VJ[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[7]=WD2;
								valid_VJ[7]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[7]=WD0;
								valid_VJ[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[7]=WD1;
								valid_VJ[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[7]=WD2;
								valid_VJ[7]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[8]) && (ISequence0==Seq[QJ[8]])) begin				
					RowDecoder=Instr[QJ[8]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[8]=WD0;
								valid_VJ[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[8]=WD1;
								valid_VJ[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[8]=WD2;
								valid_VJ[8]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[8]=WD0;
								valid_VJ[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[8]=WD1;
								valid_VJ[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[8]=WD2;
								valid_VJ[8]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[9]) && (ISequence0==Seq[QJ[9]])) begin				
					RowDecoder=Instr[QJ[9]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[9]=WD0;
								valid_VJ[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[9]=WD1;
								valid_VJ[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[9]=WD2;
								valid_VJ[9]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[9]=WD0;
								valid_VJ[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[9]=WD1;
								valid_VJ[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[9]=WD2;
								valid_VJ[9]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[10]) && (ISequence0==Seq[QJ[10]])) begin				
					RowDecoder=Instr[QJ[10]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[10]=WD0;
								valid_VJ[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[10]=WD1;
								valid_VJ[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[10]=WD2;
								valid_VJ[10]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[10]=WD0;
								valid_VJ[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[10]=WD1;
								valid_VJ[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[10]=WD2;
								valid_VJ[10]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[11]) && (ISequence0==Seq[QJ[11]])) begin				
					RowDecoder=Instr[QJ[11]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[11]=WD0;
								valid_VJ[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[11]=WD1;
								valid_VJ[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[11]=WD2;
								valid_VJ[11]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[11]=WD0;
								valid_VJ[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[11]=WD1;
								valid_VJ[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[11]=WD2;
								valid_VJ[11]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[12]) && (ISequence0==Seq[QJ[12]])) begin				
					RowDecoder=Instr[QJ[12]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[12]=WD0;
								valid_VJ[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[12]=WD1;
								valid_VJ[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[12]=WD2;
								valid_VJ[12]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[12]=WD0;
								valid_VJ[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[12]=WD1;
								valid_VJ[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[12]=WD2;
								valid_VJ[12]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[13]) && (ISequence0==Seq[QJ[13]])) begin				
					RowDecoder=Instr[QJ[13]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[13]=WD0;
								valid_VJ[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[13]=WD1;
								valid_VJ[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[13]=WD2;
								valid_VJ[13]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[13]=WD0;
								valid_VJ[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[13]=WD1;
								valid_VJ[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[13]=WD2;
								valid_VJ[13]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[14]) && (ISequence0==Seq[QJ[14]])) begin				
					RowDecoder=Instr[QJ[14]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[14]=WD0;
								valid_VJ[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[14]=WD1;
								valid_VJ[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[14]=WD2;
								valid_VJ[14]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[14]=WD0;
								valid_VJ[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[14]=WD1;
								valid_VJ[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[14]=WD2;
								valid_VJ[14]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[15]) && (ISequence0==Seq[QJ[15]])) begin				
					RowDecoder=Instr[QJ[15]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[15]=WD0;
								valid_VJ[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[15]=WD1;
								valid_VJ[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[15]=WD2;
								valid_VJ[15]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[15]=WD0;
								valid_VJ[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[15]=WD1;
								valid_VJ[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[15]=WD2;
								valid_VJ[15]=1'b1;
							end
						end
					endcase	
				end														
				if((!valid_VJ[16]) && (ISequence0==Seq[QJ[16]])) begin				
					RowDecoder=Instr[QJ[16]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[16]=WD0;
								valid_VJ[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[16]=WD1;
								valid_VJ[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[16]=WD2;
								valid_VJ[16]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[16]=WD0;
								valid_VJ[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[16]=WD1;
								valid_VJ[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[16]=WD2;
								valid_VJ[16]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[17]) && (ISequence0==Seq[QJ[17]])) begin				
					RowDecoder=Instr[QJ[17]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[17]=WD0;
								valid_VJ[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[17]=WD1;
								valid_VJ[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[17]=WD2;
								valid_VJ[17]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[17]=WD0;
								valid_VJ[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[17]=WD1;
								valid_VJ[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[17]=WD2;
								valid_VJ[17]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VJ[18]) && (ISequence0==Seq[QJ[18]])) begin				
					RowDecoder=Instr[QJ[18]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[18]=WD0;
								valid_VJ[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[18]=WD1;
								valid_VJ[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[18]=WD2;
								valid_VJ[18]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[18]=WD0;
								valid_VJ[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[18]=WD1;
								valid_VJ[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[18]=WD2;
								valid_VJ[18]=1'b1;
							end
						end
					endcase	
				end												
				if((!valid_VJ[19]) && (ISequence0==Seq[QJ[19]])) begin				
					RowDecoder=Instr[QJ[19]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[19]=WD0;
								valid_VJ[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[19]=WD1;
								valid_VJ[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[19]=WD2;
								valid_VJ[19]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[19]=WD0;
								valid_VJ[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[19]=WD1;
								valid_VJ[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[19]=WD2;
								valid_VJ[19]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VJ[20]) && (ISequence0==Seq[QJ[20]])) begin				
					RowDecoder=Instr[QJ[20]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[20]=WD0;
								valid_VJ[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[20]=WD1;
								valid_VJ[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[20]=WD2;
								valid_VJ[20]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[20]=WD0;
								valid_VJ[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[20]=WD1;
								valid_VJ[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[20]=WD2;
								valid_VJ[20]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[21]) && (ISequence0==Seq[QJ[21]])) begin				
					RowDecoder=Instr[QJ[21]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[21]=WD0;
								valid_VJ[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[21]=WD1;
								valid_VJ[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[21]=WD2;
								valid_VJ[21]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[21]=WD0;
								valid_VJ[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[21]=WD1;
								valid_VJ[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[21]=WD2;
								valid_VJ[21]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[22]) && (ISequence0==Seq[QJ[22]])) begin				
					RowDecoder=Instr[QJ[22]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[22]=WD0;
								valid_VJ[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[22]=WD1;
								valid_VJ[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[22]=WD2;
								valid_VJ[22]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[22]=WD0;
								valid_VJ[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[22]=WD1;
								valid_VJ[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[22]=WD2;
								valid_VJ[22]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VJ[23]) && (ISequence0==Seq[QJ[23]])) begin				
					RowDecoder=Instr[QJ[23]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[23]=WD0;
								valid_VJ[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[23]=WD1;
								valid_VJ[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[23]=WD2;
								valid_VJ[23]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[23]=WD0;
								valid_VJ[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[23]=WD1;
								valid_VJ[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[23]=WD2;
								valid_VJ[23]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[24]) && (ISequence0==Seq[QJ[24]])) begin				
					RowDecoder=Instr[QJ[24]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[24]=WD0;
								valid_VJ[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[24]=WD1;
								valid_VJ[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[24]=WD2;
								valid_VJ[24]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[24]=WD0;
								valid_VJ[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[24]=WD1;
								valid_VJ[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[24]=WD2;
								valid_VJ[24]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[25]) && (ISequence0==Seq[QJ[25]])) begin				
					RowDecoder=Instr[QJ[25]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[25]=WD0;
								valid_VJ[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[25]=WD1;
								valid_VJ[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[25]=WD2;
								valid_VJ[25]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[25]=WD0;
								valid_VJ[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[25]=WD1;
								valid_VJ[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[25]=WD2;
								valid_VJ[25]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VJ[26]) && (ISequence0==Seq[QJ[26]])) begin				
					RowDecoder=Instr[QJ[26]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[26]=WD0;
								valid_VJ[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[26]=WD1;
								valid_VJ[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[26]=WD2;
								valid_VJ[26]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[26]=WD0;
								valid_VJ[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[26]=WD1;
								valid_VJ[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[26]=WD2;
								valid_VJ[26]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[27]) && (ISequence0==Seq[QJ[27]])) begin				
					RowDecoder=Instr[QJ[27]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[27]=WD0;
								valid_VJ[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[27]=WD1;
								valid_VJ[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[27]=WD2;
								valid_VJ[27]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[27]=WD0;
								valid_VJ[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[27]=WD1;
								valid_VJ[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[27]=WD2;
								valid_VJ[27]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[28]) && (ISequence0==Seq[QJ[28]])) begin				
					RowDecoder=Instr[QJ[28]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[28]=WD0;
								valid_VJ[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[28]=WD1;
								valid_VJ[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[28]=WD2;
								valid_VJ[28]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[28]=WD0;
								valid_VJ[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[28]=WD1;
								valid_VJ[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[28]=WD2;
								valid_VJ[28]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[29]) && (ISequence0==Seq[QJ[29]])) begin				
					RowDecoder=Instr[QJ[29]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[29]=WD0;
								valid_VJ[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[29]=WD1;
								valid_VJ[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[29]=WD2;
								valid_VJ[29]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[29]=WD0;
								valid_VJ[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[29]=WD1;
								valid_VJ[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[29]=WD2;
								valid_VJ[29]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[30]) && (ISequence0==Seq[QJ[30]])) begin				
					RowDecoder=Instr[QJ[30]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[30]=WD0;
								valid_VJ[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[30]=WD1;
								valid_VJ[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[30]=WD2;
								valid_VJ[30]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[30]=WD0;
								valid_VJ[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[30]=WD1;
								valid_VJ[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[30]=WD2;
								valid_VJ[30]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[31]) && (ISequence0==Seq[QJ[31]])) begin				
					RowDecoder=Instr[QJ[31]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[31]=WD0;
								valid_VJ[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[31]=WD1;
								valid_VJ[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[31]=WD2;
								valid_VJ[31]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[31]=WD0;
								valid_VJ[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[31]=WD1;
								valid_VJ[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[31]=WD2;
								valid_VJ[31]=1'b1;
							end
						end
					endcase	
				end					
				if((!valid_VK[0]) && (ISequence0==Seq[QK[0]])) begin				
					RowDecoder=Instr[QK[0]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[0]=WD0;
								valid_VK[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[0]=WD1;
								valid_VK[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[0]=WD2;
								valid_VK[0]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[0]=WD0;
								valid_VK[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[0]=WD1;
								valid_VK[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[0]=WD2;
								valid_VK[0]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[1]) && (ISequence0==Seq[QK[1]])) begin				
					RowDecoder=Instr[QK[1]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[1]=WD0;
								valid_VK[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[1]=WD1;
								valid_VK[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[1]=WD2;
								valid_VK[1]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[1]=WD0;
								valid_VK[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[1]=WD1;
								valid_VK[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[1]=WD2;
								valid_VK[1]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[2]) && (ISequence0==Seq[QK[2]])) begin				
					RowDecoder=Instr[QK[2]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[2]=WD0;
								valid_VK[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[2]=WD1;
								valid_VK[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[2]=WD2;
								valid_VK[2]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[2]=WD0;
								valid_VK[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[2]=WD1;
								valid_VK[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[2]=WD2;
								valid_VK[2]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[3]) && (ISequence0==Seq[QK[3]])) begin				
					RowDecoder=Instr[QK[3]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[3]=WD0;
								valid_VK[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[3]=WD1;
								valid_VK[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[3]=WD2;
								valid_VK[3]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[3]=WD0;
								valid_VK[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[3]=WD1;
								valid_VK[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[3]=WD2;
								valid_VK[3]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[4]) && (ISequence0==Seq[QK[4]])) begin				
					RowDecoder=Instr[QK[4]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[4]=WD0;
								valid_VK[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[4]=WD1;
								valid_VK[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[4]=WD2;
								valid_VK[4]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[4]=WD0;
								valid_VK[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[4]=WD1;
								valid_VK[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[4]=WD2;
								valid_VK[4]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[5]) && (ISequence0==Seq[QK[5]])) begin				
					RowDecoder=Instr[QK[5]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[5]=WD0;
								valid_VK[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[5]=WD1;
								valid_VK[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[5]=WD2;
								valid_VK[5]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[5]=WD0;
								valid_VK[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[5]=WD1;
								valid_VK[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[5]=WD2;
								valid_VK[5]=1'b1;
							end
						end
					endcase	
				end		
				if((!valid_VK[6]) && (ISequence0==Seq[QK[6]])) begin				
					RowDecoder=Instr[QK[6]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[6]=WD0;
								valid_VK[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[6]=WD1;
								valid_VK[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[6]=WD2;
								valid_VK[6]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[6]=WD0;
								valid_VK[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[6]=WD1;
								valid_VK[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[6]=WD2;
								valid_VK[6]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[7]) && (ISequence0==Seq[QK[7]])) begin				
					RowDecoder=Instr[QK[7]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[7]=WD0;
								valid_VK[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[7]=WD1;
								valid_VK[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[7]=WD2;
								valid_VK[7]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[7]=WD0;
								valid_VK[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[7]=WD1;
								valid_VK[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[7]=WD2;
								valid_VK[7]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[8]) && (ISequence0==Seq[QK[8]])) begin				
					RowDecoder=Instr[QK[8]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[8]=WD0;
								valid_VK[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[8]=WD1;
								valid_VK[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[8]=WD2;
								valid_VK[8]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[8]=WD0;
								valid_VK[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[8]=WD1;
								valid_VK[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[8]=WD2;
								valid_VK[8]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[9]) && (ISequence0==Seq[QK[9]])) begin				
					RowDecoder=Instr[QK[9]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[9]=WD0;
								valid_VK[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[9]=WD1;
								valid_VK[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[9]=WD2;
								valid_VK[9]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[9]=WD0;
								valid_VK[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[9]=WD1;
								valid_VK[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[9]=WD2;
								valid_VK[9]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[10]) && (ISequence0==Seq[QK[10]])) begin				
					RowDecoder=Instr[QK[10]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[10]=WD0;
								valid_VK[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[10]=WD1;
								valid_VK[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[10]=WD2;
								valid_VK[10]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[10]=WD0;
								valid_VK[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[10]=WD1;
								valid_VK[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[10]=WD2;
								valid_VK[10]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[11]) && (ISequence0==Seq[QK[11]])) begin				
					RowDecoder=Instr[QK[11]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[11]=WD0;
								valid_VK[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[11]=WD1;
								valid_VK[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[11]=WD2;
								valid_VK[11]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[11]=WD0;
								valid_VK[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[11]=WD1;
								valid_VK[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[11]=WD2;
								valid_VK[11]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[12]) && (ISequence0==Seq[QK[12]])) begin				
					RowDecoder=Instr[QK[12]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[12]=WD0;
								valid_VK[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[12]=WD1;
								valid_VK[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[12]=WD2;
								valid_VK[12]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[12]=WD0;
								valid_VK[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[12]=WD1;
								valid_VK[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[12]=WD2;
								valid_VK[12]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[13]) && (ISequence0==Seq[QK[13]])) begin				
					RowDecoder=Instr[QK[13]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[13]=WD0;
								valid_VK[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[13]=WD1;
								valid_VK[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[13]=WD2;
								valid_VK[13]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[13]=WD0;
								valid_VK[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[13]=WD1;
								valid_VK[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[13]=WD2;
								valid_VK[13]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[14]) && (ISequence0==Seq[QK[14]])) begin				
					RowDecoder=Instr[QK[14]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[14]=WD0;
								valid_VK[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[14]=WD1;
								valid_VK[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[14]=WD2;
								valid_VK[14]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[14]=WD0;
								valid_VK[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[14]=WD1;
								valid_VK[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[14]=WD2;
								valid_VK[14]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[15]) && (ISequence0==Seq[QK[15]])) begin				
					RowDecoder=Instr[QK[15]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[15]=WD0;
								valid_VK[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[15]=WD1;
								valid_VK[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[15]=WD2;
								valid_VK[15]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[15]=WD0;
								valid_VK[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[15]=WD1;
								valid_VK[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[15]=WD2;
								valid_VK[15]=1'b1;
							end
						end
					endcase	
				end																
				if((!valid_VK[16]) && (ISequence0==Seq[QK[16]])) begin				
					RowDecoder=Instr[QK[16]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[16]=WD0;
								valid_VK[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[16]=WD1;
								valid_VK[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[16]=WD2;
								valid_VK[16]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[16]=WD0;
								valid_VK[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[16]=WD1;
								valid_VK[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[16]=WD2;
								valid_VK[16]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[17]) && (ISequence0==Seq[QK[17]])) begin				
					RowDecoder=Instr[QK[17]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[17]=WD0;
								valid_VK[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[17]=WD1;
								valid_VK[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[17]=WD2;
								valid_VK[17]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[17]=WD0;
								valid_VK[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[17]=WD1;
								valid_VK[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[17]=WD2;
								valid_VK[17]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VK[18]) && (ISequence0==Seq[QK[18]])) begin				
					RowDecoder=Instr[QK[18]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[18]=WD0;
								valid_VK[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[18]=WD1;
								valid_VK[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[18]=WD2;
								valid_VK[18]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[18]=WD0;
								valid_VK[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[18]=WD1;
								valid_VK[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[18]=WD2;
								valid_VK[18]=1'b1;
							end
						end
					endcase	
				end												
				if((!valid_VK[19]) && (ISequence0==Seq[QK[19]])) begin				
					RowDecoder=Instr[QK[19]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[19]=WD0;
								valid_VK[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[19]=WD1;
								valid_VK[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[19]=WD2;
								valid_VK[19]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[19]=WD0;
								valid_VK[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[19]=WD1;
								valid_VK[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[19]=WD2;
								valid_VK[19]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VK[20]) && (ISequence0==Seq[QK[20]])) begin				
					RowDecoder=Instr[QK[20]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[20]=WD0;
								valid_VK[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[20]=WD1;
								valid_VK[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[20]=WD2;
								valid_VK[20]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[20]=WD0;
								valid_VK[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[20]=WD1;
								valid_VK[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[20]=WD2;
								valid_VK[20]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[21]) && (ISequence0==Seq[QK[21]])) begin				
					RowDecoder=Instr[QK[21]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[21]=WD0;
								valid_VK[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[21]=WD1;
								valid_VK[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[21]=WD2;
								valid_VK[21]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[21]=WD0;
								valid_VK[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[21]=WD1;
								valid_VK[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[21]=WD2;
								valid_VK[21]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[22]) && (ISequence0==Seq[QK[22]])) begin				
					RowDecoder=Instr[QK[22]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[22]=WD0;
								valid_VK[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[22]=WD1;
								valid_VK[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[22]=WD2;
								valid_VK[22]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[22]=WD0;
								valid_VK[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[22]=WD1;
								valid_VK[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[22]=WD2;
								valid_VK[22]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VK[23]) && (ISequence0==Seq[QK[23]])) begin				
					RowDecoder=Instr[QK[23]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[23]=WD0;
								valid_VK[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[23]=WD1;
								valid_VK[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[23]=WD2;
								valid_VK[23]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[23]=WD0;
								valid_VK[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[23]=WD1;
								valid_VK[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[23]=WD2;
								valid_VK[23]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[24]) && (ISequence0==Seq[QK[24]])) begin				
					RowDecoder=Instr[QK[24]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[24]=WD0;
								valid_VK[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[24]=WD1;
								valid_VK[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[24]=WD2;
								valid_VK[24]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[24]=WD0;
								valid_VK[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[24]=WD1;
								valid_VK[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[24]=WD2;
								valid_VK[24]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[25]) && (ISequence0==Seq[QK[25]])) begin				
					RowDecoder=Instr[QK[25]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[25]=WD0;
								valid_VK[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[25]=WD1;
								valid_VK[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[25]=WD2;
								valid_VK[25]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[25]=WD0;
								valid_VK[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[25]=WD1;
								valid_VK[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[25]=WD2;
								valid_VK[25]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VK[26]) && (ISequence0==Seq[QK[26]])) begin				
					RowDecoder=Instr[QK[26]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[26]=WD0;
								valid_VK[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[26]=WD1;
								valid_VK[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[26]=WD2;
								valid_VK[26]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[26]=WD0;
								valid_VK[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[26]=WD1;
								valid_VK[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[26]=WD2;
								valid_VK[26]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[27]) && (ISequence0==Seq[QK[27]])) begin				
					RowDecoder=Instr[QK[27]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[27]=WD0;
								valid_VK[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[27]=WD1;
								valid_VK[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[27]=WD2;
								valid_VK[27]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[27]=WD0;
								valid_VK[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[27]=WD1;
								valid_VK[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[27]=WD2;
								valid_VK[27]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[28]) && (ISequence0==Seq[QK[28]])) begin				
					RowDecoder=Instr[QK[28]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[28]=WD0;
								valid_VK[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[28]=WD1;
								valid_VK[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[28]=WD2;
								valid_VK[28]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[28]=WD0;
								valid_VK[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[28]=WD1;
								valid_VK[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[28]=WD2;
								valid_VK[28]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[29]) && (ISequence0==Seq[QK[29]])) begin				
					RowDecoder=Instr[QK[29]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[29]=WD0;
								valid_VK[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[29]=WD1;
								valid_VK[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[29]=WD2;
								valid_VK[29]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[29]=WD0;
								valid_VK[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[29]=WD1;
								valid_VK[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[29]=WD2;
								valid_VK[29]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[30]) && (ISequence0==Seq[QK[30]])) begin				
					RowDecoder=Instr[QK[30]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[30]=WD0;
								valid_VK[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[30]=WD1;
								valid_VK[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[30]=WD2;
								valid_VK[30]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[30]=WD0;
								valid_VK[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[30]=WD1;
								valid_VK[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[30]=WD2;
								valid_VK[30]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[31]) && (ISequence0==Seq[QK[31]])) begin				
					RowDecoder=Instr[QK[31]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[31]=WD0;
								valid_VK[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[31]=WD1;
								valid_VK[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[31]=WD2;
								valid_VK[31]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[31]=WD0;
								valid_VK[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[31]=WD1;
								valid_VK[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[31]=WD2;
								valid_VK[31]=1'b1;
							end
						end
					endcase	
				end		
							
			end	
			if(I1done) begin
				if((!valid_VJ[0]) && (ISequence1==Seq[QJ[0]])) begin				
					RowDecoder=Instr[QJ[0]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[0]=WD0;
								valid_VJ[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[0]=WD1;
								valid_VJ[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[0]=WD2;
								valid_VJ[0]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[0]=WD0;
								valid_VJ[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[0]=WD1;
								valid_VJ[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[0]=WD2;
								valid_VJ[0]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[1]) && (ISequence1==Seq[QJ[1]])) begin				
					RowDecoder=Instr[QJ[1]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[1]=WD0;
								valid_VJ[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[1]=WD1;
								valid_VJ[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[1]=WD2;
								valid_VJ[1]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[1]=WD0;
								valid_VJ[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[1]=WD1;
								valid_VJ[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[1]=WD2;
								valid_VJ[1]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[2]) && (ISequence1==Seq[QJ[2]])) begin				
					RowDecoder=Instr[QJ[2]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[2]=WD0;
								valid_VJ[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[2]=WD1;
								valid_VJ[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[2]=WD2;
								valid_VJ[2]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[2]=WD0;
								valid_VJ[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[2]=WD1;
								valid_VJ[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[2]=WD2;
								valid_VJ[2]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[3]) && (ISequence1==Seq[QJ[3]])) begin				
					RowDecoder=Instr[QJ[3]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[3]=WD0;
								valid_VJ[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[3]=WD1;
								valid_VJ[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[3]=WD2;
								valid_VJ[3]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[3]=WD0;
								valid_VJ[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[3]=WD1;
								valid_VJ[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[3]=WD2;
								valid_VJ[3]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[4]) && (ISequence1==Seq[QJ[4]])) begin				
					RowDecoder=Instr[QJ[4]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[4]=WD0;
								valid_VJ[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[4]=WD1;
								valid_VJ[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[4]=WD2;
								valid_VJ[4]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[4]=WD0;
								valid_VJ[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[4]=WD1;
								valid_VJ[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[4]=WD2;
								valid_VJ[4]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[5]) && (ISequence1==Seq[QJ[5]])) begin				
					RowDecoder=Instr[QJ[5]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[5]=WD0;
								valid_VJ[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[5]=WD1;
								valid_VJ[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[5]=WD2;
								valid_VJ[5]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[5]=WD0;
								valid_VJ[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[5]=WD1;
								valid_VJ[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[5]=WD2;
								valid_VJ[5]=1'b1;
							end
						end
					endcase	
				end		
				if((!valid_VJ[6]) && (ISequence1==Seq[QJ[6]])) begin				
					RowDecoder=Instr[QJ[6]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[6]=WD0;
								valid_VJ[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[6]=WD1;
								valid_VJ[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[6]=WD2;
								valid_VJ[6]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[6]=WD0;
								valid_VJ[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[6]=WD1;
								valid_VJ[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[6]=WD2;
								valid_VJ[6]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[7]) && (ISequence1==Seq[QJ[7]])) begin				
					RowDecoder=Instr[QJ[7]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[7]=WD0;
								valid_VJ[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[7]=WD1;
								valid_VJ[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[7]=WD2;
								valid_VJ[7]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[7]=WD0;
								valid_VJ[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[7]=WD1;
								valid_VJ[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[7]=WD2;
								valid_VJ[7]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[8]) && (ISequence1==Seq[QJ[8]])) begin				
					RowDecoder=Instr[QJ[8]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[8]=WD0;
								valid_VJ[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[8]=WD1;
								valid_VJ[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[8]=WD2;
								valid_VJ[8]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[8]=WD0;
								valid_VJ[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[8]=WD1;
								valid_VJ[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[8]=WD2;
								valid_VJ[8]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[9]) && (ISequence1==Seq[QJ[9]])) begin				
					RowDecoder=Instr[QJ[9]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[9]=WD0;
								valid_VJ[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[9]=WD1;
								valid_VJ[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[9]=WD2;
								valid_VJ[9]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[9]=WD0;
								valid_VJ[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[9]=WD1;
								valid_VJ[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[9]=WD2;
								valid_VJ[9]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[10]) && (ISequence1==Seq[QJ[10]])) begin				
					RowDecoder=Instr[QJ[10]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[10]=WD0;
								valid_VJ[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[10]=WD1;
								valid_VJ[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[10]=WD2;
								valid_VJ[10]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[10]=WD0;
								valid_VJ[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[10]=WD1;
								valid_VJ[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[10]=WD2;
								valid_VJ[10]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[11]) && (ISequence1==Seq[QJ[11]])) begin				
					RowDecoder=Instr[QJ[11]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[11]=WD0;
								valid_VJ[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[11]=WD1;
								valid_VJ[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[11]=WD2;
								valid_VJ[11]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[11]=WD0;
								valid_VJ[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[11]=WD1;
								valid_VJ[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[11]=WD2;
								valid_VJ[11]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[12]) && (ISequence1==Seq[QJ[12]])) begin				
					RowDecoder=Instr[QJ[12]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[12]=WD0;
								valid_VJ[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[12]=WD1;
								valid_VJ[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[12]=WD2;
								valid_VJ[12]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[12]=WD0;
								valid_VJ[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[12]=WD1;
								valid_VJ[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[12]=WD2;
								valid_VJ[12]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[13]) && (ISequence1==Seq[QJ[13]])) begin				
					RowDecoder=Instr[QJ[13]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[13]=WD0;
								valid_VJ[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[13]=WD1;
								valid_VJ[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[13]=WD2;
								valid_VJ[13]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[13]=WD0;
								valid_VJ[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[13]=WD1;
								valid_VJ[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[13]=WD2;
								valid_VJ[13]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[14]) && (ISequence1==Seq[QJ[14]])) begin				
					RowDecoder=Instr[QJ[14]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[14]=WD0;
								valid_VJ[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[14]=WD1;
								valid_VJ[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[14]=WD2;
								valid_VJ[14]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[14]=WD0;
								valid_VJ[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[14]=WD1;
								valid_VJ[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[14]=WD2;
								valid_VJ[14]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[15]) && (ISequence1==Seq[QJ[15]])) begin				
					RowDecoder=Instr[QJ[15]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[15]=WD0;
								valid_VJ[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[15]=WD1;
								valid_VJ[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[15]=WD2;
								valid_VJ[15]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[15]=WD0;
								valid_VJ[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[15]=WD1;
								valid_VJ[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[15]=WD2;
								valid_VJ[15]=1'b1;
							end
						end
					endcase	
				end																	
				if((!valid_VJ[16]) && (ISequence1==Seq[QJ[16]])) begin				
					RowDecoder=Instr[QJ[16]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[16]=WD0;
								valid_VJ[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[16]=WD1;
								valid_VJ[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[16]=WD2;
								valid_VJ[16]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[16]=WD0;
								valid_VJ[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[16]=WD1;
								valid_VJ[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[16]=WD2;
								valid_VJ[16]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[17]) && (ISequence1==Seq[QJ[17]])) begin				
					RowDecoder=Instr[QJ[17]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[17]=WD0;
								valid_VJ[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[17]=WD1;
								valid_VJ[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[17]=WD2;
								valid_VJ[17]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[17]=WD0;
								valid_VJ[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[17]=WD1;
								valid_VJ[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[17]=WD2;
								valid_VJ[17]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VJ[18]) && (ISequence1==Seq[QJ[18]])) begin				
					RowDecoder=Instr[QJ[18]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[18]=WD0;
								valid_VJ[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[18]=WD1;
								valid_VJ[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[18]=WD2;
								valid_VJ[18]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[18]=WD0;
								valid_VJ[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[18]=WD1;
								valid_VJ[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[18]=WD2;
								valid_VJ[18]=1'b1;
							end
						end
					endcase	
				end												
				if((!valid_VJ[19]) && (ISequence1==Seq[QJ[19]])) begin				
					RowDecoder=Instr[QJ[19]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[19]=WD0;
								valid_VJ[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[19]=WD1;
								valid_VJ[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[19]=WD2;
								valid_VJ[19]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[19]=WD0;
								valid_VJ[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[19]=WD1;
								valid_VJ[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[19]=WD2;
								valid_VJ[19]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VJ[20]) && (ISequence1==Seq[QJ[20]])) begin				
					RowDecoder=Instr[QJ[20]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[20]=WD0;
								valid_VJ[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[20]=WD1;
								valid_VJ[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[20]=WD2;
								valid_VJ[20]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[20]=WD0;
								valid_VJ[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[20]=WD1;
								valid_VJ[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[20]=WD2;
								valid_VJ[20]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[21]) && (ISequence1==Seq[QJ[21]])) begin				
					RowDecoder=Instr[QJ[21]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[21]=WD0;
								valid_VJ[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[21]=WD1;
								valid_VJ[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[21]=WD2;
								valid_VJ[21]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[21]=WD0;
								valid_VJ[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[21]=WD1;
								valid_VJ[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[21]=WD2;
								valid_VJ[21]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[22]) && (ISequence1==Seq[QJ[22]])) begin				
					RowDecoder=Instr[QJ[22]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[22]=WD0;
								valid_VJ[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[22]=WD1;
								valid_VJ[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[22]=WD2;
								valid_VJ[22]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[22]=WD0;
								valid_VJ[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[22]=WD1;
								valid_VJ[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[22]=WD2;
								valid_VJ[22]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VJ[23]) && (ISequence1==Seq[QJ[23]])) begin				
					RowDecoder=Instr[QJ[23]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[23]=WD0;
								valid_VJ[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[23]=WD1;
								valid_VJ[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[23]=WD2;
								valid_VJ[23]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[23]=WD0;
								valid_VJ[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[23]=WD1;
								valid_VJ[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[23]=WD2;
								valid_VJ[23]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[24]) && (ISequence1==Seq[QJ[24]])) begin				
					RowDecoder=Instr[QJ[24]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[24]=WD0;
								valid_VJ[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[24]=WD1;
								valid_VJ[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[24]=WD2;
								valid_VJ[24]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[24]=WD0;
								valid_VJ[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[24]=WD1;
								valid_VJ[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[24]=WD2;
								valid_VJ[24]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[25]) && (ISequence1==Seq[QJ[25]])) begin				
					RowDecoder=Instr[QJ[25]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[25]=WD0;
								valid_VJ[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[25]=WD1;
								valid_VJ[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[25]=WD2;
								valid_VJ[25]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[25]=WD0;
								valid_VJ[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[25]=WD1;
								valid_VJ[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[25]=WD2;
								valid_VJ[25]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VJ[26]) && (ISequence1==Seq[QJ[26]])) begin				
					RowDecoder=Instr[QJ[26]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[26]=WD0;
								valid_VJ[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[26]=WD1;
								valid_VJ[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[26]=WD2;
								valid_VJ[26]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[26]=WD0;
								valid_VJ[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[26]=WD1;
								valid_VJ[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[26]=WD2;
								valid_VJ[26]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[27]) && (ISequence1==Seq[QJ[27]])) begin				
					RowDecoder=Instr[QJ[27]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[27]=WD0;
								valid_VJ[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[27]=WD1;
								valid_VJ[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[27]=WD2;
								valid_VJ[27]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[27]=WD0;
								valid_VJ[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[27]=WD1;
								valid_VJ[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[27]=WD2;
								valid_VJ[27]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[28]) && (ISequence1==Seq[QJ[28]])) begin				
					RowDecoder=Instr[QJ[28]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[28]=WD0;
								valid_VJ[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[28]=WD1;
								valid_VJ[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[28]=WD2;
								valid_VJ[28]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[28]=WD0;
								valid_VJ[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[28]=WD1;
								valid_VJ[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[28]=WD2;
								valid_VJ[28]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[29]) && (ISequence1==Seq[QJ[29]])) begin				
					RowDecoder=Instr[QJ[29]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[29]=WD0;
								valid_VJ[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[29]=WD1;
								valid_VJ[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[29]=WD2;
								valid_VJ[29]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[29]=WD0;
								valid_VJ[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[29]=WD1;
								valid_VJ[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[29]=WD2;
								valid_VJ[29]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[30]) && (ISequence1==Seq[QJ[30]])) begin				
					RowDecoder=Instr[QJ[30]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[30]=WD0;
								valid_VJ[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[30]=WD1;
								valid_VJ[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[30]=WD2;
								valid_VJ[30]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[30]=WD0;
								valid_VJ[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[30]=WD1;
								valid_VJ[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[30]=WD2;
								valid_VJ[30]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[31]) && (ISequence1==Seq[QJ[31]])) begin				
					RowDecoder=Instr[QJ[31]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[31]=WD0;
								valid_VJ[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[31]=WD1;
								valid_VJ[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[31]=WD2;
								valid_VJ[31]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[31]=WD0;
								valid_VJ[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[31]=WD1;
								valid_VJ[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[31]=WD2;
								valid_VJ[31]=1'b1;
							end
						end
					endcase	
				end	
				if((!valid_VK[0]) && (ISequence1==Seq[QK[0]])) begin				
					RowDecoder=Instr[QK[0]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[0]=WD0;
								valid_VK[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[0]=WD1;
								valid_VK[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[0]=WD2;
								valid_VK[0]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[0]=WD0;
								valid_VK[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[0]=WD1;
								valid_VK[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[0]=WD2;
								valid_VK[0]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[1]) && (ISequence1==Seq[QK[1]])) begin				
					RowDecoder=Instr[QK[1]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[1]=WD0;
								valid_VK[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[1]=WD1;
								valid_VK[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[1]=WD2;
								valid_VK[1]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[1]=WD0;
								valid_VK[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[1]=WD1;
								valid_VK[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[1]=WD2;
								valid_VK[1]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[2]) && (ISequence1==Seq[QK[2]])) begin				
					RowDecoder=Instr[QK[2]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[2]=WD0;
								valid_VK[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[2]=WD1;
								valid_VK[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[2]=WD2;
								valid_VK[2]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[2]=WD0;
								valid_VK[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[2]=WD1;
								valid_VK[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[2]=WD2;
								valid_VK[2]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[3]) && (ISequence1==Seq[QK[3]])) begin				
					RowDecoder=Instr[QK[3]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[3]=WD0;
								valid_VK[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[3]=WD1;
								valid_VK[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[3]=WD2;
								valid_VK[3]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[3]=WD0;
								valid_VK[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[3]=WD1;
								valid_VK[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[3]=WD2;
								valid_VK[3]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[4]) && (ISequence1==Seq[QK[4]])) begin				
					RowDecoder=Instr[QK[4]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[4]=WD0;
								valid_VK[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[4]=WD1;
								valid_VK[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[4]=WD2;
								valid_VK[4]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[4]=WD0;
								valid_VK[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[4]=WD1;
								valid_VK[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[4]=WD2;
								valid_VK[4]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[5]) && (ISequence1==Seq[QK[5]])) begin				
					RowDecoder=Instr[QK[5]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[5]=WD0;
								valid_VK[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[5]=WD1;
								valid_VK[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[5]=WD2;
								valid_VK[5]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[5]=WD0;
								valid_VK[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[5]=WD1;
								valid_VK[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[5]=WD2;
								valid_VK[5]=1'b1;
							end
						end
					endcase	
				end		
				if((!valid_VK[6]) && (ISequence1==Seq[QK[6]])) begin				
					RowDecoder=Instr[QK[6]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[6]=WD0;
								valid_VK[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[6]=WD1;
								valid_VK[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[6]=WD2;
								valid_VK[6]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[6]=WD0;
								valid_VK[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[6]=WD1;
								valid_VK[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[6]=WD2;
								valid_VK[6]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[7]) && (ISequence1==Seq[QK[7]])) begin				
					RowDecoder=Instr[QK[7]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[7]=WD0;
								valid_VK[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[7]=WD1;
								valid_VK[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[7]=WD2;
								valid_VK[7]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[7]=WD0;
								valid_VK[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[7]=WD1;
								valid_VK[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[7]=WD2;
								valid_VK[7]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[8]) && (ISequence1==Seq[QK[8]])) begin				
					RowDecoder=Instr[QK[8]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[8]=WD0;
								valid_VK[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[8]=WD1;
								valid_VK[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[8]=WD2;
								valid_VK[8]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[8]=WD0;
								valid_VK[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[8]=WD1;
								valid_VK[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[8]=WD2;
								valid_VK[8]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[9]) && (ISequence1==Seq[QK[9]])) begin				
					RowDecoder=Instr[QK[9]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[9]=WD0;
								valid_VK[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[9]=WD1;
								valid_VK[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[9]=WD2;
								valid_VK[9]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[9]=WD0;
								valid_VK[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[9]=WD1;
								valid_VK[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[9]=WD2;
								valid_VK[9]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[10]) && (ISequence1==Seq[QK[10]])) begin				
					RowDecoder=Instr[QK[10]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[10]=WD0;
								valid_VK[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[10]=WD1;
								valid_VK[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[10]=WD2;
								valid_VK[10]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[10]=WD0;
								valid_VK[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[10]=WD1;
								valid_VK[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[10]=WD2;
								valid_VK[10]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[11]) && (ISequence1==Seq[QK[11]])) begin				
					RowDecoder=Instr[QK[11]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[11]=WD0;
								valid_VK[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[11]=WD1;
								valid_VK[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[11]=WD2;
								valid_VK[11]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[11]=WD0;
								valid_VK[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[11]=WD1;
								valid_VK[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[11]=WD2;
								valid_VK[11]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[12]) && (ISequence1==Seq[QK[12]])) begin				
					RowDecoder=Instr[QK[12]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[12]=WD0;
								valid_VK[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[12]=WD1;
								valid_VK[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[12]=WD2;
								valid_VK[12]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[12]=WD0;
								valid_VK[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[12]=WD1;
								valid_VK[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[12]=WD2;
								valid_VK[12]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[13]) && (ISequence1==Seq[QK[13]])) begin				
					RowDecoder=Instr[QK[13]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[13]=WD0;
								valid_VK[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[13]=WD1;
								valid_VK[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[13]=WD2;
								valid_VK[13]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[13]=WD0;
								valid_VK[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[13]=WD1;
								valid_VK[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[13]=WD2;
								valid_VK[13]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[14]) && (ISequence1==Seq[QK[14]])) begin				
					RowDecoder=Instr[QK[14]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[14]=WD0;
								valid_VK[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[14]=WD1;
								valid_VK[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[14]=WD2;
								valid_VK[14]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[14]=WD0;
								valid_VK[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[14]=WD1;
								valid_VK[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[14]=WD2;
								valid_VK[14]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[15]) && (ISequence1==Seq[QK[15]])) begin				
					RowDecoder=Instr[QK[15]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[15]=WD0;
								valid_VK[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[15]=WD1;
								valid_VK[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[15]=WD2;
								valid_VK[15]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[15]=WD0;
								valid_VK[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[15]=WD1;
								valid_VK[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[15]=WD2;
								valid_VK[15]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[16]) && (ISequence1==Seq[QK[16]])) begin				
					RowDecoder=Instr[QK[16]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[16]=WD0;
								valid_VK[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[16]=WD1;
								valid_VK[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[16]=WD2;
								valid_VK[16]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[16]=WD0;
								valid_VK[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[16]=WD1;
								valid_VK[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[16]=WD2;
								valid_VK[16]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[17]) && (ISequence1==Seq[QK[17]])) begin				
					RowDecoder=Instr[QK[17]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[17]=WD0;
								valid_VK[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[17]=WD1;
								valid_VK[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[17]=WD2;
								valid_VK[17]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[17]=WD0;
								valid_VK[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[17]=WD1;
								valid_VK[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[17]=WD2;
								valid_VK[17]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VK[18]) && (ISequence1==Seq[QK[18]])) begin				
					RowDecoder=Instr[QK[18]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[18]=WD0;
								valid_VK[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[18]=WD1;
								valid_VK[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[18]=WD2;
								valid_VK[18]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[18]=WD0;
								valid_VK[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[18]=WD1;
								valid_VK[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[18]=WD2;
								valid_VK[18]=1'b1;
							end
						end
					endcase	
				end												
				if((!valid_VK[19]) && (ISequence1==Seq[QK[19]])) begin				
					RowDecoder=Instr[QK[19]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[19]=WD0;
								valid_VK[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[19]=WD1;
								valid_VK[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[19]=WD2;
								valid_VK[19]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[19]=WD0;
								valid_VK[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[19]=WD1;
								valid_VK[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[19]=WD2;
								valid_VK[19]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VK[20]) && (ISequence1==Seq[QK[20]])) begin				
					RowDecoder=Instr[QK[20]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[20]=WD0;
								valid_VK[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[20]=WD1;
								valid_VK[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[20]=WD2;
								valid_VK[20]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[20]=WD0;
								valid_VK[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[20]=WD1;
								valid_VK[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[20]=WD2;
								valid_VK[20]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[21]) && (ISequence1==Seq[QK[21]])) begin				
					RowDecoder=Instr[QK[21]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[21]=WD0;
								valid_VK[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[21]=WD1;
								valid_VK[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[21]=WD2;
								valid_VK[21]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[21]=WD0;
								valid_VK[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[21]=WD1;
								valid_VK[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[21]=WD2;
								valid_VK[21]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[22]) && (ISequence1==Seq[QK[22]])) begin				
					RowDecoder=Instr[QK[22]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[22]=WD0;
								valid_VK[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[22]=WD1;
								valid_VK[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[22]=WD2;
								valid_VK[22]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[22]=WD0;
								valid_VK[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[22]=WD1;
								valid_VK[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[22]=WD2;
								valid_VK[22]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VK[23]) && (ISequence1==Seq[QK[23]])) begin				
					RowDecoder=Instr[QK[23]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[23]=WD0;
								valid_VK[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[23]=WD1;
								valid_VK[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[23]=WD2;
								valid_VK[23]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[23]=WD0;
								valid_VK[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[23]=WD1;
								valid_VK[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[23]=WD2;
								valid_VK[23]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[24]) && (ISequence1==Seq[QK[24]])) begin				
					RowDecoder=Instr[QK[24]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[24]=WD0;
								valid_VK[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[24]=WD1;
								valid_VK[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[24]=WD2;
								valid_VK[24]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[24]=WD0;
								valid_VK[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[24]=WD1;
								valid_VK[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[24]=WD2;
								valid_VK[24]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[25]) && (ISequence1==Seq[QK[25]])) begin				
					RowDecoder=Instr[QK[25]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[25]=WD0;
								valid_VK[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[25]=WD1;
								valid_VK[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[25]=WD2;
								valid_VK[25]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[25]=WD0;
								valid_VK[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[25]=WD1;
								valid_VK[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[25]=WD2;
								valid_VK[25]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VK[26]) && (ISequence1==Seq[QK[26]])) begin				
					RowDecoder=Instr[QK[26]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[26]=WD0;
								valid_VK[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[26]=WD1;
								valid_VK[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[26]=WD2;
								valid_VK[26]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[26]=WD0;
								valid_VK[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[26]=WD1;
								valid_VK[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[26]=WD2;
								valid_VK[26]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[27]) && (ISequence1==Seq[QK[27]])) begin				
					RowDecoder=Instr[QK[27]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[27]=WD0;
								valid_VK[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[27]=WD1;
								valid_VK[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[27]=WD2;
								valid_VK[27]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[27]=WD0;
								valid_VK[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[27]=WD1;
								valid_VK[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[27]=WD2;
								valid_VK[27]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[28]) && (ISequence1==Seq[QK[28]])) begin				
					RowDecoder=Instr[QK[28]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[28]=WD0;
								valid_VK[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[28]=WD1;
								valid_VK[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[28]=WD2;
								valid_VK[28]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[28]=WD0;
								valid_VK[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[28]=WD1;
								valid_VK[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[28]=WD2;
								valid_VK[28]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[29]) && (ISequence1==Seq[QK[29]])) begin				
					RowDecoder=Instr[QK[29]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[29]=WD0;
								valid_VK[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[29]=WD1;
								valid_VK[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[29]=WD2;
								valid_VK[29]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[29]=WD0;
								valid_VK[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[29]=WD1;
								valid_VK[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[29]=WD2;
								valid_VK[29]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[30]) && (ISequence1==Seq[QK[30]])) begin				
					RowDecoder=Instr[QK[30]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[30]=WD0;
								valid_VK[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[30]=WD1;
								valid_VK[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[30]=WD2;
								valid_VK[30]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[30]=WD0;
								valid_VK[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[30]=WD1;
								valid_VK[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[30]=WD2;
								valid_VK[30]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[31]) && (ISequence1==Seq[QK[31]])) begin				
					RowDecoder=Instr[QK[31]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[31]=WD0;
								valid_VK[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[31]=WD1;
								valid_VK[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[31]=WD2;
								valid_VK[31]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[31]=WD0;
								valid_VK[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[31]=WD1;
								valid_VK[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[31]=WD2;
								valid_VK[31]=1'b1;
							end
						end
					endcase	
				end		
	








			end				
			if(I2done) begin				
				if((!valid_VJ[0]) && (ISequence2==Seq[QJ[0]])) begin				
					RowDecoder=Instr[QJ[0]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[0]=WD0;
								valid_VJ[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[0]=WD1;
								valid_VJ[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[0]=WD2;
								valid_VJ[0]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[0]=WD0;
								valid_VJ[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[0]=WD1;
								valid_VJ[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[0]=WD2;
								valid_VJ[0]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[1]) && (ISequence2==Seq[QJ[1]])) begin				
					RowDecoder=Instr[QJ[1]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[1]=WD0;
								valid_VJ[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[1]=WD1;
								valid_VJ[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[1]=WD2;
								valid_VJ[1]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[1]=WD0;
								valid_VJ[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[1]=WD1;
								valid_VJ[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[1]=WD2;
								valid_VJ[1]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[2]) && (ISequence2==Seq[QJ[2]])) begin				
					RowDecoder=Instr[QJ[2]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[2]=WD0;
								valid_VJ[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[2]=WD1;
								valid_VJ[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[2]=WD2;
								valid_VJ[2]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[2]=WD0;
								valid_VJ[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[2]=WD1;
								valid_VJ[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[2]=WD2;
								valid_VJ[2]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[3]) && (ISequence2==Seq[QJ[3]])) begin				
					RowDecoder=Instr[QJ[3]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[3]=WD0;
								valid_VJ[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[3]=WD1;
								valid_VJ[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[3]=WD2;
								valid_VJ[3]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[3]=WD0;
								valid_VJ[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[3]=WD1;
								valid_VJ[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[3]=WD2;
								valid_VJ[3]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[4]) && (ISequence2==Seq[QJ[4]])) begin				
					RowDecoder=Instr[QJ[4]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[4]=WD0;
								valid_VJ[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[4]=WD1;
								valid_VJ[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[4]=WD2;
								valid_VJ[4]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[4]=WD0;
								valid_VJ[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[4]=WD1;
								valid_VJ[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[4]=WD2;
								valid_VJ[4]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[5]) && (ISequence2==Seq[QJ[5]])) begin				
					RowDecoder=Instr[QJ[5]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[5]=WD0;
								valid_VJ[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[5]=WD1;
								valid_VJ[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[5]=WD2;
								valid_VJ[5]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[5]=WD0;
								valid_VJ[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[5]=WD1;
								valid_VJ[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[5]=WD2;
								valid_VJ[5]=1'b1;
							end
						end
					endcase	
				end		
				if((!valid_VJ[6]) && (ISequence2==Seq[QJ[6]])) begin				
					RowDecoder=Instr[QJ[6]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[6]=WD0;
								valid_VJ[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[6]=WD1;
								valid_VJ[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[6]=WD2;
								valid_VJ[6]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[6]=WD0;
								valid_VJ[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[6]=WD1;
								valid_VJ[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[6]=WD2;
								valid_VJ[6]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[7]) && (ISequence2==Seq[QJ[7]])) begin				
					RowDecoder=Instr[QJ[7]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[7]=WD0;
								valid_VJ[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[7]=WD1;
								valid_VJ[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[7]=WD2;
								valid_VJ[7]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[7]=WD0;
								valid_VJ[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[7]=WD1;
								valid_VJ[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[7]=WD2;
								valid_VJ[7]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[8]) && (ISequence2==Seq[QJ[8]])) begin				
					RowDecoder=Instr[QJ[8]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[8]=WD0;
								valid_VJ[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[8]=WD1;
								valid_VJ[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[8]=WD2;
								valid_VJ[8]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[8]=WD0;
								valid_VJ[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[8]=WD1;
								valid_VJ[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[8]=WD2;
								valid_VJ[8]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[9]) && (ISequence2==Seq[QJ[9]])) begin				
					RowDecoder=Instr[QJ[9]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[9]=WD0;
								valid_VJ[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[9]=WD1;
								valid_VJ[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[9]=WD2;
								valid_VJ[9]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[9]=WD0;
								valid_VJ[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[9]=WD1;
								valid_VJ[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[9]=WD2;
								valid_VJ[9]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[10]) && (ISequence2==Seq[QJ[10]])) begin				
					RowDecoder=Instr[QJ[10]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[10]=WD0;
								valid_VJ[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[10]=WD1;
								valid_VJ[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[10]=WD2;
								valid_VJ[10]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[10]=WD0;
								valid_VJ[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[10]=WD1;
								valid_VJ[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[10]=WD2;
								valid_VJ[10]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[11]) && (ISequence2==Seq[QJ[11]])) begin				
					RowDecoder=Instr[QJ[11]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[11]=WD0;
								valid_VJ[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[11]=WD1;
								valid_VJ[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[11]=WD2;
								valid_VJ[11]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[11]=WD0;
								valid_VJ[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[11]=WD1;
								valid_VJ[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[11]=WD2;
								valid_VJ[11]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[12]) && (ISequence2==Seq[QJ[12]])) begin				
					RowDecoder=Instr[QJ[12]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[12]=WD0;
								valid_VJ[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[12]=WD1;
								valid_VJ[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[12]=WD2;
								valid_VJ[12]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[12]=WD0;
								valid_VJ[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[12]=WD1;
								valid_VJ[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[12]=WD2;
								valid_VJ[12]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[13]) && (ISequence2==Seq[QJ[13]])) begin				
					RowDecoder=Instr[QJ[13]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[13]=WD0;
								valid_VJ[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[13]=WD1;
								valid_VJ[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[13]=WD2;
								valid_VJ[13]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[13]=WD0;
								valid_VJ[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[13]=WD1;
								valid_VJ[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[13]=WD2;
								valid_VJ[13]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[14]) && (ISequence2==Seq[QJ[14]])) begin				
					RowDecoder=Instr[QJ[14]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[14]=WD0;
								valid_VJ[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[14]=WD1;
								valid_VJ[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[14]=WD2;
								valid_VJ[14]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[14]=WD0;
								valid_VJ[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[14]=WD1;
								valid_VJ[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[14]=WD2;
								valid_VJ[14]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[15]) && (ISequence2==Seq[QJ[15]])) begin				
					RowDecoder=Instr[QJ[15]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[15]=WD0;
								valid_VJ[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[15]=WD1;
								valid_VJ[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[15]=WD2;
								valid_VJ[15]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[15]=WD0;
								valid_VJ[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[15]=WD1;
								valid_VJ[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[15]=WD2;
								valid_VJ[15]=1'b1;
							end
						end
					endcase	
				end																	
				if((!valid_VJ[16]) && (ISequence2==Seq[QJ[16]])) begin				
					RowDecoder=Instr[QJ[16]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[16]=WD0;
								valid_VJ[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[16]=WD1;
								valid_VJ[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[16]=WD2;
								valid_VJ[16]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[16]=WD0;
								valid_VJ[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[16]=WD1;
								valid_VJ[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[16]=WD2;
								valid_VJ[16]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[17]) && (ISequence2==Seq[QJ[17]])) begin				
					RowDecoder=Instr[QJ[17]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[17]=WD0;
								valid_VJ[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[17]=WD1;
								valid_VJ[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[17]=WD2;
								valid_VJ[17]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[17]=WD0;
								valid_VJ[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[17]=WD1;
								valid_VJ[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[17]=WD2;
								valid_VJ[17]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VJ[18]) && (ISequence2==Seq[QJ[18]])) begin				
					RowDecoder=Instr[QJ[18]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[18]=WD0;
								valid_VJ[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[18]=WD1;
								valid_VJ[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[18]=WD2;
								valid_VJ[18]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[18]=WD0;
								valid_VJ[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[18]=WD1;
								valid_VJ[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[18]=WD2;
								valid_VJ[18]=1'b1;
							end
						end
					endcase	
				end												
				if((!valid_VJ[19]) && (ISequence2==Seq[QJ[19]])) begin				
					RowDecoder=Instr[QJ[19]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[19]=WD0;
								valid_VJ[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[19]=WD1;
								valid_VJ[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[19]=WD2;
								valid_VJ[19]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[19]=WD0;
								valid_VJ[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[19]=WD1;
								valid_VJ[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[19]=WD2;
								valid_VJ[19]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VJ[20]) && (ISequence2==Seq[QJ[20]])) begin				
					RowDecoder=Instr[QJ[20]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[20]=WD0;
								valid_VJ[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[20]=WD1;
								valid_VJ[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[20]=WD2;
								valid_VJ[20]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[20]=WD0;
								valid_VJ[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[20]=WD1;
								valid_VJ[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[20]=WD2;
								valid_VJ[20]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[21]) && (ISequence2==Seq[QJ[21]])) begin				
					RowDecoder=Instr[QJ[21]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[21]=WD0;
								valid_VJ[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[21]=WD1;
								valid_VJ[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[21]=WD2;
								valid_VJ[21]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[21]=WD0;
								valid_VJ[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[21]=WD1;
								valid_VJ[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[21]=WD2;
								valid_VJ[21]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[22]) && (ISequence2==Seq[QJ[22]])) begin				
					RowDecoder=Instr[QJ[22]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[22]=WD0;
								valid_VJ[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[22]=WD1;
								valid_VJ[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[22]=WD2;
								valid_VJ[22]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[22]=WD0;
								valid_VJ[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[22]=WD1;
								valid_VJ[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[22]=WD2;
								valid_VJ[22]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VJ[23]) && (ISequence2==Seq[QJ[23]])) begin				
					RowDecoder=Instr[QJ[23]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[23]=WD0;
								valid_VJ[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[23]=WD1;
								valid_VJ[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[23]=WD2;
								valid_VJ[23]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[23]=WD0;
								valid_VJ[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[23]=WD1;
								valid_VJ[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[23]=WD2;
								valid_VJ[23]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[24]) && (ISequence2==Seq[QJ[24]])) begin				
					RowDecoder=Instr[QJ[24]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[24]=WD0;
								valid_VJ[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[24]=WD1;
								valid_VJ[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[24]=WD2;
								valid_VJ[24]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[24]=WD0;
								valid_VJ[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[24]=WD1;
								valid_VJ[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[24]=WD2;
								valid_VJ[24]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VJ[25]) && (ISequence2==Seq[QJ[25]])) begin				
					RowDecoder=Instr[QJ[25]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[25]=WD0;
								valid_VJ[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[25]=WD1;
								valid_VJ[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[25]=WD2;
								valid_VJ[25]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[25]=WD0;
								valid_VJ[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[25]=WD1;
								valid_VJ[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[25]=WD2;
								valid_VJ[25]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VJ[26]) && (ISequence2==Seq[QJ[26]])) begin				
					RowDecoder=Instr[QJ[26]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[26]=WD0;
								valid_VJ[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[26]=WD1;
								valid_VJ[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[26]=WD2;
								valid_VJ[26]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[26]=WD0;
								valid_VJ[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[26]=WD1;
								valid_VJ[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[26]=WD2;
								valid_VJ[26]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[27]) && (ISequence2==Seq[QJ[27]])) begin				
					RowDecoder=Instr[QJ[27]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[27]=WD0;
								valid_VJ[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[27]=WD1;
								valid_VJ[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[27]=WD2;
								valid_VJ[27]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[27]=WD0;
								valid_VJ[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[27]=WD1;
								valid_VJ[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[27]=WD2;
								valid_VJ[27]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[28]) && (ISequence2==Seq[QJ[28]])) begin				
					RowDecoder=Instr[QJ[28]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[28]=WD0;
								valid_VJ[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[28]=WD1;
								valid_VJ[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[28]=WD2;
								valid_VJ[28]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[28]=WD0;
								valid_VJ[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[28]=WD1;
								valid_VJ[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[28]=WD2;
								valid_VJ[28]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[29]) && (ISequence2==Seq[QJ[29]])) begin				
					RowDecoder=Instr[QJ[29]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[29]=WD0;
								valid_VJ[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[29]=WD1;
								valid_VJ[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[29]=WD2;
								valid_VJ[29]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[29]=WD0;
								valid_VJ[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[29]=WD1;
								valid_VJ[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[29]=WD2;
								valid_VJ[29]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[30]) && (ISequence2==Seq[QJ[30]])) begin				
					RowDecoder=Instr[QJ[30]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[30]=WD0;
								valid_VJ[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[30]=WD1;
								valid_VJ[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[30]=WD2;
								valid_VJ[30]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[30]=WD0;
								valid_VJ[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[30]=WD1;
								valid_VJ[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[30]=WD2;
								valid_VJ[30]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VJ[31]) && (ISequence2==Seq[QJ[31]])) begin				
					RowDecoder=Instr[QJ[31]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VJ[31]=WD0;
								valid_VJ[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VJ[31]=WD1;
								valid_VJ[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VJ[31]=WD2;
								valid_VJ[31]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VJ[31]=WD0;
								valid_VJ[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VJ[31]=WD1;
								valid_VJ[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VJ[31]=WD2;
								valid_VJ[31]=1'b1;
							end
						end
					endcase	
				end	
				if((!valid_VK[0]) && (ISequence2==Seq[QK[0]])) begin				
					RowDecoder=Instr[QK[0]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[0]=WD0;
								valid_VK[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[0]=WD1;
								valid_VK[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[0]=WD2;
								valid_VK[0]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[0]=WD0;
								valid_VK[0]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[0]=WD1;
								valid_VK[0]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[0]=WD2;
								valid_VK[0]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[1]) && (ISequence2==Seq[QK[1]])) begin				
					RowDecoder=Instr[QK[1]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[1]=WD0;
								valid_VK[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[1]=WD1;
								valid_VK[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[1]=WD2;
								valid_VK[1]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[1]=WD0;
								valid_VK[1]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[1]=WD1;
								valid_VK[1]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[1]=WD2;
								valid_VK[1]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[2]) && (ISequence2==Seq[QK[2]])) begin				
					RowDecoder=Instr[QK[2]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[2]=WD0;
								valid_VK[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[2]=WD1;
								valid_VK[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[2]=WD2;
								valid_VK[2]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[2]=WD0;
								valid_VK[2]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[2]=WD1;
								valid_VK[2]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[2]=WD2;
								valid_VK[2]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[3]) && (ISequence2==Seq[QK[3]])) begin				
					RowDecoder=Instr[QK[3]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[3]=WD0;
								valid_VK[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[3]=WD1;
								valid_VK[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[3]=WD2;
								valid_VK[3]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[3]=WD0;
								valid_VK[3]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[3]=WD1;
								valid_VK[3]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[3]=WD2;
								valid_VK[3]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[4]) && (ISequence2==Seq[QK[4]])) begin				
					RowDecoder=Instr[QK[4]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[4]=WD0;
								valid_VK[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[4]=WD1;
								valid_VK[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[4]=WD2;
								valid_VK[4]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[4]=WD0;
								valid_VK[4]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[4]=WD1;
								valid_VK[4]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[4]=WD2;
								valid_VK[4]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[5]) && (ISequence2==Seq[QK[5]])) begin				
					RowDecoder=Instr[QK[5]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[5]=WD0;
								valid_VK[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[5]=WD1;
								valid_VK[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[5]=WD2;
								valid_VK[5]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[5]=WD0;
								valid_VK[5]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[5]=WD1;
								valid_VK[5]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[5]=WD2;
								valid_VK[5]=1'b1;
							end
						end
					endcase	
				end		
				if((!valid_VK[6]) && (ISequence2==Seq[QK[6]])) begin				
					RowDecoder=Instr[QK[6]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[6]=WD0;
								valid_VK[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[6]=WD1;
								valid_VK[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[6]=WD2;
								valid_VK[6]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[6]=WD0;
								valid_VK[6]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[6]=WD1;
								valid_VK[6]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[6]=WD2;
								valid_VK[6]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[7]) && (ISequence2==Seq[QK[7]])) begin				
					RowDecoder=Instr[QK[7]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[7]=WD0;
								valid_VK[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[7]=WD1;
								valid_VK[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[7]=WD2;
								valid_VK[7]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[7]=WD0;
								valid_VK[7]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[7]=WD1;
								valid_VK[7]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[7]=WD2;
								valid_VK[7]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[8]) && (ISequence2==Seq[QK[8]])) begin				
					RowDecoder=Instr[QK[8]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[8]=WD0;
								valid_VK[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[8]=WD1;
								valid_VK[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[8]=WD2;
								valid_VK[8]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[8]=WD0;
								valid_VK[8]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[8]=WD1;
								valid_VK[8]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[8]=WD2;
								valid_VK[8]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[9]) && (ISequence2==Seq[QK[9]])) begin				
					RowDecoder=Instr[QK[9]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[9]=WD0;
								valid_VK[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[9]=WD1;
								valid_VK[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[9]=WD2;
								valid_VK[9]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[9]=WD0;
								valid_VK[9]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[9]=WD1;
								valid_VK[9]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[9]=WD2;
								valid_VK[9]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[10]) && (ISequence2==Seq[QK[10]])) begin				
					RowDecoder=Instr[QK[10]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[10]=WD0;
								valid_VK[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[10]=WD1;
								valid_VK[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[10]=WD2;
								valid_VK[10]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[10]=WD0;
								valid_VK[10]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[10]=WD1;
								valid_VK[10]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[10]=WD2;
								valid_VK[10]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[11]) && (ISequence2==Seq[QK[11]])) begin				
					RowDecoder=Instr[QK[11]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[11]=WD0;
								valid_VK[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[11]=WD1;
								valid_VK[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[11]=WD2;
								valid_VK[11]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[11]=WD0;
								valid_VK[11]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[11]=WD1;
								valid_VK[11]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[11]=WD2;
								valid_VK[11]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[12]) && (ISequence2==Seq[QK[12]])) begin				
					RowDecoder=Instr[QK[12]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[12]=WD0;
								valid_VK[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[12]=WD1;
								valid_VK[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[12]=WD2;
								valid_VK[12]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[12]=WD0;
								valid_VK[12]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[12]=WD1;
								valid_VK[12]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[12]=WD2;
								valid_VK[12]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[13]) && (ISequence2==Seq[QK[13]])) begin				
					RowDecoder=Instr[QK[13]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[13]=WD0;
								valid_VK[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[13]=WD1;
								valid_VK[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[13]=WD2;
								valid_VK[13]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[13]=WD0;
								valid_VK[13]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[13]=WD1;
								valid_VK[13]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[13]=WD2;
								valid_VK[13]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[14]) && (ISequence2==Seq[QK[14]])) begin				
					RowDecoder=Instr[QK[14]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[14]=WD0;
								valid_VK[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[14]=WD1;
								valid_VK[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[14]=WD2;
								valid_VK[14]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[14]=WD0;
								valid_VK[14]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[14]=WD1;
								valid_VK[14]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[14]=WD2;
								valid_VK[14]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[15]) && (ISequence2==Seq[QK[15]])) begin				
					RowDecoder=Instr[QK[15]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[15]=WD0;
								valid_VK[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[15]=WD1;
								valid_VK[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[15]=WD2;
								valid_VK[15]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[15]=WD0;
								valid_VK[15]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[15]=WD1;
								valid_VK[15]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[15]=WD2;
								valid_VK[15]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[16]) && (ISequence2==Seq[QK[16]])) begin				
					RowDecoder=Instr[QK[16]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[16]=WD0;
								valid_VK[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[16]=WD1;
								valid_VK[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[16]=WD2;
								valid_VK[16]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[16]=WD0;
								valid_VK[16]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[16]=WD1;
								valid_VK[16]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[16]=WD2;
								valid_VK[16]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[17]) && (ISequence2==Seq[QK[17]])) begin				
					RowDecoder=Instr[QK[17]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[17]=WD0;
								valid_VK[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[17]=WD1;
								valid_VK[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[17]=WD2;
								valid_VK[17]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[17]=WD0;
								valid_VK[17]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[17]=WD1;
								valid_VK[17]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[17]=WD2;
								valid_VK[17]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VK[18]) && (ISequence2==Seq[QK[18]])) begin				
					RowDecoder=Instr[QK[18]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[18]=WD0;
								valid_VK[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[18]=WD1;
								valid_VK[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[18]=WD2;
								valid_VK[18]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[18]=WD0;
								valid_VK[18]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[18]=WD1;
								valid_VK[18]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[18]=WD2;
								valid_VK[18]=1'b1;
							end
						end
					endcase	
				end												
				if((!valid_VK[19]) && (ISequence2==Seq[QK[19]])) begin				
					RowDecoder=Instr[QK[19]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[19]=WD0;
								valid_VK[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[19]=WD1;
								valid_VK[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[19]=WD2;
								valid_VK[19]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[19]=WD0;
								valid_VK[19]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[19]=WD1;
								valid_VK[19]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[19]=WD2;
								valid_VK[19]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VK[20]) && (ISequence2==Seq[QK[20]])) begin				
					RowDecoder=Instr[QK[20]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[20]=WD0;
								valid_VK[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[20]=WD1;
								valid_VK[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[20]=WD2;
								valid_VK[20]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[20]=WD0;
								valid_VK[20]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[20]=WD1;
								valid_VK[20]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[20]=WD2;
								valid_VK[20]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[21]) && (ISequence2==Seq[QK[21]])) begin				
					RowDecoder=Instr[QK[21]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[21]=WD0;
								valid_VK[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[21]=WD1;
								valid_VK[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[21]=WD2;
								valid_VK[21]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[21]=WD0;
								valid_VK[21]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[21]=WD1;
								valid_VK[21]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[21]=WD2;
								valid_VK[21]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[22]) && (ISequence2==Seq[QK[22]])) begin				
					RowDecoder=Instr[QK[22]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[22]=WD0;
								valid_VK[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[22]=WD1;
								valid_VK[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[22]=WD2;
								valid_VK[22]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[22]=WD0;
								valid_VK[22]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[22]=WD1;
								valid_VK[22]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[22]=WD2;
								valid_VK[22]=1'b1;
							end
						end
					endcase	
				end								
				if((!valid_VK[23]) && (ISequence2==Seq[QK[23]])) begin				
					RowDecoder=Instr[QK[23]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[23]=WD0;
								valid_VK[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[23]=WD1;
								valid_VK[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[23]=WD2;
								valid_VK[23]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[23]=WD0;
								valid_VK[23]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[23]=WD1;
								valid_VK[23]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[23]=WD2;
								valid_VK[23]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[24]) && (ISequence2==Seq[QK[24]])) begin				
					RowDecoder=Instr[QK[24]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[24]=WD0;
								valid_VK[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[24]=WD1;
								valid_VK[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[24]=WD2;
								valid_VK[24]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[24]=WD0;
								valid_VK[24]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[24]=WD1;
								valid_VK[24]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[24]=WD2;
								valid_VK[24]=1'b1;
							end
						end
					endcase	
				end				
				if((!valid_VK[25]) && (ISequence2==Seq[QK[25]])) begin				
					RowDecoder=Instr[QK[25]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[25]=WD0;
								valid_VK[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[25]=WD1;
								valid_VK[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[25]=WD2;
								valid_VK[25]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[25]=WD0;
								valid_VK[25]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[25]=WD1;
								valid_VK[25]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[25]=WD2;
								valid_VK[25]=1'b1;
							end
						end
					endcase	
				end							
				if((!valid_VK[26]) && (ISequence2==Seq[QK[26]])) begin				
					RowDecoder=Instr[QK[26]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[26]=WD0;
								valid_VK[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[26]=WD1;
								valid_VK[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[26]=WD2;
								valid_VK[26]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[26]=WD0;
								valid_VK[26]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[26]=WD1;
								valid_VK[26]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[26]=WD2;
								valid_VK[26]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[27]) && (ISequence2==Seq[QK[27]])) begin				
					RowDecoder=Instr[QK[27]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[27]=WD0;
								valid_VK[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[27]=WD1;
								valid_VK[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[27]=WD2;
								valid_VK[27]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[27]=WD0;
								valid_VK[27]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[27]=WD1;
								valid_VK[27]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[27]=WD2;
								valid_VK[27]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[28]) && (ISequence2==Seq[QK[28]])) begin				
					RowDecoder=Instr[QK[28]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[28]=WD0;
								valid_VK[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[28]=WD1;
								valid_VK[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[28]=WD2;
								valid_VK[28]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[28]=WD0;
								valid_VK[28]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[28]=WD1;
								valid_VK[28]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[28]=WD2;
								valid_VK[28]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[29]) && (ISequence2==Seq[QK[29]])) begin				
					RowDecoder=Instr[QK[29]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[29]=WD0;
								valid_VK[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[29]=WD1;
								valid_VK[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[29]=WD2;
								valid_VK[29]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[29]=WD0;
								valid_VK[29]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[29]=WD1;
								valid_VK[29]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[29]=WD2;
								valid_VK[29]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[30]) && (ISequence2==Seq[QK[30]])) begin				
					RowDecoder=Instr[QK[30]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[30]=WD0;
								valid_VK[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[30]=WD1;
								valid_VK[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[30]=WD2;
								valid_VK[30]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[30]=WD0;
								valid_VK[30]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[30]=WD1;
								valid_VK[30]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[30]=WD2;
								valid_VK[30]=1'b1;
							end
						end
					endcase	
				end
				if((!valid_VK[31]) && (ISequence2==Seq[QK[31]])) begin				
					RowDecoder=Instr[QK[31]];					
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: begin	//R-Type
							if(write0 && WR0==RowDecoder[15:11]) begin
								VK[31]=WD0;
								valid_VK[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[15:11]) begin
								VK[31]=WD1;
								valid_VK[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[15:11]) begin
								VK[31]=WD2;
								valid_VK[31]=1'b1;
							end
						end
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: begin
							if(write0 && WR0==RowDecoder[20:16]) begin
								VK[31]=WD0;
								valid_VK[31]=1'b1;
							end
							if(write1 && WR1==RowDecoder[20:16]) begin
								VK[31]=WD1;
								valid_VK[31]=1'b1;
							end
							if(write2 && WR2==RowDecoder[20:16]) begin
								VK[31]=WD2;
								valid_VK[31]=1'b1;
							end
						end
					endcase	
				end		
			end				
			
			if(write0 && Seq[RRS[WR0]]==ISequence0)
				RRSTaken[WR0]=1'b0;
			if(write1 && Seq[RRS[WR1]]==ISequence1)
				RRSTaken[WR1]=1'b0;
			if(write2 && Seq[RRS[WR2]]==ISequence2)
				RRSTaken[WR2]=1'b0;
			
			candidatelist0 = valid_VJ & valid_VK & busy & (~active);
			
			if(candidatelist0 != 32'h00000000) begin
			
				OwnerSeq0 = 32'hFFFF;
				
				if(candidatelist0[0]) begin
					candidate0=8'h00;
					OwnerSeq0=Seq[0];
					candidateDone0=1'b1;
				end
				if((candidatelist0[1]) && (Seq[1] < OwnerSeq0)) begin
					candidate0=8'h01;
					OwnerSeq0=Seq[1];
					candidateDone0=1'b1;
				end
				if((candidatelist0[2]) && (Seq[2] < OwnerSeq0)) begin
					candidate0=8'h02;
					OwnerSeq0=Seq[2];
					candidateDone0=1'b1;
				end
				if((candidatelist0[3]) && (Seq[3] < OwnerSeq0)) begin
					candidate0=8'h03;
					OwnerSeq0=Seq[3];
					candidateDone0=1'b1;
				end
				if((candidatelist0[4]) && (Seq[4] < OwnerSeq0)) begin
					candidate0=8'h04;
					OwnerSeq0=Seq[4];
					candidateDone0=1'b1;
				end		
				if((candidatelist0[5]) && (Seq[5] < OwnerSeq0)) begin
					candidate0=8'h05;
					OwnerSeq0=Seq[5];
					candidateDone0=1'b1;
				end		
				if((candidatelist0[6]) && (Seq[6] < OwnerSeq0)) begin
					candidate0=8'h06;
					OwnerSeq0=Seq[6];
					candidateDone0=1'b1;
				end		
				if((candidatelist0[7]) && (Seq[7] < OwnerSeq0)) begin
					candidate0=8'h07;
					OwnerSeq0=Seq[7];
					candidateDone0=1'b1;
				end		
				if((candidatelist0[8]) && (Seq[8] < OwnerSeq0)) begin
					candidate0=8'h08;
					OwnerSeq0=Seq[8];
					candidateDone0=1'b1;
				end		
				if((candidatelist0[9]) && (Seq[9] < OwnerSeq0)) begin
					candidate0=8'h09;
					OwnerSeq0=Seq[9];
					candidateDone0=1'b1;
				end		
				if((candidatelist0[10]) && (Seq[10] < OwnerSeq0)) begin
					candidate0=8'h0A;
					OwnerSeq0=Seq[10];
					candidateDone0=1'b1;
				end		
				if((candidatelist0[11]) && (Seq[11] < OwnerSeq0)) begin
					candidate0=8'h0B;
					OwnerSeq0=Seq[11];
					candidateDone0=1'b1;
				end		
				if((candidatelist0[12]) && (Seq[12] < OwnerSeq0)) begin
					candidate0=8'h0C;
					OwnerSeq0=Seq[12];
					candidateDone0=1'b1;
				end
				if((candidatelist0[13]) && (Seq[13] < OwnerSeq0)) begin
					candidate0=8'h0D;
					OwnerSeq0=Seq[13];
					candidateDone0=1'b1;
				end
				if((candidatelist0[14]) && (Seq[14] < OwnerSeq0)) begin
					candidate0=8'h0E;
					OwnerSeq0=Seq[14];
					candidateDone0=1'b1;
				end
				if((candidatelist0[15]) && (Seq[15] < OwnerSeq0)) begin
					candidate0=8'h0F;
					OwnerSeq0=Seq[15];
					candidateDone0=1'b1;
				end					
				if((candidatelist0[16]) && (Seq[16] < OwnerSeq0)) begin
					candidate0=8'h10;
					OwnerSeq0=Seq[16];
					candidateDone0=1'b1;
				end	
				if((candidatelist0[17]) && (Seq[17] < OwnerSeq0)) begin
					candidate0=8'h11;
					OwnerSeq0=Seq[17];
					candidateDone0=1'b1;
				end	
				if((candidatelist0[18]) && (Seq[18] < OwnerSeq0)) begin
					candidate0=8'h12;
					OwnerSeq0=Seq[18];
					candidateDone0=1'b1;
				end	
				if((candidatelist0[19]) && (Seq[19] < OwnerSeq0)) begin
					candidate0=8'h13;
					OwnerSeq0=Seq[19];
					candidateDone0=1'b1;
				end	
				if((candidatelist0[20]) && (Seq[20] < OwnerSeq0)) begin
					candidate0=8'h14;
					OwnerSeq0=Seq[20];
					candidateDone0=1'b1;
				end					
				if((candidatelist0[21]) && (Seq[21] < OwnerSeq0)) begin
					candidate0=8'h15;
					OwnerSeq0=Seq[21];
					candidateDone0=1'b1;
				end								
				if((candidatelist0[22]) && (Seq[22] < OwnerSeq0)) begin
					candidate0=8'h16;
					OwnerSeq0=Seq[22];
					candidateDone0=1'b1;
				end											
				if((candidatelist0[23]) && (Seq[23] < OwnerSeq0)) begin
					candidate0=8'h17;
					OwnerSeq0=Seq[23];
					candidateDone0=1'b1;
				end	
				if((candidatelist0[24]) && (Seq[24] < OwnerSeq0)) begin
					candidate0=8'h18;
					OwnerSeq0=Seq[24];
					candidateDone0=1'b1;
				end								
				if((candidatelist0[25]) && (Seq[25] < OwnerSeq0)) begin
					candidate0=8'h19;
					OwnerSeq0=Seq[25];
					candidateDone0=1'b1;
				end											
				if((candidatelist0[26]) && (Seq[26] < OwnerSeq0)) begin
					candidate0=8'h1A;
					OwnerSeq0=Seq[26];
					candidateDone0=1'b1;
				end	
				if((candidatelist0[27]) && (Seq[27] < OwnerSeq0)) begin
					candidate0=8'h1B;
					OwnerSeq0=Seq[27];
					candidateDone0=1'b1;
				end	
				if((candidatelist0[28]) && (Seq[28] < OwnerSeq0)) begin
					candidate0=8'h1C;
					OwnerSeq0=Seq[28];
					candidateDone0=1'b1;
				end	
				if((candidatelist0[29]) && (Seq[29] < OwnerSeq0)) begin
					candidate0=8'h1D;
					OwnerSeq0=Seq[29];
					candidateDone0=1'b1;
				end	
				if((candidatelist0[30]) && (Seq[30] < OwnerSeq0)) begin
					candidate0=8'h1E;
					OwnerSeq0=Seq[30];
					candidateDone0=1'b1;
				end	
				if((candidatelist0[31]) && (Seq[31] < OwnerSeq0)) begin
					candidate0=8'h1F;
					OwnerSeq0=Seq[31];
					candidateDone0=1'b1;
				end	
				
			end
					
			if(candidateDone0) begin
				RowDecoder=Instr[candidate0];				
				case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b1; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b1;						
				endcase	
			end
			candidatelist1 = candidatelist0;
			candidatelist1[candidate0]=1'b0;
				
			if(candidatelist1 != 32'h00000000) begin
				
				OwnerSeq1 = 32'hFFFF;
					
				if(candidatelist1[0]) begin
					if(FU[candidate0]!=FU[0]) begin
						candidate1=8'h00;
						OwnerSeq1=Seq[0];
						candidateDone1=1'b1;
						Aux1=1'b0;				
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h00;
							OwnerSeq1=Seq[0];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end
				end
				if((candidatelist1[1])	&& (Seq[1] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[1]) begin
						candidate1=8'h01;
						OwnerSeq1=Seq[1];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h01;
							OwnerSeq1=Seq[1];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end
				end
				if((candidatelist1[2])	&& (Seq[2] < OwnerSeq1)) begin
					Aux1=1'b0;
					if(FU[candidate0]!=FU[2]) begin
						candidate1=8'h02;
						OwnerSeq1=Seq[2];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h02;
							OwnerSeq1=Seq[2];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end			
				end
				if((candidatelist1[3])	&& (Seq[3] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[3]) begin
						candidate1=8'h03;
						OwnerSeq1=Seq[3];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h03;
							OwnerSeq1=Seq[3];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[4])	&& (Seq[4] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[4]) begin
						candidate1=8'h04;
						OwnerSeq1=Seq[4];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h04;
							OwnerSeq1=Seq[4];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end				
				if((candidatelist1[5])	&& (Seq[5] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[5]) begin
						candidate1=8'h05;
						OwnerSeq1=Seq[5];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h05;
							OwnerSeq1=Seq[5];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end				
				end		
				if((candidatelist1[6])	&& (Seq[6] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[6]) begin
						candidate1=8'h06;
						OwnerSeq1=Seq[6];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h06;
						OwnerSeq1=Seq[6];
						candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end				
				end		
				if((candidatelist1[7])	&& (Seq[7] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[7]) begin
						candidate1=8'h07;
						OwnerSeq1=Seq[7];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h07;
							OwnerSeq1=Seq[7];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end		
				if((candidatelist1[8])	&& (Seq[8] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[8]) begin
						candidate1=8'h08;
						OwnerSeq1=Seq[8];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h08;
							OwnerSeq1=Seq[8];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end		
				if((candidatelist1[9])	&& (Seq[9] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[9]) begin
						candidate1=8'h09;
						OwnerSeq1=Seq[9];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h09;
							OwnerSeq1=Seq[9];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end																
				end		
				if((candidatelist1[10]) && (Seq[10] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[10]) begin
						candidate1=8'h0A;
						OwnerSeq1=Seq[10];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h0A;
							OwnerSeq1=Seq[10];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end									
				end		
				if((candidatelist1[11]) && (Seq[11] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[11]) begin
						candidate1=8'h0B;
						OwnerSeq1=Seq[11];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h0B;
							OwnerSeq1=Seq[11];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end		
				if((candidatelist1[12]) && (Seq[12] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[12]) begin
						candidate1=8'h0C;
						OwnerSeq1=Seq[12];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h0C;
							OwnerSeq1=Seq[12];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end		
				end
				if((candidatelist1[13]) && (Seq[13] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[13]) begin
						candidate1=8'h0D;
						OwnerSeq1=Seq[13];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h0D;
							OwnerSeq1=Seq[13];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end		
				end
				if((candidatelist1[14]) && (Seq[14] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[14]) begin
						candidate1=8'h0E;
						OwnerSeq1=Seq[14];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h0E;
							OwnerSeq1=Seq[14];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[15]) && (Seq[15] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[15]) begin
						candidate1=8'h0F;
						OwnerSeq1=Seq[15];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h0F;
							OwnerSeq1=Seq[15];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end	
				if((candidatelist1[16]) && (Seq[16] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[16]) begin
						candidate1=8'h10;
						OwnerSeq1=Seq[16];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h10;
							OwnerSeq1=Seq[16];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end	
				if((candidatelist1[17]) && (Seq[17] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[17]) begin
						candidate1=8'h11;
						OwnerSeq1=Seq[17];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h11;
							OwnerSeq1=Seq[17];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end	
				if((candidatelist1[18]) && (Seq[18] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[18]) begin
						candidate1=8'h12;
						OwnerSeq1=Seq[18];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h12;
							OwnerSeq1=Seq[18];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end	
				if((candidatelist1[19]) && (Seq[19] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[19]) begin
						candidate1=8'h13;
						OwnerSeq1=Seq[19];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h13;
							OwnerSeq1=Seq[19];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end	
				if((candidatelist1[20]) && (Seq[20] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[20]) begin
						candidate1=8'h14;
						OwnerSeq1=Seq[20];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h14;
							OwnerSeq1=Seq[20];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end	
				if((candidatelist1[21]) && (Seq[21] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[21]) begin
						candidate1=8'h15;
						OwnerSeq1=Seq[21];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h15;
							OwnerSeq1=Seq[21];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end	
				if((candidatelist1[22]) && (Seq[22] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[22]) begin
						candidate1=8'h16;
						OwnerSeq1=Seq[22];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h16;
							OwnerSeq1=Seq[22];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[23]) && (Seq[23] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[23]) begin
						candidate1=8'h17;
						OwnerSeq1=Seq[23];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h17;
							OwnerSeq1=Seq[23];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[24]) && (Seq[24] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[24]) begin
						candidate1=8'h18;
						OwnerSeq1=Seq[24];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h18;
							OwnerSeq1=Seq[24];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[25]) && (Seq[25] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[25]) begin
						candidate1=8'h19;
						OwnerSeq1=Seq[25];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h19;
							OwnerSeq1=Seq[25];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[26]) && (Seq[26] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[26]) begin
						candidate1=8'h1A;
						OwnerSeq1=Seq[26];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h1A;
							OwnerSeq1=Seq[26];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[27]) && (Seq[27] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[27]) begin
						candidate1=8'h1B;
						OwnerSeq1=Seq[27];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h1B;
							OwnerSeq1=Seq[27];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[28]) && (Seq[28] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[28]) begin
						candidate1=8'h1C;
						OwnerSeq1=Seq[28];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h1C;
							OwnerSeq1=Seq[28];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[29]) && (Seq[29] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[29]) begin
						candidate1=8'h1D;
						OwnerSeq1=Seq[29];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h1D;
							OwnerSeq1=Seq[29];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[30]) && (Seq[30] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[30]) begin
						candidate1=8'h1E;
						OwnerSeq1=Seq[30];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h1E;
							OwnerSeq1=Seq[30];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
				if((candidatelist1[31]) && (Seq[31] < OwnerSeq1)) begin
					if(FU[candidate0]!=FU[31]) begin
						candidate1=8'h1F;
						OwnerSeq1=Seq[31];
						candidateDone1=1'b1;
						Aux1=1'b0;
					end
					else begin
						if(FU[candidate0]==2'b01) begin
							candidate1=8'h1F;
							OwnerSeq1=Seq[31];
							candidateDone1=1'b1;
							Aux1=1'b1;
						end
					end	
				end
			end
				
			if(candidateDone1) begin
				RowDecoder=Instr[candidate1];				
				case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b1; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b1;						
				endcase					
			end							

			candidatelist2=	candidatelist1;
			candidatelist2[candidate1]=1'b0;
				
			if(candidatelist2 != 32'h00000000) begin
				
				OwnerSeq2=32'hFFFF;							
				
				if(candidatelist2[0]) begin																				
					if((FU[candidate0]!=FU[0]) && (FU[candidate1]!=FU[0]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h00;
						OwnerSeq2=Seq[0];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end											
					else begin
						case({FU[candidate0],FU[candidate1],FU[0]})
							12'h112, 12'h113: begin
								candidate2=8'h00;
								OwnerSeq2=Seq[0];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h00;
								OwnerSeq2=Seq[0];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase	
					end	
				end							
				if((candidatelist2[1])	&& (Seq[1] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[1]) && (FU[candidate1]!=FU[1]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h01;
						OwnerSeq2=Seq[1];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[1]})
							12'h112, 12'h113: begin
								candidate2=8'h01;
								OwnerSeq2=Seq[1];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h01;
								OwnerSeq2=Seq[1];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase			
					end
				end			
				if((candidatelist2[2])	&& (Seq[2] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[2]) && (FU[candidate1]!=FU[2]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h02;
						OwnerSeq2=Seq[2];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[2]})
							12'h112, 12'h113: begin
								candidate2=8'h02;
								OwnerSeq2=Seq[2];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h02;
								OwnerSeq2=Seq[2];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end		
				end			
				if((candidatelist2[3])	&& (Seq[3] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[3]) && (FU[candidate1]!=FU[3]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h03;
						OwnerSeq2=Seq[3];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[3]})
							12'h112, 12'h113: begin
								candidate2=8'h03;
								OwnerSeq2=Seq[3];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h03;
								OwnerSeq2=Seq[3];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end	
				end					
				if((candidatelist2[4])	&& (Seq[4] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[4]) && (FU[candidate1]!=FU[4]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h04;
						OwnerSeq2=Seq[4];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[4]})
							12'h112, 12'h113: begin
								candidate2=8'h04;
								OwnerSeq2=Seq[4];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h04;
								OwnerSeq2=Seq[4];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase					
					end	
				end	
				if((candidatelist2[5])	&& (Seq[5] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[5]) && (FU[candidate1]!=FU[5]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h05;
						OwnerSeq2=Seq[5];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[5]})
							12'h112, 12'h113: begin
								candidate2=8'h05;
								OwnerSeq2=Seq[5];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h05;
								OwnerSeq2=Seq[5];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase					
					end				
				end		
				if((candidatelist2[6])	&& (Seq[6] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[6]) && (FU[candidate1]!=FU[6]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h06;
						OwnerSeq2=Seq[6];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[6]})
							12'h112, 12'h113: begin
								candidate2=8'h06;
								OwnerSeq2=Seq[6];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h06;
								OwnerSeq2=Seq[6];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase					
					end			
				end		
				if((candidatelist2[7])	&& (Seq[7] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[7]) && (FU[candidate1]!=FU[7]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h07;
						OwnerSeq2=Seq[7];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[7]})
							12'h112, 12'h113: begin
								candidate2=8'h07;
								OwnerSeq2=Seq[7];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h07;
								OwnerSeq2=Seq[7];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase	
					end	
				end		
				if((candidatelist2[8])	&& (Seq[8] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[8]) && (FU[candidate1]!=FU[8]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h08;
						OwnerSeq2=Seq[8];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[8]})
							12'h112, 12'h113: begin
								candidate2=8'h08;
								OwnerSeq2=Seq[8];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h08;
								OwnerSeq2=Seq[8];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end	
				if((candidatelist2[9])	&& (Seq[9] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[9]) && (FU[candidate1]!=FU[9]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h09;
						OwnerSeq2=Seq[9];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[9]})
							12'h112, 12'h113: begin
								candidate2=8'h09;
								OwnerSeq2=Seq[9];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h09;
								OwnerSeq2=Seq[9];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase												
					end															
				end	
				if((candidatelist2[10]) && (Seq[10] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[10]) && (FU[candidate1]!=FU[10]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h0A;
						OwnerSeq2=Seq[10];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[10]})
							12'h112, 12'h113: begin
								candidate2=8'h0A;
								OwnerSeq2=Seq[10];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h0A;
								OwnerSeq2=Seq[10];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase					
					end										
				end
				if((candidatelist2[11]) && (Seq[11] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[11]) && (FU[candidate1]!=FU[11]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h0B;
						OwnerSeq2=Seq[11];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
							case({FU[candidate0],FU[candidate1],FU[11]})
							12'h112, 12'h113: begin
								candidate2=8'h0B;
								OwnerSeq2=Seq[11];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h0B;
								OwnerSeq2=Seq[11];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase					
					end	
				end	
				if((candidatelist2[12]) && (Seq[12] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[12]) && (FU[candidate1]!=FU[12]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h0C;
						OwnerSeq2=Seq[12];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[12]})
							12'h112, 12'h113: begin
								candidate2=8'h0C;
								OwnerSeq2=Seq[12];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h0C;
								OwnerSeq2=Seq[12];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase					
					end		
				end			
				if((candidatelist2[13]) && (Seq[13] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[13]) && (FU[candidate1]!=FU[13]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h0D;
						OwnerSeq2=Seq[13];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[13]})
							12'h112, 12'h113: begin
								candidate2=8'h0D;
								OwnerSeq2=Seq[13];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h0D;
								OwnerSeq2=Seq[13];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase					
					end		
				end				
				if((candidatelist2[14]) && (Seq[14] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[14]) && (FU[candidate1]!=FU[14]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h0E;
						OwnerSeq2=Seq[14];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[14]})
							12'h112, 12'h113: begin
								candidate2=8'h0E;
								OwnerSeq2=Seq[14];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h0E;
								OwnerSeq2=Seq[14];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end		
				end				
				if((candidatelist2[15]) && (Seq[15] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[15]) && (FU[candidate1]!=FU[15]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h0F;
						OwnerSeq2=Seq[15];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[15]})
							12'h112, 12'h113: begin
								candidate2=8'h0F;
								OwnerSeq2=Seq[15];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h0F;
								OwnerSeq2=Seq[15];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[16]) && (Seq[16] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[16]) && (FU[candidate1]!=FU[16]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h10;
						OwnerSeq2=Seq[16];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[16]})
							12'h112, 12'h113: begin
								candidate2=8'h10;
								OwnerSeq2=Seq[16];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h10;
								OwnerSeq2=Seq[16];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[17]) && (Seq[17] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[17]) && (FU[candidate1]!=FU[17]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h11;
						OwnerSeq2=Seq[17];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[17]})
							12'h112, 12'h113: begin
								candidate2=8'h11;
								OwnerSeq2=Seq[17];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h11;
								OwnerSeq2=Seq[17];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[18]) && (Seq[18] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[18]) && (FU[candidate1]!=FU[18]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h12;
						OwnerSeq2=Seq[18];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[18]})
							12'h112, 12'h113: begin
								candidate2=8'h12;
								OwnerSeq2=Seq[18];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h12;
								OwnerSeq2=Seq[18];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[19]) && (Seq[19] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[19]) && (FU[candidate1]!=FU[19]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h13;
						OwnerSeq2=Seq[19];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[19]})
							12'h112, 12'h113: begin
								candidate2=8'h13;
								OwnerSeq2=Seq[19];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h13;
								OwnerSeq2=Seq[19];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[20]) && (Seq[20] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[20]) && (FU[candidate1]!=FU[20]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h14;
						OwnerSeq2=Seq[20];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[20]})
							12'h112, 12'h113: begin
								candidate2=8'h14;
								OwnerSeq2=Seq[20];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h14;
								OwnerSeq2=Seq[20];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[21]) && (Seq[21] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[21]) && (FU[candidate1]!=FU[21]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h15;
						OwnerSeq2=Seq[21];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[21]})
							12'h112, 12'h113: begin
								candidate2=8'h15;
								OwnerSeq2=Seq[21];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h15;
								OwnerSeq2=Seq[21];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[22]) && (Seq[22] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[22]) && (FU[candidate1]!=FU[22]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h16;
						OwnerSeq2=Seq[22];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[22]})
							12'h112, 12'h113: begin
								candidate2=8'h16;
								OwnerSeq2=Seq[22];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h16;
								OwnerSeq2=Seq[22];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[23]) && (Seq[23] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[23]) && (FU[candidate1]!=FU[23]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h17;
						OwnerSeq2=Seq[23];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[23]})
							12'h112, 12'h113: begin
								candidate2=8'h17;
								OwnerSeq2=Seq[23];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h17;
								OwnerSeq2=Seq[23];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[24]) && (Seq[24] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[24]) && (FU[candidate1]!=FU[24]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h18;
						OwnerSeq2=Seq[24];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[24]})
							12'h112, 12'h113: begin
								candidate2=8'h18;
								OwnerSeq2=Seq[24];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h18;
								OwnerSeq2=Seq[24];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[25]) && (Seq[25] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[25]) && (FU[candidate1]!=FU[25]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h19;
						OwnerSeq2=Seq[25];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[25]})
							12'h112, 12'h113: begin
								candidate2=8'h19;
								OwnerSeq2=Seq[25];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h19;
								OwnerSeq2=Seq[25];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[26]) && (Seq[26] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[26]) && (FU[candidate1]!=FU[26]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h1A;
						OwnerSeq2=Seq[26];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[26]})
							12'h112, 12'h113: begin
								candidate2=8'h1A;
								OwnerSeq2=Seq[26];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h1A;
								OwnerSeq2=Seq[26];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[27]) && (Seq[27] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[27]) && (FU[candidate1]!=FU[27]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h1B;
						OwnerSeq2=Seq[27];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[27]})
							12'h112, 12'h113: begin
								candidate2=8'h1B;
								OwnerSeq2=Seq[27];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h1B;
								OwnerSeq2=Seq[27];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[28]) && (Seq[28] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[28]) && (FU[candidate1]!=FU[28]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h1C;
						OwnerSeq2=Seq[28];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[28]})
							12'h112, 12'h113: begin
								candidate2=8'h1C;
								OwnerSeq2=Seq[28];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h1C;
								OwnerSeq2=Seq[28];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[29]) && (Seq[29] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[29]) && (FU[candidate1]!=FU[29]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h1D;
						OwnerSeq2=Seq[29];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[29]})
							12'h112, 12'h113: begin
								candidate2=8'h1D;
								OwnerSeq2=Seq[29];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h1D;
								OwnerSeq2=Seq[29];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[30]) && (Seq[30] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[30]) && (FU[candidate1]!=FU[30]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h1E;
						OwnerSeq2=Seq[30];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[30]})
							12'h112, 12'h113: begin
								candidate2=8'h1E;
								OwnerSeq2=Seq[30];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h1E;
								OwnerSeq2=Seq[30];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end
				if((candidatelist2[31]) && (Seq[31] < OwnerSeq2)) begin
					if((FU[candidate0]!=FU[31]) && (FU[candidate1]!=FU[31]) && (FU[candidate0]!=FU[candidate1])) begin
						candidate2=8'h1F;
						OwnerSeq2=Seq[31];
						candidateDone2=1'b1;
						Aux2=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[31]})
							12'h112, 12'h113: begin
								candidate2=8'h1F;
								OwnerSeq2=Seq[31];
								candidateDone2=1'b1;
								Aux2=1'b0;
							end
							12'h121, 12'h131, 12'h211, 12'h311: begin
								candidate2=8'h1F;
								OwnerSeq2=Seq[31];
								candidateDone2=1'b1;
								Aux2=1'b1;
							end
						endcase				
					end
				end	
			end
											
			if(candidateDone2) begin
				RowDecoder=Instr[candidate2];				
				case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b1; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b1;						
				endcase		
			end
		
			candidatelist3=	candidatelist2;							
			candidatelist3[candidate2]=1'b0;
						
			if(candidatelist3 != 32'h00000000) begin
				
				OwnerSeq3=32'hFFFF;
																	
				if(candidatelist3[0]) begin
					if((FU[candidate0]!=FU[0]) && (FU[candidate1]!=FU[0]) && (FU[candidate2]!=FU[0]) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
						candidate3=4'h0;
						OwnerSeq3=Seq[0];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[0]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'h0;
								OwnerSeq3=Seq[0];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'h0;
								OwnerSeq3=Seq[0];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase	
					end
				end
				if((candidatelist3[1])	&& (Seq[1] < OwnerSeq3)) begin
					if((FU[candidate0]!=FU[1]) && (FU[candidate1]!=FU[1]) && (FU[candidate2]!=FU[1]) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
						candidate3=4'h1;
						OwnerSeq3=Seq[1];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[1]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'h1;
								OwnerSeq3=Seq[1];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'h1;
								OwnerSeq3=Seq[1];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase					
					end
				end							
				if((candidatelist3[2])	&& (Seq[2] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[3]) && (FU[candidate1]!=FU[3]) && (FU[candidate2]!=FU[3])) begin
						candidate3=4'h2;
						OwnerSeq3=Seq[2];	
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[2]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'h2;
								OwnerSeq3=Seq[2];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'h2;
								OwnerSeq3=Seq[2];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase				
					end		
				end			
				if((candidatelist3[3])	&& (Seq[3] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[3]) && (FU[candidate1]!=FU[3]) && (FU[candidate2]!=FU[3])) begin
						candidate3=4'h3;
						OwnerSeq3=Seq[3];	
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[3]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'h3;
								OwnerSeq3=Seq[3];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'h3;
								OwnerSeq3=Seq[3];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase				
					end
				end							
				if((candidatelist3[4])	&& (Seq[4] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[4]) && (FU[candidate1]!=FU[4]) && (FU[candidate2]!=FU[4])) begin
						candidate3=4'h4;
						OwnerSeq3=Seq[4];	
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[4]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'h4;
								OwnerSeq3=Seq[4];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'h4;
								OwnerSeq3=Seq[4];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase				
					end	
				end						
				if((candidatelist3[5])	&& (Seq[5] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[5]) && (FU[candidate1]!=FU[5]) && (FU[candidate2]!=FU[5])) begin
						candidate3=4'h5;
						OwnerSeq3=Seq[5];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[5]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'h5;
								OwnerSeq3=Seq[5];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'h5;
								OwnerSeq3=Seq[5];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase					
					end									
				end			
				if((candidatelist3[6])	&& (Seq[6] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[6]) && (FU[candidate1]!=FU[6]) && (FU[candidate2]!=FU[6])) begin
						candidate3=4'h6;
						OwnerSeq3=Seq[6];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[6]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'h6;
								OwnerSeq3=Seq[6];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'h6;
								OwnerSeq3=Seq[6];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase				
					end							
				end					
				if((candidatelist3[7])	&& (Seq[7] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[7]) && (FU[candidate1]!=FU[7]) && (FU[candidate2]!=FU[7])) begin
						candidate3=4'h7;
						OwnerSeq3=Seq[7];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[7]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'h7;
								OwnerSeq3=Seq[7];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'h7;
								OwnerSeq3=Seq[7];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase				
					end
				end		
				if((candidatelist3[8])	&& (Seq[8] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[8]) && (FU[candidate1]!=FU[8]) && (FU[candidate2]!=FU[8])) begin
						candidate3=4'h8;
						OwnerSeq3=Seq[8];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[8]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'h8;
								OwnerSeq3=Seq[8];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'h8;
								OwnerSeq3=Seq[8];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase				
					end
				end	
				if((candidatelist3[9])	&& (Seq[9] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[9]) && (FU[candidate1]!=FU[9]) && (FU[candidate2]!=FU[9])) begin
						candidate3=4'h9;
						OwnerSeq3=Seq[9];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[9]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'h9;
								OwnerSeq3=Seq[9];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'h9;
								OwnerSeq3=Seq[9];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase				
					end															
				end			
				if((candidatelist3[10]) && (Seq[10] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[10]) && (FU[candidate1]!=FU[10]) && (FU[candidate2]!=FU[10])) begin
						candidate3=4'hA;
						OwnerSeq3=Seq[10];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[10]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'hA;
								OwnerSeq3=Seq[10];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'hA;
								OwnerSeq3=Seq[10];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase				
					end										
				end
				if((candidatelist3[11]) && (Seq[11] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[11]) && (FU[candidate1]!=FU[11]) && (FU[candidate2]!=FU[11])) begin
						candidate3=4'hB;
						OwnerSeq3=Seq[11];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[11]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'hB;
								OwnerSeq3=Seq[11];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'hB;
								OwnerSeq3=Seq[11];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase					
					end	
				end	
				if((candidatelist3[12]) && (Seq[12] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[12]) && (FU[candidate1]!=FU[12]) && (FU[candidate2]!=FU[12])) begin
						candidate3=4'hC;
						OwnerSeq3=Seq[12];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[12]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'hC;
								OwnerSeq3=Seq[12];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'hC;
								OwnerSeq3=Seq[12];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase					
					end		
				end		
				if((candidatelist3[13]) && (Seq[13] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[13]) && (FU[candidate1]!=FU[13]) && (FU[candidate2]!=FU[13])) begin
						candidate3=4'hD;
						OwnerSeq3=Seq[13];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[13]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'hD;
								OwnerSeq3=Seq[13];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'hD;
								OwnerSeq3=Seq[13];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase					
					end		
				end			
				if((candidatelist3[14]) && (Seq[14] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[14]) && (FU[candidate1]!=FU[14]) && (FU[candidate2]!=FU[14])) begin
						candidate3=4'hE;
						OwnerSeq3=Seq[14];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[14]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'hE;
								OwnerSeq3=Seq[14];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'hE;
								OwnerSeq3=Seq[14];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase					
					end			
				end					
				if((candidatelist3[15]) && (Seq[15] < OwnerSeq3) && (FU[candidate0]!=FU[candidate1]) && (FU[candidate1]!=FU[candidate2]) && (FU[candidate0]!=FU[candidate2])) begin
					if((FU[candidate0]!=FU[15]) && (FU[candidate1]!=FU[15]) && (FU[candidate2]!=FU[15])) begin
						candidate3=4'hF;
						OwnerSeq3=Seq[15];
						candidateDone3=1'b1;
						Aux3=1'b0;
					end
					else begin
						case({FU[candidate0],FU[candidate1],FU[candidate2],FU[15]})
							16'h1123, 16'h1132, 16'h1213, 16'h1312, 16'h2113, 16'h3112: begin
								candidate3=4'hF;
								OwnerSeq3=Seq[15];
								candidateDone3=1'b1;
								Aux3=1'b0;
							end
							16'h1231, 16'h1321, 16'h2131, 16'h2311, 16'h3121, 16'h3211: begin
								candidate3=4'hF;
								OwnerSeq3=Seq[15];
								candidateDone3=1'b1;
								Aux3=1'b1;
							end
						endcase					
					end
				end
			end	
			
			if(candidateDone3) begin
				RowDecoder=Instr[candidate3];				
				case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b1; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b1;						
				endcase			
			end	

			if(BrHappens) begin
				if(Seq[0]>BrSequence) begin
					RowDecoder=Instr[0];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end	
				if(Seq[1]>BrSequence) begin
					RowDecoder=Instr[1];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end	
				if(Seq[2]>BrSequence) begin
					RowDecoder=Instr[2];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[3]>BrSequence) begin
					RowDecoder=Instr[3];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[4]>BrSequence) begin
					RowDecoder=Instr[4];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[5]>BrSequence) begin
					RowDecoder=Instr[5];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[6]>BrSequence) begin
					RowDecoder=Instr[6];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[7]>BrSequence) begin
					RowDecoder=Instr[7];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[8]>BrSequence) begin
					RowDecoder=Instr[8];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[9]>BrSequence) begin
					RowDecoder=Instr[9];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[10]>BrSequence) begin
					RowDecoder=Instr[10];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[11]>BrSequence) begin
					RowDecoder=Instr[11];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[12]>BrSequence) begin
					RowDecoder=Instr[12];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase	
				end
				if(Seq[13]>BrSequence) begin
					RowDecoder=Instr[13];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[14]>BrSequence) begin
					RowDecoder=Instr[14];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[15]>BrSequence) begin
					RowDecoder=Instr[15];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end				
				if(Seq[16]>BrSequence) begin
					RowDecoder=Instr[16];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end	
				if(Seq[17]>BrSequence) begin
					RowDecoder=Instr[17];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end	
				if(Seq[18]>BrSequence) begin
					RowDecoder=Instr[18];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[19]>BrSequence) begin
					RowDecoder=Instr[19];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[20]>BrSequence) begin
					RowDecoder=Instr[20];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[21]>BrSequence) begin
					RowDecoder=Instr[21];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[22]>BrSequence) begin
					RowDecoder=Instr[22];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[23]>BrSequence) begin
					RowDecoder=Instr[23];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[24]>BrSequence) begin
					RowDecoder=Instr[24];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[25]>BrSequence) begin
					RowDecoder=Instr[25];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[26]>BrSequence) begin
					RowDecoder=Instr[26];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[27]>BrSequence) begin
					RowDecoder=Instr[27];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[28]>BrSequence) begin
					RowDecoder=Instr[28];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase	
				end
				if(Seq[29]>BrSequence) begin
					RowDecoder=Instr[29];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[30]>BrSequence) begin
					RowDecoder=Instr[30];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				if(Seq[31]>BrSequence) begin
					RowDecoder=Instr[31];
					case (RowDecoder[31:26]) //op field of the instruction												
						6'b000_000: RRSTaken[RowDecoder[15:11]]=1'b0; //R-Type
						6'b100_011,6'b001_111, 6'b001_000,	6'b001_001, 6'b001_010,	6'b001_011, 6'b001_100,	6'b001_101, 6'b001_110: RRSTaken[RowDecoder[20:16]]=1'b0;						
					endcase					
				end
				
				if(Seq[candidate0]>BrSequence)
					candidateDone0=1'b0;
				
				if(Seq[candidate1]>BrSequence)
					candidateDone1=1'b0;
				
				if(Seq[candidate2]>BrSequence)
					candidateDone2=1'b0;
				
				if(Seq[candidate3]>BrSequence)
					candidateDone3=1'b0;				
			end				
			
			if(candidateDone0) begin						
				case (FU[candidate0])
					2'b00: begin 
						Instr0ID={Instr[candidate0],Seq[candidate0]};
						ActiveLanes[0]=1'b1;
						BrPC=IPC[candidate0];
						VJ0=VJ[candidate0];
						VK0=VK[candidate0];					
					end
					2'b01: begin 
						Instr1ID={Instr[candidate0],Seq[candidate0]};
						ActiveLanes[1]=1'b1;
						VJ1=VJ[candidate0];
						VK1=VK[candidate0];	
					end
					2'b10: begin 
						Instr2ID={Instr[candidate0],Seq[candidate0]};
						ActiveLanes[2]=1'b1;
						VJ2=VJ[candidate0];	
					end
					2'b11: begin 
						Instr3ID={Instr[candidate0],Seq[candidate0]};
						ActiveLanes[3]=1'b1;
						VJ3=VJ[candidate0];
						VK3=VK[candidate0];
					end
				endcase			
			end
			if(candidateDone1) begin
				case (FU[candidate1])
					2'b00: begin 
						Instr0ID={Instr[candidate1],Seq[candidate1]};
						ActiveLanes[0]=1'b1;
						BrPC=IPC[candidate1];
						VJ0=VJ[candidate1];
						VK0=VK[candidate1];
					end
					2'b01: begin
						if(Aux1) begin
							Instr0ID={Instr[candidate1],Seq[candidate1]};
							ActiveLanes[0]=1'b1;
							VJ0=VJ[candidate1];
							VK0=VK[candidate1];
						end
						else begin
							Instr1ID={Instr[candidate1],Seq[candidate1]};
							ActiveLanes[1]=1'b1;
							VJ1=VJ[candidate1];
							VK1=VK[candidate1];	
						end
					end
					2'b10: begin 
						Instr2ID={Instr[candidate1],Seq[candidate1]};
						ActiveLanes[2]=1'b1;
						VJ2=VJ[candidate1];	
					end
					2'b11: begin 
						Instr3ID={Instr[candidate1],Seq[candidate1]};
						ActiveLanes[3]=1'b1;
						VJ3=VJ[candidate1];
						VK3=VK[candidate1];
					end
				endcase	
			end
			if(candidateDone2) begin		
				case (FU[candidate2])
					2'b00: begin 
						Instr0ID={Instr[candidate2],Seq[candidate2]};
						ActiveLanes[0]=1'b1;
						BrPC=IPC[candidate2];
						VJ0=VJ[candidate2];
						VK0=VK[candidate2];
					end
					2'b01: begin
						if(Aux2) begin
							Instr0ID={Instr[candidate2],Seq[candidate2]};
							ActiveLanes[0]=1'b1;
							VJ0=VJ[candidate2];
							VK0=VK[candidate2];
						end
						else begin
							Instr1ID={Instr[candidate2],Seq[candidate2]};
							ActiveLanes[1]=1'b1;
							VJ1=VJ[candidate2];
							VK1=VK[candidate2];	
						end
					end
					2'b10: begin 
						Instr2ID={Instr[candidate2],Seq[candidate2]};
						ActiveLanes[2]=1'b1;
						VJ2=VJ[candidate2];	
					end
					2'b11: begin 
						Instr3ID={Instr[candidate2],Seq[candidate2]};
						ActiveLanes[3]=1'b1;
						VJ3=VJ[candidate2];
						VK3=VK[candidate2];
					end
				endcase
			end
			if(candidateDone3) begin					
				case (FU[candidate3])
					2'b00: begin 
						Instr0ID={Instr[candidate3],Seq[candidate3]};
						ActiveLanes[0]=1'b1;
						BrPC=IPC[candidate3];
						VJ0=VJ[candidate3];
						VK0=VK[candidate3];
					end
					2'b01: begin
						if(Aux3) begin
							Instr0ID={Instr[candidate3],Seq[candidate3]};
							ActiveLanes[0]=1'b1;
							VJ0=VJ[candidate3];
							VK0=VK[candidate3];
						end
						else begin
							Instr1ID={Instr[candidate3],Seq[candidate3]};
							ActiveLanes[1]=1'b1;
							VJ1=VJ[candidate3];
							VK1=VK[candidate3];	
						end
					end
					2'b10: begin 
						Instr2ID={Instr[candidate3],Seq[candidate3]};
						ActiveLanes[2]=1'b1;
						VJ2=VJ[candidate3];	
					end
					2'b11: begin 
						Instr3ID={Instr[candidate3],Seq[candidate3]};
						ActiveLanes[3]=1'b1;
						VJ3=VJ[candidate3];
						VK3=VK[candidate3];
					end
				endcase	
			end	

		end		
	end
	
	//active
	always @(*) begin

		next_active=active;
		if(valid_writeptr) begin
			next_active[writeptr[7:0]]=1'b0;
			next_active[writeptr[15:8]]=1'b0;
			next_active[writeptr[23:16]]=1'b0;
			next_active[writeptr[31:24]]=1'b0;
		end
		if(candidateDone0) 			
			next_active[candidate0]=1'b1;				
		if(candidateDone1) 
			next_active[candidate1]=1'b1;
		if(candidateDone2) 
			next_active[candidate2]=1'b1;			
		if(candidateDone3) 
			next_active[candidate3]=1'b1;

	end
		
endmodule

//========================================================== 
//						Control Logic
//========================================================== 

module control_unit(
	input [31:0] Inst,	
	output reg ImmSE,
	output reg [2:0] ALUOp,	
	output reg RFWrite,
	output reg [1:0] Branch,
	output reg RegDst,
	output reg LUI,
	output reg ALUSrc
);

/*
//////////////////////////////////////////////////////
/////////////SIGNAL ASSIGNMENT DICTIONARY/////////////
//////////////////////////////////////////////////////

ImmSE=1'b1;			sign-extend the immediate value
ImmSE=1'b0;			zero-extend the immediate value

ALUOp=3'b000;		adjust ALU to add its inputs
ALUOp=3'b001;		adjust ALU to subtract its inputs
ALUOp=3'b010;		adjust ALU to and its inputs
ALUOp=3'b011;		adjust ALU to or its inputs
ALUOp=3'b100;		adjust ALU to xor its inputs
ALUOp=3'b101;		adjust ALU to nor its inputs
ALUOp=3'b110;		adjust ALU to slt (set on less than, compare) its signed inputs
ALUOp=3'b111;		adjust ALU to sltu (set on less than, compare) its unsigned inputs

RFWrite=1'b1;		allow writing on the register file
RFWrite=1'b0;		deny writing on the register file

Branch=2'b00;		announce to next-PC-generation logic that the current instruction is not a branch instruction
Branch=2'b01;		announce to next-PC-generation logic that the current instruction is a beq instruction
Branch=2'b10;		announce to next-PC-generation logic that the current instruction is a bne instruction

RegDst=1'b1;		write on the register file's destination register
RegDst=1'b0;		write on the register file's target register

LUI=1'b1;			between all sources, write shifted-immediate's value on the register file

ALUSrc=1'b1;		pass the sign-extended immediate value to the ALU
ALUSrc=1'b0;		pass the register file's second read-port value to the ALU 

When a signal's value doesn't care in a specific instruction, its value is assumed to be x.
*/

	always @(*) begin
		case (Inst[31:26]) //op field of the instruction
					
			//R-Format
			6'b000_000: begin		
				ImmSE=1'bx;
				RFWrite=1'b1;
				Branch=2'b00;
				RegDst=1'b1;
				LUI=1'b0;
				ALUSrc=1'b0;
				
				case (Inst[5:0]) //funct field of the instruction
				
					//add,addu
					6'b100_000, 6'b100_001: ALUOp=3'b000;						
									
					//sub,subu
					6'b100_010, 6'b100_011: ALUOp=3'b001;
					
					//and
					6'b100_100: ALUOp=3'b010;					
					
					//or
					6'b100_101: ALUOp=3'b011;					
					
					//xor
					6'b100_110: ALUOp=3'b100;
							
					//nor
					6'b100_111: ALUOp=3'b101;					
					
					//slt
					6'b101_010: ALUOp=3'b110;
							
					//sltu
					6'b101_011: ALUOp=3'b111;					
				
					//error
					default: ALUOp=3'b000;	
					
				endcase
			end
			
			//addi,addiu
			6'b001_000,	6'b001_001: begin		
				ImmSE=1'b1;
				ALUOp=3'b000;
				RFWrite=1'b1;
				Branch=2'b00;
				RegDst=1'b0;
				LUI=1'b0;
				ALUSrc=1'b1;
			end
			
			//slti
			6'b001_010: begin		
				ImmSE=1'b1;
				ALUOp=3'b110;
				RFWrite=1'b1;
				Branch=2'b00;
				RegDst=1'b0;
				LUI=1'b0;
				ALUSrc=1'b1;
			end
			
			//sltiu
			6'b001_011: begin		
				ImmSE=1'b0;
				ALUOp=3'b111;
				RFWrite=1'b1;
				Branch=2'b00;
				RegDst=1'b0;
				LUI=1'b0;
				ALUSrc=1'b1;
			end
			
			//andi
			6'b001_100: begin		
				ImmSE=1'b0;
				ALUOp=3'b010;
				RFWrite=1'b1;
				Branch=2'b00;
				RegDst=1'b0;
				LUI=1'b0;
				ALUSrc=1'b1;
			end
			
			//ori
			6'b001_101: begin		
				ImmSE=1'b0;
				ALUOp=3'b011;
				RFWrite=1'b1;
				Branch=2'b00;
				RegDst=1'b0;
				LUI=1'b0;
				ALUSrc=1'b1;
			end
			
			//xori
			6'b001_110: begin		
				ImmSE=1'b0;
				ALUOp=3'b100;
				RFWrite=1'b1;
				Branch=2'b00;
				RegDst=1'b0;
				LUI=1'b0;
				ALUSrc=1'b1;
			end
			
			//lui
			6'b001_111: begin		
				ImmSE=1'bx;
				ALUOp=3'bxxx;
				RFWrite=1'b1;
				Branch=2'b00;
				RegDst=1'b0;
				LUI=1'b1;
				ALUSrc=1'b1;				
			end
			
			//beq
			6'b000_100: begin		
				ImmSE=1'b1;
				ALUOp=3'b001;
				RFWrite=1'b0;
				Branch=2'b01;
				RegDst=1'bx;
				LUI=1'b0;
				ALUSrc=1'b0;			
			end
			
			//bne
			6'b000_101: begin		
				ImmSE=1'b1;
				ALUOp=3'b001;
				RFWrite=1'b0;
				Branch=2'b10;
				RegDst=1'bx;
				LUI=1'b0;
				ALUSrc=1'b0;				
			end
			
			//error
			default: begin
				ImmSE=1'bx;
				ALUOp=3'b000;
				RFWrite=1'b0;
				Branch=2'b00;
				RegDst=1'b1;
				LUI=1'b0;
				ALUSrc=1'b0;				
			end
			
		endcase
	end

endmodule

//========================================================== 
//					5-bit 2-to-1 MUX
//========================================================== 

module MUX5(
	input [4:0] In0,
	input [4:0] In1,
	input  Select,	
	output [4:0] Out
);

	assign Out = (Select)? In1:In0;
	
endmodule

//========================================================== 
//				Immediate Extension Logic
//========================================================== 

module extension(
	input  ImmSignEx,
	input  [15:0] Imm,
	output [31:0] ExtImm
);

	assign ExtImm = (ImmSignEx)? {{16{Imm[15]}},Imm}:{16'h0000,Imm}; //When required, sign-extend the immediate value, otherwise zero-extend it.

endmodule

//========================================================== 
//				Immediate Shift Logic
//========================================================== 

module Imm_Shifter(
	input  [15:0] Imm,
	output [31:0] ShImm
);

	assign ShImm = {Imm,16'h0000};	//move the immediate value to the upper (left-most) bits of the output.

endmodule

//========================================================== 
//					ID/EX Pipeline Register
//========================================================== 

module IDEXRegister(
	input clk,		
	input clr,	
	input [3:0] ActiveLanes,
	input [31:0] VJ0,
	input [31:0] VK0,
	input [31:0] VJ1,
	input [31:0] VK1,
	input [31:0] VJ2,
	input [31:0] VJ3,
	input [31:0] VK3,	
	input [31:0] SC0ID,
	input [31:0] SC1ID,
	input [31:0] SC2ID,
	input [31:0] SC3ID,
	input [4:0]	WriteReg0D,
	input [4:0]	WriteReg1D,
	input [4:0]	WriteReg2D,
	input [31:0] ExtImm0D,
	input [31:0] ExtImm1D,
	input [31:0] ExtImm2D,
	input [31:0] ExtImm3D,
	input LUI0D,
	input LUI1D,
	input [2:0] ALUOp0D,
	input [2:0] ALUOp1D,
	input ALUSrc0D,
	input ALUSrc1D,
	input [31:0] ShImm0D,
	input [31:0] ShImm1D,
	input [1:0] Branch0D,
	input RFWrite0D,
	input [31:0] BrPC,
	output reg [3:0] ActiveLanesE,
	output reg [31:0] VJ0E,
	output reg [31:0] VK0E,
	output reg [31:0] VJ1E,
	output reg [31:0] VK1E,
	output reg [31:0] VJ2E,
	output reg [31:0] VJ3E,
	output reg [31:0] WriteDataE,			
	output reg [31:0] SC0E,
	output reg [31:0] SC1E,
	output reg [31:0] SC2E,
	output reg [31:0] SC3E,	
	output reg [4:0] WriteReg0E,
	output reg [4:0] WriteReg1E,
	output reg [4:0] WriteReg2E,	
	output reg [31:0] ExtImm0E,
	output reg [31:0] ExtImm1E,
	output reg [31:0] ExtImm2E,
	output reg [31:0] ExtImm3E,
	output reg LUI0E,
	output reg LUI1E,
	output reg [2:0] ALUOp0E,
	output reg [2:0] ALUOp1E,
	output reg	ALUSrc0E,
	output reg	ALUSrc1E,
	output reg [31:0] ShImm0E,
	output reg [31:0] ShImm1E,
	output reg [1:0] BranchE,
	output reg RFWriteE,
	output reg [31:0] BrPCE	
);
	
	always @(posedge clk) begin
		if (clr) begin
			ActiveLanesE <=4'h0;
			VJ0E <=32'h00000000;
			VK0E <=32'h00000000;
			VJ1E <=32'h00000000;
			VK1E <=32'h00000000;
			VJ2E <=32'h00000000;
			VJ3E <=32'h00000000;
			WriteDataE <=32'h00000000;
			SC0E <=32'h00000000;
			SC1E <=32'h00000000;
			SC2E <=32'h00000000;
			SC3E <=32'h00000000;
			WriteReg0E <=5'b00000;
			WriteReg1E <=5'b00000;
			WriteReg2E <=5'b00000;
			ExtImm0E <=32'h00000000;
			ExtImm1E <=32'h00000000;
			ExtImm2E <=32'h00000000;
			ExtImm3E <=32'h00000000;
			LUI0E <=1'b0;
			LUI1E <=1'b0;
			ALUOp0E <=3'b000;
			ALUOp1E <=3'b000;
			ALUSrc0E <=1'b0;
			ALUSrc1E <=1'b0;
			ShImm0E <=32'h00000000;
			ShImm1E <=32'h00000000;
			BranchE <=2'b00;
			RFWriteE <=1'b0;
			BrPCE <=32'h00000000;
		end 
		else begin
			ActiveLanesE <= ActiveLanes;
			VJ0E <= VJ0;
			VK0E <= VK0;
			VJ1E <= VJ1;
			VK1E <= VK1;
			VJ2E <= VJ2;
			VJ3E <= VJ3;
			WriteDataE <= VK3;
			SC0E <= SC0ID;
			SC1E <= SC1ID;
			SC2E <= SC2ID;
			SC3E <= SC3ID;
			WriteReg0E <= WriteReg0D;
			WriteReg1E <= WriteReg1D;
			WriteReg2E <= WriteReg2D;
			ExtImm0E <= ExtImm0D;
			ExtImm1E <= ExtImm1D;
			ExtImm2E <= ExtImm2D;
			ExtImm3E <= ExtImm3D;
			LUI0E <= LUI0D;
			LUI1E <= LUI1D;
			ALUOp0E <= ALUOp0D;
			ALUOp1E <= ALUOp1D;
			ALUSrc0E <= ALUSrc0D;
			ALUSrc1E <= ALUSrc1D;
			ShImm0E <= ShImm0D;
			ShImm1E <= ShImm1D;
			BranchE <= Branch0D;
			RFWriteE <= RFWrite0D;
			BrPCE <= BrPC;		
		end			
	end
	
endmodule

//========================================================== 
//				Arithmetic & Logic Unit
//========================================================== 

module MIPSALU(
	input  [31:0] IN1,
	input  [31:0] IN2,
	input  [2:0] ALUOp,
	output reg [31:0] ALUResult,
	output Zero
);
	assign Zero=(IN1==IN2);
	
	always @(*) begin
		case(ALUOp)

		//add
		3'b000: ALUResult = IN1 + IN2; //The compiler jettisons the addition's output carry automatically

		//sub
		3'b001: ALUResult = IN1 + (32'b1 + ~IN2);

		//and
		3'b010: ALUResult = IN1 & IN2;

		//or
		3'b011: ALUResult = IN1 | IN2;

		//xor
		3'b100: ALUResult = IN1 ^ IN2;

		//nor
		3'b101: ALUResult = ~(IN1 | IN2);

		//slt
		3'b110: begin 
			if (IN1[31] != IN2[31]) 
				if (IN1[31] > IN2[31]) 
					ALUResult = 1;					 
				else 
					ALUResult = 0;			 
			else 
				ALUResult = (IN1 < IN2);		
		end

		//sltu
		3'b111: ALUResult = (IN1 < IN2);

		//error
		default: ALUResult = 32'hxxxxxxxx;

		endcase
	end
	
endmodule

//========================================================== 
//				Address Alignment Logic
//========================================================== 

module Address_Alignment(
	input [31:0] Address,
	output [31:0] AlignedAdd
);

	assign AlignedAdd = {Address[29:0],2'b00};
	
endmodule

//========================================================== 
//				Branch Conditioning Logic
//========================================================== 

module Branch_Conditioner(
	input [1:0] Branch,
	input Zero,
	input [3:0] ActiveLanesE,
	output reg BrHappens
);

	always @(*) begin
		BrHappens=1'b0;	
		if (ActiveLanesE[0])
			if ((Branch==2'b01 && Zero) || (Branch==2'b10 && !Zero)) //if the instruction is beq and its operands are equal or if the instruction is bne and its operands aren't equal
				BrHappens=1'b1;				
	end
	
endmodule

//========================================================== 
//					Reordering Buffer
//========================================================== 
module Reordering_Buffer(
	input clk,
	input clr,
	input [3:0] ActiveLanesE,
	input [31:0] SC0E,
	input [31:0] SC1E,
	input [31:0] SC2E,
	input [31:0] SC3E,	
	input [31:0] WriteDataE,	
	input [31:0] SwAddr,
	input [4:0] WriteReg2E,
	input [31:0] LwAddr,	
	input [4:0] WriteReg1E,	
	input [31:0] ALUOut1E,
	input LUI1E,
	input [31:0] ShImm1E,	
	input [4:0] WriteReg0E,	
	input [31:0] ALUOut0E,
	input LUI0E,
	input [31:0] ShImm0E,
	input RFWriteE,
	input BrHappens,	
	output reg write0,
	output reg write1,
	output reg write2,	
	output reg [ 4:0] WR0,
	output reg [ 4:0] WR1,
	output reg [ 4:0] WR2E,
	output reg [31:0] WD0,	
	output reg [31:0] WD1,	
	output reg [31:0] ISequence0,
	output reg [31:0] ISequence1,
	output reg [31:0] ISequence2E,
	output reg [31:0] ISequence3,	
	output reg I0done,		
	output reg I1done,			
	output reg I2doneE,		
	output reg I3done,
	output reg [31:0] LwAddrE,
	output reg [31:0] SwAddrE,
	output reg [31:0] DMemDataE,
	output reg DMemWriteE
);

	reg [3:0] busy0;			//lines' current busy indicator for FU #0
	reg [3:0] busy1;			//lines' current busy indicator for FU #1
	reg [3:0] busy2;			//lines' current busy indicator for FU #2
	reg [3:0] busy3;			//lines' current busy indicator for FU #3
	
	reg [3:0] condition0;		//lines' initial busy indicator for FU #0
	reg [3:0] condition1;		//lines' initial busy indicator for FU #1
	reg [3:0] condition2;		//lines' initial busy indicator for FU #2
	reg [3:0] condition3;		//lines' initial busy indicator for FU #3
	
	reg [3:0] constant_condition0;		//lines' initial busy indicator for FU #0
	reg [3:0] constant_condition1;		//lines' initial busy indicator for FU #1
	reg [3:0] constant_condition2;		//lines' initial busy indicator for FU #2
	reg [3:0] constant_condition3;		//lines' initial busy indicator for FU #3
	
	reg [3:0] conditionI;		//instrs' initial condition
				
	reg [31:0] SC0 [0:3];		//SC of awaited lane #0 instructions
	reg [31:0] SC1 [0:3];		//SC of awaited lane #1 instructions
	reg [31:0] SC2 [0:3];		//SC of awaited lane #2 instructions
	reg [31:0] SC3 [0:3];		//SC of awaited lane #3 instructions
	reg [31:0] Next_SC0 [0:3];		//SC of awaited lane #0 instructions
	reg [31:0] Next_SC1 [0:3];		//SC of awaited lane #1 instructions
	reg [31:0] Next_SC2 [0:3];		//SC of awaited lane #2 instructions
	reg [31:0] Next_SC3 [0:3];		//SC of awaited lane #3 instructions

	reg [31:0] SC;				//Done sequences counter
	reg [31:0] Next_SC;
		
	reg SC0Done;				//SC matches the expected. commit the instruction 
	reg SC1Done;				
	reg SC2Done;				
	reg SC3Done;				
		
	reg[3:0] Allocated;			//output allocation indicator
	
	reg [70:0] line0 [0:3];		//FU #0 output contents
	reg [69:0] line1 [0:3];		//FU #1 output contents
	reg [36:0] line2 [0:3];		//FU #2 output contents
	reg [63:0] line3 [0:3];		//FU #3 output contents
		
	reg OutAssigned0;			//The output is assigned 
	reg OutAssigned1;			
	reg OutAssigned2;			
	reg OutAssigned3;

	reg Passed0;				//The inputis passed to the output
	reg Passed1;			
	reg Passed2;			
	reg Passed3;
	
	reg [3:0] Winner;
	
	reg [1:0] writeptr0;
	reg [1:0] writeptr1;
	reg [1:0] writeptr2;
	reg [1:0] writeptr3;
					
	reg [70:0] RowDecoder00;
	reg [70:0] RowDecoder01;
	reg [70:0] RowDecoder02;
	reg [70:0] RowDecoder03;
	
	reg [69:0] RowDecoder10;
	reg [69:0] RowDecoder11;
	reg [69:0] RowDecoder12;
	reg [69:0] RowDecoder13;
	
	reg [36:0] RowDecoder20;
	reg [36:0] RowDecoder21;
	reg [36:0] RowDecoder22;
	reg [36:0] RowDecoder23;

	reg [63:0] RowDecoder30;
	reg [63:0] RowDecoder31;
	reg [63:0] RowDecoder32;
	reg [63:0] RowDecoder33;
		
	always @(posedge clk) begin	
		if(clr) begin		
			constant_condition0 <= 4'h0;
			constant_condition1 <= 4'h0;
			constant_condition2 <= 4'h0;
			constant_condition3 <= 4'h0;		
			SC <= 32'h00000000;
			RowDecoder00 <= 71'h0;
			RowDecoder01 <= 71'h0;
			RowDecoder02 <= 71'h0;
			RowDecoder03 <= 71'h0;		
			RowDecoder10 <= 69'h0;
			RowDecoder11 <= 69'h0;
			RowDecoder12 <= 69'h0;
			RowDecoder13 <= 69'h0;
			RowDecoder20 <= 36'h0;
			RowDecoder21 <= 36'h0;
			RowDecoder22 <= 36'h0;
			RowDecoder23 <= 36'h0;
			RowDecoder30 <= 63'h0;
			RowDecoder31 <= 63'h0;
			RowDecoder32 <= 63'h0;
			RowDecoder33 <= 63'h0;	
		end
		else begin
			constant_condition0 <= busy0;
			constant_condition1 <= busy1;
			constant_condition2 <= busy2;
			constant_condition3 <= busy3;		
			SC <= Next_SC;
			RowDecoder00 <= line0[0];
			RowDecoder01 <= line0[1];
			RowDecoder02 <= line0[2];
			RowDecoder03 <= line0[3];
			RowDecoder10 <= line1[0];
			RowDecoder11 <= line1[1];
			RowDecoder12 <= line1[2];
			RowDecoder13 <= line1[3];
			RowDecoder20 <= line2[0];
			RowDecoder21 <= line2[1];
			RowDecoder22 <= line2[2];
			RowDecoder23 <= line2[3];
			RowDecoder30 <= line3[0];
			RowDecoder31 <= line3[1];
			RowDecoder32 <= line3[2];
			RowDecoder33 <= line3[3];
			SC0[0] <= Next_SC0[0];
			SC1[0] <= Next_SC1[0];
			SC2[0] <= Next_SC2[0];		
			SC3[0] <= Next_SC3[0];
			SC0[1] <= Next_SC0[1];
			SC1[1] <= Next_SC1[1];
			SC2[1] <= Next_SC2[1];		
			SC3[1] <= Next_SC3[1];
			SC0[2] <= Next_SC0[2];
			SC1[2] <= Next_SC1[2];
			SC2[2] <= Next_SC2[2];		
			SC3[2] <= Next_SC3[2];
			SC0[3] <= Next_SC0[3];
			SC1[3] <= Next_SC1[3];
			SC2[3] <= Next_SC2[3];		
			SC3[3] <= Next_SC3[3];
		end
	end
		
	always @(*) begin
		conditionI=ActiveLanesE;
		busy0=constant_condition0;
		busy1=constant_condition1;
		busy2=constant_condition2;
		busy3=constant_condition3;
		condition0=constant_condition0;
		condition1=constant_condition1;
		condition2=constant_condition2;
		condition3=constant_condition3;
		Next_SC=SC;
		Allocated=4'h0;
		SC0Done = 1'b0;
		SC1Done = 1'b0;
		SC2Done = 1'b0;
		SC3Done = 1'b0;			
		OutAssigned0 = 1'b0;
		OutAssigned1 = 1'b0;
		OutAssigned2 = 1'b0;
		OutAssigned3 = 1'b0;
		Passed0 = 1'b0;
		Passed1 = 1'b0;
		Passed2 = 1'b0;
		Passed3 = 1'b0;
		write0=1'b0;
		write1=1'b0;		
		write2=1'b0;
		WR0=5'b00000;
		WR1=5'b00000;
		WR2E=5'b00000;
		WD0=32'h00000000;	
		WD1=32'h00000000;	
		ISequence0=32'h00000000;
		ISequence1=32'h00000000;
		ISequence2E=32'h00000000;
		ISequence3=32'h00000000;
		I0done=1'b0;
		I1done=1'b0;
		I2doneE=1'b0;
		I3done=1'b0;	

		LwAddrE=32'h00000000;
		SwAddrE=32'h00000000;
		DMemDataE=32'h00000000;
		DMemWriteE=1'b0;

		if(BrHappens) begin
			if(SC0[0]>SC0E) begin
				busy0[0]=1'b0;
				condition0[0]=1'b0;
			end
			if(SC0[1]>SC0E) begin
				busy0[1]=1'b0;
				condition0[1]=1'b0;
			end				
			if(SC0[2]>SC0E) begin
				busy0[2]=1'b0;
				condition0[2]=1'b0;
			end				
			if(SC0[3]>SC0E) begin
				busy0[3]=1'b0;
				condition0[3]=1'b0;
			end				
			if(SC1[0]>SC0E) begin
				busy1[0]=1'b0;
				condition1[0]=1'b0;
			end
			if(SC1[1]>SC0E) begin
				busy1[1]=1'b0;
				condition1[1]=1'b0;
			end	
			if(SC1[2]>SC0E) begin
				busy1[2]=1'b0;
				condition1[2]=1'b0;
			end
			if(SC1[3]>SC0E) begin
				busy1[3]=1'b0;
				condition1[3]=1'b0;
			end	
			if(SC2[0]>SC0E) begin
				busy2[0]=1'b0;
				condition2[0]=1'b0;
			end	
			if(SC2[1]>SC0E) begin
				busy2[1]=1'b0;
				condition2[1]=1'b0;
			end	
			if(SC2[2]>SC0E) begin
				busy2[2]=1'b0;
				condition2[2]=1'b0;
			end	
			if(SC2[3]>SC0E) begin
				busy2[3]=1'b0;
				condition2[3]=1'b0;
			end	
			if(SC3[0]>SC0E) begin
				busy3[0]=1'b0;
				condition3[0]=1'b0;
			end	
			if(SC3[1]>SC0E) begin
				busy3[1]=1'b0;
				condition3[1]=1'b0;
			end	
			if(SC3[2]>SC0E) begin
				busy3[2]=1'b0;
				condition3[2]=1'b0;
			end	
			if(SC3[3]>SC0E) begin
				busy3[3]=1'b0;
				condition3[3]=1'b0;
			end	
			if(SC1E>SC0E) begin
				conditionI[1]=1'b0;
			end	
			if(SC2E>SC0E) begin
				conditionI[2]=1'b0;
			end	
			if(SC3E>SC0E) begin
				conditionI[3]=1'b0;
			end						
		end
	
		if(!condition0[0])
			writeptr0=2'b00;
		else if(!condition0[1])
			writeptr0=2'b01;	
		else if(!condition0[2])
			writeptr0=2'b10;
		else
			writeptr0=2'b11;

		if(!condition1[0])
			writeptr1=2'b00;
		else if(!condition1[1])
			writeptr1=2'b01;	
		else if(!condition1[2])
			writeptr1=2'b10;
		else
			writeptr1=2'b11;

		if(!condition2[0])
			writeptr2=2'b00;
		else if(!condition2[1])
			writeptr2=2'b01;	
		else if(!condition2[2])
			writeptr2=2'b10;
		else
			writeptr2=2'b11;

		if(!condition3[0])
			writeptr3=2'b00;
		else if(!condition3[1])
			writeptr3=2'b01;	
		else if(!condition3[2])
			writeptr3=2'b10;
		else
			writeptr3=2'b11;
		
		if((SC0E==SC) && conditionI[0]) begin
			SC0Done = 1'b1;
			Allocated[0] = 1'b1;		
		end
		if((SC1E==SC) && conditionI[1]) begin
			SC0Done = 1'b1;
			Allocated[1] = 1'b1;
		end
		if((SC2E==SC) && conditionI[2]) begin
			SC0Done = 1'b1;
			Allocated[2] = 1'b1;		
		end		
		if((SC3E==SC) && conditionI[3]) begin
			SC0Done = 1'b1;
			Allocated[3] = 1'b1;
		end
				
		if((SC0[0]==SC) && condition0[0]) begin
			SC0Done = 1'b1;
			busy0[0] = 1'b0;
			Winner=4'h0;
		end	
		if((SC0[1]==SC) && condition0[1]) begin
			SC0Done = 1'b1;
			busy0[1] = 1'b0;
			Winner=4'h1;
		end	
		if((SC0[2]==SC) && condition0[2]) begin
			SC0Done = 1'b1;
			busy0[2] = 1'b0;
			Winner=4'h2;
		end	
		if((SC0[3]==SC) && condition0[3]) begin
			SC0Done = 1'b1;
			busy0[3] = 1'b0;
			Winner=4'h3;
		end	
		if((SC1[0]==SC) && condition1[0]) begin
			SC0Done = 1'b1;
			busy1[0] = 1'b0;
			Winner=4'h4;
		end	
		if((SC1[1]==SC) && condition1[1]) begin
			SC0Done = 1'b1;
			busy1[1] = 1'b0;
			Winner=4'h5;
		end	
		if((SC1[2]==SC) && condition1[2]) begin
			SC0Done = 1'b1;
			busy1[2] = 1'b0;
			Winner=4'h6;
		end	
		if((SC1[3]==SC) && condition1[3]) begin
			SC0Done = 1'b1;
			busy1[3] = 1'b0;
			Winner=4'h7;
		end	
		if((SC2[0]==SC) && condition2[0]) begin
			SC0Done = 1'b1;
			busy2[0] = 1'b0;
			Winner=4'h8;
		end	
		if((SC2[1]==SC) && condition2[1]) begin
			SC0Done = 1'b1;
			busy2[1] = 1'b0;
			Winner=4'h9;
		end	
		if((SC2[2]==SC) && condition2[2]) begin
			SC0Done = 1'b1;
			busy2[2] = 1'b0;
			Winner=4'hA;
		end	
		if((SC2[3]==SC) && condition2[3]) begin
			SC0Done = 1'b1;
			busy2[3] = 1'b0;
			Winner=4'hB;
		end	
		if((SC3[0]==SC) && condition3[0]) begin
			SC0Done = 1'b1;
			busy3[0] = 1'b0;
			Winner=4'hC;
		end	
		if((SC3[1]==SC) && condition3[1]) begin
			SC0Done = 1'b1;
			busy3[1] = 1'b0;
			Winner=4'hD;
		end	
		if((SC3[2]==SC) && condition3[2]) begin
			SC0Done = 1'b1;
			busy3[2] = 1'b0;
			Winner=4'hE;
		end	
		if((SC3[3]==SC) && condition3[3]) begin
			SC0Done = 1'b1;
			busy3[3] = 1'b0;
			Winner=4'hF;
		end	

		if(SC0Done) begin		
			Next_SC=SC+32'h00000001;
			if(Allocated==4'h0) begin
				case(Winner[3:2])
					4'h0: begin
						case (Winner[1:0])
							2'b00: begin
								write0=RowDecoder00[0];		
								ISequence0=SC0[0];
								WR0=RowDecoder00[70:66];
								if(RowDecoder00[33])			
									WD0=RowDecoder00[32:1];
								else
									WD0=RowDecoder00[65:34];								
							end
							2'b01: begin					
								write0=RowDecoder01[0];		
								ISequence0=SC0[1];
								WR0=RowDecoder01[70:66];									
								if(RowDecoder01[33])			
									WD0=RowDecoder01[32:1];
								else
									WD0=RowDecoder01[65:34];
							end
							2'b10: begin					
								write0=RowDecoder02[0];		
								ISequence0=SC0[2];
								WR0=RowDecoder02[70:66];
								if(RowDecoder02[33])			
									WD0=RowDecoder02[32:1];
								else
									WD0=RowDecoder02[65:34];
							end
							2'b11: begin					
								write0=RowDecoder03[0];		
								ISequence0=SC0[3];
								WR0=RowDecoder03[70:66];
								if(RowDecoder03[33])			
									WD0=RowDecoder03[32:1];
								else
									WD0=RowDecoder03[65:34];
							end
						endcase
						I0done=1'b1;
						OutAssigned0=1'b1;
					end
					4'h1: begin						
						case (Winner[1:0])
							2'b00: begin												
								ISequence1=SC1[0];
								WR1=RowDecoder10[69:65];
								if(RowDecoder10[32])			
									WD1=RowDecoder10[31:0];
								else
									WD1=RowDecoder10[64:33];							
							end
							2'b01: begin																	
								ISequence1=SC1[1];
								WR1=RowDecoder11[69:65];
								if(RowDecoder11[32])			
									WD1=RowDecoder11[31:0];
								else
									WD1=RowDecoder11[64:33];
							end
							2'b10: begin																
								ISequence1=SC1[2];
								WR1=RowDecoder12[69:65];
								if(RowDecoder12[32])			
									WD1=RowDecoder12[31:0];
								else
									WD1=RowDecoder12[64:33];
							end
							2'b11: begin																	
								ISequence1=SC1[3];
								WR1=RowDecoder13[69:65];
								if(RowDecoder13[32])			
									WD1=RowDecoder13[31:0];
								else
									WD1=RowDecoder13[64:33];
							end
						endcase
						write1=1'b1;
						I1done=1'b1;
						OutAssigned1=1'b1;
					end
					4'h2: begin
						case (Winner[1:0])
							2'b00: begin													
								ISequence2E=SC2[0];		
								WR2E=RowDecoder20[36:32];			
								LwAddrE=RowDecoder20[31:0];
							end
							2'b01: begin										
								ISequence2E=SC2[1];		
								WR2E=RowDecoder21[36:32];			
								LwAddrE=RowDecoder21[31:0];
							end
							2'b10: begin										
								ISequence2E=SC2[2];		
								WR2E=RowDecoder22[36:32];			
								LwAddrE=RowDecoder22[31:0];
							end
							2'b11: begin											
								ISequence2E=SC2[3];		
								WR2E=RowDecoder23[36:32];			
								LwAddrE=RowDecoder23[31:0];								
							end
						endcase
						write2=1'b1;
						I2doneE=1'b1;
						OutAssigned2=1'b1;
					end
					4'h3: begin
						case (Winner[1:0])
							2'b00: begin
								ISequence3=SC3[0];					
								SwAddrE=RowDecoder30[31:0];
								DMemDataE=RowDecoder30[63:32];													
							end
							2'b01: begin					
								ISequence3=SC3[1];					
								SwAddrE=RowDecoder31[31:0];
								DMemDataE=RowDecoder31[63:32];					
							end
							2'b10: begin					
								ISequence3=SC3[2];					
								SwAddrE=RowDecoder32[31:0];
								DMemDataE=RowDecoder32[63:32];					
							end
							2'b11: begin					
								ISequence3=SC3[3];					
								SwAddrE=RowDecoder33[31:0];
								DMemDataE=RowDecoder33[63:32];					
							end
						endcase
						DMemWriteE=1'b1;
						I3done=1'b1;
						OutAssigned3=1'b1;
					end			
				endcase
			end
			else begin
				if(Allocated[0]) begin	
					write0=RFWriteE;		
					ISequence0=SC0E;
					WR0=WriteReg0E;	
					if(LUI0E)			
						WD0=ShImm0E;
					else
						WD0=ALUOut0E;
					I0done=1'b1;
					OutAssigned0=1'b1;
					Passed0 = 1'b1;
				end
				if(Allocated[1]) begin
					write1=1'b1;				
					ISequence1=SC1E;
					WR1=WriteReg1E;
					if(LUI1E)			
						WD1=ShImm1E;
					else
						WD1=ALUOut1E;
					I1done=1'b1;
					OutAssigned1=1'b1;
					Passed1 = 1'b1;
				end
				if(Allocated[2]) begin
					ISequence2E=SC2E;		
					WR2E=WriteReg2E;			
					LwAddrE=LwAddr;
					write2=1'b1;						
					I2doneE=1'b1;
					OutAssigned2=1'b1;
					Passed2 = 1'b1;
				end
				if(Allocated[3]) begin
					ISequence3=SC3E;					
					SwAddrE=SwAddr;
					DMemDataE=WriteDataE;					
					DMemWriteE=1'b1;
					I3done=1'b1;
					OutAssigned3=1'b1;
					Passed3 = 1'b1;
				end						
			end
			
			Allocated=4'h0;
			
			if(!OutAssigned0) begin
				if((SC0E==Next_SC) && conditionI[0]) begin
					SC1Done = 1'b1;
					Allocated[0] = 1'b1;											
				end
				if((SC0[0]==Next_SC) && condition0[0]) begin
					SC1Done = 1'b1;
					busy0[0] = 1'b0;
					Winner=4'h0;
				end
				if((SC0[1]==Next_SC) && condition0[1]) begin
					SC1Done = 1'b1;
					busy0[1] = 1'b0;
					Winner=4'h1;
				end
				if((SC0[2]==Next_SC) && condition0[2]) begin
					SC1Done = 1'b1;
					busy0[2] = 1'b0;
					Winner=4'h2;
				end
				if((SC0[3]==Next_SC) && condition0[3]) begin
					SC1Done = 1'b1;
					busy0[3] = 1'b0;
					Winner=4'h3;
				end
			end
			
			if(!OutAssigned1) begin
				if((SC1E==Next_SC) && conditionI[1]) begin
					SC1Done = 1'b1;
					Allocated[1] = 1'b1;											
				end
				if((SC1[0]==Next_SC) && condition1[0]) begin
					SC1Done = 1'b1;
					busy1[0] = 1'b0;
					Winner=4'h4;
				end
				if((SC1[1]==Next_SC) && condition1[1]) begin
					SC1Done = 1'b1;
					busy1[1] = 1'b0;
					Winner=4'h5;
				end
				if((SC1[2]==Next_SC) && condition1[2]) begin
					SC1Done = 1'b1;
					busy1[2] = 1'b0;
					Winner=4'h6;
				end
				if((SC1[3]==Next_SC) && condition1[3]) begin
					SC1Done = 1'b1;
					busy1[3] = 1'b0;
					Winner=4'h7;
				end
			end
			
			if(!OutAssigned2) begin
				if((SC2E==Next_SC) && conditionI[2]) begin
					SC1Done = 1'b1;
					Allocated[2] = 1'b1;											
				end
				if((SC2[0]==Next_SC) && condition2[0]) begin
					SC1Done = 1'b1;
					busy2[0] = 1'b0;
					Winner=4'h8;
				end
				if((SC2[1]==Next_SC) && condition2[1]) begin
					SC1Done = 1'b1;
					busy2[1] = 1'b0;
					Winner=4'h9;
				end
				if((SC2[2]==Next_SC) && condition2[2]) begin
					SC1Done = 1'b1;
					busy2[2] = 1'b0;
					Winner=4'hA;
				end
				if((SC2[3]==Next_SC) && condition2[3]) begin
					SC1Done = 1'b1;
					busy2[3] = 1'b0;
					Winner=4'hB;
				end
			end
			
			if(!OutAssigned3) begin
				if((SC3E==Next_SC) && conditionI[3]) begin
					SC1Done = 1'b1;
					Allocated[3] = 1'b1;											
				end
				if((SC3[0]==Next_SC) && condition3[0]) begin
					SC1Done = 1'b1;
					busy3[0] = 1'b0;
					Winner=4'hC;
				end
				if((SC3[1]==Next_SC) && condition3[1]) begin
					SC1Done = 1'b1;
					busy3[1] = 1'b0;
					Winner=4'hD;
				end
				if((SC3[2]==Next_SC) && condition3[2]) begin
					SC1Done = 1'b1;
					busy3[2] = 1'b0;
					Winner=4'hE;
				end
				if((SC3[3]==Next_SC) && condition3[3]) begin
					SC1Done = 1'b1;
					busy3[3] = 1'b0;
					Winner=4'hF;
				end
			end
			
			if(SC1Done) begin		
				Next_SC=SC+32'h00000002;
				if(Allocated==4'h0) begin
					case(Winner[3:2])
						4'h0: begin						
							case (Winner[1:0])
								2'b00: begin
									write0=RowDecoder00[0];		
									ISequence0=SC0[0];
									WR0=RowDecoder00[70:66];
									if(RowDecoder00[33])			
										WD0=RowDecoder00[32:1];
									else
										WD0=RowDecoder00[65:34];								
								end
								2'b01: begin					
									write0=RowDecoder01[0];		
									ISequence0=SC0[1];
									WR0=RowDecoder01[70:66];									
									if(RowDecoder01[33])			
										WD0=RowDecoder01[32:1];
									else
										WD0=RowDecoder01[65:34];
								end
								2'b10: begin					
									write0=RowDecoder02[0];		
									ISequence0=SC0[2];
									WR0=RowDecoder02[70:66];
									if(RowDecoder02[33])			
										WD0=RowDecoder02[32:1];
									else
										WD0=RowDecoder02[65:34];
								end
								2'b11: begin					
									write0=RowDecoder03[0];		
									ISequence0=SC0[3];
									WR0=RowDecoder03[70:66];
									if(RowDecoder03[33])			
										WD0=RowDecoder03[32:1];
									else
										WD0=RowDecoder03[65:34];
								end
							endcase
							I0done=1'b1;
							OutAssigned0=1'b1;
						end
						4'h1: begin						
							case (Winner[1:0])
								2'b00: begin												
									ISequence1=SC1[0];
									WR1=RowDecoder10[69:65];
									if(RowDecoder10[32])			
										WD1=RowDecoder10[31:0];
									else
										WD1=RowDecoder10[64:33];							
								end
								2'b01: begin																	
									ISequence1=SC1[1];
									WR1=RowDecoder11[69:65];
									if(RowDecoder11[32])			
										WD1=RowDecoder11[31:0];
									else
										WD1=RowDecoder11[64:33];
								end
								2'b10: begin																
									ISequence1=SC1[2];
									WR1=RowDecoder12[69:65];
									if(RowDecoder12[32])			
										WD1=RowDecoder12[31:0];
									else
										WD1=RowDecoder12[64:33];
								end
								2'b11: begin																	
									ISequence1=SC1[3];
									WR1=RowDecoder13[69:65];
									if(RowDecoder13[32])			
										WD1=RowDecoder13[31:0];
									else
										WD1=RowDecoder13[64:33];
								end
							endcase
							write1=1'b1;
							I1done=1'b1;
							OutAssigned1=1'b1;
						end
						4'h2: begin
							case (Winner[1:0])
								2'b00: begin													
									ISequence2E=SC2[0];		
									WR2E=RowDecoder20[36:32];			
									LwAddrE=RowDecoder20[31:0];
								end
								2'b01: begin										
									ISequence2E=SC2[1];		
									WR2E=RowDecoder21[36:32];			
									LwAddrE=RowDecoder21[31:0];
								end
								2'b10: begin										
									ISequence2E=SC2[2];		
									WR2E=RowDecoder22[36:32];			
									LwAddrE=RowDecoder22[31:0];
								end
								2'b11: begin											
									ISequence2E=SC2[3];		
									WR2E=RowDecoder23[36:32];			
									LwAddrE=RowDecoder23[31:0];								
								end
							endcase
							write2=1'b1;
							I2doneE=1'b1;
							OutAssigned2=1'b1;
						end
						4'h3: begin
							case (Winner[1:0])
								2'b00: begin
									ISequence3=SC3[0];					
									SwAddrE=RowDecoder30[31:0];
									DMemDataE=RowDecoder30[63:32];													
								end
								2'b01: begin					
									ISequence3=SC3[1];					
									SwAddrE=RowDecoder31[31:0];
									DMemDataE=RowDecoder31[63:32];					
								end
								2'b10: begin					
									ISequence3=SC3[2];					
									SwAddrE=RowDecoder32[31:0];
									DMemDataE=RowDecoder32[63:32];					
								end
								2'b11: begin					
									ISequence3=SC3[3];					
									SwAddrE=RowDecoder33[31:0];
									DMemDataE=RowDecoder33[63:32];					
								end
							endcase
							DMemWriteE=1'b1;
							I3done=1'b1;
							OutAssigned3=1'b1;
						end			
					endcase
				end
				else begin
					if(Allocated[0]) begin
						write0=RFWriteE;		
						ISequence0=SC0E;
						WR0=WriteReg0E;	
						if(LUI0E)			
							WD0=ShImm0E;
						else
							WD0=ALUOut0E;
						I0done=1'b1;
						OutAssigned0=1'b1;
						Passed0 = 1'b1;
					end
					if(Allocated[1]) begin
						write1=1'b1;				
						ISequence1=SC1E;
						WR1=WriteReg1E;
						if(LUI1E)			
							WD1=ShImm1E;
						else
							WD1=ALUOut1E;
						I1done=1'b1;
						OutAssigned1=1'b1;
						Passed1 = 1'b1;
					end
					if(Allocated[2]) begin
						ISequence2E=SC2E;		
						WR2E=WriteReg2E;			
						LwAddrE=LwAddr;
						write2=1'b1;						
						I2doneE=1'b1;
						OutAssigned2=1'b1;
						Passed2 = 1'b1;
					end
					if(Allocated[3]) begin
						ISequence3=SC3E;					
						SwAddrE=SwAddr;
						DMemDataE=WriteDataE;					
						DMemWriteE=1'b1;
						I3done=1'b1;
						OutAssigned3=1'b1;
						Passed3 = 1'b1;
					end						
				end
			
				Allocated=4'h0;
				
				if(!OutAssigned0) begin
					if((SC0E==Next_SC) && conditionI[0]) begin
						SC2Done = 1'b1;
						Allocated[0] = 1'b1;											
					end
					if((SC0[0]==Next_SC) && condition0[0]) begin
						SC2Done = 1'b1;
						busy0[0] = 1'b0;
						Winner=4'h0;
					end
					if((SC0[1]==Next_SC) && condition0[1]) begin
						SC2Done = 1'b1;
						busy0[1] = 1'b0;
						Winner=4'h1;
					end
					if((SC0[2]==Next_SC) && condition0[2]) begin
						SC2Done = 1'b1;
						busy0[2] = 1'b0;
						Winner=4'h2;
					end
					if((SC0[3]==Next_SC) && condition0[3]) begin
						SC2Done = 1'b1;
						busy0[3] = 1'b0;
						Winner=4'h3;
					end
				end
				
				if(!OutAssigned1) begin
					if((SC1E==Next_SC) && conditionI[1]) begin
						SC2Done = 1'b1;
						Allocated[1] = 1'b1;											
					end
					if((SC1[0]==Next_SC) && condition1[0]) begin
						SC2Done = 1'b1;
						busy1[0] = 1'b0;
						Winner=4'h4;
					end
					if((SC1[1]==Next_SC) && condition1[1]) begin
						SC2Done = 1'b1;
						busy1[1] = 1'b0;
						Winner=4'h5;
					end
					if((SC1[2]==Next_SC) && condition1[2]) begin
						SC2Done = 1'b1;
						busy1[2] = 1'b0;
						Winner=4'h6;
					end
					if((SC1[3]==Next_SC) && condition1[3]) begin
						SC2Done = 1'b1;
						busy1[3] = 1'b0;
						Winner=4'h7;
					end
				end
				
				if(!OutAssigned2) begin
					if((SC2E==Next_SC) && conditionI[2]) begin
						SC2Done = 1'b1;
						Allocated[2] = 1'b1;											
					end
					if((SC2[0]==Next_SC) && condition2[0]) begin
						SC2Done = 1'b1;
						busy2[0] = 1'b0;
						Winner=4'h8;
					end
					if((SC2[1]==Next_SC) && condition2[1]) begin
						SC2Done = 1'b1;
						busy2[1] = 1'b0;
						Winner=4'h9;
					end
					if((SC2[2]==Next_SC) && condition2[2]) begin
						SC2Done = 1'b1;
						busy2[2] = 1'b0;
						Winner=4'hA;
					end
					if((SC2[3]==Next_SC) && condition2[3]) begin
						SC2Done = 1'b1;
						busy2[3] = 1'b0;
						Winner=4'hB;
					end
				end
				
				if(!OutAssigned3) begin
					if((SC3E==Next_SC) && conditionI[3]) begin
						SC2Done = 1'b1;
						Allocated[3] = 1'b1;											
					end
					if((SC3[0]==Next_SC) && condition3[0]) begin
						SC2Done = 1'b1;
						busy3[0] = 1'b0;
						Winner=4'hC;
					end
					if((SC3[1]==Next_SC) && condition3[1]) begin
						SC2Done = 1'b1;
						busy3[1] = 1'b0;
						Winner=4'hD;
					end
					if((SC3[2]==Next_SC) && condition3[2]) begin
						SC2Done = 1'b1;
						busy3[2] = 1'b0;
						Winner=4'hE;
					end
					if((SC3[3]==Next_SC) && condition3[3]) begin
						SC2Done = 1'b1;
						busy3[3] = 1'b0;
						Winner=4'hF;
					end
				end
			
				if(SC2Done) begin		
					Next_SC=SC+32'h00000003;
					if(Allocated==4'h0) begin
						case(Winner[3:2])
							4'h0: begin
								case (Winner[1:0])
									2'b00: begin
										write0=RowDecoder00[0];		
										ISequence0=SC0[0];
										WR0=RowDecoder00[70:66];
										if(RowDecoder00[33])			
											WD0=RowDecoder00[32:1];
										else
											WD0=RowDecoder00[65:34];								
									end
									2'b01: begin					
										write0=RowDecoder01[0];		
										ISequence0=SC0[1];
										WR0=RowDecoder01[70:66];									
										if(RowDecoder01[33])			
											WD0=RowDecoder01[32:1];
										else
											WD0=RowDecoder01[65:34];
									end
									2'b10: begin					
										write0=RowDecoder02[0];		
										ISequence0=SC0[2];
										WR0=RowDecoder02[70:66];
										if(RowDecoder02[33])			
											WD0=RowDecoder02[32:1];
										else
											WD0=RowDecoder02[65:34];
									end
									2'b11: begin					
										write0=RowDecoder03[0];		
										ISequence0=SC0[3];
										WR0=RowDecoder03[70:66];
										if(RowDecoder03[33])			
											WD0=RowDecoder03[32:1];
										else
											WD0=RowDecoder03[65:34];
									end
								endcase
								I0done=1'b1;
								OutAssigned0=1'b1;
							end
							4'h1: begin						
								case (Winner[1:0])
									2'b00: begin												
										ISequence1=SC1[0];
										WR1=RowDecoder10[69:65];
										if(RowDecoder10[32])			
											WD1=RowDecoder10[31:0];
										else
											WD1=RowDecoder10[64:33];							
									end
									2'b01: begin																	
										ISequence1=SC1[1];
										WR1=RowDecoder11[69:65];
										if(RowDecoder11[32])			
											WD1=RowDecoder11[31:0];
										else
											WD1=RowDecoder11[64:33];
									end
									2'b10: begin																
										ISequence1=SC1[2];
										WR1=RowDecoder12[69:65];
										if(RowDecoder12[32])			
											WD1=RowDecoder12[31:0];
										else
											WD1=RowDecoder12[64:33];
									end
									2'b11: begin																	
										ISequence1=SC1[3];
										WR1=RowDecoder13[69:65];
										if(RowDecoder13[32])			
											WD1=RowDecoder13[31:0];
										else
											WD1=RowDecoder13[64:33];
									end
								endcase
								write1=1'b1;
								I1done=1'b1;
								OutAssigned1=1'b1;
							end
							4'h2: begin
								case (Winner[1:0])
									2'b00: begin													
										ISequence2E=SC2[0];		
										WR2E=RowDecoder20[36:32];			
										LwAddrE=RowDecoder20[31:0];
									end
									2'b01: begin										
										ISequence2E=SC2[1];		
										WR2E=RowDecoder21[36:32];			
										LwAddrE=RowDecoder21[31:0];
									end
									2'b10: begin										
										ISequence2E=SC2[2];		
										WR2E=RowDecoder22[36:32];			
										LwAddrE=RowDecoder22[31:0];
									end
									2'b11: begin											
										ISequence2E=SC2[3];		
										WR2E=RowDecoder23[36:32];			
										LwAddrE=RowDecoder23[31:0];								
									end
								endcase
								write2=1'b1;
								I2doneE=1'b1;
								OutAssigned2=1'b1;
							end
							4'h3: begin
								case (Winner[1:0])
									2'b00: begin
										ISequence3=SC3[0];					
										SwAddrE=RowDecoder30[31:0];
										DMemDataE=RowDecoder30[63:32];													
									end
									2'b01: begin					
										ISequence3=SC3[1];					
										SwAddrE=RowDecoder31[31:0];
										DMemDataE=RowDecoder31[63:32];					
									end
									2'b10: begin					
										ISequence3=SC3[2];					
										SwAddrE=RowDecoder32[31:0];
										DMemDataE=RowDecoder32[63:32];					
									end
									2'b11: begin					
										ISequence3=SC3[3];					
										SwAddrE=RowDecoder33[31:0];
										DMemDataE=RowDecoder33[63:32];					
									end
								endcase
								DMemWriteE=1'b1;
								I3done=1'b1;
								OutAssigned3=1'b1;
							end			
						endcase
					end
					else begin
						if(Allocated[0]) begin
	
							write0=RFWriteE;		
							ISequence0=SC0E;
							WR0=WriteReg0E;	
							if(LUI0E)			
								WD0=ShImm0E;
							else
								WD0=ALUOut0E;
							I0done=1'b1;
							OutAssigned0=1'b1;
							Passed0 = 1'b1;
						end
						if(Allocated[1]) begin
							write1=1'b1;				
							ISequence1=SC1E;
							WR1=WriteReg1E;
							if(LUI1E)			
								WD1=ShImm1E;
							else
								WD1=ALUOut1E;
							I1done=1'b1;
							OutAssigned1=1'b1;
							Passed1 = 1'b1;
						end
						if(Allocated[2]) begin
							ISequence2E=SC2E;		
							WR2E=WriteReg2E;			
							LwAddrE=LwAddr;
							write2=1'b1;						
							I2doneE=1'b1;
							OutAssigned2=1'b1;
							Passed2 = 1'b1;
						end
						if(Allocated[3]) begin
							ISequence3=SC3E;					
							SwAddrE=SwAddr;
							DMemDataE=WriteDataE;					
							DMemWriteE=1'b1;
							I3done=1'b1;
							OutAssigned3=1'b1;
							Passed3 = 1'b1;
						end						
					end
				
					Allocated=4'h0;
					
					if(!OutAssigned0) begin
						if((SC0E==Next_SC) && conditionI[0]) begin
							SC3Done = 1'b1;
							Allocated[0] = 1'b1;											
						end
						if((SC0[0]==Next_SC) && condition0[0]) begin
							SC3Done = 1'b1;
							busy0[0] = 1'b0;
							Winner=4'h0;
						end
						if((SC0[1]==Next_SC) && condition0[1]) begin
							SC3Done = 1'b1;
							busy0[1] = 1'b0;
							Winner=4'h1;
						end
						if((SC0[2]==Next_SC) && condition0[2]) begin
							SC3Done = 1'b1;
							busy0[2] = 1'b0;
							Winner=4'h2;
						end
						if((SC0[3]==Next_SC) && condition0[3]) begin
							SC3Done = 1'b1;
							busy0[3] = 1'b0;
							Winner=4'h3;
						end
					end
					
					if(!OutAssigned1) begin
						if((SC1E==Next_SC) && conditionI[1]) begin
							SC3Done = 1'b1;
							Allocated[1] = 1'b1;											
						end
						if((SC1[0]==Next_SC) && condition1[0]) begin
							SC3Done = 1'b1;
							busy1[0] = 1'b0;
							Winner=4'h4;
						end
						if((SC1[1]==Next_SC) && condition1[1]) begin
							SC3Done = 1'b1;
							busy1[1] = 1'b0;
							Winner=4'h5;
						end
						if((SC1[2]==Next_SC) && condition1[2]) begin
							SC3Done = 1'b1;
							busy1[2] = 1'b0;
							Winner=4'h6;
						end
						if((SC1[3]==Next_SC) && condition1[3]) begin
							SC3Done = 1'b1;
							busy1[3] = 1'b0;
							Winner=4'h7;
						end
					end
					
					if(!OutAssigned2) begin
						if((SC2E==Next_SC) && conditionI[2]) begin
							SC3Done = 1'b1;
							Allocated[2] = 1'b1;											
						end
						if((SC2[0]==Next_SC) && condition2[0]) begin
							SC3Done = 1'b1;
							busy2[0] = 1'b0;
							Winner=4'h8;
						end
						if((SC2[1]==Next_SC) && condition2[1]) begin
							SC3Done = 1'b1;
							busy2[1] = 1'b0;
							Winner=4'h9;
						end
						if((SC2[2]==Next_SC) && condition2[2]) begin
							SC3Done = 1'b1;
							busy2[2] = 1'b0;
							Winner=4'hA;
						end
						if((SC2[3]==Next_SC) && condition2[3]) begin
							SC3Done = 1'b1;
							busy2[3] = 1'b0;
							Winner=4'hB;
						end
					end
					
					if(!OutAssigned3) begin
						if((SC3E==Next_SC) && conditionI[3]) begin
							SC3Done = 1'b1;
							Allocated[3] = 1'b1;											
						end
						if((SC3[0]==Next_SC) && condition3[0]) begin
							SC3Done = 1'b1;
							busy3[0] = 1'b0;
							Winner=4'hC;
						end
						if((SC3[1]==Next_SC) && condition3[1]) begin
							SC3Done = 1'b1;
							busy3[1] = 1'b0;
							Winner=4'hD;
						end
						if((SC3[2]==Next_SC) && condition3[2]) begin
							SC3Done = 1'b1;
							busy3[2] = 1'b0;
							Winner=4'hE;
						end
						if((SC3[3]==Next_SC) && condition3[3]) begin
							SC3Done = 1'b1;
							busy3[3] = 1'b0;
							Winner=4'hF;
						end
					end
					
					if(SC3Done) begin		
						Next_SC=SC+32'h00000004;
						if(Allocated==4'h0) begin
							case(Winner[3:2])
								4'h0: begin
									case (Winner[1:0])
										2'b00: begin
											write0=RowDecoder00[0];		
											ISequence0=SC0[0];
											WR0=RowDecoder00[70:66];
											if(RowDecoder00[33])			
												WD0=RowDecoder00[32:1];
											else
												WD0=RowDecoder00[65:34];								
										end
										2'b01: begin					
											write0=RowDecoder01[0];		
											ISequence0=SC0[1];
											WR0=RowDecoder01[70:66];									
											if(RowDecoder01[33])			
												WD0=RowDecoder01[32:1];
											else
												WD0=RowDecoder01[65:34];
										end
										2'b10: begin					
											write0=RowDecoder02[0];		
											ISequence0=SC0[2];
											WR0=RowDecoder02[70:66];
											if(RowDecoder02[33])			
												WD0=RowDecoder02[32:1];
											else
												WD0=RowDecoder02[65:34];
										end
										2'b11: begin					
											write0=RowDecoder03[0];		
											ISequence0=SC0[3];
											WR0=RowDecoder03[70:66];
											if(RowDecoder03[33])			
												WD0=RowDecoder03[32:1];
											else
												WD0=RowDecoder03[65:34];
										end
									endcase
									I0done=1'b1;
									OutAssigned0=1'b1;
								end
								4'h1: begin						
									case (Winner[1:0])
										2'b00: begin												
											ISequence1=SC1[0];
											WR1=RowDecoder10[69:65];
											if(RowDecoder10[32])			
												WD1=RowDecoder10[31:0];
											else
												WD1=RowDecoder10[64:33];							
										end
										2'b01: begin																	
											ISequence1=SC1[1];
											WR1=RowDecoder11[69:65];
											if(RowDecoder11[32])			
												WD1=RowDecoder11[31:0];
											else
												WD1=RowDecoder11[64:33];
										end
										2'b10: begin																
											ISequence1=SC1[2];
											WR1=RowDecoder12[69:65];
											if(RowDecoder12[32])			
												WD1=RowDecoder12[31:0];
											else
												WD1=RowDecoder12[64:33];
										end
										2'b11: begin																	
											ISequence1=SC1[3];
											WR1=RowDecoder13[69:65];
											if(RowDecoder13[32])			
												WD1=RowDecoder13[31:0];
											else
												WD1=RowDecoder13[64:33];
										end
									endcase
									write1=1'b1;
									I1done=1'b1;
									OutAssigned1=1'b1;
								end
								4'h2: begin
									case (Winner[1:0])
										2'b00: begin													
											ISequence2E=SC2[0];		
											WR2E=RowDecoder20[36:32];			
											LwAddrE=RowDecoder20[31:0];
										end
										2'b01: begin										
											ISequence2E=SC2[1];		
											WR2E=RowDecoder21[36:32];			
											LwAddrE=RowDecoder21[31:0];
										end
										2'b10: begin										
											ISequence2E=SC2[2];		
											WR2E=RowDecoder22[36:32];			
											LwAddrE=RowDecoder22[31:0];
										end
										2'b11: begin											
											ISequence2E=SC2[3];		
											WR2E=RowDecoder23[36:32];			
											LwAddrE=RowDecoder23[31:0];								
										end
									endcase
									write2=1'b1;
									I2doneE=1'b1;
									OutAssigned2=1'b1;
								end
								4'h3: begin
									case (Winner[1:0])
										2'b00: begin
											ISequence3=SC3[0];					
											SwAddrE=RowDecoder30[31:0];
											DMemDataE=RowDecoder30[63:32];													
										end
										2'b01: begin					
											ISequence3=SC3[1];					
											SwAddrE=RowDecoder31[31:0];
											DMemDataE=RowDecoder31[63:32];					
										end
										2'b10: begin					
											ISequence3=SC3[2];					
											SwAddrE=RowDecoder32[31:0];
											DMemDataE=RowDecoder32[63:32];					
										end
										2'b11: begin					
											ISequence3=SC3[3];					
											SwAddrE=RowDecoder33[31:0];
											DMemDataE=RowDecoder33[63:32];					
										end
									endcase
									DMemWriteE=1'b1;
									I3done=1'b1;
									OutAssigned3=1'b1;
								end			
							endcase
						end
						else begin
							if(Allocated[0]) begin	
								write0=RFWriteE;		
								ISequence0=SC0E;
								WR0=WriteReg0E;	
								if(LUI0E)			
									WD0=ShImm0E;
								else
									WD0=ALUOut0E;
								I0done=1'b1;
								OutAssigned0=1'b1;
								Passed0 = 1'b1;
							end
							if(Allocated[1]) begin
								write1=1'b1;				
								ISequence1=SC1E;
								WR1=WriteReg1E;
								if(LUI1E)			
									WD1=ShImm1E;
								else
									WD1=ALUOut1E;
								I1done=1'b1;
								OutAssigned1=1'b1;
								Passed1 = 1'b1;
							end
							if(Allocated[2]) begin
								ISequence2E=SC2E;		
								WR2E=WriteReg2E;			
								LwAddrE=LwAddr;
								write2=1'b1;						
								I2doneE=1'b1;
								OutAssigned2=1'b1;
								Passed2 = 1'b1;
							end
							if(Allocated[3]) begin
								ISequence3=SC3E;					
								SwAddrE=SwAddr;
								DMemDataE=WriteDataE;					
								DMemWriteE=1'b1;
								I3done=1'b1;
								OutAssigned3=1'b1;
								Passed3 = 1'b1;
							end						
						end						
					end
				end
			end
		end

		if(!Passed0 && conditionI[0]) begin
			line0[writeptr0]={WriteReg0E, ALUOut0E, LUI0E, ShImm0E, RFWriteE};
			Next_SC0[writeptr0]=SC0E;
			busy0[writeptr0]=1'b1;
		end	
		if(!Passed1 && conditionI[1]) begin
			line1[writeptr1]={WriteReg1E, ALUOut1E, LUI1E, ShImm1E};
			Next_SC1[writeptr1]=SC1E;
			busy1[writeptr1]=1'b1;
		end
		if(!Passed2 && conditionI[2]) begin
			line2[writeptr2]={WriteReg2E, LwAddr};
			Next_SC2[writeptr2]=SC2E;
			busy2[writeptr2]=1'b1;
		end
		if(!Passed3 && conditionI[3]) begin
			line3[writeptr3]={WriteDataE, SwAddr};
			Next_SC3[writeptr3]=SC3E;
			busy3[writeptr3]=1'b1;
		end
		
	end	
		
endmodule

//========================================================== 
//					EX/MEM Pipeline Register
//========================================================== 

module EXMEMRegister(
	input clk,
	input clr,	
	input [31:0] ISequence2E,	
	input I2doneE,
	input Write2E,
	input [4:0] WR2E,
	input [31:0] LwAddrE,	
	input [31:0] SwAddrE,	
	input [31:0] DMemDataE,
	input DMemWriteE,	
	output reg [31:0] ISequence2,		
	output reg I2done,
	output reg write2,
	output reg [4:0] WR2,
	output reg [31:0] LwAddrM,	
	output reg [31:0] SwAddrM,
	output reg [31:0] DMemDataM,
	output reg DMemWriteM
);
	
	always @(posedge clk) begin
		if(clr) begin
			ISequence2<=32'h00000000;
			I2done<=1'b0;
			write2<=1'b0;
			WR2 <= 5'b00000;
			LwAddrM<=32'h00000000;
			SwAddrM<=32'h00000000;
			DMemDataM<=32'h00000000;
			DMemWriteM<=1'b0;
		end
		else begin
			ISequence2<=ISequence2E;
			I2done<=I2doneE;
			write2<=Write2E;
			WR2 <= WR2E;
			LwAddrM<=LwAddrE;
			SwAddrM<=SwAddrE;
			DMemDataM<=DMemDataE;
			DMemWriteM<=DMemWriteE;
		end		
	end
	
endmodule



