# 03 — Lógica do jogo: módulo Velha

## Interface

O arquivo [Velha.v](../projeto/Velha.v) contém a memória e as regras de transição da partida. A interface real é:

```verilog
module Velha(KEY, SW, board, LEDR, winA, winB, draw, gameover, player);

    input [3:0] KEY;
    input [3:0] SW;

    output reg [17:0] board;
    output reg [8:0]  LEDR;
    output reg winA;
    output reg winB;
    output reg draw;
    output reg gameover;
    output reg player;
```

| Sinal | Direção e largura | Função |
|---|---|---|
| `KEY` | Entrada, 4 bits | KEY0 reinicia; KEY2 confirma |
| `SW` | Entrada, 4 bits | Seleciona a casa em binário |
| `board` | Saída, 18 bits | Estado das nove casas |
| `LEDR` | Saída, 9 bits | Decodificação do resultado |
| `winA`, `winB` | Saídas, 1 bit cada | Vitória azul e vermelha |
| `draw` | Saída, 1 bit | Empate |
| `gameover` | Saída, 1 bit | Encerramento e bloqueio |
| `player` | Saída, 1 bit | Participante da próxima jogada aceita |

Os sinais de resultado são registradores de estado, embora também sejam expostos como portas. KEY1 e KEY3 não são consultados pelo código. Os registradores auxiliares `position` e `aux`, de cinco bits, calculam os índices dos dois bits da casa selecionada.

## Tabuleiro de 18 bits

Para a casa de número `n`, com `1 ≤ n ≤ 9`, o par é `board[2*n-1 : 2*n-2]`. A ordem dos bits deve ser mantida na interpretação das cores:

| Par da casa | Estado | `player` ao registrar | Sinal de vitória |
|---|---|---|---|
| `00` | Vazia | — | — |
| `01` | Azul, jogador A | `0` | `winA` |
| `10` | Vermelho, jogador B | `1` | `winB` |
| `11` | Fora dos estados produzidos por jogadas válidas | — | — |

| Casa | `SW[3:0]` | Par em `board` | Bit azul | Bit vermelho |
|---|---|---|---|---|
| 1 | `0001` | `[1:0]` | 0 | 1 |
| 2 | `0010` | `[3:2]` | 2 | 3 |
| 3 | `0011` | `[5:4]` | 4 | 5 |
| 4 | `0100` | `[7:6]` | 6 | 7 |
| 5 | `0101` | `[9:8]` | 8 | 9 |
| 6 | `0110` | `[11:10]` | 10 | 11 |
| 7 | `0111` | `[13:12]` | 12 | 13 |
| 8 | `1000` | `[15:14]` | 14 | 15 |
| 9 | `1001` | `[17:16]` | 16 | 17 |

Por exemplo, uma jogada azul na casa 5 coloca `board[8]` em 1; uma jogada vermelha nessa casa colocaria `board[9]` em 1. A verificação de ocupação impede que ambos sejam escritos por jogadas válidas na mesma partida.

## Reset e confirmação

```verilog
    wire rst = !KEY[0];
    wire clk = !KEY[2];


    always @(posedge clk or posedge rst) begin


        if (rst) begin
            board    <= 18'b0;
            winA     <= 0;
            winB     <= 0;
            draw     <= 0;
            gameover <= 0;
            player   <= 0;
        end
```

`!KEY[0]` ativa `rst` quando KEY0 é pressionado. O evento `posedge rst` torna o reset assíncrono em relação à confirmação. O vetor `board` é zerado, os quatro indicadores de resultado/encerramento recebem zero e `player = 0` estabelece o primeiro turno azul.

`!KEY[2]` produz `clk`. Como o botão é ativo em nível baixo, pressioná-lo provoca a borda de subida de `clk`; soltá-lo provoca a borda oposta. O bloco sequencial registra uma jogada no primeiro evento. As variáveis auxiliares não são limpas no reset, mas são recalculadas antes de cada consulta a uma casa válida.

## Seleção e ocupação

A primeira condição é `!gameover`: uma partida encerrada só volta a aceitar jogadas após reset. A segunda é `(SW <= 9) && (SW > 0)`, que rejeita zero e os valores de 10 a 15, sem alterar o turno.

O índice do bit do participante é calculado por:

```verilog
                position = (SW * 2 + player) - 2;
```

Equivalentemente, `position = 2*(n-1) + player`. Para `player = 0`, o resultado é o bit par, associado ao azul; para `player = 1`, é o bit ímpar, associado ao vermelho. Na casa 9, por exemplo, os resultados são 16 e 17, ambos dentro do vetor de 18 bits.

```verilog
                aux = player ? position - 1 : position + 1;
```

O operador condicional `?:` escolhe o outro bit da mesma casa. Para o azul, `aux = position + 1`; para o vermelho, `aux = position - 1`. Assim, ambos os participantes verificam os mesmos dois bits antes de escrever.

```verilog
                if (board[position] || board[aux]) begin
                    //mensagem de erro
                end
                else begin //se a casa jogada nao esta preenchida
                    board[position] = 1;
                    player <= !player;
```

