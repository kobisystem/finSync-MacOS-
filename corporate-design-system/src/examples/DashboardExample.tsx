import { Badge, Button, Card, CardContent, CardHeader, Icon, Input, ThemeProvider } from "../components";
import "../styles.css";
import "./DashboardExample.css";

type DashboardExampleProps = {
  theme?: "light" | "dark";
};

const rows = [
  { company: "Atlas Corporate", owner: "A. Johnson", status: "Ativo", budget: "R$ 1,2M", progress: 78 },
  { company: "Nova Capital", owner: "M. Alves", status: "Em análise", budget: "R$ 840k", progress: 46 },
  { company: "Vector Group", owner: "R. Chen", status: "Ativo", budget: "R$ 960k", progress: 64 },
];

export function DashboardExample({ theme = "dark" }: DashboardExampleProps) {
  return (
    <ThemeProvider theme={theme}>
      <div className="app-shell">
        <div className="dashboard">
          <aside className="dashboard__sidebar">
            <div className="dashboard__brand">
              <div className="dashboard__logo" />
              <div>
                <strong>VERIDIAN</strong>
                <span>DESIGN SYSTEM</span>
              </div>
            </div>

            <nav className="dashboard__nav">
              {["Dashboard", "Clientes", "Relatórios", "Segurança"].map((item, index) => (
                <button className={index === 0 ? "is-active" : ""} key={item}>
                  <Icon name={index === 0 ? "barChart" : index === 1 ? "users" : index === 2 ? "fileText" : "shield"} />
                  {item}
                </button>
              ))}
            </nav>
          </aside>

          <main className="dashboard__main">
            <header className="dashboard__header">
              <div>
                <span className="dashboard__eyebrow">Ambiente executivo</span>
                <h1>Painel Corporativo</h1>
              </div>
              <div className="dashboard__actions">
                <Input placeholder="Buscar..." />
                <Button variant="primary">Novo contrato</Button>
              </div>
            </header>

            <section className="dashboard__metrics">
              <Card active elevated>
                <CardContent>
                  <div className="metric">
                    <span>Receita total</span>
                    <strong>R$ 8,72M</strong>
                    <Badge tone="success">+12,4%</Badge>
                  </div>
                </CardContent>
              </Card>

              <Card elevated>
                <CardContent>
                  <div className="metric">
                    <span>Margem operacional</span>
                    <strong>31,8%</strong>
                    <Badge tone="neutral">+4,2%</Badge>
                  </div>
                </CardContent>
              </Card>

              <Card elevated>
                <CardContent>
                  <div className="metric">
                    <span>Risco corporativo</span>
                    <strong>Baixo</strong>
                    <Badge tone="success">Seguro</Badge>
                  </div>
                </CardContent>
              </Card>
            </section>

            <section className="dashboard__content">
              <Card elevated className="dashboard__chart">
                <CardHeader>
                  <h2>Performance financeira</h2>
                  <p>Barras cromadas com preenchimento emerald.</p>
                </CardHeader>
                <CardContent>
                  <div className="chart-bars">
                    {[38, 54, 48, 72, 61, 84, 78, 92, 86, 108, 96, 116].map((height, index) => (
                      <div key={index} className="chart-bars__item" style={{ height: `${height}%` }}>
                        <span style={{ height: `${Math.max(20, height - 22)}%` }} />
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>

              <Card active elevated>
                <CardHeader>
                  <h2>Compliance</h2>
                  <p>Status regulatório.</p>
                </CardHeader>
                <CardContent>
                  <div className="compliance-ring">
                    <strong>94%</strong>
                    <span>aderência</span>
                  </div>
                </CardContent>
              </Card>
            </section>

            <Card elevated>
              <CardHeader>
                <h2>Contratos recentes</h2>
                <p>Acompanhamento executivo das últimas operações.</p>
              </CardHeader>
              <CardContent>
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Empresa</th>
                      <th>Responsável</th>
                      <th>Status</th>
                      <th>Budget</th>
                      <th>Progresso</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((row) => (
                      <tr key={row.company}>
                        <td>{row.company}</td>
                        <td>{row.owner}</td>
                        <td><Badge tone={row.status === "Ativo" ? "success" : "neutral"}>{row.status}</Badge></td>
                        <td>{row.budget}</td>
                        <td>
                          <div className="progress">
                            <span style={{ width: `${row.progress}%` }} />
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </CardContent>
            </Card>
          </main>
        </div>
      </div>
    </ThemeProvider>
  );
}
