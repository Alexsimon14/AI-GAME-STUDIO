# Game 001 — três propostas para decisão do proprietário

Data: **01/10/2026**. Papel: Product Manager.

Base exclusiva: [pesquisa de oportunidades de outubro/2026](../../reports/market/2026-10-first-game-opportunities.md), especialmente os espaços A, B e C, seus concorrentes e reclamações. As mecânicas, nomes de trabalho, públicos, recortes de conteúdo e estimativas abaixo são **hipóteses de produto**, não descobertas adicionais de mercado. Não foi feita nova pesquisa.

Todas as propostas são para **Android, Godot e GDScript**, com apresentação 2D, experiência individual, núcleo offline e salvamento local. Os nomes são provisórios e não tiveram disponibilidade comercial verificada. Nenhuma proposta foi escolhida. Este documento apresenta conceitos comparáveis; não é um GDD nem autorização para implementação ou monetização.

Foram usados três espaços distintos para oferecer escolhas com experiências diferentes. O espaço D, gestão compacta, permanece uma alternativa da pesquisa; ficou fora deste conjunto por sua complexidade relativa maior de simulação/interface. Isso não elimina a alternativa nem recomenda automaticamente uma das três.

## Proposta 1 — Oficina de Ecos

### Conceito, gênero e público-alvo

**Conceito:** restaurar pequenos objetos sonoros resolvendo puzzles em tabuleiros compactos. Cada tabuleiro contém peças que só podem se mover como um par indicado. O jogador escolhe um par e uma direção; as duas peças deslizam simultaneamente até encontrar obstáculos. A solução posiciona todos os pares nos encaixes correspondentes, revelando um objeto no álbum da oficina. Formas distinguem os pares sem depender apenas de cores; o som é complementar.

**Gênero:** puzzle lógico determinístico com coleção visual.

**Público-alvo:** pessoas que gostam de resolver desafios curtos, sem reflexos ou pressão de tempo, e acompanhar uma coleção. É um perfil comportamental proposto, não um segmento demográfico comprovado. Uso pretendido: intervalos e deslocamentos, com áudio opcional.

**Vínculo com a pesquisa:** espaço A. Nonogram e Flow fundamentam lógica, catálogo e coleção; os relatos de toques involuntários e anúncios em Nonogram motivam comandos grandes, desfazer livre e ausência de interrupções durante o puzzle. A pesquisa não prova demanda pela regra de movimento proposta.

### Experiência e diferenciação

**Core gameplay loop:** escolher um objeto incompleto → observar pares e obstáculos → selecionar um par e executar movimentos → desfazer/testar outra sequência → completar encaixes → revelar o objeto no álbum → escolher o próximo puzzle ou repetir um anterior com uma meta opcional de movimentos.

**Diferencial:** a decisão central está no movimento simultâneo de duas peças, incluindo situações em que melhorar uma posição prejudica a outra. A coleção dá contexto à resolução; tabuleiros, regras combinadas, arte e níveis devem ser autorais. A originalidade global dessa combinação ainda precisa ser verificada antes de produção; não se presume exclusividade.

**Progressão:** três conjuntos de objetos com dificuldade gradual. Cada nível concluído libera o seguinte e acrescenta uma parte da coleção; repetir com menos movimentos concede uma marca de domínio, sem bloquear a campanha. Sem energia, perda de sequência diária ou compra de poder. A rejogabilidade inicial é finita; não há promessa de conteúdo infinito.

**Duração média pretendida:** **2–4 minutos por puzzle**, com primeiros níveis menores. É meta de projeto, não média medida. Retomada mantém o tabuleiro atual para sessões interrompidas.

### Cosméticos e monetização possível

**Potencial para skins:** médio. Molduras da oficina, material das peças e temas do tabuleiro; preservar contraste, formas e área de toque. O MVP inclui um tema base e uma variação desbloqueável por jogar para avaliar interesse, sem loja.

