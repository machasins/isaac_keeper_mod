local mod = RegisterMod("Keeper's Balls", 1)
local game = Game()

local config = include("kss.mcm")

local sfx = SFXManager()

-- SFX --
local sfxVineBoom = Isaac.GetSoundIdByName("macha_vineBoom")
local sfxBalls = Isaac.GetSoundIdByName("macha_balls")
local sfxBallsMega = Isaac.GetSoundIdByName("macha_ballsMega")

local BALLS_ID = CollectibleType.COLLECTIBLE_KEEPERS_SACK -- ID for [Balls]

mod.defaultVineBoomVolume = 1.75 -- Vine boom volume
mod.defaultBallsVolume = 2.25 -- 'Balls' volume
mod.sfxStartDelay = 0 -- Delay before vine boom should start
mod.voicelineDelay = 50 -- Delay after vine boom to start 'Balls'
mod.blindPickedUp = 0 -- How many have been picked up while blind
mod.itemHasPlayed = {} -- Which items have played sound before
mod.sfxQueue = {} -- The queue of sfx to be played
mod.currentRoom = game:GetLevel():GetCurrentRoomDesc().SafeGridIndex -- The current room

function mod:HandleQueueSFX(mega, volumeMod)
    -- Get current time, in frames
    local currentFrame = Isaac.GetFrameCount()
    -- Queue the Vine Boom sfx
    mod.sfxQueue[1] = { currentFrame + mod.sfxStartDelay,
        function() sfx:Play(sfxVineBoom, mod.defaultVineBoomVolume * volumeMod, 2, false, 0.97, 0) end }
    -- Queue the 'Balls' sfx depending on how many [Balls] there are
    if mega then
        -- More than one, play horse pills 'Balls'
        mod.sfxQueue[2] = { currentFrame + mod.sfxStartDelay + mod.voicelineDelay,
            function() sfx:Play(sfxBallsMega, mod.defaultBallsVolume * volumeMod, 2, false, 0.97, 0) end }
    else
        -- Only one, play normal 'Balls'
        mod.sfxQueue[2] = { currentFrame + mod.sfxStartDelay + mod.voicelineDelay,
            function() sfx:Play(sfxBalls, mod.defaultBallsVolume * volumeMod, 2, false, 0.97, 0) end }
    end
end

---Check for [Balls] within the room and play the sound if it's found
function mod:CheckForSack()
    -- Config volume
    local volumeMod = (config.settings.volume) / 5

    -- Whether a sound should be played
    local play = false
    -- How many sounds have already been played
    local havePlayed = 0

    -- Handle Curse of the Blind
    if config.settings.handleBlind and (game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND) == LevelCurse.CURSE_OF_BLIND then
        -- The number of [Balls] that have been picked up in the current room
        havePlayed = mod.blindPickedUp
        -- Loop through all players and count how many are holding [Balls]
        local numPlayer = game:GetNumPlayers()
        for i = 0, numPlayer do
            local player = game:GetPlayer(i)
            local playerData = player:GetData()
            local heldItem = player.QueuedItem.Item
            if heldItem and heldItem.ID == BALLS_ID then
                -- Only count if [Balls] hasn't already been counted
                if not playerData.KBHasHeldItem then
                    play = true
                    mod.blindPickedUp = mod.blindPickedUp + 1
                    -- Mark this item as being counted
                    playerData.KBHasHeldItem = true
                end
            else
                -- Mark this player as not holding a valid item
                playerData.KBHasHeldItem = false
            end
        end
    else
        for _, item in pairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)) do
            if item.SubType == BALLS_ID then
                if mod.itemHasPlayed[item.InitSeed] == true then
                    havePlayed = havePlayed + 1
                else
                    play = true
                    mod.itemHasPlayed[item.InitSeed] = true
                end
            elseif mod.itemHasPlayed[item.InitSeed] == true then
                havePlayed = havePlayed + 1
            end
        end
    end

    -- Play the sound if needed
    if play then
        -- Play the sfx
        mod:HandleQueueSFX(havePlayed > 0, volumeMod)
    end

    -- Sub function to play the sounds after a period of time
    mod:PlaySFX()
end

---Play queued sounds after a delay
function mod:PlaySFX()
    -- Get the current time, in frames
    local currentFrame = Isaac.GetFrameCount()
    -- Loop through the queue
    for i, s in pairs(mod.sfxQueue) do
        -- If the effect exists and the time to play it is here,
        if s ~= nil and currentFrame >= s[1] then
            -- Call the callback to play the sfx
            s[2]()
            -- Remove sfx from queue
            mod.sfxQueue[i] = nil
        end
    end
end

---Get room number when entering new room
function mod:OnNewRoom()
    -- Config for playing every time you enter a room
    if not config.settings.oncePerRoom then
        -- If config not set, disregard what was in the previous room
        mod.itemHasPlayed = {}
    end
end

---Clear any room data from a previous floor
function mod:OnNewLevel()
    mod.itemHasPlayed = {}
    mod.blindPickedUp = 0
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.CheckForSack)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.OnNewLevel)