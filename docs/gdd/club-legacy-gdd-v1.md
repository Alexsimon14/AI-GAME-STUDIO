# Club Legacy — Game Design Document v1

**Game 001 · 01/10/2026 · Product Manager**

**Estado:** primeiro GDD oficial, preparado para revisão do proprietário. O proprietário aprovou Club Legacy como direção e o menor MVP do conceito como base desta etapa. A aprovação deste GDD e o avanço para arquitetura/implementação permanecem etapas posteriores.

Documentos lidos: [AGENTS.md](../../AGENTS.md), [Product Manager](../../agents/product-manager.md), [validação de mercado](../../reports/market/club-legacy-market-validation.md) e [conceito aprovado como base](../game-concepts/club-legacy-concept.md). Os documentos anteriores são registros da etapa em que foram escritos; este GDD registra a decisão posterior do proprietário sem alterá-los.

Este documento define comportamento e regras de produto. Não define arquitetura, formato de save, banco de dados ou código. As regras abaixo são propostas de design da v1, não resultados de testes. **DECISÃO PENDENTE** identifica dúvidas de produto ou parâmetros que exigem definição/validação; nenhum número econômico ou probabilidade é apresentado como balanceamento definitivo. A pesquisa não comprovou oportunidade comercial.

**Limites:** Android; Godot/GDScript na futura implementação; offline-first; save local; single-player; uma nação fictícia; sem backend, licenças esportivas, compras ou anúncios no MVP. Nome provisório sem verificação de disponibilidade comercial.

## 1. Visão do jogo

**Fantasia:** ser o treinador/gestor que constrói uma trajetória própria, transforma recursos limitados em campanhas e leva seu histórico a outros clubes. O usuário recebe autoridade da diretoria para escalação, mercado e investimentos delimitados; não é proprietário do clube.

**Objetivo:** cumprir objetivos esportivos, manter o clube sustentável e construir uma carreira com títulos, acessos e novos empregos. Não há vitória final obrigatória nem encerramento após a primeira temporada. Continuar num clube também é uma trajetória válida.

**Experiência pretendida:** decisões rápidas, consequências legíveis e temporadas que geram histórias. Ganhar com um clube menor deve ser possível; derrota, rebaixamento ou demissão devem criar caminhos de recuperação. Público hipotético: jogadores Android interessados em futebol gerencial com menos tarefas administrativas; a aceitação de um mundo fictício ainda precisa ser testada.

**Pilares:**

- Carreira independente: a identidade e o histórico persistem quando o emprego muda.
- Poucas escolhas relevantes: escalação, três estratégias, contratos e alocação do caixa.
- Futebol incerto e compreensível: qualidade e decisões influenciam oportunidades, sem garantir resultados.
- Crescimento sustentável: estádio, treino e salários competem pelos mesmos recursos finitos.
- Ritmo controlado pelo jogador: pausar, retomar e avançar o calendário sem compromisso online.

**Loop principal:** ESCALAR → JOGAR → RECEBER RESULTADO → GANHAR/PERDER DINHEIRO → NEGOCIAR JOGADORES → MELHORAR CLUBE → DISPUTAR TEMPORADA → EVOLUIR CARREIRA. Negociar e investir são decisões opcionais nos momentos permitidos, não tarefas obrigatórias a cada rodada.

**Loop de temporada:** preparação/objetivo/mercado → cinco rodadas → janela intermediária → cinco rodadas → classificação e premiação → acesso/rebaixamento → avaliação e contratos → evolução do mundo → preparação seguinte.

**Loop de carreira:** escolher primeiro clube → cumprir ou falhar em objetivos → construir histórico/reputação → renovar, aceitar outro emprego ou ser demitido → continuar no mesmo mundo. Enquanto desempregado, acompanhar vagas e avançar rodadas.

Metas de ritmo herdadas do conceito, **a medir**: 2–5 minutos por rodada com gestão; 45–90 segundos de apresentação de partida em velocidade normal; 25–50 minutos por temporada incluindo encerramento. Não são compromissos de duração nem evidência de retenção.

## 2. Carreira do treinador

### Criação e propriedade do progresso

Criar treinador com nome informado pelo usuário. Sem avatar complexo, atributos técnicos, árvore de habilidades ou finanças pessoais. Nome é identidade, não modificador de desempenho.

| Pertence ao treinador | Pertence ao clube |
|---|---|
| Nome, reputação, emprego atual, contratos de trabalho e motivos de saída | Caixa, receitas, dívidas operacionais e folha |
| Histórico por temporada e passagem; títulos e acessos conquistados | Elenco, contratos de jogadores, capacidade e obras |
| Propostas recebidas e decisões de carreira relevantes | Torcida, reputação institucional e centro de treinamento |

Trocar de clube não transfere dinheiro, jogadores ou estruturas. O clube anterior continua com as consequências das decisões tomadas. Títulos constam no histórico do clube vencedor; o treinador recebe crédito quando está empregado nesse clube no encerramento da competição. Passagens parciais registram datas/rodadas e campanha durante sua gestão, sem atribuir título posterior automaticamente.

### Reputação, objetivos e confiança

Reputação do treinador é um indicador limitado, apresentado em faixas compreensíveis. Evolui principalmente em avaliações de temporada por resultado versus expectativa, títulos e acesso; saídas e campanhas parciais também são registradas. Não ganhar reputação infinitamente por repetir uma ação, contratar/vender ou clicar em propostas. Não apagar conquistas anteriores por uma demissão.

