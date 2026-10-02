# Club Legacy — conceito e menor MVP de validação

Data: **01/10/2026**. Papel: Product Manager. Nome de trabalho, sem verificação de disponibilidade comercial.

Base: solicitação do proprietário e [validação de mercado](../../reports/market/club-legacy-market-validation.md). A direção foi escolhida pelo proprietário para exploração prioritária. Isso autoriza este conceito e a pesquisa, não a produção de um jogo. Todos os recortes, quantidades e durações abaixo são **hipóteses de produto**. Não constituem GDD, arquitetura, plano de implementação ou estimativa fechada.

## Promessa e público

**Promessa:** conduzir a carreira de um treinador num mundo de futebol fictício, tomando decisões esportivas e financeiras compreensíveis em sessões curtas; o clube pode mudar, mas o histórico do treinador continua.

**Gênero:** simulador de carreira e gestão de futebol por decisões, sem controle direto de atletas. Público hipotético: jogadores Android interessados em escalação, transferências, temporadas e histórias de carreira, que preferem menos tarefas administrativas. Não há validação de faixa etária, tamanho desse segmento ou interesse em clubes fictícios.

**Diferencial a testar:** carreira portátil entre clubes, consequências explicadas e poucas escolhas com impacto. Managers rápidos, offline e com carreira já existem; a combinação não deve ser anunciada como inédita. Reputação, demissão e transferências precisam criar decisões, em vez de apenas uma lista maior de funcionalidades.

**Restrições:** Android, Godot, GDScript, offline-first, save local, single-player e nenhum backend inicial. Clubes, jogadores, país, identidades e competições autorais/fictícios. Sem compras no MVP e sem anúncios no primeiro protótipo; a proposta mínima também exclui anúncios do MVP de validação. Não há loja, moeda premium, passe ou SDK comercial.

## Loop e unidade de sessão

**ESCALAR → JOGAR → RECEBER RESULTADO → GANHAR/PERDER DINHEIRO → NEGOCIAR JOGADORES → MELHORAR CLUBE → DISPUTAR TEMPORADA → EVOLUIR CARREIRA.**

Uma visita pode conter uma rodada: revisar escalação e folha → escolher formação/estratégia → acompanhar a partida e intervir → ler resultado e saldo → decidir se guarda dinheiro, negocia ou investe → encerrar. Nem toda rodada exige transferência ou obra; parte da estratégia é adiar uma ação. Um ciclo completo de validação precisa atravessar uma temporada e uma decisão de contrato, não apenas uma partida.

**Metas ainda não medidas:** 2–5 minutos por rodada com decisões; partida em aproximadamente 45–90 segundos de apresentação, com pause e avanço de velocidade. Uma temporada de dez rodadas pode ocupar cerca de 25–50 minutos somando mercado e encerramento. Não transformar esse intervalo em promessa antes de medir em jogadores; pausa/retomada deve permitir encerrar a sessão sem perder carreira.

## Menor mundo que sustenta o loop

- Uma nação fictícia; duas divisões com **seis clubes cada**, total de 12.
- Turno e returno: dez rodadas por divisão. Pontuação, saldo de gols e um desempate final explicitado; campeão de cada divisão.
- Um acesso e um rebaixamento entre as duas divisões ao final da temporada; sem playoffs, ligas continentais ou seleções.
- Elencos de **18 jogadores**, com posições amplas e reservas para substituição; cerca de 216 atletas iniciais. Sem atletas reais, fotos ou importação de bancos de dados.
- Clubes adversários também têm orçamento, contratos e evolução básica; mudanças continuam quando o treinador sai. Não basta simular apenas o clube do usuário num mundo congelado.
- Idade, aposentadoria, reposição de atletas fictícios e crescimento/declínio anual simplificados mantêm novas temporadas possíveis. Reposição de elenco não é sistema de categorias de base.
- Sem fim forçado após a primeira temporada. A validação inicial observaria três temporadas jogadas e continuidade de ao menos cinco temporadas em verificações futuras; isso ainda não comprovaria interesse numa carreira de décadas.

Os números são um teto candidato para reduzir calendário e conteúdo, não requisitos de realismo. Mesmo esse mundo pequeno exige balancear futebol, salários, obras e oportunidades de emprego; não é uma variação trivial dos conceitos casuais anteriores.

## Começo: três situações de clube

O mesmo mundo apresenta ao menos um clube selecionável de cada perfil. Todos têm dinheiro finito e objetivos apresentados antes da contratação.

