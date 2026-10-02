# Club Legacy — Fase 5: Vertical Slice

**01/10/2026 · Game Developer · parte automatizada CONCLUÍDA**

Autorização restrita à Fase 5. Lidos AGENTS.md, papel Game Developer, skill godot-development, GDD, arquitetura, plano e relatórios das Fases 0–4. Plano atualizado antes do código. Fase 6 não iniciada; nenhum Android, instalação, alteração de staging, commit ou push. Interface desktop provisória, sem representar orientação Android definitiva ou MVP completo.

## Fluxo entregue

**Criar treinador → escolher perfil/clube → escalar → jogar → receber resultado → atualizar classificação → salvar → carregar.**

GameSession permanece o único Autoload e coordena comandos, sinal de mudança e avanço de apresentação. CareerFlow concentra a aplicação testável sem SceneTree, compondo os serviços existentes. Domínio e motor continuam independentes da UI; controles consultam projeções e solicitam comandos. Main monta destinos dentro de ScreenHost e usa DialogLayer para erros e confirmação.

| Tela | Comportamento entregue |
|---|---|
| Início | Nome do treinador, PEQUENO/MÉDIO/ELITE, criação, continuar e confirmação de substituição |
| Home | Treinador/clube, divisão, rodada, próximo rival, posição e acesso ao fluxo seguinte |
| Elenco | 18 atletas, posição, qualidade, potencial, condição e papel na seleção |
| Escalação | Onze titulares, até sete reservas, sugestão, três formações e três táticas; validação antes de jogar |
| Partida | Placar, relógio, eventos, estatísticas, pausa, 1x/2x/4x, intervalo, formação/tática e três substituições |
| Resultado | Placar, estatísticas e gols; continuação para Home/tabela |
| Classificação | Duas divisões, seis clubes por divisão e estatísticas derivadas de fixtures confirmados |

Tema nativo escuro, Containers, área rolável e destaque dourado; nenhum asset esportivo ou interface importada. Botões de confirmar/jogar ficam antes da lista longa de escalação. Menus de intervenção pausam a partida; selecionados são preservados durante atualização de minuto e suas condições refletem MatchState. Carregar outra partida reconstrói os controles mesmo quando possui igual quantidade de comandos.

LineupSelector é **VERTICAL SLICE PLACEHOLDER**: posição natural, maior overall e ID como desempate estável. Sugere escalação do usuário e dos adversários; não é IA gerencial. FixtureMatchAdapter valida pertencimento ao elenco e deixa MatchInput validar quantidades/posições/duplicações. Trocas de formação durante jogo usam as regras já existentes, inclusive adequação fora da posição.

## Partida, rodada e determinismo

Não há partida instantânea no fluxo visual. CareerFlow acumula tempo de apresentação e solicita avanços indivisíveis ao MatchSimulator existente. Um minuto esportivo consome inicialmente 0,75 segundo em 1x; 2x/4x alteram somente apresentação. Pausa limpa a espera acumulada e não consome RNG. Minuto 45 exige continuar; fim ocorre no minuto 90. Comandos de tática, formação e substituição usam fronteiras e chaves do motor, sem reescrever eventos anteriores.

Seed da fixture deriva de SHA-256 com prefixo versionado, seed da carreira e ID da fixture; não depende de relógio ou velocidade. Os outros cinco jogos da rodada usam o mesmo MatchSimulator, com escalação mínima e tática equilibrada. Não há algoritmo alternativo de placar nem reação adversária completa.

Fechamento trabalha sobre cópia validada do mundo: limpa active_match do candidato, confirma resultado do usuário e dos rivais, faz commit da rodada e somente publica após sucesso. Falha preserva o mundo anterior. Repetir fechamento não confirma resultados outra vez. Classificação é derivada por TableCalculator. Após dez rodadas, encerrar competição não cria nova temporada, paga prêmio ou muda divisões efetivamente.

## Save, load e erros

