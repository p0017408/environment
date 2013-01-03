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
//  Description: image transform block (top-level)
//               Simple example of an 8-bit 16x16 image array that can
//               store an image and perform basic transforms
//               
///////////////////////////////////////////////////////////////////////////////


`include "rtl/image_xform_defines.sv"

module image_xform (
   input clk,
   input rst_b,
   input [5:0] addr,
   input [31:0] wdata,
   output [31:0] rdata,
   input [3:0] op,
   input int_ack,
   output done_int 

);


//image array is 16x16 (256) 8-bit pixels
//handle it as 16 rows of 4 32-bit words with row 0 on the bottom

        
//           -word60- -word61- -word62- -word63-
//     rowF: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row F (16th row)
//     rowE: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row E
//     rowD: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row D
//     rowC: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row C
//     rowB: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row B
//     rowA: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row A
//     row9: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row 9
//     row8: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row 8
//     row7: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row 7
//     row6: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row 6
//     row5: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row 5
//     row4: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row 4
//     row3: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row 3
//     row2: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row 2
//     row1: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row 1
//     row0: 0 1 2 3  4 5 6 7  8 9 A B  C D E F  <-byte# in row 0
//           -word0-  -word1-  -word2-  -word3-
//           ^ ^ ^ ^                          ^
// column0 --| | | |                          |
//  column1 ---| | |                 columnF--|
//   column2-----| |
//    column3------|
 
 

  



logic [31:0] image_mem[63:0];
logic [31:0] current_mem_word;

// image scratchpad used for entire row operations
// handle it as 16 columns of 128-bits (16 pixels) 
// or alternatively 16 rows of 128-bits (16 pixels)

logic [0:127] image_scratch[15:0];

logic [31:0] image_scratch_word;
logic [5:0] target_word_map;

logic [3:0] scratch_column;
logic [3:0] scratch_row;
logic [3:0] rr0;  //rotate operation scratch write row0
logic [3:0] rr1;  //rotate operation scratch write row1
logic [3:0] rr2;  //rotate operation scratch write row2
logic [3:0] rr3;  //rotate operation scratch write row3



logic [3:0] scratch_row_opposite;

logic [3:0] zi_scratch_row;
logic [3:0] zi_scratch_row_next;
logic [3:0] zo_scratch_row;

logic [31:0] zoomout_bottom_word;
logic [31:0] zoomout_top_word;
logic [7:0] zoomout_byte1, zoomout_byte2;

logic [31:0] stat_reg;

reg [31:0] rdata1;
assign rdata = rdata1;


//counters
logic [6:0] cntr128;
logic [5:0] cntr64;   //use this as the 32-bit word counter for memory read/writes when processing the entire memory
logic [5:0] cntr64_inv;   //inverse of cntr64 (cntr64 == 0, cntr64_inv <= 3f)

logic [1:0] pixel_op;  //2-bit code for pixel operation used by "image_word_op"
logic [31:0] word_op_result;

//Flags & enables
logic byte_op;
logic longword_op;
logic ctr_incr;
logic writeback;
reg done_int1;
assign done_int = done_int1;
logic busy;

logic zoomin_wordgrab;
logic [0:127] zoomout_fill128;
logic rotate_op;

integer i;
integer k;



//pixel operations that can be done 32-bits at a time and take 64 cycles
assign byte_op = (op == `DARKEN) || (op == `LIGHTEN) || (op == `INVERTALL) || (op == `CHECKSUM);

//multi-pixel operations and take 128 cycles
assign longword_op = (op == `ROTCLKWISE) || (op == `ROTCNTCLKWISE) || (op == `ZOOMIN) || (op == `ZOOMOUT);
assign rotate_op = (op == `ROTCLKWISE) || (op == `ROTCNTCLKWISE);

//processed data is ready to be written back to main image memory
assign writeback = longword_op && cntr128[6];


//STATE MACHINE
enum logic [1:0] {STAT_IDLE, STAT_BUSY, STAT_DONE, STAT_TEST} current_state, next_state;

always_comb 
begin

   //Done interrupt acknowledge
   if (current_state == STAT_DONE)
   begin
     if (int_ack)
       next_state = STAT_IDLE;
     else
        next_state = STAT_DONE;
   end

   //Idle with new operation
   else if (current_state == STAT_IDLE)
   begin
     ctr_incr = 1'b0;
     if(op == `NOP)
      next_state = STAT_IDLE;
      //always go busy for at least a cycle if not doing a NOP operation
    else  
     next_state = STAT_BUSY;
   end     
   
   //Already busy
   else if (current_state == STAT_BUSY)
     begin
 	casex (op) //synopsys full_case parallel_case
	  `LOADMEM, `READMEM : 
	    begin
	       next_state = STAT_DONE;
	       ctr_incr = 1'b0;
	    end
	  
	   `DARKEN, `LIGHTEN, `CHECKSUM, `INVERTALL, `CHECKERBOARD: 
	      if (cntr64 < 6'b111111)
	       begin
	        next_state = STAT_BUSY;
		ctr_incr = 1'b1;
	       end
	      else
	       begin
	         next_state = STAT_DONE;
		 ctr_incr = 1'b0;
	       end
	  	
	  `ALLBLACK, `ALLWHITE, `ALLGREY :
	   begin
	     next_state = STAT_DONE;
	     ctr_incr = 1'b0;
	   end  
	  
	  `ROTCLKWISE,`ROTCNTCLKWISE, `ZOOMOUT, `ZOOMIN	:
	    if (cntr128 < 7'b1111111)
	      begin
	        next_state = STAT_BUSY;
		ctr_incr = 1'b1;
	      end
	     else 
	       begin
	         next_state = STAT_DONE;
		 ctr_incr = 1'b0;
	       end
	 
	default : 
	  begin
	    next_state = current_state;    
	    ctr_incr = 1'b1;
	  end
	endcase               
     end 
    else  //reserved state STAT_TEST -- requires reset to exit
      begin
        next_state = current_state;
	ctr_incr = 1'b0;
      end 
end //always_comb


always @(posedge clk or negedge rst_b)
begin
 if (~rst_b)
     current_state <= STAT_IDLE;
 else
     current_state <= next_state;
end 


assign busy = (current_state == STAT_BUSY);

// end of state machine
/////////////////////////



always @(posedge clk or negedge rst_b)
begin
  if (~rst_b)
     done_int1 <= 1'b0;
  else if (int_ack)
     done_int1 <= 1'b0; 
  else if (busy & (next_state == STAT_DONE))
     done_int1 <= 1'b1;

end


/////////////////////////////////////////////
//Status register:
// Bit 0:1:  Statemachine
// Bit 2:    writing to memory
// Bit 3:    byte operation (64 cycles)
// Bit 4:    longword operation (64 to 128 cycles)

assign stat_reg = {26'h0, done_int, longword_op, byte_op, writeback,current_state};

//Read data
always @(posedge clk or negedge rst_b)
begin
 if (~rst_b)
    rdata1 <= 32'h0;
 else
  begin
    if ((op == `READMEM) && busy)
       rdata1 <= current_mem_word;
    else if (op == `READSTAT)
       rdata1 <= stat_reg;
   end    
end

//Counters

always @(posedge clk or negedge rst_b)
begin
  if (~rst_b)
    cntr128 <= 7'h0;
  else if (current_state == STAT_IDLE)
    cntr128 <= 7'h0;
  else if ((current_state == STAT_IDLE) && (op == `ZOOMIN))  //if doing a zoom, start at word 17 instead of reading unneeded iamge data
    cntr128 <= 7'h11;  
  else if ((current_state == STAT_BUSY) && (op == `ZOOMIN) && (cntr128 == 7'h2e))  //once word 46 has been grabbed on zoom, just skip the rest of the image
    cntr128 <= 7'h40;
  else if (busy && ctr_incr)    //otherwise, just increment counter
    cntr128 <= cntr128 + 7'h1;
end

assign cntr64 = cntr128[5:0];
assign cntr64_inv = ~cntr64;

//////////////////////////////////
// Image processing scratchpad
//16 columns of 128-bits (4 words) image-transform scratchpad

always @(posedge clk or negedge rst_b)
begin
    if (~rst_b)
      begin
        for (k=0; k<16; k++)
	   image_scratch[k] <= 128'h0;
      end
    else if (rotate_op & busy & ~writeback)
     begin
  	case (scratch_column) //synopsys full_case
	    4'hf :
	    begin
	    image_scratch[rr0][120:127]      <= current_mem_word[7:0];    
	    image_scratch[rr1][120:127] <= current_mem_word[15:8];
	    image_scratch[rr2][120:127] <= current_mem_word[23:16];
	    image_scratch[rr3][120:127] <= current_mem_word[31:24];	    
	    end
	    4'he :
	    begin
	    image_scratch[rr0][112:119]      <= current_mem_word[7:0];    
	    image_scratch[rr1][112:119] <= current_mem_word[15:8];
	    image_scratch[rr2][112:119] <= current_mem_word[23:16];
	    image_scratch[rr3][112:119] <= current_mem_word[31:24]; 	    
	    end
	    4'hd :
	    begin
	    image_scratch[rr0][104:111]      <= current_mem_word[7:0];    
	    image_scratch[rr1][104:111] <= current_mem_word[15:8];
	    image_scratch[rr2][104:111] <= current_mem_word[23:16];
	    image_scratch[rr3][104:111] <= current_mem_word[31:24]; 	    
	    end
 	    4'hc :
	    begin
	    image_scratch[rr0][96:103]      <= current_mem_word[7:0];	 
	    image_scratch[rr1][96:103] <= current_mem_word[15:8];
	    image_scratch[rr2][96:103] <= current_mem_word[23:16];
	    image_scratch[rr3][96:103] <= current_mem_word[31:24]; 	   
	    end
 	    4'hb :
	    begin
	    image_scratch[rr0][88:95]      <= current_mem_word[7:0];	
	    image_scratch[rr1][88:95] <= current_mem_word[15:8];
	    image_scratch[rr2][88:95] <= current_mem_word[23:16];
	    image_scratch[rr3][88:95] <= current_mem_word[31:24];     
	    end
  	    4'ha :
	    begin
	    image_scratch[rr0][80:87]      <= current_mem_word[7:0];	
	    image_scratch[rr1][80:87] <= current_mem_word[15:8];
	    image_scratch[rr2][80:87] <= current_mem_word[23:16];
	    image_scratch[rr3][80:87] <= current_mem_word[31:24];    
	    end
 	    4'h9 :
	    begin
	    image_scratch[rr0][72:79]      <= current_mem_word[7:0];	 
	    image_scratch[rr1][72:79] <= current_mem_word[15:8];
	    image_scratch[rr2][72:79] <= current_mem_word[23:16];
	    image_scratch[rr3][72:79] <= current_mem_word[31:24];      
	    end
 	    4'h8 :
	    begin
	    image_scratch[rr0][64:71]      <= current_mem_word[7:0];	 
	    image_scratch[rr1][64:71] <= current_mem_word[15:8];
	    image_scratch[rr2][64:71] <= current_mem_word[23:16];
	    image_scratch[rr3][64:71] <= current_mem_word[31:24];      
	    end
	    4'h7 :
	    begin
	    image_scratch[rr0][56:63]      <= current_mem_word[7:0];	
	    image_scratch[rr1][56:63] <= current_mem_word[15:8];
	    image_scratch[rr2][56:63] <= current_mem_word[23:16];
	    image_scratch[rr3][56:63] <= current_mem_word[31:24];     
	    end
	    4'h6 :
	    begin
	    image_scratch[rr0][48:55]      <= current_mem_word[7:0];	 
	    image_scratch[rr1][48:55] <= current_mem_word[15:8];
	    image_scratch[rr2][48:55] <= current_mem_word[23:16];
	    image_scratch[rr3][48:55] <= current_mem_word[31:24];      
	    end
	    4'h5 :
	    begin
	    image_scratch[rr0][40:47]      <= current_mem_word[7:0];	 
	    image_scratch[rr1][40:47] <= current_mem_word[15:8];
	    image_scratch[rr2][40:47] <= current_mem_word[23:16];
	    image_scratch[rr3][40:47] <= current_mem_word[31:24];      
	    end
 	    4'h4 :
	    begin
	    image_scratch[rr0][32:39]      <= current_mem_word[7:0];	
	    image_scratch[rr1][32:39] <= current_mem_word[15:8];
	    image_scratch[rr2][32:39] <= current_mem_word[23:16];
	    image_scratch[rr3][32:39] <= current_mem_word[31:24];     
	    end
 	    4'h3 :
	    begin
	    image_scratch[rr0][24:31]      <= current_mem_word[7:0];	
	    image_scratch[rr1][24:31] <= current_mem_word[15:8];
	    image_scratch[rr2][24:31] <= current_mem_word[23:16];
	    image_scratch[rr3][24:31] <= current_mem_word[31:24];     
	    end
  	    4'h2 :
	    begin
	    image_scratch[rr0][16:23]      <= current_mem_word[7:0];	
	    image_scratch[rr1][16:23] <= current_mem_word[15:8];
	    image_scratch[rr2][16:23] <= current_mem_word[23:16];
	    image_scratch[rr3][16:23] <= current_mem_word[31:24];     
	    end
 	    4'h1 :
	    begin
	    image_scratch[rr0][8:15]      <= current_mem_word[7:0];     
	    image_scratch[rr1][8:15] <= current_mem_word[15:8];
	    image_scratch[rr2][8:15] <= current_mem_word[23:16];
	    image_scratch[rr3][8:15] <= current_mem_word[31:24];      
	    end
 	    4'h0 :
	    begin
	    image_scratch[rr0][0:7]      <= current_mem_word[7:0];    
	    image_scratch[rr1][0:7] <= current_mem_word[15:8];
	    image_scratch[rr2][0:7] <= current_mem_word[23:16];
	    image_scratch[rr3][0:7] <= current_mem_word[31:24];    
	    end
         endcase
      end	
    //zooming in cuts outer 8 pixels on all sides
    //and takes remaining pixels and repeats each 4 times (1x1 becomes 4x4)	
    else if ((op == `ZOOMIN) & busy & ~writeback &  zoomin_wordgrab)  
      begin
	 if (cntr64[0])  //odd numbered words
	 begin  
	     //bloat each zoomed image pixel to cover 4 pixels
		image_scratch[zi_scratch_row][0:31]        <= {current_mem_word[31:24], current_mem_word[31:24], current_mem_word[23:16], current_mem_word[23:16]};
		image_scratch[zi_scratch_row][32:63]       <= {current_mem_word[15:8], current_mem_word[15:8], current_mem_word[7:0], current_mem_word[7:0]}; 
		image_scratch[zi_scratch_row_next][0:31]   <= {current_mem_word[31:24], current_mem_word[31:24], current_mem_word[23:16], current_mem_word[23:16]};
		image_scratch[zi_scratch_row_next][32:63]  <= {current_mem_word[15:8], current_mem_word[15:8], current_mem_word[7:0], current_mem_word[7:0]}; 
	 end
	 else   //even numbered words
	 begin 
	     //bloat each zoomed image pixel to cover 4 pixels
		image_scratch[zi_scratch_row][64:95]       <= {current_mem_word[31:24], current_mem_word[31:24], current_mem_word[23:16], current_mem_word[23:16]};
		image_scratch[zi_scratch_row][96:127]      <= {current_mem_word[15:8], current_mem_word[15:8], current_mem_word[7:0], current_mem_word[7:0]}; 
		image_scratch[zi_scratch_row_next][64:95]  <= {current_mem_word[31:24], current_mem_word[31:24], current_mem_word[23:16], current_mem_word[23:16]};
		image_scratch[zi_scratch_row_next][96:127] <= {current_mem_word[15:8], current_mem_word[15:8], current_mem_word[7:0], current_mem_word[7:0]}; 
	 end
     end
     
    else if ((op == `ZOOMOUT) & busy & ~writeback )
    begin
      if ((zi_scratch_row == 4'hf) | (cntr64[2]))
        begin
           image_scratch[0] <= zoomout_fill128;
           image_scratch[1] <= zoomout_fill128;
           image_scratch[2] <= zoomout_fill128;
           image_scratch[3] <= zoomout_fill128;
           image_scratch[12] <= zoomout_fill128;
           image_scratch[13] <= zoomout_fill128;
           image_scratch[14] <= zoomout_fill128;
           image_scratch[15] <= zoomout_fill128;
        end
      else  
      begin
	image_scratch[zo_scratch_row][0:31] <= zoomout_fill128[0:31]; 
        image_scratch[zo_scratch_row][96:127] <= zoomout_fill128[0:31];
        case (cntr64[1:0])
        2'b00:
	   image_scratch[zo_scratch_row][32:47] <= {zoomout_byte1,zoomout_byte2};
	2'b01:
	   image_scratch[zo_scratch_row][48:63] <= {zoomout_byte1,zoomout_byte2};
	2'b10:
	   image_scratch[zo_scratch_row][64:79] <= {zoomout_byte1,zoomout_byte2};
	2'b11:
	   image_scratch[zo_scratch_row][80:95] <= {zoomout_byte1,zoomout_byte2};	 
	endcase
     end
    end
end  //image_scratch

assign scratch_column = (op == `ROTCLKWISE) ? ~cntr64[5:2] : cntr64[5:2];

//every time cntr64 increments by 4 the scratch row pointer is incremented by one
assign scratch_row =  cntr64[5:2];

//choose which row the rotate operation is writing in scratch memory based on which word in the original image row
assign rr0 = (op == `ROTCLKWISE) ? {cntr64[1:0],2'b00} : {~cntr64[1:0],2'b11};

assign rr1 = (op == `ROTCLKWISE) ? rr0 + 4'h1 : rr0 - 4'h1;
assign rr2 = (op == `ROTCLKWISE) ? rr0 + 4'h2 : rr0 - 4'h2;
assign rr3 = (op == `ROTCLKWISE) ? rr0 + 4'h3 : rr0 - 4'h3;


//scratch_row_opposite is complement of scratch_rotate. 
//  e.g. 
// if scratch row = 0 on left, scratch_row_opposite = 15 on right
// if scratch row = 1, scratch_row_opposite = 14
// if scratch row = 8, scratch_row_opposite = 7

assign scratch_row_opposite = ~scratch_row;



always_comb 
begin
  case (cntr64[1:0]) //synopsys full_case
    2'b00:
     image_scratch_word = image_scratch[scratch_row][0:31];
    2'b01:
     image_scratch_word = image_scratch[scratch_row][32:63];
    2'b10:
     image_scratch_word = image_scratch[scratch_row][64:95];
    2'b11:
     image_scratch_word = image_scratch[scratch_row][96:127];    
   endcase
end

////////////////////////////////////////
//Image memory 
//is 64 addressable words 
always @(posedge clk or negedge rst_b)
begin
  if (~rst_b)
    begin
     for (i=0; i<64; i++)
 	image_mem[i] <= 32'h0;
    end
// begin
// image_mem[0] <= 32'h0;  image_mem[1] <= 32'h0; image_mem[2] <= 32'h0; image_mem[3] <= 32'h0;
// image_mem[4] <= 32'h0;  image_mem[5] <= 32'h0; image_mem[6] <= 32'h0; image_mem[7] <= 32'h0;
// image_mem[8] <= 32'h0;  image_mem[9] <= 32'h0; image_mem[10] <= 32'h0; image_mem[11] <= 32'h0;
// image_mem[12] <= 32'h0;  image_mem[13] <= 32'h0; image_mem[14] <= 32'h0; image_mem[15] <= 32'h0;
// image_mem[16] <= 32'h0;  image_mem[17] <= 32'h0; image_mem[18] <= 32'h0; image_mem[19] <= 32'h0;
// image_mem[20] <= 32'h0;  image_mem[21] <= 32'h0; image_mem[22] <= 32'h0; image_mem[23] <= 32'h0;
// image_mem[24] <= 32'h0;  image_mem[25] <= 32'h0; image_mem[26] <= 32'h0; image_mem[27] <= 32'h0;
// image_mem[28] <= 32'h0;  image_mem[29] <= 32'h0; image_mem[30] <= 32'h0; image_mem[31] <= 32'h0;
// image_mem[32] <= 32'h0;  image_mem[33] <= 32'h0; image_mem[34] <= 32'h0; image_mem[35] <= 32'h0;
// image_mem[36] <= 32'h0;  image_mem[37] <= 32'h0; image_mem[38] <= 32'h0; image_mem[39] <= 32'h0;
// image_mem[40] <= 32'h0;  image_mem[41] <= 32'h0; image_mem[42] <= 32'h0; image_mem[43] <= 32'h0;
// image_mem[44] <= 32'h0;  image_mem[45] <= 32'h0; image_mem[46] <= 32'h0; image_mem[47] <= 32'h0;
// image_mem[48] <= 32'h0;  image_mem[49] <= 32'h0; image_mem[50] <= 32'h0; image_mem[51] <= 32'h0;
// image_mem[52] <= 32'h0;  image_mem[53] <= 32'h0; image_mem[54] <= 32'h0; image_mem[55] <= 32'h0;
// image_mem[56] <= 32'h0;  image_mem[57] <= 32'h0; image_mem[58] <= 32'h0; image_mem[59] <= 32'h0;
// image_mem[60] <= 32'h0;  image_mem[61] <= 32'h0; image_mem[62] <= 32'h0; image_mem[63] <= 32'h0;
// end
    

  //simple one-cycle operations  
   else if (op == `ALLBLACK)
      image_mem[cntr64] <= 32'h0000_0000;
      
   else if (op == `ALLWHITE)   
      image_mem[cntr64] <= 32'hffff_ffff;
      
   else if (op == `ALLGREY)
       image_mem[cntr64] <= 32'hf0f0_f0f0;
       
  //creates (2x2) dark spot followed by 2x2 white spot using the values written on wrdata
   else if (op == `CHECKERBOARD)
      if (cntr64[3])
         image_mem[cntr64] <= {wdata[7:0], wdata[7:0], wdata[15:8], wdata[15:8]} ;
      else
         image_mem[cntr64] <= {wdata[15:8], wdata[15:8], wdata[7:0], wdata[7:0]} ;

	 
   else if ((op == `LOADMEM) & busy)
      image_mem[addr] <= wdata;
   

   //64-cycle pixel operations    
   else if (byte_op & busy)
      image_mem[cntr64] <= word_op_result;

   //longword operation complete - write results back to image memory
   else if (writeback & busy) 
       image_mem[cntr64] <= image_scratch_word;
     
     
end  //image_mem

assign current_mem_word = (op == `READMEM) ? image_mem[addr] : 
			                     (rotate_op) ? 
					          image_mem[cntr64_inv] : image_mem[cntr64];

///////////////////////////////////////////
//Pixel Arithmetic/Logic functions
//Performs pixel operations 32-bits at a time
// Darken, lighten, invert, XOR-checksum

always_comb
begin
   casex (op)
     `DARKEN :    pixel_op = `PIXELOP_DARK;
     `LIGHTEN :   pixel_op = `PIXELOP_LITE;
     `INVERTALL : pixel_op = `PIXELOP_INVT;
     `CHECKSUM :  pixel_op = `PIXELOP_CKSM;
     default : pixel_op = 2'b00;
   
   endcase

end


image_word_op  image_word_op (.operate(pixel_op), .datain(current_mem_word), .dataout(word_op_result));

//////////////////////////////////////
//Image ZOOM-IN function control
//treat image_scratchpad as 16 rows of 16-bytes each
/*
Zooming in only captures this data - all other bytes/words are discarded
bytes 180 181 182 183 184 185 186 187
      164 165 166 167 168 169 170 171
      148 149 150 151 152 153 154 155
      132 133 134 135 136 137 138 139
      116 117 118 119 120 121 122 123
      100 101 102 103 104 105 106 107
      84  85  86  87  88  89  90  91
      68  69  70  71  72  73  74  75 

words 45 46    (10_1101  10_1110)
      41 42    (10_1001  10_1010)
      37 38    (10_0101  10_0110)
      33 34    (10_0001  10_0010)
     
      29 30    (01_1101  01_1110)   
      25 26    (01_1001  01_1010)   
      21 22    (01_0101  01_0110)	  
      17 18    (01_0001  01_0010)	  
*/

assign zoomin_wordgrab = (cntr64[4] ^ cntr64[5])  &&  (cntr64[1] ^ cntr64[0]) ;
           
/*	      
//check my math - 
ERROR_ZOOMIN_WORDGRAB :
assert property (
 @(cntr64) disable iff (op != `ZOOMIN)
 ((cntr64==17) | (cntr64==18) | (cntr64==21) |	(cntr64==22) | (cntr64==25) |  (cntr64==26) |
  (cntr64==29) | (cntr64==30) | (cntr64==33) | (cntr64==34) | (cntr64==37) | (cntr64==38) |
  (cntr64==41) | (cntr64==42) | (cntr64==45) | (cntr64==46)) -> (zoomin_wordgrab == 1'b1)
);
*/
//zoomed bytes on row4 fill row0/row1    in scratch image 
//zoomed bytes on row5 fill row2/row3	 in scratch image 
//zoomed bytes on row11 fill row14/row15 in scratch image 

assign zi_scratch_row      = {cntr64[3],cntr64[1],cntr64[0], 1'b0};
assign zi_scratch_row_next = {cntr64[3],cntr64[1],cntr64[0], 1'b1};
	 
	 
///////////////////////////////////////////
//Image ZOOM-OUT function control
//treat image_scratchpad as 16 rows of 16-bytes each

/*
Zooming out results in final image that only consumes only this portion
The outer 4 bytes on each side are made blank (white)

bytes 180 181 182 183 184 185 186 187
      164 165 166 167 168 169 170 171
      148 149 150 151 152 153 154 155
      132 133 134 135 136 137 138 139
      116 117 118 119 120 121 122 123
      100 101 102 103 104 105 106 107
      84  85  86  87  88  89  90  91
      68  69  70  71  72  73  74  75 

words 45 46    (10_1101  10_1110)
      41 42    (10_1001  10_1010)
      37 38    (10_0101  10_0110)
      33 34    (10_0001  10_0010)
     
      29 30    (01_1101  01_1110)   
      25 26    (01_1001  01_1010)   
      21 22    (01_0101  01_0110)	  
      17 18    (01_0001  01_0010)	  
*/

 
//instead of writing as:  
//		orig words 0/1/4/5   map to word 17
//		orig words 2/3/6/7   map to word 18
//		orig words 8/9/12/13 map to word 21
//		etc.
assign target_word_map = {cntr64[5], ~cntr64[5],  cntr64[4],   cntr64[3],  cntr64[1], ~cntr64[1] };
assign zo_scratch_row = target_word_map[5:2];



//check my math
//verify the correct target word selection in zoom-out in the SAME cycle (continuous assignment)
ERROR_ZOOMOUT_TARGET17:
assert property (
 @(cntr64) disable iff (op != `ZOOMOUT)
 ( ((cntr64 == 6'd0) | (cntr64 == 6'd1) | (cntr64 == 6'd4) | (cntr64 == 6'd5)) |->  ( target_word_map == 6'd17)) 
 );

ERROR_ZOOMOUT_TARGET18:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd2) | (cntr64 == 6'd3) | (cntr64 == 6'd6) | (cntr64 == 6'd7)) |->  ( target_word_map == 6'd18))
 );

ERROR_ZOOMOUT_TARGET21:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd8) | (cntr64 == 6'd9) | (cntr64 == 6'd12) | (cntr64 == 6'd13)) |-> ( target_word_map == 6'd21)) 
);

ERROR_ZOOMOUT_TARGET22:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd10) | (cntr64 == 6'd11) | (cntr64 == 6'd14) | (cntr64 == 6'd15)) |->  ( target_word_map == 6'd22))
 );

ERROR_ZOOMOUT_TARGET25:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd16) | (cntr64 == 6'd17) | (cntr64 == 6'd20) | (cntr64 == 6'd21)) |->  ( target_word_map == 6'd25))
 );

ERROR_ZOOMOUT_TARGET26:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd18) | (cntr64 == 6'd19) | (cntr64 == 6'd22) | (cntr64 == 6'd23)) |->  ( target_word_map == 6'd26))
 );

ERROR_ZOOMOUT_TARGET29:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd24) | (cntr64 == 6'd25) | (cntr64 == 6'd28) | (cntr64 == 6'd29)) |->  ( target_word_map == 6'd29))
 );

ERROR_ZOOMOUT_TARGET30:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd26) | (cntr64 == 6'd27) | (cntr64 == 6'd30) | (cntr64 == 6'd31)) |->  ( target_word_map == 6'd30))
 );

ERROR_ZOOMOUT_TARGET33:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd32) | (cntr64 == 6'd33) | (cntr64 == 6'd36) | (cntr64 == 6'd37)) |->  ( target_word_map == 6'd33))
 );

ERROR_ZOOMOUT_TARGET34:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd34) | (cntr64 == 6'd35) | (cntr64 == 6'd38) | (cntr64 == 6'd39)) |->  ( target_word_map == 6'd34))
 );

ERROR_ZOOMOUT_TARGET37:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd40) | (cntr64 == 6'd41) | (cntr64 == 6'd44) | (cntr64 == 6'd45)) |->  ( target_word_map == 6'd37))
 );

ERROR_ZOOMOUT_TARGET38:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd42) | (cntr64 == 6'd43) | (cntr64 == 6'd46) | (cntr64 == 6'd47)) |->  ( target_word_map == 6'd38))
 );

ERROR_ZOOMOUT_TARGET41:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd48) | (cntr64 == 6'd49) | (cntr64 == 6'd52) | (cntr64 == 6'd53)) |->  ( target_word_map == 6'd41))
 );

ERROR_ZOOMOUT_TARGET42:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd50) | (cntr64 == 6'd51) | (cntr64 == 6'd54) | (cntr64 == 6'd55)) |->  ( target_word_map == 6'd42))
 );

ERROR_ZOOMOUT_TARGET45:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd56) | (cntr64 == 6'd57) | (cntr64 == 6'd60) | (cntr64 == 6'd61)) |->  ( target_word_map == 6'd45))
 );

ERROR_ZOOMOUT_TARGET46:
assert property (  
 @(cntr64) disable iff (op != `ZOOMOUT)
(  ((cntr64 == 6'd58) | (cntr64 == 6'd59) | (cntr64 == 6'd62) | (cntr64 == 6'd63)) |->  ( target_word_map == 6'd46))
 );

 
 
//read top/bottom word pairs:  0,4  1,5   2,6  3,7    8,12 9,13 10,14  11,15 , etc. 
assign zoomout_bottom_word_addr = cntr64;
assign zoomout_top_word_addr =    cntr64 || 6'b00_0100;    //zoomout_top_word = zoomout_bottom_word + 4
 
  
 //shrink 4 pixels (2x2) down to 1x1 with an "averaged" value

assign   zoomout_top_word = image_mem[zoomout_top_word_addr];
assign   zoomout_bottom_word = image_mem[zoomout_bottom_word_addr];

//scratch rows that are left blank will be filled with 16 bytes of value written on wdata
assign zoomout_fill128 = {wdata[7:0],wdata[7:0],wdata[7:0],wdata[7:0],wdata[7:0],wdata[7:0],wdata[7:0],wdata[7:0],
                          wdata[7:0],wdata[7:0],wdata[7:0],wdata[7:0],wdata[7:0],wdata[7:0],wdata[7:0],wdata[7:0]};

	  
image_byte_avg  byte_avg0  (.byte1(zoomout_top_word[31:24]), .byte2(zoomout_top_word[23:16]), 
			    .byte3(zoomout_bottom_word[31:24]), .byte4(zoomout_bottom_word[23:16]), .outbyte(zoomout_byte1));

image_byte_avg  byte_avg1  (.byte1(zoomout_top_word[15:8]), .byte2(zoomout_top_word[7:0]), 
			    .byte3(zoomout_bottom_word[15:8]), .byte4(zoomout_bottom_word[7:0]), .outbyte(zoomout_byte2));



endmodule
