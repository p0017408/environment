`timescale 1 ns / 10 ps
`include "environment.sv"
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
