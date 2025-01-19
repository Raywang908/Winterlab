module binary2bcd_double_dabble (
  input wire [7:0] binary_in,   // 8-bit binary input
  output reg [19:0] unpacked_bcd,  // 20-bit unpacked BCD output
  output reg [11:0] packed_bcd    // 12-bit packed BCD output
);

  // Define constants
  localparam FOUR = 4;          // Constant for comparison (BCD value of 4)
  localparam THREE = 3;         // Constant for adding 3 to BCD value
  localparam ZERO = 4'b0000;    // BCD value representing 0 (4 bits)

  // Temporary registers for intermediate calculations
  reg [19:0] scratch_pad;        // 20-bit register for intermediate storage during conversion
  reg [19:0] scratch_pad_temp;   // Temporary register for shifting the bits
  integer i, j;                  // Loop variables

  // Always block for combinational logic
  always @(*) begin
    // Initialize scratch_pad with binary input and padding zeros at the high end
    scratch_pad = {12'b0, binary_in}; // Prepend 12 zeros to the 8-bit binary input to make it 20 bits
    scratch_pad_temp = 20'b0;         // Clear the temporary register

    // Double Dabble Algorithm loop
    for (i = 0; i < 8; i = i + 1) begin  // Loop for each bit of the binary input
      // Check and modify the BCD values if they are greater than 4 (i.e., 0100)
      for (j = 0; j < 3; j = j + 1) begin  // Loop for checking each 4-bit BCD digit
        case (j)
          2'b00: if (scratch_pad[19:16] > FOUR) scratch_pad[19:16] = scratch_pad[19:16] + THREE;  
          // Check and modify the most significant 4 bits
          2'b01: if (scratch_pad[15:12] > FOUR) scratch_pad[15:12] = scratch_pad[15:12] + THREE;  
          // Check and modify the next 4 bits
          2'b10: if (scratch_pad[11:8] > FOUR)  scratch_pad[11:8]  = scratch_pad[11:8]  + THREE;  
          // Check and modify the next 4 bits
        endcase
      end

      // Left shift the scratch_pad to prepare for the next bit in the binary input
      scratch_pad = scratch_pad << 1;
    end

    // Generate the final outputs after the conversion
    packed_bcd = scratch_pad[19:8];   // Extract the packed BCD (first 12 bits of scratch_pad)
    unpacked_bcd = {scratch_pad[19:16], ZERO, scratch_pad[15:12], ZERO, scratch_pad[11:8]};  
    // Create unpacked BCD with zeros between each BCD digit
  end

endmodule
