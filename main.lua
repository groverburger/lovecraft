Engine = require "engine"
require "things"
require "player"
require "chunk"

function love.load()
    -- window graphics settings
    GraphicsWidth, GraphicsHeight = 520*2, (520*9/16)*2
    InterfaceWidth, InterfaceHeight = GraphicsWidth/2, GraphicsHeight/2
    love.graphics.setBackgroundColor(0,0.7,0.95)
    love.mouse.setRelativeMode(true)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.window.setMode(GraphicsWidth,GraphicsHeight, {vsync=true})

    -- create scene object from SS3D engine
    Scene = Engine.newScene(GraphicsWidth, GraphicsHeight)
    Scene.camera.perspective = TransposeMatrix(cpml.mat4.from_perspective(90, love.graphics.getWidth()/love.graphics.getHeight(), 0.1, 10000))

    -- load assets
    DefaultTexture = love.graphics.newImage("assets/texture.png")
    TileTexture = love.graphics.newImage("assets/terrain.png")

    -- create lighting value textures on LightingTexture canvas
    LightValues = 16
    local width, height = TileTexture:getWidth(), TileTexture:getHeight()
    LightingTexture = love.graphics.newCanvas(width*LightValues, height)
    local mult = 1
    love.graphics.setCanvas(LightingTexture)
    love.graphics.clear(0,0,0,1)
    for i=LightValues, 1, -1 do
        local xx = (i-1)*width
        love.graphics.setColor(1,1,1, mult)
        love.graphics.draw(TileTexture, xx,0)
        mult = mult * 0.8
    end
    love.graphics.setColor(1,1,1)
    love.graphics.setCanvas()

    -- global random numbers used for generation
    Salt = {}
    for i=1, 128 do
        Salt[i] = love.math.random()
    end

    -- global variables used in world generation
    ChunkSize = 16
    SliceHeight = 8
    WorldHeight = 128
    TileWidth, TileHeight = 1/16,1/16

    -- initializing the update queue that holds all entities
    ThingList = {}

    -- generate the world
    ChunkList = {}
    local worldSize = 4
    for i=worldSize/-2 +1, worldSize/2 do
        print(i)
        ChunkList[ChunkHash(i)] = {}
        for j=worldSize/-2 +1, worldSize/2 do
            ChunkList[ChunkHash(i)][ChunkHash(j)] = CreateThing(NewChunk(i,j))
        end
    end
    for i=worldSize/-2 +1, worldSize/2 do
        print(i)
        for j=worldSize/-2 +1, worldSize/2 do
            ChunkList[ChunkHash(i)][ChunkHash(j)]:initialize()
        end
    end
    ThePlayer = CreateThing(NewPlayer(0,128,0))
end

-- convert an index into a point on a 2d plane of given width and height
function NumberToCoord(n, w,h)
    local y = math.floor(n/w)
    local x = n-(y*w)

    return x,y
end

-- hash function used in chunk hash table
function ChunkHash(x)
    if x < 0 then
        return math.abs(2*x)
    end

    return 1 + 2*x
end

-- get chunk from reading chunk hash table at given position
function GetChunk(x,y,z)
    local x = math.floor(x)
    local y = math.floor(y)
    local z = math.floor(z)
    local hashx,hashy = ChunkHash(math.floor(x/ChunkSize)+1), ChunkHash(math.floor(z/ChunkSize)+1)
    local getChunk = nil 
    if ChunkList[hashx] ~= nil then 
        getChunk = ChunkList[hashx][hashy]
    end

    local mx,mz = x%ChunkSize +1, z%ChunkSize +1

    return getChunk, mx,y,mz, hashx,hashy
end

-- get voxel by looking at chunk at given position's local coordinate system
function GetVoxel(x,y,z)
    local chunk, cx,cy,cz = GetChunk(x,y,z)
    local v = 0
    if chunk ~= nil then
        v = chunk:getVoxel(cx,cy,cz)
    end
    return v
end