Save é **explícito**, sem autosave. Schema permanece **3 / phase-4-v1**: nenhuma nova migração ou campo persistente foi inventado. Salvar durante partida produz checkpoint atual com entrada, escalação, comandos, eventos e RNG; load reconstrói e valida pelo codec existente, retomando **pausado**. Não gera carreira nova em erro de leitura.

Escalação pré-jogo é transitória e recebe sugestão ao carregar fora de partida; resultado detalhado também é transitório. Placar confirmado e tabela continuam no mundo salvo. Condição durante partida funciona, mas não foi introduzida aplicação/recuperação de condição entre rodadas no WorldState. Histórico completo de replays fica para etapa posterior. Fechar sem salvar perde mudanças posteriores ao último checkpoint.

Nova carreira pede confirmação quando já existe carreira em memória ou snapshot. A substituição em disco só ocorre ao salvar a nova carreira confirmada. SaveRepository valida e prepara o novo snapshot, conserva arquivos `previous-a.json`/`previous-b.json` de uma geração anterior e usa `replacement.pending` para recuperação do intervalo de substituição. Falha simulada restaura a carreira antiga; load consegue recuperar arquivos anteriores quando A/B estão ausentes e o marcador existe. Salvar após recuperação consolida o estado. Outra substituição é recusada enquanto recuperação estiver pendente, evitando remover a única cópia recuperável. Arquivos incompatíveis não são sobrescritos para contornar erro.

A/B normal e fallback continuam validados. Fallback é comunicado ao usuário; ausência/corrupção de save, nome vazio, seleção inválida, comando rejeitado e falha de gravação têm mensagens, sem publicar candidato parcial. Arquivos de testes usam diretórios exclusivos em user:// e limpeza de arquivos conhecidos. Não há garantia absoluta contra perda de energia/filesystem danificado, lock entre processos ou múltiplos slots visíveis.

## Execução e testes

Engine executada: `C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`, versão **4.7.2.stable.official.ed1daf0bf**, hash **ed1daf0bf**. Processos aguardados por Start-Process -Wait -PassThru, stdout/stderr capturados em TEMP; execução fora do sandbox com aprovação para acesso da engine a user://. Nenhuma instalação.

| Verificação | Argumentos | Exit e resultado |
|---|---|---|
| Versão | `--version` | 0; versão acima, stderr vazio |
| Import | `--headless --path games/club-legacy --editor --quit` | 0; stderr vazio |
| Suíte completa | `--headless --path games/club-legacy --script res://tests/run_tests.gd --quit-after 1000` | 0; **490 PASS / 0 FAIL**, stderr vazio |
| Probe | mesmos argumentos + `-- --force-failure` | 1; **490 PASS / 1 falha intencional** |
| Startup | `--headless --path games/club-legacy --quit-after 2` | 0; stderr vazio |
| Suíte focada | `--headless --path games/club-legacy --script res://tests/run_vertical_slice.gd` | 0; **80 PASS / 0 FAIL**, stderr vazio |
| Smoke gráfico | `--path games/club-legacy --script res://tests/visual_smoke.gd` | 0; nove capturas, stderr vazio |

Probe registrou somente `FAIL: Intentional runner failure probe`. O limite de frames é proteção, não critério de sucesso: resumos completos, stderr e exit foram verificados. Logs: `club-legacy-phase5-{version,import,normal,failure,startup,visual}.{stdout,stderr}.txt` em TEMP; logs focados também foram capturados. Não são dependências versionadas.

**410 verificações anteriores preservadas + 80 novas.** Cobertura nova: três perfis, navegação/controles, seleção inválida e válida, formações, início incremental, pausa, intervalo, velocidades com resultado idêntico, comandos, três rodadas consecutivas, seis resultados por rodada, idempotência, save/load após destruir o coordenador, checkpoint exato após intervenções, fallback A/B, confirmação de nova carreira, rollback e recuperação de substituição. Comparações não se limitam a contagem de entidades.

