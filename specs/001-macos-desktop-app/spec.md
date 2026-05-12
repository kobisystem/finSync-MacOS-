# Feature Specification: FinSync macOS Desktop App

**Feature Branch**: `001-macos-desktop-app`  
**Created**: 2026-05-05  
**Status**: Draft  
**Input**: User description: "Criar o FinSync macOS, um aplicativo nativo instalavel para macOS que funciona como interface desktop do FinSync existente, com autenticacao, consulta de dados financeiros ja processados, importacoes, revisao de classificacoes, KPIs mensais, previsao de fluxo de caixa, auditoria, isolamento por account owner e sem backend proprio nesta fase."

## Clarifications

### Session 2026-05-05

- Q: Qual deve ser o limite de armazenamento local de dados financeiros? → A: Permitir cache local protegido de dados financeiros recentes, apagado no logout.
- Q: Qual deve ser a consequencia de correcoes de categoria sobre regras de classificacao? → A: Correcoes alteram a transacao atual e podem sugerir regra, mas so criam regra com confirmacao explicita.
- Q: Quando o app deve atualizar os dados financeiros exibidos? → A: Atualizar ao abrir o app, ao voltar para a janela e por acao manual.
- Q: Como o app deve lidar com conflito durante a revisao de classificacao? → A: Bloquear o salvamento, recarregar os dados e pedir nova confirmacao do usuario.
- Q: Como o app deve tratar agregacoes quando houver moedas diferentes? → A: Separar agregacoes por moeda e nao somar moedas diferentes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Acessar dados financeiros com sessao segura (Priority: P1)

Como account owner, quero abrir o FinSync no macOS, autenticar minha conta e ver apenas meus dados financeiros, para usar o app desktop sem expor informacoes antes do login ou de outra pessoa.

**Why this priority**: Autenticacao, sessao e isolamento de dados sao pre-condicoes para qualquer valor financeiro do produto.

**Independent Test**: Pode ser testado instalando o app, abrindo-o sem sessao, tentando acessar telas financeiras, autenticando com uma conta valida e confirmando que apenas dados vinculados ao usuario autenticado aparecem.

**Acceptance Scenarios**:

1. **Given** o app foi aberto sem sessao autenticada, **When** o usuario visualiza a janela inicial, **Then** nenhum dado financeiro, KPI, transacao, conta, importacao ou forecast e exibido.
2. **Given** o usuario informa credenciais validas, **When** a autenticacao e concluida, **Then** o app mostra a area autenticada com dados pertencentes somente ao account owner da sessao.
3. **Given** a sessao expirou, **When** o usuario tenta atualizar ou abrir uma tela financeira, **Then** o app bloqueia os dados protegidos, informa que a sessao expirou e permite nova autenticacao.
4. **Given** uma consulta nao tem permissao para retornar dados, **When** a tela tenta carregar informacoes, **Then** o app exibe erro de permissao sem revelar conteudo financeiro parcial.

---

### User Story 2 - Acompanhar a saude financeira do mes (Priority: P1)

Como account owner, quero ver um dashboard do mes atual com resultado liquido, receitas, despesas, pendencias de revisao, importacoes recentes, confianca do forecast e horario da ultima atualizacao, para entender rapidamente minha situacao financeira.

**Why this priority**: O dashboard e a principal experiencia recorrente e concentra os sinais que orientam as proximas acoes do usuario.

**Independent Test**: Pode ser testado com uma conta autenticada que tenha transacoes, importacoes e forecasts existentes, validando os numeros exibidos e os estados vazios quando nao houver dados.

**Acceptance Scenarios**:

1. **Given** o usuario autenticado possui dados no mes atual, **When** abre o dashboard, **Then** ve receitas, despesas, resultado liquido, pendencias de revisao, importacoes recentes, confianca do forecast e ultima atualizacao.
2. **Given** existem transacoes do tipo pagamento de cartao, **When** o dashboard calcula despesas do mes, **Then** esses pagamentos nao sao apresentados como despesa comum duplicada.
3. **Given** nao ha dados financeiros processados para o usuario, **When** o dashboard carrega, **Then** o app mostra um estado vazio claro sem inventar valores ou previsoes.
4. **Given** o usuario abre o app, retorna para a janela ou aciona atualizacao manual, **When** dados protegidos precisam ser atualizados, **Then** o app tenta atualizar as informacoes e reflete o horario da ultima atualizacao bem-sucedida.
5. **Given** a atualizacao falha por rede indisponivel, **When** o dashboard tenta carregar, **Then** o app mostra o ultimo estado conhecido se disponivel, indica que os dados podem estar desatualizados e oferece nova tentativa.

