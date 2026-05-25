---
title: "Patterns — como ESTE projeto escreve código"
---

# Patterns — como ESTE projeto escreve código

Esta pasta guarda **exemplos reais** extraídos do seu próprio código. Enquanto as
skills de stack (`.sdd/workflow/skills/stacks/`) ensinam boas práticas *universais*,
os patterns aqui ensinam **o estilo específico do seu time** — nomes, estrutura de
pastas, tratamento de erro, forma dos testes.

É o que faz a IA gerar código que "parece feito pelo time", em vez de inventar um
estilo novo. **É a maior arma anti-alucinação do workflow.**

## Como esta pasta é preenchida

O comando `/analyze` extrai os patterns automaticamente do seu código (Fase 4).
Em projeto novo/vazio, ela começa vazia e os patterns nascem na primeira feature.

## Estrutura

```
docs/patterns/
├── <stack>/                 # ex.: php-laravel, react
│   ├── controller.md        # esqueleto + convenções de um controller real
│   ├── service.md
│   ├── test.md
│   └── ...
```

Cada arquivo de pattern tem: quando usar · convenções observadas · esqueleto
(trecho real, enxuto) · regras.

## Quem lê isto

Os comandos `/spec`, `/tasks` e `/implement` leem `docs/patterns/` antes de propor
ou escrever código, para seguir a forma já existente no projeto.

> Mantenha os patterns atualizados: quando o time mudar de convenção, rode
> `/analyze` de novo (ou edite o pattern à mão) para a IA acompanhar.