Objetivo principal é esportivo: uma posição/faixa de classificação apropriada ao elenco e à divisão, com título para elite quando aplicável. Sustentabilidade financeira é uma condição de gestão separada e visível. Objetivos são anunciados antes da assinatura e ficam fixos até o encerramento, salvo contratação no meio da temporada: nesse caso, mostrar situação herdada e meta de recuperação ajustada ao calendário restante.

Confiança da diretoria é distinta da reputação de carreira. Mostrar situação segura, atenção ou risco, com razões recentes e expectativa. Avaliar tendência de resultados em relação à meta e déficit persistente; não demitir por uma derrota isolada nem exigir que um contratado recupere instantaneamente um déficit herdado. Aviso deve anteceder a decisão e dizer o que ainda pode melhorar.

**DECISÃO PENDENTE — C1:** escala/faixas de reputação e confiança, janela de resultados, limiares e tolerância por perfil, prazo de recuperação financeira e tratamento de campanha parcial. Esses parâmetros devem admitir risco real sem tornar a demissão arbitrária.

### Contratos, propostas e saída

Contrato do treinador dura até o fim da temporada corrente; contratos assinados durante a temporada têm duração restante explícita. Sem negociação de salário pessoal ou indenização no MVP.

Ao encerrar a temporada, a diretoria oferece renovação ou comunica não renovação com justificativa. O jogador pode aceitar, recusar e examinar vagas/propostas antes de confirmar seu destino. Contrato renovado vale por uma nova temporada. Recusar deixa o treinador disponível quando o vínculo atual termina, não durante a partida em curso.

Propostas dependem de vaga, exigência do clube e reputação compatível. Exibem elenco resumido, divisão, caixa/folha, objetivo e duração. Não garantem uma oferta de elite a cada ano. Aceitar uma proposta entre temporadas encerra o vínculo anterior e preserva o mundo. Jogador empregado não troca voluntariamente no meio da temporada neste MVP; desempregados podem ser contratados em vagas abertas durante ela.

Demissão é processada entre rodadas, após aviso e avaliação. Clube recebe um substituto gerencial simplificado; treinador fica desempregado, mantém histórico e recebe explicação. Não renovação e demissão são motivos diferentes no histórico.

### Desemprego e continuidade

Sem clube, a ação principal é consultar vagas e avançar a próxima rodada; todos os jogos e balanços continuam. Candidatar-se exige compatibilidade mínima e permite recusa explicada. Não cobrar dinheiro nem apagar save para retornar.

Para evitar carreira bloqueada, a abertura de temporada deve oferecer ao menos um caminho de contratação em clube de menor exigência para um treinador desempregado. Esse caminho usa uma vaga/revisão de contratação do mundo e não cria um décimo terceiro clube. O calendário pode continuar até lá, com aviso do próximo período de oportunidades. Essa proteção de continuidade não assegura emprego desejado ou ausência de espera.

**DECISÃO PENDENTE — C2:** reputação inicial comum e justificativa da primeira contratação em elite, conforme dúvida do conceito; regras de seleção de vagas e de contratação acessível no início da temporada. As três escolhas iniciais permanecem disponíveis no MVP.

Histórico registra temporada, clube/divisão, rodada de entrada/saída, classificação quando pertinente, vitórias/empates/derrotas na passagem, títulos, acessos/rebaixamentos, reputação e motivo de saída. Rebaixamento pertence ao clube e recebe contexto de participação do treinador; não imputar automaticamente toda a campanha a um substituto tardio.

## 3. Clubes

Mundo inicial com 12 clubes fictícios, seis por divisão. Identidades, nomes e textos próprios; nenhum banco de dados esportivo importado.

| Atributo mínimo | Função |
|---|---|
| Nome/identidade e divisão | Reconhecer o clube e sua competição atual |
| Reputação institucional limitada | Interesse de atletas e contexto de expectativa |
| Torcida agregada | Base de demanda, distinta do público de uma partida |
| Nome do estádio e capacidade | Identidade e limite de bilheteria |
| Caixa e compromissos | Recursos disponíveis e previsão financeira |
| Folha salarial | Soma dos salários dos contratos ativos por rodada |
| Centro de treinamento | Nível inicial e melhoria limitada |
| Expectativa/confiança da diretoria | Meta esportiva e tolerância de gestão |
| Elenco, investimentos em andamento e histórico | Continuidade do clube ao longo dos empregos |

| Perfil inicial | Recursos e elenco | Cobrança |
|---|---|---|
| Pequeno | Segunda divisão, menor caixa, folha, torcida e capacidade; atletas mais limitados | Meta modesta; mais tolerância esportiva e dificuldade financeira real |
| Médio | Recursos e infraestrutura intermediários; elenco compatível com sua divisão | Meta intermediária e escolhas relevantes entre folha e obras |
| Elite | Primeira divisão, orçamento, elenco, torcida e estádio maiores | Disputar título, alta folha e pouca tolerância a desempenho inferior |

Perfil descreve a situação inicial, não um multiplicador oculto de resultado. Clube pequeno pode crescer, elite pode cair; objetivos futuros acompanham divisão e capacidade esportiva, sem redefinir metas durante a campanha. Haverá ao menos um clube inicial selecionável de cada perfil.

**DECISÃO PENDENTE — CL1:** nomes autorais, distribuição dos perfis e valores iniciais de caixa, torcida, estruturas, reputação e qualidade. Deve existir um cenário inicial solvente para cada perfil sem depender de título ou venda obrigatória.

## 4. Jogadores

