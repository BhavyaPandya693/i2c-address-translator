//master module-------------------------------------------------------
module i2c_master (
  input  wire clk,
  input  wire rst_n,

  input  wire start,// inital start instruction from the master
  input  wire [6:0]addr,//7bit address assigned as per i2c protocol
  input  wire rw,// reaf=1, write=0
  input   [7:0]wr_data,//8bit write

  //outputs
  output reg  [7:0] rd_data,//8bit read data
  output reg busy,// busy=0(idle), busy=1(transfer in progress)
  output reg done,// done goes from 0 to 1 when one click cycle is finished and returns back to 0
  output reg ACK_error,//acknowledgement error

  //data & clock bus
  output wire scl,// serial clock
  inout  wire sda// serial data
);
endmodule
