# Club Legacy — Fase 1: modelo do mundo e carreira inicial

**01/10/2026 · Game Developer · CONCLUÍDA em Godot/headless Windows**

Escopo autorizado: somente Fase 1. Lidos AGENTS.md, papel Game Developer, skill godot-development, GDD, arquitetura, plano e relatório da Fase 0. Nenhuma Fase 2 implementada; nenhuma instalação, commit ou push.

## Implementação e decisões

WorldState e os seis modelos Career/Manager/Club/Player/Contract/League são RefCounted, sem UI/SceneTree. WorldFactory cria tudo em memória mediante Resource válido, seed, nome/perfil do treinador e namespace de carreira fornecido pelo chamador. Retorna mundo validado ou erros, sem publicar mundo parcial.

IDs têm namespace de carreira, tipo e contador monotônico pertencente à Career. Não usam nome, índice de array, instance_id ou posição visual; o contador não é reiniciado ao renomear. Namespace deve ser único para carreiras diferentes; IDs não prometem ser globalmente exclusivos se o chamador reutilizar deliberadamente o mesmo namespace. Testes de reprodução usam o mesmo namespace e mesmos dados de entrada. Seed varia nomes/atributos, não a identidade das posições de criação; nenhuma operação de rename recalcula IDs.

Contract é fonte canônica do vínculo. Player guarda somente contract_id; Club não guarda cópia de elenco ou salário. WorldState deriva roster_ids e payroll dos contratos ativos. Manager é referenciado pela Career, com histórico vazio e um contrato employment; identidade não depende do clube. Alteração direta do club_id desse contrato foi testada somente como isolamento de modelo: não existe funcionalidade de troca de emprego.

Configuração e catálogo locais em Resource de geração; carreira guarda cópia profunda dos parâmetros efetivos em memória. Isso não é formato de save, repositório ou migração da Fase 2. Geração não modifica configuração e carreiras não compartilham estado mutável. Recursos simples permanecem locais ao projeto, sem shared/ ou framework externo.

Política inicial reproduzível: primeiro clube compatível na ordem explícita do catálogo; não há sorteio de emprego, vagas, demissão, negociação ou ofertas. Perfis internos: PEQUENO, MEDIO (MÉDIO), ELITE. Reputação inicial 70 para todos os cenários **apenas TEST / PLACEHOLDER**, suficiente para representar início na elite autorizado pelo proprietário. Não há gating de contratação por reputação ou pressão/demissão funcional; não é balanceamento de carreira.

Club contém somente escalares iniciais de caixa, torcida, estádio/capacidade, reputação, treino e expectativa. Nenhum desses campos tem comportamento econômico ou de estrutura nesta fase. Contratos terminam em uma referência de temporada 1/2, sem modelo Season ou processamento de expiração.

## Configuração TEST / PLACEHOLDER

Versão `phase-1-test-v1`; catálogo de 12 nomes de clubes, duas ligas e componentes de nomes fictícios autorais locais. Nomes de atletas podem repetir; identidade é o ID. Nenhuma API/banco esportivo/IA em runtime.

| Perfil | Clubes | Overall | Potencial | Salário por rodada | Caixa | Torcida / capacidade | Reputação / treino |
|---|---:|---|---|---|---:|---|---|
| PEQUENO | 4 | 30–44 | 45–60 | 10–20 | 20.000 | 1.000 / 1.500 | 20 / 0 |
| MÉDIO | 5 | 50–64 | 65–80 | 30–40 | 60.000 | 4.000 / 5.000 | 45 / 1 |
| ELITE | 3 | 70–84 | 85–99 | 50–60 | 120.000 | 10.000 / 12.000 | 70 / 2 |

Idades 18–33, condição inicial 100, duração de atleta 1–2 temporadas; treinador até o fim da primeira temporada, salário pessoal zero. Faixas e demais valores são provisórios em configuração. Não comprovar solvência ou profundidade sem sistemas futuros.

| Distribuição inicial | Quantidade |
|---|---:|
| Clubes | 12 |
| Divisão I | 6: três elite e três médios |
| Divisão II | 6: dois médios e quatro pequenos |
| Atletas por clube | 18 |
| Atletas totais | 216 |
| Goleiros (GK) | 24: dois por clube |
| Defensores (DEF) | 72: seis por clube |
| Meias (MID) | 72: seis por clube |
| Atacantes (ATT) | 48: quatro por clube |
| Contratos ativos | 217: 216 atletas + um emprego |
| Treinadores do usuário | 1 |
| IDs de entidades | 449: Career, Manager, clubes, atletas, contratos e ligas |

Cobertura permite 4–4–2, 4–3–3 e 5–3–2 sem posições individuais adicionais. Validação inicial detecta contagens incorretas, IDs duplicados/vazios e índices inconsistentes, jogador com mais de um vínculo ativo, ausência de contrato, clube/subject inexistente, posições/atributos inválidos, divisão sem seis clubes, cobertura insuficiente e emprego inicial incompatível. Validação é para esse agregado inicial; não é importação de saves arbitrários.

## Arquivos criados/modificados

Criados em `games/club-legacy/`:

- `scripts/domain/models/{career,manager,club,player,contract,league,world_state}.gd`.
- `scripts/domain/services/world_factory.gd`.
- `resources/config/world_config.gd` e `world_config.tres`.
- `tests/unit/world_model_tests.gd`.
- Metadados `.gd.uid` correspondentes gerados pela importação Godot; caches `.godot/` ignorados.

