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
mod.sfxQueue = {} -- The queue of sfx to be played
mod.roomsSfxPlayed = {} -- Rooms the sfx has been played in
mod.currentRoom = game:GetLevel():GetCurrentRoomDesc().SafeGridIndex -- The current room

---Check for [Balls] within the room and play the sound if it's found
function mod:CheckForSack()
    -- Config volume
    local volumeMod = (config.settings.volume) / 5

    -- Check for [Balls] in the room
    local items = Isaac.CountEntities(nil, EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, BALLS_ID)
    -- How many [Balls] were in the room when last entered
    local previous = mod.roomsSfxPlayed[mod.currentRoom]

    -- Proceed if the room previously has no [Balls] but now has [Balls]
    -- OR if the number of [Balls] has increased since last entered
    if (previous == nil and items > 0) or (previous ~= nil and items > previous) then
        -- Keep track of new number of [Balls] in the room
        mod.roomsSfxPlayed[mod.currentRoom] = items
        -- Get current time, in frames
        local currentFrame = Isaac.GetFrameCount()
        -- Queue the Vine Boom sfx
        mod.sfxQueue[1] = { currentFrame + mod.sfxStartDelay,
            function() sfx:Play(sfxVineBoom, mod.defaultVineBoomVolume * volumeMod, 2, false, 0.97, 0) end }
        -- Queue the 'Balls' sfx depending on how many [Balls] there are
        if items > 1 or (previous ~= nil and items > previous) then
            -- More than one, play horse pills 'Balls'
            mod.sfxQueue[2] = { currentFrame + mod.sfxStartDelay + mod.voicelineDelay,
                function() sfx:Play(sfxBallsMega, mod.defaultBallsVolume * volumeMod, 2, false, 0.97, 0) end }
        else
            -- Only one, play normal 'Balls'
            mod.sfxQueue[2] = { currentFrame + mod.sfxStartDelay + mod.voicelineDelay,
                function() sfx:Play(sfxBalls, mod.defaultBallsVolume * volumeMod, 2, false, 0.97, 0) end }
        end
    end

    -- Account for removing [Balls] and then re-adding it
    if previous ~= nil and items < previous then
        mod.roomsSfxPlayed[mod.currentRoom] = items
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
        mod.roomsSfxPlayed[mod.currentRoom] = nil
    end
    -- Get the new room number
    mod.currentRoom = game:GetLevel():GetCurrentRoomDesc().SafeGridIndex
end

---Clear any room data from a previous floor
function mod:OnNewLevel()
    mod.roomsSfxPlayed = {}
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.CheckForSack)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.OnNewLevel)