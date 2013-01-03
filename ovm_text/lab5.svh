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
//  Date    : December 6, 2010
//               
///////////////////////////////////////////////////////////////////////////////
//
// OVM LAB5 INSTRUCTIONS:
//
// STEP 1) In the sequence body task, send a constrained sequence-item with "reset_req" = 1
// STEP 2) In the sequence body task, send a constrained sequence-item with "opcode" = CHECKERBOARD
// STEP 3) In the sequence body task, send a constrained sequenece-item with "opcode" = READMEM
//         and  "address" = i (use a semicolon to separate the constraints inside { } brackets
// STEP 4) source ../runme 

///////////////////////////////////////////////////////////////////////////////
//`include "test_if.svh"

//program lab5 (test_if pins);
  import ovm_pkg::*;
  `include "ovm_macros.svh"

typedef enum logic[3:0]{
  NOP             = 4'b0000,
  LOADMEM         = 4'b0001,
  READMEM         = 4'b0010,
  ROTCLKWISE      = 4'b0011,
  ROTCNTCLKWISE   = 4'b0100,
  DARKEN          = 4'b0101,
  LIGHTEN         = 4'b0110,
  INVERTALL       = 4'b0111,
  ALLBLACK        = 4'b1000,
  ALLWHITE        = 4'b1001,
  ALLGREY         = 4'b1010,
  CHECKERBOARD    = 4'b1011,
  ZOOMIN          = 4'b1100,
  ZOOMOUT         = 4'b1101,
  CHECKSUM        = 4'b1110,
  READSTAT        = 4'b1111
} image_opcode_type;

`include "lab5_xaction.svh"

event test_done;
///////////////////////////////

class lab5_seq extends ovm_sequence #(image_op_xaction);
  `ovm_sequence_utils(lab5_seq, image_xform_sequencer)
  function new (string name = "lab5_seq");
     super.new(name);
  endfunction
  
  
  task body();
    int i;
      
      /* SEND A RESET SEQUENCE ITEM BY CONSTRAINING "reset_req" TO 1  */
     `ovm_do_with(req,  {reset_req == 1;})
    req.print;

      /* SEND A CONSTRAINED SEQUENCE ITEM BY CONSTRAINING ENUMERATED FIELD "opcode" TO CHECKERBOARD  */
     `ovm_do_with(req, {opcode == CHECKERBOARD;} )
    req.print; 
     
     for (i=0;i<64;i++) begin
       /* SEND 64 CONSTRAINED SEQUENCE ITEMS BY CONSTRAINING ENUMERATED FIELD "opcode" TO READMEM
         AND the "address" FIELD TO THE VARIABLE "i"
	 ->HINT: USE SEMICOLON TO PUT MULTIPLE CONSTRAINTS IN THE SAME LINE  */
      
       `ovm_do_with(req, {opcode == READMEM && address == i;} )

         ovm_report_info("Lab5 Test Sequence", $psprintf("Reading address %h", i));
     end
  endtask
  
  task post_body();
     ->test_done;
  endtask

endclass

///////////////////////////////
`include "lab5_test.svh"


module lab5 (test_if pins);

 initial begin
  
  run_test("lab5_test");
 end
 
 
endmodule 
