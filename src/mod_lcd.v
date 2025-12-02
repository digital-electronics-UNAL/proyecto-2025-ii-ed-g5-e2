module lcd_controller (
    input clk,
    input reset,          // Reset activo bajo
    input [9:0] sensor_val, // Valor entero (Ej: 125 para 12.5)
    output reg rs,
    output reg rw,
    output enable,
    output reg [7:0] data // Salida 8 bits (D0-D7)
);

    // Parámetros de tiempo y estados
    reg [19:0] clk_cnt;
    reg clk_slow; // Reloj lento para la LCD
    
    // Generar reloj lento (~500Hz)
    always @(posedge clk) begin
        if (clk_cnt == 100000) begin
            clk_slow <= ~clk_slow;
            clk_cnt <= 0;
        end else clk_cnt <= clk_cnt + 1;
    end
    assign enable = clk_slow; // Usamos el reloj como enable

    // Estados
    localparam INIT = 0, CFG_FUNC = 1, CFG_DISP = 2, CFG_CLR = 3, 
               WRITE_LABEL = 4, NEW_LINE = 5, WRITE_VAL = 6;
               
    reg [3:0] state = INIT;
    reg [3:0] step = 0;

    // Caracteres fijos: "I = "
    reg [7:0] label [0:3];
    initial begin
        label[0] = "I"; label[1] = "="; label[2] = " ";
    end

    always @(posedge clk_slow or negedge reset) begin
        if (!reset) begin
            state <= INIT;
            step <= 0;
            rs <= 0; rw <= 0; data <= 0;
        end else begin
            case (state)
                // 1. Inicialización
                INIT: begin
                    state <= CFG_FUNC; step <= 0;
                end
                
                // 2. Comandos Básicos
                CFG_FUNC: begin
                    rs <= 0; data <= 8'h38; // 8-bit, 2-line, 5x7 font
                    state <= CFG_DISP;
                end
                CFG_DISP: begin
                    rs <= 0; data <= 8'h0C; // Display ON, Cursor OFF
                    state <= CFG_CLR;
                end
                CFG_CLR: begin
                    rs <= 0; data <= 8'h01; // Clear Display
                    state <= WRITE_LABEL; step <= 0;
                end

                // 3. Escribir "I= "
                WRITE_LABEL: begin
                    rs <= 1; // Dato
                    if (step < 3) begin
                        data <= label[step];
                        step <= step + 1;
                    end else begin
                        state <= WRITE_VAL; // Pasamos a escribir el numero
                        step <= 0;
                    end
                end

                // 4. Escribir Valor Numérico Dinámico "XX.X"
                // Asumimos sensor_val = 125 (queremos ver "12.5")
                WRITE_VAL: begin
                    rs <= 1;
                    case (step)
                        0: data <= 8'h30 + (sensor_val / 100);       // Centenas/Decenas (1)
                        1: data <= 8'h30 + ((sensor_val / 10) % 10); // Unidades (2)
                        2: data <= 8'h2E;                            // Punto '.'
                        3: data <= 8'h30 + (sensor_val % 10);        // Decimal (5)
                        4: data <= 8'h6D;                            // 'm'
                        5: data <= 8'h41;                            // 'A'
                        6: begin 
                            // Regresar cursor al inicio para refrescar
                            rs <= 0; data <= 8'h80 + 3; // Posición después de "I= "
                            step <= 0; // Reiniciar loop de escritura
                        end
                        default: step <= 0;
                    endcase
                    if (state == WRITE_VAL && step < 6) step <= step + 1;
                end
            endcase
        end
    end

endmodule