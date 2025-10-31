/*
 * Testbench para o elevador
 */

`timescale 1ns / 1ps

module elevador_pequeno_tb;

    // Sinais
    reg CLOCK_50;
    reg [3:0] KEY;
    reg [9:0] SW;
    wire [6:0] HEX0, HEX1, HEX2, HEX3;
    wire [9:0] LEDR;
    wire [7:0] LEDG;
    
    // instancia o elevador (usa versão rápida para simulação)
    elevador_pequeno uut (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .SW(SW),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .LEDR(LEDR),
        .LEDG(LEDG)
    );
    
    // Clock 50MHz
    always #10 CLOCK_50 = ~CLOCK_50;
    
    // Funções auxiliares
    task wait_clocks;
        input integer n;
        begin
            repeat(n) @(posedge CLOCK_50);
        end
    endtask
    
    task wait_move;
        begin
            wait_clocks(110); // Espera movimento (100 ciclos + margem)
        end
    endtask
    
    task add_person;
        begin
            SW[9] = 1;
            wait_clocks(5);
            SW[9] = 0;
            wait_clocks(5);
        end
    endtask
    
    task rem_person;
        begin
            SW[8] = 1;
            wait_clocks(5);
            SW[8] = 0;
            wait_clocks(5);
        end
    endtask
    
    task call_floor;
        input [4:0] floor_mask;
        begin
            SW[4:0] = floor_mask;
            wait_clocks(10);
        end
    endtask
    
    task press_emergency;
        begin
            KEY[0] = 0;
            wait_clocks(5);
            KEY[0] = 1;
            wait_clocks(5);
        end
    endtask
    
    // Testes
    initial begin
        $display("\n╔════════════════════════════════════════════════════════════╗");
        $display("║           TESTBENCH DO ELEVADOR INTELIGENTE               ║");
        $display("╚════════════════════════════════════════════════════════════╝\n");
        
        // Inicialização
        CLOCK_50 = 0;
        KEY = 4'b1111;
        SW = 10'b0;
        wait_clocks(10);
        
        $display("Estado Inicial:");
        $display("  Andar: %0d | Pessoas: %0d | Chamadas: %b", uut.floor, uut.people, uut.calls);
        
        // Teste 1: Adicionar pessoas
        $display("\n>>> TESTE 1: Controle de Pessoas");
        add_person();
        add_person();
        add_person();
        $display("  3 pessoas adicionadas - Cheio: %b", LEDG[2]);
        if (uut.people == 3 && LEDG[2] == 1)
            $display("  ✓ PASSOU");
        else
            $display("  ✗ FALHOU");
        
        rem_person();
        $display("  Removeu 1 pessoa - Total: %0d", uut.people);
        
        // Teste 2: Movimento básico
        $display("\n>>> TESTE 2: Movimento para Andar 3");
        call_floor(5'b00100);
        $display("  Chamou andar 3");
        wait_move();
        $display("  Andar atual: %0d", uut.floor);
        wait_move();
        $display("  Andar atual: %0d", uut.floor);
        if (uut.floor == 3)
            $display("  ✓ PASSOU");
        else
            $display("  ✗ FALHOU");
        
        SW[4:0] = 5'b0;
        
        // Teste 3: Elevador cheio
        $display("\n>>> TESTE 3: Elevador Cheio");
        add_person();
        add_person();
        $display("  Elevador cheio (3 pessoas)");
        call_floor(5'b00001);
        wait_move();
        if (uut.floor == 3)
            $display("  ✓ PASSOU - Não se moveu");
        else
            $display("  ✗ FALHOU - Se moveu");
        
        SW[4:0] = 5'b0;
        rem_person();
        
        // Teste 4: Múltiplas chamadas
        $display("\n>>> TESTE 4: Múltiplas Chamadas");
        call_floor(5'b10010);
        $display("  Chamou andares 2 e 5");
        repeat(3) begin
            wait_move();
            $display("  Andar: %0d | Chamadas: %b", uut.floor, uut.calls);
        end
        
        SW[4:0] = 5'b0;
        
        // Teste 5: Emergência
        $display("\n>>> TESTE 5: Modo Emergência (190)");
        call_floor(5'b11111);
        wait_clocks(10);
        $display("  Todas chamadas ativas");
        
        $display("  🚨 Ativando emergência...");
        press_emergency();
        SW[4:0] = 5'b0;
        wait_clocks(10);
        
        if (uut.calls == 5'b0 && uut.emergency_mode == 1 && LEDG[3] == 1)
            $display("  ✓ PASSOU - Emergência ativa, chamadas zeradas");
        else
            $display("  ✗ FALHOU");
        
        $display("  Descendo...");
        repeat(6) wait_move();
        
        if (uut.floor == 1 && uut.emergency_mode == 0)
            $display("  ✓ PASSOU - Desceu até andar 1");
        else
            $display("  ✗ FALHOU");
        
        // Finalização
        wait_clocks(50);
        
        $display("\n╔════════════════════════════════════════════════════════════╗");
        $display("║                   TESTES CONCLUÍDOS!                       ║");
        $display("╚════════════════════════════════════════════════════════════╝\n");
        
        $finish;
    end
    
    // Timeout
    initial begin
        #50000000;
        $display("\n⏱️  TIMEOUT");
        $finish;
    end

endmodule

