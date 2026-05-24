import type { ReactNode } from "react";

export type Theme = "light" | "dark";

export type ThemeProviderProps = {
  theme?: Theme;
  children: ReactNode;
};

export function ThemeProvider({ theme = "light", children }: ThemeProviderProps) {
  return <div data-theme={theme}>{children}</div>;
}
