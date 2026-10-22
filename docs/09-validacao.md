# 09 — Validação, preservação e limitações

## Origem e estrutura

O projeto mantém as fontes individuais e os caminhos relativos da revisão `Velha`, integrados pelo topo `Block2`. O conjunto local de 154 arquivos e os 154 arquivos extraídos do `Velha.zip` do commit de referência `80b0b4d3d949d441afe44ddfc320b8d60cbe52a2` apresentaram **igualdade de SHA-256 em todos os caminhos**. O ZIP indicado no caminho local não estava presente; a comparação utilizou a pasta local existente e o arquivo obtido do repositório.

```text
Jogo_da_velha/
├── README.md
├── projeto/                   # HDL, QPF, QSF, BDF e símbolos
├── docs/                      # Tutoriais 01 a 09 e inventário
│   └── relatorios-originais/   # Três resumos de compilação de referência
├── imagens/                   # Quatro fotografias e o esquemático
├── testes/                    # Regressão funcional reproduzível
├── .gitattributes
└── .gitignore
```

O [inventário completo](inventario-arquivos.csv) registra caminho original, tamanho, hash original, destino, hash publicado e decisão de preservação para cada arquivo. O ZIP remoto é substituído por arquivos individuais; nenhuma cópia compactada substituta integra a estrutura final. Os originais locais permanecem preservados.

## Adequação técnica mínima

O controlador publicado mantém a implementação original, com uma adequação pontual necessária à geometria da diagonal secundária azul: a expressão utiliza **`board[4] & board[8] & board[12]`**, correspondentes às casas 3, 5 e 7. A regressão sobre a cópia de referência demonstrou a divergência dessa condição antes da adequação; a mesma regressão passou integralmente sobre a fonte publicada. O inventário registra a diferença de hash desse arquivo.

Os demais arquivos preservados do projeto mantêm seus bytes. Não houve reimplementação do controlador, do gerador gráfico, do sincronizador, do PLL, do esquemático ou das atribuições de pinos. As explicações e os trechos HDL descrevem a versão publicada.

## Verificações executadas em 22 de outubro de 2026

| Verificação | Resultado e alcance |
|---|---|
| Comparação local × ZIP remoto | 154 arquivos, todos idênticos por SHA-256 antes da adequação |
| Dependências do QPF/QSF ativo | Topo, BDF e quatro fontes HDL presentes; referências relativas preservadas |
| Simulação funcional de `Velha` | **761.424 vetores**, percorrendo **5.478 estados alcançáveis** e **87.648 transições candidatas** |
| Simulação funcional de `VGA` | **272 verificações** de posição, codificação de cores, bordas e limites |
| Análise VHDL de `VGA_SYNC.vhd` | Aprovada com GHDL 6.0.0, VHDL-93 e pacotes compatíveis com Synopsys |
| Análise externa de `Video_PLL.vhd` | Limitada pela ausência da biblioteca `altera_mf`; sem elaboração/simulação completa do PLL |
| Trechos de código e links relativos | Conferidos contra os arquivos publicados |
| Imagens | Cinco arquivos originais, abertos e conferidos visualmente |

### Regressão do jogo

[testes/executar.py](../testes/executar.py) constrói um modelo de regras independente a partir das oito combinações geométricas. Uma busca em largura enumera todos os estados alcançáveis com alternância azul/vermelho e interrupção no primeiro resultado terminal. Para cada estado, a sequência é reaplicada ao **módulo HDL real** e são verificadas todas as 16 seleções possíveis de `SW[3:0]`.

O resultado inclui tabuleiro, turno, vitória azul, vitória vermelha, empate, encerramento e LEDs. São verificadas seleções inválidas, casas ocupadas, conservação do estado terminal, alterações das chaves sem confirmação e conservação do estado ao soltar KEY2. A reaplicação das sequências exige reset e verifica a recuperação da partida. Os 761.424 vetores incluem esses passos de preparação e observação; não representam 761.424 partidas distintas.

A comparação é feita por [tb_velha.sv](../testes/tb_velha.sv), usando pulsos ideais. Ela não mede contatos físicos, metastabilidade ou temporização após posicionamento e roteamento.