| Campo | Regra de produto |
|---|---|
| Nome fictício e identidade persistente | Distinguir atleta e acompanhar sua história entre clubes |
| Idade | Avança uma vez por temporada; informa desenvolvimento/declínio |
| Posição principal | Goleiro, defensor, meio-campista ou atacante |
| Qualidade geral (overall) | Resumo da capacidade para sua função; escala limitada |
| Potencial | Limite de desenvolvimento; mostrado como faixa, sem promessa de evolução |
| Condição física | Disponibilidade funcional atual e fadiga de jogo |
| Salário | Custo por rodada, apresentado com custo da temporada restante |
| Valor de mercado | Referência estimada, não preço garantido de venda |
| Contrato | Clube, fim ao término de uma temporada e salário vigente |

Finalização, passe, defesa e velocidade **não são quatro atributos independentes gerenciáveis no MVP**. Qualidade geral, posição, adequação à função e condição alimentam a contribuição conceitual de cada setor. Não exibir subatributos inventados para explicar um lance; o relato usa qualidade do setor e contexto observado. Isso reduz gestão de conteúdo e interface, assumindo menor personalização dos atletas.

Potencial limita crescimento, não dá gols ou aceitação automática de transferência. Idade e treino influenciam evolução entre temporadas; atletas podem estabilizar e declinar. Aposentadoria remove o atleta do elenco depois do encerramento e cria necessidade de reposição.

**DECISÃO PENDENTE — J1:** escala de qualidade/condição, limites de potencial, faixas de idade, progressão/declínio e aposentadoria. Jogadores de reposição terão variedade controlada de posições/qualidade e salários coerentes; não formar uma fonte infinita de craques gratuitos.

## 5. Elenco e escalação

Elenco de **18 atletas por clube**; onze titulares e sete reservas na partida. Composição inicial deve oferecer dois goleiros e cobertura suficiente dos demais setores para todas as formações. Durante o mercado, 18 é o teto e onze atletas aptos com goleiro é o mínimo para confirmar uma venda. Trocas podem exigir vender primeiro; mostrar o risco de perder cobertura. Clubes abaixo do teto devem poder recompor o elenco.

Formações iniciais: **4–4–2, 4–3–3 e 5–3–2**, sempre com um goleiro. Defensores não se dividem em laterais/zagueiros neste MVP. A interface mostra as vagas por setor, sugere a última escalação válida e avisa sobre uso fora da posição. Fora de posição reduz a adequação funcional, especialmente no gol, sem remover o atleta do mundo.

Até **três substituições** por partida, em pausas de jogo; substituído não retorna. Mudança de formação reorganiza os onze em campo sem conceder substituições adicionais. Alterações confirmadas valem no próximo evento, sem reescrever chances já resolvidas. Adversário obedece às mesmas regras.

Condição cai com minutos jogados e esforço estratégico, reduzindo contribuição ao longo da partida. Reservas descansados são alternativas reais. Recuperação ocorre no intervalo entre rodadas; mostrar previsão antes do próximo jogo. Não cobrar sessões diárias de treino.

Lesões e suspensões **fora do MVP**; cartões também ficam fora para evitar criar sanção sem consequência. A fadiga já testa banco e gestão mínima. Não narrar lesão, expulsão ou suspensão inexistente. Aposentadoria e contratos são problemas de temporada, não eventos inesperados que inviabilizam a primeira partida.

**DECISÃO PENDENTE — E1:** intensidade da perda/recuperação física, efeitos de inadequação e composição exata dos 18 por setor. A reposição deve impedir calendário sem goleiro ou elenco jogável; não permitir iniciar partida com escalação inválida.

## 6. Táticas

| Estratégia | Intenção e consequência conceitual | Compromisso |
|---|---|---|
| Cautelosa | Mais organização e cobertura, menos jogadores avançando; buscar saídas em espaços deixados pelo rival | Pode reduzir criação própria e permitir pressão territorial adversária |
| Equilibrada | Distribuir apoio entre construção, ataque e proteção | Não explora tanto extremos de pressão ou retração |
| Ofensiva | Mais apoio à frente e esforço para recuperar/criar; ocupação ofensiva maior | Pode expor transições e cansar mais, sobretudo sem qualidade/condição |

Formação determina distribuição dos recursos por setor; estratégia determina como são utilizados. Mais atacantes não significam automaticamente mais chances se a criação no meio for fraca. Cautela não garante defesa perfeita nem contra-ataque; ofensiva não soma um percentual fixo de gol.

Adversários podem reagir ao placar, tempo e condição. Não existe estratégia secreta sempre superior, bônus por perfil de clube ou punição por alternar estratégia. Mudanças afetam apenas os próximos trechos. **DECISÃO PENDENTE — T1:** magnitude e interação entre cobertura, criação, transição e esforço; validar vantagem situacional e ausência de estratégia dominante.

## 7. Motor de partida — design conceitual

### Encadeamento causal

A partida representa 90 minutos em duas etapas de 45, com intervalo para decisões. Sem prorrogação, pênaltis ou acréscimos no MVP. Apresentação acelerada não muda o tempo esportivo ou a distribuição de oportunidades.

1. **Compor os setores em campo:** qualidade, posição adequada e condição dos onze definem capacidade relativa de proteção, criação e ataque. Formação distribui atletas; estratégia altera exposição e apoio. Goleiro participa da defesa das finalizações.
2. **Disputar a iniciativa:** em trechos do tempo, comparar construção/pressão com cobertura adversária. Mando pode oferecer influência pequena na iniciativa, sem vitória garantida. Contexto gera possibilidade de ataque, disputa ou sequência sem chance.
3. **Construir uma chance:** ataque precisa superar obstáculos de criação e proteção. Espaço de transição, distribuição dos setores, condição e decisão tática influenciam a qualidade da chance. Nem todo ataque vira chute.
4. **Resolver a chance:** atacante adequado, qualidade da oportunidade e oposição defensiva/goleiro influenciam chute bloqueado, fora, defesa ou gol. Aleatoriedade participa da construção e conclusão, sempre condicionada ao contexto, sem placar sorteado independentemente dos lances.
5. **Registrar e seguir:** atualizar relógio, placar e estatísticas a partir do evento ocorrido; desgaste progride. Estratégia/substituição confirmada modifica somente os setores futuros.

