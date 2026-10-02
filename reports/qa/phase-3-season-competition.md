# Club Legacy — Fase 3: temporada, calendário e classificação

**01/10/2026 · Game Developer · CONCLUÍDA em Godot/headless Windows**

Autorização restrita à Fase 3. Lidos AGENTS.md, agents/game-developer.md, skills/godot-development/SKILL.md, GDD, arquitetura, plano e relatórios das Fases 0/1/2. Plano atualizado antes da implementação. Nenhuma Fase 4, instalação, alteração de staging, commit ou push.

## Implementação

Season e Fixture são RefCounted. Season mantém participantes congelados por divisão, ordem de desempate publicada, rodada atual, estados das rodadas e operações confirmadas. Fixture mantém IDs, divisão, rodada, mandante/visitante e resultado. IDs são alocados pelo contador persistente da Career, sem nomes, índices de arrays ou instance_id. O domínio continua sem FileAccess, UI ou SceneTree.

SeasonService cria a primeira temporada a partir do mundo válido. Cada divisão tem seis clubes, turno e returno, dez rodadas e três jogos por rodada: 30 jogos por divisão e 60 no mundo. Cada clube disputa dez jogos, cinco em casa e cinco fora; cada par joga uma vez em cada mando. A criação repetida é rejeitada. Mesmos mundo/configuração/seed produzem calendário e ordem de desempate idênticos na engine testada. A ordem final usa sorteio próprio reproduzível e fica preservada no estado; consultar tabela não consome RNG.

`submit_result` recebe fixture_id, gols e chave de operação. Os resultados são **entradas externas**, usadas pelo harness; não há simulação, sorteio de placar ou motor temporário. A entrada exige inteiros não negativos, até 1.000 gols por lado como limite de integridade, não parâmetro de balanceamento. Fixture desconhecida, rodada futura, resultado já confirmado com outra chave e chave reutilizada com dados diferentes são rejeitados. Repetir a mesma chave com o mesmo conteúdo retorna sucesso idempotente, sem alterar tabela ou resultado.

Rodadas têm estados READY, RESOLVING e COMMITTED. Confirmar um resultado coloca a rodada em resolução; somente os seis jogos concluídos permitem commit e avanço. A décima rodada confirmada deixa a temporada aguardando encerramento; `finish` exige todas as rodadas confirmadas. Commit e encerramento também têm chaves idempotentes persistentes. Fixture admite PENDING, ACTIVE e COMPLETED; a submissão externa conclui sua mudança na mesma chamada, sem introduzir partida ativa jogável.

TableCalculator deriva classificação exclusivamente dos fixtures concluídos: jogos, vitórias, empates, derrotas, gols pró/contra, saldo e pontos (3/1/0). Não há tabela canônica duplicada. Ordenação: pontos → saldo → gols marcados → vitórias → ordem sorteada antes da temporada. Nome e posição visual não decidem empate.

Após encerramento, `outcomes` identifica campeões, primeiro da segunda divisão para acesso e último da primeira para rebaixamento. **Não muda divisão ou participantes**, não gera outra temporada, não paga prêmio e não processa idade, contratos, empregos ou evolução anual. Esses sistemas permanecem fora desta fase.

SeasonValidator verifica referências e IDs, namespace/contador, seis membros por divisão, permutação de desempate, 60 fixtures, pares e mandos, cobertura das rodadas, resultados e relação entre estados e operações. Também rejeita resultados em rodadas futuras e operações órfãs/inconsistentes. Um mundo anterior ainda pode existir sem temporada e sem fixtures; isso preserva criação inicial e testes anteriores.

## Persistência e migração

CompetitionCodec possui campos explícitos para Season e Fixture. WorldCodec incorpora temporada, fixtures, estados de rodada e descritores de operações. Inteiros persistentes seguem a representação decimal canônica usada na Fase 2. A tabela é recalculada após load, sem salvar uma segunda autoridade de classificação.

Envelope atual: **schema_version 2**, save_version `phase-3-v1`. Checksum continua cobrindo envelope/payload, exceto o próprio checksum. A/B, temporário, validação, fallback e proteção contra versões futuras permanecem no repositório existente.

Migração real de schema 1: validar envelope/checksum original → reconstruir e validar mundo antigo → criar temporada inicial sem resultados → emitir payload schema 2 e novo checksum. Identidades, relações, atributos, emprego, seed e configuração efetiva anteriores são preservados. São alocados 61 IDs novos (Season e 60 Fixtures), avançando o contador; nenhum ID antigo é recriado. Revision é preservada durante load. A migração não grava automaticamente nem altera o arquivo antigo; save posterior grava a próxima revisão no snapshot inativo, mantendo o anterior.

