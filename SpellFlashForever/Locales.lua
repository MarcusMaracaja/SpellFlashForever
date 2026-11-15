-- SpellFlashForever / Locales.lua
-- Localização do addon (ptBR / en). Carregado ANTES de qualquer outro arquivo
-- do núcleo (ver SpellFlashForever.toc). O idioma é escolhido pelo locale do
-- cliente: ptBR -> português; qualquer outro locale -> inglês.
--
-- Uso nos módulos: `local L = AddonTable.L` (ou _G["SpellFlashForever"].L)
-- Strings com placeholders usam string.format no ponto de uso, ex.:
--   string.format(L.dbg_loaded, CLASS)

local addonName = "SpellFlashForever"
local s = _G[addonName]
if not s then
    s = CreateFrame("Frame", addonName, UIParent)
    _G[addonName] = s
end

local L = {}

-- ===========================================================================
-- Português (ptBR) — idioma padrão do projeto
-- ===========================================================================
local ptBR = {
    -- ---- Núcleo / Compat / SharedFunctions ---------------------------------
    compat_loaded     = "|cff33ff99SpellFlashForever:|r compatibilidade (SpellFlash WotLK) carregada.",
    compat_module_failed = "|cffff0000[SF DEBUG]|r Módulo '%s' falhou: %s",
    shared_unnamed    = "(sem nome)",

    -- ---- Minimap -------------------------------------------------------------
    minimap_toggle    = "|cff33ff99SpellFlashForever:|r botão do minimapa %s.",
    minimap_shown     = "mostrado",
    minimap_hidden    = "escondido",
    minimap_tt_open   = "Clique para abrir/fechar o menu.",
    minimap_tt_drag   = "Arraste para reposicionar. Use /sfminimap para esconder/mostrar.",

    -- ---- Botão de tecla (KeyButton) -----------------------------------------
    key_lock          = "Movimento do botão bloqueado.",
    key_unlock        = "Arraste o botão para movê-lo.",
    key_error         = "Erro no botão de tecla: %s",
    key_help          = "/sfkey: botão com a tecla da habilidade que está brilhando",
    key_off_hint      = "Botão de tecla desligado. /sfkey on para religar.",
    key_on            = "Botão de tecla ligado.",
    key_pos_reset     = "Posição do botão restaurada.",
    key_hidden        = "Botão de tecla oculto.",
    key_shown         = "Botão de tecla visível.",
    key_debug_on      = "Depuração ativada. Dispare um flash e veja as mensagens no chat.",
    key_debug_off     = "Depuração desativada.",
    key_commands      = "Comandos: on/off, lock/unlock, reset, show, hide, debug",

    -- ---- Debug / diagnóstico do núcleo --------------------------------------
    dbg_onflash_error   = "|cffff0000[SF DEBUG]|r Erro no OnFlash: %s",
    dbg_slots_occupied  = "|cffff0000[SF DEBUG]|r Slots ocupados: %s",
    dbg_slot_not_found  = "|cffff0000[SF DEBUG]|r Nenhum slot na barra de ação encontrado para '%s'.",
    dbg_slot_no_button  = "|cffff0000[SF DEBUG]|r Slot %s encontrado para '%s' mas nenhum botão de barra corresponde.",
    dbg_category_id     = "|cff33ff99SpellFlashForever:|r Categoria registrada. ID: %s",
    dbg_category_nil    = "|cffff0000SpellFlashForever:|r ERRO: SettingsCategoryID é nil!",
    dbg_settings_missing = "|cffff0000SpellFlashForever:|r Settings API não disponível!",
    dbg_loaded          = "|cff33ff99SpellFlashForever:|r carregado (Classe: %s). Digite |cffffcc00/sf|r para abrir o menu.",
    dbg_slash_header    = "|cff33ff99SpellFlashForever|r comandos:",
    dbg_help_1          = "  /sf ou /sfbyferal        - Abrir/fechar a janela visual de configurações",
    dbg_help_2          = "  /sfbyferal flash <nome>  - Flashar um feitiço/item",
    dbg_help_3          = "  /sfbyferal size <n>      - Tamanho do flash (atual: %s)",
    dbg_help_4          = "  /sfbyferal bright <n>    - Brilho do flash (atual: %s)",
    dbg_help_5          = "  /sfbyferal off           - Desativar flash de feitiços",
    dbg_help_6          = "  /sfbyferal on            - Ativar flash de feitiços",
    dbg_help_7          = "  /sfbyferal status        - Mostrar status",
    dbg_help_8          = "  /sfbyferal key [on|off]  - Botão que mostra a tecla da habilidade (use /sfkey)",
    dbg_flash_disabled  = "|cffff0000SpellFlashForever:|r flash está desativado. Use /sfbyferal on",
    dbg_flashing        = "|cff33ff99SpellFlashForever:|r flashando: %s",
    dbg_size_current    = "|cff33ff99SpellFlashForever:|r tamanho atual: %s",
    dbg_size_set        = "|cff33ff99SpellFlashForever:|r tamanho definido: %s",
    dbg_bright_set      = "|cff33ff99SpellFlashForever:|r brilho definido: %s",
    dbg_off             = "|cff33ff99SpellFlashForever:|r flash de feitiços desativado",
    dbg_on              = "|cff33ff99SpellFlashForever:|r flash de feitiços ativado",
    dbg_status          = "|cff33ff99SpellFlashForever:|r classe: %s | raca: %s",
    dbg_race_detected   = "|cff33ff99SpellFlashForever:|r Hunter raça detectada: %s",
    dbg_flash_off       = "|cff33ff99SpellFlashForever:|r flash off: %s",
    dbg_status_sizes    = "|cff33ff99SpellFlashForever:|r tamanho: %s | brilho: %s",
    dbg_debug_status    = "|cff33ff99SpellFlashForever:|r debug: %s",
    dbg_key_button      = "|cff33ff99SpellFlashForever:|r botão de tecla: %s",
    dbg_debug_toggle    = "|cff33ff99SpellFlashForever:|r debug %s",
    dbg_debug_on_word   = "ativado",
    dbg_debug_off_word  = "desativado",
    dbg_traits_header   = "|cff33ff99SpellFlashForever:|r === C_Traits / C_ClassTalents ===",
    dbg_traits_nil      = "|cffff0000SpellFlashForever:|r C_Traits: nil",
    dbg_traits          = "|cff33ff99SpellFlashForever:|r C_Traits: %s",
    dbg_classtalents_nil = "|cffff0000SpellFlashForever:|r C_ClassTalents: nil",
    dbg_classtalents    = "|cff33ff99SpellFlashForever:|r C_ClassTalents: %s",
    dbg_traits_end      = "|cff33ff99SpellFlashForever:|r === fim ===",
    dbg_unknown_command = "|cffff0000SpellFlashForever:|r comando desconhecido: %s. Use /sfbyferal help",

    -- ---- Painel Geral / Sobre -------------------------------------------------
    tab_general       = "Geral",
    tab_about         = "Sobre",

    opt_general_title = "|cff33ff99Configurações Gerais|r",
    opt_general_desc  = "Ajuste as opções visuais e comportamento de sugestões.",
    opt_flash_enable  = "Ativar Sugestões de Feitiços (Spell Flashing)",
    opt_flash_enable_tt = "Pisca as habilidades recomendadas nas barras de ação.",
    opt_flash_border  = "Brilho de contorno (borda)",
    opt_flash_border_tt = "Pisca a borda do botão em vez do brilho de estrela sobreposto.",
    opt_flash_solid   = "Cor sólida (sem transparência)",
    opt_flash_solid_tt = "Mantém o brilho na opacidade máxima, sem esmaecer.",
    opt_single_color  = "Mesma cor para todos os brilhos",
    opt_single_color_tt = "Quando ligado, todos os flashes usam a cor escolhida e ignoram a cor individual.",
    col_yellow = "Amarelo", col_white = "Branco", col_red = "Vermelho", col_green = "Verde",
    col_blue = "Azul", col_aqua = "Ciano", col_orange = "Laranja", col_purple = "Roxo",
    col_pink = "Rosa", col_gray = "Cinza",
    opt_suppress_range = "Suprimir verificação de alcance",
    opt_suppress_range_tt = "Piscar botões mesmo se o alvo estiver fora de alcance.",
    opt_suppress_speed = "Suprimir verificação de movimento",
    opt_suppress_speed_tt = "Piscar botões mesmo durante movimento.",
    opt_disable_immune  = "Desativar detecção automática de imunidade",
    opt_disable_immune_tt = "Não registrar imunidades de criaturas contra tipos de magia.",
    opt_flash_size    = "Tamanho do Flash",
    opt_flash_bright  = "Brilho / Opacidade do Flash",
    opt_flash_border_width = "Largura da moldura",
    opt_flash_border_width_tt = "Apenas no modo de brilho de contorno: largura extra da moldura em pixels (0 = rente ao botão).",
    opt_bar_rank_warnings = "Avisar sobre habilidades desatualizadas na barra de ação",
    bar_rank_warn = "|cffffcc00[SpellFlash Forever]|r %s na barra de ação está no rank %d; você já conhece o rank %d. Arraste do grimório para atualizar.",
    opt_minimap       = "Mostrar botão no minimapa",
    opt_minimap_tt    = "Exibe um botão no minimapa que abre/fecha este menu. Arraste-o para reposicionar. Use /sfminimap para igualmente esconder/mostrar.",
    opt_keybutton     = "Mostrar botão com a tecla da habilidade",
    opt_keybutton_tt  = "Exibe um botão extra mostrando a tecla que deve ser apertada para a habilidade que está brilhando.",
    opt_keybutton_lock = "Travar o botão de tecla (não arrasta)",
    opt_keybutton_lock_tt = "Impede que o botão de tecla seja arrastado por engano. Use junto com 'Mostrar botão com a tecla da habilidade'.",
    opt_test_button   = "Testar Flash",
    opt_test_msg      = "|cff33ff99SpellFlash Forever:|r Testando flash no Botão 1.",
    opt_test_fail     = "|cff33ff99SpellFlash Forever:|r Botão 1 não encontrado para teste.",

    about_what_is      = "O que é",
    about_what_is_body = "O SpellFlash Forever é um assistente de rotação para o WoW Forever. A cada 0,2s ele avalia seu alvo, sua spec, seus talentos, sua mana, seu alcance e o estado do combate — e faz piscar na barra de ação a habilidade que você deveria usar agora.\n\nCada habilidade pisca com a cor da sua função: dano principal (amarelo), AoE (roxo), interrupção/controle (ciano), defensivo (vermelho), utilidade (verde) e situacional (rosa/laranja).",
    about_includes     = "O que inclui",
    about_includes_body = "• Núcleo SpellFlashForever: driver de sugestões, crenças de auras em combate, editor visual de rotação por personagem (/sf, seção \"Rotação personalizada\" em cada aba de classe), botão de tecla nos botões, botão de minimapa.\n• Módulos de classe: Hunter, Shaman, Warrior e Druid — cada um com a rotação recomendada do Forever como padrão, editável por personagem.\n• Um erro por vez; toda mudança é registrada no histórico do projeto.",
    about_howto        = "Como usar",
    about_howto_body   = "/sf abre (e fecha) esta janela. A aba de cada classe tem o toggle do módulo, a detecção de spec (com override) e o editor de rotação. /sf status mostra o estado do módulo. /sfminimap alterna o botão no minimapa.",
    about_credits      = "Créditos — criação",
    about_credits_body = "|cffffffffMarcus|r — criação e direção do projeto SpellFlash Forever.\n\n|cffffffffInkling 2 Small Free (OpenCode)|r — parceiro de tecnologia e desenvolvimento: inteligência artificial usada como par de programação (pesquisas, arquitetura, código, testes e documentação).\n\nSpellFlash original (WotLK 3.3.5a): Exalter (Druid), BigRedBrent (Warrior), SF Community (Shaman) e comunidade SpellFlash. Este projeto é um port/derivado, com profundo retrabalho de arquitetura e de rotação para o Forever.",
    about_thanks       = "Agradecimentos",
    about_thanks_body  = "Ao time do WoW Forever, à comunidade de teoria de rotações e a quem testou o addon em jogo e reportou cada erro — cada correção virou uma entrada no histórico do projeto.",
    about_version      = "Versão %s-forever · WoW Forever (Interface 16001)",

    settings_hint      = "Clique no botão abaixo para abrir a janela completa de configurações do SpellFlash Forever.",
    settings_open      = "Abrir Menu SpellFlash Forever",

    -- ---- Editor de rotação ---------------------------------------------------
    rot_axis_combat   = "1. Combate",
    rot_axis_env      = "2. Ambiente",
    rot_axis_target   = "3. Alvo",
    rot_axis_range    = "4. Alcance",
    rot_axis_resource = "5. Recurso",
    rot_axis_aoe      = "6. Área",
    axis_both         = "ambos",
    axis_in_combat    = "em combate",
    axis_out_combat   = "fora de combate",
    axis_any          = "qualquer",
    axis_attackable   = "atacável",
    axis_casting      = "conjurando",
    axis_no_attack    = "sem alvo atacável",
    axis_ranged       = "ranged (> dead zone)",
    axis_melee        = "melee / dead zone",
    axis_dead_zone    = "na dead zone",
    axis_mana15       = "mana > 15%",
    axis_mana40       = "mana > 40%",
    axis_mana50       = "mana > 50%",
    axis_rage40       = "rage >= 40",
    axis_energy40     = "energia >= 40",
    axis_combo5       = "combo >= 5",
    axis_aoe_2        = "AoE (2+)",
    axis_single       = "alvo único",

    rot_header        = "|cff33ff99Rotação da aba (editável)|r",
    rot_no_condition  = "|cff888888- sem condicoes -|r",
    rot_always        = "- sempre -",
    rot_none_active   = "(nenhuma condicao ativa)",
    rot_add_condition = "Adicionar condicao",
    rot_remove_condition = "Remover condicao",
    rot_clear_all     = "Apagar todas as condicoes",
    rot_spec_prefix   = "Espec.: ",
    rot_save          = "Gravar rotação",
    rot_restore       = "Restaurar padrão",
    rot_saved         = "|cff33ff99[SF Rot]|r Rotação gravada (por personagem) para %s / %s.",
    rot_share         = "|cff33ff99Compartilhar rotação|r (formato !SFROT-1!, estilo Hekili)",
    rot_yours         = "Sua rotação - copie e envie:",
    rot_import_title  = "Importar - cole a rotação de alguém aqui:",
    rot_import_button = "Importar rotação",
    rot_import_help   = "Importa só a spec desta aba. Nós desconhecidos são ignorados. A importação substitui a sua rotação personalizada atual desta spec (restaurar padrão reverte).",
    rot_import_failed = "|cffff0000[SF Rot]|r Importar falhou: %s",
    rot_imported      = "Rotação importada (%d nós",
    rot_unknown_skipped = "; %d desconhecido(s) ignorado(s)",
    rot_select_all    = "Selecionar tudo",
    rot_custom_title  = "Rotação personalizada",
    rot_click_test    = "Clique: testa o flash na barra de ação",
    rot_not_known     = "|cff33ff99[SF Rot]|r Você não conhece esta magia ainda.",
    rot_bad_char      = "caractere inválido: '%s'",
    rot_bad_prefix    = "prefixo !SFROT-1! não encontrado",
    rot_decode_failed = "decodificação falhou: %s",
    rot_no_header     = "cabeçalho SFR1 não encontrado",
    rot_wrong_module  = "rotação é de outro módulo (%s)",
    rot_wrong_spec    = "rotação é de outra spec (%s)",
    rot_no_nodes      = "nenhum nó reconhecido na string",
    rot_unknown_spec  = "spec desconhecido: %s",

    pred_not_cat_form = "você NÃO está em forma de animal (Cat Form)",
    pred_bear_form = "você está em Bear Form",
    pred_not_moonkin = "você NÃO está em Moonkin Form",
    pred_mark_missing = "Mark of the Wild ausente (caster/Moonkin, não montado)",
    pred_thorns_missing = "Thorns ausente (caster/Moonkin, não montado)",
    pred_natures_grasp_missing = "Nature's Grasp / Enredamento ausente (não montado)",
    pred_insect_swarm_missing = "Insect Swarm ausente no alvo",
    pred_moonfire_missing = "Moonfire ausente no alvo",
    pred_behind = "por trás do alvo",
    pred_cat_form_combo = "Cat Form, 40+ de energia, PvE",
    pred_combo5 = "5 pontos de combo",
    pred_energy40 = "40+ de energia",
    pred_my_hp35 = "você abaixo de 35%",
    pred_aoe_dead_zone = "AoE e fora da dead zone",
    pred_aoe_pve_mana15 = "AoE, PvE e mana acima de 15%",
    pred_single_dead_zone = "alvo único e fora da dead zone",
    pred_enemy_combat_dead_zone = "alvo atacável, em combate e fora da dead zone",
    pred_interruptible_nocc = "alvo conjurando (interruptível), fora da dead zone e sem CC nele",
    pred_pet_interruptible = "alvo conjurando, pet vivo, fora da dead zone e alvo sem CC",
    pred_pvp_target_mana = "PvP e alvo com mana",
    pred_pvp_target_melee = "PvP e alvo Guerreiro/Ladino",
    pred_no_viper = "sem Viper Sting no alvo",
    pred_no_scorpid = "sem Scorpid Sting no alvo",
    pred_pvp_viper = "PvP, alvo com mana e sem Viper Sting",
    pred_pvp_scorpid = "PvP, alvo Guerreiro/Ladino e sem Scorpid Sting",
    pred_no_serpent = "sem Serpent Sting ativo (alvo atacável, fora do melee)",
    pred_no_any_sting = "sem sting ativo no alvo",
    pred_melee_dead_zone = "em melee/dead zone",
    pred_dead_zone_not_melee = "na dead zone e fora de melee",
    pred_pvp_no_clip = "melee/dead zone, PvP e alvo sem Wing Clip",
    pred_melee_interruptible = "melee com alvo atacável e conjurando",
    pred_within_8_aoe = "ao alcance (≤ 8 jd) em AoE",
    pred_within_8_st = "ao alcance (≤ 8 jd) em alvo único",
    pred_pve_no_serpent = "PvE, sem Serpent Sting ativo, fora do melee",
    pred_no_serpent_belief = "sem Serpent Sting ativo (via crença), fora do melee",
    pred_pvp_hp30 = "PvP e você abaixo de 30%",
    pred_aoe_and_enemy = "AoE com alvo atacável",
    pred_casting_stun = "alvo atacável conjurando (stun/interrupt)",
    pred_target_hp20 = "alvo abaixo de 20%",
    pred_undead_or_demon = "alvo é morto-vivo ou demônio (Exorcism)",
    pred_prot_fury = "Protection e Righteous Fury ausente",
    pred_prot_shield = "Protection e Holy Shield ausente",
    pred_ret_seal = "Retribution e Seal of Command ausente",
    pred_casting_interrupt = "alvo atacável conjurando (interrupt)",
    pred_clearcasting = "Clearcasting ativo (Elemental Focus)",
    pred_chain_lightning_ok = "Chain Lightning ok (AoE ou mana >= 50% ou Clearcasting)",
    pred_lightning_shield = "Lightning Shield ausente",
    pred_ele_flametongue = "Elemental e Flametongue ausente",
    pred_enh_windfury = "Enhancement e Windfury ausente",
    pred_enh_earth = "Enhancement e Strength of Earth ausente",
    pred_flame_shock = "Flame Shock ausente (alvo atacável, mana ok)",
    pred_fire_totem_aoe = "AoE com totem de fogo ativo",
    pred_fire_totem_magma = "AoE e falta totem de fogo (Magma)",
    pred_fire_totem_searing = "alvo único e falta totem de fogo (Searing)",
    pred_mana_spring = "Mana Spring ausente (luta longa ou mana < 50%)",
    pred_aoe_mana15 = "AoE e mana acima de 15%",
    pred_maelstrom5 = "Maelstrom Weapon com 5 pilhas",
    pred_rage40 = "rage acima de 40",
    pred_rage_enemy = "rage acima de 40 e alvo atacável",
    pred_aoe_rage40 = "AoE, rage acima de 40 e alvo atacável",
    pred_aoe_rage45 = "AoE, rage acima de 45 e alvo atacável",
    pred_shield_attackable = "com escudo e alvo atacável",
    pred_shield = "com escudo",
    pred_cast_not_berserker = "alvo conjurando e você NÃO está em Berserker Stance (3)",
    pred_cast_berserker = "alvo conjurando e você está em Berserker Stance (3)",
    pred_cast_defensive = "alvo conjurando e você está em Defensive Stance (2)",
    pred_cast_shield = "alvo conjurando e você com escudo",
    pred_not_berserker = "você NÃO está em Berserker Stance (3)",
    pred_out_battle_stance = "fora de combate e você NÃO está em Battle Stance (1)",
    pred_out_attackable_battle = "fora de combate, alvo atacável e você NÃO está em Battle Stance (1)",
    pred_out_attackable = "fora de combate e alvo atacável",
    pred_out_shout = "fora de combate e sem Battle Shout",
    pred_combat_not_berserker = "em combate e você NÃO está em Berserker Stance (3)",
    pred_not_defensive = "você NÃO está em Defensive Stance (2)",
    pred_pvp_attackable = "PvP com alvo atacável",
    pred_target_casting = "alvo conjurando",
    pred_roar_missing = "Demoralizing Roar ausente (Bear)",
    spec_feral = "Feral (Cat PvE) / Bear",
    spec_fury2h = "Fury (two-hand / dual)",
    cd_usage = "uso: /sfcd <spellID>",
    cd_spellid = "spellID=%s name=%s",
    cd_resolve_known = "resolve -> rank conhecido: %s",
    cd_getcooldown_rank = "GetSpellCooldown(rank: %s): ok=%s tipo=%s",
    cd_rank_info = "  rank info.%s = %s (%s)",
    cd_info = "  info.%s = %s (%s)",
    cd_spellcooldown_rank = "SpellCooldown(rank: %s): timeLeft=%s dur=%s",
    cd_getcooldown_raw = "GetSpellCooldown(raw: %s): ok=%s tipo=%s",
    cd_return = "  retorno: %s",
    cd_duration = "GetSpellCooldownDuration: ok=%s tipo=%s valor=%s",
    cd_duration_ignoredcf = "GetSpellCooldownDuration(id,ignoreGCD=true): ok=%s tipo=%s valor=%s",
    cd_raw = "SpellCooldown(raw: %s): timeLeft=%s dur=%s",
    cd_action_slot = "Action slot pro rank conhecido = %s",
    cd_cooldown_slot = "ActionCooldown(slot): timeLeft=%s dur=%s",
    cd_not_found = "nome inexistente",
    cd_simulated = "CheckIfSpellCastable(simulado) = %s",
    cd_getcooldown_absent = "GetSpellCooldown: ausente",
    drc_race = "playerRace=%s | racial=%s (%s)",
    drc_known_ok = "IsSpellKnown -> ok=%s known=%s",
    drc_known_absent = "C_SpellBook.IsSpellKnown AUSENTE",
    drc_info = "GetSpellInfo -> ok=%s nome=%s",
    drc_cooldown_table = "  cd.%s = %s",
    drc_cooldown_ok = "GetSpellCooldown -> ok=%s",
    drc_usable = "IsSpellUsable -> ok=%s usable=%s power=%s",
    drc_spellknown = "SpellKnown() = %s",
    drc_cooldown_remaining = "RacialCooldownRemaining = %s",
    drc_incombat = "InCombat = %s",
    drc_canattack = "UnitCanAttack -> ok=%s canAttack=%s",
    drc_no_target = "sem alvo",
    drc_should = "ShouldUseRacial() = %s",

    -- ---- Módulos (abas, toggles, specs) --------------------------------------
    mod_desc_abilities = "Controle a rotação do %s: se desligado, o módulo deixa de sugerir habilidades (as sugestões gerais continuam em Geral).",
    mod_desc_spells    = "Controle a rotação do %s: se desligado, o módulo deixa de sugerir magias (as sugestões gerais continuam em Geral).",
    mod_toggle         = "Ativar sugestões de rotação do %s",
    mod_toggle_hint    = "Desligar acima equivale a 'spell_flashing_off' só para este módulo.",
    mod_toggle_hint_long = "Desligar acima equivale a 'spell_flashing_off' só para este módulo. O flash é feito nos botões da barra de ação (qualquer skill/macro com a tecla vinculada).",
    mod_spec_title     = "Forçar rotação (senão, detecta automaticamente):",

    spec_bm            = "Mestre das Feras (BM)",
    spec_mm            = "Atirador de Elite (MM)",
    spec_sv            = "Sobrevivência (SV)",
    spec_arms          = "Arms (arms PvE)",
    spec_prot          = "Protection (tank)",
    spec_ele           = "Elemental (caster)",
    spec_enh           = "Enhancement (melee)",
    spec_resto         = "Restoration (healer)",
    spec_balance       = "Balance (caster)",
    spec_ret           = "Retribution (DPS)",

    mod_druid_spec_hint  = "Use se a rotação não estiver sendo reconhecida em combate. Se nenhuma estiver marcada, o Druid detecta a spec sozinho (pontos por árvore via C_Traits).",
    mod_hunter_spec_hint = "Use se a rotação não estiver sendo reconhecida em combate. Se nenhuma estiver marcada, o Hunter detecta a spec sozinho (C_SpecializationInfo / talentos / spells assinatura / SV).",
    mod_pal_spec_hint    = "Use se a rotação não estiver sendo reconhecida em combate. Holy não é suportada (rotas por detecção não existem); use o override acima.",
    mod_shaman_spec_hint = "Use se a rotação não estiver sendo reconhecida em combate. Se nenhuma estiver marcada, o Shaman detecta a spec sozinho (C_Traits + assinatura de spell).",
    mod_warrior_spec_hint = "Use se a rotação não estiver sendo reconhecida em combate. Se nenhuma estiver marcada, o Warrior detecta a spec sozinho (C_Traits por árvore).",

    mod_not_available  = "|cffff9900[SF %s]|r SpellFlashForever não disponível para registrar a aba %s.",
    mod_loaded         = "|cFF00FF00[SF %s]|r %s",
    mod_load_functions = "Functions carregado!",
    mod_load_options   = "Options carregado!",
    mod_load_scripts   = "Scripts Core Carregado!",

    -- ---- Predicados (rótulos do editor) --------------------------------------
    pred_always            = "sempre",
    pred_in_combat         = "em combate",
    pred_out_combat        = "fora de combate",
    pred_aoe2              = "AoE (2+ inimigos)",
    pred_single_target     = "alvo único",
    pred_has_enemy         = "alvo atacável",
    pred_moving            = "em movimento",
    pred_mana15            = "mana acima de 15%",
    pred_mana40            = "mana acima de 40%",
    pred_ranged_melee_out  = "fora de alcance melee",
    pred_ranged            = "fora da dead zone (ranged)",
    pred_melee_range       = "em alcance melee",
    pred_melee_combat      = "em alcance melee e em combate",

    rot_desc = "Ordem abaixo = prioridade. Padrão = guia do projeto; mudanças salvas por personagem. Toque em + para adicionar condição, em - para remover. Use as setas ^ e v para subir/descer; o check liga/desliga; clicar no ícone testa o flash.",
    rot_special_header = "Especial (do guia)",
    rot_special_prefix = "Especial: ",
    rot_share_button = "Compartilhar",
    rot_failed = "falhou",

    bless_bm = "|cFFFF8000Mestre das Feras:|r O vínculo com seu pet é sua maior arma! Destrua-os!",
    bless_mm = "|cFF69CCF0Atirador de Elite:|r Precisão mortal a quilômetros de distância! Fogo neles!",
    bless_sv = "|cFFABD473Sobrevivência:|r Mestre das armadilhas e do veneno! Prepare a emboscada!",
    bless_low = "|cFFCCCCCCRecruta Hunter:|r Aprendendo os caminhos da selva... Sobreviva!",
    bless_arms = "|cFF69CCF0Arms:|r Ode ao eixo da guerra — que cada golpe seja uma sentença!",
    bless_fury = "|cFFFF8000Fury:|r Sangue na lâmina — a fúria te revigorará!",
    bless_prot = "|cFFABD473Protection:|r Baluarte — sua muralha nunca cairá!",
    bless_ele = "|cFFFF8000Elemental:|r Aberração elemental — a tempestade lhe obedece!",
    bless_enh = "|cFF69CCF0Enhancement:|r Podem dobrar o ferro — a tempestade responde aos seus punhos!",
    bless_bal = "|cFFBD9CFFBalance:|r O equilíbrio é o caminho — as estrelas sussurram!",
    bless_cat = "|cFF69CCF0Feral:|r Entre no instinto — a selva te aceitará!",
    bless_rest = "|cFFABD473Restoration:|r O grande enodo te guiará!",
    bless_prot_pal = "|cFFFFD700Protection:|r Baluarte da Luz — sua muralha não cairá!",
    bless_ret = "|cFFFF8000Retribution:|r Pela Luz — cada golpe é um julgamento!",
    dbg_default_spec = "padrão",
    title_cat = "Feral — Gato (DPS)",
    title_bear = "Feral — Urso (tank)",
    title_rest = "Restauração",

    dbg_count_na = "Contagem indisponível",
    dbg_traits_absent = "C_ClassTalents/C_Traits ausentes",
    dbg_attackaction_absent = "C_ActionBar.IsAttackAction AUSENTE",
    dbg_attackaction_exists = "C_ActionBar.IsAttackAction existe (usado para localizar o slot de Atacar)",

    -- ---- Raciais --------------------------------------------------------------
    race_human    = "Humano",
    race_dwarf    = "Anão",
    race_nightelf = "Elfo Noturno",
    race_gnome    = "Gnomo",
    race_orc      = "Orc",
    race_undead   = "Morto-vivo",
    race_tauren   = "Tauren",
    race_troll    = "Troll",
    race_highorder = "Skyborne (High Order)",
    race_windshaper = "Skyborne (Windshaper)",

    race_greet_human    = "Você é um Humano, defensor de Stormwind. Cada homem por si!",
    race_greet_dwarf    = "Você é um Anão de Dun Morogh. Sua Pele de Pedra é sua fortaleza!",
    race_greet_nightelf = "Você é um Elfo Noturno, amante das sombras. Mescle-se à noite!",
    race_greet_gnome    = "Você é um Gnomo de Gnomeregan. Artista da Fuga, liberte-se das amarras!",
    race_greet_orc      = "Você é um Orc de Durotar. Fúria Sanguinária para a caça!",
    race_greet_undead   = "Você é um Morto-vivo, livre do Flagelo. Vontade dos Renegados!",
    race_greet_tauren   = "Você é um Tauren de Mulgore. Golpe de Guerra para controlar!",
    race_greet_troll    = "Você é um Troll da tribo Darkspear. Berserking para abater!",
    race_greet_highorder = "Você é um Skyborne da Ordem Maior. A terra canta — leia as linhas ley!",
    race_greet_windshaper = "Você é um Skyborne Windshaper. O vento obedece aos seus pés!",
    race_unmapped       = "|cff33ff99[SF Hunter]|r Raça não mapeada: %s",
}