Essa sequência define a lógica de design, não algoritmo, frequência de processamento ou fórmulas. **DECISÃO PENDENTE — P1:** tamanho dos trechos, distribuições de chance/conversão, influência do mando, desgaste e peso relativo dos setores. Devem ser calibrados para placares plausíveis e diferença de qualidade relevante, sem resultados certos.

### Aleatoriedade e justiça

Um clube mais fraco pode vencer por boa cobertura, chance favorável, aproveitamento e defesas, mesmo produzindo menos. O clube melhor deve, em amostra de partidas comparáveis, criar vantagem coerente com suas decisões/qualidade; uma partida não mede esse efeito. Nenhum clube recebe vitória por estar no objetivo da diretoria. Sem roteiro de recuperação, resultado predeterminado para estimular compra ou compensação secreta depois de derrotas.

Todos os jogos da rodada seguem o mesmo modelo de regras, mesmo quando apresentados apenas por resultado. O usuário não recebe probabilidades especiais e rivais não ignoram fadiga. Recarregar uma partida interrompida preserva eventos e situação já vividos; não é uma nova partida destinada a sortear outro placar.

### Eventos, estatísticas e explicação

Eventos mínimos: chance/chute, defesa ou chute para fora/bloqueado, gol, início/intervalo/fim, alteração de estratégia e substituição. Sem comentarista narrando centenas de passes. Gols têm autor pertencente ao time em campo e minuto válido; gol acrescenta uma finalização e finalização no alvo. Estatísticas mínimas: finalizações, no alvo e chances claras por equipe; a definição de chance clara é a qualidade prévia da oportunidade, não se ela virou gol. Não exibir posse se ela não for representada de modo coerente.

Pós-jogo mostra placar, eventos e estatísticas, além de observações ligadas ao que ocorreu: “Criamos poucas oportunidades”; “As chances mais claras vieram depois da mudança”; “O adversário explorou espaços com nossa linha mais avançada”, somente quando esse contexto foi registrado. Dizer que algo contribuiu ou coincidiu com uma mudança; não afirmar que trocar um atleta causaria necessariamente vitória.

Exemplo de derrota explicável: equipe teve mais chutes, mas poucos de boa qualidade; rival aproveitou uma chance clara e seu goleiro fez defesas. O resumo deve sustentar essa leitura com eventos, e não inventar uma desculpa posterior. Não revelar fórmulas internas; explicar conceitos e limites da informação. **DECISÃO PENDENTE — P2:** definição operacional das categorias de chance e vocabulário dos relatos; cada explicação deverá ter suporte verificável no jogo.

## 8. Interface da partida

Tela com placar/nome dos clubes, relógio esportivo, estratégia ativa, lista cronológica de eventos e estatísticas acessíveis sem perder contexto. Identificar claramente primeiro tempo, intervalo e encerramento.

Controles: pausar/retomar, velocidade de apresentação, alterar estratégia/formação e substituir. Ao pausar, relógio e novos eventos param; abrir seleção não consome tempo. Mostrar reservas, condição, posições, atleta a sair e substituições restantes; confirmar antes de aplicar. Depois de três trocas, explicar indisponibilidade do comando.

No intervalo, manter pausa até confirmação de continuar. Após o fim, nenhuma alteração afeta o resultado. Retomar app deve permitir continuar do estado interrompido; nenhuma tela de anúncio ou compra. Sem campo animado 2D/3D; apenas texto, indicadores e desenho estático de escalação quando útil.

**DECISÃO PENDENTE — UI1:** orientação da tela Android, níveis de velocidade, tamanho/agrupamento dos eventos e apresentação acessível em telas pequenas. Validar legibilidade e rapidez sem definir layout copiado de referência.

## 9. Temporada

- Duas divisões, seis clubes em cada; turno e returno, cinco partidas em casa e cinco fora por clube.
- Dez rodadas por divisão; três jogos por rodada e 30 jogos por divisão/temporada, 60 no mundo.
- Vitória: três pontos; empate: um; derrota: zero.
- Desempate: pontos → saldo de gols → gols marcados → número de vitórias → ordem de desempate sorteada e publicada antes da temporada. Essa última ordem permanece estável e não favorece o jogador. Sem partida extra.
- Campeão de cada divisão; primeiro da segunda sobe e último da primeira desce. Segunda divisão não rebaixa para uma terceira inexistente; campeão da primeira não sobe.

Avançar uma rodada conclui todos os jogos e balanços daquele período uma única vez, antes de ofertas/avaliações entre rodadas. Partida do usuário pode ser pausada; tabela fica identificada como parcial enquanto a rodada ainda não terminou. Resultados dos rivais não são jogados novamente ao abrir a tabela.

Transição, em ordem de produto:

