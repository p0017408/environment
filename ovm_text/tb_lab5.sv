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
//DO NOT EDIT

`include "test_if.svh"
`include "lab5.svh"

module tb_top();

  //test interface signals
  test_if   i_test_if();
    
  //test program that launches sequences
  lab5  lab5_test(i_test_if); 
 
 
//Clock generator

always @(i_test_if.clk)
   #10 i_test_if.clk <= !i_test_if.clk;

//DUT
image_xform image_xform (       .clk(i_test_if.clk),
                                .rst_b(i_test_if.rst_b),
                                .addr(i_test_if.addr),
                                .wdata(i_test_if.wdata),
                                .op(i_test_if.op),
                                .int_ack(i_test_if.int_ack),
                                .rdata(i_test_if.rdata),
                
                                .done_int(i_test_if.done_int)
                        );







endmodule : tb_top
