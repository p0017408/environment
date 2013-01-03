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
