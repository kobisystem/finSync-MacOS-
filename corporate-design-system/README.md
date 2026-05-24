# Corporate Design System React

Starter kit em React + TypeScript para o design system corporativo criado no preview.

## O que vem incluído

- Tokens CSS para tema claro e escuro
- Paleta graphite + emerald
- Variação dark chrome com metal/chrome sutil
- Componentes base:
  - Button
  - Card
  - Input
  - Badge
  - Icon
  - ThemeProvider
- Exemplo de dashboard com troca de tema

## Como rodar

```bash
npm install
npm run dev
```

## Como usar em outro projeto React

Copie a pasta:

```bash
src/tokens
src/components
```

Depois importe o CSS global no entrypoint do projeto:

```tsx
import "./tokens/tokens.css";
```

Use os componentes:

```tsx
import { Button, Card, CardContent, Badge, ThemeProvider } from "./components";

export function Example() {
  return (
    <ThemeProvider theme="dark">
      <Card active elevated>
        <CardContent>
          <h2>Contrato aprovado</h2>
          <Badge tone="success">Ativo</Badge>
          <Button>Continuar</Button>
        </CardContent>
      </Card>
    </ThemeProvider>
  );
}
```

## Estratégia de temas

O tema é controlado por `data-theme`.

```html
<div data-theme="light">...</div>
<div data-theme="dark">...</div>
```

Os componentes usam variáveis CSS, então você pode trocar tema sem alterar os componentes.

## Tokens principais

```css
--ds-bg
--ds-surface
--ds-surface-raised
--ds-text
--ds-text-muted
--ds-border
--ds-primary
--ds-primary-hover
--ds-primary-soft
--ds-focus
--ds-chrome
--ds-brushed-metal
```

## Neon funcional

O neon foi pensado para uso moderado:

- item selecionado
- foco de input
- CTA principal
- card ativo
- status positivo de alta relevância

Evite aplicar glow em todos os elementos para manter a sobriedade corporativa.
