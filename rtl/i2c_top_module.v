// top module----------------------------------------------------------------------

`timescale 1ns/1ps

module i2c_top_module (
    input  wire clk,
    input  wire rst_n
);

    // I2C physical bus (shared by master + 3 slaves)
    tri1 sda_bus;   // open-drain with pull-up behaviour
    wire scl_bus;

    // downstream master
    wire dn_start;
    wire [6:0]dn_addr;
    wire dn_rw;
    wire [7:0]dn_wr_data;
    wire [7:0]dn_rd_data;
    wire dn_busy;
    wire dn_done;
    wire dn_ack_error;

  // upstream (controller to translator)
    reg up_start;
    reg [6:0]up_addr;
    reg up_rw;
    reg [7:0]up_wr_data;
    wire [7:0]up_rd_data;
    wire up_busy;
    wire up_done;
    wire up_ack_error;

    //using i2c_addr_translator module
    i2c_addr_translator u_trans (
        .clk (clk),
        .rst_n (rst_n),
        .up_start (up_start),
        .up_addr (up_addr),
        .up_rw (up_rw),
        .up_wr_data (up_wr_data),
        .up_rd_data (up_rd_data),
        .up_busy (up_busy),
        .up_done (up_done),
      .up_ack_error (up_ack_error),
        .dn_start (dn_start),
        .dn_addr (dn_addr),
        .dn_rw (dn_rw),
        .dn_wr_data (dn_wr_data),
        .dn_rd_data (dn_rd_data),
        .dn_busy (dn_busy),
        .dn_done (dn_done),
      	.dn_ack_error(dn_ack_error)
    );

    // using i2c_master module
    i2c_master u_master (
        .clk (clk),
        .rst_n (rst_n),
        .start (dn_start),
        .addr (dn_addr),
        .rw (dn_rw),
        .wr_data (dn_wr_data),
        .rd_data (dn_rd_data),
        .busy (dn_busy),
        .done (dn_done),
      	.ack_error(dn_ack_error),
        .scl (scl_bus),
        .sda (sda_bus)
    );

    //instatntiating 3 slaves 
  wire [7:0] slv0_reg_out, slv1_reg_out, slv2_reg_out;//out
  wire [7:0] slv0_reg_in,  slv1_reg_in,  slv2_reg_in;//in

    // Constant data each slave will return on read
    assign slv0_reg_in = 8'hA0;
    assign slv1_reg_in = 8'hB1;
    assign slv2_reg_in = 8'hC2;

    //slave0
    i2c_slave #(
        .slave_addr(7'h20)
    ) u_slave0 (
        .rst_n(rst_n),
        .scl(scl_bus),
        .sda(sda_bus),
        .reg_data_out(slv0_reg_out),
        .reg_data_in(slv0_reg_in)
    );

    // slave1
    i2c_slave #(
        .slave_addr(7'h21)
    ) u_slave1 (
        .rst_n(rst_n),
      	.scl(scl_bus),
        .sda(sda_bus),
        .reg_data_out(slv1_reg_out),
        .reg_data_in(slv1_reg_in)
    );

    // slave2
    i2c_slave #(
        .slave_addr(7'h22)
    ) u_slave2 (
        .rst_n(rst_n),
        .scl(scl_bus),
        .sda(sda_bus),
        .reg_data_out(slv2_reg_out),
        .reg_data_in(slv2_reg_in)
    );

    // upstream control fsm example
    localparam [1:0]
  // idle(00)-> s0(01)-> s1(10)-> s2(11)-> idle(00)
        CMD_IDLE= 2'd0,
        CMD_S0= 2'd1,
        CMD_S1= 2'd2,
        CMD_S2= 2'd3;

    reg [1:0] cmd_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cmd_state <= CMD_IDLE;
            up_start <= 1'b0;
            up_addr <= 7'h10;
            up_rw <= 1'b1;  // read
            up_wr_data <= 8'h00;
        end else begin
            up_start <= 1'b0;

            case (cmd_state)
                CMD_IDLE: begin
                    if (!up_busy) begin
                        up_addr <= 7'h10; // logical addr for slave0
                        up_rw <= 1'b1;  // read
                        up_start <= 1'b1;
                        cmd_state <= CMD_S0;
                    end
                end

                CMD_S0: begin
                    if (up_done) begin
                        up_addr <= 7'h11;
                        up_rw <= 1'b1;
                        up_start <= 1'b1;
                        cmd_state <= CMD_S1;
                    end
                end

                CMD_S1: begin
                    if (up_done) begin
                        up_addr <= 7'h12;
                        up_rw <= 1'b1;
                        up_start <= 1'b1;
                        cmd_state <= CMD_S2;
                    end
                end

                CMD_S2: begin
                    if (up_done) begin
                        cmd_state <= CMD_S2; // stay here
                    end
                end
            endcase
        end
    end

endmodule
