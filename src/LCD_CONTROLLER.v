module LCD1602_controller #(parameter NUM_COMMANDS = 4, 
                                      NUM_DATA_ALL = 32,  
                                      NUM_DATA_PERLINE = 16,
                                      DATA_BITS = 8,
                                      COUNT_MAX = 800000)(
    input clk,            
    input reset,          
    input ready_i,
    //los tres datós dinámicos que provienen de los sensores
    input [DATA_BITS-1:0] data_1_sen,
    input [DATA_BITS-1:0] data_2_sen,
    input [DATA_BITS-1:0] data_3_sen,
    input [n:0] LCD_mode,
    output reg rs,        
    output reg rw,
    output enable,    
    output reg [DATA_BITS-1:0] data

);

// Definir los estados de la FSM
localparam IDLE = 3'b000;
localparam CONFIG_CMD1 = 3'b001;
localparam WR_STATIC_TEXT_1L = 3'b010;
localparam CONFIG_CMD2 = 3'b011;
localparam WR_STATIC_TEXT_2L = 3'b100;
localparam WRITE_DYNAMIC_TXT = 3'b101;

localparam SET_CURSOR = 2'b00;
//Cada uno de los estados para escribir cada dígito
localparam WRITE_C = 2'b01;
localparam WRITE_D = 2'b10;
localparam WRITE_U = 2'b11;

reg [2:0] fsm_state;
reg [2:0] next_state;
reg clk_16ms;
reg [1:0] sel_dyna;
// Contador para saber en que posición estamos escribiendo el dato dinámico
reg [1:0] cursor_counter;

// Comandos de configuración
localparam CLEAR_DISPLAY = 8'h01;
localparam SHIFT_CURSOR_RIGHT = 8'h06;
localparam DISPON_CURSOROFF = 8'h0C;
localparam DISPON_CURSORBLINK = 8'h0E;
localparam LINES2_MATRIX5x8_MODE8bit = 8'h38;
localparam START_2LINE = 8'hC0;

// Definir un contador para el divisor de frecuencia
reg [$clog2(COUNT_MAX)-1:0] clk_counter;
// Definir un contador para controlar el envío de comandos
reg [$clog2(NUM_COMMANDS):0] command_counter;
// Definir un contador para controlar el envío de datos
reg [$clog2(NUM_DATA_PERLINE):0] data_counter;

// Banco de registros
reg [DATA_BITS-1:0] static_data_mem [0: NUM_DATA_ALL-1];
reg [DATA_BITS-1:0] config_mem [0:NUM_COMMANDS-1]; 
//Bancos de registros para datos dinámicos
reg [DATA_BITS-1:0] cursor_data [0:3-1];
reg [DATA_BITS-1:0] input_data [0:3-1];

initial begin
    fsm_state <= IDLE;
    command_counter <= 'b0;
    data_counter <= 'b0;
    rs <= 1'b0;
    rw <= 1'b0;
    data <= 8'b0;
    clk_16ms <= 1'b0;
    clk_counter <= 'b0;
    $readmemh("/home/sebastian/Descargas/data.txt", static_data_mem);    
	config_mem[0] <= LINES2_MATRIX5x8_MODE8bit;
	config_mem[1] <= SHIFT_CURSOR_RIGHT;
	config_mem[2] <= DISPON_CURSOROFF;
	config_mem[3] <= CLEAR_DISPLAY;
    //Posiciones iniciales para los datos dinámicos
    cursor_data[0] <= 8'h80+8'h05;
    cursor_data[1] <= 8'h80+8'h09;
    cursor_data[2] <= 8'hC0+8'h05;
    //Valores iniciales para los datos dinámicos
    input_data[0] <= 8'h00;
    input_data[1] <= 8'h00;
    input_data[2] <= 8'h00;
end

always @(posedge clk) begin
    if (clk_counter == COUNT_MAX-1) begin
        clk_16ms <= ~clk_16ms;
        clk_counter <= 'b0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end


always @(posedge clk_16ms)begin
    if(reset == 0)begin
        fsm_state <= IDLE;
    end else begin
        fsm_state <= next_state;
    end
end

