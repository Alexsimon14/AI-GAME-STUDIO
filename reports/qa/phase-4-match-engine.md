# Club Legacy — Fase 4: Match Engine

**01/10/2026 · Game Developer · CONCLUÍDA em Godot/headless Windows**

Escopo autorizado: somente Fase 4. Lidos AGENTS.md, agents/game-developer.md, skills/godot-development/SKILL.md, GDD, arquitetura, plano e relatórios das Fases 0–3. Plano atualizado antes do código. Fase 5/Vertical Slice não iniciada. Nenhuma instalação, alteração de staging, commit ou push.

## Motor e modelos

**match_engine_version = 1**, independente da versão Godot. Configuração efetiva `phase-4-test-v1`, propósito **TEST / PLACEHOLDER**. Não representa balanceamento oficial, reprodução exata do futebol real ou evidência de diversão.

MatchSimulator é RefCounted e não consulta WorldState, SceneTree, UI, GameSession, FileAccess, relógio real ou RNG global. Recebe um MatchInput completo e separado do mundo. Execução incremental e execução até o fim usam o mesmo `advance`; não existem algoritmos distintos para adversários e usuário.

| Componente | Responsabilidade |
|---|---|
| MatchInput | Snapshot de fixture/club IDs, seed int64, versão/configuração, atletas com posição/overall/condição, onze titulares, até sete reservas, formação e tática |
| MatchState | Minuto/fase, atletas e funções em campo, condição atual, banco/removidos/trocas, táticas, estatísticas, eventos, comandos e RNG dedicado |
| MatchCommand | ID, minuto de fronteira, lado, tipo e payload de tática/formação/substituição |
| MatchEvent | ID sequencial, minuto, tipo, clube/atleta e contexto observado |
| MatchResult | Resultado final, vencedor/empate, eventos, estatísticas, condição/elencos finais, comandos, seed/versão/configuração e resumo de contagens observadas |
| TeamStrengthCalculator | Contribuições por goleiro, defesa, meio e ataque; nenhuma média única decide o placar |
| TacticalContext | Apoio, cobertura, exposição e esforço a partir da tática |
| ChanceGenerator | Construção contextual de oportunidades depois da disputa de iniciativa |
| ChanceResolver | Atleta elegível, finalização, alvo, defesa/gol; nunca sorteia placar |
| MatchSimulator | Ordena minutos, comandos, oportunidades, resolução, estatísticas, desgaste e eventos |

Input e Result são configurados uma vez e oferecem cópias profundas pelos acessores. Não recebem Player/Club vivos; entrada rejeita objetos e valores não finitos. Campos privados seguem a convenção GDScript: não há segurança contra código que deliberadamente acesse membros internos. State é o estado mutável do motor, não uma referência ao agregado da carreira.

## Escalação, condição e tática

Formações iniciais válidas: 4-4-2, 4-3-3 e 5-3-2, com um GK natural e as quantidades correspondentes de DEF/MID/ATT. Exatamente onze titulares e até sete reservas; IDs não se repetem entre titulares/banco ou equipes. Não há posições detalhadas, moral, entrosamento, química ou lesões.

Força provisória individual: `overall × (0,35 + 0,65 × condição/100)`. Somar por função em campo; dividir defesa por quatro, meio por quatro e ataque por dois, mantendo goleiro separado. Assim, número de atletas por setor e sua condição alteram capacidades distintas.

Mudança de formação redistribui os mesmos onze em funções amplas, preservando posições naturais quando possível, em ordem determinística. Atuar em outro setor aplica fator **0,65** de adequação; goleiro não atua em função de campo e atleta de campo não ocupa o gol. Isso permite mudar formação sem consumir substituição, sem criar funções detalhadas. Finalização e seleção do autor também consideram função/adequação.

| Tática | Apoio à criação/ataque | Cobertura | Exposição | Esforço |
|---|---:|---:|---:|---:|
| CAUTELOSA | 0,78 | 1,16 | 0,82 | 0,90 |
| EQUILIBRADA | 1,00 | 1,00 | 1,00 | 1,00 |
| OFENSIVA | 1,20 | 0,82 | 1,20 | 1,35 |

São parâmetros TEST nos setores e na exposição, não um bônus direto de chance de gol. Desgaste por minuto em campo: `0,18 × esforço`, limitado a condição zero. Banco e substituídos não continuam perdendo condição. Sem recuperação/efeitos anuais ou aplicação automática da condição final ao WorldState nesta fase.

## Fluxo de partida e estatísticas

Representar 90 minutos em **90 avanços indivisíveis de um minuto**. Cada avanço compõe setores/contextos, disputa iniciativa, tenta construir oportunidade, resolve-a, registra eventos e aplica desgaste. Intervalo após minuto 45; fim após 90. Na execução headless, um novo avanço após intervalo inicia o segundo tempo; um controlador futuro decide quando chamá-lo. Não há timers, velocidades ou UI de pausa.

