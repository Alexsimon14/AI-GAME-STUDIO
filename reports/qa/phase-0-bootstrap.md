# Club Legacy — Fase 0: bootstrap e harness

**01/10/2026 · Game Developer · implementação restrita à Fase 0**

Base: AGENTS.md, agents/game-developer.md, skills/godot-development/SKILL.md, GDD, arquitetura e plano aprovados. Nenhuma funcionalidade da Fase 1 foi implementada.

## Resultado e limitações

**Atualização após disponibilização da engine: Fase 0 validada em Godot/headless.** Godot retornou `4.7.2.stable.official.ed1daf0bf`; importação e inicialização concluíram com exit 0, runner normal com 14 aprovados/0 reprovados e exit 0, probe com 14 aprovados/1 falha intencional e exit 1. Nenhum erro de parsing encontrado; nenhuma correção de código necessária. Android permanece pendente e fora desta validação. O relato de indisponibilidade abaixo descreve a tentativa inicial, superada pela validação ao final deste relatório.

Fundação criada, mas **validação executável pendente**: Godot não foi encontrado no PATH nem nas localizações pesquisadas. Nenhuma versão exata foi selecionada; o projeto declara compatibilidade com Godot 4.x e renderer Compatibility. Não houve instalação de engine/dependências, abertura gráfica, import real, execução do runner ou export Android. Não afirmar que projeto/testes funcionam antes de executar com engine estável instalada.

Não foram encontrados Java/adb no PATH, variáveis ANDROID_HOME/ANDROID_SDK_ROOT/JAVA_HOME configuradas, SDK no diretório Android usual ou templates na pasta Godot usual. Essa inspeção não exclui instalações em locais personalizados. Android não foi verificado por build/aparelho; ausência não bloqueou criação dos arquivos de bootstrap.

## Arquivos

Criados:

- `games/club-legacy/project.godot`: Main, único Autoload GameSession e Compatibility; viewport provisório, sem orientação de produto definitiva.
- `games/club-legacy/scenes/main.tscn`: Control Main, ScreenHost e DialogLayer; sem gameplay ou interface completa.
- `games/club-legacy/scripts/application/game_session.gd`: inicialização/validação da configuração, sem WorldState ou regras de jogo.
- `games/club-legacy/resources/config/bootstrap_config.gd`: Resource com esquema/identidade/propósito validáveis.
- `games/club-legacy/resources/config/bootstrap_config.tres`: TEST / PLACEHOLDER, somente metadados de bootstrap, sem balanceamento.
- `games/club-legacy/tests/run_tests.gd`: runner SceneTree headless, assertions e exit code 0/1; falha intencional via `--force-failure`.
- `reports/qa/phase-0-bootstrap.md`: este registro.

Modificado: `README.md`, acrescentando abertura, requisitos e comandos de verificação. Não foram criados diretórios com arquivos vazios, dependências externas ou implementação de temporada, clubes/atletas, mercado, economia, partida, save ou monetização.

## Inspeção e comandos executados

PowerShell, a partir da raiz do repositório:

```powershell
Get-Command godot*,java,adb -ErrorAction SilentlyContinue
```

Sem executáveis retornados. Também foram listadas entradas com nome Godot em Downloads, Desktop, Program Files e AppData/Local; templates em AppData/Roaming/Godot/export_templates e SDK em AppData/Local/Android/Sdk: nenhum encontrado.

```powershell
rg --files --hidden 'C:\Users\alexs\Downloads' 'C:\Users\alexs\Desktop' 'C:\Users\alexs\AppData\Local\Programs' 'C:\Users\alexs\scoop' 'C:\Program Files' 'C:\Program Files (x86)' 2>$null | rg -i '(godot.*\.exe$|android.*(adb\.exe|sdkmanager\.bat)$|java\.exe$|android_debug\.apk$)'
godot --headless --path games/club-legacy --script res://tests/run_tests.gd
```

Busca sem matches (código 1); diretórios ausentes/inacessíveis podem ter sido omitidos. Tentativa de runner: código 1 do shell, `CommandNotFoundException` para godot. **Isso não é uma falha de teste nem demonstra o exit code do runner**: a engine não iniciou.

```powershell
git -c safe.directory=C:/Users/alexs/Desktop/projetos/PARTICULAR/ai-game-studio-codex diff --check
git -c safe.directory=C:/Users/alexs/Desktop/projetos/PARTICULAR/ai-game-studio-codex diff --stat
git -c safe.directory=C:/Users/alexs/Desktop/projetos/PARTICULAR/ai-game-studio-codex status --short
rg --files games/club-legacy
```

Diff check sem erros; avisos de conversão LF/CRLF. Diff stat: `README.md | 17 +++++++++++++++++`, um arquivo modificado. Arquivos novos não rastreados não entram em `git diff --stat`; não foram staged para produzir estatística. Status inclui README modificado, projeto/relatório novos e documentos não rastreados de etapas anteriores. Aviso de permissão no ignore global Git não impediu leitura do status. Nenhum commit/push feito.

## Verificações a executar quando a engine estiver disponível

Comandos também no README:

