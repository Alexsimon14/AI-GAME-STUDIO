# Club Legacy — Fase 6: economia do clube e ledger

**02/10/2026 · Game Developer · CONCLUÍDA em Godot/headless e smoke Windows**

Autorização somente para a Fase 6, após aprovação das Fases 5/5.1. Lidos AGENTS.md, papel Game Developer, skill godot-development, GDD, arquitetura, plano e relatórios 0–5.1. Plano atualizado antes do código. Investigação independente de domínio/persistência e implementação de testes em arquivos separados, sem edição concorrente do mesmo arquivo.

## Modelo e autoridade

`WorldState.finance` contém FinanceState, configuração efetiva independente, marco de início financeiro, marcadores de rodadas e ledger por ID. FinancialEntry e serviços são RefCounted, sem UI, SceneTree, FileAccess ou RNG. IDs financeiros usam namespace da Career e seu contador monotônico; renomear clubes não muda relações.

Ledger é a autoridade de movimentações. `Club.cash` é saldo materializado e reconciliado com a soma dos lançamentos pelo validator. Alterações de dinheiro em funcionamento passam por FinanceService; a geração inicial fornece o saldo que vira uma abertura explícita. Consultas devolvem projeções destacadas, não referências mutáveis às entradas.

Moeda: **unidades fictícias inteiras**, sem centavos/float. Entrada positiva, despesa negativa; zero pode registrar operação legítima sem movimento. UI usa `¤`, com sinal textual para negativos. Inteiros persistidos como strings decimais canônicas, inclusive valores/contextos monetários. Limite de integridade de ±10¹² por valor/saldo, sem pretensão de balanceamento. Contratos continuam sendo a única fonte de salário.

Categorias implementadas: **OPENING_BALANCE, MATCHDAY_REVENUE, WAGES, MAINTENANCE**. Sem prêmio por vitória: o GDD não define essa receita. Premiação anual fica fora desta entrega, assim como processamento de contratos/idade ou nova temporada.

## Parâmetros TEST / PLACEHOLDER e regras

Configuração financeira `phase-6-test-v1`, congelada em cópia independente por carreira. Saldo inicial e salários continuam no catálogo/configuração da Fase 1.

| Perfil | Abertura inicial | Ocupação base | Manutenção por rodada |
|---|---:|---:|---:|
| PEQUENO | 20.000 | 60% | 100 |
| MÉDIO | 60.000 | 70% | 300 |
| ELITE | 120.000 | 80% | 700 |

Ingresso: 2 unidades. Ocupação armazenada em pontos-base inteiros (6.000/7.000/8.000 sobre 10.000). Público = capacidade × ocupação / 10.000, com divisão inteira; receita = público × ingresso. Público nunca excede capacidade. Sem torcida dinâmica, aleatoriedade, preço editável, upgrade ou efeito de resultado esportivo na bilheteria. A capacidade é o atributo inicial existente.

Somente os seis mandantes de fixtures concluídos recebem bilheteria na rodada. Todos os 12 clubes pagam `wages_per_round`, soma dos contratos ativos de atletas, e manutenção. Contrato do treinador continua sem remuneração pessoal, como no GDD. Saldo negativo é válido: obrigações continuam, sem empréstimo, aporte, venda, falência, bloqueio ou demissão automática.

## Idempotência e atomicidade

Cada abertura/rodada/clube/categoria tem chave estável e payload identificável. Repetição idêntica tem sucesso sem lançamento, saldo ou ID novo; conteúdo diferente na mesma chave é recusado. Operação individual nova não é publicada: somente lotes completos de abertura/rodada. Uma rodada gera 30 entradas: seis bilheterias, 12 salários e 12 manutenções. Dez rodadas geram 312 entradas contando as 12 aberturas.

FinanceService valida estado, cria candidato, calcula saldos e contador candidatos, verifica invariantes e somente então publica. Rejeição preserva dinheiro, ledger e contador. Validator verifica IDs/namespace/contador, chaves, categorias, sinais/contextos, referências, marco, rodadas confirmadas contíguas, completude por clube e reconciliação de caixa. Parâmetros inválidos e inteiros excessivos são recusados antes de cálculos/iterações inseguras.

