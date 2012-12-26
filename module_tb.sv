`timescale 1 ns / 10 ps
/*
interface testSignals();
  logic test1;
endinterface
*/
module module_tb();

reg clk;
reg rstb;

always
  forever #10 clk = ~clk;

initial 
   begin
   clk = 1'b0;
   rstb = 1'b1;
   #5;
   rstb = 1'b0;
   #30;
   rstb = 1'b1;
   #100;
//   $finish;
      end  

//testSignals if_testSignals();
testSignals if_testSignals(.clock(clk), .resetb(rstb));

wire test_tb1 = if_testSignals.test1;

test i_test(if_testSignals);  

always@(posedge clk) 
	 $display("signals are rstb = %b test1 = %b ",rstb,test_tb1);
	 	
endmodule