| Perfil | Situação inicial | Pressão e possibilidade de carreira |
|---|---|---|
| Pequeno | Segunda divisão, caixa/folha baixos, elenco limitado, estádio e torcida pequenos | Meta inicial modesta; mais tolerância a resultados, sem imunidade a demissão; construir reputação por superar expectativas |
| Médio | Recursos e elenco intermediários, infraestrutura moderada | Meta compatível com sua divisão; pressão intermediária e escolhas entre salários e investimento |
| Elite | Primeira divisão, elenco/orçamento fortes, maior estádio e torcida | Disputar título; margem menor para desempenho ruim, salários altos e risco de perder o cargo apesar de maior receita |

Perfil não é só dificuldade: muda caixa, qualidade inicial e expectativa. A reputação inicial do treinador pode ser a mesma nos três cenários por conveniência do teste, com a primeira contratação excepcional explicada; empregos seguintes dependem do histórico. Esse ponto exige avaliação de coerência antes de produção.

## Carreira independente do clube

Manter identidade, reputação, clubes treinados, temporadas, resultados relevantes, títulos e motivos de saída. **Caixa, estádio, elenco e torcida pertencem ao clube**, não acompanham o treinador. Não criar inventário financeiro pessoal neste MVP.

Contrato do treinador de uma temporada, com decisão de renovação no encerramento. Objetivo e pressão são visíveis; confiança da diretoria responde a desempenho relativo às expectativas e disciplina financeira. Antes de uma demissão esportiva, comunicar risco e razão; um resultado ruim isolado não deve destruir arbitrariamente a carreira.

Ofertas de outros clubes usam reputação e vagas disponíveis. No menor recorte, contratação inicial, propostas, renovação e troca voluntária ocorrem entre temporadas; demissão pode ocorrer durante a temporada. Uma proposta deve apresentar clube, objetivos e situação financeira, permitir recusa e encerrar o contrato anterior ao ser aceita.

Após demissão, preservar o histórico e permitir procurar vagas/avançar o calendário enquanto o mundo continua. Deve existir um caminho plausível para voltar a um clube de menor exigência; se não houver vaga imediata, explicar espera e não prender o jogador numa tela sem saída. O teste precisa incluir esse caminho, não apenas carreira vitoriosa.

## Escalação e partida

Onze titulares, banco, posições amplas, condição física e qualidade resumida. Três formações e três estratégias gerais: cautelosa, equilibrada e ofensiva. Sem dezenas de funções individuais, árvores de instrução, controle de passe/chute ou treino por agenda diária.

Partida simulada com **placar, relógio, eventos e estatísticas básicas**. Pausar, trocar estratégia e fazer até três substituições, observando quem entrou/saiu e os efeitos posteriores. A simulação deve considerar as decisões tomadas; não prometer que toda troca gera gol ou vitória. Informações pós-jogo precisam ser coerentes com os eventos e reconhecer incerteza, sem inventar uma causa certa para cada derrota.

Representação 2D animada **fica para depois**: não é necessária para testar escalação, decisão e confiança no resultado, e aumenta arte, legibilidade e sensação de realismo exigida. Um desenho estático de formação pode servir à escalação, sem virar engine de partida visual.

## Mercado e contratos simplificados

Lista pequena de atletas acessíveis, com posição, qualidade, idade, salário e preço esperado. Comprar/vender envolve proposta ao clube e, na compra, aceitação salarial pelo atleta. Uma contraproposta simples pode ser aceita ou recusada; sem agentes, parcelas, bônus múltiplos, empréstimos ou guerras de leilão.

Uma janela entre temporadas e uma janela breve no meio da temporada dão motivo para planejar sem negociar a cada partida. Salários têm efeito recorrente; preço de compra não é o custo total. Contratos de jogador de uma ou duas temporadas, renovação e saída no vencimento completam o teste de folha salarial. Atletas sem contrato formam uma pequena opção de reposição, sem garantir craques gratuitos.

Compradores adversários precisam ter necessidade e capacidade de pagar; venda não pode ser uma fonte ilimitada de caixa. Jogadores mais fortes podem recusar clubes sem orçamento/reputação adequados, com motivo compreensível. Não tornar toda tentativa do clube pequeno inviável: manter alternativas úteis e acessíveis.

## Gestão e evolução: o que entra e o que fica adiado

