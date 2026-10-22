# 05 — Sincronização VGA e PLL

## Linguagem e responsabilidade

[VGA_SYNC.vhd](../projeto/VGA_SYNC.vhd) contém a implementação de sincronismo fornecida para a integração do experimento. A linguagem é **VHDL**, identificada por `library IEEE`, `ENTITY VGA_SYNC` e `ARCHITECTURE a`. A configuração [Velha.qsf](../projeto/Velha.qsf) já o registra com `VHDL_FILE`; não é necessário renomear ou alterar referências.

O sincronizador recebe `clock_50Mhz` e os sinais de cor `red`, `green` e `blue`. Produz `red_out`, `green_out`, `blue_out`, `horiz_sync_out`, `vert_sync_out`, `video_on`, `pixel_clock`, `pixel_row[9:0]` e `pixel_column[9:0]`.

Sua função é percorrer a imagem, fornecer coordenadas à lógica gráfica, gerar os pulsos de sincronismo e desligar as cores nos intervalos de retorno da varredura. O monitor recebe RGB e sincronismos; o clock de pixels é uma referência interna do circuito.

## Parâmetros efetivos

```vhdl
    CONSTANT H_pixels_across:   Natural := 640;
    CONSTANT H_sync_low:        Natural := 664;
    CONSTANT H_sync_high:       Natural := 760;
    CONSTANT H_end_count:       Natural := 800;
-- Vertical Timing Constants
    CONSTANT V_pixels_down:     Natural := 480;
    CONSTANT V_sync_low:        Natural := 491;
    CONSTANT V_sync_high:       Natural := 493;
    CONSTANT V_end_count:       Natural := 525;
```

Os nomes sugerem o modo nominal **640 × 480**. Para compreender o circuito reproduzido, devem ser consideradas também as comparações inclusivas e a ordem das atualizações, em vez de substituir seus parâmetros por uma tabela genérica de VGA.

| Parâmetro | Valor | Comparação na fonte |
|---|---|---|
| `H_pixels_across` | 640 | Vídeo horizontal com `h_count < 640` |
| `H_sync_low` | 664 | Início do nível baixo horizontal |
| `H_sync_high` | 760 | Fim inclusivo do nível baixo horizontal |
| `H_end_count` | 800 | Retorno horizontal quando `h_count = 800` |
| `V_pixels_down` | 480 | Vídeo vertical com `v_count <= 480` |
| `V_sync_low` | 491 | Início do nível baixo vertical |
| `V_sync_high` | 493 | Fim inclusivo do nível baixo vertical |
| `V_end_count` | 525 | Condição de retorno vertical, também dependente de `h_count` |

## Relógio de pixels e PLL

O componente `video_PLL` recebe `CLOCK_50` e devolve `c0` para `pixel_clock_int`. A configuração está em [Video_PLL.vhd](../projeto/Video_PLL.vhd):

```vhdl
    GENERIC MAP (
        clk0_duty_cycle => 50,
        lpm_type => "altpll",
        clk0_multiply_by => 1,
        inclk0_input_frequency => 20000,
        clk0_divide_by => 2,
        pll_type => "FAST",
        intended_device_family => "Cyclone II",
        operation_mode => "NORMAL",
        compensate_clock => "CLK0",
        clk0_phase_shift => "0"
    )
```

`inclk0_input_frequency = 20000` representa período de entrada de 20.000 ps, equivalente a 50 MHz. A multiplicação por 1 e a divisão por 2 resultam em:

```text
f_pixel = 50 MHz × 1 / 2 = 25 MHz
T_pixel = 1 / 25 MHz = 40 ns
```

Também estão definidos ciclo de trabalho de 50%, fase zero, família Cyclone II, tipo `FAST`, modo `NORMAL` e compensação `CLK0`. O bloco não expõe uma saída `locked` nem uma entrada de reset do PLL na interface utilizada.

O arquivo possui comentários de recuperação do assistente que mencionam 25 MHz. Esses valores concordam com o mapa de genéricos efetivamente instanciado. Já o comentário do sincronizador sobre uma placa UP3 e clock de 48 MHz não descreve a ligação deste projeto: o BDF conecta `CLOCK_50`, e o PLL declara 50 MHz na entrada. A tabela de modos comentada no sincronizador menciona 25,175 MHz como referência nominal, mas esse não é o clock configurado.

