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
//  Description: image 4-pixel average value calculator 
//              
//               
///////////////////////////////////////////////////////////////////////////////

module image_byte_avg (
input [7:0] byte1,
input [7:0] byte2,
input [7:0] byte3,
input [7:0] byte4,
output [7:0] outbyte
);

//logic [7:0] byte1;
//logic [7:0] byte2;
//logic [7:0] byte3;
//logic [7:0] byte4;
//logic [7:0] outbyte;



logic [9:0]  finalsum;
	   
//perform 2x2 pixel averaging
// average byte1/byte2  &  byte3/byte4 
// then average the results

// avg(ff,ff) = ff
// avg(00,00) = 00
// avg(ff,00) = 7f
// avg(00,ff) = 7f
// avg(18,fc) = 8a  0001_1000  1111_1100  = 1000_10100     1000_1010
// avg(ab,20) = 65  1010_1011  0010_0000  = 0110_01011     0110_0101

//full-adder

assign finalsum = byte1 + byte2 + byte3 + byte4;

assign outbyte = finalsum[8:2];

endmodule



