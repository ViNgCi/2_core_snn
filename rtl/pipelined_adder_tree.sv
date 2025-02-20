(*use_dsp = "yes" *)


module pipelined_adder_tree_v2 #(
  parameter NUM_AXONS = 256,
  parameter DATA_WIDTH = 9,
  parameter STAGES_NUM = $clog2(NUM_AXONS)
) (
  input  clk_i,
  input  rst_n,
  
  input  enable_calc_i,
  input  signed [DATA_WIDTH-1:0] data_i [NUM_AXONS],
  output reg signed [DATA_WIDTH-1:0] data_o,
  output reg valid_o
);

  localparam IDLE = 0;
  localparam CALC = 1;
  logic at_state, at_next_state;

  logic signed [DATA_WIDTH-1:0] temp_result [0:NUM_AXONS/2-1];
  logic signed [DATA_WIDTH-1:0] temp_input [0:NUM_AXONS/2-1];

  logic [2:0] stage_count_d;
  logic [2:0] stage_count_q;

  logic valid;
  logic [DATA_WIDTH-1:0] data;

  //genvar dsp_num;

  genvar i;
  generate
    for(i = 0; i < NUM_AXONS/4; i = i + 1) begin : adder_0
      always_ff @(posedge clk_i or posedge rst_n) begin
        if(rst_n)
          temp_result[i] <= '0;
        else
          temp_result[i] <= temp_input[2*i] + temp_input[2*i+1];
      end
    end
    for(i = NUM_AXONS/4; i < NUM_AXONS/2; i = i + 1) begin : adder_1
      always_ff @(posedge clk_i or posedge rst_n) begin
        if(rst_n)
          temp_result[i] <= '0;
        else
          temp_result[i] <= data_i[2*i] + data_i[2*i+1];
      end
    end
  endgenerate
  
  always_ff @( posedge clk_i or posedge rst_n ) begin : ff_control
    if(rst_n == 1'b1) begin
      at_state <= IDLE;
      stage_count_q <= 3'b0;
    end else begin
      at_state <= at_next_state;
      stage_count_q <= stage_count_d;
    end
  end

  //genvar input_num;
  always_comb begin : fsm_control
    case(at_state)
      IDLE: begin
        // stage_count_d = 3'b0;
        // valid_o = 1'b0;
        // for(int input_num = 0; input_num < NUM_AXONS; input_num = input_num + 1) begin
        //   temp_input[input_num] = data_i[input_num];
        // end
        if(enable_calc_i) begin
          at_next_state = CALC;
        end else begin
          at_next_state = IDLE;
        end
      end
      CALC: begin
        // stage_count_d = stage_count_q + 1;
        // for(int input_num = 0; input_num < NUM_AXONS/2; input_num = input_num + 1) begin
        //   temp_input[input_num] = temp_result[input_num];
        // end
        // for(int input_num = NUM_AXONS/2; input_num < NUM_AXONS; input_num = input_num + 1) begin
        //   temp_input[input_num] = '0;
        // end
        if(stage_count_d == STAGES_NUM-1) begin
          at_next_state = IDLE;
          // valid_o = 1'b1;
        end else begin
          at_next_state = CALC;
          // valid_o = 1'b0;
        end
      end
      default: begin
        // stage_count_d = 3'b0;
        at_next_state = IDLE;
        // valid_o = 1'b0;
        // for(int input_num = 0; input_num < NUM_AXONS; input_num = input_num + 1) begin
        //   temp_input[input_num] = '0;
        // end
      end
    endcase
  end

  always_comb begin
    if (at_state) begin
      stage_count_d = stage_count_q + 1;
//      if (stage_count_d == STAGES_NUM - 1) begin
//        valid_o = 1'b1;
//      end else begin
//        valid_o = 1'b0;
//      end
      for(int input_num = 0; input_num < NUM_AXONS/2; input_num = input_num + 1) begin
        temp_input[input_num] = temp_result[input_num];
      end
    end else begin
      //valid_o = 1'b0;
      stage_count_d = 3'b0;
      for(int input_num = 0; input_num < NUM_AXONS/2; input_num = input_num + 1) begin
        temp_input[input_num] = data_i[input_num];
      end
    end
    valid_o = (stage_count_q == STAGES_NUM - 1)? '1 : '0;
    data_o = (valid_o) ? temp_result[0] : '0;
  end

endmodule

// module pipelined_adder_tree #(
//   parameter NUM_AXONS = 256,
//   parameter DATA_WIDTH = 9,
//   parameter STAGES_NUM = $clog2(NUM_AXONS)
// ) (
//   input  clk_i,
//   input  rst_n,
  
//   input  enable_calc_i,
//   input  signed [DATA_WIDTH-1:0] data_i [NUM_AXONS],
//   output reg signed [DATA_WIDTH-1:0] data_o,
//   output reg valid_o
// );

//   //-------------------------------------------------------------------------
//   // Stage 1: Cộng theo cặp dữ liệu đầu vào
//   // Với NUM_AXONS=256, sau cộng theo cặp ta có REDUCED_NUM = 128 giá trị
//   //-------------------------------------------------------------------------
//   localparam REDUCED_NUM = NUM_AXONS/2;
//   localparam CNT_WIDTH   = $clog2(REDUCED_NUM);

//   // Mảng lưu kết quả trung gian của stage 1
//   reg signed [DATA_WIDTH-1:0] stage1_mem [0:REDUCED_NUM-1];
//   // Signal cho biết stage 1 đã hoàn tất (sinh ra sau một chu kỳ khi enable_calc_i active)
//   reg stage1_valid;

//   integer j;
//   always_ff @(posedge clk_i or negedge rst_n) begin
//     if (!rst_n) begin
//       for (j = 0; j < REDUCED_NUM; j = j + 1) begin
//         stage1_mem[j] <= '0;
//       end
//       stage1_valid <= 1'b0;
//     end
//     else if (enable_calc_i) begin
//       // Mỗi cặp 2 phần tử được cộng lại và lưu vào stage1_mem
//       for (j = 0; j < NUM_AXONS; j = j + 2) begin
//         stage1_mem[j/2] <= data_i[j] + data_i[j+1];
//       end
//       stage1_valid <= 1'b1;
//     end
//     else begin
//       stage1_valid <= 1'b0;
//     end
//   end

//   //-------------------------------------------------------------------------
//   // Stage 2: Tích lũy dần các giá trị trong stage1_mem
//   // Sử dụng FSM với 2 trạng thái: IDLE và CALC
//   //-------------------------------------------------------------------------
//   typedef enum logic {IDLE, CALC} state_t;
//   state_t state, next_state;

//   // Bộ đếm để duyệt qua các phần tử của stage1_mem
//   reg [CNT_WIDTH:0] cnt;
//   // Thanh ghi tích lũy để lưu tổng các giá trị
//   reg signed [DATA_WIDTH-1:0] accum;

//   always_ff @(posedge clk_i or negedge rst_n) begin
//     if (!rst_n) begin
//       state   <= IDLE;
//       cnt     <= '0;
//       accum   <= '0;
//       data_o  <= '0;
//       valid_o <= 1'b0;
//     end
//     else begin
//       state <= next_state;
//       case (state)
//         IDLE: begin
//           valid_o <= 1'b0;
//           // Khi stage1_valid được kích hoạt (đã có kết quả từ stage 1)
//           // khởi tạo bộ tích lũy với phần tử đầu tiên của stage1_mem
//           if (stage1_valid) begin
//             accum <= stage1_mem[0];
//             cnt   <= 1;
//           end
//         end
//         CALC: begin
//           // Tích lũy lần lượt các giá trị còn lại từ stage1_mem
//           accum <= accum + stage1_mem[cnt];
//           cnt   <= cnt + 1;
//           // Nếu đây là chu kỳ cộng cuối cùng, gán kết quả ra data_o và set valid_o
//           if (cnt == REDUCED_NUM - 1) begin
//             data_o  <= accum + stage1_mem[cnt]; // Tổng cuối cùng của 256 input
//             valid_o <= 1'b1;
//           end
//         end
//         default: ; // Không xảy ra
//       endcase
//     end
//   end

//   always_comb begin
//     case (state)
//       IDLE: begin
//         if (stage1_valid)
//           next_state = CALC;
//         else
//           next_state = IDLE;
//       end
//       CALC: begin
//         // Khi đã xử lý hết các phần tử của stage1_mem, về lại IDLE
//         if (cnt == REDUCED_NUM)
//           next_state = IDLE;
//         else
//           next_state = CALC;
//       end
//       default: next_state = IDLE;
//     endcase
//   end

// endmodule
