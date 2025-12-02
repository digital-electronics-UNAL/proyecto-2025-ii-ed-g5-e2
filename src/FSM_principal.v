/*
Aquí se va a encontrar la FSM principal que contiene toda la lógico de switcheo de los reles,
y de la información que va a mostrar la lcd
*/

module FMS_principal #(parameter COUNT_MAX = 800000)(
    input clk,
    input rst,
    input [------:0] sen_1,  
    input [------:0] sen_2, 
    input [-------:0] sen_3, 
    output reg [3:0] state_out,
    output reg [7:0] output_signal
);


//Estados de la FSM
localparam STATE_IDLE = 
localparam STATE_HEAR_SENSOR = 
localparam STATE_OPEN_1 = 
localparam STATE_OPEN_2 = 
localparam STATE_OPEN_3 =
localparam STATE_CLOSE_1 = 
localparam STATE_CLOSE_2 = 
localparam STATE_CLOSE_3 =
localparam STATE_DEFINITIVE_FAIL_1 = 
localparam STATE_DEFINITIVE_FAIL_2 = 
localparam STATE_DEFINITIVE_FAIL_3 =

//Variables internas del programa
reg [3:0] fsm_state;
reg [3:0] next_state;
reg clk_16ms;
reg [--------:0] diff_sen_1;
reg [---------:0] diff_sen_2;
reg [--------:0] diff_sen_3;

//Divisor de Frecuencia 
always @(posedge clk) begin
    if (clk_counter == COUNT_MAX-1) begin
        clk_16ms <= ~clk_16ms;
        clk_counter <= 'b0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end


//Comparador diferencial para cada sensor
always @(*) begin
    diff_sen_1 = sen_1 - sen_ref;
    diff_sen_2 = sen_2 - sen_ref;
    diff_sen_3 = sen_3 - sen_ref;
    if(diff_sen_1 > threshold_sen) begin
        fail_sen_1 = 1'b1;
    end else begin
        fail_sen_2= 1'b0;
    end
    if(diff_sen_2 > threshold_sen) begin
        fail_sen_2 = 1'b1;
    end else begin
        fail_sen_2= 1'b0;
    end
    if(diff_sen_3 > threshold_sen) begin
        fail_sen_3 = 1'b1;
    end else begin
        fail_sen_3= 1'b0;   
    end
end


//Activación de reles
always @(*) begin
    case (fsm_State)
        STATE_IDLE: begin
            relay_1 = 1'b0;
            relay_2 = 1'b0;
            relay_3 = 1'b0;
        end
        STATE_OPEN_1: begin
            relay_1 = 1'b1;
        end
        STATE_OPEN_2: begin
            relay_2 = 1'b1;
        end
        STATE_OPEN_3: begin    
            relay_3 = 1'b1;
        end
        STATE_CLOSE_1: begin
            relay_1 = 1'b0;
        end
        STATE_CLOSE_2: begin
            relay_2 = 1'b0;       
        end    
        STATE_CLOSE_3: begin
            relay_3 = 1'b0;       
        end
        STATE_DEFINITIVE_FAIL_1: begin
            relay_1 = 1'b1;
        end
        STATE_DEFINITIVE_FAIL_2: begin
            relay_2 = 1'b1;
        end
        STATE_DEFINITIVE_FAIL_3: begin
            relay_3 = 1'b1;
        end            
    endcase
end

//Las transiciones de la FSM
always @(*) begin
    case(fsm_state)
        IDLE: begin
            next_state <= (ready_i)? STATE_HEAR_SENSOR : IDLE;
        end
        STATE_HEAR_SENSOR: begin 
            if (fail_sen_1 <= 1'b1) begin
                next_state <= STATE_OPEN_1;
            end else if (fail_sen_2 <= 1'b1) begin
                next_state <= STATE_OPEN_2;
            end else if (fail_sen_3 <= 1'b1) begin
                next_state <= STATE_OPEN_3;
            end else begin
                next_state <= STATE_HEAR_SENSOR;
            end
        end
        STATE_OPEN_1:begin
			next_state <= (data_counter == NUM_DATA_PERLINE)? CONFIG_CMD2 : WR_STATIC_TEXT_1L;
        end
        STATE_OPEN_2: begin 
            next_state <= WR_STATIC_TEXT_2L;
        end
	    STATE_OPEN_3: begin
			next_state <= (data_counter == NUM_DATA_PERLINE)? WRITE_DYNAMIC_TXT: WR_STATIC_TEXT_2L;
		end
        //Se tiene de defecto el caso de escribir el texto dinámico
        default: next_state = WRITE_DYNAMIC_TXT;
    endcase
end







endmodule