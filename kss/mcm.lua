local json = require("json")

local mod = RegisterMod("Keeper's Balls MCM", 1)

mod.name = "Keeper's Balls"
mod.settings = {
    oncePerRoom = true,
    handleBlind = true,
    volume = 5
}

---Load saved config data
function mod:Load()
    if not mod:HasData() then
        return
    end

    local jsonString = mod:LoadData()
    mod.settings = json.decode(jsonString)
    
    local defaults = {
        oncePerRoom = true,
        handleBlind = true,
        volume = 5
    }
    for key, value in pairs(defaults) do
        if mod.settings[key] == nil then
            mod.settings[key] = value
        end
    end
end

---Save config data
function mod:Save()
    local jsonString = json.encode(mod.settings)
    mod:SaveData(jsonString)
end

---Configure the mod menu
function mod:ConfigMenuInit()
    if ModConfigMenu == nil then
        return
    end

    -- Reset if reloading
    ModConfigMenu.RemoveCategory(mod.name)

    -- Load data
    mod:Load()

    -- Main Category
    ModConfigMenu.UpdateCategory(
        mod.name,
        {
            Info = {
                "Settings for the mod that says 'Balls'",
                "This is truly a Mattman moment"
            }
        }
    )

    -- Setting for when to play sfx
    ModConfigMenu.AddSetting(
        mod.name,
        nil,
        {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return mod.settings.oncePerRoom
            end,
            Display = function()
                return "Only play once: " .. (mod.settings.oncePerRoom and "on" or "off")
            end,
            OnChange = function (b)
                mod.settings.oncePerRoom = b
                mod:Save()
            end,
            Info = {
                "Play the sound only the first time you enter a room with",
                "Keeper's Sack (Off = Play every time you enter the room)"
            }
        }
    )

    -- Setting for respecting Curse of the Blind
    ModConfigMenu.AddSetting(
        mod.name,
        nil,
        {
            Type = ModConfigMenu.OptionType.BOOLEAN,
            CurrentSetting = function()
                return mod.settings.handleBlind
            end,
            Display = function()
                return "Respect Curse of the Blind: " .. (mod.settings.handleBlind and "on" or "off")
            end,
            OnChange = function (b)
                mod.settings.handleBlind = b
                mod:Save()
            end,
            Info = {
                "Whether to respect Curse of the Blind and not play the sound",
                "until picking up the item (Off = Play regardless)"
            }
        }
    )
    -- Setting for sfx volume
    ModConfigMenu.AddSetting(
        mod.name,
        nil,
        {
            Type = ModConfigMenu.OptionType.SCROLL,
            CurrentSetting = function()
                return mod.settings.volume
            end,
            Display = function()
                return "Volume: $scroll" .. mod.settings.volume
            end,
            OnChange = function (n)
                mod.settings.volume = n
                mod:Save()
            end,
            Info = {
                "Volume the sound will play at"
            }
        }
    )
end

-- Init the config menu
mod:ConfigMenuInit()

return mod