Modificados: `tests/run_tests.gd` para executar os testes novos depois das 14 verificações preservadas da Fase 0; `docs/plans/club-legacy-mvp-plan.md` para registrar execução restrita autorizada; README para apontar o relatório. Criado este relatório. GameSession, Main e configuração bootstrap não precisaram alteração.

## Execução real e comandos

Executável: `C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`. Versão retornada: **4.7.2.stable.official.ed1daf0bf**, hash **ed1daf0bf**. Processo aguardado por Start-Process -Wait -PassThru -WindowStyle Hidden, fora do sandbox com aprovação, pois chamada direta ao executável Windows pode mostrar só banner sem capturar saída final.

Forma utilizada, da raiz do repositório (argumentos substituídos para cada check):

```powershell
$enginePath = 'C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe'
$outPath = Join-Path $env:TEMP 'club-legacy-phase1-normal.stdout.txt'
$errPath = Join-Path $env:TEMP 'club-legacy-phase1-normal.stderr.txt'
$process = Start-Process -FilePath $enginePath -ArgumentList @('--headless','--path','games/club-legacy','--script','res://tests/run_tests.gd') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $outPath -RedirectStandardError $errPath
$process.ExitCode
Get-Content -LiteralPath $outPath
Get-Content -LiteralPath $errPath
```

| Check final | Argumentos | Exit | stdout / stderr |
|---|---|---:|---|
| Versão | `--version` | 0 | `4.7.2.stable.official.ed1daf0bf`; stderr vazio |
| Importação | `--headless --path games/club-legacy --editor --quit` | 0 | Scan/autoload/editor concluídos; stderr vazio, sem erro de parsing |
| Suíte normal | `--headless --path games/club-legacy --script res://tests/run_tests.gd` | 0 | `Phase 0: 14 passed, 0 failed`; `Phase 0 + Phase 1: 88 passed, 0 failed`; stderr vazio |
| Probe | mesmos argumentos + `-- --force-failure` | 1 | `Phase 0 + Phase 1: 88 passed, 1 failed`; stderr `FAIL: Intentional runner failure probe` |
| Inicialização | `--headless --path games/club-legacy --quit-after 2` | 0 | Banner Godot; stderr vazio |

Logs completos capturados em TEMP: `club-legacy-phase1-{version,import,normal,failure,startup}.{stdout,stderr}.txt`. Não são arquivos de jogo nem dependências versionadas.

Primeira execução da suíte: 84 PASS / 0 FAIL. Acrescentadas quatro verificações de corrupção de ID/cobertura, faixa ausente e contador de ID; execução final: **88 PASS / 0 FAIL (14 Fase 0 + 74 Fase 1)**. Nenhuma falha original de código/parsing; nenhuma correção para esconder teste. Probe contém uma falha proposital, não regressão.

Testes cobrem criação/contagens, seis por divisão, 18 por clube, cobertura, unicidade, contratos, três perfis/primeiro emprego, geração idêntica por seed/config/namespace/inputs e variação por seed diferente, configuração não mutada, snapshot independente, rename, isolamento de condição entre mundos, ausência de transferência de caixa/elenco por vínculo gerencial, referências quebradas, contrato duplicado, ID duplicado, falta de goleiros, config inválida/nula/tipo errado/campo ausente, perfil/nome inválidos e ordem de qualidade TEST por perfil.

**Determinismo: PASS.** Duas carreiras com seed 12345, mesma Resource e mesmas entradas foram comparadas estruturalmente em campos de Career/Manager, clubes, jogadores/atributos/IDs, contratos e ligas. Seed 54321 gera variação prevista. Garantia testada na versão Godot acima; não prometer reprodução entre versões de engine sem verificação.

## Limitações e etapas futuras

Verificações Git executadas com `git -c safe.directory=C:/Users/alexs/Desktop/projetos/PARTICULAR/ai-game-studio-codex diff --check`, `diff --stat` e `status --short`. Diff check passou (exit 0), apenas avisos LF/CRLF. Diff stat em relação ao índice: três arquivos, oito inserções e uma remoção — README, plano e runner. Novos arquivos não rastreados não entram nessa contagem. Status mostra arquivos novos da Fase 1 `??`, os três arquivos citados com mudanças de trabalho e arquivos de etapas anteriores já staged pelo estado existente do repositório. Não alteramos staging nem fizemos commit/push. Aviso de acesso ao ignore global não impediu os comandos.

Somente criação em memória por código/harness, sem gameplay ou UI de carreira. Nenhum calendário, rodada, tabela, partida/motor, mercado/transferência, economia funcional, obra, torcida dinâmica, vagas/demissão, save/load, arte, Android ou monetização. Escolher clube em teste não implementa contratação dinâmica.

Balanceamento CL1/J1/E1/C1/C2 continua provisório; o cenário elite está autorizado como início de teste, não prova progressão. Persistência/migração ficam exclusivamente para Fase 2 posterior. Não persistimos counters/snapshots em disco nesta fase. Android não executado e nenhum componente instalado.

**Conclusão:** todos os critérios desta Fase 1 passaram no ambiente headless validado; Fase 0 preservada. Parar aqui, sem iniciar Fase 2.
