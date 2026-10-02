# Club Legacy — Fase 5.1: UI/UX Foundation e identidade visual

**02/10/2026 · Game Developer · fundação implementada**

Escopo autorizado: somente Fase 5.1. O proprietário aprovou a Fase 5 e seu Owner Check manual, inclusive fechamento/reabertura do jogo e retomada de partida salva. Esta entrega registra uma revisão visual posterior; não altera o registro histórico daquele teste nem declara aprovação estética da nova UI.

Lidos AGENTS.md, agents/game-developer.md, skills/godot-development/SKILL.md, GDD, arquitetura, plano, relatórios das Fases 0–5 e UI existente. Skill frontend-design aplicada à apresentação nativa Godot. Plano atualizado antes de alterações substanciais. Investigação independente de regressões feita por agente somente em leitura, sem edição concorrente.

**Owner Visual Check: APPROVED. Fase 5.1 concluída e aprovada pelo owner.** Direção visual, densidade e responsividade aprovadas para continuidade do MVP. O registro inicial abaixo mantém as evidências históricas; as atualizações e aprovação final estão ao final. Fase 6 não iniciada. Sem instalações, Android build, staging, commit, push ou publicação.

## Referência e decisões

Imagem oficial localizada e realmente inspecionada: [club-legacy-dashboard-concept.png](../../docs/visual-reference/club-legacy-dashboard-concept.png). Identificados sidebar esquerda, contexto da carreira no topo, próximo jogo dominante, escudos como identidade, cards densos, navy quase preto e dourado. A composição orientou a implementação; não é reprodução pixel-perfect.

Adaptação: próximo jogo é um duelo de badges originais, com ação **PREPARAR PARTIDA**, seguida por classificação/desempenho/resultados/próximos jogos/elenco. O campo tático estático é o elemento esportivo distintivo da preparação. Arte de estádio, retratos, clima, horários, notificações e métricas avançadas da imagem não foram importados ou inventados. Não houve download de assets, fonte ou API.

## Design system e componentes

Tokens centralizados em `ui/slice_theme.gd`:

| Token | Valor |
|---|---|
| Background | #0b1018 |
| Surface | #141e2b |
| Surface elevada | #1d2a39 |
| Border | #2d3b4c |
| Texto primário / secundário | #edf0f4 / #a3b0bf |
| Accent gold / warning | #dfb76d / #d5ae65 |
| Success / danger | #7bbd99 / #cd8483 |

Tipografia: Bahnschrift com fallback Segoe UI/Noto Sans para títulos e números de destaque; Segoe UI/Noto Sans para leitura. Fontes de sistema, sem arquivos externos/licenciamento novo. Hierarquia: display 38, título 27, seção 19, card 16, body 15, caption 12, destaque numérico 30. Spacing 4/8/12/18/24/32; raios de card 7, botão/input 5, badge/barra 4. Estados normal, hover, pressed, selected, disabled e focus são definidos no tema/componentes; foco usa borda dourada. Botões funcionais possuem altura mínima 44; slots do campo são maiores. Nenhuma ação depende de hover.

Componentes usados: AppShell/Sidebar/TopBar; card/header; botão primário/secundário/selecionado; ClubBadge; PlayerCard; ConditionIndicator; EmptyState; StandingsTable; TacticalPitch; comparação de estatísticas; timeline e dialogs. Permanecem locais ao jogo: não foi criada biblioteca shared sem uso comprovado. Pequenas cores de identidade/campo e dimensões próprias do desenho ficam nos componentes correspondentes.

## Shell e identidade

Sidebar permanece como o mesmo objeto através de mudanças de tela; conteúdo de ScreenHost é substituído dentro da área principal. TopBar mostra clube/badge, temporada, liga e treinador reais. Navegação funcional: Início da carreira/Home, Elenco, Escalação, Competições, Salvar e Nova/continuar. Clube/Finanças/Mercado/Estádio/CT/Empregos são itens **desabilitados**, marcados “em breve”, sem tela falsa.

Salvar e Nova/continuar ficam no rodapé acessível. Área de navegação possui scroll próprio quando falta altura; conteúdo tem scroll separado por responsabilidade. Não há conta, avatar real, configuração complexa ou notificação funcional.

Catálogo visual cobre os 12 nomes existentes sem renomear: Aurora de Neral, Vale de Tervan, Porto de Luren, Estrela de Soval, Monte de Ardel, União de Veldra, Riacho de Belven, Lago de Orven, Pedra de Ceral, Campos de Darel, Vila de Erel e Horizonte de Farel. Cada um possui abreviação e duas cores. Badges são escudos geométricos originais desenhados em Godot, com iniciais e faixa discreta; não são arte final.

