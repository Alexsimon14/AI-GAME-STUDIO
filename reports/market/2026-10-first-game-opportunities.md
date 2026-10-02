# Game 001 — oportunidades no mercado Android

Data da pesquisa: **01/10/2026**. Papel: Market Researcher. Skill: `skills/market-research/SKILL.md`. Escopo: pesquisa e shortlist; nenhum conceito final selecionado, GDD produzido ou jogo desenvolvido.

## Síntese para decisão

Há quatro espaços para avaliação humana: **micro-puzzles 2D com coleção**, **arcade de sobrevivência em rodadas curtas**, **coleção cozy com progressão leve** e **puzzle de gestão compacta**. A aderência operacional é maior em puzzles 2D, mas isso é uma avaliação de escopo, não seleção do Game 001 nem previsão de sucesso comercial.

O sinal mais consistente na amostra é a fricção com anúncios e progressão, acompanhada de problemas de legibilidade, controles e excesso de conteúdo/sistemas. Melhorar essas experiências pode ajudar, mas “menos anúncios” sozinho dificilmente sustenta diferenciação. Identidade visual, uma regra própria e um motivo claro para voltar precisam ser validados.

## Método e limites

- Fontes primárias: páginas Android no Google Play, sites de desenvolvedores e análises públicas do fornecedor Sensor Tower. Links junto às afirmações; todas as páginas consultadas em 01/10/2026.
- Amostra qualitativa de avaliações que a loja expôs nas páginas consultadas, em diferentes idiomas/regiões. Não houve extração de todas as avaliações nem amostragem aleatória. Datas e autores permitem localizar os relatos, mas a seleção exibida pela loja muda.
- “Recorrente na amostra” significa pelo menos dois relatos independentes do mesmo tema; não significa prevalência estatística. Relatos antigos não comprovam falhas na versão atual. Respostas de desenvolvedores não são verificação de correções.
- Downloads do Play são faixas acumuladas, não instalações mensais, jogadores ativos, retenção ou lucro. Evitamos notas como critério porque variam por região/dispositivo.
- Dados macro abaixo agregam plataformas mobile; não são uma estimativa exclusiva de Android. Não foram obtidos CPI, eCPM, receita de anúncios, D1/D7 ou margem dos concorrentes. Não há previsão financeira.
- Nenhum aplicativo foi instalado ou testado. Offline é declaração de loja/relato quando indicado, não auditoria técnica. Durações de 1–5 minutos e complexidade em Godot são hipóteses de projeto, não tempos medidos nos concorrentes.

## Mercado atual: evidência e implicação

