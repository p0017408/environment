class signal_seq;
 environment env;

  function new();
   env = environment::get_environment();
  endfunction
task body;
begin 
#5;
env.bfm1.test();
#25;
env.bfm1.test();
#30;
env.bfm1.test();
#15;
env.bfm1.test();
#1;
end
endtask

endclass

class five_seq;
 environment env;

  function new();
   env = environment::get_environment();
  endfunction
task body;
begin 
    repeat (5)begin
       env.bfm1.test();
       #20;
     end
end
endtask

endclass