Esse catálogo é apresentação por nome conhecido, sem mudar IDs/relações do domínio. Clube renomeado recebe placeholder de iniciais e cor derivada de seu ID; preservar exatamente a identidade visual ao renomear exigiria catálogo autoral com chave própria numa etapa futura, não uma alteração de schema agora.

## Telas entregues

| Tela | Comportamento e fonte dos dados |
|---|---|
| Inicial | CLUB LEGACY, tagline, nome, três cards de desafio selecionáveis e botão iniciar; perfis mantêm regras existentes |
| Continuar | Preview de save validado pelo repositório; treinador/clube/temporada; active_match mostra placar/minuto reais e RETOMAR PARTIDA |
| Home | Próximo fixture/rodada/mandos/badges e posição; PREPARAR abre escalação, não inicia jogo |
| Classificação resumida | TableCalculator por CareerFlow.standings; clube controlado em dourado, J e PTS, link para completa |
| Últimos resultados | Somente fixtures COMPLETED do clube; V/E/D e placar real; EmptyState quando vazio |
| Desempenho | Jogos, vitórias, empates, derrotas e gols pró/contra da linha canônica da classificação |
| Elenco resumido | Quantidade, condição média, melhor overall e dois destaques reais; nenhum retrato real |
| Próximas partidas | Fixtures pendentes reais, ordenados por rodada, adversário e CASA/FORA |
| Elenco | Tabela nativa com filtros TODOS/GK/DEF/MID/ATT, overall dourado, potencial secundário, condição/status e seleção |
| Escalação | Campo escuro com linhas/áreas/círculo, onze slots por setor, banco separado e táticas segmentadas |
| Partida | Placar dominante com badges/nomes, minuto/estado/velocidade, timeline, comparação de posse/chances/chutes/no alvo e painel de ajustes |
| Resultado | APITO FINAL, placar, vitória/empate/derrota relativa ao clube do usuário, autores/minutos de gols, estatísticas e continuar |
| Classificação completa | POS/CLUBE/J/V/E/D/GP/GC/SG/PTS, badges, clube controlado destacado; primeiro da II em verde, último da I em vermelho |

DashboardProjection é leitura da apresentação: não guarda tabela própria nem processa resultados. Ordena fixtures já existentes e resume roster. Não consome RNG, avança calendário ou altera WorldState. Condição da Home/Elenco vem do estado do clube existente; efeitos físicos entre rodadas continuam fora deste recorte, conforme Fase 5. Na partida, os controles mostram condição atual de MatchState. Não simular melhoria de condição ou progressão anual para enriquecer cards.

## Campo, banco e comandos

Formações 4–4–2, 4–3–3 e 5–3–2 reorganizam visualmente as linhas ATT/MID/DEF/GK. Escolher formação usa a sugestão existente e pode recompor os titulares; não é drag-and-drop nem treino. Slot mostra nome abreviado, posição, overall e condição. Nome repetido não define identidade: comandos usam IDs.

Clique/toque no titular → seleção indicada em texto → escolha “Trocar” num atleta do banco. A alteração passa por CareerFlow.set_lineup e validação existente; posição incompatível não publica escalação inválida. Sugestão, confirmação e iniciar continuam disponíveis. Banco possui sete atletas sugeridos, com potencial secundário/barra de condição. Não foi criado novo algoritmo de escalação.

Táticas pré-jogo têm descrições curtas sem multiplicadores; seleção é enviada ao confirmar/iniciar. Ajustes durante partida usam MatchCommands existentes. Formação durante jogo pode redistribuir funções pelas regras do motor; o campo de preparação não anima lances.

Pausa/continuar e 1x/2x/4x mantêm efeito apenas de apresentação, com velocidade selecionada destacada. Intervalo fica explícito e a ação passa a “INICIAR SEGUNDO TEMPO”. Timeline distingue tipos por texto e destaca GOL em dourado/negrito, sem depender de emoji. Estatísticas comparativas consultam projeção existente, inclusive posse aproximada. Não há xG/moral/momentum inventado.

Atualização incremental de Match preserva widgets, menus e seleções entre ticks/save; comandos ou outra MatchState reconstruem o conteúdo necessário. Modal de atenção pausa a partida. Retry de fechamento aparece quando estado FINISHED persistir após erro, sem liberar avanços indevidos.

## Save/load e regressões preservadas

