Engine = require "engine"
require "chunk"

function love.load()
    GraphicsWidth, GraphicsHeight = 520*2, (520*9/16)*2
    love.graphics.setBackgroundColor(0,0.7,0.95)
    love.mouse.setRelativeMode(true)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.window.setMode(GraphicsWidth,GraphicsHeight, {vsync=true})
    Scene = Engine.newScene(GraphicsWidth, GraphicsHeight)
    Scene.camera.perspective = TransposeMatrix(cpml.mat4.from_perspective(90, love.graphics.getWidth()/love.graphics.getHeight(), 0.1, 10000))

    LightValues = 16
    DefaultTexture = love.graphics.newImage("texture.png")
    TileTexture = love.graphics.newImage("terrain.png")

    local width, height = TileTexture:getWidth(), TileTexture:getHeight()
    LightingTexture = love.graphics.newCanvas(width*LightValues, height)
    local mult = 1
    love.graphics.setCanvas(LightingTexture)
    for i=LightValues, 1, -1 do
        local xx = (i-1)*width
        love.graphics.setColor(1,1,1)
        love.graphics.draw(TileTexture, xx,0)
        love.graphics.setColor(0,0,0, mult)
        love.graphics.rectangle("fill", xx,0, xx+width, height)
        love.graphics.setColor(1,1,1)
        mult = mult * 0.8
    end
    love.graphics.setCanvas()

    ChunkSize = 16
    SliceHeight = 8
    WorldHeight = 128
    TileWidth, TileHeight = 1/16,1/16
    ThingList = {}

    Salt = {}
    for i=1, 256 do
        Salt[i] = love.math.random()
    end

    ChunkList = {}
    local viewSize = 4
    for i=viewSize/-2 +1, viewSize/2 do
        print(i)
        ChunkList[ChunkHash(i)] = {}
        for j=viewSize/-2 +1, viewSize/2 do
            ChunkList[ChunkHash(i)][ChunkHash(j)] = CreateThing(NewChunk(i,j))
        end
    end
    ThePlayer = CreateThing(NewPlayer(0,90,0))
end

function ChunkHash(x)
    if x < 0 then
        return math.abs(2*x)
    end

    return 1 + 2*x
end

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

function CreateThing(thing)
    table.insert(ThingList, thing)
    return thing
end

function NewThing(x,y,z)
    local t = {}
    t.x = x
    t.y = y
    t.z = z
    t.xSpeed = 0
    t.ySpeed = 0
    t.zSpeed = 0
    t.modelID = -1
    t.model = nil
    t.direction = 0
    t.name = "thing"
    t.assignedModel = 0

    t.update = function (self, dt)
        return true
    end

    t.assignModel = function (self, model)
        self.model = model 

        if self.assignedModel == 0 then
            table.insert(Scene.modelList, self.model)
            self.assignedModel = #Scene.modelList
        else
            Scene.modelList[self.assignedModel] = self.model
        end
    end

    t.destroyModel = function (self)
        self.model.dead = true
    end

    t.destroy = function (self)
    end

    t.mousepressed = function (self, b)
    end

    t.distanceToThing = function (self, thing,radius, ignorey)
        for i=1, #ThingList do
            local this = ThingList[i]
            local distcheck = math.dist3d(this.x,this.y,this.z, self.x,self.y,self.z) < radius

            if ignorey then
                distcheck = math.dist3d(this.x,0,this.z, self.x,0,self.z) < radius
            end

            if this.name == thing 
            and this ~= self 
            and distcheck then
                return this
            end
        end

        return nil
    end

    return t
end

