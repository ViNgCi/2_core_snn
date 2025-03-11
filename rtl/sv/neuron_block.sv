module neuron_block_sv #(
    parameter NUM_AXONS = 256,
    parameter LEAK_WIDTH = 9,
    parameter WEIGHT_WIDTH = 9,
    parameter THRESHOLD_WIDTH = 9,
    parameter POTENTIAL_WIDTH = 9,
    parameter NUM_WEIGHTS = 4,
    parameter NUM_RESET_MODES = 2 
) (
    input logic clk_i,
    input logic rst_n_i,
    input logic signed [LEAK_WIDTH-1:0] leak_i,
    input logic signed [WEIGHT_WIDTH-1:0] weights_0_i,
    input logic signed [WEIGHT_WIDTH-1:0] weights_1_i,
    input logic signed [THRESHOLD_WIDTH-1:0] positive_threshold_i,
    input logic signed [THRESHOLD_WIDTH-1:0] negative_threshold_i,
    input logic signed [POTENTIAL_WIDTH-1:0] reset_potential_i,
    input logic signed [POTENTIAL_WIDTH-1:0] current_potential_i,
    input logic signed [$clog2(NUM_RESET_MODES)-1:0] reset_mode_i,
    input logic signed [NUM_AXONS-1:0] synapses_in_i,
    input logic signed [NUM_AXONS-1:0] axon_in_i,

    output logic signed [POTENTIAL_WIDTH-1:0] write_potential_o,
    output logic spike_o
);

    logic signed [POTENTIAL_WIDTH-1:0] calc_leak_potential;
    logic signed lower_neg_threshold;
    logic signed upper_pos_threshold;
    logic signed [NUM_AXONS-1:0][THRESHOLD_WIDTH-1:0] axon_calc_potential;
    logic signed [POTENTIAL_WIDTH-1:0] calc_potential;
    logic signed [NUM_AXONS-1:0][WEIGHT_WIDTH-1:0] selected_weight;
    

    generate
        integer i;
        always_comb begin : blockName
            for (i = 0;i<NUM_AXONS ; i=i+1) begin
                if (i[0] == 0) begin
                    selected_weight[i] = weights_0_i;
                end else begin
                    selected_weight[i] = weights_1_i;
                end
                axon_calc_potential[i] = (axon_in_i[i]&synapses_in_i[i]) ? selected_weight[i] : 9'b000000000;
            end
        end
    endgenerate

    always_comb begin : calc_poten
        integer i;
        calc_potential = current_potential_i;
        for (i = 0;i<NUM_AXONS ; i=i+1) begin
            calc_potential += axon_calc_potential[i];
        end
        calc_leak_potential = calc_potential + leak_i;
        lower_neg_threshold = (calc_leak_potential < negative_threshold_i) ? 1'b1 : 1'b0;
        upper_pos_threshold = (calc_leak_potential > positive_threshold_i) ? 1'b1 : 1'b0;       
        spike_o <= upper_pos_threshold;
        write_potential_o <= (upper_pos_threshold || lower_neg_threshold) ? reset_potential_i : calc_leak_potential;
    end
endmodule