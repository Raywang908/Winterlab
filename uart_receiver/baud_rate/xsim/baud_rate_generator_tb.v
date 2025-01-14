// set the timescale for the simulation
 `timescale 1ns/1ps 
module testbench;  // module of testbench
//  parameter defined
parameter CYCLE = 10; // use CYCLE to describe the clock period
parameter LARGE_NUMBER  = 10500;// max cycle time=>timeout

// localparam
localparam N = 10417; //BAUD_RATE_NUMBER


// input signal use reg
reg clk;
reg rst_n;

// output signal use wire
wire baud_rate_out;
wire [13:0] counter;
// interger 
integer i, j, error;
///// instantiate  module /////
// instantiate the module you finished in following format //
// module_name #(.parameter1(5),.parameter2(3)) unit_name (.port1(...), .port2(...), ...); //
baud_rate_generator baud_rate_generator(
  .clk(clk),
  .rst_n(rst_n),
  .baud_rate_signal(baud_rate_out),
  .counter(counter)
);

//  dump the waveform of the simulation for fsdb//
/*initial begin
 $fsdbDumpfile("testbench.fsdb"); 
 $fsdbDumpvars;              
end*/

// dump the waveform of the simulation for vcd//
initial begin
  $dumpfile("testbench.vcd");
  $dumpvars("+mda");
end

// generate clk 
always #(CYCLE/2) clk = ~clk; 

// System block set only clock,reset signal and the timeout finish. 
initial begin
  clk = 1;
  rst_n = 1;
  // system reset
  #(CYCLE) rst_n = 0;
  #(CYCLE) rst_n = 1;

  #(CYCLE*LARGE_NUMBER) $finish;
end


// output result checking block, control when to sample and verify the result.
integer  fp_w;
initial begin
// error count
  error = 0;
// Use the same control technique to control when to sample output result.
  wait(rst_n==0);
// adder output for two cycle from input to output
  // you can also write the result to a text file
  fp_w = $fopen("answer.txt");
  for (j = 0; j < N; j = j + 1) begin
    @(posedge clk);
    if (j != 10416) begin
      if (baud_rate_out != 0) begin
        error = error + 1;
        $display("************* Pattern No.%d is wrong at %t ************", j,$time);
        $display("Output = 0, but your answer is %b ", baud_rate_out);  
      end
      $fdisplay(fp_w, "0_%b %d", baud_rate_out, counter);
    end else begin
      if (baud_rate_out != 1) begin
        error = error + 1;
        $display("************* Pattern No.%d is wrong at %t ************", j,$time);
        $display("Output = 1, but your answer is %b ", baud_rate_out);  
      end
      $fdisplay(fp_w, "1_%b %d", baud_rate_out, counter);
    end
  end
  $fclose(fp_w); 
  // check the error count
  if(error==0) begin
    $display("Congratulations!! The functionality of your adder is correct!!");
  end else begin
    $display("error !!");
  end 
  #(CYCLE) $finish;
end

endmodule