Nenhuma alteração em domínio, application, MatchSimulator, GameSession, persistência, RNG, schema ou formatos de save nesta fase. UI solicita os mesmos comandos. Schema 3 e seus limites permanecem; save explícito continua obrigatório. Preview lê somente o save validado e não grava automaticamente.

Retomar pelo preview chama load_career e permanece pausado. Teste compara checkpoint inteiro antes/depois, incluindo minuto/eventos/comandos/RNG; input da simulação também permanece idêntico. Seleção pré-jogo e resultado detalhado continuam transitórios. Os 490 testes prévios foram preservados, incluindo confirmação/substituição de nova carreira e recuperação A/B. A nova UI não promete que velocidade de apresentação seja persistida: load mantém o comportamento anterior de retornar em 1x.

## Responsividade e observação gráfica

Containers/anchors/size flags estruturam shell, cards, grade, campo e controles. Grades de Home/banco passam a uma coluna em largura reduzida; dimensões mínimas mantêm números e targets legíveis. Listeners de resize são desconectados ao remover componentes, evitando acumular callbacks a cada navegação. Sidebar/TopBar permanecem e o conteúdo longo rola. Elenco conserva scroll da Tree, útil para os 18 atletas; não há múltiplos scrolls empilhados para a mesma lista de cards.

Smoke executado em **1100×780** e **860×650**, Compatibility/OpenGL 3.3, NVIDIA GeForce RTX 3050, driver 591.86. Screenshots realmente abertas/inspecionadas: inicial, Home superior/inferior, elenco, campo nas três formações, banco/ações, partida pausada, preview ativo, resultado, tabela e variantes reduzidas. Rendering passou; não é comparação pixel-perfect nem aprovação estética.

Capturas em `TEMP/club-legacy-phase51-visual/`, 19 imagens: nove telas base, Home inferior, banco, duas formações adicionais, preview e cinco variantes reduzidas. Harness aciona controles/sinais e comandos, sem coordenadas de mouse. Ajustes de scroll/tamanho no harness comprovam renderização desses estados, não toda interação manual em todos os tamanhos. Layout Android final, acessibilidade em aparelho, toque físico e export não foram testados.

## Execução real

Executável: `C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`. Versão retornada **4.7.2.stable.official.ed1daf0bf**, hash ed1daf0bf. Processos aguardados por Start-Process -Wait -PassThru; Hidden em headless, Normal no smoke solicitado. Logs stdout/stderr em TEMP. Execução fora do sandbox com aprovação, necessária ao acesso da engine a seus caches/user://; nenhuma instalação.

| Verificação | Argumentos | Exit / resultado |
|---|---|---|
| Version | `--version` | 0; versão acima, stderr vazio |
| Import | `--headless --path games/club-legacy --editor --quit` | 0; stderr vazio |
| Suíte completa | `--headless --path games/club-legacy --script res://tests/run_tests.gd --quit-after 1000` | 0; **533 PASS / 0 FAIL**, stderr vazio |
| Probe | runner acima + `-- --force-failure` | 1; **533 PASS / 1 falha intencional**, somente mensagem prevista em stderr |
| Startup | `--headless --path games/club-legacy --quit-after 2` | 0; stderr vazio |
| Focada | `--headless --path games/club-legacy --script res://tests/run_vertical_slice.gd --quit-after 1000` | 0; **123 PASS / 0 FAIL**, stderr vazio |
| Smoke gráfico | `--path games/club-legacy --script res://tests/visual_smoke.gd` | 0; 19 PNGs gravados, stderr vazio |

Logs: `club-legacy-phase51-{version,import,normal,failure,startup,focused,visual}.{stdout,stderr}.txt` em TEMP. Limite de frames não é evidência de sucesso: resumo completo, stderr e exit foram conferidos. Probe registrou `FAIL: Intentional runner failure probe`.

**43 testes novos + 490 anteriores.** Cobertura nova: shell estável, comandos indisponíveis antes da carreira, 12 identidades, dados reais da Home e ausência de mutação por leitura, preparação sem pular escalação, linhas nas três formações, banco separado, troca válida/recusa inválida, menus preservados em atualização, modal pausa, preview do save ativo, checkpoint/input intactos, resultado, continuidade da rodada e limpeza de saves isolados. Sem testes de coordenadas/pixels/screenshot comparison.

Após ajustes finais apenas de largura/alinhamento dos rótulos numéricos e CASA/FORA, a suíte focada 123/0 e o smoke completo foram repetidos; a suíte completa acima valida todos os componentes e regras. Nenhum teste removido, ignorado ou enfraquecido.

## Falhas encontradas e corrigidas

