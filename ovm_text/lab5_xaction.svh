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

class image_op_xaction extends ovm_sequence_item;
    
// rand  int        reset_req; 	//Boolean flag to indicate a hard reset request
   int        reset_req; 	//Boolean flag to indicate a hard reset request
	 
// rand image_opcode_type opcode = CHECKERBOARD;
  image_opcode_type opcode = CHECKERBOARD;
// rand  logic [5:0] address = 6'h0;     
   logic [5:0] address = 6'h0;     
// rand  logic [31:0] writedata = 32'h0;  
   logic [31:0] writedata = 32'h0;  
 
 logic [31:0]  readdata = 32'h0;
 
 constraint in_reset {reset_req -> {opcode == NOP; address == 6'h0; writedata == 32'h0;} }

     
 
  `ovm_object_utils_begin(image_op_xaction)
     `ovm_field_int(reset_req, OVM_ALL_ON);
     `ovm_field_enum(image_opcode_type, opcode, OVM_ALL_ON);
     `ovm_field_int(address, OVM_ALL_ON);
     `ovm_field_int(writedata, OVM_NOPRINT);
     `ovm_field_int(readdata, OVM_ALL_ON);
  `ovm_object_utils_end
 
 
// protected logic [31:0] readdata;
 static int iter_count = 0; 
  
 
    // new - constructor
  function new (string name = "image_op_inst",
                ovm_sequencer_base sequencer = null,
                ovm_sequence parent_seq = null);
    super.new(name, sequencer, parent_seq);
    iter_count++;
    address = iter_count;
  endfunction : new
 
   
endclass : image_op_xaction
///////////////////////////////

class image_xform_sequencer extends ovm_sequencer #(image_op_xaction);

  `ovm_sequencer_utils(image_xform_sequencer) 

  function new (string name, ovm_component parent);
    super.new(name, parent);
    
    `ovm_update_sequence_lib_and_item(image_op_xaction)  
    
  endfunction : new

endclass :image_xform_sequencer 


///////////////////////////////
class image_xform_driver extends ovm_driver #(image_op_xaction); 
  
  virtual test_if  pins;

 `ovm_component_utils(image_xform_driver)

 function assign_vi (virtual interface test_if  interface_handle);
   this.pins = interface_handle; 
 endfunction

 function new( string name , ovm_component parent = null);
    super.new( name , parent );
 endfunction // new

 task run();
     pins.clk <= 1'b0;
     pins.int_ack <= 1'b0;
     pins.addr <= 6'h0;
     pins.op <= NOP; 
     pins.wdata <= 32'hxxxx_xxxx;

   forever begin
    seq_item_port.get_next_item(req);
$display("Zak driver item");    
req.print();
    
     if (req.reset_req)
       begin
        ovm_report_info("Driver", "Issuing reset");
        pins.rst_b <= 1'b0;     
        #5 pins.rst_b <= 1'b1;
        end
      else
       begin 
//          pins.driver_cb.op <= req.opcode;
//          pins.driver_cb.addr <= req.address;
        // pins.driver_cb.wdata <= req.writedata;  
