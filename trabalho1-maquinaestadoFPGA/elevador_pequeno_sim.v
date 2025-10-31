module elevador_pequeno (
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [9:0] LEDR,
    output [7:0] LEDG
);

    localparam IDLE = 2'b00, UP = 2'b01, DOWN = 2'b10;
    
    reg [1:0] state = IDLE;
    reg [2:0] floor = 3'd1;
    reg [4:0] calls = 5'b0;
    reg [1:0] people = 2'b0;  // 0 a 3 pessoas
    reg emergency_mode = 1'b0;  // Modo emergência
    reg key0_prev, sw9_prev, sw8_prev;
    
    always @(posedge CLOCK_50) begin
        key0_prev <= ~KEY[0];
        sw9_prev <= SW[9];
        sw8_prev <= SW[8];
    end
    
    wire emergency_pressed = ~key0_prev && ~KEY[0];  // Detecta borda de descida do KEY[0]
    wire add_person = ~sw9_prev && SW[9];
    wire rem_person = ~sw8_prev && SW[8];
    wire is_full = (people == 2'd3);
    wire [4:0] sw_calls = SW[4:0];

    // Divisor de clock para movimento automático
    // VERSÃO RÁPIDA PARA SIMULAÇÃO
    reg [7:0] counter = 0;
    
    // Gera um pulso a cada 100 ciclos (para simulação rápida)
    wire move_tick = (counter == 8'd100);
    
    always @(posedge CLOCK_50) begin
        if (counter == 8'd100) begin
            counter <= 0;
        end else begin
            counter <= counter + 1'b1;
        end
    end
    
    // Lógica do elevador: move automaticamente
    reg [2:0] next_floor;
    
    always @(posedge CLOCK_50) begin
        // Ativa modo emergência quando KEY[0] for pressionado
        if (emergency_pressed) begin
            emergency_mode <= 1'b1;
            calls <= 5'b0;  // Descarta todas as requisições
        end
        // Controle de pessoas (não funciona em modo emergência)
        else if (!emergency_mode) begin
            if (add_person && people < 2'd3) people <= people + 1;
            if (rem_person && people > 2'd0) people <= people - 1;
        end
        
        // Modo emergência ativo: mantém chamadas zeradas
        if (emergency_mode) begin
            calls <= 5'b0;  // Força calls zeradas durante TODA a emergência
        end
        // Move automaticamente quando move_tick ocorrer
        else if (move_tick) begin
            next_floor = floor;  // Assume que não move
            
            // Modo normal: atende chamadas
            if (!is_full && calls != 5'b0) begin
                case (floor)
                    3'd1: begin
                        if (calls[4] || calls[3] || calls[2] || calls[1]) next_floor = 3'd2;
                    end
                    3'd2: begin
                        if (calls[4] || calls[3] || calls[2]) next_floor = 3'd3;
                        else if (calls[0]) next_floor = 3'd1;
                    end
                    3'd3: begin
                        if (calls[4] || calls[3]) next_floor = 3'd4;
                        else if (calls[1] || calls[0]) next_floor = 3'd2;
                    end
                    3'd4: begin
                        if (calls[4]) next_floor = 3'd5;
                        else if (calls[2] || calls[1] || calls[0]) next_floor = 3'd3;
                    end
                    3'd5: begin
                        if (calls[3] || calls[2] || calls[1] || calls[0]) next_floor = 3'd4;
                    end
                endcase
                
                // Limpa chamada do andar onde acabou de chegar
                case (next_floor)
                    3'd1: calls[0] <= 1'b0;
                    3'd2: calls[1] <= 1'b0;
                    3'd3: calls[2] <= 1'b0;
                    3'd4: calls[3] <= 1'b0;
                    3'd5: calls[4] <= 1'b0;
                endcase
            end
            
            // Atualiza andar
            floor <= next_floor;
            
            // Atualiza estado baseado no movimento
            if (next_floor > floor) begin
                state <= UP;
            end else if (next_floor < floor) begin
                state <= DOWN;
            end else begin
                state <= IDLE;
            end
        end
        // Registra novas chamadas continuamente (apenas em modo normal, sem move_tick)
        else begin
            calls <= calls | sw_calls;
        end
        
        // Lógica de movimento durante emergência
        if (move_tick && emergency_mode) begin
            if (floor > 3'd1) begin
                floor <= floor - 1'b1;  // Desce um andar
                state <= DOWN;
            end else begin
                // Chegou no térreo, desativa emergência
                emergency_mode <= 1'b0;
                state <= IDLE;
            end
        end
    end
    
    // Display de 7 segmentos para o andar (HEX0)
    reg [6:0] seg_floor;
    always @(*) begin
        if (emergency_mode) begin
            seg_floor = 7'b0111111;  // 0 (para "190")
        end else begin
            case (floor)
                3'd1: seg_floor = 7'b0000110;  // 1
                3'd2: seg_floor = 7'b1011011;  // 2
                3'd3: seg_floor = 7'b1001111;  // 3
                3'd4: seg_floor = 7'b1100110;  // 4
                3'd5: seg_floor = 7'b1101101;  // 5
                default: seg_floor = 7'b0000000;
            endcase
        end
    end

    reg [6:0] seg_direction;
    always @(*) begin
        if (emergency_mode) begin
            seg_direction = 7'b1101111;  // 9 (para "190")
        end else begin
            case (state)
                UP:      seg_direction = 7'b1101101;  // 5 (Subindo)
                DOWN:    seg_direction = 7'b1011110;  // d (Descendo)
                IDLE:    seg_direction = 7'b1110011;  // P (Parado)
                default: seg_direction = 7'b0000000;
            endcase
        end
    end
    
    // Display de 7 segmentos para o número de pessoas (HEX2)
    reg [6:0] seg_people;
    always @(*) begin
        if (emergency_mode) begin
            seg_people = 7'b0000110;  // 1 (para "190")
        end else begin
            case (people)
                2'd0: seg_people = 7'b0111111;  // 0
                2'd1: seg_people = 7'b0000110;  // 1
                2'd2: seg_people = 7'b1011011;  // 2
                2'd3: seg_people = 7'b1001111;  // 3
                default: seg_people = 7'b0000000;
            endcase
        end
    end
    
    assign HEX0 = ~seg_floor;      // Andar atual (1-5) ou "0" (para "190")
    assign HEX1 = ~seg_direction;  // Direção (S/D/P) ou "9" (para "190")
    assign HEX2 = ~seg_people;     // Número de pessoas (0-3) ou "1" (para "190")
    assign HEX3 = 7'b1111111;      // Sempre apagado (todos segmentos off)
    assign LEDR[4:0] = calls;      // Chamadas dos andares
    assign LEDR[9:8] = people;     // Número de pessoas (também nos LEDs)
    assign LEDR[7:5] = 3'b0;
    assign LEDG[0] = (state == UP);       // LED verde 0: subindo
    assign LEDG[1] = (state == DOWN);     // LED verde 1: descendo
    assign LEDG[2] = is_full;             // LED verde 2: cheio (3 pessoas)
    assign LEDG[3] = emergency_mode;      // LED verde 3: modo emergência
    assign LEDG[7:4] = 4'b0;

endmodule