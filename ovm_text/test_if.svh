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
//  Description: image transform testbench/DUT interface
//               
///////////////////////////////////////////////////////////////////////////////

interface test_if();

 
   //DUT inputs
   logic clk ;
   logic rst_b;
   logic [5:0] addr;
   logic [31:0] wdata;
   logic [3:0] op;
   logic int_ack;
   
   //DUT outputs
   logic [31:0] rdata;
   logic done_int;
   
/*   
  //From the testbench driver's perspective
   clocking driver_cb @(negedge clk);
      output addr, wdata, op, int_ack, rst_b;
      input done_int, rdata;
   endclocking
   
  //From the testbench monitor's perspective (monitor only has inputs)
   clocking monitor_cb @(posedge clk);
     input rdata, done_int;
     input addr, wdata, op, int_ack;
   endclocking
*/   
endinterface   
