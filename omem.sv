module omem_sv #(
    parameter NUM_AXONS = 256,
    parameter OMEM_BASE_0 = 32'h80040000,
    parameter OMEM_BASE_1 = 32'h80050000
) (
    input logic wb_clk_i,             // Clock
    input logic wb_rst_i,             // Reset
    input logic wbs_cyc_i,            // Indicates an active Wishbone cycle
    input logic wbs_stb_i,            // Active during a valid address phase
    input logic wbs_we_i,             // Determines read or write operation
    input logic [3:0] wbs_sel_i,      // Byte lanes selector
    input logic [31:0] wbs_adr_i,     // Address input
    input logic [31:0] wbs_dat_i,     // Data input for writes
    output logic wbs_ack_o,       // Acknowledgment for data transfer
    output logic [31:0] wbs_dat_o, // Data output

    input logic [1:0] enable_calc_i,
    input logic [1:0] core_en_i,
    input logic [255:0] spike_neuron_0_i,
    input logic [255:0] spike_neuron_1_i
);

    logic [31:0] address0, address1;

    logic [31:0] sram_0 [7:0];
    logic [31:0] sram_1 [7:0];

    always_comb begin
        address0 = (wbs_adr_i - OMEM_BASE_0)>>2;
        address1 = (wbs_adr_i - OMEM_BASE_1)>>2;
    end

    logic [255:0] spike_check;


    always_ff @( posedge wb_clk_i or posedge wb_rst_i) begin : omem_ff
        if(wb_rst_i) begin
            wbs_ack_o <= 1'b0;
            wbs_dat_o <= 32'h00000000;
        end else begin
            if(wbs_cyc_i && wbs_stb_i) begin
                if(wbs_we_i) begin
                    if(core_en_i[0])begin
                        if (address0 >= 0 && address0 < 8) begin
                            if (wbs_sel_i[0]) sram_0[address0][7:0] <= wbs_dat_i[7:0];
                            if (wbs_sel_i[1]) sram_0[address0][15:8] <= wbs_dat_i[15:8];
                            if (wbs_sel_i[2]) sram_0[address0][23:16] <= wbs_dat_i[23:16];
                            if (wbs_sel_i[3]) sram_0[address0][31:24] <= wbs_dat_i[31:24];
                        end
                    end else if (core_en_i[1]) begin
                        if (address1 >= 0 && address1 < 8) begin
                            if (wbs_sel_i[0]) sram_1[address1][7:0] <= wbs_dat_i[7:0];
                            if (wbs_sel_i[1]) sram_1[address1][15:8] <= wbs_dat_i[15:8];
                            if (wbs_sel_i[2]) sram_1[address1][23:16] <= wbs_dat_i[23:16];
                            if (wbs_sel_i[3]) sram_1[address1][31:24] <= wbs_dat_i[31:24];
                        end
                    end
                    wbs_ack_o <= 1'b1;
                    if(core_en_i[0])begin
                        wbs_dat_o <= sram_0[address0];
                    end else if (core_en_i[1]) begin
                       wbs_dat_o <= sram_1[address1];
                    end
                end
            end else begin
                wbs_ack_o <= 1'b0;
                if(enable_calc_i[0])begin
                    //if(core_en_i[0])begin
                        sram_0[0]<=spike_neuron_0_i[255-:32];
                        sram_0[1]<=spike_neuron_0_i[223-:32];
                        sram_0[2]<=spike_neuron_0_i[191-:32];
                        sram_0[3]<=spike_neuron_0_i[159-:32];
                        sram_0[4]<=spike_neuron_0_i[127-:32];
                        sram_0[5]<=spike_neuron_0_i[95-:32];
                        sram_0[6]<=spike_neuron_0_i[63-:32];
                        sram_0[7]<=spike_neuron_0_i[31-:32];
                    end
                    if (enable_calc_i[1]) begin
                        sram_1[0]<=spike_neuron_1_i[255-:32];
                        sram_1[1]<=spike_neuron_1_i[223-:32];
                        sram_1[2]<=spike_neuron_1_i[191-:32];
                        sram_1[3]<=spike_neuron_1_i[159-:32];
                        sram_1[4]<=spike_neuron_1_i[127-:32];
                        sram_1[5]<=spike_neuron_1_i[95-:32];
                        sram_1[6]<=spike_neuron_1_i[63-:32];
                        sram_1[7]<=spike_neuron_1_i[31-:32];
                    end
                
            end
        end
    end

    assign spike_check = {sram_0[0], sram_0[1], sram_0[2], sram_0[3], sram_0[4], sram_0[5], sram_0[6], sram_0[7]};
endmodule