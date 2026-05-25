// Cloudflare Worker — serve o instalador do SDD Workflow.
//
// Em https://install.jonathanteixeira.com.br/install.sh ele entrega o
// installer.sh mais recente do repositório sdd-flow (GitHub raw), com um
// cache curto. Assim, editar o installer.sh é só dar git push — sem redeploy.
//
// Uso pelo usuário final:
//   curl -fsSL https://install.jonathanteixeira.com.br/install.sh | bash
//   curl -fsSL https://install.jonathanteixeira.com.br/install.sh | bash -s -- --all

const RAW = 'https://raw.githubusercontent.com/jonathantx/sdd-flow/main/installer.sh';

export default {
  async fetch(request) {
    const url = new URL(request.url);

    // Saúde / raiz: pequena ajuda em texto.
    if (url.pathname === '/' || url.pathname === '') {
      return new Response(
        [
          'SDD Workflow installer',
          '',
          'Instale com:',
          '  curl -fsSL https://install.jonathanteixeira.com.br/install.sh | bash',
          '  curl -fsSL https://install.jonathanteixeira.com.br/install.sh | bash -s -- --all',
          '',
          'Repo: https://github.com/jonathantx/sdd-flow',
          '',
        ].join('\n'),
        { headers: { 'content-type': 'text/plain; charset=utf-8' } }
      );
    }

    // /install.sh  (ou qualquer caminho .sh) → entrega o script de bootstrap.
    if (url.pathname.endsWith('.sh') || url.pathname === '/install') {
      const upstream = await fetch(RAW, {
        cf: { cacheTtl: 300, cacheEverything: true }, // cache 5 min na borda
      });
      if (!upstream.ok) {
        return new Response(
          `# erro ao buscar o instalador (HTTP ${upstream.status}). Tente o raw direto:\n` +
            `# curl -fsSL ${RAW} | bash\n`,
          { status: 502, headers: { 'content-type': 'text/plain; charset=utf-8' } }
        );
      }
      const body = await upstream.text();
      return new Response(body, {
        headers: {
          'content-type': 'text/x-shellscript; charset=utf-8',
          'cache-control': 'public, max-age=300',
        },
      });
    }

    return new Response('Not found\n', { status: 404 });
  },
};
