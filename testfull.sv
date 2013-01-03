`timescale 1 ns / 10 ps
typedef class environment;
event clock_env , reset_env;

//interface testSignals();
interface testSignals(input clock, input resetb);
  logic test1;
endinterface

class clkrst_monitor;
  virtual testSignals testSignals_if;
  function new (virtual testSignals i);
   testSignals_if  = i;
  endfunction
task run;
  fork
    begin
      forever begin 
        @(posedge testSignals_if.clock)
        -> clock_env;
      end
    end
    begin
      forever begin 
        @(posedge testSignals_if.resetb)
        -> reset_env;
      end
    end  
  join_none      
endtask
endclass

///////////////////////////////////////////////
//              sequence driver              //
///////////////////////////////////////////////
`include "seqLib.sv"
class seqer;
 environment env;
 signal_seq  signal_seq;
 five_seq five_seq;
  function new();
//   $cast(env, environment::get_environment());
   env = environment::get_environment();
   signal_seq = new();
   five_seq = new();
  endfunction
  
task MAIN;
begin 
//   $cast(env, environment::get_environment());
//   env = environment::get_environment();
  signal_seq.body();
  five_seq.body();
end
endtask
endclass
/////////// end of sequence driver ///////////

///////////////////////////////////////////////
//                 bfm driver                //
///////////////////////////////////////////////
class bfm;
  virtual testSignals testSignals_if;
event bfm_clock;  
  function new (virtual testSignals i);
   testSignals_if  = i;
 endfunction

task test;
 begin
 $display("start bus transuction");
 @(clock_env);
//@(bfm_clock);
  testSignals_if.test1 = 1'b0;
#20;
//wait(bfm_clock.triggered);
//wait(bfm_clock);
@(bfm_clock);
//#20;
  testSignals_if.test1 = 1'b1;  
 $display("end bus transuction");
end
endtask
endclass
////////////// bfm driver ////////////////////

///////////////////////////////////////////////
//                environment                //
///////////////////////////////////////////////
class environment;
  event env_clock;
 
  static environment _environment;

  virtual testSignals testSignals_if;

bfm bfm1;
seqer seqer1;

  function new (virtual testSignals i);
   testSignals_if  = i;
   _environment = this;
   bfm1 = new(testSignals_if);
   bfm1.bfm_clock = clock_env;
   seqer1 = new();
 endfunction
 
  static function environment get_environment();
     return _environment;
  endfunction

task run;
  seqer1.MAIN();
endtask

endclass

module test(testSignals testSignals_if);

environment env;
clkrst_monitor monitor;

initial begin
env = new (testSignals_if);
env.env_clock = clock_env;
monitor = new (testSignals_if);
fork 
env.run();
monitor.run();
join_none
end

endmodule
