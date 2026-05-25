# SDD Workflow — Diagramas para Apresentação

Diagramas em **Mermaid** (renderizam no GitHub, Notion, VS Code, slides com plugin Mermaid).
Cada um pode virar um slide.

---

## 1. Visão geral — O conceito fonte-única → adaptadores

```mermaid
flowchart TD
    subgraph FONTE["🗂️ Fonte-única — VOCÊ EDITA AQUI (.sdd/workflow)"]
        C["commands/<br/>ideia, prd, spec, tasks..."]
        S["skills/<br/>stacks + analyze-project"]
    end

    SYNC{{"⚙️ sdd sync"}}

    FONTE --> SYNC
    SYNC --> CLAUDE["🤖 .claude/<br/>(Claude Code)"]
    SYNC --> CODEX["🤖 .codex/<br/>(Codex CLI)"]
    SYNC --> GEMINI["🤖 .gemini/<br/>(Gemini CLI)"]

    CLAUDE --> CMD["Mesmos comandos<br/>/ideia /prd /spec ...<br/>em qualquer IA"]
    CODEX --> CMD
    GEMINI --> CMD

    style FONTE fill:#e3f2fd,stroke:#1976d2
    style SYNC fill:#fff3e0,stroke:#f57c00
    style CMD fill:#e8f5e9,stroke:#388e3c
```

---

## 2. Pipeline principal — O ciclo de uma FEATURE

```mermaid
flowchart LR
    A["💡 /ideia<br/>capturar"] --> B["📋 /prd<br/>o quê & porquê"]
    B --> AP1{"/approve"}
    AP1 --> C["🏗️ /spec<br/>como (técnico)"]
    C --> AP2{"/approve"}
    AP2 --> D["✂️ /tasks<br/>quebrar em pedaços"]
    D --> E["⚙️ /run-all<br/>implementar tudo"]
    E --> R["🔎 /review<br/>revisar diff"]
    R --> Z["📦 /archive<br/>fechar + changelog"]

    style A fill:#fff9c4
    style B fill:#bbdefb
    style C fill:#c5cae9
    style D fill:#d1c4e9
    style E fill:#c8e6c9
    style R fill:#ffe0b2
    style Z fill:#f8bbd0
```

---

## 3. Os 3 caminhos — Feature vs Fix vs Refactor

O `/ideia` classifica e manda para o caminho certo (pela quantidade de decisões).

```mermaid
flowchart TD
    START["💡 /ideia 'descrição'"] --> CLASS{"Que tipo de<br/>mudança é?"}

    CLASS -->|"comportamento novo<br/>(decisão de produto)"| FEAT["FEATURE"]
    CLASS -->|"algo quebrado<br/>(comportamento correto já conhecido)"| FIX["FIX"]
    CLASS -->|"melhorar código<br/>(sem mudar comportamento)"| REF["REFACTOR"]
    CLASS -->|"trivial<br/>(dep, rename, config)"| CHORE["CHORE"]

    FEAT --> F1["/prd → /approve → /spec → /approve<br/>→ /tasks → /run-all"]
    FIX --> X1["/fix<br/>(causa raiz + teste de regressão)"]
    REF --> R1["/refactor<br/>(testes existentes provam: nada mudou)"]
    CHORE --> CH1["commit direto"]

    F1 --> REV["🔎 /review"]
    X1 --> REV
    R1 --> REV
    REV --> ARC["📦 /archive"]
    CH1 --> ARC

    style FEAT fill:#bbdefb
    style FIX fill:#ffcdd2
    style REF fill:#fff9c4
    style CHORE fill:#e0e0e0
    style REV fill:#ffe0b2
    style ARC fill:#f8bbd0
```

---

## 4. Onde a SKILL de stack entra (anti-alucinação)

```mermaid
flowchart TD
    AN["🔍 /analyze<br/>detecta a stack do projeto"] --> CON["📜 constitution.md<br/>registra stacks ativas"]

    CON -.alimenta.-> SP["🏗️ /spec"]
    CON -.alimenta.-> TK["✂️ /tasks"]
    CON -.alimenta.-> IM["⚙️ /implement"]

    subgraph KB["📚 Base de conhecimento (skills/stacks)"]
        K1["node-typescript"]
        K2["php-laravel"]
        K3["react"]
        K4["svelte"]
    end

    KB ==>|"carregada antes<br/>de escrever código"| IM
    IM --> CODE["✅ Código no padrão<br/>da stack, sem alucinar"]

    style AN fill:#e1f5fe
    style CON fill:#fff3e0
    style KB fill:#e8f5e9
    style CODE fill:#c8e6c9
```

---

## 5. Estados de uma "change" (máquina de estados)

```mermaid
stateDiagram-v2
    [*] --> draft: /ideia
    draft --> prd_approved: /prd + /approve
    prd_approved --> spec_validated: /spec + /approve
    spec_validated --> in_progress: /tasks + /implement
    in_progress --> in_review: /review
    in_review --> in_progress: mudanças necessárias
    in_review --> delivered: /archive
    delivered --> [*]

    note right of draft
        Tudo vive em Markdown
        versionado no Git
    end note
```

---

## 6. Ciclo de vida da governança (instalar / atualizar / consertar)

```mermaid
flowchart TD
    subgraph INSTALL["🆕 Instalar"]
        I1["install.sh --tools ..."] --> I2["/analyze"] --> I3["sdd doctor"]
    end

    subgraph UPDATE["🔄 Atualizar"]
        U1["editar .sdd/workflow/"] --> U2["sdd sync"] --> U3["sdd verify"] --> U4["sdd doctor"]
    end

    subgraph FIX["🔧 Consertar"]
        X1["sdd doctor + verify<br/>(diagnóstico)"] --> X2["sdd sync<br/>(realinha)"] --> X3["sdd verify ✅"]
    end

    INSTALL ==> USE["✍️ Usar:<br/>/ideia → ... → /archive"]
    USE -.evoluiu.-> UPDATE
    USE -.quebrou.-> FIX
    UPDATE --> USE
    FIX --> USE

    style INSTALL fill:#e8f5e9
    style UPDATE fill:#e3f2fd
    style FIX fill:#fff3e0
    style USE fill:#f3e5f5
```

---

## 7. Tabela de comandos (referência rápida — bom como slide-resumo)

```mermaid
flowchart LR
    subgraph CAP["📥 Capturar"]
        c1["/ideia"]
        c2["/analyze"]
    end
    subgraph PLAN["📐 Planejar"]
        p1["/prd"]
        p2["/spec"]
        p3["/approve"]
        p4["/tasks"]
    end
    subgraph EXEC["⚙️ Executar"]
        e1["/implement"]
        e2["/run-all"]
        e3["/preparar-lote"]
        e4["/approve-task"]
    end
    subgraph DIR["🎯 Direto"]
        d1["/fix"]
        d2["/refactor"]
    end
    subgraph QA["✅ Qualidade"]
        q1["/review"]
        q2["/status"]
    end
    subgraph END["📦 Fechar"]
        f1["/archive"]
    end

    CAP --> PLAN --> EXEC --> QA --> END
    DIR --> QA
```