-- ===========================================================================
-- English (default for non-ptBR clients)
-- ===========================================================================
local enUS = {}
do
    -- copy ptBR as fallback, then override everything with English
    for k, v in pairs(ptBR) do enUS[k] = v end

    -- ---- Core / Compat / SharedFunctions -----------------------------------
    enUS.compat_loaded     = "|cff33ff99SpellFlashForever:|r WotLK SpellFlash compatibility layer loaded."
    enUS.compat_module_failed = "|cffff0000[SF DEBUG]|r Module '%s' failed: %s"
    enUS.shared_unnamed    = "(unnamed)"

    -- ---- Minimap -------------------------------------------------------------
    enUS.minimap_toggle    = "|cff33ff99SpellFlashForever:|r minimap button %s."
    enUS.minimap_shown     = "shown"
    enUS.minimap_hidden    = "hidden"
    enUS.minimap_tt_open   = "Click to open/close the menu."
    enUS.minimap_tt_drag   = "Drag to reposition. Use /sfminimap to hide/show."

    -- ---- KeyButton -----------------------------------------------------------
    enUS.key_lock          = "Key button movement locked."
    enUS.key_unlock        = "Drag the button to move it."
    enUS.key_error         = "Key button error: %s"
    enUS.key_help          = "/sfkey: shows the key of the ability currently glowing"
    enUS.key_off_hint      = "Key button disabled. Use /sfkey on to re-enable."
    enUS.key_on            = "Key button enabled."
    enUS.key_pos_reset     = "Key button position restored."
    enUS.key_hidden        = "Key button hidden."
    enUS.key_shown         = "Key button visible."
    enUS.key_debug_on      = "Debug enabled. Flash a button and watch the chat messages."
    enUS.key_debug_off     = "Debug disabled."
    enUS.key_commands      = "Commands: on/off, lock/unlock, reset, show, hide, debug"

    -- ---- Debug / diagnostics --------------------------------------------------
    enUS.dbg_onflash_error   = "|cffff0000[SF DEBUG]|r OnFlash error: %s"
    enUS.dbg_slots_occupied  = "|cffff0000[SF DEBUG]|r Occupied slots: %s"
    enUS.dbg_slot_not_found  = "|cffff0000[SF DEBUG]|r No action bar slot found for '%s'."
    enUS.dbg_slot_no_button  = "|cffff0000[SF DEBUG]|r Slot %s found for '%s' but no bar button matches it."
    enUS.dbg_category_id     = "|cff33ff99SpellFlashForever:|r Settings category registered. ID: %s"
    enUS.dbg_category_nil    = "|cffff0000SpellFlashForever:|r ERROR: SettingsCategoryID is nil!"
    enUS.dbg_settings_missing = "|cffff0000SpellFlashForever:|r Settings API not available!"
    enUS.dbg_loaded          = "|cff33ff99SpellFlashForever:|r loaded (Class: %s). Type |cffffcc00/sf|r to open the menu."
    enUS.dbg_slash_header    = "|cff33ff99SpellFlashForever|r commands:"
    enUS.dbg_help_1          = "  /sf or /sfbyferal        - Open/close the visual settings window"
    enUS.dbg_help_2          = "  /sfbyferal flash <name>  - Flash a spell/item"
    enUS.dbg_help_3          = "  /sfbyferal size <n>      - Flash size (current: %s)"
    enUS.dbg_help_4          = "  /sfbyferal bright <n>    - Flash brightness (current: %s)"
    enUS.dbg_help_5          = "  /sfbyferal off           - Disable spell flashing"
    enUS.dbg_help_6          = "  /sfbyferal on            - Enable spell flashing"
    enUS.dbg_help_7          = "  /sfbyferal status        - Show status"
    enUS.dbg_help_8          = "  /sfbyferal key [on|off]  - Button showing the key of the ability (see /sfkey)"
    enUS.dbg_flash_disabled  = "|cffff0000SpellFlashForever:|r flashing is disabled. Use /sfbyferal on"
    enUS.dbg_flashing        = "|cff33ff99SpellFlashForever:|r flashing: %s"
    enUS.dbg_size_current    = "|cff33ff99SpellFlashForever:|r current size: %s"
    enUS.dbg_size_set        = "|cff33ff99SpellFlashForever:|r size set to: %s"
    enUS.dbg_bright_set      = "|cff33ff99SpellFlashForever:|r brightness set to: %s"
    enUS.dbg_off             = "|cff33ff99SpellFlashForever:|r spell flashing disabled"
    enUS.dbg_on              = "|cff33ff99SpellFlashForever:|r spell flashing enabled"
    enUS.dbg_status          = "|cff33ff99SpellFlashForever:|r class: %s | race: %s"
    enUS.dbg_race_detected   = "|cff33ff99SpellFlashForever:|r Hunter race detected: %s"
    enUS.dbg_flash_off       = "|cff33ff99SpellFlashForever:|r flash off: %s"
    enUS.dbg_status_sizes    = "|cff33ff99SpellFlashForever:|r size: %s | brightness: %s"
    enUS.dbg_debug_status    = "|cff33ff99SpellFlashForever:|r debug: %s"
    enUS.dbg_key_button      = "|cff33ff99SpellFlashForever:|r key button: %s"
    enUS.dbg_debug_toggle    = "|cff33ff99SpellFlashForever:|r debug %s"
    enUS.dbg_debug_on_word   = "enabled"
    enUS.dbg_debug_off_word  = "disabled"
    enUS.dbg_traits_header   = "|cff33ff99SpellFlashForever:|r === C_Traits / C_ClassTalents ==="
    enUS.dbg_traits_nil      = "|cffff0000SpellFlashForever:|r C_Traits: nil"
    enUS.dbg_traits          = "|cff33ff99SpellFlashForever:|r C_Traits: %s"
    enUS.dbg_classtalents_nil = "|cffff0000SpellFlashForever:|r C_ClassTalents: nil"
    enUS.dbg_classtalents    = "|cff33ff99SpellFlashForever:|r C_ClassTalents: %s"
    enUS.dbg_traits_end      = "|cff33ff99SpellFlashForever:|r === end ==="
    enUS.dbg_unknown_command = "|cffff0000SpellFlashForever:|r unknown command: %s. Use /sfbyferal help"

    -- ---- General / About panels -----------------------------------------------
    enUS.tab_general       = "General"
    enUS.tab_about         = "About"

    enUS.opt_general_title = "|cff33ff99General Settings|r"
    enUS.opt_general_desc  = "Adjust the visual options and suggestion behavior."
    enUS.opt_flash_enable  = "Enable Spell Suggestion Flashing"
    enUS.opt_flash_enable_tt = "Flashes the recommended abilities on your action bars."
    enUS.opt_flash_border  = "Border glow (outline)"
    enUS.opt_flash_border_tt = "Flashes the button border instead of the overlaid star glow."
    enUS.opt_flash_solid   = "Solid color (no transparency)"
    enUS.opt_flash_solid_tt = "Keeps the glow at full opacity, no fading."
    enUS.opt_single_color  = "Same color for all glows"
    enUS.opt_single_color_tt = "When enabled, all flashes use the chosen color and ignore each individual color."
    enUS.col_yellow = "Yellow"
    enUS.col_white = "White"
    enUS.col_red = "Red"
    enUS.col_green = "Green"
    enUS.col_blue = "Blue"
    enUS.col_aqua = "Cyan"
    enUS.col_orange = "Orange"
    enUS.col_purple = "Purple"
    enUS.col_pink = "Pink"
    enUS.col_gray = "Gray"
    enUS.opt_suppress_range = "Suppress range check"
    enUS.opt_suppress_range_tt = "Flash buttons even if the target is out of range."
    enUS.opt_suppress_speed = "Suppress movement check"
    enUS.opt_suppress_speed_tt = "Flash buttons even while moving."
    enUS.opt_disable_immune  = "Disable automatic immunity detection"
    enUS.opt_disable_immune_tt = "Do not register creature immunities against magic types."
    enUS.opt_flash_size    = "Flash Size"
    enUS.opt_flash_bright  = "Flash Brightness / Opacity"
    enUS.opt_flash_border_width = "Border width"
    enUS.opt_flash_border_width_tt = "Border glow mode only: extra width of the frame in pixels (0 = flush with the button)."
    enUS.opt_bar_rank_warnings = "Warn about outdated abilities on the action bar"
    enUS.bar_rank_warn = "|cffffcc00[SpellFlash Forever]|r %s on the action bar is Rank %d; you already know Rank %d. Drag it from the spellbook to update."
    enUS.opt_minimap       = "Show minimap button"
    enUS.opt_minimap_tt    = "Shows a minimap button that opens/closes this menu. Drag it to reposition. Use /sfminimap to hide/show it too."
    enUS.opt_keybutton     = "Show button with the ability key"
    enUS.opt_keybutton_tt  = "Shows an extra button displaying the key to press for the currently flashing ability."
    enUS.opt_keybutton_lock = "Lock the key button (no dragging)"
    enUS.opt_keybutton_lock_tt = "Prevents the key button from being dragged by accident. Use together with 'Show button with the ability key'."
    enUS.opt_test_button   = "Test Flash"
    enUS.opt_test_msg      = "|cff33ff99SpellFlash Forever:|r Testing flash on Button 1."
    enUS.opt_test_fail     = "|cff33ff99SpellFlash Forever:|r Button 1 not found for testing."

    enUS.about_what_is      = "What is this"
    enUS.about_what_is_body = "SpellFlash Forever is a rotation assistant for WoW Forever. Every 0.2s it evaluates your target, your spec, your talents, your mana, your range and the combat state — and flashes the action bar button for the ability you should use right now.\n\nEach ability flashes with the color of its function: primary damage (yellow), AoE (purple), interrupt/control (cyan), defensive (red), utility (green) and situational (pink/orange)."
    enUS.about_includes     = "What is included"
    enUS.about_includes_body = "• SpellFlashForever core: suggestion driver, combat aura beliefs, per-character visual rotation editor (/sf, \"Custom rotation\" section on each class tab), key button on your bars, minimap button.\n• Class modules: Hunter, Shaman, Warrior and Druid — each with the recommended Forever rotation as default, editable per character.\n• One error at a time; every change is recorded in the project history."
    enUS.about_howto        = "How to use"
    enUS.about_howto_body   = "/sf opens (and closes) this window. Each class tab has the module toggle, spec detection (with override) and the rotation editor. /sf status shows the module state. /sfminimap toggles the minimap button."
    enUS.about_credits      = "Credits — creation"
    enUS.about_credits_body = "|cffffffffMarcus|r — SpellFlash Forever project creation and direction.\n\n|cffffffffInkling 2 Small Free (OpenCode)|r — technology and development partner: artificial intelligence used as a pair programmer (research, architecture, code, testing and documentation).\n\nOriginal SpellFlash (WotLK 3.3.5a): Exalter (Druid), BigRedBrent (Warrior), SF Community (Shaman) and the SpellFlash community. This is a port/derivative with a deep architecture and rotation rework for the Forever."
    enUS.about_thanks       = "Thanks"
    enUS.about_thanks_body  = "To the WoW Forever team, the rotation theorycrafting community and everyone who tested the addon in game and reported each bug — every fix became an entry in the project history."
    enUS.about_version      = "Version %s-forever · WoW Forever (Interface 16001)"

    enUS.settings_hint      = "Click the button below to open the full SpellFlash Forever settings window."
    enUS.settings_open      = "Open SpellFlash Forever Menu"

    -- ---- Rotation editor ------------------------------------------------------
    enUS.rot_axis_combat   = "1. Combat"
    enUS.rot_axis_env      = "2. Environment"
    enUS.rot_axis_target   = "3. Target"
    enUS.rot_axis_range    = "4. Range"
    enUS.rot_axis_resource = "5. Resource"
    enUS.rot_axis_aoe      = "6. Area"
    enUS.axis_both         = "both"
    enUS.axis_in_combat    = "in combat"
    enUS.axis_out_combat   = "out of combat"
    enUS.axis_any          = "any"
    enUS.axis_attackable   = "attackable"
    enUS.axis_casting      = "casting"
    enUS.axis_no_attack    = "no attackable target"
    enUS.axis_ranged       = "ranged (> dead zone)"
    enUS.axis_melee        = "melee / dead zone"
    enUS.axis_dead_zone    = "in the dead zone"
    enUS.axis_mana15       = "mana > 15%"
    enUS.axis_mana40       = "mana > 40%"
    enUS.axis_mana50       = "mana > 50%"
    enUS.axis_rage40       = "rage >= 40"
    enUS.axis_energy40     = "energy >= 40"
    enUS.axis_combo5       = "combo >= 5"
    enUS.axis_aoe_2        = "AoE (2+)"
    enUS.axis_single       = "single target"

    enUS.rot_header        = "|cff33ff99Rotation Editor (editable)|r"
    enUS.rot_no_condition  = "|cff888888- no conditions -|r"
    enUS.rot_always        = "- always -"
    enUS.rot_none_active   = "(no condition active)"
    enUS.rot_add_condition = "Add condition"
    enUS.rot_remove_condition = "Remove condition"
    enUS.rot_clear_all     = "Clear all conditions"
    enUS.rot_spec_prefix   = "Spec: "
    enUS.rot_save          = "Save rotation"
    enUS.rot_restore       = "Restore default"
    enUS.rot_saved         = "|cff33ff99[SF Rot]|r Rotation saved (per character) for %s / %s."
    enUS.rot_share         = "|cff33ff99Share rotation|r (!SFROT-1! format, Hekili style)"
    enUS.rot_yours         = "Your rotation - copy and send:"
    enUS.rot_import_title  = "Import - paste someone else's rotation here:"
    enUS.rot_import_button = "Import rotation"
    enUS.rot_import_help   = "Imports only this tab's spec. Unknown nodes are ignored. The import replaces your current custom rotation for this spec (restore default reverts it)."
    enUS.rot_import_failed = "|cffff0000[SF Rot]|r Import failed: %s"
    enUS.rot_imported      = "Rotation imported (%d nodes"
    enUS.rot_unknown_skipped = "; %d unknown node(s) skipped"
    enUS.rot_select_all    = "Select all"
    enUS.rot_custom_title  = "Custom rotation"
    enUS.rot_click_test    = "Click: test the flash on the action bar"
    enUS.rot_not_known     = "|cff33ff99[SF Rot]|r You don't know this spell yet."
    enUS.rot_bad_char      = "invalid character: '%s'"
    enUS.rot_bad_prefix    = "prefix !SFROT-1! not found"
    enUS.rot_decode_failed = "decoding failed: %s"
    enUS.rot_no_header     = "SFR1 header not found"
    enUS.rot_wrong_module  = "rotation is from another module (%s)"
    enUS.rot_wrong_spec    = "rotation is for another spec (%s)"
    enUS.rot_no_nodes      = "no recognized node in the string"
    enUS.rot_unknown_spec  = "unknown spec: %s"

    -- ---- Modules (tabs, toggles, specs) ---------------------------------------
    enUS.mod_desc_abilities = "Toggle the %s rotation: if disabled, the module stops suggesting abilities (general suggestions keep working in General)."
    enUS.mod_desc_spells    = "Toggle the %s rotation: if disabled, the module stops suggesting spells (general suggestions keep working in General)."
    enUS.mod_toggle         = "Enable %s rotation suggestions"
    enUS.mod_toggle_hint_long = "Turning this off is the same as 'spell_flashing_off' for this module only. Flashing happens on your action bar buttons (any skill/macro with its key bound)."
    enUS.mod_toggle_hint    = "Turning this off is the same as 'spell_flashing_off' for this module only."
    enUS.mod_spec_title     = "Force rotation (otherwise auto-detected):"

    enUS.spec_bm            = "Beast Mastery (BM)"
    enUS.spec_mm            = "Marksmanship (MM)"
    enUS.spec_sv            = "Survival (SV)"
    enUS.spec_arms          = "Arms (arms PvE)"
    enUS.spec_prot          = "Protection (tank)"
    enUS.spec_ele           = "Elemental (caster)"
    enUS.spec_enh           = "Enhancement (melee)"
    enUS.spec_resto         = "Restoration (healer)"
    enUS.spec_balance       = "Balance (caster)"
    enUS.spec_ret           = "Retribution (DPS)"

    enUS.mod_druid_spec_hint  = "Use this if the rotation isn't being recognized in combat. If none is checked, the Druid detects the spec by itself (talent points per tree via C_Traits)."
    enUS.mod_hunter_spec_hint = "Use this if the rotation isn't being recognized in combat. If none is checked, the Hunter detects the spec by itself (C_SpecializationInfo / talents / signature spells / SV)."
    enUS.mod_pal_spec_hint    = "Use this if the rotation isn't being recognized in combat. Holy is not supported (detection routes don't exist); use the override above."
    enUS.mod_shaman_spec_hint = "Use this if the rotation isn't being recognized in combat. If none is checked, the Shaman detects the spec by itself (C_Traits + spell signature)."
    enUS.mod_warrior_spec_hint = "Use this if the rotation isn't being recognized in combat. If none is checked, the Warrior detects the spec by itself (C_Traits per tree)."

    enUS.mod_not_available  = "|cffff9900[SF %s]|r SpellFlashForever not available to register the %s tab."
    enUS.mod_loaded         = "|cFF00FF00[SF %s]|r %s"
    enUS.mod_load_functions = "Functions loaded!"
    enUS.mod_load_options   = "Options loaded!"
    enUS.mod_load_scripts   = "Core Scripts loaded!"

    -- ---- Predicates (editor labels) -------------------------------------------
    enUS.pred_always            = "always"
    enUS.pred_in_combat         = "in combat"
    enUS.pred_out_combat        = "out of combat"
    enUS.pred_aoe2              = "AoE (2+ enemies)"
    enUS.pred_single_target     = "single target"
    enUS.pred_has_enemy         = "attackable target"
    enUS.pred_moving            = "moving"
    enUS.pred_mana15            = "mana above 15%"
    enUS.pred_mana40            = "mana above 40%"
    enUS.pred_ranged_melee_out  = "out of melee range"
    enUS.pred_ranged            = "out of the dead zone (ranged)"
    enUS.pred_melee_range       = "in melee range"
    enUS.pred_melee_combat      = "in melee range and in combat"

    -- ---- Races -----------------------------------------------------------------
    enUS.race_human    = "Human"
    enUS.race_dwarf    = "Dwarf"
    enUS.race_nightelf = "Night Elf"
    enUS.race_gnome    = "Gnome"
    enUS.race_orc      = "Orc"
    enUS.race_undead   = "Undead"
    enUS.race_tauren   = "Tauren"
    enUS.race_troll    = "Troll"
    enUS.race_highorder = "Skyborne (High Order)"
    enUS.race_windshaper = "Skyborne (Windshaper)"

    enUS.race_greet_human    = "You are a Human, defender of Stormwind. Every man for himself!"
    enUS.race_greet_dwarf    = "You are a Dwarf from Dun Morogh. Your Stoneform is your fortress!"
    enUS.race_greet_nightelf = "You are a Night Elf, lover of the shadows. Blend into the night!"
    enUS.race_greet_gnome    = "You are a Gnome from Gnomeregan. Escape Artist, break free from your bonds!"
    enUS.race_greet_orc      = "You are an Orc from Durotar. Blood Fury for the hunt!"
    enUS.race_greet_undead   = "You are an Undead, free from the Scourge. Will of the Forsaken!"
    enUS.race_greet_tauren   = "You are a Tauren from Mulgore. War Stomp to control!"
    enUS.race_greet_troll    = "You are a Darkspear Troll. Berserking to destroy!"
    enUS.race_greet_highorder = "You are a High Order Skyborne. The earth sings — read the ley lines!"
    enUS.race_greet_windshaper = "You are a Windshaper Skyborne. The wind obeys your feet!"
    enUS.race_unmapped       = "|cff33ff99[SF Hunter]|r Unmapped race: %s"    enUS.pred_not_cat_form = "you are NOT in animal form (Cat Form)"
    enUS.pred_bear_form = "you are in Bear Form"
    enUS.pred_not_moonkin = "you are NOT in Moonkin Form"
    enUS.pred_mark_missing = "Mark of the Wild missing (caster/Moonkin, not mounted)"
    enUS.pred_thorns_missing = "Thorns missing (caster/Moonkin, not mounted)"
    enUS.pred_natures_grasp_missing = "Nature's Grasp missing (not mounted)"
    enUS.pred_insect_swarm_missing = "Insect Swarm missing on the target"
    enUS.pred_moonfire_missing = "Moonfire missing on the target"
    enUS.pred_behind = "behind the target"
    enUS.pred_cat_form_combo = "Cat Form, 40+ energy, PvE"
    enUS.pred_combo5 = "5 combo points"
    enUS.pred_energy40 = "40+ energy"
    enUS.pred_my_hp35 = "you are below 35%"
    enUS.pred_aoe_dead_zone = "AoE and out of the dead zone"
    enUS.pred_aoe_pve_mana15 = "AoE, PvE and mana above 15%"
    enUS.pred_single_dead_zone = "single target and out of the dead zone"
    enUS.pred_enemy_combat_dead_zone = "attackable target, in combat and out of the dead zone"
    enUS.pred_interruptible_nocc = "target casting (interruptible), out of the dead zone and no CC on them"
    enUS.pred_pet_interruptible = "target casting, pet alive, out of the dead zone and target without CC"
    enUS.pred_pvp_target_mana = "PvP and target with mana"
    enUS.pred_pvp_target_melee = "PvP and Warrior/Rogue target"
    enUS.pred_no_viper = "no Viper Sting on the target"
    enUS.pred_no_scorpid = "no Scorpid Sting on the target"
    enUS.pred_pvp_viper = "PvP, target with mana and no Viper Sting"
    enUS.pred_pvp_scorpid = "PvP, Warrior/Rogue target and no Scorpid Sting"
    enUS.pred_no_serpent = "no Serpent Sting active (attackable target, out of melee)"
    enUS.pred_no_any_sting = "no sting active on the target"
    enUS.pred_melee_dead_zone = "in melee/dead zone"
    enUS.pred_dead_zone_not_melee = "in the dead zone and out of melee"
    enUS.pred_pvp_no_clip = "melee/dead zone, PvP and target without Wing Clip"
    enUS.pred_melee_interruptible = "melee with attackable and casting target"
    enUS.pred_within_8_aoe = "within range (≤ 8 yd) in AoE"
    enUS.pred_within_8_st = "within range (≤ 8 yd) on single target"
    enUS.pred_pve_no_serpent = "PvE, no Serpent Sting active, out of melee"
    enUS.pred_no_serpent_belief = "no Serpent Sting active (via cast belief), out of melee"
    enUS.pred_pvp_hp30 = "PvP and you are below 30%"
    enUS.pred_aoe_and_enemy = "AoE with attackable target"
    enUS.pred_casting_stun = "attackable target casting (stun/interrupt)"
    enUS.pred_target_hp20 = "target below 20%"
    enUS.pred_undead_or_demon = "target is undead or demon (Exorcism)"
    enUS.pred_prot_fury = "Protection and Righteous Fury missing"
    enUS.pred_prot_shield = "Protection and Holy Shield missing"
    enUS.pred_ret_seal = "Retribution and Seal of Command missing"
    enUS.pred_casting_interrupt = "attackable target casting (interrupt)"
    enUS.pred_clearcasting = "Clearcasting active (Elemental Focus)"
    enUS.pred_chain_lightning_ok = "Chain Lightning ok (AoE or mana >= 50% or Clearcasting)"
    enUS.pred_lightning_shield = "Lightning Shield missing"
    enUS.pred_ele_flametongue = "Elemental and Flametongue missing"
    enUS.pred_enh_windfury = "Enhancement and Windfury missing"
    enUS.pred_enh_earth = "Enhancement and Strength of Earth missing"
    enUS.pred_flame_shock = "Flame Shock missing (attackable target, mana ok)"
    enUS.pred_fire_totem_aoe = "AoE with fire totem active"
    enUS.pred_fire_totem_magma = "AoE and fire totem missing (Magma)"
    enUS.pred_fire_totem_searing = "single target and fire totem missing (Searing)"
    enUS.pred_mana_spring = "Mana Spring missing (long fight or mana < 50%)"
    enUS.pred_aoe_mana15 = "AoE and mana above 15%"
    enUS.pred_maelstrom5 = "Maelstrom Weapon with 5 stacks"
    enUS.pred_rage40 = "rage above 40"
    enUS.pred_rage_enemy = "rage above 40 and attackable target"
    enUS.pred_aoe_rage40 = "AoE, rage above 40 and attackable target"
    enUS.pred_aoe_rage45 = "AoE, rage above 45 and attackable target"
    enUS.pred_shield_attackable = "with shield and attackable target"
    enUS.pred_shield = "with shield"
    enUS.pred_cast_not_berserker = "target casting and you are NOT in Berserker Stance (3)"
    enUS.pred_cast_berserker = "target casting and you are in Berserker Stance (3)"
    enUS.pred_cast_defensive = "target casting and you are in Defensive Stance (2)"
    enUS.pred_cast_shield = "target casting and you with a shield"
    enUS.pred_not_berserker = "you are NOT in Berserker Stance (3)"
    enUS.pred_out_battle_stance = "out of combat and you are NOT in Battle Stance (1)"
    enUS.pred_out_attackable_battle = "out of combat, attackable target and you are NOT in Battle Stance (1)"
    enUS.pred_out_attackable = "out of combat and attackable target"
    enUS.pred_out_shout = "out of combat and without Battle Shout"
    enUS.pred_combat_not_berserker = "in combat and you are NOT in Berserker Stance (3)"
    enUS.pred_not_defensive = "you are NOT in Defensive Stance (2)"
    enUS.pred_pvp_attackable = "PvP with attackable target"
    enUS.pred_target_casting = "target casting"
    enUS.pred_roar_missing = "Demoralizing Roar missing (Bear)"
    enUS.spec_feral = "Feral (Cat PvE) / Bear"
    enUS.spec_fury2h = "Fury (two-hand / dual)"
    enUS.cd_usage = "usage: /sfcd <spellID>"
    enUS.cd_spellid = "spellID=%s name=%s"
    enUS.cd_resolve_known = "resolve -> known rank: %s"
    enUS.cd_getcooldown_rank = "GetSpellCooldown(rank: %s): ok=%s type=%s"
    enUS.cd_rank_info = "  rank info.%s = %s (%s)"
    enUS.cd_info = "  info.%s = %s (%s)"
    enUS.cd_spellcooldown_rank = "SpellCooldown(rank: %s): timeLeft=%s dur=%s"
    enUS.cd_getcooldown_raw = "GetSpellCooldown(raw: %s): ok=%s type=%s"
    enUS.cd_return = "  return: %s"
    enUS.cd_duration = "GetSpellCooldownDuration: ok=%s type=%s value=%s"
    enUS.cd_duration_ignoredcf = "GetSpellCooldownDuration(id,ignoreGCD=true): ok=%s type=%s value=%s"
    enUS.cd_raw = "SpellCooldown(raw: %s): timeLeft=%s dur=%s"
    enUS.cd_action_slot = "Action slot for the known rank = %s"
    enUS.cd_cooldown_slot = "ActionCooldown(slot): timeLeft=%s dur=%s"
    enUS.cd_not_found = "no name found"
    enUS.cd_simulated = "CheckIfSpellCastable(simulated) = %s"
    enUS.cd_getcooldown_absent = "GetSpellCooldown: missing"
    enUS.drc_race = "playerRace=%s | racial=%s (%s)"
    enUS.drc_known_ok = "IsSpellKnown -> ok=%s known=%s"
    enUS.drc_known_absent = "C_SpellBook.IsSpellKnown MISSING"
    enUS.drc_info = "GetSpellInfo -> ok=%s name=%s"
    enUS.drc_cooldown_table = "  cd.%s = %s"
    enUS.drc_cooldown_ok = "GetSpellCooldown -> ok=%s"
    enUS.drc_usable = "IsSpellUsable -> ok=%s usable=%s power=%s"
    enUS.drc_spellknown = "SpellKnown() = %s"
    enUS.drc_cooldown_remaining = "RacialCooldownRemaining = %s"
    enUS.drc_incombat = "InCombat = %s"
    enUS.drc_canattack = "UnitCanAttack -> ok=%s canAttack=%s"
    enUS.drc_no_target = "no target"
    enUS.drc_should = "ShouldUseRacial() = %s"
    enUS.rot_desc = "Order below = priority. Default = project guide; changes are saved per character. Tap + to add a condition, - to remove one. Use the ^ and v arrows to move; the check toggles on/off; clicking the icon tests the flash."
    enUS.rot_special_header = "Special (from the guide)"
    enUS.rot_special_prefix = "Special: "
    enUS.rot_share_button = "Share"
    enUS.rot_failed = "failed"
    enUS.bless_bm = "|cFFFF8000Beast Mastery:|r Your pet's bond is your greatest weapon! Destroy them!"
    enUS.bless_mm = "|cFF69CCF0Marksmanship:|r Deadly precision at a distance! Take them down!"
    enUS.bless_sv = "|cFFABD473Survival:|r Master of traps and poison! Prepare the ambush!"
    enUS.bless_low = "|cFFCCCCCCHunter Recruit:|r Learning the ways of the wilds... Survive!"
    enUS.bless_arms = "|cFF69CCF0Arms:|r Ode to the war-fury — may every blow be a verdict!"
    enUS.bless_fury = "|cFFFF8000Fury:|r Blood on the blade — the fury will sustain you!"
    enUS.bless_prot = "|cFFABD473Protection:|r Bulwark — your wall will never fall!"
    enUS.bless_ele = "|cFFFF8000Elemental:|r Elemental aberration — the storm obeys you!"
    enUS.bless_enh = "|cFF69CCF0Enhancement:|r They can bend iron — the storm answers your fists!"
    enUS.bless_bal = "|cFFBD9CFFBalance:|r Balance is the path — the stars whisper!"
    enUS.bless_cat = "|cFF69CCF0Feral:|r Enter the instinct — the jungle will accept you!"
    enUS.bless_rest = "|cFFABD473Restoration:|r The great enodo will guide you!"
    enUS.bless_prot_pal = "|cFFFFD700Protection:|r Bulwark of Light — your wall shall not fall!"
    enUS.bless_ret = "|cFFFF8000Retribution:|r By the Light — every strike is a judgment!"
    enUS.dbg_default_spec = "default"
    enUS.title_cat = "Feral - Cat (DPS)"
    enUS.title_bear = "Feral - Bear (tank)"
    enUS.title_rest = "Restoration"
    enUS.dbg_count_na = "Talent count unavailable"
    enUS.dbg_traits_absent = "C_ClassTalents/C_Traits missing"
    enUS.dbg_attackaction_absent = "C_ActionBar.IsAttackAction MISSING"
    enUS.dbg_attackaction_exists = "C_ActionBar.IsAttackAction exists (used to locate the Attack slot)"

end

if GetLocale() == "ptBR" then
    for k, v in pairs(ptBR) do L[k] = v end
else
    for k, v in pairs(enUS) do L[k] = v end
end

-- Fallback: qualquer chave ausente devolve a própria chave (nunca nil),
-- para não quebrar a UI se algo faltar numa tradução futura.
setmetatable(L, { __index = function(_, key) return key end })

s.L = L
