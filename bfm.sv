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