- Import detectou inferência de tipo em retorno dinâmico da grade; adicionada tipagem explícita. Exit 0 com stderr de parsing não foi aceito como sucesso.
- Constante Projection conflitou com tipo nativo Godot; renomeada Dashboard. A execução inicial incompleta da UI não foi tratada como aprovação.
- Inspeção revelou nomes/números quebrando em colunas, VS estreito e rótulos CASA/FORA verticais; corrigidas larguras mínimas e wrapping por função.
- Sidebar inicialmente excedia altura; navegação recebeu scroll e ações de rodapé fixas.
- Fonte de badge era temporária no draw; mantida referência no componente para glifos renderizados corretamente.
- Revisão apontou modal deixando simulação rodar e retry de rodada pouco acessível; pausa de modal e visibilidade incremental corrigidas na apresentação.

## Arquivos e verificação Git

Criados em `games/club-legacy/ui/`: app_shell.gd, game_components.gd, club_identity.gd, club_badge.gd, dashboard_projection.gd, career_screens.gd, lineup_screen.gd e tactical_pitch.gd. Criado `tests/integration/ui_foundation_tests.gd` e metadados .gd.uid gerados pelo Godot. Criado este relatório.

Modificados: ui/main.gd, ui/slice_views.gd, ui/slice_theme.gd, tests/run_tests.gd, tests/run_vertical_slice.gd, tests/visual_smoke.gd, README e plano. Referência PNG já foi fornecida pelo proprietário; não foi alterada. Nenhuma cena/projeto/engine/renderer/domínio/save foi modificado para acomodar a UI.

Git diff --check, diff --stat e status --short executados com safe.directory restrito ao repositório, sem erros de diff check. Somente avisos LF/CRLF e de acesso ao ignore global; estes não impediram a verificação. Diff stat: oito arquivos rastreados, 257 inserções/281 remoções. Novos componentes/teste/relatório e referência do proprietário aparecem não rastreados e não entram nessa contagem. Staging preservado; nenhum add/reset/restore/checkout/commit/push.

## Aprovação humana pendente e limites

**OWNER VISUAL CHECK REQUIRED** para avaliar estética, densidade, leitura, campo, badges, tamanho/scroll, perfil por cards e foco/cliques reais. Roteiro: abrir Main, criar cada perfil, preparar formação/tática, selecionar titular e trocar pelo banco, confirmar/jogar, pausar/velocidades/intervalo/ajustes/substituições, salvar ativa, fechar/reabrir, continuar pelo preview e concluir rodada; conferir Home/tabela/resultado e redimensionar a janela. Aprovação anterior da Fase 5 não aprova automaticamente este redesign.

Esta entrega não acrescenta sistemas futuros: economia, mercado, receitas/despesas, estádio/CT funcionais, diretoria, demissão, empregos, evolução anual, notificações, notícias, conquistas, backend, monetização ou Android. Não há 216 retratos nem 12 escudos profissionais finais. O motor e parâmetros TEST permanecem sem nova alegação de balanceamento/função comercial.

## Atualização — aprovação visual e correção final da sidebar

O proprietário aprovou identidade, sidebar, topbar, cards, badges, escalação, central da partida, resultado e classificação como fundação visual do MVP. A única correção solicitada antes do encerramento foi o corte vertical do título/logo.

Em `ui/app_shell.gd`, CLUB LEGACY foi retirado da área rolável da navegação e mantido em um cabeçalho fixo, com margem superior/inferior e quebra automática desativada. Assim, rolar os itens não oculta o título e há espaço para os ascendentes da fonte. Nenhum redesign adicional ou mudança em domínio, gameplay, Match Engine, persistência, RNG ou schema.

Validação após a correção, na mesma engine validada: runner relevante `tests/run_vertical_slice.gd` com **123 PASS / 0 FAIL**, exit 0 e stderr vazio; smoke gráfico com **19 capturas**, exit 0 e stderr vazio. Capturas de Home em **1100×780** e **860×650** foram abertas e inspecionadas: CLUB LEGACY completamente visível. Logs `club-legacy-phase51-brand-{focused,visual}.{stdout,stderr}.txt` em TEMP. Todos os testes anteriores foram preservados; o batch/suíte completa 533/0 acima não foi repetido para esta alteração localizada de layout.

**Owner Visual Check aprovado após esta correção, conforme decisão do proprietário. Fase 5.1 encerrada.** Melhorias estéticas adicionais ficam como polish futuro e não bloqueiam o MVP. Sem commit/push ou início da Fase 6.

## Atualização — ajuste final de densidade / viewport