---

### User Story 3 - Revisar classificacoes pendentes sem perder contexto (Priority: P1)

Como account owner, quero revisar transacoes marcadas como pendentes, confirmar ou corrigir categorias e voltar ao dashboard mantendo o contexto, para melhorar a qualidade dos meus indicadores sem perder fluidez.

**Why this priority**: A revisao corrige a principal fonte de incerteza dos KPIs e forecasts, preservando rastreabilidade.

**Independent Test**: Pode ser testado com transacoes em status needs_review, categorias ativas e classificacoes existentes, confirmando que a classificacao ativa muda corretamente e que o historico permanece.

**Acceptance Scenarios**:

1. **Given** ha transacoes com revisao pendente, **When** o usuario abre a tela de revisao, **Then** ve a lista de pendencias com descricao, data, valor, conta, categoria sugerida, confianca e explicacao disponivel.
2. **Given** o usuario confirma uma categoria sugerida, **When** salva a revisao, **Then** a transacao passa para reviewed, a classificacao ativa e preservada ou atualizada conforme necessario, e um evento de auditoria e registrado.
3. **Given** o usuario escolhe outra categoria ativa, **When** salva a correcao, **Then** a classificacao anterior deixa de ser ativa, a nova classificacao vira a unica ativa, o historico e preservado e um evento de auditoria e registrado.
4. **Given** uma correcao de categoria indica um padrao reaproveitavel, **When** o app sugere criar uma regra de classificacao, **Then** a regra so e criada se o usuario confirmar explicitamente.
5. **Given** a transacao ou classificacao mudou depois que a tela de revisao foi carregada, **When** o usuario tenta salvar uma revisao, **Then** o app bloqueia o salvamento, recarrega os dados atuais e pede nova confirmacao do usuario.
6. **Given** o usuario abriu a revisao a partir do dashboard, **When** conclui ou cancela a revisao, **Then** consegue retornar ao dashboard mantendo o periodo e o contexto anterior.

---

### User Story 4 - Consultar importacoes, contas e transacoes (Priority: P2)

Como account owner, quero consultar arquivos importados, contas e transacoes com filtros, para investigar origem dos dados, pendencias, erros e movimentos financeiros.

**Why this priority**: A consulta detalhada permite explicar os numeros agregados e diagnosticar problemas de importacao.

**Independent Test**: Pode ser testado carregando listas de importacoes, contas e transacoes, aplicando filtros combinados e verificando detalhes sem editar fatos imutaveis.

**Acceptance Scenarios**:

1. **Given** existem arquivos importados em diferentes estados, **When** o usuario abre importacoes, **Then** ve arquivos pending, processing, processed, ignored e error com status, motivo acionavel, datas relevantes, emissor/layout detectado quando disponivel e historico recente.
2. **Given** existem contas bancarias e cartoes, **When** o usuario abre contas, **Then** ve instituicao, nome exibido, tipo, moeda e identificador mascarado.
3. **Given** existem transacoes importadas, **When** o usuario filtra por periodo, conta, categoria, tipo, origem ou status de revisao, **Then** a lista mostra apenas transacoes correspondentes e mantem fatos financeiros originais somente leitura.
4. **Given** uma transacao possui arquivo de origem, conta, fatura ou classificacao, **When** o usuario abre seu detalhe, **Then** o app mostra os relacionamentos relevantes sem expor conteudo bruto sensivel.

---

### User Story 5 - Analisar KPIs mensais e forecast (Priority: P2)

Como account owner, quero ver KPIs mensais, principais categorias, evolucao por mes e forecast de fluxo de caixa, para planejar decisoes financeiras com base nos dados ja processados.

**Why this priority**: KPIs e forecast transformam dados importados em decisao recorrente, mas dependem de dados autenticados e classificados.

**Independent Test**: Pode ser testado com meses de historico variados, incluindo menos de 3 meses, 3 a 11 meses e 12 ou mais meses.

**Acceptance Scenarios**:

