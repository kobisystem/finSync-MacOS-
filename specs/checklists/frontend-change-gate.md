# Checklist: Gate de Mudanças de Front-End (finSync-MacOS)

Use este checklist antes de implementar qualquer alteração de front-end no `finSync-MacOS`.

## 1. Escopo e Contrato

- [ ] A mudança é de UX/apresentação no cliente macOS.
- [ ] Se houver impacto em regra de negócio financeira, existe spec/contrato atualizado no `finSync` antes da implementação no cliente.
- [ ] A mudança não redefine no cliente semânticas de `forecast`, `KPI`, `classification` ou `audit`.

## 2. Integridade de Fatos Financeiros

- [ ] Não existe caminho para editar fatos financeiros imutáveis (`amount`, `date`, `description`, `source ids`).
- [ ] Apenas mutações já previstas pelo engine são expostas (ex.: correção de classificação/categoria).

## 3. Isolamento e Segurança

- [ ] Leituras e mutações respeitam `account_owner_id`.
- [ ] Sessão protegida (ex.: Keychain) e cache local protegido por conta.
- [ ] Logout limpa sessão e cache derivado.
- [ ] Logs/diagnósticos não expõem dados financeiros sensíveis desnecessários.

## 4. Estados de UI Obrigatórios

- [ ] Fluxo/tela impactado cobre estados `loading`, `success`, `empty`, `error`.
- [ ] Erros são explícitos e acionáveis para o usuário.
- [ ] Conflitos de mutação (concorrência/retry) possuem tratamento claro.

## 5. Usabilidade e Acessibilidade

- [ ] Fluxo principal preserva legibilidade para tomada de decisão financeira.
- [ ] Navegação por teclado e acessibilidade básica (labels/semântica) continuam válidas em telas críticas.
- [ ] Em visões de forecast, `confidence` e `calculation basis` permanecem visíveis quando aplicável.

## 6. Performance (Constitution Gates)

- [ ] Dashboard acionável em até 30 segundos.
- [ ] Listas comuns (até ~1000 linhas visíveis) resolvem em até 3 segundos em conectividade normal.
- [ ] Ação de review concluída em até 3 interações após abrir a fila.

## 7. Qualidade e Testes

- [ ] XCTest atualizado para lógica/view-model impactada.
- [ ] XCUITest atualizado para fluxo crítico impactado.
- [ ] Cobertura inclui isolamento por usuário, sessão expirada, erro de rede e reconciliação de totais/KPIs/forecast.

## 8. Governança SpecKit

- [ ] Fluxo seguido: Spec -> Clarify -> Plan -> Tasks -> Implement.
- [ ] Se o comportamento pretendido mudou, specs/contratos foram atualizados no repositório correto.
- [ ] Regra de fronteira respeitada: engine define regra; macOS consome contrato.

## Referências

- `finSync-MacOS/.specify/memory/constitution.md`
- `finSync/.specify/memory/constitution.md` (Boundary Contract)

## Uso sugerido

1. Execute este checklist no início da feature.
2. Revalide antes de abrir PR.
3. Anexe o status do checklist na descrição da PR quando houver impacto em fluxos financeiros.
