# 01 — Introdução e fundamentos

## Objetivos e organização

O sistema implementa uma partida de jogo da velha diretamente em circuitos digitais configurados na FPGA. Os objetivos são representar o estado de uma partida em bits, controlar transições por eventos, avaliar condições lógicas e transformar os dados armazenados em uma imagem com sincronismo VGA.

O estudo pode seguir o caminho dos sinais: as chaves e os botões alimentam [Velha.v](../projeto/Velha.v); o tabuleiro alimenta [VGA.v](../projeto/VGA.v); as cores e as coordenadas se relacionam com [VGA_SYNC.vhd](../projeto/VGA_SYNC.vhd); o [esquemático Block2](../projeto/Block2.bdf) integra as interfaces físicas. O projeto pertence à disciplina de Sistemas Digitais do curso de Engenharia de Computação da UFSCar, em 2026.

## FPGA e recursos da DE1

Uma FPGA (*Field-Programmable Gate Array*) contém recursos lógicos e conexões configuráveis. A síntese transforma a descrição HDL em uma rede de circuitos; o posicionamento e o roteamento distribuem essa rede no dispositivo. Após a configuração, os blocos trabalham concorrentemente, de acordo com os sinais e clocks presentes.

A Terasic DE1 utilizada contém o Cyclone II **EP2C20F484C7**. Para este experimento, interessam o oscilador de 50 MHz, as chaves, os quatro botões, os LEDs, o USB-Blaster integrado e a saída VGA com rede resistiva de quatro bits por canal. O projeto conecta apenas o bit 3 de cada canal RGB. A placa também possui memórias e outros periféricos que não são utilizados pelo circuito. A [especificação oficial da DE1](https://www.terasic.com.tw/cgi-bin/page/archive.pl?CategoryNo=165&Language=English&No=83&PartNo=2) descreve esses recursos.

## Lógica combinacional e sequencial

Uma rede **combinacional** calcula saídas a partir dos valores atuais das entradas. Por exemplo, o bloco `always @(*)` de `Velha` converte `winA`, `winB` e `gameover` no padrão dos LEDs. Não é preciso pressionar outro botão para que essa decodificação acompanhe uma mudança dos sinais de resultado.

Um circuito **sequencial** conserva estado entre eventos. O tabuleiro, o jogador e os indicadores de encerramento são mantidos no bloco `always @(posedge clk or posedge rst)`. Uma mudança isolada de `SW` não modifica a partida: é necessário o evento de confirmação. O reset constitui a exceção assíncrona, pois pode limpar os registradores sem aguardar uma jogada.

Em [VGA.v](../projeto/VGA.v), as expressões que identificam regiões são cálculos lógicos, mas o bloco que as executa é acionado em `posedge clk`: as saídas de cor são atualizadas em eventos do relógio de pixels. Em `VGA_SYNC`, contadores e saídas também são atualizados por clock. Portanto, a função de desenhar uma região e o modo de registrar sua saída devem ser distinguidos.

## Representação binária e registradores

Um bit representa dois níveis lógicos. Quatro bits representam 16 combinações, de `0000` a `1111`; por isso, `SW[3:0]` comporta os valores de 1 a 9 e também valores que a lógica rejeita. A seleção `0101`, por exemplo, representa a casa 5.

O tabuleiro usa **18 bits**, organizados em nove pares. Cada par armazena `00` para vazio, `01` para azul ou `10` para vermelho. A escrita `board[1:0]` identifica os dois bits da primeira casa. O vetor inteiro permite que todas as casas sejam consultadas pelas expressões de vitória e pela lógica gráfica.

No Verilog, `reg` é um tipo de variável usado em blocos procedurais; seu nome, isoladamente, não garante a existência de um registrador físico. O hardware inferido depende das atribuições e da sensibilidade do bloco. No controle do jogo, a conservação do tabuleiro entre eventos é que caracteriza a memória de estado.

## Verilog e VHDL no mesmo projeto

Verilog e VHDL descrevem hardware, incluindo portas, sinais, processos e relações temporais. A sintaxe difere: Verilog utiliza `module`, `always` e vetores como `[17:0]`; VHDL utiliza `entity`, `architecture`, `process` e `STD_LOGIC_VECTOR(17 DOWNTO 0)`. Ambas as linguagens permitem expressar lógica combinacional e sequencial.

Neste projeto, `Velha` e `VGA` são Verilog; `VGA_SYNC` e `video_PLL` são VHDL. O Quartus reconhece as linguagens pelas atribuições de arquivo do [Velha.qsf](../projeto/Velha.qsf) e conecta os blocos pelo esquemático. O nome de um arquivo não deve ser usado como única evidência de linguagem: o sincronizador também existia com sufixo `.v`, embora seu conteúdo fosse VHDL. A configuração ativa já referencia a versão `.vhd`.

## Clock, evento de confirmação e reset

O circuito possui duas origens de eventos. `CLOCK_50` fornece a referência periódica de 50 MHz ao PLL de vídeo. No controle do jogo, o sinal `clk` é a inversão de `KEY[2]`, de modo que pressionar KEY2 produz a borda de subida usada para registrar a jogada. Esse evento manual não tem a função de varrer a tela.

`rst = !KEY[0]` torna o reset ativo ao pressionar KEY0. Os registradores da partida são limpos, e `player` recebe zero, preparando o turno azul. A conservação do estado após soltar o botão permite iniciar uma nova sequência de jogadas.

## Princípio da interface VGA

O monitor interpreta os níveis de vermelho, verde e azul em conjunto com os pulsos de sincronismo horizontal e vertical. O clock de pixels marca a progressão da varredura; os contadores indicam onde a imagem está sendo percorrida. Durante o retorno da varredura, a lógica de apagamento força as cores a zero.

A imagem é calculada por coordenadas, sem um framebuffer: o circuito verifica se o pixel pertence à grade, a uma marca ou a uma legenda. O PLL divide a referência de 50 MHz por dois, produzindo 25 MHz. As comparações efetivamente utilizadas e suas diferenças em relação ao modo nominal 640 × 480 estão no [capítulo de sincronização](05-sincronizacao-vga.md).

## Papel do Quartus II

O Quartus organiza o projeto, interpreta as fontes e o esquemático, sintetiza a lógica, atribui os recursos da FPGA, verifica temporização e gera o arquivo de configuração. O `.qpf` identifica a revisão; o `.qsf` registra dispositivo, fontes, topo e pinos. O Programmer transfere a configuração para a placa. Esses arquivos exercem papéis diferentes e devem permanecer juntos em `projeto/`.

---

[Página inicial](../README.md) · [Índice](../README.md#roteiro-de-estudo) · [Próximo capítulo](02-arquitetura.md)