**Rewarded ads:** possibilidade de obter uma dica adicional que indique um par relevante, sem entregar automaticamente a solução. Desfazer, reiniciar e resolver ficam gratuitos e offline; incluir algumas dicas por progresso normal. Sem anúncio disponível ou após recusa, o jogo continua. Uma oferta por vez, com recompensa explícita; integração comercial depende de aprovação posterior.

**Season pass futuro:** encaixe condicional em novas coleções temáticas e cosméticos. Exige comprovar interesse no catálogo e capacidade de criar puzzles; fora do MVP, sem conteúdo já liberado retirado do jogador.

### Viabilidade, riscos e MVP

**Complexidade técnica:** baixa a média relativa. Principais desafios: movimentos simultâneos previsíveis, UX de seleção e autoria de níveis solucionáveis com dificuldade adequada. Sem física dinâmica ou geração procedural no MVP.

**Backend:** não é necessário no MVP. Níveis, álbum e progresso locais; sem login ou ranking online. Anúncios/compras futuros exigem rede e integrações Android, mesmo sem servidor próprio. Backup entre dispositivos fica fora do recorte inicial e precisa ser explicado ao usuário.

**Principais riscos:** regra confusa; puzzles triviais ou frustrantes; custo de produzir conteúdo maior que o esperado; fim rápido do catálogo; diferencial percebido apenas na apresentação; skins prejudicando leitura.

**Escopo de MVP proposto:**

- Uma regra de movimento, obstáculos fixos e encaixes; tabuleiros pequenos, com tamanho final ajustado por teste de toque.
- 24 puzzles autorais em três conjuntos, incluindo quatro introdutórios.
- Álbum com seis objetos ilustrados, revelados por grupos de puzzles.
- Desfazer, reiniciar, dica básica, seleção de nível e retomada local.
- Um tema base, uma variação cosmética por conquista e interface em PT-BR.
- Sem editor, UGC, gerador, eventos, loja, passe, nuvem ou SDK de anúncios no recorte de validação.

**Estimativa relativa de esforço:** **1,0×**, referência deste conjunto; depende principalmente do tempo de autoria e teste dos 24 níveis. Inclui arte simples, implementação futura e QA Android. Não é prazo ou orçamento; quantidade de níveis pode precisar cair se a regra exigir muita curadoria.

**Validação e critério de corte:** observar entendimento da ação em pares, erros de toque, conclusão sem dicas, tempo por puzzle e desejo de tentar outro. Reduzir ou abandonar a proposta se a regra continuar incompreensível após simplificação, ou se interesse depender exclusivamente de recompensas do álbum. Os critérios numéricos de um teste futuro ainda deverão ser definidos.

## Proposta 2 — Farol Errante

### Conceito, gênero e público-alvo

**Conceito:** conduzir uma pequena máquina de luz por uma arena escura durante uma tempestade de quatro minutos. Sua emissão de luz acontece automaticamente; ao atravessar um dos poucos pontos de carga, o jogador escolhe a forma da próxima emissão. Ondas circulares protegem áreas próximas, fachos abrem caminhos e pulsos afastam ameaças. Decidir quando buscar carga e por onde passar importa tanto quanto desviar.

**Gênero:** arcade de sobrevivência e pontuação, com rodadas finitas.

**Público-alvo:** jogadores que gostam de desvio, decisões rápidas e repetir uma rodada para melhorar. Uso pretendido: uma partida em uma pausa curta, com controle de uma mão. O interesse específico em survivors de quatro minutos é hipótese, não demanda demonstrada.

**Vínculo com a pesquisa:** espaço B. Os relatos de grind em Magic Survival, consulta difícil de combinações e repetição em Survivor.io motivam poucas escolhas legíveis, duração delimitada e desbloqueios laterais. Não se busca reproduzir catálogo, personagens, armas ou arenas desses jogos.

### Experiência e diferenciação

