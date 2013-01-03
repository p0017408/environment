`include "env_list.sv"
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
