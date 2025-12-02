/*
Aquí se va a encontrar la FSM principal que contiene toda la lógico de switcheo de los reles,
y de la información que va a mostrar la lcd
*/

module FMS_principal #(parameter COUNT_MAX = 800000)(
    input clk,
    input rst,
    input [7:0] sen_1,  
    input [7:0] sen_2, 
    input [7:0] sen_3, 
    output reg [3:0] state_out,
    output reg [7:0] output_signal
);


//Estados de la FSM
localparam STATE_IDLE = 
localparam STATE_HEAR_SENSOR = 
localparam STATE_FAIL_DETECTED_1 = 
localparam STATE_FAIL_DETECTED_2 = 
localparam STATE_FAIL_DETECTED_3 = 
localparam STATE_OPEN_1 = 
localparam STATE_OPEN_2 = 
localparam STATE_OPEN_3 =
localparam STATE_CLOSE_1 = 
localparam STATE_CLOSE_2 = 
localparam STATE_CLOSE_3 =
localparam STATE_DEFINITIVE_FAIL_1 = 
localparam STATE_DEFINITIVE_FAIL_2 = 
localparam STATE_DEFINITIVE_FAIL_3 =

// Un parametro para indicar LCD
reg LCD_hola; 
reg LCD_medición;
reg LCD_falla;
reg LCD_desaparecio;
reg LCD_contenida;


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
        STATE_HEAR_SENSOR: begin
            relay_1 = 1'b0;
            relay_2 = 1'b0;
            relay_3 = 1'b0;
        end
        STATE_FAIL_DETECTED: begin
            if(fail_sen_1) begin
                relay_1 = 1'b1;
            end
            if(fail_sen_2) begin
                relay_2 = 1'b1;
            end
            if(fail_sen_3) begin
                relay_3 = 1'b1;
            end
        end
        STATE_DONE: begin
            relay_1 = 1'b0;
            relay_2 = 1'b0;
            relay_3 = 1'b0;
        end
    endcase
end


//Estados de la LCD
always @(*) begin
    case (fsm_state)
        STATE_IDLE: begin

        end
        STATE_HEAR_SENSOR: begin

        end
        STATE_FAIL_DETECTED: begin

        end
        STATE_DONE: begin

        end
    endcase
end







endmodule