**Core gameplay loop:** selecionar um emissor disponível → iniciar a tempestade → desviar de ameaças e buscar pontos de carga → escolher uma forma de emissão com efeito explicado → sobreviver até o resgate ou perder → ver pontuação/desafio concluído → desbloquear uma alternativa e tentar outra rota.

**Diferencial:** a carga é obtida em posições visíveis e a escolha altera a próxima emissão, criando decisões de rota e oportunidade em vez de uma árvore extensa de armas. Poucos efeitos com papéis distintos e fim fixo procuram preservar clareza. Essa combinação é proposta autoral; sua capacidade de sustentar repetição ainda não foi testada.

**Progressão:** desafios de sobrevivência, precisão de rota e uso de emissões liberam emissores com vantagens e limitações diferentes, sem upgrades permanentes obrigatórios de dano. Cada rodada começa em condições comparáveis; recordes locais e domínio sustentam retorno. Desbloqueios não exigem assistir anúncios.

**Duração média pretendida:** **3–4 minutos por partida**, com limite de quatro minutos; derrotas antecipadas reduzem a média. Pause e retomada local evitam perder uma rodada ao interromper o aplicativo. O equilíbrio entre preparação, tensão e fim é uma incógnita de validação.

### Cosméticos e monetização possível

**Potencial para skins:** alto em carcaça da máquina, trilha e aparência da arena. Cores/efeitos devem conservar área de dano e leitura das ameaças. MVP com uma aparência base e uma variação conquistável.

**Rewarded ads:** opção pós-partida de ganhar uma pequena quantidade extra de fragmentos usados apenas em cosméticos. Evitar revive no primeiro recorte, para manter tempo e dificuldade claros. Nenhum efeito na força dos emissores ou no recorde; recusa e ausência de rede não alteram recompensas normais. Integração comercial pendente de aprovação.

**Season pass futuro:** possível para cosméticos e desafios adicionais, mas encaixe apenas condicional. Exige variedade e capacidade de entregar conteúdo sem reintroduzir grind; não entra no MVP nem serve de justificativa para tornar a progressão longa.

### Viabilidade, riscos e MVP

**Complexidade técnica:** média. Movimento, emissões, colisões, spawn e balanceamento; muitas entidades e efeitos podem prejudicar desempenho Android. Prever uma quantidade pequena e controlada de ameaças, sem assumir resultado de performance antes de testes.

**Backend:** não necessário. Rodadas, desbloqueios e recordes locais; sem contas, PvP, rankings globais ou eventos sincronizados. SDK de anúncios seria dependência de rede opcional no futuro.

**Principais riscos:** parecer um survivor genérico com tema novo; quatro minutos insuficientes para variedade; pontos de carga gerarem camping ou rotas obrigatórias; controles desconfortáveis; otimização custosa; poucas opções não sustentarem retorno.

**Escopo de MVP proposto:**

- Uma arena 2D, um personagem controlável e três padrões de ameaça.
- Três formas de emissão, dois emissores laterais desbloqueáveis e pontos de carga fixos.
- Uma rodada de quatro minutos, sem chefes, narrativa longa ou campanha.
- Seis desafios de domínio, recordes locais e descrição de efeitos no pause.
- Tutorial breve, retomada local, uma skin conquistável e interface em PT-BR.
- Sem multiplayer, dezenas de armas, equipamentos, loot aleatório, clãs, loja, passe ou SDK publicitário no recorte de validação.

**Estimativa relativa de esforço:** **1,5–2,0×** a referência da proposta 1, sobretudo por balanceamento em tempo real, UX de controle e otimização/QA em aparelhos. Intervalo de julgamento do Product Manager, não medição. Reduzir efeitos e variedade pode reduzir esforço; não elimina o risco de performance.

