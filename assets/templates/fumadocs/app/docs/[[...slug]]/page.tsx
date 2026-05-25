import { source } from "@/lib/source";
import { notFound } from "next/navigation";
import { DocsPage, DocsBody, DocsTitle, DocsDescription } from "fumadocs-ui/page";

interface Param {
  slug?: string[];
}

export default async function Page(props: { params: Promise<Param> }) {
  const params = await props.params;
  const page = source.getPage(params.slug);

  if (!page) {
    notFound();
  }

  const MDX = page.data.body;

  return (
    <DocsPage toc={page.data.toc} full={page.data.full}>
      <DocsTitle>{page.data.title}</DocsTitle>
      <DocsDescription>{page.data.description}</DocsDescription>
      <DocsBody>
        <MDX />
      </DocsBody>
    </DocsPage>
  );
}

export async function generateStaticParams() {
  return source.generateParams();
}

export async function generateMetadata(props: { params: Promise<Param> }) {
  const params = await props.params;
  const page = source.getPage(params.slug);

  if (!page) {
    return {};
  }

  return {
    title: page.data.title,
    description: page.data.description,
  };
}
