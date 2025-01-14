module baud_rate_generator (
  input wire clk,
  input wire rst_n,
  output reg baud_rate_signal
);

  parameter BAUD_RATE_NUMBER = 20;
  reg [13:0] counter;
  /*
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= BAUD_RATE_NUMBER - 1;
      baud_rate_signal <= 1'b0;
    end else begin
      if (counter == 1) begin
        counter <= counter - 1;
        baud_rate_signal <= 1;
      end else if (counter == 0) begin
        counter <= BAUD_RATE_NUMBER - 1;
        baud_rate_signal <= 0;
      end else begin  
        counter <= counter - 1;
        baud_rate_signal <= 0;
      end
    end
  end
  */
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= BAUD_RATE_NUMBER - 1;
      baud_rate_signal <= 1'b0;
    end else begin
      case (counter)
        14'b00000000000001: begin
          counter <= counter - 1;
          baud_rate_signal <= 0;
        end
        14'b00000000000000: begin
          counter <= BAUD_RATE_NUMBER - 1;
          baud_rate_signal <= 1;
        end
        default: begin
          counter <= counter - 1;
          baud_rate_signal <= 0;
        end
      endcase 
    end
  end

endmodule