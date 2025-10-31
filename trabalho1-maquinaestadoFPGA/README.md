# 🏢 Elevador - Sistema Digital

Sistema de controle de elevador com 5 andares, limite de 2 pessoas e modo de emergência desenvolvido em Verilog.

---

## 📦 Arquivos do Projeto

| Arquivo                  | Descrição                       | Linhas |
| ------------------------ | ------------------------------- | ------ |
| `elevador_pequeno.v`     | Código principal para FPGA      | 204    |
| `elevador_pequeno_sim.v` | Versão otimizada para simulação | 205    |
| `elevador_pequeno_tb.v`  | Testbench automatizado          | ~190   |

---

### **Características do Sistema**

#### **Andares**

- 5 andares (1 ao 5)
- Inicia no andar 1
- Movimento automático (1 andar/segundo)

#### **Capacidade**

- Máximo: 3 pessoas
- LED indica quando está cheio
- Não atende chamadas quando cheio

#### **Modo Emergência**

- Botão KEY[0]
- Desce suavemente até o andar 1
- Descarta todas as chamadas
- Mostra "190" nos displays (Bombeiros)

---

## 🎮 Controles

### **Botões (KEY)**

| Botão  | Função                                               |
| ------ | ---------------------------------------------------- |
| KEY[0] | 🚨 **Emergência** - Desce até andar 1 e mostra "190" |
| KEY[1] | _(não usado)_                                        |
| KEY[2] | _(não usado)_                                        |
| KEY[3] | _(não usado)_                                        |

### **Switches (SW)**

| Switch  | Função              |
| ------- | ------------------- |
| SW[0]   | 📞 Chamar andar 1   |
| SW[1]   | 📞 Chamar andar 2   |
| SW[2]   | 📞 Chamar andar 3   |
| SW[3]   | 📞 Chamar andar 4   |
| SW[4]   | 📞 Chamar andar 5   |
| SW[5-7] | _(não usados)_      |
| SW[8]   | ➖ Remover pessoa   |
| SW[9]   | ➕ Adicionar pessoa |

---

## 📺 Displays e LEDs

### **Displays de 7 Segmentos**

| Display  | Modo Normal         | Modo Emergência |
| -------- | ------------------- | --------------- |
| **HEX0** | Andar atual (1-5)   | **0**           |
| **HEX1** | Direção (S/D/P)     | **9**           |
| **HEX2** | Nº de pessoas (0-3) | **1**           |
| **HEX3** | _(apagado)_         | _(apagado)_     |

**Legenda HEX1:**

- **S** = Subindo (UP)
- **D** = Descendo (DOWN)
- **P** = Parado (IDLE)

### **LEDs Vermelhos (LEDR)**

| LED       | Função                      |
| --------- | --------------------------- |
| LEDR[0]   | Chamada do andar 1 ativa    |
| LEDR[1]   | Chamada do andar 2 ativa    |
| LEDR[2]   | Chamada do andar 3 ativa    |
| LEDR[3]   | Chamada do andar 4 ativa    |
| LEDR[4]   | Chamada do andar 5 ativa    |
| LEDR[8-9] | Número de pessoas (binário) |

### **LEDs Verdes (LEDG)**

| LED     | Função                        |
| ------- | ----------------------------- |
| LEDG[0] | 🟢 Elevador subindo           |
| LEDG[1] | 🟢 Elevador descendo          |
| LEDG[2] | 🟢 Elevador cheio (3 pessoas) |
| LEDG[3] | 🟢 Modo emergência ativo      |

---

## 🚀 Como Usar

### **Na FPGA**

1. **Compilar o projeto:**

   - Use `elevador_pequeno.v` no Quartus
   - Configurar pinos conforme placa DE1-SoC
   - Compilar e gravar na FPGA

2. **Operação normal:**

   - Ligue switches SW[0-4] para chamar andares
   - Use SW[9] para adicionar pessoas
   - Use SW[8] para remover pessoas
   - Elevador se move automaticamente (1 andar/segundo)

3. **Modo emergência:**
   - Pressione KEY[0]
   - Displays mostram "190"
   - Elevador desce até andar 1
   - Todas chamadas são canceladas

### **Simulação**

