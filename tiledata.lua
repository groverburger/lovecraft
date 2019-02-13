-- tile enumerations stored as a function called by tile index (base 0 to accomodate air)
function TileCollisions(n)
    if n == 0
    or n == 6
    or n == 8
    or n == 9
    or n == 10
    or n == 11
    or n == 37
    or n == 38
    or n == 39
    or n == 40 then
        return false
    end

    return true
end

function TileTransparency(n)
    if n == 0
    or n == 37
    or n == 38
    or n == 6 then -- air (fully transparent)
        return 0
    end

    if n == 18 then -- leaves (not very transparent)
        return 1
    end

    if n == 20 then -- glass (very transparent)
        return 2
    end

    if n == 89 then -- glowstone (technically very transparent)
        return 2
    end

    return 3 -- solid (opaque)
end

function TileLightSource(n)
    if n == 89 then -- glowstone
        return 15
    end

    return 0
end

function TileLightable(n)
    local t = TileTransparency(n)
    return t == 0 or t == 2
end

function TileSemiLightable(n)
    local t = TileTransparency(n)
    return t == 0 or t == 1 or t == 2
end

function TileTextures(n)
    local list = {
        -- textures are in format: SIDE UP DOWN FRONT
        -- at least one texture must be present
        {0}, -- 0 air
        {1}, -- 1 stone
        {3,0,2}, -- 2 grass
        {2}, -- 3 dirt
        {16}, -- 4 cobble
        {4}, -- 5 planks
        {15}, -- 6 sapling
        {17}, -- 7 bedrock
        {14}, -- 8 water
        {14}, -- 9 stationary water
        {63}, -- 10 lava
        {63}, -- 11 stationary lava
        {18}, -- 12 sand
        {19}, -- 13 gravel
        {32}, -- 14 gold
        {33}, -- 15 iron
        {34}, -- 16 coal
        {20,21,21}, -- 17 log
        {52}, -- 18 leaves
        {48}, -- 19 sponge
        {49}, -- 20 glass
    }
    list[38] = {13} -- 37 yellow flower
    list[39] = {12} -- 38 rose
    list[46] = {7} -- 18 leaves
    list[90] = {105} -- 89 glowstone

    -- transforms the list into base 0 to accomodate for air blocks
    return list[n+1]
end

function TileModel(n)
    -- flowers and mushrooms have different models
    if n == 37
    or n == 38
    or n == 39
    or n == 40 then
        return 1
    end

    return 0
end