always @(*) begin
    case(fsm_state)
        IDLE: begin
            next_state <= (ready_i)? CONFIG_CMD1 : IDLE;
        end
        CONFIG_CMD1: begin 
            next_state <= (command_counter == NUM_COMMANDS)? WR_STATIC_TEXT_1L : CONFIG_CMD1;
        end
        WR_STATIC_TEXT_1L:begin
			next_state <= (data_counter == NUM_DATA_PERLINE)? CONFIG_CMD2 : WR_STATIC_TEXT_1L;
        end
        CONFIG_CMD2: begin 
            next_state <= WR_STATIC_TEXT_2L;
        end
		WR_STATIC_TEXT_2L: begin
			next_state <= (data_counter == NUM_DATA_PERLINE)? WRITE_DYNAMIC_TXT: WR_STATIC_TEXT_2L;
		end
        //Se tiene de defecto el caso de escribir el texto dinámico
        default: next_state = WRITE_DYNAMIC_TXT;
    endcase
end

always @(posedge clk_16ms) begin
    if (reset == 0) begin
        command_counter <= 'b0;
        data_counter <= 'b0;
		data <= 'b0;
        //Cuando hay reseteo se reinicia el contador de cursor
        cursor_counter <='b0;
        sel_dyna <='b0;
        $readmemh("/home/sebastian/Descargas/data.txt", static_data_mem);
    end else begin
        case (next_state)
            IDLE: begin
                command_counter <= 'b0;
                data_counter <= 'b0;
                rs <= 1'b0;
                data  <= 'b0;
            end
            CONFIG_CMD1: begin
			    rs <= 1'b0; 	
                command_counter <= command_counter + 1;
				data <= config_mem[command_counter];
            end
            WR_STATIC_TEXT_1L: begin
                data_counter <= data_counter + 1;
                rs <= 1'b1; 
				data <= static_data_mem[data_counter];
            end
            CONFIG_CMD2: begin
                data_counter <= 'b0;
				rs <= 1'b0; 
				data <= START_2LINE;
            end
			WR_STATIC_TEXT_2L: begin
                data_counter <= data_counter + 1;
                rs <= 1'b1; 
				data <= static_data_mem[NUM_DATA_PERLINE + data_counter];
                //Al sel_dyna se le asigna el valor de SET_CURSOR para iniciar
                sel_dyna <= SET_CURSOR;
                //Se reseteo el contador de cursor
                cursor_counter <= 2'b00;
            end
            WRITE_DYNAMIC_TXT: begin
                case(sel_dyna)
                    // SET_CURSOR por medio del banco de registros cursor_data indica la posición donde se va a escribir el dato
                    SET_CURSOR: begin
                        rs <= 1'b0;
                        data <= cursor_data[cursor_counter];
                        sel_dyna <= WRITE_C;
                    end
                    //Se cálcula el número de las centenas 
                    WRITE_C:begin
                        rs <=1'b1;
                        data <= ((input_data[cursor_counter]-input_data[cursor_counter]%100)/100)+8'h30;
                        sel_dyna <= WRITE_D;
                    end
                    //Se cálcula el número de las decenas
                    WRITE_D: begin
                        rs <= 1'b1;
                        data <= ((input_data[cursor_counter]%100-input_data[cursor_counter]%10)/10)+8'h30;
                        sel_dyna <= WRITE_U;
                    end
                    //Se cálcula el número de las unidades
                    WRITE_U: begin
                        rs <=1'b1;
                        data <= (input_data[cursor_counter]%10)+8'h30;
                    //CUando se termina de escribir un dato, se incrementa el contador de cursor para pasar al siguiente
                         if (cursor_counter==2'b10) begin
                            cursor_counter <= 2'b00;
                        end else begin
                            cursor_counter <= cursor_counter+1;
                        end
                        sel_dyna <= SET_CURSOR;
                    end
                endcase
            end
        endcase
    end
end

//Proceso resetear los datos
always@(posedge clk) begin
    if (reset == 0) begin
        input_data[0] <= 8'h00;
        input_data[1] <= 8'h00;
        input_data[2] <= 8'h00;
        cursor_data[0] <= 8'h80+8'h05;
        cursor_data[1] <= 8'h80+8'h09;
        cursor_data[2] <= 8'hC0+8'h05;
    end else begin
        input_data[0] <= data_1_sen;
        input_data[1] <= data_2_txt;
        input_data[2] <= data_3_txt;
    end

end

assign enable = clk_16ms;

endmodule