**Validação e critério de corte:** medir compreensão dos efeitos, duração real, rotas utilizadas, repetição voluntária e desempenho em aparelhos representativos. Reduzir ou abandonar se houver uma única rota eficaz, se as escolhas forem pouco relevantes ou se a diversão exigir muito mais armas/inimigos que o recorte suporta.

## Proposta 3 — Jardim de Miudezas

### Conceito, gênero e público-alvo

**Conceito:** cuidar de um pequeno jardim de criaturas de papel. Três canteiros produzem sementes; a cada visita, o jogador escolhe como distribuir uma colheita limitada entre descobrir uma criatura, mudar seu abrigo ou ornamentar o jardim. Uma criatura nova permanece na coleção e pode ocupar um dos abrigos, mudando a composição visual do cenário. Não há morte, fome punitiva ou perda por ausência.

**Gênero:** coleção cozy com gestão idle leve.

**Público-alvo:** pessoas que preferem escolhas tranquilas, personalização e colecionar, com visitas curtas e sem cobrança diária. Perfil hipotético apoiado nos sinais qualitativos da pesquisa; não há validação de idade, tamanho do segmento ou disposição a pagar.

**Vínculo com a pesquisa:** espaço C. Cats&Soup fundamenta coleção/decoração e mostra elogios à ausência de punição, além de relatos divergentes sobre anúncios. Pocket Frogs sinaliza risco de mudar acesso a colecionáveis. A proposta preserva formas normais de obter conteúdo e limita o volume de arte inicial.

### Experiência e diferenciação

**Core gameplay loop:** abrir o jardim → recolher sementes produzidas até um limite → escolher entre descoberta e decoração → posicionar uma criatura ou ornamento em espaços definidos → registrar a coleção → encerrar e voltar quando desejar. Deve existir ao menos uma escolha útil na visita, sem exigir longas sequências de cliques.

**Diferencial:** coleção finita de criaturas com composição visual feita pelo jogador, priorizando escolhas de alocação e um cenário pequeno. Descobertas seguem uma trilha visível e determinística, evitando depender de sorte para completar o álbum. A proposta busca apego e transformação; seu diferencial não pode se resumir a trocar gatos ou sapos por outra espécie.

**Progressão:** uma moeda, pequenas melhorias de canteiros e uma trilha de oito criaturas. Todas obtidas por jogar; decorações ampliam expressão sem acelerar a economia. Produção offline tem limite de armazenamento, sem perda de criaturas ou tarefas vencidas; o limite é uma hipótese para balancear, não um convite a notificações constantes. Após completar a coleção, reorganização e pequenas metas decorativas oferecem retorno limitado.

**Duração média pretendida:** **1–3 minutos por visita**. Não há partida competitiva com fim definido; a unidade comparável é a visita ao jardim. Tempo até completar a coleção permanece indefinido até testar a economia.

### Cosméticos e monetização possível

**Potencial para skins:** alto em padrões das criaturas, abrigos e elementos de cenário. A identidade deve sobreviver a pouca animação. MVP com decorações conquistáveis; sem venda ou espécies exclusivas pagas.

**Rewarded ads:** possibilidade de um bônus limitado de sementes na colheita, com ritmo base suficiente para descobrir todas as criaturas. O bônus não pode ser necessário para cumprir prazos, pois não haverá eventos cronometrados no MVP. Recusa ou indisponibilidade da rede preserva toda a colheita normal. Depende de aprovação e validação futura do equilíbrio.

**Season pass futuro:** maior encaixe temático entre estas propostas, por coleções de decoração e padrões. Ainda assim, exige capacidade de produzir arte, interesse em voltar e avaliação da pressão criada por recompensas temporárias. Fora do MVP; não retirar caminhos gratuitos existentes nem converter coleção base em conteúdo pago.

### Viabilidade, riscos e MVP

**Complexidade técnica:** média. Inventário pequeno, cálculo de produção, save/retomada e posicionamento em espaços fixos; custo relevante de ilustração e animação. Relógio alterado e progresso inconsistente exigem tratamento futuro, sem tentar garantir uma economia competitiva inexistente.