Iniciativa usa a criação relativa dos dois meios, com termo de estabilização 10, e vantagem de mando configurável **0,025**. O lado com iniciativa recebe um tick de posse. Esse tick não garante oportunidade, chute ou gol.

Probabilidade provisória de oportunidade: frequência **0,26** × construção relativa × exposição adversária. Construção compara criação mais apoio de ataque com cobertura defensiva. Qualidade da chance combina ataque/cobertura com variação aleatória limitada; categoria CLEAR a partir de qualidade 0,48. Goleiro/qualidade do finalizador entram na resolução, não no sorteio de um placar independente.

Autor é escolhido somente entre atletas ativos de campo. Peso considera qualidade efetiva e função (ATT 3; MID 1,5; DEF 0,4); GK é excluído. Resolução pode ser CHANCE_LOST, SHOT_OFF_TARGET, SAVE ou GOAL. Somente GOAL incrementa placar. Não há assistência, cartão, falta, impedimento, VAR, pênalti ou lesão.

Eventos: START, CHANCE, os desfechos acima, HALF_TIME, END e comandos aplicados. Minutos entre 1 e 90, em ordem; o evento inicial e comandos antes do primeiro avanço usam minuto 1. Não registrar passes ou acontecimentos sem consequência. Contexto inclui criação, cobertura, exposição, qualidade e categoria da chance; resumo é uma projeção das contagens observadas, sem narrativa causal inventada ou IA generativa.

Estatísticas são produzidas pelos mesmos eventos: chances, chances claras, finalizações, no alvo, gols e ticks de posse. Invariante: **gols ≤ no alvo ≤ finalizações ≤ chances**. Chance perdida não é finalização; gol é finalização no alvo. Posse aproximada = ticks de iniciativa/90; soma 100% ao final. Essa é uma estimativa do controle de iniciativa, não simulação de passes ou tempo físico de posse. Atende ao pedido desta fase sem alegar fidelidade de futebol real.

## RNG, comandos e determinismo

RandomNumberGenerator exclusivo de cada MatchState, com seed explícita int64. Somente `advance` consome esse stream; comandos e leituras não sorteiam. Geração do mundo e da temporada não usa o RNG da partida. Não há seed baseada em hora, randf/randi globais ou decisões dependentes da velocidade de apresentação.

Garantia testada: mesmo input, configuração, engine Godot, versão do motor, seed e sequência ordenada de comandos produzem resultado estruturalmente idêntico. Cem repetições passaram; seeds diferentes geraram placares diferentes. Queries de placar/eventos/estatísticas e cálculo de força preservam o estado RNG. Não prometer reprodução entre engines/arquiteturas futuras sem validação.

**Três substituições por lado foram implementadas**, pois estão explicitamente no plano da Fase 4. Atleta precisa estar no banco, substituído não retorna, funções permanecem válidas e o novo atleta passa a contribuir nos avanços seguintes. Comandos aplicados ficam nos eventos e histórico. Mudar tática/formação ou substituir não reescreve evento passado. Retry da mesma chave/conteúdo é idempotente inclusive depois de avançar ou encerrar; conteúdo conflitante é erro. Comando novo exige fronteira atual e partida não encerrada.

## Integração com competição e persistência

FixtureMatchAdapter constrói snapshot a partir de fixture/contratos/elenco, com seed fornecida pelo chamador; não modifica o mundo durante simulação. MatchResult final validado é entregue a `SeasonService.submit_result`. SeasonService não passou a depender do MatchSimulator e continua aceitando resultado externo. Negociação, economia, recuperação de condição, IA gerencial e fechamento de rodada completo não entram nessa integração.

Decisão de save: o plano exige retomada ativa, portanto **schema_version 3 / save_version phase-4-v1**. WorldState recebe apenas um campo `active_match`, null ou checkpoint de primitivas; o motor continua independente de persistência. Codec explícito inclui checkpoint_version 1, versão Godot/motor, input/configuração, seed, minuto, estado RNG, comandos e estado/eventos resolvidos.

IDs, seed e state RNG int64 continuam strings decimais canônicas no JSON. Load reconstrói input e reproduz os trechos/comandos já confirmados para verificar estado/eventos/RNG; divergência é rejeitada. Depois restaura o state RNG validado para continuar. Não consulta config atual, não troca acontecimentos anteriores por um novo resultado e não usa essa reconstrução como reroll. Esse replay de validação custa trabalho proporcional a até 90 minutos; não foi otimizado prematuramente.

