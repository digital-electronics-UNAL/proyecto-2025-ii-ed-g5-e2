module lcd_controller_x3 (
    input clk,
    input reset,
    input [15:0] val1, // Sensor 1
    input [15:0] val2, // Sensor 2
    input [15:0] val3, // Sensor 3
    output reg rs,
    output reg rw,
    output reg enable,
    output reg [7:0] data
);
    // CONFIGURACIÓN DE TIEMPOS (50MHz)
    // Generamos un "Tick" lento para la LCD
    reg [19:0] count_tick;
    reg lcd_tick; // Pulso de enable
    
    always @(posedge clk) begin
        if (count_tick == 100000) begin // Velocidad segura
            lcd_tick <= 1;
            count_tick <= 0;
        end else begin
            lcd_tick <= 0;
            count_tick <= count_tick + 1;
        end
    end

    // ESTADOS
    localparam PWR_ON = 0,
               FUNC_SET1 = 1, FUNC_SET2 = 2, FUNC_SET3 = 3,
               DISP_ON = 4, CLEAR = 5, ENTRY_MODE = 6,
               // ESCRITURA
               WR_S1_LABEL = 7, WR_S1_VAL = 8,
               WR_SPACE = 9,
               WR_S2_LABEL = 10, WR_S2_VAL = 11,
               NEXT_LINE = 12,
               WR_S3_LABEL = 13, WR_S3_VAL = 14,
               FINISH = 15;

    reg [4:0] state = PWR_ON;
    reg [3:0] char_idx = 0;
    reg [2:0] sub_step = 0; // 0: Setup, 1: Enable High, 2: Enable Low

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= PWR_ON; enable <= 0; rs <= 0; rw <= 0;
        end else if (lcd_tick) begin
            // MÁQUINA DE PULSOS ENABLE
            case (sub_step)
                0: begin // SETUP DATOS
                    enable <= 0;
                    rw <= 0; // Siempre escritura
                    case (state)
                        PWR_ON: begin rs<=0; data<=8'h38; end
                        FUNC_SET1: begin rs<=0; data<=8'h38; end
                        FUNC_SET2: begin rs<=0; data<=8'h38; end
                        FUNC_SET3: begin rs<=0; data<=8'h38; end
                        DISP_ON:   begin rs<=0; data<=8'h0C; end
                        CLEAR:     begin rs<=0; data<=8'h01; end
                        ENTRY_MODE:begin rs<=0; data<=8'h06; end
                        
                        // --- SENSOR 1 ---
                        WR_S1_LABEL: begin 
                            rs<=1; 
                            case(char_idx) 0:data<="S"; 1:data<="1"; 2:data<=":"; default:data<=" "; endcase 
                        end
                        WR_S1_VAL: begin
                            rs<=1;
                            case(char_idx)
                                0:data<=8'h30 + ((val1/100)%10); // Centenas
                                1:data<=8'h30 + ((val1/10)%10);  // Decenas
                                2:data<=8'h30 + (val1%10);       // Unidades
                            endcase
                        end
                        
                        WR_SPACE: begin rs<=1; data<=" "; end

                        // --- SENSOR 2 ---
                        WR_S2_LABEL: begin 
                            rs<=1; 
                            case(char_idx) 0:data<="S"; 1:data<="2"; 2:data<=":"; default:data<=" "; endcase 
                        end
                        WR_S2_VAL: begin
                            rs<=1;
                            case(char_idx)
                                0:data<=8'h30 + ((val2/100)%10);
                                1:data<=8'h30 + ((val2/10)%10);
                                2:data<=8'h30 + (val2%10);
                            endcase
                        end

                        NEXT_LINE: begin rs<=0; data<=8'hC0; end // Salto Linea

                        // --- SENSOR 3 ---
                        WR_S3_LABEL: begin 
                            rs<=1; 
                            case(char_idx) 0:data<="S"; 1:data<="3"; 2:data<=":"; default:data<=" "; endcase 
                        end
                        WR_S3_VAL: begin
                            rs<=1;
                            case(char_idx)
                                0:data<=8'h30 + ((val3/100)%10);
                                1:data<=8'h30 + ((val3/10)%10);
                                2:data<=8'h30 + (val3%10);
                            endcase
                        end
                        
                        FINISH: begin rs<=0; data<=8'h80; end // Home
                    endcase
                    sub_step <= 1;
                end
                
                1: begin enable <= 1; sub_step <= 2; end // PULSO ALTO
                
                2: begin 
                    enable <= 0; sub_step <= 0; // PULSO BAJO & CAMBIO ESTADO
                    
                    // LÓGICA DE TRANSICIÓN DE ESTADOS
                    case (state)
                        PWR_ON: state <= FUNC_SET1;
                        FUNC_SET1: state <= FUNC_SET2;
                        FUNC_SET2: state <= FUNC_SET3;
                        FUNC_SET3: state <= DISP_ON;
                        DISP_ON: state <= CLEAR;
                        CLEAR: state <= ENTRY_MODE;
                        ENTRY_MODE: begin state <= WR_S1_LABEL; char_idx <= 0; end

                        WR_S1_LABEL: if(char_idx==2) begin state<=WR_S1_VAL; char_idx<=0; end else char_idx<=char_idx+1;
                        WR_S1_VAL:   if(char_idx==2) begin state<=WR_SPACE; char_idx<=0; end else char_idx<=char_idx+1;
                        WR_SPACE:    begin state<=WR_S2_LABEL; char_idx<=0; end
                        
                        WR_S2_LABEL: if(char_idx==2) begin state<=WR_S2_VAL; char_idx<=0; end else char_idx<=char_idx+1;
                        WR_S2_VAL:   if(char_idx==2) begin state<=NEXT_LINE; char_idx<=0; end else char_idx<=char_idx+1;
                        
                        NEXT_LINE:   begin state<=WR_S3_LABEL; char_idx<=0; end
                        
                        WR_S3_LABEL: if(char_idx==2) begin state<=WR_S3_VAL; char_idx<=0; end else char_idx<=char_idx+1;
                        WR_S3_VAL:   if(char_idx==2) begin state<=FINISH; end else char_idx<=char_idx+1;
                        
                        FINISH: begin state<=WR_S1_LABEL; char_idx<=0; end // Repetir loop
                    endcase
                end
            endcase
        end
    end
endmodule