| Sistema | Recorte mínimo proposto | O que testa |
|---|---|---|
| Finanças | Caixa, folha salarial, receitas/despesas por rodada e previsão de saldo | Decisão entre reforço, reserva e investimento |
| Receita | Bilheteria em casa e premiação de temporada por posição; valores do mundo fictício | Impacto de capacidade, público e campanha |
| Despesa | Salários e manutenção básica; compra/obra com custo pontual | Risco de crescer além do caixa |
| Estádio/capacidade | Valor inicial por clube e uma expansão pequena, com custo e prazo visíveis | Aumentar capacidade só ajuda se houver demanda de torcida |
| Centro de treinamento | Valor inicial e uma melhoria limitada, com benefício modesto ao desenvolvimento anual | Escolha entre jogador pronto e melhoria futura |
| Torcida | Um indicador agregado de interesse; influencia público, limitado pela capacidade | Resultados podem aumentar demanda, sem receita automática infinita |
| Reputação do clube | Prestígio simples, distinto do treinador | Interesse de atletas e expectativa de crescimento |
| Reputação do treinador | Evolui por resultados versus expectativa, títulos e saídas | Ofertas, renovação e mobilidade |
| Seguidores | **Adiado**; não duplicar torcida/reputação com um contador sem decisão própria | Validar depois se acrescenta significado |
| Categorias de base | **Adiado**; reposição de jogadores sustenta calendário sem academia gerenciável | Evitar recrutamento/treinamento juvenil no primeiro recorte |
| Patrocinadores | **Adiados**; não negociar contratos comerciais ou cobrar metas extras | Conter sistemas e interface |

Resultados influenciam reputação/torcida; investimento pode ampliar capacidade e desenvolvimento; orçamento e prestígio alteram acesso a jogadores; desempenho relativo muda ofertas de emprego. Nenhuma relação deve ser escalada como ganho garantido: um estádio maior pode não lotar, um reforço caro pode não compensar e a folha pode consumir o aumento de receita.

O treinador atua como treinador/gestor autorizado pela diretoria. Obras usam dinheiro e limites do clube, não propriedade pessoal. Sem falência complexa: mostrar déficit, limitar novas despesas e permitir recuperação por cortes/vendas; insolvência persistente pode motivar demissão com explicação e continuidade da carreira.

## Copa nacional

**Proposta para o menor MVP: adiar.** A liga já testa campeões, temporada, acesso/rebaixamento e pressão. Uma copa acrescentaria sorteio, rodadas extras, recompensas, calendário e mais situações de elenco/empate. Mesmo sem 2D, não é apenas outra tabela.

Extensão futura possível: eliminatória curta com os 12 clubes, folgas iniciais e resolução de empate, somente depois de validar o loop principal. Não é parte do recorte mínimo nem funcionalidade aprovada.

## Limites explícitos e esforço

Não entram: clubes/atletas/licenças reais, dados proprietários, reprodução de interfaces, novos países, seleções, copas, multiplayer, backend, nuvem, editor/datapacks, staff completo, agentes, imprensa, patrocinadores, academia de base, seguidores separados, economia pessoal do treinador, partida 3D/2D animada ou monetização.

**Complexidade e esforço relativos:** maiores que um puzzle ou arcade casual pequeno. A maior carga está nas dependências entre temporada, simulação, economia e carreira; arte simples não elimina isso. Dentro deste conceito, eventos textuais, liga única por divisão e contratos curtos são o recorte de menor esforço. Copa e animação 2D acrescentariam esforço sem serem necessárias à pergunta inicial. Não há prazo/orçamento confiável antes de uma futura etapa autorizada de escopo e planejamento.

## Validação proposta e critérios de interrupção

São perguntas para uma etapa futura, sem testes executados ou autorização de protótipo nesta tarefa:

- O jogador consegue escalar, alterar estratégia e explicar uma escolha sem acompanhamento constante?
- Após resultado e balanço, entende por que ganhou/perdeu dinheiro e considera ao menos duas opções de uso do caixa?
- Consegue contratar, renovar e vender sem confundir salário recorrente com taxa de transferência?
- Deseja completar a temporada e iniciar outra, inclusive quando não conquista título?
- Troca/demissão mantém apego à carreira ou o jogador entende a saída como perda de todo o progresso?
- O mundo fictício é interessante sem nomes reais? História, jogadores e oportunidades renovam-se ao longo das temporadas?

Observar tempo de rodada, conclusão de temporada, retorno voluntário, variedade de escolhas e razões de abandono. Resultados de poucas pessoas não estimam retenção comercial. Em verificação futura, percorrer caminhos de título, acesso, rebaixamento, déficit, vencimento de contratos, demissão, recontratação e retomada de save. Nenhum desses caminhos foi testado agora.

**Reduzir/reavaliar** se as decisões não mudarem a experiência, se a economia só funcionar com ajuda arbitrária, se resultados parecerem inexplicáveis, se o jogador não entender a carreira separada ou se diversão exigir muitos países, nomes reais e visual de partida. **Não ampliar** para copa, patrocinadores ou base para esconder um loop principal sem interesse.

## Estado e decisão pendente

Este é um conceito candidato da direção prioritária escolhida pelo proprietário, com um MVP mínimo proposto. Aprovar o recorte e uma próxima etapa exige decisão humana; esta tarefa termina na documentação. Nenhum GDD, arquitetura, projeto Godot, código, integração comercial ou publicação foi criado.
