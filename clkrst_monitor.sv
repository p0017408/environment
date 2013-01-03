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
