# SpellFlash Forever

<p align="center">
  <img src="assets/LogoSpellFlash.jpg" alt="SpellFlash Forever" width="360">
</p>

> **[English](#english)** · **[Português (ptBR)](#português-ptbr)**

---

## English

Rotation assistant for **WoW Forever** (Interface `16001`, vanilla content on a modern
engine). Every 0.2s the addon evaluates your spec, talents, target, mana, range and
combat state — and makes **the action bar button for the ability you should use right
now flash**, with colors per function (damage, AoE, interrupt, defensive, utility).

It does **not** press the key for you — it just flashes the button. You stay in
control.

### What's new in 1.8.0

- **Shaman — weapon imbue defense in layers.**
  After pressing the imbue button (Flametongue/Windfury/Lightning Shield) the module now registers a long (≥10 min) belief, so the addon can never show "still missing the imbue" forever — no matter the client's aura-secret quirks.
- **New — outdated rank warnings on the action bar (chat).**
  At login, the addon prints a localized message for every ability on the bar whose rank is lower than the one in your spellbook, with both rank numbers. Turn it off anytime in **General**.
- **General tab — new checkbox** (pre-checked): _Warn about outdated abilities on the action bar_ / _Avisar sobre habilidades desatualizadas na barra de ação_.
- **General tab settings now persist across sessions** (all sliders live in the same proven storage).
- **New option — "Border width"** (0–60 px, default 12) for the border glow mode (0 = old look).
- **The configuration window now has an obvious red ✕ close button** in the top-right corner (drawn in code, so it is always visible). You can still close the window with `ESC`, with `/sf` again, or by clicking the red X.
- **The General tab (`/sf` → General) now has a "Save Settings" button** next to the "Test Flash" button. It forces an extra write of every configured value to the character's saved variables and confirms in chat. (Your settings are normally persisted on logout/`/reload`; this button gives you immediate, explicit feedback.)
- **All 6 TOCs declare Version 1.8.0** (dynamic About tab).
- **Bilingual**: ptBR / English — addon reads your client locale automatically.

### Modules

| Folder | Class | Highlights |
|---|---|---|
| `SpellFlashForever/` | Core (SpellFlashForever) | Suggestion driver, combat aura beliefs, per-character visual rotation editor (`/sf`), key button, minimap button |
| `SpellFlash_Hunter/` | Hunter | BM / MM / SV (Survival) |
| `SpellFlash_Shaman/` | Shaman | Elemental (focus) and Enhancement |
| `SpellFlash_Warrior/` | Warrior | Arms / Fury / Protection |
| `SpellFlash_Druid/` | Druid | Cat / Bear / Balance (best-effort) |
| `SpellFlash_Paladin/` | Paladin | Protection (tank) and Retribution (DPS) |

### Requirements

- WoW Forever, Interface **16001**.
- Any locale — the addon auto-detects ptBR (Portuguese) and English (all others).
- All 6 addon folders copied into `Interface\AddOns\`.

### Installation

1. Download the ZIP from the latest [Release](../../releases).
2. Extract it into `World of Warcraft\_forever_\Interface\AddOns\`
   (the 6 folders must sit directly inside `AddOns`).
3. Log in or `/reload`, then type `/sf`.

### Commands

| Command | Function |
|---|---|
| `/sf` | Open/close the configuration window (tabs: General, **About**, and each class) |
| `/sf status` | Module status |
| `/sfminimap` | Show/hide the minimap button |
| `/sfcd` | Cooldown diagnostics board |
| `/sfkey` | Toggle the key button (shows the key for the flashing ability) |

### Rotation editor

Each class tab has a **"Custom rotation"** section: enable/disable nodes, reorder
(▲▼), add conditions per ability, **Save** (per character) and **Share** (export as
`!SFROT-1!...` string). "Restore default" reverts to the guide.

### Credits

- **Marcus** — creation and project direction.
- **Inkling 2 Small Free (OpenCode)** — technology and development partner.
- Original SpellFlash (WotLK 3.3.5a): Exalter (Druid), BigRedBrent (Warrior),
  SF Community (Shaman) and the SpellFlash community. This is a port/derivative,
  with a deep architecture and rotation rework for the Forever.

### License

[MIT](LICENSE) — see the `LICENSE` file.

---

## Português (ptBR)

Assistente de rotação para o **WoW Forever** (Interface `16001`, conteúdo vanilla em
engine moderna). A cada 0,2 s o addon avalia sua spec, seus talentos, seu alvo, sua
mana, seu alcance e o estado do combate — e faz **piscar na barra de ação a
habilidade que você deveria usar agora**, com cores por função (dano, AoE,
interrupção, defensivo, utilidade).

Ele **não aperta a tecla por você** — apenas acende o botão. Quem joga é você.

### Novidades na 1.8.0

- **Shaman — defesa em camadas para os imbues das armas.**
  Após pressionar o botão do imbue (Labaredas/Windfury/Lightning Shield) o módulo registra uma crença longa (≥10 min), então o addon nunca mais mostra "ainda falta imbue" para sempre — independente das segredos de aura do cliente.
- **Novo — avisos de rank desatualizado na barra (chat).**
  No login, para cada habilidade na barra com rank menor do que o seu spellbook o addon imprime um aviso localizado com os dois ranks. Desligue a qualquer momento na aba **Geral**.
- **Aba Geral — novo checkbox** (pré-marcado): _Avisar sobre habilidades desatualizadas na barra de ação_ / _Warn about outdated abilities on the action bar_.
- **Preferências da aba Geral agora persistem entre sessões** (todos os sliders na mesma coleção).
- **Nova opção — "Largura da moldura"** (0–60 px, padrão 12) para o modo de brilho de contorno (0 = visual antigo).
- **A janela de configuração agora tem um botão vermelho ✕ de fechar** no canto superior direito (desenhado por código, então está sempre visível). Você ainda pode fechar com `ESC`, com `/sf` de novo ou clicando no X vermelho.
- **A aba Geral (`/sf` → Geral) agora tem um botão "Salvar Configurações"** ao lado do botão "Testar Flash". Ele força uma escrita extra de todos os valores configurados nas variáveis salvas do personagem e confirma no chat. (As configurações normalmente são salvas ao sair/`/reload`; este botão dá retorno imediato e explícito.)
- **As 6 TOCs declaram Versão 1.8.0** (aba Sobre lê dinamicamente).
- **Bilíngue**: ptBR / English — o addon lê o locale do cliente automaticamente.

### Módulos

| Pasta | Classe | Destaque |
|---|---|---|
| `SpellFlashForever/` | Core (SpellFlashForever) | Driver de sugestões, crenças de auras em combate, editor visual de rotação por personagem (`/sf`), botão de tecla, botão de minimapa |
| `SpellFlash_Hunter/` | Hunter | BM / MM / SV (Survival) |
| `SpellFlash_Shaman/` | Shaman | Elemental (foco) e Enhancement |
| `SpellFlash_Warrior/` | Warrior | Arms / Fury / Protection |
| `SpellFlash_Druid/` | Druid | Cat / Bear / Balance (best-effort) |
| `SpellFlash_Paladin/` | Paladin | Protection (tank) e Retribution (DPS) |

### Requisitos

- WoW Forever, Interface **16001**.
- Qualquer locale — o addon detecta ptBR (português) e inglês (todos os outros).
- As 6 pastas do addon copiadas para `Interface\AddOns\`.

### Instalação

1. Baixe o ZIP da última [Release](../../releases).
2. Descompacte em `World of Warcraft\_forever_\Interface\AddOns\`
   (as 6 pastas devem ficar direto dentro de `AddOns`).
3. Entre no jogo ou `/reload` e use `/sf`.

### Comandos

| Comando | Função |
|---|---|
| `/sf` | Abre/fecha o menu de configuração (abas: Geral, **Sobre**, e cada classe) |
| `/sf status` | Status do módulo carregado |
| `/sfminimap` | Mostra/esconde o botão no minimapa |
| `/sfcd` | Quadro de diagnóstico de cooldowns |
| `/sfkey` | Liga/desliga o botão de tecla (mostra a tecla da habilidade acesa) |

### Editor de rotação

Cada aba de classe tem a seção **"Rotação personalizada"**: ligue/desligue nós,
reordene (▲▼), adicione condições por habilidade, **Gravar** (por personagem) e
**Compartilhar** (exportar como string `!SFROT-1!...`). "Restaurar rotação padrão"
volta ao guia.

### Créditos

- **Marcus** — criação e direção do projeto.
- **Inkling 2 Small Free (OpenCode)** — parceiro de tecnologia e desenvolvimento.
- SpellFlash original (WotLK 3.3.5a): Exalter (Druid), BigRedBrent (Warrior),
  SF Community (Shaman) e a comunidade SpellFlash. Este projeto é um port/derivado,
  com profundo retrabalho de arquitetura e de rotação para o Forever.

### Licença

[MIT](LICENSE) — ver o arquivo `LICENSE`.
