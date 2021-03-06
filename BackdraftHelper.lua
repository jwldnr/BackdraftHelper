local AddonName, Addon = ...

-- locals and speed
local select = select
local pairs = pairs

local _G = _G
local CreateFrame = CreateFrame
local UnitBuff = UnitBuff

local ActionButton_ShowOverlayGlow = ActionButton_ShowOverlayGlow
local ActionButton_HideOverlayGlow = ActionButton_HideOverlayGlow

local GetActionInfo = GetActionInfo

local GetSpellInfo = GetSpellInfo
local GetMacroSpell = GetMacroSpell

local ACTION_BUTTON_TEMPLATES = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarLeftButton",
    "MultiBarRightButton"
}

local UNIT_TAG_PLAYER = "player"

local BACKDRAFT = "Backdraft"

local ABILITY_TYPE_SPELL = "spell"
local ABILITY_TYPE_MACRO = "macro"

local ABILITIES = {
    ["Chaos Bolt"] = true,
    ["Incinerate"] = true
}

-- main
function Addon:Load()
    self.frame = CreateFrame("Frame", nil)
    
    self.frame:SetScript("OnEvent", function(_, ...)
        self:OnEvent(...)
    end)

    self.frame:RegisterEvent("ADDON_LOADED")
    self.frame:RegisterEvent("PLAYER_LOGIN")
end

function Addon:OnEvent(event, ...)
    local action = self[event]
  
    if (action) then
        action(self, ...)
    end
end

function Addon:HasBuff(name)
    for i = 1, #self.buffs do
        if (self.buffs[i] == name) then
            return true
        end
    end

    return false
end

function Addon:UpdateActionButtons()
    self.buttons = {}

    for _, template in pairs(ACTION_BUTTON_TEMPLATES) do
        for i = 1, 12 do
            local button = _G[template..i]
            local type, id = GetActionInfo(button.action)
            local name = nil

            if (id and type == ABILITY_TYPE_SPELL) then
                name = GetSpellInfo(id)
            end

            if (id and type == ABILITY_TYPE_MACRO) then
                name = GetSpellInfo(select(1, GetMacroSpell(id)))
            end

            -- only save a reference to abilities we're tracking
            if (name and ABILITIES[name]) then
                self.buttons[button] = name
            end
        end
    end
end

function Addon:ToggleButtonOverlays()
    self.buffs = {}

    local i = 1
    local buff = UnitBuff(UNIT_TAG_PLAYER, i)

    while (buff) do
        if (buff == BACKDRAFT) then
            self.buffs[#self.buffs + 1] = buff
        end

        i = i + 1
        buff = UnitBuff(UNIT_TAG_PLAYER, i)
    end

    for button, _ in pairs(self.buttons) do
        if (self:HasBuff(BACKDRAFT)) then
            ActionButton_ShowOverlayGlow(button)
        else
            ActionButton_HideOverlayGlow(button)
        end
    end
end

function Addon:ADDON_LOADED(name)
    if (name == AddonName) then
        self.frame:RegisterUnitEvent("UNIT_AURA", UNIT_TAG_PLAYER)

        print(name, "loaded")

        self.frame:UnregisterEvent("ADDON_LOADED")
    end
end

function Addon:UNIT_AURA()
    self:UpdateActionButtons()
    self:ToggleButtonOverlays()
end

function Addon:PLAYER_LOGIN()
    self:UpdateActionButtons()
    self:ToggleButtonOverlays()

    self.frame:UnregisterEvent("PLAYER_LOGIN")
end

-- begin
Addon:Load()