-- tile enumerations stored as a function called by tile index (base 0 to accomodate air)
function TileEnums(n)
    local list = {
        -- textures are in format: SIDE UP DOWN FRONT
        -- at least one texture must be present
        {texture = {0}, isVisible = false, isSolid = false}, -- air
        {texture = {1}, isVisible = true, isSolid = true}, -- stone
        {texture = {3,0,2}, isVisible = true, isSolid = true}, -- grass
        {texture = {2}, isVisible = true, isSolid = true}, -- dirt
        {texture = {4}, isVisible = true, isSolid = true}, -- planks
        {texture = {7}, isVisible = true, isSolid = true}, -- bricks
        {texture = {16}, isVisible = true, isSolid = true}, -- cobble
    }

    -- transforms the list into base 0 to accomodate for air blocks
    return list[n+1]
end

function love.update(dt)
    -- update 3d scene
    Scene:update()

    -- update all things in ThingList update queue
    local i = 1
    while i<=#ThingList do
        local thing = ThingList[i]
        if thing:update(dt) then
            i=i+1
        else
            table.remove(ThingList, i)
            thing:destroy()
            thing:destroyModel()
        end
    end
end

function love.draw()
    -- draw 3d scene
    Scene:render(true)

    -- draw HUD
    Scene:renderFunction(
        function ()
            love.graphics.setColor(0,0,0)
            love.graphics.print("x: "..math.floor(ThePlayer.x+0.5).."\ny: "..math.floor(ThePlayer.y+0.5).."\nz: "..math.floor(ThePlayer.z+0.5))
            local chunk, cx,cy,cz, hashx,hashy = GetChunk(ThePlayer.x,ThePlayer.y,ThePlayer.z)
            if chunk ~= nil then
                love.graphics.print("kB: "..math.floor(collectgarbage('count')),0,50)
            end
            love.graphics.print("FPS: "..love.timer.getFPS(), 0, 70)

            love.graphics.setColor(1,1,1)
            local crosshairSize = 6
            love.graphics.line(InterfaceWidth/2,InterfaceHeight/2 -crosshairSize+1, InterfaceWidth/2,InterfaceHeight/2 +crosshairSize)
            love.graphics.line(InterfaceWidth/2 -crosshairSize,InterfaceHeight/2, InterfaceWidth/2 +crosshairSize-1,InterfaceHeight/2)
        end, false
    )

    love.graphics.setColor(1,1,1)
    local scale = love.graphics.getWidth()/InterfaceWidth
    love.graphics.draw(Scene.twoCanvas, love.graphics.getWidth()/2,love.graphics.getHeight()/2 +1, 0, scale,scale, InterfaceWidth/2, InterfaceHeight/2)
end

function love.mousemoved(x,y, dx,dy)
    -- forward mouselook to Scene object for first person camera control
    Scene:mouseLook(x,y, dx,dy)
end

function love.mousepressed(x,y, b)
    -- forward mousepress events to all things in ThingList 
    for i=1, #ThingList do
        local thing = ThingList[i]
        thing:mousepressed(b)
    end

    -- handle clicking to place / destroy blocks
    local pos = ThePlayer.cursorpos
    local value = 0

    if b == 2 then
        pos = ThePlayer.cursorposPrev
        value = 6
    end

    local cx,cy,cz = pos.x, pos.y, pos.z
    local chunk = pos.chunk
    if chunk ~= nil and ThePlayer.cursorpos.chunk ~= nil and ThePlayer.cursorHit then
        chunk:setVoxel(cx,cy,cz, value)
        chunk:updateModel(cx,cy,cz)
        --print("---")
        --print(cx,cy,cz)
        --print(cx%ChunkSize,cy%SliceHeight,cz%ChunkSize)
    end
end

function love.keypressed(k)
    if k == "escape" then
        love.event.push("quit")
    end
end

function lerp(a,b,t) return (1-t)*a + t*b end
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
function math.dist3d(x1,y1,z1, x2,y2,z2) return ((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)^0.5 end