**Backend:** não necessário. Jardim, tempo de produção e inventário locais; sem comércio, visitas de amigos, mensagens ou contas. Nenhuma garantia de sincronização entre dispositivos no MVP. Compras futuras demandariam restauração e entrega confiável, tratadas numa etapa aprovada.

**Principais riscos:** visita virar apenas coleta automática; espera substituir decisões; oito criaturas não gerarem apego; custo artístico superar a capacidade; retorno cair após completar o álbum; bônus publicitário tornar o ritmo normal insatisfatório; alterações de relógio e save corrompido.

**Escopo de MVP proposto:**

- Um jardim 2D, três canteiros, quatro espaços de abrigo e uma moeda.
- Oito criaturas autorais, seis decorações e três patamares simples de produção.
- Trilhas de descoberta determinísticas e poucas animações reutilizáveis.
- Produção offline limitada, salvamento local, tutorial e interface em PT-BR.
- Sem merge, livre construção, sistemas de fome, raridades aleatórias, histórias extensas, amigos, nuvem, eventos, loja, passe ou SDK de anúncios no recorte de validação.

**Estimativa relativa de esforço:** **1,4–2,0×** a referência da proposta 1. A amplitude depende principalmente de arte/animação e ajuste do ritmo; interface, inventário e QA de tempo/save também pesam. Não equivale a prazo; se a equipe não tiver produção artística disponível, a comparação pode mudar significativamente.

**Validação e critério de corte:** observar se as pessoas fazem escolhas distintas, desejam uma criatura específica e retornam por interesse no jardim. Medir duração das visitas e tempo até uma aquisição útil. Reduzir ou abandonar se não houver decisão relevante sem muita arte extra, se o loop depender de tarefas compulsórias ou se o ritmo só parecer aceitável com bônus de anúncio.

## Comparação para apoiar a escolha

As estimativas incluem apenas os recortes de validação descritos, sem integrações comerciais. Não há dados de receita, retenção, conversão ou custo de aquisição para prever retorno financeiro. Todos os tempos são metas a verificar; públicos e diferenciais permanecem hipóteses.

| Aspecto | Oficina de Ecos | Farol Errante | Jardim de Miudezas |
|---|---|---|---|
| Experiência central | Raciocínio e descoberta | Desvio e decisões de rota | Coleção e composição visual |
| Unidade de sessão | Puzzle de 2–4 min | Rodada de 3–4 min, máximo 4 | Visita de 1–3 min |
| Retorno pretendido | Resolver e melhorar solução | Dominar e variar escolhas | Descobrir e decorar |
| Custo dominante | Autoria/validação de níveis | Balanceamento e performance | Arte e ritmo da economia |
| Complexidade relativa | Baixa a média | Média | Média |
| Esforço relativo | 1,0×, referência | 1,5–2,0× | 1,4–2,0× |
| Potencial cosmético | Médio | Alto | Alto |
| Rewarded hipotético | Dica extra | Bônus cosmético pós-rodada | Bônus limitado de colheita |
| Passe futuro | Condicional ao catálogo | Condicional à variedade | Condicional à cadência artística |
| Backend próprio no MVP | Não | Não | Não |
| Maior incerteza | Qualidade e interesse na regra | Variedade dentro de quatro minutos | Apego e decisões com pouca arte |

## Estado da decisão

As três propostas estão disponíveis para avaliação do proprietário, sem ranking ou seleção automática. Escopos são limites candidatos, não compromissos de produção. Monetização, nomes comerciais e extensões futuras seguem pendentes de aprovação e validação.

**Encerramento desta tarefa:** documento de conceitos criado. Nenhum GDD, arquitetura, código, protótipo, credencial ou publicação foi produzido. A decisão do usuário precede qualquer avanço para a próxima etapa.
