(* use_dsp =  "yes" *)
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
    input logic enable_calc_i,
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
    output logic spike_valid_o,
    output logic spike_o
);

    reg signed [POTENTIAL_WIDTH-1:0] calc_leak_potential;
    reg signed lower_neg_threshold;
    reg signed upper_pos_threshold;
    reg signed [THRESHOLD_WIDTH-1:0] axon_calc_potential [NUM_AXONS];
    wire signed [POTENTIAL_WIDTH-1:0] calc_potential;
    wire signed [WEIGHT_WIDTH-1:0] selected_weight [NUM_AXONS];
    //logic signed [WEIGHT_WIDTH-1:0] pre_selected_weight [NUM_AXONS];

    reg [NUM_AXONS-1:0] enable_synapse;

    generate
        genvar i;
        for (i = 0;i<NUM_AXONS/2 ; i=i+1) begin
            assign selected_weight[i*2] = weights_0_i;
            assign selected_weight[i*2+1] = weights_1_i;
        end
        // for (i = 0;i<NUM_AXONS ; i=i+1) begin
        //     assign enable_synapse[i] = synapses_in_i[i]&axon_in_i[i];
        // end
    endgenerate
    
    generate
        for (i = 0; i < NUM_AXONS; i++) begin
            always_comb begin
                enable_synapse[i] = synapses_in_i[i]& axon_in_i[i];
                axon_calc_potential[i] = (enable_synapse[i]) ? selected_weight[i] : '0;
            end
        end
    endgenerate    
    

    pipelined_adder_tree_v2 adder_tree_inst (
        .clk_i(clk_i),
        .rst_n(rst_n_i),
        .enable_calc_i(enable_calc_i),
        .data_i(axon_calc_potential),
        .data_o(calc_potential),
        .valid_o(spike_valid_o)
    );

    reg spike_check;

    always_comb begin : potential_calc
        calc_leak_potential = calc_potential + current_potential_i + leak_i;
        lower_neg_threshold = (calc_leak_potential < negative_threshold_i) ? 1'b1 : 1'b0;
        upper_pos_threshold = (calc_leak_potential > positive_threshold_i) ? 1'b1 : 1'b0;
        spike_check = (lower_neg_threshold | upper_pos_threshold);    
        spike_o = upper_pos_threshold;
        write_potential_o =(spike_check) ? reset_potential_i : calc_leak_potential;
    end
endmodule