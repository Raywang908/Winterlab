// set the timescale for the simulation
 `timescale 1ns/1ps 
module testbench;  // module of testbench

// localparam
localparam N = 256;
localparam CYCLE = 10;
// input signal use reg
reg [7:0] binary_in;
reg clk;
reg rst_n;

// output signal use wire
wire [19:0] unpacked_bcd;
wire [11:0] packed_bcd;

// interger 
integer j, error;
///// instantiate  module /////
// instantiate the module you finished in following format //
// module_name #(.parameter1(5),.parameter2(3)) unit_name (.port1(...), .port2(...), ...); //
binary2bcd_double_dabble binary2bcd_double_dabble(
.binary_in(binary_in),
.clk(clk),
.rst_n(rst_n),
.unpacked_bcd(unpacked_bcd),
.packed_bcd(packed_bcd)
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

reg [39:0] golden [0:N];
initial begin
  $readmemb("golden.dat",golden);
end

always #(CYCLE/2) clk = ~clk; 
always #(CYCLE) rst_n = ~rst_n;

// System block set only clock,reset signal and the timeout finish. 
initial begin
  clk = 1;
  rst_n = 1;
  // system reset
end

// output result checking block, control when to sample and verify the result.
integer fp_w;
reg [11:0] correct_data_packed;
reg [19:0] correct_data_unpacked;

initial begin
// error count
  error = 0;
// Use the same control technique to control when to sample output result.
// adder output for two cycle from input to output
  // you can also write the result to a text file
  fp_w = $fopen("answer.txt");
  for (j = 0; j < N; j = j + 1) begin
    @(negedge rst_n);
    //#(CYCLE);
    binary_in = golden[j][39:32];
    correct_data_packed = golden[j][31:20];
    correct_data_unpacked = golden[j][19:0];
    #(CYCLE);
    if(packed_bcd !== correct_data_packed || unpacked_bcd !== correct_data_unpacked) begin
        error = error + 1;
        $display("************* Pattern No.%d is wrong at %t ************", j,$time);
        $display("signal_in = %b, correct packed data is %b, correct unpacked data is %b,", binary_in, correct_data_packed, correct_data_unpacked);
        $display("but your result is %b and %b !!", packed_bcd, correct_data_unpacked);
      end
      $fdisplay(fp_w, "%b  %b___%b %b___%b", binary_in, correct_data_packed, packed_bcd, correct_data_unpacked, unpacked_bcd);
  end

  $fclose(fp_w);

  if(error == 0) begin
    $display("Congratulations!! The functionality of your binary2bcd is correct!!");
  end
  else begin
    $display("error !!");
  end 
  #(CYCLE) $finish; 

end

endmodule
