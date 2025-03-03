module parameter_v #(
    parameter NUM_AXONS = 256,
    parameter LEAK_WIDTH = 9,
    parameter WEIGHT_WIDTH = 2,
    parameter THRESHOLD_WIDTH = 9,
    parameter POTENTIAL_WIDTH = 9,
    parameter NUM_WEIGHTS = 4,
    parameter NUM_RESET_MODES = 2,
    parameter PARAM_BASE = 80020000
) (
    input wb_clk_i,             // Clock
    input wb_rst_i,             // Reset
    input wbs_cyc_i,            // Indicates an active Wishbone cycle
    input wbs_stb_i,            // Active during a valid address phase
    input wbs_we_i,             // Determines read or write operation
    input [3:0] wbs_sel_i,      // Byte lanes selector
    input [31:0] wbs_adr_i,     // Address input
    input [31:0] wbs_dat_i,     // Data input for writes
    output reg wbs_ack_o,       // Acknowledgment for data transfer
    output reg [31:0] wbs_dat_o, // Data outpoutput 
    
    input enable_calc_i,


    output [NUM_AXONS-1:0] connections_o,
    output signed [LEAK_WIDTH-1:0] leak_o,
    output signed [WEIGHT_WIDTH-1:0] weights_0_o,
    output signed [WEIGHT_WIDTH-1:0] weights_1_o,
    output signed [THRESHOLD_WIDTH-1:0] positive_threshold_o,
    output signed [THRESHOLD_WIDTH-1:0] negative_threshold_o,
    output signed [POTENTIAL_WIDTH-1:0] reset_potential_o,
    output signed [POTENTIAL_WIDTH-1:0] current_potential_o,
    output signed [$clog2(NUM_RESET_MODES)-1:0] reset_mode_o
);

    reg [31:0] address;

    reg [31:0] sram [11:0];

    wire [367:0] current_neuron_param;

    always @(wbs_adr_i) begin
        address = (wbs_adr_i - PARAM_BASE)>>2;
    end
    
    integer i;

    always @( posedge wb_clk_i or posedge wb_rst_i) begin : param_ff
        if(wb_rst_i) begin
            wbs_ack_o <= 1'b0;
            wbs_dat_o <= 32'h00000000;
            for (i = 0; i < 12; i=i+1) begin
                sram[i] <= 32'h00000000;
            end
        end else begin
            if(wbs_cyc_i && wbs_stb_i) begin
                if(wbs_we_i) begin
                    //if (address >= 0 && address < 12) begin
                        if (wbs_sel_i[0]) sram[address][7:0] <= wbs_dat_i[7:0];
                        if (wbs_sel_i[1]) sram[address][15:8] <= wbs_dat_i[15:8];
                        if (wbs_sel_i[2]) sram[address][23:16] <= wbs_dat_i[23:16];
                        if (wbs_sel_i[3]) sram[address][31:24] <= wbs_dat_i[31:24];
                    //end
                end else begin
                    wbs_ack_o <= 1'b1;
                    wbs_dat_o <= sram[address];
                end
            end else begin
                wbs_ack_o <= 1'b0;
            end
        end
    end

    assign current_neuron_param = {sram[0], sram[1], sram[2], sram[3], sram[4], sram[5], sram[6], sram[7], sram[8], sram[9], sram[10], sram[11][31:16]};
    assign connections_o = current_neuron_param[367:112];
    assign current_potential_o = current_neuron_param[111-:9];
    assign reset_potential_o = current_neuron_param[102-:9];
    assign weights_0_o = current_neuron_param[85+:2];
    assign weights_1_o = current_neuron_param[76+:2];
    assign leak_o = current_neuron_param[57-:9];
    assign positive_threshold_o = current_neuron_param[48-:9];
    assign negative_threshold_o = current_neuron_param[39-:9];
    assign reset_mode_o = current_neuron_param[30];    
endmodule