1. Encerrar décima rodada, fixar tabela e resultados; registrar campeões e campanhas.
2. Creditar premiação da divisão/posição disputada, uma vez; registrar acesso e rebaixamento.
3. Avaliar treinador pela meta da campanha encerrada; apresentar renovação/não renovação e oportunidades de carreira.
4. Concluir contratos de atletas que vencem, envelhecimento/desenvolvimento e aposentadorias; guardar vínculos/histórico anteriores.
5. Aplicar mudança de divisão, atualizar situação financeira/torcida/reputação e abrir preparação de novo ano.
6. Gerar reposição, permitir mercado/renovações e definir novos objetivos; iniciar calendário com seis clubes por divisão.

Durante encerramento, oferecer ação de renovação antes da efetiva saída dos atletas e decisão de emprego antes da primeira rodada seguinte. Não avançar silenciosamente uma etapa irreversível. Sem salário extra de “11ª rodada” durante menus de pré-temporada: período financeiro regular contém dez cobranças, mais movimentos pontuais.

## 10. Mercado

Janelas: pré-temporada até confirmar a primeira rodada e intervalo entre rodadas cinco e seis. Demissão/contratação do treinador não abre janela de atletas. Renovações do próprio elenco podem ser negociadas fora da janela; compra, venda e contratação de livres ocorrem nas janelas.

**Compra:** selecionar atleta/lista acessível → mostrar referência, salário e custo total estimado → propor taxa ao clube → aceitar/refutar contraproposta → negociar salário/duração com atleta → confirmar movimento. Taxa é paga integralmente na conclusão; até então não mover atleta nem cobrar compra. Recusa salarial não pode consumir a taxa.

**Venda:** listar atleta → receber proposta de comprador com necessidade e recursos → aceitar, recusar ou fazer uma contraproposta → concluir após aceitação das partes. Listar não gera receita garantida; mostrar falta de interessados. Jogador também considera salário/reputação do destino. Não permitir vender atleta de outro clube ou repetir receita do mesmo negócio.

Cada lado pode apresentar **uma contraproposta** por negociação; rejeição encerra aquele processo. Nova negociação exige mudança relevante de proposta/contexto ou próxima janela, evitando tentativas ilimitadas até conseguir dinheiro. Sem taxas por abrir menus ou criar proposta.

Contratos de atletas duram até o fim de uma ou duas temporadas, informando se a atual está incluída. Renovação substitui o vínculo mediante aceitação e informa quando começa o novo salário; proposta de design: novo salário vigora na rodada seguinte, duração conta os encerramentos futuros indicados. Contrato vencido sem renovação torna o atleta livre; não produzir taxa de venda nesse momento. Livre exige salário e vaga, sem taxa a clube e sem bônus de assinatura no MVP.

Atleta pode recusar por remuneração inadequada ou reputação incompatível. Clube vendedor pode recusar por preço, necessidade ou falta de reposição. Sempre informar motivo, sem prometer que a única solução é pagar mais. Limitar opções exibidas não significa bloquear acesso a alternativas econômicas úteis.

**DECISÃO PENDENTE — M1:** quantidade da lista, duração das propostas dentro da janela, faixas de preço/salário, tolerância de contraproposta, critérios de interesse e mudança relevante para nova tentativa. Necessidade e orçamento dos rivais têm precedência sobre venda garantida.

Sem empresários, parcelas, cláusulas complexas, empréstimos, bônus de performance ou leilões online.

## 11. Economia

Uma unidade monetária fictícia, sem câmbio, crédito bancário, moeda premium ou dinheiro pessoal do treinador. Balanço distingue movimentação já realizada e projeção; valor de mercado de atletas não é caixa disponível.

| Movimento | Regra |
|---|---|
| Bilheteria | Receita somente do mandante; público efetivo limitado por capacidade × preço de ingresso fixado pelo design |
| Premiação | Uma vez no encerramento, por divisão e posição; não repetir receita por abrir resultado |
| Salários | Cobrar contratos ativos uma vez por rodada de todo clube, mesmo fora de casa ou durante desemprego do usuário |
| Manutenção | Custo por rodada de operação/estruturas; expansão pode elevar custo posterior |
| Compra/venda | Transferência de caixa entre dois clubes; taxa não cria moeda no mundo |
| Obras | Custo pontual com efeito e prazo; manutenção futura visível |

Preço de ingresso não é mais um controle do jogador no MVP. Finanças mostra saldo anterior, linhas de receitas/despesas, saldo novo e projeção até o fim da temporada. Premiação aparece como intervalo/projeção identificada, não dinheiro já garantido. Compra e expansão são avaliadas contra compromissos e reserva mínima, não somente caixa de hoje.

### Sustentabilidade e limites

- Valores de salário, ingresso e premiação usam referências limitadas e estáveis por faixa/divisão. Não escalar todos os preços com o caixa do usuário ou cada ano.
- Valorização do atleta é limitada por qualidade, idade, contrato e referência econômica, não pelo último preço pago. Compra não aumenta automaticamente valor; listar por preço alto não gera comprador.
- Rivais têm orçamento, necessidade e limites de elenco. Taxas saem do comprador e entram no vendedor; salários saem da economia. Livres não reaparecem como cópias e atleta aposentado não pode ser revendido.
- Bilheteria é limitada por demanda/capacidade; premiação por temporada; crescimento de torcida e estruturas têm teto. Não pagar renda passiva por dia real, posse de caixa ou troca de tela.
- Melhoria aumenta capacidade/custos ou desenvolvimento limitado, sem multiplicar receita automaticamente. Reduzir lista de obras não elimina risco de folha excessiva.
- Cenários iniciais devem suportar campanha ordinária sem título, aumento de torcida ou venda obrigatória. Mostrar alertas de projeção antes de comprometer recursos; evitar insuficiência causada apenas por menus de transição.

