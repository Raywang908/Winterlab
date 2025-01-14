// set the timescale for the simulation
 `timescale 1ns/1ps 
module testbench;  // module of testbench
//  parameter defined
parameter CYCLE = 10; // use CYCLE to describe the clock period
parameter BAUD_RATE_NUMBER = 20;

// localparam
localparam N = 258; 


// input signal use reg
reg clk;
reg rst_n;
reg uart_rx;

// output signal use wire
wire baud_rate_signal;
wire [7:0] data;
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

uart_receiver uart_receiver(
  .uart_rx(uart_rx),
  .baud_rate_signal(baud_rate_signal),
  .rst_n(rst_n),
  .data(data),
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
reg [18:0] golden [0:N];
initial begin
  $readmemb("golden.dat",golden);
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
end

integer k;
task send_uartrx (input reg [9:0] pattern_in);
  begin
    for(k = 9; k >= 0; k = k - 1) begin
      @(posedge baud_rate_signal);
      uart_rx = pattern_in[k];
    end
  end
endtask

// output result checking block, control when to sample and verify the result.
integer fp_w;
reg [9:0] signal_in;
reg [7:0] correct_data;
reg correct_valid;

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
    signal_in = golden[j][18:9];
    correct_data = golden[j][8:1];
    correct_valid = golden[j][0];
    send_uartrx(signal_in);
    #(CYCLE)
    if({data, valid_data} !== {correct_data, correct_valid}) begin
        error = error + 1;
        $display("************* Pattern No.%d is wrong at %t ************", j,$time);
        $display("uart_rx = %b, correct data and correct valid_data is %b and %b,", signal_in, correct_data, correct_valid);
        $display("but your data and valid_data are %b and %b !!", data, valid_data);
      end
      $fdisplay(fp_w, "%b_%b_%b_%b_%b", signal_in, data, valid_data, correct_data, correct_valid);
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
