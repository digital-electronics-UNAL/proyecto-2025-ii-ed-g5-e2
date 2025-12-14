//Modulo que maneja el protocolo I2C para comunicación sensor-FPGA
module i2c_ina219_x3 #(
    parameter [7:0] SENSOR_ADDR = 8'h80 // Dirección de ESCRITURA por defecto
)(
    input wire clk,             
    input wire reset,           
    inout wire sda,             
    output reg scl,            
    output reg [15:0] data_out  
);
    // --- 1. Generador de TICK (Velocidad segura ~50kHz) ---
    reg [9:0] clk_div;
    reg tick; 
    always @(posedge clk) begin
        if (clk_div == 499) begin tick <= 1; clk_div <= 0; end
        else begin tick <= 0; clk_div <= clk_div + 1; end
    end

    // Buffer SDA
    reg sda_out = 1;
    reg sda_en = 0; 
    assign sda = (sda_en) ? sda_out : 1'bz;

    // --- SECUENCIAS DE DATOS ---
    reg [1:0] phase = 0; 
    reg [7:0] current_byte;

    // Estados de la máquina manual
    localparam IDLE=0, START1=1, START2=2, 
               WRITE_BIT=3, READ_ACK=4, 
               READ_BIT=5, SEND_ACK=6, SEND_NACK=7,
               STOP1=8, STOP2=9, STOP3=10, 
               WAIT_STEP=11, NEXT_PHASE=12;

    reg [4:0] state = IDLE;
    reg [3:0] bit_cnt;
    reg [2:0] sub_step;
    reg [1:0] byte_idx; 
    reg [15:0] read_buffer;
    reg [19:0] long_timer; 

    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= IDLE; scl <= 1; sda_en <= 0; sda_out <= 1;
            phase <= 0; byte_idx <= 0; data_out <= 0;
        end else if (tick) begin 
            case (state)
                // --- INICIO ---
                IDLE: begin
                    scl <= 1; sda_en <= 1; sda_out <= 1;
                    if (long_timer == 25000) begin 
                        long_timer <= 0;
                        state <= START1;
                    end else long_timer <= long_timer + 1;
                end

                // --- START CONDITION ---
                START1: begin scl <= 1; sda_out <= 0; state <= START2; end
                START2: begin 
                    scl <= 0; 
                    state <= WRITE_BIT; 
                    bit_cnt <= 7; 
                    sub_step <= 0;
                    
                    // SELECCIÓN DEL BYTE A ENVIAR SEGÚN LA FASE
                    if (phase == 0) begin // CALIBRACIÓN
                        if (byte_idx == 0) current_byte <= SENSOR_ADDR; // Usa Parámetro
                        else if (byte_idx == 1) current_byte <= 8'h05; 
                        else if (byte_idx == 2) current_byte <= 8'h10; 
                        else current_byte <= 8'h00; 
                    end else if (phase == 1) begin // PUNTERO
                        if (byte_idx == 0) current_byte <= SENSOR_ADDR; // Usa Parámetro
                        else current_byte <= 8'h04; 
                    end else begin // LECTURA (Fase 2)
                        // --- ERROR ESTABA AQUI: Antes era 8'h81 fijo ---
                        // Ahora calculamos: Dirección Base OR 1 (para bit de lectura)
                        current_byte <= SENSOR_ADDR | 8'h01; 
                    end
                end

                // --- ESCRIBIR UN BYTE (Bit a Bit) ---
                WRITE_BIT: begin
                    case (sub_step)
                        0: begin scl<=0; sda_en<=1; sda_out<=current_byte[bit_cnt]; sub_step<=1; end
                        1: begin scl<=1; sub_step<=2; end
                        2: begin scl<=1; sub_step<=3; end
                        3: begin 
                            scl<=0; 
                            if (bit_cnt==0) begin state<=READ_ACK; sub_step<=0; end
                            else begin bit_cnt<=bit_cnt-1; sub_step<=0; end
                        end
                    endcase
                end

                // --- LEER ACK (Del sensor) ---
                READ_ACK: begin
                    case (sub_step)
                        0: begin scl<=0; sda_en<=0; sub_step<=1; end // Soltar SDA
                        1: begin scl<=1; sub_step<=2; end
                        2: begin scl<=1; sub_step<=3; end
                        3: begin 
                            scl<=0; 
                            // Lógica de siguiente paso
                            if (phase == 2 && byte_idx == 0) begin 
                                state <= READ_BIT; bit_cnt <= 7; byte_idx <= 1; sub_step <= 0;
                            end else begin
                                if (phase == 0 && byte_idx < 3) begin
                                    byte_idx <= byte_idx + 1;
                                    state <= WRITE_BIT; 
                                    bit_cnt <= 7;
                                    // Cargar siguiente byte
                                    if (byte_idx == 0) current_byte <= 8'h05;
                                    else if (byte_idx == 1) current_byte <= 8'h10;
                                    else current_byte <= 8'h00;
                                end else if (phase == 1 && byte_idx < 1) begin
                                    byte_idx <= byte_idx + 1;
                                    state <= WRITE_BIT;
                                    bit_cnt <= 7;
                                    current_byte <= 8'h04;
                                end else begin
                                    state <= STOP1; 
                                end
                            end
                        end
                    endcase
                end

                // --- LEER UN BYTE (Bit a Bit desde el sensor) ---
                READ_BIT: begin
                    case (sub_step)
                        0: begin scl<=0; sda_en<=0; sub_step<=1; end
                        1: begin scl<=1; sub_step<=2; end
                        2: begin 
                            scl<=1; 
                            if (byte_idx == 1) read_buffer[bit_cnt + 8] <= sda; // MSB
                            else read_buffer[bit_cnt] <= sda; // LSB
                            sub_step<=3; 
                        end
                        3: begin 
                            scl<=0; 
                            if (bit_cnt==0) begin 
                                if (byte_idx == 1) state<=SEND_ACK; 
                                else state<=SEND_NACK;              
                                sub_step<=0; 
                            end else begin bit_cnt<=bit_cnt-1; sub_step<=0; end
                        end
                    endcase
                end

                // --- ENVIAR ACK ---
                SEND_ACK: begin
                    case (sub_step)
                        0: begin scl<=0; sda_en<=1; sda_out<=0; sub_step<=1; end
                        1: begin scl<=1; sub_step<=2; end
                        2: begin scl<=1; sub_step<=3; end
                        3: begin 
                            scl<=0; 
                            byte_idx <= 2; 
                            state <= READ_BIT; bit_cnt <= 7; sub_step <= 0;
                        end
                    endcase
                end

                // --- ENVIAR NACK ---
                SEND_NACK: begin
                    case (sub_step)
                        0: begin scl<=0; sda_en<=1; sda_out<=1; sub_step<=1; end
                        1: begin scl<=1; sub_step<=2; end
                        2: begin scl<=1; sub_step<=3; end
                        3: begin scl<=0; state <= STOP1; end
                    endcase
                end

                // --- STOP CONDITION ---
                STOP1: begin scl<=0; sda_en<=1; sda_out<=0; state<=STOP2; end
                STOP2: begin scl<=1; state<=STOP3; end
                STOP3: begin 
                    sda_out<=1; 
                    state <= NEXT_PHASE; 
                end

                // --- GESTIÓN DE FASES ---
                NEXT_PHASE: begin
                    if (phase == 0) phase <= 1;      // Calib -> Puntero
                    else if (phase == 1) phase <= 2; // Puntero -> Lectura
                    else begin 
                        phase <= 1; // Lectura -> Puntero
                        data_out <= read_buffer; // Actualizar salida
                    end
                    
                    byte_idx <= 0;
                    state <= IDLE; 
                end
            endcase
        end
    end
endmodule
