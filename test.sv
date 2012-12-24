`timescale 1 ns / 10 ps
typedef class environment;
///////////////////////////////////////////////
//              sequence driver              //
///////////////////////////////////////////////
class seqer;
 environment env;

  function new();
//   $cast(env, environment::get_environment());
   env = environment::get_environment();
  endfunction
task check_seq;
begin 
//   $cast(env, environment::get_environment());
//   env = environment::get_environment();
$display("seqr display task");
env.bfm1.test();
$display("seqr end display task");
end
endtask
endclass
/////////// end of sequence driver ///////////

///////////////////////////////////////////////
//                 bfm driver                //
///////////////////////////////////////////////
class bfm;
  virtual testSignals testSignals_if;

  function new (virtual testSignals i);
   testSignals_if  = i;
  endfunction
  
task test;
 begin
 $display("start bus transuction");
  testSignals_if.test1 = 1'b0;
#20;
  testSignals_if.test1 = 1'b1;  
 $display("end bus transuction");
end
endtask
task display;
begin 
$display("bfm display task");
end
endtask
endclass
////////////// bfm driver ////////////////////

///////////////////////////////////////////////
//                environment                //
///////////////////////////////////////////////
class environment;
 
  static environment _environment;

  virtual testSignals testSignals_if;

bfm bfm1;
seqer seqer1;

  function new (virtual testSignals i);
   testSignals_if  = i;
   _environment = this;
   bfm1 = new(testSignals_if);
   seqer1 = new();
 endfunction
  
  static function environment get_environment();
     return _environment;
  endfunction

task run;
#5;
seqer1.check_seq();
#25;
seqer1.check_seq();
#30;
seqer1.check_seq();
#15;
seqer1.check_seq();
endtask

endclass

module test(testSignals testSignals_if);

environment env;
initial begin
env = new (testSignals_if);
env.run();
end

endmodule