Déficit possível: bloquear novas despesas discricionárias, oferecer revisão de contratos/venda na janela e explicar receitas futuras; salários/manutenção continuam registrados como obrigação, sem apagar dívida por trocar de treinador. Não haver dispensa gratuita que cancele salário contratado: atletas podem sair por venda ou vencimento. Incapacidade prolongada leva à avaliação de diretoria/demissão, não ao fim da carreira.

**DECISÃO PENDENTE — F1:** receitas/custos, reserva mínima, limite de déficit, prazo de recuperação e como tratar clube insolvente sem elenco suficiente para cumprir calendário. Definir recuperação interna da diretoria para usuário e rivais, sem aporte repetível explorável, sem apagar obrigações e sem recriar clube. Este é um bloqueio de regra econômica antes de declarar MVP jogável; não pressupor equilíbrio já demonstrado.

## 12. Estádio

Cada clube possui capacidade inicial e demanda estimada. Público de cada jogo depende de torcida, reputação, forma recente, divisão e atratividade do adversário; nunca excede capacidade. Mostrar previsão como estimativa e público realizado no balanço. Estádio maior não cria demanda.

Uma expansão pequena por clube durante toda a carreira do mundo, não renovada ao trocar de treinador ou virar temporada. Antes de confirmar: custo integral, aumento de lugares, prazo em rodadas, manutenção futura e alerta se demanda recente está abaixo da capacidade. Sem editor de estádio ou níveis ilimitados.

Capacidade atual permanece disponível enquanto a obra ocorre; a obra não modela interdição parcial no MVP. Nova capacidade vale depois da conclusão, nunca retroativamente. Obra iniciada fica no clube e continua após demissão/troca. Sem cancelar para recuperar dinheiro após usar benefícios.

**DECISÃO PENDENTE — S1:** capacidades, incremento, custo, duração e manutenção. A contagem de prazo segue rodadas do mundo e atravessa temporadas; abrir/fechar app não conclui obras.

## 13. Torcida

Um indicador agregado limitado, sem seguidores ou redes sociais. Torcida representa interesse potencial; público de cada partida é uma realização dessa demanda. Não somar permanentemente cada ingresso vendido ao número de torcedores.

Resultados recentes afetam interesse de curto prazo de modo moderado. Título/acesso e reputação podem elevar a base no encerramento; rebaixamento e campanha inferior podem reduzi-la, sem zerar torcida. Não multiplicar o mesmo prêmio por título, acesso e reputação sem limite conjunto. Novos patamares financeiros não garantem crescimento permanente.

Torcida tende a estabilizar dentro de limites do mundo e pode regredir. Eventos já avaliados não dão crescimento outra vez ao carregar save. **DECISÃO PENDENTE — TO1:** limites por contexto, velocidade de mudança, amortecimento de sequências e contribuição relativa de reputação/divisão/campanha; distinguir reação temporária e mudança de base sem criar uma segunda tela de gestão.

## 14. Centro de treinamento

Estrutura com situação inicial e **uma melhoria limitada por clube**, persistente no mundo. Sem agenda, exercícios, staff ou bônus diário. Mostrar custo, prazo de obra e benefício esperado como auxílio ao desenvolvimento anual, não aumento instantâneo de overall.

Evolução no fechamento combina idade, potencial, condição de desenvolvimento e treino; qualidade tem teto e veteranos podem declinar apesar de boa estrutura. Uma obra concluída pouco antes do fechamento não concede o benefício de um ano completo: contribuição considera o período ativo. Não repetir evolução ao visitar tela ou carregar save.

**DECISÃO PENDENTE — CT1:** custo/prazo, manutenção, magnitude do efeito, influência de utilização esportiva e tempo elegível de treino quando um atleta muda de clube. Registrar contexto suficiente para aplicar evolução uma vez, sem garantir crescimento de todo atleta.

## 15. IA dos clubes

Comportamento mínimo, com mesmas restrições financeiras e esportivas do usuário:

- Escalar onze válidos por adequação, qualidade e condição; escolher uma das três formações e estratégias conforme recursos e contexto.
- Reagir ao placar/tempo/fadiga, fazer até três substituições e evitar atletas fora de posição quando existe alternativa melhor.
- Identificar faltas de cobertura, negociar poucos reforços e vender excedentes quando há interessados; considerar custo total e necessidade, não comprar tudo listado pelo usuário.
- Renovar atletas úteis e acessíveis antes do vencimento; contratar livres para reposição, sem gerar atletas gratuitos privilegiados.
- Projetar caixa e manter reserva; escolher entre elenco e melhoria limitada, sem endividamento exponencial ou obras simultâneas sem capacidade.
- Aplicar envelhecimento, treino, aposentadoria e reposição pelas mesmas regras; manter histórico e mudanças de divisão.

Treinadores rivais são **vínculos gerenciais simplificados**, suficientes para ocupar/liberar vagas. Não criar personagens completos, salários ou carreiras simuladas equivalentes ao usuário. Diretorias podem trocar vínculo após má campanha, abrindo oportunidades; não manter uma vaga por demissão em todas as rodadas para fabricar propostas.

Ao usuário sair, o clube recebe gestão rival com seus dados atuais, sem reset de caixa, estrutura, confiança institucional ou elenco. Ao entrar, o usuário herda essa situação, explicitada na proposta. **DECISÃO PENDENTE — IA1:** frequência/limites de negociações e trocas de treinador, prioridades de investimento e preenchimento das vagas compatível com reentrada garantida na preparação anual.

## 16. Save — continuidade de produto

Save local deve preservar:

