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




class lab5_test extends ovm_test;

`ovm_component_utils(lab5_test)

  image_op_xaction   test_trans1, test_trans2;
  ovm_table_printer  printer;
//  image_xform_driver             lab5_driver;
//  image_xform_sequencer          lab5_sequencer;
  image_xform_agent              lab5_agent;
  image_xform_scoreboard         lab5_scoreboard;
  
   ovm_active_passive_enum  active_flag = OVM_ACTIVE;
   
 function new(string name = "lab5_test", ovm_component parent = null);
   super.new(name, parent);
 endfunction

 function void build();
   super.build();
  
   set_config_string("*", "default_sequence", "lab5_seq");
  lab5_agent = image_xform_agent::type_id::create("lab5_agent", this); 
  lab5_scoreboard = image_xform_scoreboard::type_id::create("lab5_scoreboard", this); 
  printer = new();
 endfunction

 function void connect();
    
//    lab5_agent.lab5_monitor.assign_vi(pins);
    lab5_agent.lab5_monitor.op_ch_out.connect(lab5_scoreboard.monitor_resp.analysis_export);

    
    if (active_flag == OVM_ACTIVE) begin
//      lab5_agent.lab5_driver.assign_vi(pins);
      lab5_agent.lab5_driver.seq_item_port.connect(lab5_agent.lab5_sequencer.seq_item_export);
    end
 endfunction


 function void start_of_simulation();
   ovm_report_info("lab5", "Starting the Test...");
 endfunction

 task run();
 
   if (active_flag == OVM_ACTIVE) 
      ovm_report_info("lab5","You have successfully built a testbench with a monitor & active agent");
   else
      ovm_report_info("lab5","You have successfully built a testbench with a monitor & passive agent - no driver/sequencer");
  
   printer.knobs.depth = 4;
   ovm_top.print_topology(printer);

    
      @(test_done)
     global_stop_request();
      
  endtask;

 function void report();
   ovm_report_info("lab5 Test", "Test Passed!");
 endfunction


endclass