```powershell
godot --headless --path games/club-legacy --editor --quit
godot --headless --path games/club-legacy --script res://tests/run_tests.gd
godot --headless --path games/club-legacy --script res://tests/run_tests.gd -- --force-failure
godot --headless --path games/club-legacy --quit-after 2
```

Esperado: import sem erro; runner aceita configuração TEST e rejeita esquema/ID/propósito inválidos, null e tipo errado; sessão recupera após configuração corrigida; Autoload inicializado e cena com os dois hosts. Caminho normal espera código 0; probe intencional espera 1. Abrir graficamente pelo project manager quando permitido, fixar versão realmente testada e verificar Android somente se toolchain disponível.

**Estado:** arquivos da Fase 0 entregues; execução Godot/headless e smoke Android não validados. A tarefa para aqui, sem avançar para Fase 1.

## Retomada — validação efetivamente executada

Engine executada: `C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`. Versão escolhida/testada: **4.7.2.stable.official.ed1daf0bf**, build/hash **ed1daf0bf**, renderer configurado Compatibility. Confirmação explícita:

```powershell
& 'C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe' --version
```

Retorno: `4.7.2.stable.official.ed1daf0bf`, exit 0.

Primeiro import/runner dentro do sandbox retornaram exit 0, mas stderr apresentou erros de permissão de caches/configurações/log em AppData, acesso a user:// e leitura de certificados. Não eram erros de parsing. Repetimos fora do sandbox, com aprovação, sem instalar componentes. Chamadas diretas ao executável gráfico Windows fora do sandbox exibiram apenas banner; não usamos esses retornos como evidência do runner. Para capturar término, stdout/stderr e código real, a execução final usou `Start-Process -Wait -PassThru -WindowStyle Hidden`, redirecionando logs para TEMP.

Cada invocação final usou o executável acima, da raiz do repositório, com estes argumentos:

| Verificação | Argumentos | Exit real | Resultado / stderr |
|---|---|---|---|
| Import | `--headless --path games/club-legacy --editor --quit` | 0 | Inicialização/escaneamento/autoload/editor concluídos; stderr vazio |
| Runner normal | `--headless --path games/club-legacy --script res://tests/run_tests.gd` | 0 | 14 aprovados, 0 reprovados; stderr vazio |
| Failure probe | `--headless --path games/club-legacy --script res://tests/run_tests.gd -- --force-failure` | 1 | 14 aprovados, 1 falha intencional; stderr: `FAIL: Intentional runner failure probe` |
| Inicialização | `--headless --path games/club-legacy --quit-after 2` | 0 | Main e Autoload iniciados, sem erros; stderr vazio |

Forma efetiva de execução para cada linha (substituir argumentos e nome do check):

```powershell
$enginePath = 'C:\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe'
$outPath = Join-Path $env:TEMP 'club-legacy-phase0-normal.stdout.txt'
$errPath = Join-Path $env:TEMP 'club-legacy-phase0-normal.stderr.txt'
$process = Start-Process -FilePath $enginePath -ArgumentList @('--headless','--path','games/club-legacy','--script','res://tests/run_tests.gd') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $outPath -RedirectStandardError $errPath
$process.ExitCode
Get-Content -LiteralPath $outPath
Get-Content -LiteralPath $errPath
```

Logs finais em TEMP: `club-legacy-phase0-{import,normal,failure,startup}.{stdout,stderr}.txt`. Não são arquivos versionados. Stdout do runner normal:

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
PASS: Default TEST / PLACEHOLDER config accepted
PASS: Invalid schema, empty ID and purpose rejected
PASS: GameSession initializes without SceneTree
PASS: Valid session reports initialized
PASS: Invalid config rejected by session
PASS: Rejected initialization leaves session unavailable
PASS: Missing config rejected
PASS: Wrong resource type rejected
PASS: Session can recover using valid config
PASS: Project creates GameSession autoload
PASS: Autoload accepts default configuration
PASS: Main scene loads as Control
PASS: Main owns ScreenHost
PASS: Main owns DialogLayer
Phase 0: 14 passed, 0 failed
```

O probe repete os 14 PASS e termina com `Phase 0: 14 passed, 1 failed`; a falha intencional vai para stderr e o processo retorna 1. Configuração inválida agrupa schema=99, ID vazio e propósito inválido, verificando exatamente três erros; null/tipo incorreto e recuperação são verificações separadas. Não removemos testes. Main é instanciável como Control, ScreenHost como Control e DialogLayer como CanvasLayer; execução do projeto confirma inicialização da cena. GameSession foi validado tanto sem SceneTree quanto como Autoload inicializado.

**Correções:** nenhuma correção de GDScript/Resources/cenas necessária. README atualizado para retirar a limitação superada e registrar engine testada. Godot gerou caches ignorados em `.godot/` e metadados `.gd.uid`; metadados de script permanecem junto ao projeto. Sem implementação de Fase 1.

**Limitações restantes:** somente validação headless Windows; nenhuma validação visual, export/renderização Android ou aparelho. Android explicitamente fora desta retomada; nenhum SDK/JDK/ADB/template instalado. Resultado não comprova gameplay ou MVP completo.

**Estado atual:** todos os critérios obrigatórios da Fase 0 Godot/headless passaram; Android PENDENTE. Sem commit/push. Fase 1 não iniciada.