- Identidade/reputação do treinador, emprego ou desemprego, contrato, objetivos, confiança/avisos, propostas e histórico/títulos.
- Todos os clubes: divisão, reputação, torcida, caixa/obrigações, folha, estádio, treino, obras com prazo e melhoria já utilizada, vínculos gerenciais e histórico.
- Todos os atletas: identidade, posição, idade, qualidade/potencial/condição, clube ou condição livre, contrato/salário e contexto anual necessário à evolução.
- Temporada/rodada/etapa de transição, calendário, resultados, tabela e ordem final de desempate; premiações/evoluções já processadas.
- Escalação/formação/estratégia e negociações ativas com prazo, estágio e valores; não perder uma contraproposta ao sair do app.
- Partida interrompida: minuto, placar, atletas em campo/banco, condição, substituições usadas, eventos/estatísticas e continuidade da simulação. Estado necessário para não duplicar evento ou sortear novamente ações passadas.
- Preferências relevantes de apresentação e ponto de retomada.

Sair/retomar não movimenta calendário ou dinheiro por tempo real. Continuar deve retornar à mesma carreira; nova carreira exige confirmação de descarte se houver apenas um espaço. **DECISÃO PENDENTE — SV1:** quantidade de espaços e comportamento de substituição/recuperação de save interrompido. Um espaço funcional com proteção contra perda acidental é suficiente ao MVP; formato, armazenamento e solução técnica ficam para arquitetura posterior. Não prometer cloud save, portabilidade ou compatibilidade futura ainda não definida.

## 17. Telas e responsabilidades

São destinos funcionais; agrupamento em abas/menus pode ser resolvido depois sem criar funcionalidades.

| Tela | Responsabilidade |
|---|---|
| Início | Continuar carreira ou iniciar criação com confirmação quando necessário |
| Criação/escolha | Nome do treinador, três perfis, clubes e resumo das consequências; aceitar primeiro contrato |
| Home da carreira | Próxima ação/rodada, situação do emprego, objetivo, alertas e avanço controlado |
| Perfil/histórico do treinador | Reputação, contrato, passagens, títulos e motivos de saída |
| Empregos | Renovação, propostas e vagas; aceitar/recusar/candidatar-se e avançar calendário sem clube |
| Clube | Identidade, divisão, torcida, reputação e expectativa/confiança da diretoria |
| Elenco/atleta | Dezoito vagas, condição, qualidade, contrato e ações de renovação/listagem |
| Escalação | Onze, banco, formação e estratégia; validar adequação antes de jogar |
| Mercado/negociação | Listas acessíveis, livres, ofertas, contraproposta, salário e custo completo |
| Partida/resultado | Acompanhar e intervir; resumo final, estatísticas e ação para concluir rodada |
| Temporada/tabela | Calendário, resultados, classificação, desempates e acesso/rebaixamento |
| Finanças | Balanço por rodada, caixa, folha/compromissos e previsão |
| Estrutura | Capacidade/demanda e treino; comparar custo/prazo e acompanhar melhoria limitada |
| Encerramento | Campanha, prêmio, mudanças de divisão, contratos e passagem para próximo ano |

Não criar feed social, imprensa, loja ou painéis de dados sem ação útil. Alertas de bloqueio dizem como resolvê-los; desemprego troca ações de clube por carreira/vagas.

## 18. Primeira experiência

1. **Abrir:** mostrar “Nova carreira” ou “Continuar”, sem conta, download de banco esportivo ou anúncio.
2. **Criar:** informar nome; explicar em uma frase que a carreira continua ao trocar de clube.
3. **Escolher:** selecionar pequeno, médio ou elite, depois um clube disponível; comparar recursos e cobrança, sem prometer superioridade comercial de um perfil.
4. **Conhecer objetivo:** mostrar meta, duração do contrato, caixa/folha e situação inicial; confirmar o emprego. Disponibilizar detalhes sem obrigar leitura extensa.
5. **Escalar:** oferecer onze válidos sugeridos e estratégia equilibrada; destacar vagas/setores e permitir alterar. Informar que o usuário pode pausar e substituir.
6. **Primeira partida:** iniciar rodada um após confirmação. Não obrigar negociação ou obra para conseguir jogar. Evento, relógio e placar mostram futebol rapidamente.
7. **Resultado:** apresentar placar/estatísticas e uma observação sustentada por eventos; abrir balanço da rodada.
8. **Finanças:** mostrar salários/manutenção e bilheteria quando for mandante. Se visitante, explicar ausência dessa receita; confirmar uma cobrança por rodada, sem punição oculta.
9. **Próxima rodada:** voltar à Home com condição recuperada/projetada, próxima escalação e tabela. Mercado inicial continua acessível antes do primeiro jogo, mas pode ser ignorado; depois, próxima compra fica para janela intermediária.

Tutorial contextual curto e dispensável; não bloquear veteranos. **DECISÃO PENDENTE — PE1:** tempo-alvo até primeira partida e quantidade de instruções após teste de compreensão. Metas de sessão do conceito não substituem medição da primeira experiência.

## 19. Balanceamento e decisões pendentes

Não há valores definitivos de moeda, atributos ou probabilidades nesta v1. Quantidades estruturais aprovadas — 12 clubes, duas divisões, dez rodadas, elenco de 18, onze titulares, três estratégias e até três substituições — definem escopo, não provam equilíbrio.

