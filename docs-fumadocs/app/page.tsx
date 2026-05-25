import Link from "next/link";
import { HomeLayout } from "fumadocs-ui/layouts/home";
import { baseOptions } from "./layout.config";

const features = [
  {
    title: "Change rastreável",
    description:
      "Toda alteração passa por ideia → spec → tasks → implementação → documentação. Sem board externo — o estado vive nos arquivos.",
  },
  {
    title: "Agentes sob trilhos",
    description:
      "Claude Code e outros agentes executam cada etapa via comandos /, sempre dentro dos limites definidos pela SPEC.",
  },
  {
    title: "Git como fonte de verdade",
    description:
      "Branch por change, commit limpo no final. O histórico completo fica no Git e nos artefatos Markdown.",
  },
];

export default function HomePage() {
  return (
    <HomeLayout {...baseOptions}>
      <main className="flex flex-1 flex-col">
        <section className="container mx-auto flex flex-col items-center gap-6 px-4 py-24 text-center md:py-32">
          <span className="rounded-full border bg-fd-secondary px-3 py-1 text-xs font-medium uppercase tracking-wide text-fd-muted-foreground">
            Local-first · Spec-Driven
          </span>
          <h1 className="max-w-3xl text-4xl font-bold tracking-tight md:text-6xl">
            SDD —{" "}
            <span className="bg-gradient-to-br from-fd-primary to-fd-foreground bg-clip-text text-transparent">
              Spec-Driven Development
            </span>
          </h1>
          <p className="max-w-2xl text-balance text-lg text-fd-muted-foreground">
            Fluxo de desenvolvimento com IA, local-first, onde cada mudança
            nasce de uma especificação versionada e termina em documentação
            atualizada.
          </p>
          <div className="flex flex-wrap items-center justify-center gap-3 pt-2">
            <Link
              href="/docs/explanation/constitution"
              className="inline-flex h-11 items-center justify-center rounded-md bg-fd-primary px-6 text-sm font-medium text-fd-primary-foreground transition-colors hover:bg-fd-primary/90"
            >
              Constitution
            </Link>
            <Link
              href="/docs/CHANGELOG"
              className="inline-flex h-11 items-center justify-center rounded-md border bg-fd-background px-6 text-sm font-medium transition-colors hover:bg-fd-accent hover:text-fd-accent-foreground"
            >
              Changelog
            </Link>
          </div>
        </section>

        <section className="container mx-auto grid gap-6 px-4 pb-24 md:grid-cols-3">
          {features.map((feature) => (
            <article
              key={feature.title}
              className="rounded-xl border bg-fd-card p-6 transition-colors hover:bg-fd-accent/30"
            >
              <h3 className="mb-2 text-base font-semibold">{feature.title}</h3>
              <p className="text-sm text-fd-muted-foreground">
                {feature.description}
              </p>
            </article>
          ))}
        </section>
      </main>
    </HomeLayout>
  );
}
