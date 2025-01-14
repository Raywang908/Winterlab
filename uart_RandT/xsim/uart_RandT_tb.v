// set the timescale for the simulation
 `timescale 1ns/1ps 
module testbench;  // module of testbench
//  parameter defined
parameter CYCLE = 10; // use CYCLE to describe the clock period
parameter BAUD_RATE_NUMBER = 20;

// localparam
localparam N = 256; 


// input signal use reg
reg clk;
reg rst_n;
reg start;
reg [7:0] data;

// output signal use wire
wire baud_rate_signal;
wire uart_tx;
wire [8:1] result;
wire valid_data;

// interger 
integer j, error;
///// instantiate  module /////
// instantiate the module you finished in following format //
// module_name #(.parameter1(5),.parameter2(3)) unit_name (.port1(...), .port2(...), ...); //
baud_rate_generator baud_rate_generator(
  .clk(clk),
  .rst_n(rst_n),
  .baud_rate_signal(baud_rate_signal)
);

uart_transmitter uart_transmitter(
  .data(data),
  .baud_rate_signal(baud_rate_signal),
  .start(start),
  .rst_n(rst_n),
  .clk(clk),
  .uart_tx(uart_tx)
);

uart_receiver uart_receiver(
  .uart_rx(uart_tx),
  .baud_rate_signal(baud_rate_signal),
  .rst_n(rst_n),
  .data(result),
  .valid_data(valid_data)
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

// there you can read data from the file,and store in the register.
reg [15:0] golden [0:N];
initial begin
  $readmemb("golden.dat",golden);
end


// generate clk 
always #(CYCLE/2) clk = ~clk; 

// System block set only clock,reset signal and the timeout finish. 
initial begin
  clk = 1;
  rst_n = 1;
  start = 0;
  // system reset
  #(CYCLE) rst_n = 0;
  #(CYCLE) rst_n = 1;
  #(CYCLE*2) start = 1;
end

// output result checking block, control when to sample and verify the result.
integer fp_w;
reg [7:0] correct_data;
integer debug = 0;
/*
initial begin 
  for (j = 0; j < N; j = j + 1) begin
    @(posedge clk);
    data = golden[j][15:8];
    correct_data = golden[j][7:0];
    #(CYCLE * BAUD_RATE_NUMBER * 11);
  end
end
*/

initial begin
// error count
  error = 0;
// Use the same control technique to control when to sample output result.
  wait(rst_n==0);
  wait(rst_n==1);
// adder output for two cycle from input to output
  // you can also write the result to a text file
  fp_w = $fopen("answer.txt");
  for (j = 0; j < N; j = j + 1) begin
    @(posedge clk);
    data = golden[j][15:8];
    correct_data = golden[j][7:0];
    #(CYCLE * BAUD_RATE_NUMBER * 11);
    debug = ~debug;
    if(result !== correct_data) begin
        error = error + 1;
        $display("************* Pattern No.%d is wrong at %t ************", j,$time);
        $display("signal_in = %b, correct data is %b,", data, correct_data);
        $display("but your result is %b !!", result);
      end
      $fdisplay(fp_w, "%b  %b_%b_%b", data, correct_data, result, valid_data);
    //#(CYCLE * BAUD_RATE_NUMBER);
  end

  $fclose(fp_w);

  if(error == 0) begin
    $display("Congratulations!! The functionality of your receiver is correct!!");
  end
  else begin
    $display("error !!");
  end 
  #(CYCLE) $finish; 

end

endmodule
