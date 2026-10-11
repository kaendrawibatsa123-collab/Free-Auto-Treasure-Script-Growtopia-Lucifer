-- Free Script By Berlinn <3
-- Discord: berlinn1
-- Dm me if you find bug in my script

local WorldsSetting = {
    worldTreasure = {
        "BERLINNTREASURE11",

        -- Change this to your worlds
    },
    worldTreasureId = 'KAKA1', -- id door world treasure
    storageWorld =  'BRLNPEPPER', -- storage worlds
    storageWorldId = 'KAKA1', -- storage world id
}

local Delay = {
    dynamicDelay = {
        enabled = true, -- set true for dynamic delay, reduce bot detection
    },
    -- ignore this if dynamicDelay true
    DelayBreak = 150, -- you can change this (miliseconds),
    DelayWarp = 5000, -- you can change this (miliseconds),
}

local onlyBreakTreasure = true -- set true for only break treasure, if false bot will break other items like altar, etc

-- ================= Code Area (Dont Touch)
rewardsId = {7624, 7625, 7630, 7631, 7626, 7627, 440, 441, 7590, 7764, 2226, 2227}
bot = getBot()

local nuked = false
local stuck = false
local bot = getBot()
bot.auto_collect = true
local trashId = { 3564, 3565, 9380, 9381, 3556, 3557, 10102, 9400, 3568, 3570, 3571, 3573, 3572, 9393, 3569, 3568, 7620, 7621 }

local function log(text)
    return print('[' .. bot.name .. '] ' .. text)
end


local function findPath(x, y)
    for i, node in pairs(bot:getPath(x, y)) do
        if bot:isInWorld() then
            bot:moveTile(node.x, node.y)
            sleep(100)
        end
    end
end

local function warp(world, id)
    world = world:upper()
    id = id or ''
    nuked = false
    stuck = false
    if not bot:isInWorld(world) then
        addEvent(Event.variantlist, function(var, netid)
            if var:get(0):getString() == "OnConsoleMessage" then
                if var:get(1):getString() == "That world is inaccessible." then
                    nuked = true
                    unlistenEvents()
                end
            end
        end)
        while not bot:isInWorld(world) and not nuked do
            bot:warp(id == '' and world or world .. ('|' .. id))
            sleep(15000)
            listenEvents(5)
        end
        removeEvent(Event.variantlist)
    end
    if bot:isInWorld(world) and getTile(bot.x, bot.y).fg == 6 and id ~= '' then
        local count = 0
        while getTile(bot.x, bot.y).fg == 6 and not stuck do
            bot:warp(id == '' and world or world .. ('|' .. id))
            sleep(5000)
            count = count + 1
            if count % 5 == 0 then
                stuck = true
            end
        end
    end
end

local function findItem(id)
    return getInventory():findItem(id)
end

local function trash()
    for _, itm in pairs(trashId) do
        for _, inv in pairs(getInventory():getItems()) do
            if itm == inv.id then
                bot:trash(inv.id, findItem(inv.id))
                sleep(500)
            end
        end
    end
end

