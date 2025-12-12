module lcd_controller_x3 #(
    parameter COUNT_MAX = 100000 // Velocidad de refresco (ajustado para 50MHz)
)(
    input wire clk,            
    input wire reset,          
    // Entradas de 16 bits para recibir el valor completo de los sensores
    input wire [15:0] val1,
    input wire [15:0] val2,
    input wire [15:0] val3,
    
    output reg rs,        
    output reg rw,
    output wire enable,    
    output reg [7:0] data
);

    // Estados de la FSM
    localparam IDLE = 0, INIT = 1, CONFIG1=2, CONFIG2=3, CONFIG3=4, 
               CLEAR=5, MODE=6, PRINT_L1=7, PRINT_VAL1=8, SPACE=9, 
               PRINT_VAL2=10, NEXT_L=11, PRINT_L2=12, PRINT_VAL3=13, HOME=14;

    reg [4:0] state = IDLE;
    reg [19:0] clk_cnt;
    reg lcd_tick;
    reg [3:0] char_idx;

    // Generador de Tick Lento para la LCD
    always @(posedge clk) begin
        if (clk_cnt >= COUNT_MAX) begin
            lcd_tick <= 1;
            clk_cnt <= 0;
        end else begin
            lcd_tick <= 0;
            clk_cnt <= clk_cnt + 1;
        end
    end
    
    assign enable = lcd_tick; // El pulso de Enable lo da el tick

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= IDLE; rs <= 0; rw <= 0; data <= 0; char_idx <= 0;
        end else if (lcd_tick) begin
            case (state)
                IDLE: state <= INIT;
                
                // --- INICIALIZACIÓN ---
                INIT:    begin rs<=0; data<=8'h38; state<=CONFIG1; end
                CONFIG1: begin rs<=0; data<=8'h38; state<=CONFIG2; end
                CONFIG2: begin rs<=0; data<=8'h0C; state<=CONFIG3; end // Display ON
                CONFIG3: begin rs<=0; data<=8'h01; state<=CLEAR; end   // Clear
                CLEAR:   begin rs<=0; data<=8'h06; state<=PRINT_L1; char_idx<=0; end // Entry Mode

                // --- LINEA 1: "S1:XXX S2:XXX" ---
                PRINT_L1: begin
                    rs <= 1;
                    case(char_idx)
                        0: data <= "S"; 1: data <= "1"; 2: data <= ":";
                        default: state <= PRINT_VAL1; // Terminó etiqueta
                    endcase
                    if(state == PRINT_L1) char_idx <= char_idx + 1;
                    else char_idx <= 0;
                end

                PRINT_VAL1: begin
                    rs <= 1;
                    // Lógica para mostrar 3 dígitos del VALOR 1
                    case(char_idx)
                        0: data <= 8'h30 + ((val1 / 100) % 10); // Centenas
                        1: data <= 8'h30 + ((val1 / 10) % 10);  // Decenas
                        2: data <= 8'h30 + (val1 % 10);         // Unidades
                        3: state <= SPACE;
                    endcase
                    if(state == PRINT_VAL1 && char_idx < 3) char_idx <= char_idx + 1;
                    else char_idx <= 0;
                end

                SPACE: begin rs<=1; data<=" "; state<=PRINT_VAL2; char_idx<=0; end // Espacio separador

                PRINT_VAL2: begin // Etiqueta S2 y Valor pegados para ahorrar estados
                    rs <= 1;
                    case(char_idx)
                        0: data <= "S"; 1: data <= "2"; 2: data <= ":";
                        3: data <= 8'h30 + ((val2 / 100) % 10);
                        4: data <= 8'h30 + ((val2 / 10) % 10);
                        5: data <= 8'h30 + (val2 % 10);
                        6: state <= NEXT_L;
                    endcase
                    if(state == PRINT_VAL2 && char_idx < 6) char_idx <= char_idx + 1;
                    else char_idx <= 0;
                end

                // --- LINEA 2: "S3:XXX" ---
                NEXT_L: begin rs<=0; data<=8'hC0; state<=PRINT_L2; char_idx<=0; end // Salto de línea

                PRINT_L2: begin
                    rs <= 1;
                    case(char_idx)
                        0: data <= "S"; 1: data <= "3"; 2: data <= ":";
                        default: state <= PRINT_VAL3;
                    endcase
                    if(state == PRINT_L2) char_idx <= char_idx + 1;
                    else char_idx <= 0;
                end

                PRINT_VAL3: begin
                    rs <= 1;
                    case(char_idx)
                        0: data <= 8'h30 + ((val3 / 100) % 10);
                        1: data <= 8'h30 + ((val3 / 10) % 10);
                        2: data <= 8'h30 + (val3 % 10);
                        3: state <= HOME;
                    endcase
                    if(state == PRINT_VAL3 && char_idx < 3) char_idx <= char_idx + 1;
                    else char_idx <= 0;
                end

                HOME: begin rs<=0; data<=8'h80; state<=PRINT_L1; char_idx<=0; end // Volver al inicio
            endcase
        end
    end
endmodule