CareerFlow resolve os seis jogos no candidato existente, confirma a rodada pela SeasonService e processa seu lote financeiro antes de publicar o mundo. Falha preserva o agregado anterior. MatchSimulator não foi alterado e não conhece dinheiro; SeasonService conserva sua responsabilidade esportiva. Abrir Home/Finanças, jogar ticks, preparar escalação, salvar ou carregar não cria receita/cobrança.

## Persistência e migração

**Schema 4 · save_version phase-6-v1.** FinanceCodec explícito adiciona ledger, configuração efetiva, IDs, chaves, contexto e marcadores ao JSON. Sem objetos opacos, execução de scripts ou segundo índice financeiro persistido. Checksum e estratégia A/B existentes são preservados.

Migração real **3→4** valida envelope/checksum e mundo anterior, preserva IDs, contratos, resultados e active_match, cria 12 aberturas no caixa existente e fixa o último commit esportivo como marco. Não calcula economia retroativa. A próxima rodada passa a usar as regras desta fase. Apenas os novos IDs financeiros avançam o contador. Migrações 1/2 continuam suportadas e encadeiam a inicialização financeira depois da migração esportiva já existente.

Migração ocorre em memória, sem gravar sobre o original; save posterior usa nova revisão no snapshot inativo. Versão futura é recusada e protegida contra sobrescrita. Mundos de geração/harness podem manter `finance = null`; CareerFlow inicializa explicitamente ao criar ou ao carregar esse caso, sem cobrança histórica nem save automático. Não é uma nova modalidade de carreira sem economia.

## UI e smoke

Finanças está funcional na Sidebar, usando AppShell, TopBar, cards e tokens navy/dourado existentes. Clube, Mercado, Estádio, CT e Empregos continuam desabilitados. Tela mostra saldo, receitas/despesas/resultante da temporada, folha por rodada, composição real e até 12 movimentações recentes. Abertura é distinguida de receita. Não há previsão, TV, patrocinador, dívida bancária ou gráfico inventado. Home e demais telas não foram redesenhadas.

Smoke gráfico produziu **26 capturas** em 1100×780 e 860×650: estados anteriores preservados, Finanças inicial, após rodada, ledger rolado e déficit em ambas as resoluções. Fixture de déficit usa configuração TEST própria, manutenção 200.000/ingresso zero, processada pelo serviço; não edita caixa diretamente. Capturas foram abertas e inspecionadas, incluindo Finanças positiva, negativa reduzida e preview ativo.

Nova/continuar preserva **675 px de conteúdo / 694 px disponíveis** em 1100×780, sem scroll vertical. Sidebar com logo e itens cabe nessa resolução. Resolução menor mantém scroll/legibilidade. Finanças pode rolar para consultar o ledger. Arte, renderer, Match Engine e densidade anterior permanecem. Smoke por sinais/comandos não equivale a teste manual de todos os cliques nem aprovação humana da nova tela.

Capturas: `TEMP/club-legacy-phase51-visual/`. Logs do smoke: `club-legacy-phase6-visual.{stdout,stderr}.txt`. Exit 0, stderr vazio.

## Execução e testes

Engine confirmada: `C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`, **4.7.2.stable.official.ed1daf0bf**, Compatibility. Start-Process com Wait/PassThru, stdout/stderr em TEMP; Hidden para processos auxiliares. Nenhuma instalação.

Suíte completa: **700 PASS / 0 FAIL**, exit 0 e stderr vazio: **533 anteriores preservados + 167 novos**. Runner focado anterior do Vertical Slice: **123/0**, exit 0/stderr vazio. Runner financeiro final: **167/0**, exit 0/stderr vazio. Sem remoção, skip ou enfraquecimento de testes prévios.

