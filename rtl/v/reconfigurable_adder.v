`timescale 1ns / 1ps

(*use_dsp = "yes" *)
module ReconfigurableAdder #(parameter N = 2)(
    input signed [N-1:0] A, B,
    output signed [N:0] SUM
);

    assign SUM = A + B;

    
endmodule

module reconfig_adder_tree #(parameter N = 2, parameter NUM_INPUTS = 256, parameter OUT_WIDTH = 9)(
    input signed [N*NUM_INPUTS-1:0] inputs_i,
    //input enable_calc_i,
    output signed [OUT_WIDTH-1:0] sum_out
);
    wire signed [N-1:0] inputs [NUM_INPUTS-1:0];

    for (genvar i = 0; i < NUM_INPUTS; i = i + 1) begin : init
        assign inputs[i] = inputs_i[(i+1)*N-1:i*N];
    end

    localparam STAGES = $clog2(NUM_INPUTS);

    wire signed [2:0] adder_tree_stage_0 [NUM_INPUTS/2-1:0];
    wire signed [3:0] adder_tree_stage_1 [NUM_INPUTS/4-1:0];
    wire signed [4:0] adder_tree_stage_2 [NUM_INPUTS/8-1:0];
    wire signed [5:0] adder_tree_stage_3 [NUM_INPUTS/16-1:0];
    wire signed [6:0] adder_tree_stage_4 [NUM_INPUTS/32-1:0];
    wire signed [7:0] adder_tree_stage_5 [NUM_INPUTS/64-1:0];
    wire signed [8:0] adder_tree_stage_6 [NUM_INPUTS/128-1:0];
    wire signed [9:0] adder_tree_stage_7;

    genvar i, stage;
    generate
        // stage 0
        for (i = 0; i < NUM_INPUTS/2; i = i + 1) begin : first_stage
            ReconfigurableAdder #(N) adder (
                .A(inputs[2*i]),
                .B(inputs[2*i+1]),
                .SUM(adder_tree_stage_0[i][N:0])
            );
        end

        // stage 1
        for (i = 0; i < NUM_INPUTS/4; i = i + 1) begin : second_stage
            ReconfigurableAdder #(N+1) adder (
                .A(adder_tree_stage_0[2*i]),
                .B(adder_tree_stage_0[2*i+1]),
                .SUM(adder_tree_stage_1[i][N+1:0])
            );
        end

        // stage 2
        for (i = 0; i < NUM_INPUTS/8; i = i + 1) begin : third_stage
            ReconfigurableAdder #(N+2) adder (
                .A(adder_tree_stage_1[2*i]),
                .B(adder_tree_stage_1[2*i+1]),
                .SUM(adder_tree_stage_2[i][N+2:0])
            );
        end

        // stage 3
        for (i = 0; i < NUM_INPUTS/16; i = i + 1) begin : fourth_stage
            ReconfigurableAdder #(N+3) adder (
                .A(adder_tree_stage_2[2*i]),
                .B(adder_tree_stage_2[2*i+1]),
                .SUM(adder_tree_stage_3[i][N+3:0])
            );
        end

        // stage 4
        for (i = 0; i < NUM_INPUTS/32; i = i + 1) begin : fifth_stage
            ReconfigurableAdder #(N+4) adder (
                .A(adder_tree_stage_3[2*i]),
                .B(adder_tree_stage_3[2*i+1]),
                .SUM(adder_tree_stage_4[i][N+4:0])
            );
        end

        // stage 5
        for (i = 0; i < NUM_INPUTS/64; i = i + 1) begin : sixth_stage
            ReconfigurableAdder #(N+5) adder (
                .A(adder_tree_stage_4[2*i]),
                .B(adder_tree_stage_4[2*i+1]),
                .SUM(adder_tree_stage_5[i][N+5:0])
            );
        end

        // stage 6
        for (i = 0; i < NUM_INPUTS/128; i = i + 1) begin : seventh_stage
            ReconfigurableAdder #(N+6) adder (
                .A(adder_tree_stage_5[2*i]),
                .B(adder_tree_stage_5[2*i+1]),
                .SUM(adder_tree_stage_6[i][N+6:0])
            );
        end
    endgenerate

    // stage 7
    ReconfigurableAdder #(N+7) adder (
        .A(adder_tree_stage_6[0]),
        .B(adder_tree_stage_6[1]),
        .SUM(adder_tree_stage_7) 
    );
    assign sum_out = {adder_tree_stage_7[9],adder_tree_stage_7[7:0]};    
endmodule