//          pins.driver_cb.wdata <= {16'h0, 8'h2a, 8'h20};  //Just for this lab to load checkerboard pattern
      
      //wait for interrupts and acknowledge
        wait (pins.done_int == 1'b1);
//         pins.driver_cb.int_ack <= 1'b1;
            
            
            
       wait (pins.done_int == 1'b0);
//         pins.driver_cb.int_ack <= 1'b0;
//         pins.driver_cb.op <= NOP;
//         pins.driver_cb.wdata <= 32'hxxx_xxxx;
//         pins.driver_cb.addr <= 6'h0;
        
         
      end  //else
    
   seq_item_port.item_done();   
  end
 
 
 endtask

endclass
////////////////////////
class image_xform_monitor extends ovm_monitor;
   event done;
   
  `ovm_component_utils(image_xform_monitor)
   
   ovm_analysis_port #( image_op_xaction ) op_ch_out;
   
   virtual test_if  pins;

   function new(string nm, ovm_component parent = null);
      super.new(nm, parent);
      op_ch_out =  new("ap_monitor_i",this);
   endfunction : new

  function assign_vi (virtual interface test_if  interface_handle);
 
     this.pins = interface_handle; 
 
  endfunction
 
 
 task run();
   image_op_xaction obs_xaction;     //observed host transaction
   image_opcode_type  opcode_val;
 
  forever begin
     obs_xaction = new;
     begin_tr(obs_xaction);
//       @(posedge pins.monitor_cb.done_int)
       
//         $cast(opcode_val, pins.monitor_cb.op); 
	 
        obs_xaction.opcode = opcode_val;
//        obs_xaction.address = pins.addr;
//        obs_xaction.readdata = pins.monitor_cb.rdata;
	
        op_ch_out.write(obs_xaction);
		
      end_tr(obs_xaction);
  end
 endtask
 
endclass
////////////////////////

class image_xform_agent extends ovm_agent;

  protected ovm_active_passive_enum is_active = OVM_ACTIVE;
  `ovm_component_utils_begin(image_xform_agent)
    `ovm_field_enum(ovm_active_passive_enum, is_active, OVM_ALL_ON)
  `ovm_component_utils_end
    
  image_xform_driver lab5_driver;
  image_xform_sequencer lab5_sequencer;
  image_xform_monitor lab5_monitor;

  function new (string name, ovm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build();
    super.build();
     lab5_monitor = image_xform_monitor::type_id::create("lab5_monitor",this);
    if(is_active == OVM_ACTIVE) begin  
       lab5_sequencer = image_xform_sequencer::type_id::create("lab5_sequencer",this);        
          lab5_driver = image_xform_driver::type_id::create("lab5_driver",this);
    end 
  endfunction

endclass


////////////////////////
class image_xform_scoreboard extends ovm_scoreboard;
  typedef  bit [0:15][0:15][7:0] image_array_packed;
 
  `ovm_component_utils(image_xform_scoreboard)
  
   event new_read_flag;
   
  local int in_read_ctr = 0;
  tlm_analysis_fifo #(image_op_xaction) monitor_resp;             //FIFO to collect all the read responses from the DUT
  local image_op_xaction Packet_in, Packet_out, inpkt, outpkt;      // Transactions viewd from monitor
  local image_array_packed  image_result  = '{default : '0};    //actual 16x16 image constructed from DUT 
 
  function new( string name , ovm_component parent = null );
     super.new( name , parent );
  endfunction // new

  function void build();
      super.build();  //Need to call this to apply the `ovm_field_int values!
       monitor_resp = new("mon_fifo", this);

  endfunction
 
   
   task run();
      fork
         construct_image;	 
      join_none
    
   endtask
   
     task construct_image();
     
      int rowcnt, row_num;
      int col_A, col_B, col_C, col_D;  

     forever begin
       monitor_resp.get(Packet_in);    //Operation or data load into DUT
       if (Packet_in.opcode == READMEM) begin
       
               row_num = Packet_in.address >> 2;
          col_A =  {Packet_in.address[1:0], 2'b00};
          col_B =  {Packet_in.address[1:0], 2'b01};
          col_C =  {Packet_in.address[1:0], 2'b10};
          col_D =  {Packet_in.address[1:0], 2'b11};

          image_result[row_num][col_A][7:0] = Packet_in.readdata[31:24];
          image_result[row_num][col_B][7:0] = Packet_in.readdata[23:16];
          image_result[row_num][col_C][7:0] = Packet_in.readdata[15:8];
          image_result[row_num][col_D][7:0] = Packet_in.readdata[7:0];

       
       
       
          in_read_ctr++;
          ->new_read_flag;
        end  
        else 
           in_read_ctr = 0;
 
        if (in_read_ctr == 64) begin
            ovm_report_info("Lab 5 Scoreboard", "Detected Frame Read (64 Read sequences)");
            ovm_report_info("Lab 5 Scoreboard", "DUT Frame contains the following contents");
	    
             for (rowcnt=15; rowcnt>=0; rowcnt=rowcnt-1) begin  
                //reconstruct one row (128 bits per/row) of the image at a time from top to bottom
                                
                        ovm_report_info("DUT Current image", $psprintf("%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", 
                          image_result[rowcnt][0][7:0],  image_result[rowcnt][1][7:0],image_result[rowcnt][2][7:0], image_result[rowcnt][3][7:0],
                          image_result[rowcnt][4][7:0],  image_result[rowcnt][5][7:0],image_result[rowcnt][6][7:0], image_result[rowcnt][7][7:0],
                          image_result[rowcnt][8][7:0],  image_result[rowcnt][9][7:0],image_result[rowcnt][10][7:0],image_result[rowcnt][11][7:0],
                          image_result[rowcnt][12][7:0], image_result[rowcnt][13][7:0],image_result[rowcnt][14][7:0],image_result[rowcnt][15][7:0] ) );
                          

               end //for
	       in_read_ctr = 0;
         end //if
       end
      endtask
      
endclass