## Varredura horizontal

```vhdl
    IF (h_count = H_end_count) THEN
        h_count <= "0000000000";
    ELSE
        h_count <= h_count + 1;
    END IF;
```

Depois de inicializado, `h_count` percorre os valores **0 a 800**, totalizando 801 períodos de pixel por ciclo horizontal. Com clock ideal de 25 MHz, isso corresponde a `801 × 40 ns = 32,04 µs`, ou aproximadamente 31,211 kHz. São valores deduzidos da configuração e do contador, não medições do monitor.

HSYNC é levado a zero quando `664 ≤ h_count ≤ 760`. A largura lógica é `760 - 664 + 1 = 97` períodos de pixel. A janela horizontal ativa é `0..639`; o retorno ocupa os valores de 640 a 800. O pulso é ativo em nível baixo. A saída `horiz_sync_out` é registrada, acrescentando uma etapa em relação ao sinal interno de sincronismo.

## Varredura vertical

```vhdl
    IF (v_count >= V_end_count) AND (h_count >= H_sync_low) THEN
        v_count <= "0000000000";
    ELSIF (h_count = H_sync_low) THEN
        v_count <= v_count + 1;
    END IF;
```

O contador vertical avança quando o valor anterior de `h_count` é 664. Quando `v_count` atinge 525 e `h_count >= 664`, o ramo de retorno tem prioridade. Assim, o valor 525 existe apenas brevemente: no ciclo que segue o incremento para 525, a condição de retorno já está satisfeita. **Não se deve concluir que existem 526 linhas completas apenas porque o contador alcança 525.**

VSYNC fica baixo para `491 ≤ v_count ≤ 493`, abrangendo três valores completos de linha. A habilitação vertical utiliza `v_count <= 480`, incluindo os valores 0 a 480. Portanto, a janela lógica possui 481 valores de linha; ela não é uma janela estritamente definida por `v_count < 480`.

Essas comparações são características da implementação preservada. A resolução pretendida é 640 × 480, mas os intervalos efetivos não devem ser apresentados como reprodução exata de uma temporização VESA. O tabuleiro e as legendas ocupam regiões internas que terminam antes de `y = 420`.

## Vídeo ativo e apagamento

`video_on_int` é a conjunção de `video_on_h` e `video_on_v`. Durante a região horizontal ativa, `pixel_column` recebe `h_count`; durante a região vertical ativa, `pixel_row` recebe `v_count`. Fora dessas condições, as coordenadas conservam o último valor atribuído; o apagamento impede que ele produza imagem no retorno.

```vhdl
        red_out <= red AND video_on_int;
        green_out <= green AND video_on_int;
        blue_out <= blue AND video_on_int;
```

As atribuições VHDL dentro do processo agendam atualizações de sinais. A geração dos sincronismos internos, sua transferência às saídas e o registro de RGB formam etapas sequenciais. Por isso, o circuito deve ser interpretado como uma cadeia de sinais registrados, e não como um conjunto de valores instantâneos sem latência.

No BDF, `pixel_column → v → VGA.h_counter` e `pixel_row → h → VGA.v_counter`. O nome intermediário da rede não altera a função final das coordenadas. A [arquitetura](02-arquitetura.md) mostra todas as conexões.

## Bibliotecas e limites da verificação

O sincronizador utiliza os pacotes `STD_LOGIC_ARITH` e `STD_LOGIC_UNSIGNED`, além de `STD_LOGIC_1164`. Na análise com GHDL, os dois primeiros exigem a opção compatível com Synopsys. O PLL depende da megafunção `altpll` e da biblioteca `altera_mf`, normalmente disponibilizadas pelo ambiente Quartus; seu modelo de simulação não acompanha o repositório.

Os contadores do sincronizador não possuem reset ou inicialização explícita no VHDL. Uma simulação completa precisa considerar a partida desses sinais e o modelo do PLL; não pode assumir automaticamente valores iniciais definidos. A análise estática realizada não equivale à simulação do sincronismo nem a medições de frequência. Os resultados executados estão registrados em [Validação](09-validacao.md).

---

[Capítulo anterior](04-geracao-vga.md) · [Índice](../README.md#roteiro-de-estudo) · [Próximo capítulo](06-integracao-quartus.md)
