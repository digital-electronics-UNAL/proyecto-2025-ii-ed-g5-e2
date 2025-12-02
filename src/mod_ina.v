module i2c_ina219 (
    input wire clk,             // 50MHz clock
    input wire reset,           // Reset activo bajo
    inout wire sda,             // I2C Data
    output wire scl,            // I2C Clock
    output reg [15:0] data_out  // Dato leído (16 bits)
);

    // Configuración de tiempos para 100kHz I2C
    // 50MHz / 500 = 100kHz. Usamos contadores para generar los tiempos.
    reg [8:0] clk_count = 0;
    reg i2c_clk = 1;
    
    always @(posedge clk) begin
        if (clk_count == 249) begin
            i2c_clk <= ~i2c_clk;
            clk_count <= 0;
        end else clk_count <= clk_count + 1;
    end
    
    assign scl = i2c_clk; // El reloj sale directo 

    // Máquina de Estados
    localparam STATE_IDLE = 0, STATE_START = 1, STATE_ADDR = 2, 
               STATE_READ_MSB = 3, STATE_ACK1 = 4, STATE_READ_LSB = 5, 
               STATE_NACK = 6, STATE_STOP = 7;
               
    reg [2:0] state = STATE_IDLE;
    reg [3:0] bit_cnt;
    reg [15:0] shift_reg;
    
    // Control Tri-estado SDA
    reg sda_out = 1;
    reg sda_en = 0; // 1 = Output, 0 = Input
    assign sda = (sda_en) ? sda_out : 1'bz;

    always @(negedge i2c_clk or negedge reset) begin
        if (!reset) begin
            state <= STATE_IDLE;
            sda_en <= 0;
            sda_out <= 1;
        end else begin
            case (state)
                STATE_IDLE: begin
                    sda_en <= 1; sda_out <= 1;
                    state <= STATE_START;
                end

                STATE_START: begin
                    sda_en <= 1; sda_out <= 0; // Bajada SDA con SCL alto
                    state <= STATE_ADDR;
                    bit_cnt <= 7;
                end

                STATE_ADDR: begin
                    sda_en <= 1;
                    // Dirección 0x40 (1000000) + Read bit (1) = 10000001 (0x81)
                    case (bit_cnt)
                        7: sda_out <= 1; 6: sda_out <= 0; 5: sda_out <= 0; 4: sda_out <= 0;
                        3: sda_out <= 0; 2: sda_out <= 0; 1: sda_out <= 0; 0: sda_out <= 1;
                    endcase
                    
                    if (bit_cnt == 0) begin
                        state <= STATE_READ_MSB; // Saltamos chequeo ACK del esclavo por simplicidad
                        sda_en <= 0; // Soltar línea para leer
                        bit_cnt <= 7;
                    end else bit_cnt <= bit_cnt - 1;
                end

                STATE_READ_MSB: begin
                    // La lectura real se hace en el bloque posedge, aqui solo contamos
                    if (bit_cnt == 0) begin
                        state <= STATE_ACK1;
                        sda_en <= 1; sda_out <= 0; // Master ACK
                    end else bit_cnt <= bit_cnt - 1;
                end

                STATE_ACK1: begin
                    state <= STATE_READ_LSB;
                    sda_en <= 0; // Soltar línea
                    bit_cnt <= 7;
                end

                STATE_READ_LSB: begin
                    if (bit_cnt == 0) begin
                        state <= STATE_NACK;
                        sda_en <= 1; sda_out <= 1; // Master NACK (fin)
                    end else bit_cnt <= bit_cnt - 1;
                end

                STATE_NACK: begin
                    state <= STATE_STOP;
                    sda_out <= 0; // Preparar subida STOP
                end

                STATE_STOP: begin
                    sda_out <= 1; // Subida SDA con SCL alto
                    state <= STATE_IDLE; // Repetir
                end
            endcase
        end
    end

    // Captura de datos (Sampleo en subida del reloj)
    always @(posedge i2c_clk) begin
        if (state == STATE_READ_MSB) shift_reg[bit_cnt + 8] <= sda;
        if (state == STATE_READ_LSB) shift_reg[bit_cnt] <= sda;
        if (state == STATE_STOP) data_out <= shift_reg; // Actualizar salida final
    end

endmodule
