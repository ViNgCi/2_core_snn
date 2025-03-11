`timescale 1ns / 1ps

(*use_dsp = "yes" *)
module ReconfigurableAdder #(parameter N = 2)(
    input signed [N-1:0] A, B,
    //input enable_i,
    //output reg valid_o,
    output signed [N:0] SUM
    //input clk
);
    
    // always @(posedge clk) begin
    //     //valid_o <= enable_i;
    //     if (enable_i) begin
        assign SUM = A + B;
    //     end
    // end
    
endmodule

// module ReconfigurableAdder #(parameter N = 8)(
//     input signed [N-1:0] A, B,
//     input enable_i,
//     output reg signed [N:0] SUM,
//     input clk
// );

//     // Combinational ripple-carry adder
//     wire [N:0] comb_sum;
//     wire [N:0] carry;

//     // Kh\u1edfi t\u1ea1o carry ban \u0111\u1ea7u
//     assign carry[0] = 1'b0;

//     genvar i;
//     generate
//         for (i = 0; i < N; i = i + 1) begin : bit_adder
//             // Tính bit t\u1ed5ng: sum = A[i] XOR B[i] XOR carry[i]
//             assign comb_sum[i] = A[i] ^ B[i] ^ carry[i];
//             // Tính carry cho bit ti\u1ebfp theo:
//             // carry[i+1] = (A[i] & B[i]) | (carry[i] & (A[i] ^ B[i]))
//             assign carry[i+1] = (A[i] & B[i]) | (carry[i] & (A[i] ^ B[i]));
//         end
//     endgenerate

//     // Bit th\u1eeba cu\u1ed1i cùng là carry[N]
//     assign comb_sum[N] = carry[N];

//     // \u0110\u01b0a k\u1ebft qu\u1ea3 c\u1ee7a m\u1ea1ch combinational vào register khi enable_i \u0111\u01b0\u1ee3c kích ho\u1ea1t
//     always @(posedge clk) begin
//         if (enable_i) begin
//             SUM <= comb_sum;
//         end
//     end

// endmodule

module reconfig_adder_tree #(parameter N = 2, parameter NUM_INPUTS = 256, parameter OUT_WIDTH = 9)(
    input signed [NUM_INPUTS-1:0] inputs_i,
    //input clk,
    // input enable_calc_i,
    output signed [OUT_WIDTH-1:0] sum_out
    // output valid_o
);
    // wire signed [N-1:0] inputs [NUM_INPUTS-1:0];

    // for (genvar i = 0; i < NUM_INPUTS; i = i + 1) begin : init
    //     assign inputs[i] = inputs_i[(i+1)*N-1:i*N];
    // end

    localparam STAGES = $clog2(NUM_INPUTS);
    
    //wire signed [N+STAGES-1:0] adder_tree [STAGES-1:0][NUM_INPUTS/2-1:0];

    wire signed [1:0] adder_tree_stage_0 [NUM_INPUTS/2-1:0];
    wire signed [2:0] adder_tree_stage_1 [NUM_INPUTS/4-1:0];
    wire signed [3:0] adder_tree_stage_2 [NUM_INPUTS/8-1:0];
    wire signed [4:0] adder_tree_stage_3 [NUM_INPUTS/16-1:0];
    wire signed [5:0] adder_tree_stage_4 [NUM_INPUTS/32-1:0];
    wire signed [6:0] adder_tree_stage_5 [NUM_INPUTS/64-1:0];
    wire signed [7:0] adder_tree_stage_6 [NUM_INPUTS/128-1:0];
    wire signed [8:0] adder_tree_stage_7;

    genvar i, stage;
    generate
        // stage 0
        for (i = 0; i < NUM_INPUTS/2; i = i + 1) begin : first_stage
            // ReconfigurableAdder #(N) adder (
            //     .A(inputs[2*i]),
            //     .B(inputs[2*i+1]),
            //     .SUM(adder_tree_stage_0[i][N:0])
            //     //.clk(clk)
            // );
            assign adder_tree_stage_0[i][0] = inputs_i[2*i]^inputs_i[2*i+1];
            assign adder_tree_stage_0[i][1] = (~inputs_i[2*i])&inputs_i[2*i+1];
        end

        // stage 1
        for (i = 0; i < NUM_INPUTS/4; i = i + 1) begin : second_stage
            ReconfigurableAdder #(N) adder (
                .A(adder_tree_stage_0[2*i]),
                .B(adder_tree_stage_0[2*i+1]),
                .SUM(adder_tree_stage_1[i])
                //.clk(clk)
            );
        end

        // stage 2
        for (i = 0; i < NUM_INPUTS/8; i = i + 1) begin : third_stage
            ReconfigurableAdder #(N+1) adder (
                .A(adder_tree_stage_1[2*i]),
                .B(adder_tree_stage_1[2*i+1]),
                .SUM(adder_tree_stage_2[i])
                //.clk(clk)
            );
        end

        // stage 3
        for (i = 0; i < NUM_INPUTS/16; i = i + 1) begin : fourth_stage
            ReconfigurableAdder #(N+2) adder (
                .A(adder_tree_stage_2[2*i]),
                .B(adder_tree_stage_2[2*i+1]),
                .SUM(adder_tree_stage_3[i])
                //.clk(clk)
            );
        end

        // stage 4
        for (i = 0; i < NUM_INPUTS/32; i = i + 1) begin : fifth_stage
            ReconfigurableAdder #(N+3) adder (
                .A(adder_tree_stage_3[2*i]),
                .B(adder_tree_stage_3[2*i+1]),
                .SUM(adder_tree_stage_4[i])
                //.clk(clk)
            );
        end

        // stage 5
        for (i = 0; i < NUM_INPUTS/64; i = i + 1) begin : sixth_stage
            ReconfigurableAdder #(N+4) adder (
                .A(adder_tree_stage_4[2*i]),
                .B(adder_tree_stage_4[2*i+1]),
                .SUM(adder_tree_stage_5[i])
                //.clk(clk)
            );
        end

        // stage 6
        for (i = 0; i < NUM_INPUTS/128; i = i + 1) begin : seventh_stage
            ReconfigurableAdder #(N+5) adder (
                .A(adder_tree_stage_5[2*i]),
                .B(adder_tree_stage_5[2*i+1]),
                .SUM(adder_tree_stage_6[i])
                //.clk(clk)
            );
        end
    endgenerate

    // stage 7
    ReconfigurableAdder #(N+6) adder (
        .A(adder_tree_stage_6[0]),
        .B(adder_tree_stage_6[1]),
        .SUM(adder_tree_stage_7)
        //.clk(clk)
    );

    // assign valid_o = enable_calc_i;
    assign sum_out = adder_tree_stage_7[7:0];    
endmodule


// module AdderTree #(parameter N = 2, parameter NUM_INPUTS = 256, parameter OUT_WIDTH = 9)(
//     input signed [N*NUM_INPUTS-1:0] inputs_i,
//     input clk,
//     output reg signed [OUT_WIDTH-1:0] sum_out
// );
    
//     localparam STAGES = $clog2(NUM_INPUTS);
    
//     wire signed [OUT_WIDTH-1:0] adder_tree [NUM_INPUTS-1:0];
//     wire signed [N-1:0] inputs [NUM_INPUTS-1:0];

//     for (genvar i = 0; i < NUM_INPUTS; i = i + 1) begin : init
//         assign inputs[i] = inputs_i[(i+1)*N-1:i*N];
//     end
    
//     genvar i, stage;
//     generate
//         // T\u1ea7ng \u0111\u1ea7u tiên
//         for (i = 0; i < NUM_INPUTS/2; i = i + 1) begin : first_stage
//             ReconfigurableAdder #(N) adder (
//                 .A(inputs[2*i]),
//                 .B(inputs[2*i+1]),
//                 .SUM(adder_tree[i]),
//                 .clk(clk)
//             );
//         end
        
//         // Các t\u1ea7ng ti\u1ebfp theo
//         for (stage = 1; stage < STAGES; stage = stage + 1) begin : stages
//             for (i = 0; i < (NUM_INPUTS >> (stage + 1)); i = i + 1) begin : stage_level
//                 ReconfigurableAdder #(N+stage) adder (
//                     .A(adder_tree[2*i]),
//                     .B(adder_tree[2*i+1]),
//                     .SUM(adder_tree[i]),
//                     .clk(clk)
//                 );
//             end
//         end
//     endgenerate
    
//     always @(posedge clk) begin
//         sum_out <= adder_tree[0];
//     end
    
// endmodule