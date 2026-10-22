# 04 — Geração gráfica: módulo VGA

## Uma imagem calculada por coordenadas

O módulo [VGA.v](../projeto/VGA.v) recebe `clk`, `h_counter[9:0]`, `v_counter[9:0]`, `tabuleiro[17:0]`, `winA`, `winB` e `draw`. Produz três saídas de um bit: `vga_r`, `vga_g` e `vga_b`. O módulo de sincronismo fornece as coordenadas e o relógio; o módulo gráfico decide a cor de cada posição.

O bloco `always @(posedge clk)` inicia cada atualização com RGB igual a zero, estabelecendo fundo preto. Em seguida, verifica as regiões da imagem. Não há memória de quadro: o circuito consulta a casa correspondente diretamente no vetor de 18 bits. As variáveis `linha`, `coluna`, `indice`, `x_local` e `y_local` auxiliam o cálculo; não representam uma segunda cópia do tabuleiro.

## Região do tabuleiro

| Constante da fonte | Valor | Efeito |
|---|---|---|
| `X_INI` | 30 | Início horizontal |
| `Y_INI` | 60 | Início vertical |
| `TAM_CASA` | 120 | Lado de cada célula |
| `TAM_TABULEIRO` | 360 | Lado das três células |
| `ESP_GRADE` | 4 | Faixa de grade em cada borda da célula |
| `MARGEM` | 24 | Primeiro pixel da marca, na célula |
| `FIM` | 96 | Limite superior exclusivo da marca |

O teste de pertencimento usa limites inferiores inclusivos e superiores exclusivos. Assim, o tabuleiro ocupa `30 ≤ x < 390` e `60 ≤ y < 420`: são exatamente 360 × 360 posições. Fora dessa região, somente as legendas podem alterar o fundo preto.

Há **três linhas e três colunas de casas**. As bordas de cada célula formam a grade branca; não são desenhadas apenas três linhas isoladas.

## Localização de uma casa

```verilog
            coluna = (h_counter - X_INI) / TAM_CASA;
            linha  = (v_counter - Y_INI) / TAM_CASA;

            // Coordenadas locais dentro da casa
            x_local = (h_counter - X_INI) % TAM_CASA;
            y_local = (v_counter - Y_INI) % TAM_CASA;

            // Indice de 0 a 8
            indice = linha * 3 + coluna;

            // Leitura dos dois bits da casa
            casa = tabuleiro[2*indice +: 2];
```

Dentro do tabuleiro, as operações correspondem a:

```text
coluna  = piso((x - 30) / 120)
linha   = piso((y - 60) / 120)
indice  = 3*linha + coluna
x_local = (x - 30) mod 120
y_local = (y - 60) mod 120
```

As divisões de inteiros não negativos identificam os grupos de 120 pixels. Linha e coluna variam de 0 a 2; `indice` varia de 0 a 8. A seleção Verilog `tabuleiro[2*indice +: 2]` extrai dois bits a partir de `2*indice`, mantendo a codificação documentada no [controle do jogo](03-logica-do-jogo.md).

No pixel `(210,240)`, obtêm-se coluna 1, linha 1, índice 4 e coordenadas locais `(60,60)`. O pixel pertence à casa 5 e consulta `tabuleiro[9:8]`. O par `01` produz azul; `10`, vermelho; `00`, preto no interior da célula.

## Grade e quadrados

A grade é branca quando `x_local < 4`, `y_local < 4`, `x_local >= 116` ou `y_local >= 116`. Cada célula contribui com quatro pixels de borda de cada lado. Em uma divisão interna, as duas células vizinhas somam **oito pixels brancos**. Por exemplo, a divisão entre a primeira e a segunda coluna ocupa `x = 146..153`.

A marca colorida exige, simultaneamente, `24 ≤ x_local < 96` e `24 ≤ y_local < 96`. Seu lado mede `96 - 24 = 72` pixels. Na casa 1, o quadrado ocupa `x = 54..125` e `y = 84..155`; na casa 5, ocupa `x = 174..245` e `y = 204..275`.

A prioridade da grade é maior que a da marca, pois o teste da cor está em `else if`. Os pares `00` e `11` não satisfazem as condições de desenho das marcas, conservando o fundo preto nessa região. O par `11` não é produzido por uma partida válida e não possui uma cor de jogador definida.

## Cores RGB

| Cor | `vga_r` | `vga_g` | `vga_b` | Uso |
|---|---|---|---|---|
| Preto | 0 | 0 | 0 | Fundo e casas vazias |
| Branco | 1 | 1 | 1 | Grade |
| Vermelho | 1 | 0 | 0 | Casa `10` e legenda vermelha |
| Azul | 0 | 0 | 1 | Casa `01` e legenda azul |
| Verde | 0 | 1 | 0 | Borda de vitória |
| Amarelo | 1 | 1 | 0 | Bordas de empate |

O comentário que chama o quadrado vermelho de “Jogador 1” e o azul de “Jogador 2” no arquivo gráfico descreve a ordem das legendas. Para os turnos e sinais do controlador, a referência inequívoca é **A/azul/`01`** e **B/vermelho/`10`**. O azul inicia a partida.

## Legendas laterais e resultados

As duas legendas ocupam `430 ≤ x < 500`, com lado de 70 pixels. A vermelha ocupa `150 ≤ y < 220`; a azul, `270 ≤ y < 340`. Seus interiores permanecem nas cores dos participantes durante toda a partida.

Se `winB = 1`, a borda da legenda vermelha torna-se verde. Se `winA = 1`, a borda da azul torna-se verde. A espessura é quatro pixels: na legenda azul, por exemplo, `x = 430..433` e `496..499` pertencem às bordas laterais. O interior vai de `x = 434..495` e `y = 274..335`.

Se `draw = 1`, ambas as bordas tornam-se amarelas. O teste de empate precede os testes de vitória em cada legenda; portanto, possui prioridade gráfica se sinais forem aplicados artificialmente ao módulo. Na partida válida, o controlador produz apenas um resultado terminal.

`VGA` não recebe `player` nem `gameover`. O bloqueio das jogadas pertence a `Velha`, e não existe uma animação de turno nessa interface. Os indicadores laterais são referências de cor e de resultado.

## Relação com a saída do monitor

Os três sinais de cor alimentam `red`, `green` e `blue` de `VGA_SYNC`. O sincronizador registra e apaga as cores fora de sua janela de vídeo; suas saídas chegam apenas ao bit 3 dos canais RGB da DE1. Dessa forma, a capacidade de quatro bits por canal da placa não significa que o projeto gere 16 intensidades diferentes em cada cor.

As [fotografias](08-utilizacao-e-resultados.md) mostram o tabuleiro, as marcas e as legendas. As coordenadas deste capítulo são as usadas pela lógica, e não medidas sobre os pixels das fotografias do monitor.

---

[Capítulo anterior](03-logica-do-jogo.md) · [Índice](../README.md#roteiro-de-estudo) · [Próximo capítulo](05-sincronizacao-vga.md)