| Verificação | Argumentos | Exit / evidência final |
|---|---|---|
| Versão | `--version` | 0; versão exata acima |
| Import | `--headless --path games/club-legacy --editor --quit` | 0; stderr vazio, sem parsing error |
| Completa | `--headless --path games/club-legacy --script res://tests/run_tests.gd --quit-after 1000` | 0; 700 PASS / 0 FAIL; stderr vazio |
| Probe | completa + `-- --force-failure` | 1; 700 PASS / 1 falha intencional; apenas `FAIL: Intentional runner failure probe` em stderr |
| Startup | `--headless --path games/club-legacy --quit-after 2` | 0; stderr vazio |
| Focada slice | `--headless --path games/club-legacy --script res://tests/run_vertical_slice.gd --quit-after 1000` | 0; 123/0; stderr vazio |
| Focada economia | `--headless --path games/club-legacy --script res://tests/run_finance_tests.gd --quit-after 1000` | 0; 167/0; stderr vazio |
| Smoke gráfico | `--path games/club-legacy --script res://tests/visual_smoke.gd` | 0; 26 PNGs; stderr vazio |

Logs finais em TEMP: `club-legacy-phase6-{version,import,normal,failure,startup,focused-slice,focused-finance,visual}.{stdout,stderr}.txt`. Processo aguardado, código real e resumos completos conferidos; limite de frames não foi usado como sinal de sucesso. Import e smoke foram repetidos após os ajustes de integridade; capturas finais de Finanças positiva/reduzida, ledger e déficit em ambas as resoluções foram inspecionadas.

Cobertura nova: aberturas e perfis dos 12 clubes, 30 operações por rodada, bilheteria por mando/capacidade/ocupação/preço, salários por contrato e manutenção, todos os clubes, dez rodadas sem premiação, déficit e continuidade, keys/retries/conflitos, falha sem publicação, leituras/projeções imutáveis, IDs e reconciliação, configuração inválida e independente, tipos/referências/contextos/marcos corrompidos. Round-trips iniciais, primeira/segunda rodadas, múltiplas categorias/rodadas e déficit; A/B/fallback; schema futuro/checksum; migração parcial, commit anterior e partida ativa no minuto 23, preservando checkpoint/input/eventos/RNG; arquivo legado intacto e próxima revisão no B. UI verifica navegação, cinco itens futuros desabilitados, valores/ledger reais e déficit com sinal explícito.

Primeira tentativa do novo teste encontrou `namespace` como nome reservado em parâmetro; corrigido para `world_namespace`, sem remover assertions. Revisão independente levou a rejeição antecipada de marco exagerado/perfil desconhecido, checks explícitos de contexto inteiro e proteção de tipo do estado financeiro. A tentativa de parsing retornou 1 e não foi considerada sucesso.

## Arquivos e limites

Criados: `resources/config/finance_config.gd/.tres`; `scripts/domain/finance/{finance_state,financial_entry,finance_service,finance_validator}.gd`; `scripts/persistence/finance_codec.gd`; `ui/finance_screen.gd`, `ui/money_formatter.gd`; `tests/integration/finance_tests.gd`, `tests/run_finance_tests.gd`; respectivos `.gd.uid` gerados; este relatório.

Modificados nesta fase: WorldState, WorldCodec, SaveEnvelope, CareerFlow, AppShell, SliceViews, runner completo, smoke visual, plano e README. Mudanças anteriores da Fase 5.1 continuam no workspace e não são atribuídas a esta fase.

Sem mercado/transferências, vagas/diretoria/demissão, estruturas evolutivas, torcida dinâmica, promoção/rebaixamento efetivo, transição anual, monetização, backend, nuvem ou Android build. Integridade e funcionamento não comprovam equilíbrio econômico, diversão ou viabilidade comercial. Mantidas limitações anteriores de durabilidade física A/B e escritor único.

Verificações Git finais: `git diff --check`, `git diff --stat`, `git status --short`, com safe.directory limitado ao repositório. Diff check sem erro; avisos LF/CRLF e ignore global não impediram as verificações. Diff acumulado inclui mudanças anteriores não commitadas; arquivos novos não rastreados não entram em diff --stat. Staging preservado; nenhum add/reset/restore/clean/commit/push.

**FASE 6 — CONCLUÍDA NOS CRITÉRIOS HEADLESS/SMOKE.** Parar aqui. Fase 7 não iniciada; Android e balanceamento definitivo não validados.