Uma pequena correção final de reconstrução da tela ao carregar outra MatchState foi verificada novamente pela suíte focada e smoke gráfico; o probe completo também executou o código final. Nenhum teste anterior removido, ignorado ou enfraquecido.

## Smoke observado e OWNER CHECK REQUIRED

Smoke gráfico executado em Compatibility/OpenGL 3.3, GeForce RTX 3050, driver NVIDIA 591.86. Capturas geradas pelo viewport Godot em `TEMP/club-legacy-phase5-visual/`: Início, Home, Elenco, Escalação, Partida pausada, Partida carregada, Resultado, Tabela e Home carregada. Imagens realmente abertas e inspecionadas: textos/controles legíveis, botões de escalação acessíveis, condição atualizada, placar/eventos de retomada e rodada seguinte presentes.

O harness acionou controles/comandos por código; isso **não comprova interação real por mouse/teclado**, navegação por foco, scroll manual, redimensionamento ou percepção do ritmo. Esses itens permanecem **OWNER CHECK REQUIRED**:

1. Abrir o projeto no Godot e executar Main; criar carreira em cada perfil e conferir os resumos.
2. Percorrer Elenco e Escalação com scroll; editar titulares/reservas, tentar seleção inválida e confirmar uma válida.
3. Jogar em 1x/2x/4x; pausar, continuar no intervalo e alterar tática/formação; realizar três substituições e conferir bloqueio da quarta.
4. Salvar durante partida, fechar e abrir o app, escolher Continuar e verificar retomada pausada; terminar, conferir resultado/tabela e próxima rodada.
5. Salvar fora da partida, reabrir e conferir carreira; testar recusa de nova carreira e confirmação apenas quando desejar substituir o progresso.

Não marcar esses itens como PASS antes de realizá-los. Nenhum teste visual Android foi executado.

## Arquivos e correções

Criados: `scripts/application/career_flow.gd`, `scripts/domain/services/lineup_selector.gd`, `ui/{main,slice_theme,slice_views}.gd`, `tests/integration/vertical_slice_tests.gd`, `tests/run_vertical_slice.gd`, `tests/visual_smoke.gd`, metadados `.gd.uid` e este relatório. Modificados: GameSession, FixtureMatchAdapter, MatchInput, SaveRepository, Main, project.godot, runner, plano e README.

Primeiro import revelou parâmetro `namespace` reservado; renomeado para career_namespace. Import com exit 0 e parsing error não foi considerado sucesso. Primeira suíte completa: 489 PASS / 1 FAIL, comparação exata de checkpoint por engine_version inteiro versus float após JSON. Normalizada a representação no MatchInput; não alterado algoritmo ou enfraquecida comparação. Após correção: 490/0. Inspeção gráfica motivou mover botões de escalação e atualizar condição nos menus. Revisão independente identificou pausa não sinalizada em falha de avanço e risco de substituir arquivos anteriores durante recuperação pendente; corrigidos e cobertos por verificações.

## Limites e encerramento

Somente slice desktop/offline com configuração TEST / PLACEHOLDER. Não comprova balanceamento, diversão, retenção ou MVP completo. Sem finanças operacionais, salários/bilheteria/prêmios, mercado, obras, evolução anual, dinâmica de emprego, arte esportiva, áudio, backend, multiplayer ou monetização. Estádio/caixa iniciais são dados estáticos, não sistemas funcionais. Fase 6+ depende de autorização posterior.

Verificações Git finais: diff --check, diff --stat e status --short com safe.directory restrito ao repositório. Diff check sem erros; apenas avisos LF/CRLF. Diff stat: nove arquivos rastreados, 110 inserções e 21 remoções; arquivos novos não rastreados não entram nessa contagem. Aviso de permissão no ignore global não impediu os comandos. Staging preservado; nenhum add/reset/restore/commit/push.

**Parte automatizada da Fase 5 concluída; renderização gráfica observada, interação manual OWNER CHECK REQUIRED. Parar aqui. Fase 6 não iniciada; Android não validado.**