Se `board[position] || board[aux]` for verdadeiro, a casa está ocupada. O ramo correspondente não executa atribuições: a marca existente e o turno são conservados. O comentário sobre mensagem de erro não corresponde a uma saída implementada; não há mensagem textual, LED de erro ou consumo do turno.

Na jogada aceita, `board[position] = 1` utiliza **atribuição bloqueante**. As expressões seguintes consultam o tabuleiro já com a nova marca, dentro da mesma execução do bloco. `player <= !player` utiliza atribuição não bloqueante, agendando a alternância para o fim do evento. Essa distinção explica por que a vitória é reconhecida na própria confirmação da terceira marca alinhada.

## Oito combinações geométricas

| Tipo | Casas | Bits azuis | Bits vermelhos |
|---|---|---|---|
| Linha superior | 1, 2, 3 | 0, 2, 4 | 1, 3, 5 |
| Linha central | 4, 5, 6 | 6, 8, 10 | 7, 9, 11 |
| Linha inferior | 7, 8, 9 | 12, 14, 16 | 13, 15, 17 |
| Coluna esquerda | 1, 4, 7 | 0, 6, 12 | 1, 7, 13 |
| Coluna central | 2, 5, 8 | 2, 8, 14 | 3, 9, 15 |
| Coluna direita | 3, 6, 9 | 4, 10, 16 | 5, 11, 17 |
| Diagonal principal | 1, 5, 9 | 0, 8, 16 | 1, 9, 17 |
| Diagonal secundária | 3, 5, 7 | 4, 8, 12 | 5, 9, 13 |

```verilog
                    if ( /*linhas p0*/ (board[0]&board[2]&board[4]) || (board[6]&board[8]&board[10]) || (board[12]&board[14]&board[16])
                     /*colunas p0*/ || (board[0]&board[6]&board[12]) || (board[2]&board[8]&board[14]) || (board[4]&board[10]&board[16])
                     /*diagonais p0*/ || (board[0]&board[8]&board[16]) || (board[4]&board[8]&board[12])
                   ) begin
                    winA <= 1;
                    gameover <= 1;
                end

                else if ( /*linhas p1*/ (board[1]&board[3]&board[5]) || (board[7]&board[9]&board[11]) || (board[13]&board[15]&board[17])
                     /*colunas p1*/ || (board[1]&board[7]&board[13]) || (board[3]&board[9]&board[15]) || (board[5]&board[11]&board[17])
                     /*diagonais p1*/ || (board[1]&board[9]&board[17]) || (board[5]&board[9]&board[13])
                   ) begin
                    winB <= 1;
                    gameover <= 1;
                end
```

Cada operador `&` exige as três marcas de uma combinação. Os operadores `||` aceitam qualquer uma das oito combinações. O primeiro ramo registra `winA` e `gameover`; o segundo registra `winB` e `gameover`. O ramo vermelho é `else if`, portanto só é avaliado quando o azul não venceu. Em partidas válidas, o bloqueio após a primeira vitória impede que os dois resultados sejam produzidos simultaneamente.

## Empate e encerramento

Após as condições de vitória, o código verifica se os nove pares estão ocupados. Cada expressão como `(board[0] | board[1])` representa a ocupação de uma casa; o `&&` entre as nove expressões exige ocupação total. Esse ramo registra `draw = 1` e `gameover = 1`.

A ordem é decisiva: uma vitória na nona jogada é reconhecida antes da ocupação total, portanto não se transforma em empate. Os indicadores permanecem registrados até KEY0. `gameover` impede novas escritas, inclusive em casas ainda vazias.

O turno também alterna na jogada vencedora. Depois de uma vitória azul, `player` vale 1; depois de uma vitória vermelha, vale 0. Para identificar o vencedor, devem ser usados `winA` e `winB`, e não o valor final de `player`.

## LEDs

```verilog
    always @(*) begin
        LEDR = 9'b0;
        if (winA)     LEDR[3:0] = 4'b1111;
        if (winB)     LEDR[7:4] = 4'b1111;
        if (gameover) LEDR[8]   = 1'b1;
    end
```

A atribuição inicial zera todos os LEDs e define uma saída para qualquer combinação dos sinais, evitando a necessidade de conservar um valor anterior nesse bloco combinacional.

| Resultado | LEDs acesos | `LEDR[8:0]` |
|---|---|---|
| Partida em andamento | Nenhum | `000000000` |
| Vitória azul | 0 a 3 e 8 | `100001111` |
| Vitória vermelha | 4 a 7 e 8 | `111110000` |
| Empate | Apenas 8 | `100000000` |

Os exemplos de partidas estão em [Utilização e resultados](08-utilizacao-e-resultados.md). A regressão funcional e a adequação pontual da expressão da diagonal são registradas em [Validação](09-validacao.md).

---

[Capítulo anterior](02-arquitetura.md) · [Índice](../README.md#roteiro-de-estudo) · [Próximo capítulo](04-geracao-vga.md)