### Regressão gráfica

[tb_vga.sv](../testes/tb_vga.sv) aplica os quatro valores possíveis de cada par nas nove casas e confere pontos interiores e limites dos quadrados. Verifica a grade, os limites externos, as legendas, as bordas verdes, as amarelas e a prioridade gráfica de `draw`. São verificações pontuais de comportamento; não constituem uma simulação completa do monitor ou da cadeia mista Verilog/VHDL.

### Reprodução das simulações

Requer Python 3 e Icarus Verilog (`iverilog` e `vvp`) no PATH. A execução registrada utilizou a distribuição Windows identificada como **Icarus Verilog 12.0 (devel), s20150603-1539-g2693dd32b**, sem integração ao Quartus.

Na raiz do repositório:

```sh
python testes/executar.py
```

O script gera os vetores e os resultados em `testes/build/`, ignorado pelo Git. A saída inclui `PASS Velha` e `PASS VGA` se todas as comparações forem aprovadas. Caminhos alternativos podem ser informados por `--iverilog`, `--vvp` e, em distribuições portáteis, `--ivl-base` para a pasta `lib/ivl`.

Para repetir apenas a análise do sincronizador, em um diretório de trabalho separado:

```sh
ghdl -a --std=93 --ieee=synopsys caminho/para/projeto/VGA_SYNC.vhd
```

A [documentação do Icarus](https://steveicarus.github.io/iverilog/usage/installation.html) descreve as opções de obtenção do simulador; o [projeto GHDL](https://github.com/ghdl/ghdl) fornece ferramentas para VHDL. A análise isolada do sincronizador não resolve a megafunção `altpll`.

## Relatórios de referência e temporização

Os resumos [Analysis & Synthesis](relatorios-originais/Velha.map.summary), [Fitter](relatorios-originais/Velha.fit.summary) e [TimeQuest](relatorios-originais/Velha.sta.summary) pertencem à compilação registrada em **21 de outubro de 2026**, anterior à preparação desta publicação. São evidências do conjunto de referência, e não de uma nova compilação da fonte publicada.

O Fitter registra **1.043 elementos lógicos**, **72 registradores**, **23 pinos** e **um PLL** no EP2C20F484C7. O TimeQuest apresenta, entre outros resultados, folga de setup de **−8,502 ns** no clock do PLL e **−6,648 ns** em KEY2 no modelo lento. Esses números não permitem afirmar atendimento de temporização. Os relatórios completos de origem também indicam ausência de `Velha.sdc`.

Não foi encontrado Quartus II executável no ambiente disponível. Portanto, **não foram executados síntese Quartus, Fitter, Assembler, nova análise TimeQuest, gravação da FPGA ou ensaio físico** sobre a versão publicada. Os arquivos `.sof` e `.pof` de referência não são distribuídos como binários desta versão; é necessário recompilar antes de gravar.

## Arquivos não versionados

| Grupo | Decisão e justificativa |
|---|---|
| `db/`, `incremental_db/`, `greybox_tmp/` | Caches e bancos intermediários regeneráveis pelo Quartus |
| `output_files/` | Saídas de compilação, relatórios e programação regeneráveis; três `.summary` preservados separadamente como referência |
| `*.bak` | Cópias de edição que não integram a revisão ativa |
| `Velha.qws` | Estado da interface e da área de trabalho local do Quartus |
| `VGA_SYNC.v` | Cópia redundante de conteúdo VHDL; a versão `.vhd` já está registrada no QSF, diferindo apenas no término de linha final |

Configurações essenciais `.qpf` e `.qsf`, esquemático `.bdf`, símbolos `.bsf`, fontes HDL e configuração do PLL foram preservados. O arquivo de cadeia de programação de referência possuía caminho absoluto de outra máquina; o Programmer deve criar uma cadeia local apontando para o `.sof` recém-compilado.

Os avisos legais originais das ferramentas e da megafunção permanecem nas fontes. Esta organização documental não atribui uma nova licença aos componentes de terceiros.

---

[Capítulo anterior](08-utilizacao-e-resultados.md) · [Índice](../README.md#roteiro-de-estudo) · [Página inicial](../README.md)
