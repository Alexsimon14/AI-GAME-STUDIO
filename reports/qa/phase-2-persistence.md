# Club Legacy — Fase 2: persistência e integridade

**01/10/2026 · Game Developer · CONCLUÍDA em Godot/headless Windows**

Autorização restrita à Fase 2. Lidos AGENTS.md, papel Game Developer, skill godot-development, GDD, arquitetura, plano e relatórios das Fases 0/1. Nenhum gameplay/Fase 3, instalação, commit, push ou alteração de staging.

## Componentes e campos preservados

Criados em `games/club-legacy/`: `scripts/persistence/world_codec.gd`, `save_envelope.gd`, `save_repository.gd`, `tests/integration/persistence_tests.gd` e respectivos metadados `.gd.uid` gerados pelo Godot. Modificado `tests/run_tests.gd`, acrescentando a suíte após as Fases 0/1 sem remover verificações. Plano recebeu registro da execução autorizada e README referência ao resultado. Criado este relatório.

Domínio permanece sem FileAccess/UI/SceneTree. Codec e repositório são RefCounted; GameSession não precisou expansão. Codec usa esquemas explícitos de campos para Career, Manager, Club, Player, Contract, League e WorldState, reconstruindo cada modelo sem WorldFactory e sem criar IDs. Relações/counters/namespace/seed/condição/contratos/emprego/configuração efetiva e demais escalares são preservados.

Inteiros de domínio, seed, contador e revision são strings decimais canônicas, convertidas com verificação de round-trip para int64. Testado seed `9223372036854775807` sem perda. Não há estado RNG ativo no mundo da Fase 1; persistimos sua seed. Configuração efetiva é copiada explicitamente para JSON: ranges Vector2i tornam-se pares de strings, PackedStringArray torna-se array, mapas/escalares tornam-se primitivas. Na reconstrução, todos os campos necessários são obrigatórios e validados; não carregar world_config.tres para recriar atributos. Alterar reputação na configuração atual não altera estado carregado.

Nenhum objeto executável, caminho de script, referência de memória ou instance_id é persistido. Projeção estrutural por reflexão existe somente no teste comparativo preexistente; o codec de produção possui lista explícita de campos. Ainda não há estado de calendário, partida ou ledger.

## Envelope, schema e integridade

`schema_version = 1`, independente da versão da engine. Envelope:

- schema_version numérico, save_version `phase-2-v1`;
- engine_version informativa `4.7.2.stable.official.ed1daf0bf`;
- revision como string decimal positiva;
- checksum SHA-256;
- payload com selected_profile, career/config_snapshot, manager e arrays de clubs/players/contracts/leagues.

Timestamp deliberadamente omitido: revision ordena commits; nenhuma identidade/determinismo depende de hora. SHA-256 cobre **todos os campos do envelope, exceto checksum**, inclusive revision e metadados, por JSON compacto com chaves ordenadas e normalizado mediante parse/stringify. Normalização evita diferenças entre schema inteiro original e float retornado pelo parser Godot. Inteiros grandes permanecem strings. Checksum detecta alteração acidental; não autentica autor, não impede edição/rechecksum por usuário e não é DRM.

Load rejeita JSON inválido/truncado, campos ausentes, versão incompatível, checksum incorreto, tipos inválidos, ID duplicado, contador incoerente, namespace estranho, referência/contrato quebrado e contagens/cobertura inválidas. Aplica WorldState.validation_errors após reconstrução, mais validação específica de ID/config/schema. História nesta versão é a história inicial vazia; versões futuras com história preenchida exigirão evolução explícita do codec/schema. Configs iniciais atuais são TEST / PLACEHOLDER; persistência não cria balanceamento final.

Migration foundation: ponto de entrada `migrate`, aceita apenas schema 1. Versão antiga/futura/desconhecida é rejeitada com erro de migração indisponível. Não inventamos migrations de schemas inexistentes. Migrações reais futuras precisam validação, testes e preservação do snapshot anterior.

## Repositório A/B e gravação

Um save lógico em `user://club_legacy_save`, com `a.json`, `b.json` e `snapshot.tmp`; nenhum save em res://. Repository aceita pasta user:// dedicada, rejeita res:// e travessia `..`. Testes usam somente `user://phase2_tests_<identificador>` separado dos saves normais. FileAccess de produção fica na persistência; testes usam um helper restrito à pasta própria para provocar corrupção.

Fluxo: validar WorldState → encode/envelope → validar decode em memória → escrever temporário UTF-8 → flush/close → reabrir/validar → remover apenas alvo inativo, se necessário → rename no mesmo diretório → reabrir/validar snapshot promovido → retornar sucesso e revision. Única cópia válida atual nunca é o alvo de substituição. Erro não publica WorldState candidato no domínio. Sem integração automática ao boot ou criação silenciosa de carreira.

Save inicial: A revision 1; seguinte: B revision 2; seguinte: A revision 3. Revision = maior revision válida + 1; falhas antes de promoção não incrementam revisão confirmada. Após corrupção, revisão do arquivo inválido não é confiável e não é usada para ordenar. Carreiras diferentes/two slots com revisions iguais são recusadas explicitamente. Revision int64 esgotada é erro. Pressupõe um escritor por carreira; não há lock entre processos nesta fase.

