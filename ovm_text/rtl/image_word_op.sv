///////////////////////////////////////////////////////////////////////////////
//  Copyright (c) 
//  2010 Intel Corporation, all rights reserved.
//
//  THIS PROGRAM IS AN UNPUBLISHED WORK FULLY 
//  PROTECTED BY COPYRIGHT LAWS AND IS CONSIDERED A 
//  TRADE SECRET BELONGING TO THE INTEL CORPORATION.
///////////////////////////////////////////////////////////////////////////////
// 
//  Author  : Joel Feldman    
//  Email   : joel.d.feldman@intel.com
//  Date    : October 1, 2010
//  Description: image singe-word (4-byte) transform 
//                Performs these pixel operations 32-bits at a time:
//                      Darken, lighten, invert, XOR-checksum
//               
///////////////////////////////////////////////////////////////////////////////
`define PIXELOP_DARK 2'b00
`define PIXELOP_LITE 2'b01
`define PIXELOP_INVT 2'b10
`define PIXELOP_CKSM 2'b11


module image_word_op (
  input [1:0] operate,
  input [31:0] datain,
  output [31:0] dataout
);

logic [7:0] outbyte0, outbyte1, outbyte2, outbyte3;

assign dataout = {outbyte0, outbyte1, outbyte2, outbyte3};

always @(operate or datain)
begin
  casex (operate) //synopsys full_case_parallel_case
	`PIXELOP_DARK :
	   begin 
	     outbyte0 = datain[7:0] - 8'h1f;
	     outbyte1 = datain[15:8] - 8'h1f;
	     outbyte2 = datain[23:16] - 8'h1f;
	     outbyte3 = datain[31:24] - 8'h1f;	   
	   end
	`PIXELOP_LITE : 
	   begin 
	     outbyte0 = datain[7:0] + 8'h1f;
	     outbyte1 = datain[15:8] + 8'h1f;
	     outbyte2 = datain[23:16] + 8'h1f;
	     outbyte3 = datain[31:24] + 8'h1f;	   
	   end
	`PIXELOP_INVT :
	   begin 
	     outbyte0 = 8'hff - datain[7:0];
	     outbyte1 = 8'hff - datain[15:8];
	     outbyte2 = 8'hff - datain[23:16];
	     outbyte3 = 8'hff - datain[31:24];	   
	   end
	`PIXELOP_CKSM :
	   begin 
	     outbyte3 = datain[7:0] ^ datain[15:8] ^ datain[23:16] ^ datain[31:24];
	     outbyte1 = 8'h0;
	     outbyte2 = 8'h0;
	     outbyte0 = 8'h0;     
	   end	
   endcase
end


endmodule