O teste usa um envelope com o formato efetivo da Fase 2, schema 1/save_version phase-2-v1, checksum válido e payload sem os campos novos. Não é uma migração fictícia de uma versão inexistente. Mundo legado inválido é rejeitado; versão futura continua rejeitada. Não são inventados jogos ou progresso para uma carreira antiga.

Comandos de domínio alteram memória; o chamador deve solicitar save. Nenhuma integração automática de GameSession ou UI foi criada. O snapshot inclui resultado e chave juntos, permitindo replay seguro depois de carregar; não há garantia nova de transação entre processos ou durabilidade contra falha física.

## Arquivos

Criados em `games/club-legacy/`:

- `scripts/domain/models/season.gd` e `fixture.gd`;
- `scripts/domain/services/season_service.gd`, `season_validator.gd` e `table_calculator.gd`;
- `scripts/persistence/competition_codec.gd`;
- `tests/integration/season_tests.gd`;
- metadados `.gd.uid` gerados pelo Godot.

Modificados: WorldState, WorldCodec, SaveEnvelope e runner, além do plano e README. Criado este relatório. Não foram removidos testes anteriores nem ampliados Main, GameSession ou WorldFactory com gameplay.

## Execução real

Executável: `C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`. Versão retornada: **4.7.2.stable.official.ed1daf0bf**, hash ed1daf0bf. Execução final fora do sandbox com aprovação, aguardada por Start-Process -Wait -PassThru -WindowStyle Hidden, com stdout/stderr redirecionados para TEMP.

| Verificação | Argumentos | Exit real | Resultado |
|---|---|---:|---|
| Versão | `--version` | 0 | Versão acima |
| Importação | `--headless --path games/club-legacy --editor --quit` | 0 | Sem erro de parsing; stderr vazio |
| Suíte | `--headless --path games/club-legacy --script res://tests/run_tests.gd --quit-after 1000` | 0 | 322 aprovados / 0 falhas; stderr vazio |
| Probe | runner com `-- --force-failure` | 1 | 322 aprovados / 1 falha intencional |
| Inicialização | `--headless --path games/club-legacy --quit-after 2` | 0 | Inicialização sem erro; stderr vazio |

O limite de segurança da suíte não determinou seu exit: o runner encerrou normalmente com sucesso. Probe registrou somente `FAIL: Intentional runner failure probe` em stderr. Logs em TEMP: `club-legacy-phase3-{version,import,normal,failure,startup}.{stdout,stderr}.txt`; não são dependências versionadas.

```text
Phase 0: 14 passed, 0 failed
Phase 0 + Phase 1: 88 passed, 0 failed
Phase 0 + Phase 1 + Phase 2: 136 passed, 0 failed
Phase 0 + Phase 1 + Phase 2 + Phase 3: 322 passed, 0 failed
```

**186 verificações novas**, preservando as 136 anteriores. Cobertura: calendário completo/mando/pares/rodadas, reprodução, validação de corrupção e referências, rejeição de entradas inválidas, estatísticas de vitória/derrota/empate, cada desempate, resultado imutável, chaves conflitantes e replay idempotente, avanço bloqueado/incompleto, dez rodadas e encerramento, campeões/acesso/rebaixamento sem troca de divisão.

Save/load comparou payloads e continuidade no início, rodada parcial, primeira rodada confirmada, múltiplas rodadas, penúltima rodada, todos os jogos antes do último commit e temporada encerrada. Testada migração em memória e pelo repositório, arquivo original intacto, save convertido com revisão seguinte, estado antigo preservado e calendário novo inteiramente pendente. Diretórios de teste são exclusivos em user:// e seus arquivos conhecidos são removidos pelo harness; suíte normal e probe confirmaram limpeza.

## Falha encontrada e corrigida

Primeira execução encontrou rejeição indevida de schema 2 após parse JSON: o parser retorna número como float e a verificação de pertencimento à lista não o reconhecia como o inteiro esperado. Corrigida comparação numérica explícita após checagem de tipo. A falha também causou acesso downstream a mundo nulo no checkpoint; esse resultado inicial não foi considerado validação. Reexecutada a suíte completa: 322/0, stderr vazio. Nenhum teste foi removido para obter sucesso.

## Limites e encerramento

Validação somente headless Windows. Nenhum Android, teste visual, instalação, partida simulada, Match Engine, tática, finanças, mercado, prêmio, dinâmica de carreira ou transição anual. Placares controlados dos testes não demonstram realismo esportivo ou balanceamento.

Verificações Git finais: diff --check, diff --stat e status --short, com safe.directory restrito ao repositório. Novos arquivos não rastreados não entram em diff --stat. Nenhum add/reset/restore/commit/push foi executado.

**Fase 3 concluída nos critérios headless. Parar aqui; Fase 4 não iniciada.**
