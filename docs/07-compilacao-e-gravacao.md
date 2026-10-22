# 07 — Compilação, gravação e execução na DE1

## Preparação

São necessários a placa **Terasic DE1 com Cyclone II EP2C20F484C7**, um monitor compatível com a saída VGA, cabo VGA, conexão USB ao USB-Blaster e alimentação adequada à placa. O ambiente original registrado nos arquivos é **Quartus II 13.0 SP1, 13.0.1 Build 232, Web Edition**.

Instalar essa versão com suporte à família Cyclone II e o driver USB-Blaster correspondente ao sistema operacional. O suporte ao dispositivo deve ser conferido no instalador e no seletor de dispositivos; uma versão recente do Quartus não deve ser presumida equivalente para essa família. A [página oficial de suporte à instalação](https://www.intel.com/content/www/us/en/support/programmable/licensing/installation-and-licensing.html) orienta a escolha de software e arquivos de dispositivos. Consultar também o [manual da DE1](https://www.terasic.com.tw/attachment/archive/83/DE1_UserManual_v1018.pdf) para alimentação, chave de configuração e conexão USB.

## Obter e abrir

1. Clonar o repositório:

   ```sh
   git clone https://github.com/sd-ufscar/Jogo_da_velha.git
   cd Jogo_da_velha
   ```

2. No Quartus, selecionar **File → Open Project** e abrir [projeto/Velha.qpf](../projeto/Velha.qpf). Manter os arquivos de `projeto/` juntos.
3. Confirmar a revisão `Velha`. Em **Assignments → Device**, conferir **Cyclone II / EP2C20F484C7**.
4. Conferir o topo **Block2**, definido por [Block2.bdf](../projeto/Block2.bdf). O topo não é o módulo `Velha` isolado, pois o BDF também integra desenho e sincronismo.

## Conferir as fontes

Em **Project → Add/Remove Files in Project**, verificar as fontes:

| Linguagem/tipo | Arquivos |
|---|---|
| Verilog | `Velha.v`, `VGA.v` |
| VHDL | `VGA_SYNC.vhd`, `Video_PLL.vhd` |
| Esquemático | `Block2.bdf` |

Não adicionar `vgadisplay.v` para substituir o bloco ativo. O sincronizador é VHDL; a cópia redundante com extensão `.v` foi retirada da estrutura publicada. Os símbolos necessários ao editor permanecem na mesma pasta.

Examinar o PLL no arquivo `Video_PLL.vhd`: `inclk0_input_frequency = 20000`, multiplicação 1 e divisão 2, resultando em 25 MHz a partir de 50 MHz. Se for utilizado o MegaWizard para inspecionar a megafunção, conferir esses valores e a família antes de salvar qualquer regeneração. O projeto fornecido não exige que a configuração seja recriada manualmente.

Em **Assignments → Pin Planner**, comparar as portas com a [tabela de pinos](06-integracao-quartus.md). Os sinais de cor saem apenas em `VGA_R[3]`, `VGA_G[3]` e `VGA_B[3]`. As atribuições de periféricos ausentes do topo podem aparecer como ignoradas; não importar integralmente outro modelo de pinos para tentar eliminá-las.

## Compilar

Selecionar **Processing → Start Compilation**. Acompanhar Analysis & Synthesis, Fitter, Assembler e TimeQuest. Conferir os erros e avisos no relatório; conclusão de geração do arquivo e satisfação dos requisitos de temporização são verificações diferentes.

Com `quartus_sh` disponível no terminal, a compilação também pode ser iniciada a partir da pasta `projeto`:

```sh
quartus_sh --flow compile Velha
```

O diretório configurado para as saídas é `projeto/output_files/`. O arquivo de programação esperado após uma compilação bem-sucedida é **`output_files/Velha.sof`**. Essa pasta é ignorada pelo Git para evitar versionar intermediários e arquivos de configuração desatualizados.

O conjunto não inclui `Velha.sdc`; os relatórios de referência registram essa ausência e folgas negativas. Se a compilação indicar erro de componente `altpll`, conferir o suporte Cyclone II e as bibliotecas da instalação Quartus. Para simulação externa, `altera_mf` precisa estar disponível e configurada. Não substituir o PLL por um clock ideal e tratar esse resultado como validação da implementação física.

## Conectar e programar

1. Conectar o cabo VGA entre a placa e o monitor e selecionar a entrada VGA do monitor.
2. Conectar o USB-Blaster integrado ao computador. Alimentar e ligar a DE1 conforme seu manual, verificando o reconhecimento do cabo e o driver.
3. Para configuração JTAG, posicionar a chave **RUN/PROG em RUN**, conforme a seção de configuração JTAG do manual da DE1.
4. Abrir **Tools → Programmer**, selecionar o modo **JTAG** e escolher **USB-Blaster** em **Hardware Setup**.
5. Usar **Auto Detect** quando necessário e conferir o dispositivo Cyclone II da placa.
6. Adicionar o **`Velha.sof` recém-gerado** em `output_files/`, associando-o ao dispositivo correto. Marcar **Program/Configure** e selecionar **Start**.
7. Conferir a conclusão da operação no Programmer. Depois, pressionar **KEY0** para iniciar a partida com o estado do jogo definido.

A configuração `.sof` por JTAG é volátil: desligar a placa elimina essa configuração. A gravação persistente da memória de configuração é outro procedimento e não é necessária para reproduzir a experiência descrita. Nenhum `.pof` anterior é fornecido como resultado desta publicação.

## Comandos físicos

| Ação | Comando |
|---|---|
| Escolher a casa | Ajustar `SW[3:0]` para 1 a 9 |
| Confirmar | Pressionar e soltar KEY2 uma vez |
| Reiniciar | Pressionar e soltar KEY0 |
| Primeiro turno | Azul, automaticamente após reset |
| KEY1, KEY3, SW4 a SW9 | Sem função na lógica ativa |

`SW[3]` é o bit mais significativo dos quatro utilizados; `SW[0]`, o menos significativo. Ajustar as chaves antes de confirmar. Pressionar KEY2 com zero, valor acima de nove ou casa ocupada conserva o tabuleiro e o jogador.

| Casa | SW3 | SW2 | SW1 | SW0 |
|---|---|---|---|---|
| 1 | 0 | 0 | 0 | 1 |
| 2 | 0 | 0 | 1 | 0 |
| 3 | 0 | 0 | 1 | 1 |
| 4 | 0 | 1 | 0 | 0 |
| 5 | 0 | 1 | 0 | 1 |
| 6 | 0 | 1 | 1 | 0 |
| 7 | 0 | 1 | 1 | 1 |
| 8 | 1 | 0 | 0 | 0 |
| 9 | 1 | 0 | 0 | 1 |

## Reconhecer os resultados

A borda **verde na legenda azul** indica vitória azul; a borda **verde na legenda vermelha**, vitória vermelha. Duas bordas **amarelas** indicam empate. `LEDR[8]` acende em qualquer encerramento; os grupos 0–3 e 4–7 identificam, respectivamente, vitória azul e vermelha. Em uma partida encerrada, KEY2 não registra novas jogadas até KEY0.

Se a tela não apresentar a imagem, conferir a entrada do monitor, o cabo, a configuração JTAG concluída, o topo, o PLL e os pinos efetivos. Consultar os relatórios antes de alterar as constantes do sincronismo. O procedimento desta página é um guia de reprodução; uma nova compilação Quartus e uma nova gravação física não foram executadas durante a preparação do repositório.

---

[Capítulo anterior](06-integracao-quartus.md) · [Índice](../README.md#roteiro-de-estudo) · [Próximo capítulo](08-utilizacao-e-resultados.md)