1. **Given** ha transacoes classificadas em varios meses, **When** o usuario abre KPIs mensais, **Then** ve receitas, despesas, resultado liquido, principais categorias e evolucao mensal.
2. **Given** ha forecasts existentes, **When** o usuario abre previsao de fluxo de caixa, **Then** ve receitas, despesas, obrigacoes de cartao, resultado liquido projetado, saldo projetado, confianca, resumo da base usada e data de geracao.
3. **Given** o usuario tem menos de 3 meses de historico elegivel, **When** consulta forecast mensal, **Then** o app informa que nao ha base suficiente para previsao mensal.
4. **Given** o usuario tem de 3 a 11 meses de historico elegivel, **When** consulta forecast, **Then** o app apresenta a confianca como baixa quando houver forecast existente.
5. **Given** o usuario tem 12 ou mais meses de historico elegivel, **When** consulta forecast, **Then** o app respeita a confianca existente normal ou alta sem recalcular localmente.

---

### User Story 6 - Consultar auditoria sem dados sensiveis brutos (Priority: P3)

Como account owner, quero consultar eventos relevantes de importacao, erro, classificacao, correcao e forecast, para entender o que aconteceu sem expor conteudo bruto sensivel.

**Why this priority**: Auditoria aumenta confianca e suporte a diagnostico, mas e secundaria em relacao ao uso financeiro diario.

**Independent Test**: Pode ser testado abrindo eventos de auditoria associados a entidades financeiras e confirmando que os metadados estao redigidos.

**Acceptance Scenarios**:

1. **Given** existem eventos de auditoria para o usuario, **When** abre a tela ou detalhe de auditoria, **Then** ve tipo de evento, ator, entidade relacionada, data e metadados redigidos.
2. **Given** um evento referencia importacao, transacao, classificacao, forecast ou fatura, **When** o usuario abre o evento, **Then** consegue entender o contexto sem visualizar conteudo bruto de documentos.

### Edge Cases

