# SpellFlash Forever

Assistente de rotação para o **WoW Forever** (Interface `16001`, pt-BR, conteúdo
vanilla em engine moderna). A cada 0,2 s o addon avalia sua spec, seus talentos, seu
alvo, sua mana, seu alcance e o estado do combate — e faz **piscar na barra de ação a
habilidade que você deveria usar agora**, com cores por função (dano, AoE, interrupção,
defensivo, utilidade).

## Módulos

| Pasta | Classe | Destaque |
|---|---|---|
| `SpellFlashForever/` | Core (SpellFlashForever) | Driver de sugestões, crenças de auras em combate, editor visual de rotação por personagem (`/sf`), botão de tecla, botão de minimapa |
| `SpellFlash_Hunter/` | Hunter | BM / MM / SV (Survival) |
| `SpellFlash_Shaman/` | Shaman | Elemental (foco) e Enhancement |
| `SpellFlash_Warrior/` | Warrior | Arms / Fury / Protection |
| `SpellFlash_Druid/` | Druid | Cat / Bear / Balance (best-effort) |

## Requisitos

- WoW Forever, Interface **16001**, locale pt-BR (outras locales funcionam com limitações).
- Todos os 5 addons copiados para `Interface\AddOns\`.

## Instalação

1. Baixe o ZIP da última [Release](../../releases).
2. Descompacte em `World of Warcraft\_forever_\Interface\AddOns\`
   (as 5 pastas devem ficar direto dentro de `AddOns`).
3. Entre no jogo ou `/reload` e use `/sf`.

## Comandos

| Comando | Função |
|---|---|
| `/sf` | Abre/fecha o menu de configuração (abas: Geral, **Sobre**, e cada classe) |
| `/sf status` | Status do módulo carregado |
| `/sfminimap` | Mostra/esconde o botão no minimapa |
| `/sfcd` | Quadro de cooldowns |

## Editor de rotação

Cada aba de classe tem a seção **"Rotação personalizada"**: ligue/desligue nós,
reordene (▲▼), adicione condições por habilidade, **Gravar** (por personagem) e
**Compartilhar** (exportar como string `!SFROT-1!...`). "Restaurar rotação padrão"
volta ao guia.

## Créditos

- **Marcus** — criação e direção do projeto.
- **Inkling 2 Small Free (OpenCode)** — parceiro de tecnologia e desenvolvimento.
- SpellFlash original (WotLK 3.3.5a): Exalter (Druid), BigRedBrent (Warrior),
  SF Community (Shaman) e a comunidade SpellFlash. Este projeto é um port/derivado,
  com profundo retrabalho de arquitetura e de rotação para o Forever.

## Licença

[MIT](LICENSE) — ver o arquivo `LICENSE`.
