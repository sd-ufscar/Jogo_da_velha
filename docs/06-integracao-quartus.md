# 06 — Integração no Quartus II

## Arquivos que definem o projeto

O ponto de entrada é [Velha.qpf](../projeto/Velha.qpf), cuja revisão se chama `Velha`. O arquivo [Velha.qsf](../projeto/Velha.qsf) estabelece `FAMILY "Cyclone II"`, `DEVICE EP2C20F484C7`, `TOP_LEVEL_ENTITY Block2` e a pasta de resultados `output_files`.

| Arquivo | Papel no projeto |
|---|---|
| [Velha.v](../projeto/Velha.v) | Controle da partida em Verilog |
| [VGA.v](../projeto/VGA.v) | Geração gráfica em Verilog |
| [VGA_SYNC.vhd](../projeto/VGA_SYNC.vhd) | Sincronismo em VHDL |
| [Video_PLL.vhd](../projeto/Video_PLL.vhd) | Instância da megafunção de PLL |
| [Block2.bdf](../projeto/Block2.bdf) | Esquemático de nível superior |
| [Velha.bsf](../projeto/Velha.bsf), [VGA.bsf](../projeto/VGA.bsf), [VGA_SYNC.bsf](../projeto/VGA_SYNC.bsf) | Símbolos dos blocos |
| [Arquivo_Pinos_DE1.qsf](../projeto/Arquivo_Pinos_DE1.qsf) | Modelo geral de atribuições da placa, separado da configuração ativa |

As cinco fontes ativas estão relacionadas no `.qsf`: dois arquivos `VERILOG_FILE`, dois `VHDL_FILE` e um `BDF_FILE`. Seus caminhos são relativos à pasta `projeto/`. Mover essa pasta como uma unidade conserva as referências necessárias.

Também permanecem disponíveis [vgadisplay.v](../projeto/vgadisplay.v), [vgadisplay.bsf](../projeto/vgadisplay.bsf), [vga_display.bsf](../projeto/vga_display.bsf) e [jogodavelha.bsf](../projeto/jogodavelha.bsf), encontrados junto ao projeto. Eles não constam como fontes ativas nem substituem os módulos documentados. Em particular, `vgadisplay.v` possui outra organização de bits e outra interface; não deve ser adicionado para substituir `VGA.v`.

## Abertura e inspeção do topo

Ao abrir o `.qpf`, conferir a revisão `Velha` e o topo `Block2`. Abrir `Block2.bdf` no editor de esquemáticos permite examinar os blocos e as redes nomeadas. A seleção do topo deve ser conferida em **Assignments → Settings → General**, ou pela propriedade equivalente da revisão na interface.

Os símbolos `.bsf` descrevem a aparência e os terminais usados pelo editor. Os módulos HDL fornecem o comportamento. Caso uma interface HDL seja alterada em estudos posteriores, o símbolo correspondente precisa ser regenerado e suas conexões conferidas; a simples existência de um símbolo não altera a implementação HDL.

O [diagrama original](../imagens/diagrama.jpeg) e a [tabela de redes](02-arquitetura.md) auxiliam a conferência. As saídas `gameover`, `player` e `video_on` não possuem consumidores externos no topo.

## Dispositivo e pinos efetivamente usados

| Porta | Pino do Cyclone II | Função |
|---|---|---|
| `CLOCK_50` | `PIN_L1` | Clock de referência |
| `KEY[0]` | `PIN_R22` | Reset |
| `KEY[1]` | `PIN_R21` | Entrada sem uso lógico |
| `KEY[2]` | `PIN_T22` | Confirmação da jogada |
| `KEY[3]` | `PIN_T21` | Entrada sem uso lógico |
| `SW[0]` | `PIN_L22` | Bit de peso 1 |
| `SW[1]` | `PIN_L21` | Bit de peso 2 |
| `SW[2]` | `PIN_M22` | Bit de peso 4 |
| `SW[3]` | `PIN_V12` | Bit de peso 8 |
| `LEDR[0]` | `PIN_R20` | Grupo de vitória azul |
| `LEDR[1]` | `PIN_R19` | Grupo de vitória azul |
| `LEDR[2]` | `PIN_U19` | Grupo de vitória azul |
| `LEDR[3]` | `PIN_Y19` | Grupo de vitória azul |
| `LEDR[4]` | `PIN_T18` | Grupo de vitória vermelha |
| `LEDR[5]` | `PIN_V19` | Grupo de vitória vermelha |
| `LEDR[6]` | `PIN_Y18` | Grupo de vitória vermelha |
| `LEDR[7]` | `PIN_U18` | Grupo de vitória vermelha |
| `LEDR[8]` | `PIN_R18` | Encerramento |
| `VGA_R[3]` | `PIN_B7` | Componente vermelha |
| `VGA_G[3]` | `PIN_A8` | Componente verde |
| `VGA_B[3]` | `PIN_B10` | Componente azul |
| `VGA_HS` | `PIN_A11` | Sincronismo horizontal |
| `VGA_VS` | `PIN_B11` | Sincronismo vertical |

A tabela foi extraída das atribuições `set_location_assignment` de [Velha.qsf](../projeto/Velha.qsf). Há uma atribuição global `STRATIX_DEVICE_IO_STANDARD "3.3-V LVTTL"`, preservada com esse nome original. O padrão efetivamente aplicado às portas deve ser conferido no **Pin Planner** e no relatório do Fitter.

O `.qsf` contém atribuições de outros periféricos da DE1 que não existem como portas neste topo. O Quartus pode emitir avisos de atribuições ignoradas para esses nomes. A quantidade de atribuições no arquivo não corresponde à quantidade de sinais fisicamente usados pelo jogo.

## PLL e dependências

O componente `video_PLL` é declarado e instanciado dentro de `VGA_SYNC`. Sua definição está no arquivo `Video_PLL.vhd`, incluído no `.qsf`. A família declarada é Cyclone II; o mapa ativo configura 50 MHz na entrada e 25 MHz na saída.

O próprio arquivo VHDL contém a configuração da instância `altpll`. Os comentários do assistente mencionam arquivos opcionais como `.cmp`, `.inc` e `_inst.vhd`, que não foram encontrados. Nenhum deles é listado como fonte ativa ou referenciado pelo BDF; a megafunção depende do suporte de bibliotecas do Quartus. Não foi encontrado `.qip` necessário ao conjunto ativo.

O modelo geral `Arquivo_Pinos_DE1.qsf` possui uma atribuição `HEX_FILE VGA_Controller/Img_DATA.hex`. Essa imagem não existe no conjunto e **não é dependência do jogo ativo**, pois o modelo não é carregado por `Velha.qsf`. Importá-lo integralmente pode introduzir essa referência desnecessária. Para reproduzir o circuito, utilizar as atribuições da revisão fornecida.

## Temporização

Não foi encontrado `Velha.sdc`. Os relatórios de referência acusam ausência de restrições e apresentam folgas negativas de setup. Portanto, uma síntese ou um Fitter concluído com sucesso não comprova fechamento temporal.

O tutorial conserva o circuito e seus parâmetros. Antes de utilizá-lo como referência de temporização para outro projeto, é necessário estabelecer restrições coerentes com o PLL, com o evento de KEY2 e com a transferência dos sinais entre os domínios. Não é fornecido um `.sdc` com valores presumidos.

---

[Capítulo anterior](05-sincronizacao-vga.md) · [Índice](../README.md#roteiro-de-estudo) · [Próximo capítulo](07-compilacao-e-gravacao.md)
