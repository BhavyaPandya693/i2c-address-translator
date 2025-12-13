// slave module------------------------------------------------------------------------

`timescale 1ns/1ps

module i2c_slave #(
  parameter [6:0]slave_addr = 7'h20// 7bit slave address
)(
    input rst_n,
    input scl,
    inout sda,

  output reg  [7:0]reg_data_out,  // byte written by the master
  input  wire [7:0]reg_data_in    // byte sent to the master to read
);

    // Open-drain SDA
  wire sda_in;
  reg  sda_drive_low;              // 1 = pull low, 0 = release (Z)

  assign sda =sda_drive_low ? 1'b0 : 1'bz;
  assign sda_in =sda;

    // FSM states, all written capital
  localparam [3:0]
      ST_IDLE= 4'd0,// idle state at 0000
      ST_ADDR= 4'd1,// address + read/ write bit sent at 0001
      ST_ADDR_ACK= 4'd2,// address acknowledgement at 0010
      ST_WRITE= 4'd3,// write state at 0011
      ST_WRITE_ACK = 4'd4,// write acknowledgement sent at 0100
      ST_READ = 4'd5,// read state at 0101
      ST_READ_ACK = 4'd6,// read ack state at 0110
      ST_IGNORE = 4'd7;// ignore unwanted conditions at 0111

  reg [3:0]state;// 4 bits match the above mentioned states and determine current state
  reg [7:0]shift_reg;
  reg [2:0]bit_count;// bit count
  reg rw;
  reg [7:0]mem;//8 bit memory

    
  always @(negedge scl or negedge rst_n) begin
    if (!rst_n) begin
      sda_drive_low <= 1'b0;// release sda on reset
    end else begin// 
      case (state)
        ST_ADDR_ACK,// address ack state
        ST_WRITE_ACK: begin
          // ACK bit
          sda_drive_low <= 1'b1;
        end

        ST_READ: begin//read state begin
          // Drive data bits (0 -> low, 1 -> release)
          if (shift_reg[bit_count] == 1'b0)
            sda_drive_low <= 1'b1;
          else
            sda_drive_low <= 1'b0;
        end

        default: begin
          sda_drive_low <= 1'b0;
        end
      endcase
    end
  end

    //fsm & datapath
  always @(posedge scl or negedge rst_n) begin
    if (!rst_n) begin//reset all registers
      state <= ST_IDLE;
      bit_count <= 3'd0;
      shift_reg <= 8'd0;
      rw <= 1'b0;
      mem <= 8'd0;
      reg_data_out <= 8'd0;
    end else begin
      case (state)
        ST_IDLE: begin
          // Simplified START: SDA low while SCL high
          if (sda_in == 1'b0) begin
            state <= ST_ADDR;
            bit_count <= 3'd7;
          end
        end

        ST_ADDR: begin
          shift_reg[bit_count] <= sda_in;

          if (bit_count == 3'd0) begin
            // Last bit is R/W
            rw <= sda_in;
            if (shift_reg[7:1] == slave_addr)
              state <= ST_ADDR_ACK;// address match acknowlege state
            else
              state <= ST_IGNORE;// address mismatch ignore state
          end else begin
            bit_count <= bit_count - 3'd1;
          end
        end
        
        ST_ADDR_ACK: begin
          if (rw == 1'b0) begin// write operation
            state <= ST_WRITE;
            bit_count <= 3'd7;
          end else begin
            state <= ST_READ;// read operation
            bit_count <= 3'd7;
            shift_reg <= reg_data_in;// or mem
          end
        end

        ST_WRITE: begin
          shift_reg[bit_count] <= sda_in;
          if (bit_count == 3'd0) begin
            mem <= {shift_reg[7:1], sda_in};
            reg_data_out <= {shift_reg[7:1], sda_in};
            state <= ST_WRITE_ACK;
          end else begin
            bit_count <= bit_count - 3'd1;
          end
        end

        ST_WRITE_ACK: begin
          state <= ST_IDLE;// single-byte only
        end

        ST_READ: begin
          if (bit_count == 3'd0)
            state <= ST_READ_ACK;
          else
            bit_count <= bit_count - 3'd1;
        end

        ST_READ_ACK: begin
                    // Master ACK/NACK on SDA
          if (sda_in == 1'b0) begin
                        // ACK -> could send more bytes, we just repeat
            state <= ST_READ;
            bit_count <= 3'd7;
            shift_reg <= reg_data_in;
          end else begin
            // NACK
            state <= ST_IDLE;
          end
        end

        ST_IGNORE: begin
          state <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

endmodule