Pedido posterior do proprietário: manter a direção aprovada e fazer Nova/continuar caber integralmente em 1100×780, sem esconder scrollbar nem usar escala global. Alteração localizada em apresentação: espaçamento do body da tela inicial 8, título 30 em vez de 38, cards dessa tela com padding 8 e separação interna 4, badge de preview 28 e desafios com altura mínima 84 em vez de 104. Inputs e botões funcionais mantêm targets de 44; texto inferior permanece visível. Outras telas restauram separação normal ao navegar.

Sidebar mantém título fixo integral. Gaps da navegação reduzidos a 4; itens futuros desabilitados usam altura 32/padding 4, enquanto ações funcionais permanecem 44. Não houve remoção de ScrollContainer, posicionamento absoluto, escala global, redesign ou alteração de domínio/Match Engine/RNG/persistência/schema/gameplay.

Smoke mede a altura mínima real do conteúdo, incluindo margens, e falha se exceder a área disponível em 1100×780. Resultado observado com **preview ativo + nova carreira**: **675 px de conteúdo / 694 px disponíveis**, sem scroll vertical; sidebar completa, incluindo logo e todos os itens. Captura `TEMP/club-legacy-phase51-visual/05b-active-preview.png` aberta e inspecionada, mostrando título, introdução, continuar, nome, três perfis, iniciar e texto inferior integralmente.

Captura adicional `05c-start-narrow.png`, em **860×650**, foi aberta e inspecionada: layout íntegro, logo completo, scroll preservado para alcançar conteúdo longo. Perfis passam a uma coluna pela regra responsiva existente; não houve redução extrema de fonte para caber nessa resolução. Smoke agora produz 20 PNGs e retorna exit 0, stderr vazio. Logs `club-legacy-density-visual.{stdout,stderr}.txt` em TEMP.

Revalidação solicitada, após as alterações: import headless exit 0/stderr vazio; suíte completa **533 PASS / 0 FAIL**, exit 0/stderr vazio; failure probe **533 PASS / 1 falha intencional**, exit 1, somente `FAIL: Intentional runner failure probe` em stderr; startup exit 0/stderr vazio. Logs `club-legacy-density-{import,normal,failure,startup}.{stdout,stderr}.txt` em TEMP. Todos os testes existentes preservados; nenhuma regra modificada. O smoke acrescenta uma verificação de overflow por tamanho de conteúdo, sem comparação de pixels.

Git diff --check passou, diff --stat e status --short executados. O diff rastreado acumulado das mudanças ainda não commitadas: oito arquivos, 269 inserções/281 remoções; componentes novos e relatório continuam não rastreados. Avisos LF/CRLF e ignore global sem impedir verificação. Staging preservado; nenhum commit/push. Esta correção tocou apenas app_shell.gd, career_screens.gd, slice_views.gd, visual_smoke.gd e este relatório.

**FASE 5.1 — OWNER VISUAL CHECK FINAL REQUIRED.** A aprovação da direção permanece; o ajuste de densidade aguarda o check final do proprietário. Polish adicional continua futuro e não bloqueia o MVP. Sem commit/push ou Fase 6.

## Aprovação final do proprietário e conferência CASA/FORA

**Owner Visual Check: APPROVED.** O proprietário aprovou a versão atual como fundação do MVP: direção visual aprovada, densidade aprovada e responsividade aprovada para continuidade do desenvolvimento. Nova/continuar deve permanecer sem scroll vertical em 1100×780; telas naturalmente extensas podem manter scroll, preservando legibilidade. Melhorias cosméticas adicionais são polish futuro e não bloqueiam o desenvolvimento.

Conferência somente em leitura: DashboardProjection seleciona fixtures reais cujo home_club_id ou away_club_id corresponde ao clube controlado, separa os pendentes e ordena por rodada. Em `ui/career_screens.gd`, “Próximas partidas” exibe **CASA quando f.home_club_id == club.id; FORA caso contrário**. Como a projeção garante participação do clube, o outro caso corresponde ao away_club_id. O adversário é o away_club_id em casa e o home_club_id fora. A indicação usa IDs dos fixtures, sem nomes, índices, sequência presumida ou valores inventados.

**CASA/FORA está correto.** Nenhuma alteração na UI, calendário ou código foi necessária. Todos os testes existentes preservados; não houve nova execução de testes nesta atualização documental. Evidências executáveis 533/0 e smoke de densidade permanecem registradas acima. Verificações Git finais executadas: diff --check sem erros, diff --stat e status --short; staging preservado, sem commit/push. Não iniciar Fase 6.

**FASE 5.1 — CONCLUÍDA E APROVADA PELO OWNER.**