local function isCanfindPath(x, y)
    return (#bot:getPath(x, y) == 0 and bot:isInTile(x, y)) or
        (#bot:getPath(x, y) ~= 0 and not bot:isInTile(x, y))
end

local function Reconnect(world, id, x, y)
    if bot.status ~= BotStatus.online then
        local sended = false
        while bot.status ~= BotStatus.online or bot:getPing() == 0 do
            sleep(10000)
            if bot.status == BotStatus.account_banned then
                if not sended then
                    log("Failed to reconnected,account is banned")
                    sended = true
                end
            end
        end
        sleep(5000)
    end
    if bot.status == BotStatus.online then
        if world and not bot:isInWorld() then
            warp(world, id)
            if x and y then
                while isCanfindPath(x, y) and not bot:isInTile(x, y) do
                    findPath(x, y)
                    sleep(500)
                end
            end
        end
    end
end

addEvent(Event.variantlist, function(var, world)
    if var:get(0):getString() == "OnConsoleMessage" then
        vartext = var:get(1):getString()
        if vartext:find("kkkkkkkkkkkkk") then
            log('hard warp detected (The system is currently experiencing high loads)')
            bot:warp(world)
            unlistenEvents()
        end
    end
end)

local function distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

local function successPath(tile, x, y)
    local dirrection = {
        { x = 1,  y = 0 },
        { x = -1, y = 0 },
        { x = 0,  y = 1 },
        { x = 0,  y = 0 },
        { x = 0,  y = -1 },
    }
    for _, dirr in pairs(dirrection) do
        local newPathX = dirr.x + tile.x
        local newPathY = dirr.y + tile.y
        if newPathX == x and newPathY == y then
            return true
        end
    end
    return false
end

local function getTilesFg(id, tilese)
    local tiles = {}
    for _, tile in pairs(tilese) do
        if tile.fg == id and hasAccess(tile.x, tile.y) > 0 then
            table.insert(tiles, { x = tile.x, y = tile.y, distance = distance(bot.x, bot.y, tile.x, tile.y) })
        end
    end

    table.sort(tiles, function(a, b) return a.distance < b.distance end)

    for _, tile in ipairs(tiles) do
        tile.distance = nil
    end

    return tiles
end

local function isPunchable(x, y)
    return getTile(x, y) and hasAccess(x, y) > 0 and getTile(x, y).flags < 4096 and getTile(x, y).fg ~= 0 and
    getTile(x, y).fg ~= 8 and getTile(x, y).fg ~= 6
end

local function haveRelated(x, y)
    local dirrection = {
        { x = 1,  y = 0 },
        { x = -1, y = 0 },
        { x = 0,  y = 1 },
        { x = 0,  y = -1 },
        { x = 1,  y = 1 },
        { x = -1, y = 1 },
        { x = 1,  y = -1 },
        { x = -1, y = -1 },
    }
    for _, dir in pairs(dirrection) do
        if isPunchable(dir.x + x, dir.y + y) then
            return true
        end
    end
    return false
end

local function clossestPath(x, y)
    local clossest = { x = bot.x, y = bot.y }
    local distances = math.huge
    local rangeY = y - bot.y
    local rangeX = x - bot.x
    for ye = bot.y, y, rangeY >= 0 and 1 or -1 do
        for ex = bot.x, x, rangeX >= 0 and 1 or -1 do
            if isCanfindPath(ex, ye) and haveRelated(ex, ye) then
                local distance = distance(ex, ye, x, y)
                if distance < distances then
                    clossest = { x = ex, y = ye }
                    distances = distance
                end
            end
        end
    end
    return clossest
end

local function clossestPunch(x, y)
    local dirrection = {
        { x = 1,  y = 0 },
        { x = -1, y = 0 },
        { x = 0,  y = 1 },
        { x = 0,  y = -1 },
        { x = 1,  y = 1 },
        { x = -1, y = 1 },
        { x = 1,  y = -1 },
        { x = -1, y = -1 },
    }
    local distances = math.huge
    local clossest = {}
    for _, dir in pairs(dirrection) do
        local newPathX = bot.x + dir.x
        local newPathY = bot.y + dir.y
        if isPunchable(newPathX, newPathY) then
            local distance = distance(newPathX, newPathY, x, y)
            if distance < distances then
                clossest = { x = newPathX, y = newPathY }
                distances = distance
            end
        end
    end
    return clossest
end

function getNextClosestTile(tileWorlds, pos, fgToAvoid)
    for _, tile in pairs(tileWorlds) do
        if tile.fg ~= fgToAvoid and successPath(tile, pos.x, pos.y) then
            return tile
        end
    end
    return nil
end

local function breakTreasure(world, idBlock)
    log('Break Treasure')
    sleep(1000)
    local tileWorlds = getTiles()
    local tiles = getTilesFg(idBlock, tileWorlds)
    log('Total tiles found: ' .. #tiles.." "..getInfo(idBlock).name)

    
    for i, tile in ipairs(tiles) do
        local pos = { x = bot.x, y = bot.y }
        local targetTile = tile
        local currentEgg = bot:getInventory():getItemCount(7764)
        print("currentEgg: "..currentEgg)
        while not successPath(targetTile, pos.x, pos.y) do
            pos = clossestPath(targetTile.x, targetTile.y)

            Reconnect(world, WorldsSetting.worldTreasureId, pos.x, pos.y)

            if getTile(pos.x, pos.y+1).fg == idLock then
                targetTile = getNextClosestTile(tileWorlds, pos, idLock)
                if not targetTile then
                   break
                end
            end

            while not bot:isInTile(pos.x, pos.y) do
                Reconnect(world, WorldsSetting.worldTreasureId, pos.x, pos.y)
                findPath(pos.x, pos.y)
                Reconnect(world, WorldsSetting.worldTreasureId, pos.x, pos.y)
            end

            if successPath(targetTile, pos.x, pos.y) then
                break
            end

            local a = clossestPunch(targetTile.x, targetTile.y)
            if not a.x or not a.y then
                break
            end

            if isPunchable(a.x, a.y) and bot:isInTile(pos.x, pos.y) then
                while isPunchable(a.x, a.y) and bot:isInTile(pos.x, pos.y) do
                    bot:hit(a.x, a.y)
                    if Delay.dynamicDelay.enabled then
                        sleep(math.random(100,150)+bot:getPing())
                    else
                        sleep(Delay.DelayBreak)
                    end
                end
            else
                while not bot:isInTile(pos.x, pos.y) do
                    Reconnect(world, WorldsSetting.worldTreasureId, pos.x, pos.y)
                    findPath(pos.x, pos.y)
                    Reconnect(world, WorldsSetting.worldTreasureId, pos.x, pos.y)
                end
            end
            Reconnect(world, WorldsSetting.worldTreasureId, pos.x, pos.y)
        end

        if successPath(targetTile, pos.x, pos.y) and bot:isInTile(pos.x, pos.y) then
            while getTile(targetTile.x, targetTile.y).fg == idBlock and hasAccess(targetTile.x, targetTile.y) > 0 and bot:isInTile(pos.x, pos.y) do
                Reconnect(world, WorldsSetting.worldTreasureId, pos.x, pos.y)
                bot:hit(targetTile.x, targetTile.y)
                if Delay.dynamicDelay.enabled then
                    sleep(math.random(100,150)+bot:getPing())
                else
                    sleep(Delay.DelayBreak)
                end
                Reconnect(world, WorldsSetting.worldTreasureId, pos.x, pos.y)
            end
            local Egg = bot:getInventory():getItemCount(7764)
            print("Egg "..Egg)
            if Egg > currentEgg then
                log("Got Stone Egg")
            end
        else
        end
    end
end

local function isNeedToStore()
    for _, itm in pairs(rewardsId) do
        if findItem(itm) > 0 then
            return true
        end
    end
    return false
end

local function storeItem()
    if isNeedToStore() then
        bot.custom_status = "Dropping Prize"
        log('Storing Item')
        bot.auto_collect = false
        while isNeedToStore() do
            warp(WorldsSetting.storageWorld, WorldsSetting.storageWorldId)
            if not nuked then
                if not stuck then
                    for _, itm in pairs(rewardsId) do
                        if findItem(itm) > 0 then
                            while findItem(itm) > 0 do
                                bot:findOutput()
                                sleep(400)
                                bot:drop(itm, findItem(itm))
                                sleep(500)
                            end
                        end
                    end
                    
                end
            end
            sleep(1)
        end
        while bot:isInWorld() do
            bot:leaveWorld()
            sleep(5000)
        end
        bot.auto_collect = true
    end
end

local function gacha(worlds)
    bot.custom_status = "Gacha Treasure"
    if bot:isInWorld() then
        if onlyBreakTreasure then
            breakTreasure(worlds, 7628)
        else
            breakTreasure(worlds, 7628)
            breakTreasure(worlds, 7624)
            breakTreasure(worlds, 7626)
            breakTreasure(worlds, 440)
        end
    end

end

local function runScript()
    bot.ignore_gems = true
    Reconnect()
    for i = 1, #WorldsSetting.worldTreasure do
        bot.auto_collect = true
        while not bot:isInWorld(WorldsSetting.worldTreasure[i]) do
            warp(WorldsSetting.worldTreasure[i], WorldsSetting.worldTreasureId)
            if Delay.dynamicDelay.enabled then
                sleep(math.random(4000,7000)+bot:getPing())
            else
                sleep(Delay.DelayWarp)
            end
            if bot:isInWorld(WorldsSetting.worldTreasure[i]) then
                break
            end
        end
        local world = WorldsSetting.worldTreasure[i]
        gacha(world)
        trash()
        storeItem()
        bot.custom_status = ""
    end
end

runScript()
