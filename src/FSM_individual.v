module FSM_individual #(parameter threshold = 16'd100,
parameter sen_ref = 16'd350
)(
    input clk_16ms,
    input rst,
    input enable,              
    input [15:0] sen,
    output reg relay_out
);

// Estados
localparam STATE_IDLE = 3'd0;
localparam STATE_HEAR_SENSOR = 3'd1;
localparam STATE_OPEN =  3'd2;
localparam STATE_WAIT_5S =  3'd3;
localparam STATE_DEFINITIVE_FAIL =  3'd4;

//Variables internas del programa
reg [3:0] fsm_state;
reg [3:0] next_state;
reg [1:0] retry_cnt;
reg [8:0] timer;

// Lógica de Comparación
reg fail_sen;
reg [15:0] sen_diff;
    
always @(*) begin
    sen_diff = (sen > sen_ref) ? (sen - sen_ref) : (sen_ref - sen);
    fail_sen <= (sen_diff > threshold);
end

// Lógica de la FSM
always @(posedge clk_16ms or posedge rst) begin
    if (rst) begin
        fsm_state <= STATE_IDLE;
        relay_out <= 1'b0;
        retry_cnt <= 2'b00;
        timer <= 9'b0;
    end else if (enable) begin
        fsm_state <= next_state;
        case (fsm_state)
            STATE_IDLE: begin
                relay_out <= 1'b0;
                retry_cnt <= 2'b00;
                timer <= 9'b0;
            end
            STATE_HEAR_SENSOR: begin
                if (fail_sen) begin
                    next_state <= STATE_OPEN;
                end else begin
                    next_state <= STATE_HEAR_SENSOR;
                end
            end
            STATE_OPEN: begin
                relay_out <= 1'b1;
                next_state <= STATE_WAIT_5S;
            end
            STATE_WAIT_5S: begin
                if (timer < 9'd312) begin // 5s at 16ms clock
                    timer <= timer + 1;
                    next_state <= STATE_WAIT_5S;
                end else begin
                    timer <= 9'b0;
                    if (retry_cnt == 3'b11) begin
                        next_state <= STATE_DEFINITIVE_FAIL;
                    end else begin
                        next_state <= STATE_HEAR_SENSOR;
                    end
                end
            end
            STATE_DEFINITIVE_FAIL: begin
                relay_out <= 1'b1;
                next_state <= STATE_DEFINITIVE_FAIL;
            end
            default: begin
                next_state <= STATE_IDLE;
            end
        endcase
    end
end
            
endmodule