- Usuario autenticado sem account owner associado: o app deve bloquear telas financeiras e exibir orientacao de suporte ou configuracao indisponivel.
- Usuario autenticado sem dados processados: todas as telas financeiras devem apresentar estados vazios especificos por contexto.
- Sessao expirada durante uma acao de revisao: a acao nao deve ser confirmada parcialmente; o usuario deve reautenticar e repetir ou retomar com dados atualizados.
- Conflito durante revisao: se a transacao, o status de revisao ou a classificacao ativa mudar desde o carregamento, o app deve bloquear o salvamento, recarregar os dados atuais e pedir nova confirmacao.
- Falha de rede, servico indisponivel ou tempo limite: o app deve exibir erro recuperavel, preservar a navegacao e permitir nova tentativa.
- Logout do usuario: o app deve apagar o cache local protegido de dados financeiros recentes antes de retornar ao estado nao autenticado.
- Permissoes insuficientes ou tentativa de acesso a dados de outro account owner: nenhum dado deve ser exibido e o evento deve ser tratado como acesso negado.
- Importacao em processamento por muito tempo: a tela deve mostrar status atual, ultimo horario conhecido e mensagem acionavel quando houver.
- Arquivo em error ou ignored que voltou para processing: a tela deve refletir o estado mais recente e manter historico relevante.
- Transacao com baixa confianca ou categoria ausente: deve aparecer como pendente de revisao quando o status indicar needs_review.
- Transacao reviewed que voltou para needs_review: deve voltar a aparecer na fila de revisao.
- Fatura de cartao sem status definitivo: deve ser mostrada como unknown ou open sem assumir pagamento.
- Categoria inativa usada em classificacao historica: historico pode mostrar a categoria, mas novas correcoes devem priorizar categorias ativas.
- Dados monetarios em moeda diferente do padrao: o app deve exibir a moeda registrada, separar agregacoes por moeda e nao somar moedas diferentes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O app MUST ser um software desktop nativo instalavel para macOS, com experiencia integrada ao ambiente desktop e sem funcionar como uma aplicacao web empacotada.
- **FR-002**: O app MUST exigir autenticacao antes de exibir qualquer dado financeiro, operacional ou de auditoria do usuario.
- **FR-003**: O app MUST manter sessao autenticada entre aberturas quando permitido e bloquear dados protegidos quando a sessao expirar ou for invalidada.
- **FR-004**: O app MUST filtrar todas as informacoes financeiras, operacionais e de auditoria pelo account owner autenticado.
- **FR-005**: O app MUST mostrar estados de carregamento, erro recuperavel, ausencia de dados, sessao expirada e permissao insuficiente em todas as telas que consultam dados protegidos.
- **FR-006**: O app MUST exibir, em telas agregadas e detalhadas, quando os dados foram atualizados ou gerados pela ultima vez.
- **FR-006a**: O app MAY manter cache local protegido de dados financeiros recentes para continuidade da experiencia, desde que o cache seja apagado no logout e nunca seja exibido antes de uma sessao autenticada valida.
- **FR-006b**: O app MUST tentar atualizar dados protegidos ao abrir o app autenticado, ao retornar para a janela ativa e quando o usuario acionar atualizacao manual.
- **FR-007**: O app MUST oferecer um dashboard inicial do mes atual com receitas, despesas, resultado liquido, pendencias de revisao, importacoes recentes, confianca do forecast e ultima atualizacao.
- **FR-008**: O app MUST excluir transacoes do tipo card_payment de despesas comuns quando isso causaria duplicidade com compras de cartao ja contabilizadas.
- **FR-009**: O app MUST permitir navegar do dashboard para revisao de classificacoes pendentes e retornar mantendo periodo e contexto visual relevantes.
- **FR-010**: O app MUST listar import files com status pending, processing, processed, error e ignored, incluindo status, motivo acionavel, metadados disponiveis e horarios de processamento quando existirem.
- **FR-011**: O app MUST representar as transicoes validas de importacao e refletir reprocessamentos de error ou ignored para processing e processed quando os dados existentes indicarem essa evolucao.
- **FR-012**: O app MUST listar accounts bancarias e cartoes com instituicao, nome exibido, tipo, moeda e identificador sempre mascarado.
- **FR-013**: O app MUST permitir consultar transactions por periodo, conta, categoria, tipo, origem e status de revisao.
- **FR-014**: O app MUST exibir fatos financeiros imutaveis de transacoes como somente leitura, incluindo valor, data original, descricao original e arquivo de origem.
- **FR-015**: O app MUST permitir revisar transactions com status needs_review, incluindo confirmacao da classificacao sugerida ou escolha de categoria ativa diferente.
- **FR-016**: O app MUST garantir que, apos uma correcao ou confirmacao de classificacao, exista apenas uma classificacao ativa por transacao.
- **FR-017**: O app MUST preservar historico de classificacoes ao corrigir categorias, sem apagar classificacoes anteriores.
- **FR-018**: O app MUST registrar ou refletir evento de auditoria para correcao ou confirmacao feita pelo usuario quando a acao modificar o estado de revisao ou a classificacao ativa.
- **FR-018a**: O app MAY sugerir a criacao de regra de classificacao a partir de uma correcao de categoria, mas MUST criar a regra somente apos confirmacao explicita do usuario.
- **FR-018b**: O app MUST bloquear o salvamento de revisao quando detectar que a transacao, o status de revisao ou a classificacao ativa mudou desde o carregamento, recarregando os dados e solicitando nova confirmacao do usuario.
- **FR-019**: O app MUST exibir categorias ativas usadas nas classificacoes, incluindo hierarquia quando disponivel.
- **FR-020**: O app MUST exibir KPIs mensais com receitas, despesas, resultado liquido, principais categorias e evolucao por mes.
- **FR-020a**: O app MUST separar agregacoes financeiras por moeda e MUST NOT somar valores de moedas diferentes em um unico total.
- **FR-021**: O app MUST exibir forecasts mensais existentes com receitas, despesas, obrigacoes de cartao, resultado liquido projetado, saldo projetado, confianca, resumo da base usada e data de geracao.
- **FR-022**: O app MUST comunicar que nao ha forecast mensal quando houver menos de 3 meses de historico elegivel.
- **FR-023**: O app MUST tratar forecasts com 3 a 11 meses de historico como baixa confianca quando esse contexto estiver disponivel nos dados.
- **FR-024**: O app MUST respeitar a confianca existente dos forecasts para usuarios com 12 ou mais meses de historico, sem recalcular ou sobrescrever a confianca localmente.
- **FR-025**: O app MUST permitir consultar eventos de auditoria relevantes para importacoes, falhas, deduplicacoes, classificacoes, correcoes e geracao de forecast.
- **FR-026**: O app MUST exibir auditoria somente com metadados redigidos, sem conteudo bruto sensivel de documentos, arquivos ou identificadores.
- **FR-027**: O app MUST impedir lancamento manual de transacoes, processamento local de OFX ou PDF, criacao de backend proprio e edicao de fatos financeiros imutaveis no escopo inicial.
- **FR-028**: O app MUST evitar exibir identificadores sensiveis sem mascaramento em qualquer tela, erro, detalhe, exportacao visual ou historico.

