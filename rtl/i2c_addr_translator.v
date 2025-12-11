//address translator-------------------------------------------------------------

module i2c_addr_translator #(
  // 7bit logicall address mapped to physical address
  parameter [6:0]logical0= 7'h10,
  parameter [6:0]logical1= 7'h11,
  parameter [6:0]logical2= 7'h12,
  parameter [6:0]physical0= 7'h20,
  parameter [6:0]physical1 = 7'h21,
  parameter [6:0]physical2= 7'h22
)(
  input clk,
  input rst_n,
  
  // upstream
  input up_start,//start upstream
  input wire [6:0]up_addr,//7bit address upstream
  input up_rw,//read/ write = 1/0
  input wire [7:0]up_wr_data,
// here we see that write data is an input whereas read data is output 
  output reg [7:0]up_rd_data,
  output reg up_busy,
  output reg up_done,
  output reg up_ACK_error,

  //downstream 
  output reg dn_start,
  output reg [6:0]dn_addr,
  output reg dn_rw,
  output reg [7:0]dn_wr_data,
  // here we see that the write data is output and read data is input to the 
  input  wire [7:0]dn_rd_data,
  input dn_busy,
  input dn_done,
  input dn_ACK_error
);

// address mapping logical to physical
  reg map_check;// check if address has been mapped, if map check =1, the address has been mapped, else if 0, then address not mapped
  reg [6:0]mapping_addr;

  always @(*) begin
    map_check =1'b1;
    mapping_addr =up_addr;//we assign upstream address value to the mapping address
/*
if the upstram address is equal to one of the logical addresses we map the mapping address with corresponding logical address
*/
    if (up_addr== logical0) begin
      mapping_addr= physical0;
    end
    else if (up_addr== logical1) begin
      mapping_addr= physical1;
    end
    else if (up_addr== logical2) begin
      mapping_addr= physical2;
    end
    else begin
      map_check = 1'b0;  // no mapping for this address
    end
  end

  //fsm
  localparam [1:0]
  
  		//4 states-- states alwayes written in upper case
  ST_IDLE= 2'd0,//idle state at 00
  ST_LAUNCH_DN= 2'd1,// launch data in negedge at 01
  ST_WAIT_DN = 2'd2,//timing hold state, scl stays low when 10
  ST_DONE= 2'd3;// done at 11

  reg [1:0] state, next_state;// declaring current and next state

    //state register
  always @(posedge clk or negedge rst_n) begin
    // at reset 0, state = idle, else go to next state
    if (!rst_n)
      state <= ST_IDLE;
    else
      state <= next_state;
  end
  
  //next state logic,
  /* for dn start = 0, next state remains same, i.e. next state = present state */
  always @(*) begin
    next_state= state;
    dn_start= 1'b0;
    case (state)
      /*if upstart= 0 then stay idle, 
      else if upstart= 1
      		if mapcheck= 1, go to LAUNCH_DN state, else go to to state done */
      ST_IDLE: begin
        if (up_start) begin
          if (map_check)
            next_state= ST_LAUNCH_DN;
          else
            next_state= ST_DONE;
        end
      end
      
      /*
      launch data negedge
      dn starrt =1
      next state = Wait_DN
      */
      ST_LAUNCH_DN: begin
        dn_start= 1'b1;
        next_state= ST_WAIT_DN;
      end
      
      /*
      dn done =1
      next state= done state
      */
      ST_WAIT_DN: begin
        if (dn_done)
          next_state= ST_DONE;
      end
      
      ST_DONE: begin
        next_state= ST_IDLE;
      end
    endcase
  end

    // Outputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      up_busy <= 1'b0;
      up_done <= 1'b0;
      up_ACK_error <= 1'b0;
      up_rd_data <= 8'd0;
      dn_addr <= 7'd0;
      dn_rw <= 1'b0;dn_wr_data<= 8'd0;
    end else begin
      up_done <= 1'b0;
      up_ACK_error <= 1'b0;

      case (state)
        ST_IDLE: begin
          up_busy <= 1'b0;
          if (up_start) begin
            up_busy <= 1'b1;
            dn_rw <= up_rw;
            dn_wr_data <= up_wr_data;
            if (map_check)
              dn_addr <= mapping_addr;
            else
              dn_addr <= 7'h00;
          end
        end
        ST_LAUNCH_DN: begin
          up_busy <= 1'b1;
        end

        ST_WAIT_DN: begin
          up_busy <= 1'b1;
          if (dn_done) begin
            up_rd_data <= dn_rd_data;
            up_ACK_error <= dn_ACK_error;
          end
        end

        ST_DONE: begin
          up_busy <= 1'b0;
          up_done <= 1'b1;
        end
      endcase
    end
  end

endmodule