#### **Requisitos:**

```bash
sudo apt install iverilog
```

#### **Compilar e Simular:**

```bash
cd sistemas_digitais
iverilog -o elevador_sim elevador_pequeno_sim.v elevador_pequeno_tb.v
vvp elevador_sim
```

#### **Resultado Esperado:**

```
╔════════════════════════════════════════════════════════════╗
║           TESTBENCH DO ELEVADOR INTELIGENTE               ║
╚════════════════════════════════════════════════════════════╝

>>> TESTE 1: Controle de Pessoas
  ✓ PASSOU
>>> TESTE 2: Movimento para Andar 3
  ✓ PASSOU
>>> TESTE 3: Elevador Cheio
  ✓ PASSOU
>>> TESTE 4: Múltiplas Chamadas
  ✓ PASSOU
>>> TESTE 5: Modo Emergência (190)
  ✓ PASSOU

╔════════════════════════════════════════════════════════════╗
║                   TESTES CONCLUÍDOS!                       ║
╚════════════════════════════════════════════════════════════╝
```

---

## 🔧 Arquitetura Interna

### **Estados da FSM**

```
IDLE (00) ─┬─> UP (01)
           └─> DOWN (10)
```

- **IDLE**: Parado, aguarda chamadas
- **UP**: Subindo
- **DOWN**: Descendo

### **Lógica de Movimento**

1. **Andar atual**: Limpa chamada ao chegar
2. **Decisão**: Verifica chamadas acima/abaixo
3. **Prioridade**: Subir > Descer
4. **Velocidade**: 1 andar por segundo (ajustável)

### **Divisor de Clock**

| Versão                               | Contador          | Frequência    |
| ------------------------------------ | ----------------- | ------------- |
| FPGA (`elevador_pequeno.v`)          | 50.000.000 ciclos | ~1 Hz (1 seg) |
| Simulação (`elevador_pequeno_sim.v`) | 100 ciclos        | ~500 kHz      |

**Diferença:** Apenas o valor do contador - resto do código é idêntico!

---

## 🧪 Testes Implementados

O testbench (`elevador_pequeno_tb.v`) verifica:

1. **Controle de Pessoas**

   - Adiciona até 3 pessoas
   - Recusa 4ª pessoa
   - Remove pessoas corretamente

2. **Movimento Básico**

   - Sobe do andar 1 → 3
   - LED apaga ao chegar

3. **Elevador Cheio**

   - Não atende chamadas quando cheio
   - LEDG[2] acende

4. **Múltiplas Chamadas**

   - Atende várias chamadas
   - Prioriza direção correta

5. **Modo Emergência**
   - Chamadas zeradas imediatamente
   - Desce suavemente até andar 1
   - Display mostra "190"
   - LEDG[3] acende

---

## 📊 Especificações de Tempo

### **FPGA (Real)**

- Clock: 50 MHz
- Movimento: 1 andar/segundo
- Emergência: ~4 segundos (do andar 5 ao 1)

### **Simulação**

- Clock: 50 MHz (simulado)
- Movimento: 100 ciclos (~2 μs simulados)
- Teste completo: ~30 ms simulados

---

## 🎯 Funcionalidades Extras

- ✅ Movimento automático (sem precisar clicar)
- ✅ Atende chamadas ao passar pelos andares
- ✅ Prioriza direção de movimento
- ✅ Modo emergência suave (não teleporta)
- ✅ Display "190" na emergência
- ✅ LED de elevador cheio
- ✅ Indicadores visuais de direção

---

## 📝 Notas de Desenvolvimento

### **Decisões de Design**

1. **Por que 3 pessoas?**

   - Usa 2 bits: `people[1:0]` = 00, 01, 10, 11
   - Valor 11 (3) como máximo

2. **Por que "190"?**

   - Número de emergência dos Bombeiros no Brasil
   - Easter egg sensacional

3. **Por que movimento automático?**

   - Mais realista (elevadores reais não precisam de cliques)
   - Melhor UX na FPGA
   - Evita problemas com ações em simultâneo

4. **Por que dois arquivos?**
   - FPGA precisa de clock lento (real)
   - Simulação precisa de clock rápido (eficiência)