### Key Entities *(include if feature involves data)*

- **Account Owner**: Pessoa autenticada dona dos dados financeiros; define o isolamento de todas as consultas e a sessao visivel no app.
- **Account**: Conta bancaria ou cartao de credito; inclui tipo, instituicao, nome exibido, identificador mascarado e moeda.
- **Import File**: Arquivo detectado e processado externamente; possui metadados, status, motivos acionaveis, emissor/layout detectado e horarios.
- **Transaction**: Movimento financeiro normalizado; contem fatos imutaveis, tipo, conta, arquivo de origem, possivel fatura e status de revisao.
- **Credit Card Statement**: Fatura mensal de cartao; contem periodo, vencimento, total, status e relacao com compras e pagamentos de cartao.
- **Category**: Categoria visivel para receitas e despesas, com suporte a hierarquia e estado ativo.
- **Transaction Classification**: Categoria atribuida a uma transacao; possui origem, confianca, explicacao, indicador de ativa e historico.
- **Classification Rule**: Regra deterministica existente que pode explicar classificacoes e correcoes anteriores.
- **Cash Flow Forecast**: Previsao mensal existente; inclui componentes confirmados, previstos e estimados, resultado projetado, saldo projetado, confianca e resumo da base.
- **Audit Event**: Registro redigido de eventos relevantes; referencia entidades financeiras sem armazenar conteudo bruto sensivel.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das tentativas de abrir telas financeiras sem autenticacao exibem bloqueio de acesso sem mostrar dados financeiros.
- **SC-002**: Em testes com dados de dois account owners, 100% das telas exibem somente registros do usuario autenticado.
- **SC-003**: Um usuario recorrente consegue abrir o app autenticado e identificar resultado liquido, pendencias de revisao e ultima atualizacao em ate 30 segundos.
- **SC-004**: 90% das revisoes de classificacao pendente podem ser concluidas em ate 3 interacoes apos abrir a fila de revisao.
- **SC-005**: 100% das correcoes de classificacao testadas preservam historico e deixam exatamente uma classificacao ativa por transacao.
- **SC-006**: Em cenarios com pagamentos de cartao e compras da fatura, 100% dos dashboards e KPIs evitam duplicar card_payment como despesa comum.
- **SC-007**: 95% das consultas de listas comuns com ate 1.000 registros visiveis apresentam carregamento, resultado ou erro em ate 3 segundos em condicoes normais de conexao.
- **SC-008**: 100% dos estados de ausencia de dados, falha de rede, sessao expirada e permissao insuficiente apresentam mensagem compreensivel e uma acao clara quando houver recuperacao possivel.
- **SC-009**: 100% das telas que mostram dados agregados ou forecasts indicam ultima atualizacao, periodo de referencia ou data de geracao.
- **SC-010**: Em validacao com usuarios-alvo, pelo menos 80% conseguem localizar uma importacao com erro, revisar uma classificacao pendente e consultar forecast sem instrucao externa.

## Assumptions

- O app usara o backend e o repositorio de dados financeiro existentes; a criacao de novos servicos de backend esta fora do escopo inicial.
- Os dados financeiros ja foram processados e populados antes de serem consultados pelo app.
- O usuario-alvo e o proprio account owner, sem papeis administrativos multiusuario no escopo inicial.
- O app precisa de conexao de rede para consultar dados atuais; visualizacao offline completa nao faz parte do escopo inicial.
- A atualizacao de dados deve ocorrer ao abrir o app, ao voltar para a janela e por acao manual; atualizacao continua em intervalo fixo nao faz parte do escopo inicial.
- O app pode manter cache local protegido de dados financeiros recentes apenas para continuidade de experiencia, sem substituir a fonte oficial dos dados, e deve apagar esse cache no logout.
- O idioma inicial da experiencia e portugues do Brasil.
- Valores financeiros devem preservar a moeda registrada; somatorios e KPIs agregados devem ser separados por moeda e nao devem somar moedas diferentes.
- A gestao avancada de regras de classificacao nao faz parte do escopo inicial; correcoes de categoria podem sugerir criacao de regra, mas a criacao exige confirmacao explicita do usuario.