Checkpoint verifica fixture atual não concluída, participantes e pertencimento/identidade/posição dos atletas no mundo. Testada retomada em minutos 0, 23, 45 e 75, depois de comandos e por JSON real em disco. Seed máxima int64 preservada. Resultados/eventos corrompidos, RNG divergente e versões incompatíveis são recusados. SaveRepository protege também checkpoint de versão futura contra sobrescrita quando o outro snapshot permite fallback.

Migração **2→3** preserva toda competição e adiciona `active_match = null`, sem criar partida ou progresso. Migração antiga de schema 1 permanece suportada, com criação da temporada inicial já prevista na Fase 3 e emissão no schema atual. Testes anteriores e suas descrições históricas foram mantidos; seus rótulos sobre schema 2 não significam que o writer atual continue nessa versão. Load não grava a migração automaticamente.

O chamador salva checkpoint e limpa `active_match` antes de confirmar resultado. Não foi criado GameSession completo, comando composto de UI ou save automático. Depois do commit, Fixture mantém o placar canônico; arquivo histórico completo de replays/resultados fica para etapa posterior, não é prometido aqui. A/B e limites de durabilidade física da Fase 2 permanecem.

## Testes e batch estatístico

Validação final: **410 PASS / 0 FAIL**, sendo **322 anteriores + 88 da Fase 4** (78 verificações unitárias/integração e dez do batch). Probe: 410 PASS / uma falha intencional, exit 1. Os testes anteriores permanecem sem remoção/ignorância/enfraquecimento. Novos testes cobrem isolamento de input/result, entradas inválidas, formações/funções/adequação, condição, táticas, autores/eventos/estatísticas, replay/queries/RNG, comandos/substituições, retomada em memória/disco, integração e migração 2→3/proteção de versões futuras.

Batch independente executado com sucesso: **10.000 partidas**, mais **2.000** para comparação pareada de mando (1.000 em cada grupo). Versão do motor 1; config phase-4-test-v1; seeds 0 até N−1 por cenário, e 20.000–20.999 no pareado. Nenhum comando nas partidas estatísticas. Cada resultado passou por verificação de eventos, autoria e invariantes de estatísticas.

| Cenário (mandante × visitante) | N | Gols/jogo | Vitória mandante | Empate | Vitória visitante |
|---|---:|---:|---:|---:|---:|
| Equivalentes, overall 60×60 | 2.000 | 2,279 | 39,00% | 29,80% | 31,20% |
| Mandante superior, 85×40 | 1.500 | 3,211 | 89,00% | 9,13% | 1,87% |
| Visitante superior, 40×85 | 1.500 | 3,046 | 2,60% | 10,33% | 87,07% |
| Pequeno×elite, 37×77 | 1.000 | 3,026 | 3,90% | 10,80% | 85,30% |
| 60×60, condição mandante 25 | 1.000 | 2,944 | 4,30% | 12,30% | 83,40% |
| OFENSIVA×EQUILIBRADA, 60×60 | 1.500 | 2,811 | 39,00% | 26,07% | 34,93% |
| CAUTELOSA×EQUILIBRADA, 60×60 | 1.500 | 1,742 | 35,13% | 33,53% | 31,33% |

Os cenários comprovam tendência neste modelo/fixture: qualidade superior favorece sem impedir derrotas/empates; condição baixa reduz contribuição. Não estimam futebol real nem provam equilíbrio final. O agregado mistura forças distintas e três cenários desfavoráveis ao mandante; não usar sua taxa de vitória visitante como medida de mando.

| Agregado das 10.000 | Valor |
|---|---:|
| Gols totais | 26.743 |
| Média total | 2,6743 |
| Gols mandante / média | 11.637 / 1,1637 |
| Gols visitante / média | 15.106 / 1,5106 |
| Vitória mandante / empate / visitante | 33,48% / 20,13% / 46,39% |
| 0x0 | 761 (7,61%) |
| Sete ou mais gols | 207 (2,07%) |
| Maior total observado | 10 gols; 8x2 e 10x0 |

Distribuição básica de placares (mandante×visitante): 0x1 1.030; 1x1 935; 0x2 869; 1x0 825; 0x0 761; 0x3 647; 1x2 585; 2x0 580; 2x1 550; 3x0 391. Distribuição completa emitida em stdout. Placares extremos continuam possíveis; não eliminar a cauda por um limite artificial de gols. O primeiro lote com frequência 0,34 teve média 3,5026 e pico 13x0; revisão provisória para 0,26 reduziu a cauda, sem alterar testes para esconder falhas.

Trade-offs observados, chances/jogo de mandante/visitante: equilibrado **6,948 / 6,301**, ofensivo **7,851 / 7,540**, cauteloso **5,639 / 5,444**. Ofensiva aumentou criação própria e oportunidades rivais, além de desgaste; cautelosa reduziu ambas. Isso não prova ausência de uma tática dominante em todas as formações/forças/comandos.

