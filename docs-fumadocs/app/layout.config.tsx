import type { BaseLayoutProps } from "fumadocs-ui/layouts/shared";

export const baseOptions: BaseLayoutProps = {
  nav: {
    title: (
      <>
        <span className="font-semibold">SDD</span>
        <span className="text-fd-muted-foreground ms-1.5">
          Spec-Driven Development
        </span>
      </>
    ),
  },
  links: [
    {
      text: "Documentação",
      url: "/docs",
      active: "nested-url",
    },
    {
      text: "Changelog",
      url: "/docs/CHANGELOG",
    },
  ],
};