| Grupo | Variáveis a calibrar |
|---|---|
| Carreira (C1/C2) | Reputação inicial, mudanças/tetos/faixas, compatibilidade de ofertas, confiança, janela de avaliação, avisos e recuperação; vagas e espera por contratação |
| Clubes (CL1) | Distribuição de perfis, metas por divisão, qualidade, caixa, folha, torcida e infraestrutura iniciais |
| Atletas (J1/E1) | Escalas/limites de qualidade/potencial, idade, evolução, declínio, aposentadoria, composição por posição, reposição/livres e perda/recuperação de condição |
| Tática/partida (T1/P1/P2) | Adequação de posição, contribuição dos setores/goleiro, formação, criação/cobertura/transição, esforço, mando, quantidade/qualidade de chances, conversão, defesas e variância |
| Mercado (M1) | Quantidade/variedade acessível, preço/salário/valorização, interesse de atletas/compradores, contraproposta, prazo e renovação |
| Finanças (F1) | Ingresso, premiação por divisão/posição, manutenção, salários, obras, reserva, déficit e recuperação; oferta de moeda versus despesas no mundo |
| Estruturas/torcida (S1/TO1/CT1) | Capacidade, demanda, limites de torcida, reação aos resultados/títulos/acesso/queda, custo/prazo único das melhorias, manutenção e desenvolvimento anual |
| Rivais (IA1) | Frequência de movimentos, reserva, prioridade de elenco/obra, contratos e abertura/preenchimento de vagas |
| Experiência (UI1/SV1/PE1) | Velocidade/ritmo de eventos, legibilidade, orientação, espaços/proteção de save, instruções e tempo até futebol |

Pendências qualitativas de produto estão identificadas nas seções correspondentes, especialmente primeira contratação em elite (C2), recuperação de insolvência (F1) e continuidade do emprego (C2/IA1). Resolvê-las antes da implementação das partes afetadas; não substituí-las por fórmulas arbitrárias nesta etapa.

Futura validação precisa observar distribuição de placares e surpresas, eficácia situacional das táticas, facilidade de entender gastos e confiança, solvência de todos os clubes por temporadas, concentração de dinheiro/qualidade e interesse em continuar após fracasso. Medir conclusão de rodada/temporada, retorno voluntário e variedade de escolhas sem confundir teste pequeno com retenção comercial. Não exige backend ou SDK de analytics no MVP.

Reavaliar o recorte se decisões não mudam a experiência, a economia exige resgates recorrentes, o resultado não é compreensível, a demissão elimina interesse ou o jogador exige nomes reais/visual de campo para se divertir. Não acrescentar sistemas para mascarar essas falhas.

## 20. Fora do MVP

Copa nacional; competições continentais; seleções; outras nações/divisões; categorias de base completas; patrocinadores; seguidores; staff; agentes/empresários; imprensa; multiplayer; backend; cloud save; editor/datapacks; partidas animadas 2D/3D; controle direto de atletas; monetização de qualquer tipo; clubes/jogadores reais; conteúdo ou bancos licenciados/proprietários.

Também ficam fora: lesões, cartões/suspensões, treino diário, subatributos técnicos individuais, economia pessoal do treinador, empréstimos, parcelas, cláusulas complexas e melhorias ilimitadas. Reposição anual não é academia de base. Diagrama estático de formação não é apresentação animada da partida.

## 21. Critérios de MVP jogável

Só declarar **“Club Legacy MVP está jogável”** depois de verificar o seguinte no Android, com regras pendentes essenciais resolvidas e sem alegar build/teste antes de executá-los:

- Criar treinador e iniciar com cada perfil; objetivos, recursos e contrato aparecem antes do primeiro jogo; escalação válida leva à partida sem negociação obrigatória.
- Escalar onze/banco, escolher formação/estratégia, jogar com relógio/eventos/estatísticas coerentes, pausar/retomar e fazer até três substituições; decisões alteram contexto futuro sem mudar eventos passados.
- Comprar, vender, receber/recusar contraproposta, acertar salário/duração, renovar e contratar livre; impedir duplicação de atleta/dinheiro, venda sem comprador ou movimento fora da janela.
- Administrar caixa e folha, entender balanço/projeção, investir em estádio/treino com custo e prazo; estádio vazio não ganha público automaticamente e melhoria não reaparece após troca de clube.
- Completar dez rodadas com cinco jogos em casa/fora e seis clubes por divisão; validar pontuação/desempates, campeão, prêmio único, um acesso e um rebaixamento; manter seis clubes em cada divisão seguinte.
- Percorrer renovação, não renovação e demissão com aviso/motivo; sair de um emprego, permanecer desempregado, ser contratado e trocar de clube; treinador mantém histórico e clube mantém patrimônio/obrigações.
- Continuar por ao menos cinco temporadas em verificação de integridade, incluindo envelhecimento, contratos, aposentadoria/reposição e mundo adversário; ao menos três temporadas em observação de uso, conforme conceito. Isso não comprova interesse por décadas nem viabilidade comercial.
- Salvar/carregar carreira empregada/desempregada, negociação, obra e partida interrompida; preservar minutos/eventos, não pagar prêmio/salário duas vezes nem refazer evolução/transição já concluída.
- Percorrer campanha ruim, rebaixamento, déficit e reentrada no emprego sem carreira bloqueada ou calendário inválido. Todos os clubes obedecem aos limites; nenhuma falha crítica impede concluir o loop e continuar o save.
- Executar núcleo completo offline, sem conta, backend, anúncios, compras ou recursos esportivos reais. Registrar evidência dos testes e limitações; pendências de equilíbrio podem existir, mas não regras essenciais indefinidas ou perda de progresso.

**Estado desta entrega:** documentação de design apenas. Nenhum critério acima foi testado nesta tarefa. O documento termina aqui para revisão humana; não inicia arquitetura, código, projeto Godot, banco de dados ou monetização.