Load analisa snapshots A/B, valida ambos e seleciona maior revision válida. Save de versão futura/incompatível nunca é sobrescrito, mesmo quando há fallback válido. Arquivo temporário órfão não é commit e é ignorado; próxima tentativa o substitui, abort o limpa. Snapshot mais novo corrompido leva ao anterior com `recovered`/diagnostics, nunca a carreira nova. Ambos inválidos geram erro; save também recusa sobrescrevê-los. Se diretório não tem arquivos, retorna erro “No snapshots”, sem gerar mundo. Arquivos maiores que 8 MiB são recusados nesta fundação; aumento futuro depende de medição.

Failure seam `failure_stage` permite falhar após temp validado, antes da promoção e depois de remover alvo inativo. Em todos os casos de teste, último snapshot válido continua carregável e temporário é removido. Não simulamos disco fisicamente cheio, falta de energia ou corrupção de filesystem. Flush/rename não garantem durabilidade absoluta contra desligamento: atomicidade lógica e recuperação por snapshot foram testadas, não fsync/power-loss. Primeiro save falho pode não ter nenhum snapshot anterior, retornando erro sem inventar continuidade.

## Execução real e resultados

Engine: `C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`, versão real **4.7.2.stable.official.ed1daf0bf**, hash **ed1daf0bf**. Execuções finais fora do sandbox com aprovação, processo aguardado e stdout/stderr capturados em TEMP.

| Execução final | Argumentos | Exit real | Resultado |
|---|---|---:|---|
| Engine | `--version` | 0 | Versão acima; stderr vazio |
| Import | `--headless --path games/club-legacy --editor --quit` | 0 | Import/autoload/editor completos, sem parsing error; stderr vazio |
| Suíte | `--headless --path games/club-legacy --script res://tests/run_tests.gd` | 0 | 136 PASS / 0 FAIL; stderr vazio |
| Probe | mesmos argumentos + `-- --force-failure` | 1 | 136 PASS / 1 falha intencional; stderr `FAIL: Intentional runner failure probe` |
| Inicialização | `--headless --path games/club-legacy --quit-after 2` | 0 | Projeto inicia; stderr vazio |

Forma de execução:

```powershell
$enginePath = 'C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe'
$outPath = Join-Path $env:TEMP 'club-legacy-phase2-normal.stdout.txt'
$errPath = Join-Path $env:TEMP 'club-legacy-phase2-normal.stderr.txt'
$process = Start-Process -FilePath $enginePath -ArgumentList @('--headless','--path','games/club-legacy','--script','res://tests/run_tests.gd') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $outPath -RedirectStandardError $errPath
$process.ExitCode
Get-Content -LiteralPath $outPath
Get-Content -LiteralPath $errPath
```

Logs: `club-legacy-phase2-{version,import,normal,failure,startup}.{stdout,stderr}.txt` em TEMP. Resumos finais:

```text
Phase 0: 14 passed, 0 failed
Phase 0 + Phase 1: 88 passed, 0 failed
Phase 0 + Phase 1 + Phase 2: 136 passed, 0 failed
```

**48 verificações da Fase 2**, mais 88 anteriores preservadas. Round-trip compara todos os campos persistentes estruturalmente, não apenas contagens; original em memória é liberado antes de reconstrução. Testes incluem JSON/UTF-8 real, IDs/counter/namespace/seed, emprego/config independente, revisions 1/2/3, maior válida, corrupção/fallback, ambos corrompidos, checksum de payload/revision, campos ausentes, schema futuro, payload rechecksummed inválido por referência/ID/tipo/contagem/contrato/counter/config, repositório vazio, temporário órfão, três seams de falha e limpeza. Diretório exclusivo foi removido em execução normal e probe; nenhuma pasta phase2_tests_* residual foi encontrada no diretório usual inspecionado.

## Falhas encontradas e corrigidas

Primeiro harness encontrou parsing errors no teste de independência da configuração: atribuição via constante preloaded foi considerada atribuição a constante. Corrigido somente o teste, usando referência Resource local/set e restaurando valor original. Processo inicial precisou timeout, pois falha de script impediu o encerramento normal; não usamos esse exit como validação. Nenhum teste removido.

Em seguida, round-trip de envelope falhou com `Checksum mismatch`: JSON parser representa schema numérico como float. Corrigida canonicalização do hash com normalização JSON em ambas as pontas. Guard no teste registra erro e evita acessar mundo null. Reexecutada suíte inteira: 133 PASS / 0 FAIL; acrescentado teste de falha após remover alvo inativo, total final 136 PASS / 0 FAIL. Nenhuma falha real restante; probe intencional confirma código não zero.

## Limites e encerramento

Git final executado com `git -c safe.directory=C:/Users/alexs/Desktop/projetos/PARTICULAR/ai-game-studio-codex diff --check`, `diff --stat` e `status --short`. Diff check passou (exit 0), apenas avisos LF/CRLF. Diff stat: README e runner, dois arquivos, seis inserções e uma remoção; arquivos novos não rastreados não entram nessa contagem. Status: README/runner modificados; persistence/, tests/integration/ e este relatório não rastreados. Nenhum comando add/reset/restore/commit/push foi executado. Aviso de acesso ao ignore global não impediu a leitura. Registro de execução da Fase 2 no plano já aparece no estado atual do arquivo, sem diff de trabalho ao finalizar.

Sem UI de save, GameSession ampliado, múltiplos saves visíveis, nuvem/backend/SDK/Android ou monetização. Não implementado calendário/Fase 3. Persistência cobre somente WorldState atual e schema inicial. Regras novas deverão atualizar codec/validação/schema, com migração real quando necessária. Sem prometer recuperação perfeita de hardware danificado ou determinismo entre engines futuras.

Fase 2 concluída nos critérios headless; parar após esta entrega. Nenhum commit/push/staging alterado pelo agente.
