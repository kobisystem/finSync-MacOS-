import { useState } from "react";
import { Button } from "./components";
import { DashboardExample } from "./examples/DashboardExample";

export default function App() {
  const [theme, setTheme] = useState<"light" | "dark">("dark");

  return (
    <>
      <div style={{
        position: "fixed",
        right: 24,
        bottom: 24,
        zIndex: 50,
        display: "flex",
        gap: 8
      }}>
        <Button variant={theme === "light" ? "primary" : "secondary"} onClick={() => setTheme("light")}>
          Claro
        </Button>
        <Button variant={theme === "dark" ? "primary" : "secondary"} onClick={() => setTheme("dark")}>
          Escuro
        </Button>
      </div>
      <DashboardExample theme={theme} />
    </>
  );
}
