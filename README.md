# Jogo da Velha em FPGA com Interface VGA

Jogo da velha para dois participantes, implementado em hardware na **Terasic DE1**, com seleção por chaves, confirmação por botão e apresentação do tabuleiro em um monitor VGA. O circuito armazena as jogadas, alterna os jogadores, identifica vitória ou empate e sinaliza o resultado na tela e nos LEDs.

Projeto acadêmico de **Engenharia de Computação — Universidade Federal de São Carlos (UFSCar)**, desenvolvido na disciplina de **Sistemas Digitais, em 2026**.

| Plataforma | Implementação |
|---|---|
| FPGA | Cyclone II **EP2C20F484C7**, placa Terasic DE1 |
| Ambiente original | Quartus II **13.0 SP1**, versão 13.0.1 Build 232 |
| Descrição de hardware | Verilog HDL e VHDL |
| Integração | Esquemático de nível superior `Block2.bdf` |
| Saída | VGA, com um bit por cor, e `LEDR[8:0]` |

O experimento relaciona registradores, lógica combinacional, circuitos sequenciais, integração de módulos e temporização de vídeo. As fontes individuais, os símbolos e as configurações necessárias para abrir o projeto estão em [projeto/](projeto/).

## Demonstração

| Vitória do jogador azul | Vitória do jogador vermelho |
|---|---|
| ![Vitória azul na primeira linha, com borda verde na legenda azul](imagens/Azul.jpeg) | ![Vitória vermelha na diagonal principal, com borda verde na legenda vermelha](imagens/Vermelho.jpeg) |
| Primeira linha azul; `winA = 1`. | Diagonal principal vermelha; `winB = 1`. |

| Empate | Placa utilizada |
|---|---|
| ![Tabuleiro completo e bordas amarelas nas duas legendas](imagens/Empate.jpeg) | ![Terasic DE1 conectada ao cabo VGA e ao USB](imagens/FPGA.jpeg) |
| Nove casas ocupadas, sem vencedor; `draw = 1`. | DE1 com FPGA Cyclone II e interface VGA. |

As fotografias são registros originais do experimento. Sua interpretação e os limites da validação estão em [Utilização e resultados](docs/08-utilizacao-e-resultados.md).

## Funcionamento geral

1. `SW[3:0]` seleciona uma posição de **1 a 9**, em binário.
2. Ao pressionar **KEY2**, a lógica verifica se a posição é válida e está livre.
3. Uma jogada aceita atualiza os dois bits correspondentes à casa.
4. O turno alterna automaticamente; o jogador **azul inicia**.
5. A lógica verifica vitória e, na ausência dela, empate. `gameover` bloqueia novas jogadas.
6. Os LEDs indicam o resultado; a imagem VGA exibe as casas e destaca a legenda do vencedor em verde, ou as duas legendas em amarelo no empate.

**KEY0 reinicia a partida.** KEY1 e KEY3 não participam da lógica. Os comandos completos e a tabela binária estão no [guia de execução](docs/07-compilacao-e-gravacao.md).

```text
 1 | 2 | 3
---+---+---
 4 | 5 | 6
---+---+---
 7 | 8 | 9
```

## Roteiro de estudo

| Capítulo | Conteúdo |
|---|---|
| [01 — Introdução e fundamentos](docs/01-introducao.md) | FPGA, HDL, bits, registradores, clocks e VGA |
| [02 — Arquitetura](docs/02-arquitetura.md) | Diagrama Mermaid, esquemático e fluxo real dos sinais |
| [03 — Lógica do jogo](docs/03-logica-do-jogo.md) | Módulo `Velha`, codificação das casas, turnos e resultados |
| [04 — Geração gráfica](docs/04-geracao-vga.md) | Módulo `VGA`, coordenadas, grade, cores e legendas |
| [05 — Sincronização VGA](docs/05-sincronizacao-vga.md) | VHDL, contadores, sincronismos e PLL |
| [06 — Integração no Quartus](docs/06-integracao-quartus.md) | Fontes, símbolos, pinos e dependências |
| [07 — Compilação e gravação](docs/07-compilacao-e-gravacao.md) | Preparação do ambiente e execução na DE1 |
| [08 — Utilização e resultados](docs/08-utilizacao-e-resultados.md) | Partidas explicadas e fotografias |
| [09 — Validação e preservação](docs/09-validacao.md) | Verificações executadas, inventário e limitações |

## Reprodução

```sh
git clone https://github.com/sd-ufscar/Jogo_da_velha.git
cd Jogo_da_velha
```

No Quartus II 13.0 SP1, abrir [projeto/Velha.qpf](projeto/Velha.qpf), conferir o dispositivo e o topo `Block2`, compilar e programar o arquivo `.sof` recém-gerado pelo modo JTAG. Seguir o [procedimento completo](docs/07-compilacao-e-gravacao.md) antes da gravação.