**Observado:** em 2025, Sensor Tower estima receita IAP de jogos mobile próxima de US$82 bilhões, crescimento de 1,3%, enquanto downloads caíram e tempo de uso cresceu ligeiramente. **Inferência:** disputar atenção e retenção em um mercado maduro exige mais que uma mecânica genérica; isso não obriga um estúdio pequeno a reproduzir live ops de grandes editoras. [State of Mobile 2026, janeiro/2026](https://sensortower.com/blog/state-of-mobile-2026?pubDate=20260122).

**Observado:** no segundo trimestre de 2026, o fornecedor reporta puzzle com crescimento anual de 17% em IAP e 1% em downloads; o avanço foi impulsionado por sucessos de puzzles de setas. **Inferência:** puzzle merece investigação, mas desempenho concentrado em sucessos não demonstra que qualquer novo puzzle terá distribuição barata. [Q2 Digital Market Index, agosto/2026](https://develop.sensortower.com/blog/q2-2026-digital-market-index-report).

**Observado:** Block Blast! e Arrow Puzzle figuraram entre os cinco jogos mobile mais baixados em julho/2026; Brasil representou 6,3% dos downloads globais de jogos naquele mês. **Inferência:** PT-BR é uma localização plausível para testar; volume de downloads brasileiro não estima receita por usuário nem define o mercado inicial. [Ranking de julho, publicado em agosto/2026](https://develop.sensortower.com/blog/top-10-worldwide-mobile-games-by-revenue-and-downloads-in-july-2026).

## Concorrentes Android e sinais dos jogadores

As descrições abaixo resumem fatos de loja e relatos individuais; as implicações comerciais aparecem na shortlist.

| Concorrente / fonte | Oferta observada | Avaliações datadas e limite |
|---|---|---|
| [Nonogram.com — Easybrain](https://play.google.com/store/apps/details?hl=en-US&id=com.easybrain.nonogram) | 50M+; offline, anúncios/IAP; atualização 19/08/2026. Imagens colecionáveis, dificuldades, desafios e eventos. | Andrew Williams (18/03/2025) e Angelina Cardiel (27/09/2025) reclamam de anúncios. Andrew e Megan B (11/02/2025) relatam toques involuntários. Megan também pede zoom e transferência de progresso. Dois temas recorrentes na amostra, sem confirmação na versão atual. |
| [Flow Free — Big Duck Games](https://play.google.com/store/apps/details/Flow_Free?hl=en&id=com.bigduckgames.flow) | 100M+; offline, anúncios/IAP; atualização 16/01/2026. Muitos puzzles e modos livre/cronômetro. | Katharyn Curry (25/09/2025) relata perda de dicas ilimitadas compradas: ocorrência isolada. Alex Holley (09/04/2026) elogia ausência de energia e compra única para remover anúncios; Morgan Underwood (09/12/2024) elogia conteúdo e cores. |
| [Mekorama](https://play.google.com/store/apps/details?hl=en_US&id=com.martinmagni.mekorama) | 10M+; anúncios/IAP; atualização listada 28/12/2023. Dioramas, coleção e editor. | Lluís G. (20/08/2025, [página espanhola](https://play.google.com/store/apps/details?hl=es-419&id=com.martinmagni.mekorama)) relata física imprevisível; Basile Bonduelle (09/10/2021, [francesa](https://play.google.com/store/apps/details?hl=fr&id=com.martinmagni.mekorama)) relata bugs em estruturas do editor. Falhas diferentes, não recorrência da mesma falha. |
| [Vampire Survivors — poncle](https://play.google.com/store/apps/details?id=com.poncle.vampiresurvivors&hl=en) | 5M+; atualização 02/09/2026. Sobrevivência com combinações e desbloqueios. | Peter Tran (29/01/2025) pede filtragem melhor do excesso de armas. Fishman465 (29/10/2025) menciona bugs raros e anúncios opt-in para reviver/ouro. Não sustenta alegação de paywall ou anúncios compulsórios. |
| [Survivor.io — Habby](https://play.google.com/store/apps/details?id=com.dxx.firenow&hl=en) | 50M+; atualização 08/09/2026. Progressão ampla; changelog inclui capítulos 346–350, além de sistemas/eventos. | H Steele (27/12/2024) critica repetição após evolução rápida de armas. Connor Valentine (21/04/2025) elogia progressão sem grind intransponível: contraponto à generalização de barreiras. |
| [Magic Survival — LEME](https://play.google.com/store/apps/details?id=com.vkslrzm.Zombie&hl=en) | 5M+; atualização 26/09/2026. Sobrevivência com classes, avatares e combinações. | Shawn Kua (07/09/2024) e Mryell (02/05/2026, [en-GB](https://play.google.com/store/apps/details?id=com.vkslrzm.Zombie&hl=en_GB)) relatam grind; Tristan (09/06/2025) pede combinações visíveis no pause. Grind é recorrente nesta amostra; não medimos tempo de desbloqueio. |
| [Cats&Soup — NEOWIZ](https://play.google.com/store/apps/details?id=com.hidea.cat&hl=en) | 10M+; offline, anúncios/IAP; atualização 29/09/2026. Produção idle, roupas e decoração. | Mckenzie Cherry (07/09/2026) elogia anúncios opcionais, offline e ausência de punição por não jogar. Jackie E. (29/08/2026) reclama de tamanho das atualizações; Annalese Wilkerson (05/08/2025) relata roupas adquiridas que não aparecem. São sinais individuais de custo técnico e entrega de itens. |
| [Pocket Frogs — NimbleBit](https://play.google.com/store/apps/details?id=com.nimblebit.pocketfrogs&hl=en) | 1M+; coleção e personalização de habitats. | Nicholas Kapetanakis (12/09/2026) reclama que colecionáveis/habitats antes gratuitos passaram a ser pagos. Ocorrência isolada; não prova taxa de abandono nem rejeição geral à monetização. |
| [Merge Mayor — StarBerry Games](https://play.google.com/store/apps/details?id=games.starberry.idlevillage&hl=en_US) | 1M+; anúncios/IAP; atualização 25/09/2026. Combinação, tarefas e restauração de cidade; descrição anuncia sessões de poucos minutos e online/offline. | Dean McCauley (01/08/2026) relata loop de carregamento; desenvolvedor diz ter lançado correção, não testada nesta pesquisa. Nicole Ratliff (22/08/2026) pede chat melhor e acesso a brindes fora do Discord. Ocorrências distintas. |
| [Mini Metro — Dinosaur Polo Club](https://play.google.com/store/apps/details?id=nz.co.codepoint.minimetro) | 1M+; premium, sem anúncios/IAP; offline; atualização 15/06/2026. Crescimento aleatório, modos e desafios. | chereshyna (17/08/2026) elogia profundidade, mas aponta controles delicados; Caleb Honegger (27/06/2024) critica microgerenciamento tardio; Sally Keith (30/08/2022) pede mais conteúdo após terminar cidades. Sinais distintos, não três ocorrências da mesma reclamação. |

## Reclamações transversais e oportunidade possível

1. **Interrupção por anúncios:** recorrência explícita em Nonogram; contrapontos positivos em Flow, Vampire Survivors e Cats&Soup mostram que formato e contexto importam. Hipótese: preservar o fluxo e oferecer recompensa voluntária pode melhorar satisfação; falta validar receita e retorno.
2. **Progresso que vira trabalho:** dois relatos de grind em Magic Survival e um de repetição em Survivor.io. Hipótese: metas pequenas e opções novas, em vez de apenas bônus numéricos, podem favorecer retorno. Não se conhece a frequência desse sentimento no público total.
3. **Legibilidade e controle:** dois relatos de toques involuntários em Nonogram, um de controles em Mini Metro e um de consulta de combinações em Magic Survival. Hipótese: interface clara e regras consultáveis podem diferenciar um produto compacto.
4. **Confiança no progresso e nas compras:** relatos isolados em Flow, Pocket Frogs e Cats&Soup apontam riscos diferentes. Hipótese: regras estáveis, salvamento confiável e entrega explícita de cosméticos merecem prioridade; não presumir que todos perderam dados/compras.

Um contraponto importante dentro do mesmo jogo: Lady Kurai (05/04/2026, [Cats&Soup en-US](https://play.google.com/store/apps/details?id=com.hidea.cat&hl=en_US)) descreve anúncios de eventos como quase obrigatórios; NEOWIZ reconhece a sensação na resposta de 10/04/2026. Isso contrasta com o elogio de Mckenzie em setembro. É evidência de experiências diferentes, não consenso sobre o estado atual do produto.

## Shortlist de espaços, sem escolher um conceito

### A. Micro-puzzles 2D com coleção visual

**Evidência:** Nonogram e Flow mostram coleção/conteúdo e lógica acessível; os relatos de anúncios e precisão apontam fricções concretas.

**Hipótese de oportunidade:** puzzles determinísticos compactos, com uma regra original, toque tolerante e desfazer; progresso visível por uma coleção própria. Meta de 1–5 minutos por puzzle, a medir. Rejogabilidade por desafios autorais e variações verificadas, sem copiar tabuleiros ou apresentação dos concorrentes.

**Godot/GDScript:** complexidade baixa a média relativa: grade 2D, estados, UI e save local. O custo oculto é criar e testar dificuldade e solucionabilidade. MVP potencial: uma família de regras e um pequeno catálogo autoral; gerador, editor e UGC podem multiplicar o escopo.

**Extensões hipotéticas:** skins de tabuleiro e elementos; rewarded para dica/prévia com solução sempre possível offline. Passe temático somente se houver coleção e cadência sustentável. **Risco principal:** saturação e catálogo que acaba rápido. **Pergunta:** a regra é reconhecível e interessante sem depender da promessa de poucos anúncios?

### B. Arcade de sobrevivência/score attack em rodadas de 3–5 minutos

**Evidência:** três survivors têm ampla distribuição acumulada; há relatos de grind, repetição e dificuldade de consultar combinações. Isso não comprova procura por partidas mais curtas.

**Hipótese de oportunidade:** decisões legíveis e rodada com fim claro; evolução horizontal pequena, consulta de sinergias e retomada local. Retorno por domínio e combinações, sem buscar a amplitude de conteúdo dos líderes.

**Godot/GDScript:** complexidade média: combate 2D, spawn, performance com muitos objetos, balanceamento e legibilidade. MVP potencial: uma arena, poucos inimigos e um conjunto pequeno de opções. Limitar efeitos e entidades é importante em aparelhos Android modestos.

**Extensões hipotéticas:** skins de personagem, projéteis e arena; rewarded para bônus pós-rodada ou uma continuação limitada, sem se tornar requisito de vitória. Passe apenas depois de demonstrada demanda por novos desafios. **Riscos:** comparação com catálogos enormes, duração real acima de cinco minutos e evolução numérica repetitiva. **Pergunta:** reduzir a rodada preserva decisões interessantes?

### C. Coleção cozy com progressão leve e ações curtas

**Evidência:** Cats&Soup reúne produção, roupas e decoração; Pocket Frogs oferece coleção/habitats. Relatos mostram tanto valor no jogo relaxante quanto riscos de itens pagos, armazenamento e mudanças de acesso.

**Hipótese de oportunidade:** uma coleção pequena e expressiva, com ações de 1–5 minutos e possibilidade de voltar sem tarefas obrigatórias. Progresso local e decoração podem criar apego sem infraestrutura social.

**Godot/GDScript:** complexidade média; lógica idle pode ser simples, mas arte, animação, inventário e economia são trabalho contínuo. MVP potencial: um ambiente, uma moeda e coleção limitada; cálculo offline precisa tolerar relógio alterado e interrupções. Não exige economia competitiva protegida por servidor.

**Alternativa investigada:** merge com restauração visual, apoiado pelo posicionamento de Merge Mayor. Não ganhou espaço separado na shortlist porque cadeias de itens, inventário e tarefas podem aumentar o catálogo e balanceamento rapidamente. Pode ser reconsiderado na etapa de conceitos se houver capacidade de produzir ícones e conteúdo; essa restrição é julgamento de escopo, não falta de mercado demonstrada.

**Extensões hipotéticas:** cosméticos têm encaixe natural; rewarded pode dar bônus limitado de produção mantendo ritmo base viável. Passe temático tem encaixe maior aqui, porém exige conteúdo recorrente e pode contrariar a proposta sem pressão. **Riscos:** custo artístico, recompensas que viram trabalho e “jogo de anúncios”. **Pergunta:** a coleção continua desejável sem muita animação/conteúdo novo?

### D. Puzzle de gestão compacta com objetivos finitos

**Evidência:** Mini Metro mostra profundidade, crescimento variável e modos; avaliações apontam microgerenciamento tardio e controle fino como possíveis fricções.

**Hipótese de oportunidade:** um sistema abstrato próprio de organizar fluxos/recursos, com objetivo de cenário atingível em 3–5 minutos e feedback claro. Não reproduzir redes, mapas ou estética de Mini Metro. Rejogabilidade por restrições e combinações de cenários.

**Godot/GDScript:** complexidade média a alta relativa; simulação, interface e balanceamento podem crescer rapidamente. MVP potencial: um recurso e uma única operação de gestão, sem economia de cidade ou IA de agentes complexa.

**Extensões hipotéticas:** temas visuais e decoração; rewarded teria encaixe menos natural e deve ser dispensável. Passe não parece necessário. **Riscos:** interface pequena, profundidade que demanda sessões longas e nicho menor. **Pergunta:** o sistema cabe numa tela e produz decisão relevante em poucos minutos?

## Comparação de aderência ao estúdio

Avaliação qualitativa do pesquisador, não métricas do mercado. “Maior” indica aderência ao critério, não probabilidade de lucro.

| Critério | A: micro-puzzle | B: arcade curto | C: coleção cozy | D: gestão compacta |
|---|---|---|---|---|
| Simplicidade relativa de implementação | Maior | Média | Média | Menor |
| Sessões 1–5 min como meta | Natural por nível | Exige corte explícito | Natural por visita | Exige cenários finitos |
| Progressão/rejogabilidade possível | Coleção e desafios | Domínio e combinações | Coleção e decoração | Restrições e domínio |
| Custo de conteúdo/arte | Médio | Médio | Alto | Médio |
| Espaço cosmético | Médio | Alto | Alto | Médio |
| Encaixe de rewarded opcional | Dicas | Pós-rodada | Bônus limitado | Fraco |
| Passe futuro | Condicional | Condicional | Mais natural, ainda arriscado | Fraco |
| Backend obrigatório no MVP proposto | Não | Não | Não | Não |
| Evidência de demanda específica pela proposta | Ainda não validada | Ainda não validada | Ainda não validada | Ainda não validada |

## Monetização e infraestrutura: alternativas para avaliação

Estas são possibilidades de pesquisa, **não uma estratégia aprovada**. Nenhuma conta, credencial, gasto ou integração foi criada.

O loop base pode funcionar com salvamento local e sem login obrigatório. Anúncios dependem de rede/SDK quando utilizados; offline não implica receita publicitária offline. Compras exigem integração da loja e tratamento de restauração/entrega; ausência de backend próprio não elimina manutenção ou suporte.

Se rewarded for avaliado, a política AdMob exige consentimento explícito, recompensa claramente informada e entrega do prometido; recusar não pode prejudicar o uso normal. Proposta de UX: sem anúncio disponível, jogador continua o loop base sem bloqueio. Não transportar a recompensa publicitária para um requisito de dificuldade/economia. [Política de rewarded, consultada 01/10/2026](https://support.google.com/admob/answer/7313578?hl=en-GB).

Cosméticos devem preservar leitura e desempenho. Passe sazonal é extensão futura apenas se retenção, demanda cosmética e capacidade de produção justificarem a cadência; não é um requisito de MVP. Monetização deve passar pela aprovação humana prevista em AGENTS.md.

## Validação seguinte, somente após seleção humana

Antes de autorizar implementação, o proprietário pode escolher um espaço para a etapa de conceitos. Perguntas pendentes: público/país inicial, orientação da tela, capacidade de arte, orçamento/tempo e tolerância a produção contínua de conteúdo. Essas respostas podem mudar a avaliação de escopo.

Uma etapa posterior, separadamente autorizada, poderia comparar propostas originais com jogadores Android: compreensão das regras, interesse sem recompensas extrínsecas e diferença percebida frente aos concorrentes. Para um protótipo futuramente aprovado, medir tempo real de sessão, precisão de toque, conclusão, vontade de repetir e retorno em dias posteriores; critérios devem ser definidos antes do teste. Não adotar benchmarks de retenção/receita que esta pesquisa não obteve.

Rejeitar ou reduzir uma proposta se só parecer divertida com muitos sistemas, se exigir internet para o loop base, se a sessão curta não contiver decisões relevantes, ou se anúncios forem necessários para tornar a progressão tolerável. Validar retomada/save e performance em Android real antes de alegar funcionamento.

**Estado do gate:** pesquisa concluída como levantamento inicial. Shortlist disponível para avaliação; escolha de conceito, GDD, arquitetura e implementação continuam pendentes de suas respectivas etapas. Nenhum jogo iniciado.