function NewBillboard(x,y,z)
    local t = NewThing(x,y,z)
    local verts = {}
    local scale = 6
    local hs = scale/2
    verts[#verts+1] = {0,0,hs, 1,1}
    verts[#verts+1] = {0,0,-hs, 0,1}
    verts[#verts+1] = {0,scale,hs, 1,0}

    verts[#verts+1] = {0,0,-hs, 0,1}
    verts[#verts+1] = {0,scale,-hs, 0,0}
    verts[#verts+1] = {0,scale,hs, 1,0}

    texture = love.graphics.newImage("/textures/enemy1.png")
    local model = Engine.newModel(Engine.luaModelLoader(verts), DefaultTexture, {0,0,0})
    model.lightable = false
    t:assignModel(model)

    t.direction = 0

    t.update = function (self, dt)
        self.direction = -1*Scene.camera.angle.x+math.pi/2 
        self.model:setTransform({self.x,self.y,self.z}, {self.direction, cpml.vec3.unit_y})
        return true
    end

    return t
end

function TileEnums(n)
    local list = {
        -- textures are in format: SIDE UP DOWN FRONT
        -- at least one texture must be present
        {texture = {0}, isVisible = false, isSolid = false}, -- air
        {texture = {1}, isVisible = true, isSolid = true}, -- stone
        {texture = {3,0,2}, isVisible = true, isSolid = true}, -- grass
        {texture = {2}, isVisible = true, isSolid = true}, -- dirt
    }

    return list[n+1]
end

function NumberToCoord(n, w,h)
    local y = math.floor(n/w)
    local x = n-(y*w)

    return x,y
end

function NewPlayer(x,y,z)
    local t = NewThing(x,y,z)
    t.friction = 0.9
    t.moveSpeed = 0.01
    t.viewBob = 0
    t.viewBobMult = 0
    t.name = "player"
    t.voxelCursor = CreateThing(NewVoxelCursor(0,0,0))
    t.cursorpos = {}
    t.cursorposPrev = {}
    t.onGround = false

    t.update = function (self, dt)
        local Camera = Scene.camera
        self.xSpeed = self.xSpeed * self.friction
        self.zSpeed = self.zSpeed * self.friction
        self.ySpeed = self.ySpeed - 0.01
        self.onGround = false
        if TileEnums(GetVoxel(self.x,self.y-1.5+self.ySpeed,self.z)).isSolid then
            self.ySpeed = 0
            self.onGround = true
        end

        local mx,my = 0,0
        local moving = false

        if love.keyboard.isDown("w") then
            mx = mx + 0
            my = my - 1

            moving = true
        end
        if love.keyboard.isDown("a") then
            mx = mx - 1
            my = my + 0

            moving = true
        end
        if love.keyboard.isDown("s") then
            mx = mx + 0
            my = my + 1

            moving = true
        end
        if love.keyboard.isDown("d") then
            mx = mx + 1
            my = my + 0

            moving = true
        end

        if love.keyboard.isDown("space") and self.onGround then
            self.ySpeed = self.ySpeed + 0.165
        end

        if moving then
            local angle = math.angle(0,0, mx,my)
            self.direction = (Camera.angle.x + angle)*-1 +math.pi/2
            self.xSpeed = self.xSpeed + math.cos(Camera.angle.x + angle) * self.moveSpeed
            self.zSpeed = self.zSpeed + math.sin(Camera.angle.x + angle) * self.moveSpeed
        end
        if not TileEnums(GetVoxel(self.x+self.xSpeed,self.y,self.z)).isSolid
        and not TileEnums(GetVoxel(self.x+self.xSpeed,self.y-1,self.z)).isSolid then
            self.x = self.x + self.xSpeed
        else
            self.xSpeed = 0
        end
        if not TileEnums(GetVoxel(self.x,self.y,self.z+self.zSpeed)).isSolid
        and not TileEnums(GetVoxel(self.x,self.y-1,self.z+self.zSpeed)).isSolid then
            self.z = self.z + self.zSpeed
        else
            self.zSpeed = 0
        end
        self.y = self.y + self.ySpeed

        local speed = math.dist(0,0, self.xSpeed,self.zSpeed)
        self.viewBob = self.viewBob + speed*2
        self.viewBobMult = math.min(speed, 1)

        Scene.camera.pos.x = self.x
        Scene.camera.pos.y = self.y + math.sin(self.viewBob)*self.viewBobMult*0.5
        Scene.camera.pos.z = self.z

        local rx,ry,rz = Scene.camera.pos.x,Scene.camera.pos.y,Scene.camera.pos.z
        local step = 0.1
        self.voxelCursor.model.visible = false
        for i=1, 5, step do
            local chunk, cx,cy,cz, hashx,hashy = GetChunk(rx,ry,rz)
            if chunk ~= nil and chunk:getVoxel(cx,cy,cz) ~= 0 then
                self.cursorpos = {x=cx,y=cy,z=cz, chunk=chunk}
                self.voxelCursor.model.visible = true
                self.voxelCursor.model:setTransform({math.floor(rx), math.floor(ry), math.floor(rz)})
                break
            end
            self.cursorposPrev = {x=cx,y=cy,z=cz, chunk=chunk}

            rx = rx + math.cos(Scene.camera.angle.x -math.pi/2)*step*math.cos(Scene.camera.angle.y)
            rz = rz + math.sin(Scene.camera.angle.x -math.pi/2)*step*math.cos(Scene.camera.angle.y)
            ry = ry - math.sin(Scene.camera.angle.y)*step
        end

        return true
    end

    return t
end

function GetVoxel(x,y,z)
    local chunk, cx,cy,cz = GetChunk(x,y,z)
    local v = 0
    if chunk ~= nil then
        v = chunk:getVoxel(cx,cy,cz)
    end
    return v
end

function NewVoxelCursor(x,y,z)
    local t = NewThing(x,y,z)
    local model = {}
    local scale = 1.002
    local x,y,z = -0.001,-0.001,-0.001

    -- top
    model[#model+1] = {x, y+scale, z}
    model[#model+1] = {x, y+scale, z}
    model[#model+1] = {x, y+scale, z+scale}
    model[#model+1] = {x+scale, y+scale, z+scale}
    model[#model+1] = {x+scale, y+scale, z+scale}
    model[#model+1] = {x+scale, y+scale, z}
    model[#model+1] = {x+scale, y+scale, z+scale}
    model[#model+1] = {x+scale, y+scale, z+scale}
    model[#model+1] = {x, y+scale, z+scale}
    model[#model+1] = {x+scale, y+scale, z}
    model[#model+1] = {x+scale, y+scale, z}
    model[#model+1] = {x, y+scale, z}

    -- bottom
    model[#model+1] = {x, y, z}
    model[#model+1] = {x, y, z}
    model[#model+1] = {x, y, z+scale}
    model[#model+1] = {x+scale, y, z+scale}
    model[#model+1] = {x+scale, y, z+scale}
    model[#model+1] = {x+scale, y, z}
    model[#model+1] = {x+scale, y, z+scale}
    model[#model+1] = {x+scale, y, z+scale}
    model[#model+1] = {x, y, z+scale}
    model[#model+1] = {x+scale, y, z}
    model[#model+1] = {x+scale, y, z}
    model[#model+1] = {x, y, z}

    -- sides
    model[#model+1] = {x, y+scale, z}
    model[#model+1] = {x, y+scale, z}
    model[#model+1] = {x, y, z}
    model[#model+1] = {x+scale, y+scale, z}
    model[#model+1] = {x+scale, y+scale, z}
    model[#model+1] = {x+scale, y, z}
    model[#model+1] = {x, y+scale, z+scale}
    model[#model+1] = {x, y+scale, z+scale}
    model[#model+1] = {x, y, z+scale}
    model[#model+1] = {x+scale, y+scale, z+scale}
    model[#model+1] = {x+scale, y+scale, z+scale}
    model[#model+1] = {x+scale, y, z+scale}

    local compmodel = Engine.newModel(Engine.luaModelLoader(model), nil, {0,0,0}, {0,0,0})
    compmodel.wireframe = true
    t:assignModel(compmodel)

    return t
end

function love.update(dt)
    Scene:update()
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
    Scene:render(false)
    Scene:renderFunction(
        function ()
            love.graphics.setColor(0,0,0)
            love.graphics.print(ThePlayer.x.."\n"..ThePlayer.y.."\n"..ThePlayer.z)
            local chunk, cx,cy,cz, hashx,hashy = GetChunk(ThePlayer.x,ThePlayer.y,ThePlayer.z)
            if chunk ~= nil then
                love.graphics.print(collectgarbage('count'),0,50)
                love.graphics.print(#chunk.voxels[1][1], 0,70)
            end
        end, false
    )

    love.graphics.setColor(1,1,1)
    local scale = love.graphics.getWidth()/GraphicsWidth
    love.graphics.draw(Scene.threeCanvas, love.graphics.getWidth()/2,love.graphics.getHeight()/2, 0, scale,-1*scale, GraphicsWidth/2, GraphicsHeight/2)
    love.graphics.draw(Scene.twoCanvas, love.graphics.getWidth()/2,love.graphics.getHeight()/2 +1, 0, scale,scale, GraphicsWidth/2, GraphicsHeight/2)
end

function love.mousemoved(x,y, dx,dy)
    Scene:mouseLook(x,y, dx,dy)
end

function love.mousepressed(x,y, b)
    for i=1, #ThingList do
        local thing = ThingList[i]
        thing:mousepressed(b)
    end

    local pos = ThePlayer.cursorpos
    local value = 0

    if b == 2 then
        pos = ThePlayer.cursorposPrev
        value = 1
    end

    local cx,cy,cz = pos.x, pos.y, pos.z
    local chunk = pos.chunk
    if chunk ~= nil 
    and ThePlayer.cursorpos.chunk ~= nil 
    and ThePlayer.cursorpos.chunk:getVoxel(ThePlayer.cursorpos.x,ThePlayer.cursorpos.y,ThePlayer.cursorpos.z) ~= 0 then
        chunk:setVoxel(cx,cy,cz, value)
        chunk:updateSlice(cy)
    end
end

function love.keypressed(k)
end

function lerp(a,b,t) return (1-t)*a + t*b end
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
function math.dist3d(x1,y1,z1, x2,y2,z2) return ((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)^0.5 end