Mando pareado: neutro 38,1% vitória mandante e 34,9% visitante; vantagem 41,8% e 31,0%. Ticks de iniciativa mandante subiram de 45.136 para 47.408. Efeito observado pequeno, com derrotas do mandante presentes; não é garantia por partida.

Batch independente de 10.000: **77,149 segundos**; o tempo do pareado adicional não está incluído nessa medição. Memória estática Godot de 26.528.934 para 26.591.450 bytes, aumento de 62.516 bytes (inclui tabelas de métricas acumuladas). Nenhum erro/exceção; dez verificações do batch passaram. O diagnóstico de 32 MiB de crescimento é um alerta conservador do harness, não orçamento Android. Não foi medido pico de processo, bateria ou uso em dispositivo.

## Execução real e arquivos

Engine: `C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`, versão retornada **4.7.2.stable.official.ed1daf0bf**, hash ed1daf0bf. Processos fora do sandbox com aprovação, aguardados por Start-Process -Wait -PassThru -WindowStyle Hidden, stdout/stderr em TEMP.

| Check | Argumentos | Exit / resultado |
|---|---|---|
| Versão | `--version` | 0; versão acima |
| Import | `--headless --path games/club-legacy --editor --quit` | 0; stderr vazio |
| Suíte | `--headless --path games/club-legacy --script res://tests/run_tests.gd --quit-after 1000` | 0; 410 PASS/0 FAIL; stderr vazio |
| Probe | mesmos argumentos + `-- --force-failure` | 1; 410 PASS/uma falha intencional; somente `FAIL: Intentional runner failure probe` em stderr |
| Startup | `--headless --path games/club-legacy --quit-after 2` | 0; stderr vazio |
| Batch separado | `--headless --path games/club-legacy --script res://tests/simulation/run_match_batch.gd --quit-after 1000` | 0; 10 PASS/0 FAIL; stderr vazio |

Limite de frames é uma proteção do processo, não evidência de sucesso; somente resumo completo, stderr e exit do runner são considerados. Logs `club-legacy-phase4-{version,import,normal,failure,startup,batch}.{stdout,stderr}.txt` em TEMP, não versionados.

Criados: dez scripts em `scripts/domain/match/` (cinco modelos, quatro componentes de regra e simulador), `scripts/application/fixture_match_adapter.gd`, `scripts/persistence/match_checkpoint_codec.gd`, `tests/unit/match_engine_tests.gd`, `tests/simulation/match_batch_tests.gd` e `run_match_batch.gd`, mais `.gd.uid` gerados pelo Godot e este relatório.

Modificados: WorldState, WorldCodec, SaveEnvelope, SaveRepository, runner principal, plano e README. Main, GameSession e cenas não foram ampliados.

## Falhas corrigidas e limites

Primeira execução encontrou parsing por constante `Input` em conflito com classe nativa; renomeada para MatchInputModel. Embora o processo tenha retornado 0 após o limite de segurança, havia erros e execução incompleta: não foi considerado sucesso. Em seguida, round-trip do resultado divergiu porque atletas de mundo tinham overall inteiro e parse JSON trazia float; normalizada a representação numérica no input, sem alterar atributos ou enfraquecer comparação. Reexecutadas suítes completas após correções.

Revisão independente identificou restrição indevida na troca de formação, falta de validação de pertencimento do checkpoint, adapter aceitando resultado malformado e retries limitados ao minuto original. Corrigidos e acrescentadas regressões. Também protegido checkpoint futuro e rejeitado goleiro em função de campo, mantendo seleção de finalizador consistente com função/adequação.

Sem UI, controle de atletas, campo/animação 2D/3D, áudio, monetização, Android, rede/backend ou multiplayer. Sem cartões/lesões/VAR, transferências, economia, instalações funcionais, torcida dinâmica, demissão ou vagas. Sem IA completa de reação adversária; comandos programados podem atuar sobre ambos os lados pelo mesmo motor. Onboarding, apresentação/velocidade/pausa, coordenação de sessão e aplicação dos efeitos finais ao mundo ficam para etapas autorizadas posteriores.

Git: diff --check, diff --stat e status --short executados com safe.directory restrito ao repositório, todos exit 0. Diff check passou, com avisos de LF/CRLF; diff stat: sete arquivos rastreados, 33 inserções/seis remoções. Status mostra os sete modificados e arquivos novos não rastreados desta fase. Aviso de acesso ao ignore global não impediu leitura. Nenhum add/reset/restore/commit/push executado; staging preservado. Arquivos novos não rastreados não entram em diff --stat. Inspeção final da pasta usual user:// não encontrou diretórios phase4_tests_* residuais.

**Conclusão: todos os critérios obrigatórios da Fase 4 passaram no ambiente headless validado. Parar aqui. Fase 5/Vertical Slice não iniciada; Android não validado.**
