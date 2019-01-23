function NewPlayer(x,y,z)
    local t = NewThing(x,y,z)
    t.friction = 0.85
    t.moveSpeed = 0.01
    t.viewBob = 0
    t.viewBobMult = 0
    t.name = "player"
    t.voxelCursor = CreateThing(NewVoxelCursor(0,0,0))
    t.cursorpos = {}
    t.cursorposPrev = {}
    t.onGround = false
    t.height = 1.85
    t.eyeLevel = 1.62
    t.width = 0.25

    t.update = function (self, dt)
        if PhysicsStep then
            self:physics()
        end

        -- view bobbing
        local speed = math.dist(0,0, self.xSpeed,self.zSpeed)
        self.viewBob = self.viewBob + speed*2.75*(dt*60)
        self.viewBobMult = math.min(speed, 1)

        -- update camera position to new player position
        Scene.camera.pos.x = self.x
        Scene.camera.pos.y = self.y + math.sin(self.viewBob)*self.viewBobMult*1 +self.eyeLevel
        Scene.camera.pos.z = self.z

        -- update voxel cursor position to whatever block currently pointing at
        local rx,ry,rz = Scene.camera.pos.x,Scene.camera.pos.y,Scene.camera.pos.z
        local step = 0.1
        self.voxelCursor.model.visible = false
        self.cursorHit = false
        for i=1, 5, step do
            local chunk, cx,cy,cz, hashx,hashy = GetChunk(rx,ry,rz)
            if chunk ~= nil and chunk:getVoxel(cx,cy,cz) ~= 0 then
                self.cursorpos = {x=cx,y=cy,z=cz, chunk=chunk}
                self.cursorHit = true
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

    t.physics = function (self)
        local Camera = Scene.camera

        -- apply gravity and friction
        self.xSpeed = self.xSpeed * self.friction
        self.zSpeed = self.zSpeed * self.friction
        self.ySpeed = self.ySpeed - 0.009

        -- determine if player has hit ground this frame
        self.onGround = false
        if TileCollisions(GetVoxel(self.x+self.width,self.y+self.ySpeed,self.z+self.width))
        or TileCollisions(GetVoxel(self.x+self.width,self.y+self.ySpeed,self.z-self.width))
        or TileCollisions(GetVoxel(self.x-self.width,self.y+self.ySpeed,self.z+self.width))
        or TileCollisions(GetVoxel(self.x-self.width,self.y+self.ySpeed,self.z-self.width)) then
            local i = 0
            while not TileCollisions(GetVoxel(self.x+self.width,self.y+i,self.z+self.width))
            and not TileCollisions(GetVoxel(self.x+self.width,self.y+i,self.z-self.width))
            and not TileCollisions(GetVoxel(self.x-self.width,self.y+i,self.z+self.width))
            and not TileCollisions(GetVoxel(self.x-self.width,self.y+i,self.z-self.width)) do
                i = i-0.01
            end
            self.y = self.y + i+0.01
            self.ySpeed = 0
            self.onGround = true
        end

        local mx,my = 0,0
        local moving = false

        -- take player input
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

        -- jump if on ground
        if love.keyboard.isDown("space") and self.onGround then
            self.ySpeed = self.ySpeed + 0.15
        end

        -- hit head ceilings
        if math.abs(self.ySpeed) == self.ySpeed
        and (TileCollisions(GetVoxel(self.x-self.width,self.y+self.height+self.ySpeed,self.z+self.width))
        or TileCollisions(GetVoxel(self.x-self.width,self.y+self.height+self.ySpeed,self.z-self.width))
        or TileCollisions(GetVoxel(self.x+self.width,self.y+self.height+self.ySpeed,self.z+self.width))
        or TileCollisions(GetVoxel(self.x+self.width,self.y+self.height+self.ySpeed,self.z-self.width))) then
            self.ySpeed = -0.5*self.ySpeed
        end

        -- convert WASD keys pressed into an angle, move xSpeed and zSpeed according to cos and sin
        if moving then
            local angle = math.angle(0,0, mx,my)
            self.direction = (Camera.angle.x + angle)*-1 +math.pi/2
            self.xSpeed = self.xSpeed + math.cos(Camera.angle.x + angle) * self.moveSpeed
            self.zSpeed = self.zSpeed + math.sin(Camera.angle.x + angle) * self.moveSpeed
        end

        -- y values are good, cement them
        self.y = self.y + self.ySpeed

        -- check for collisions with walls along the x direction
        if not TileCollisions(GetVoxel(self.x+self.xSpeed +GetSign(self.xSpeed)*self.width,self.y,self.z -self.width))
        and not TileCollisions(GetVoxel(self.x+self.xSpeed +GetSign(self.xSpeed)*self.width,self.y+1,self.z -self.width))
        and not TileCollisions(GetVoxel(self.x+self.xSpeed +GetSign(self.xSpeed)*self.width,self.y,self.z +self.width))
        and not TileCollisions(GetVoxel(self.x+self.xSpeed +GetSign(self.xSpeed)*self.width,self.y+1,self.z +self.width)) then
            -- x values are good, cement them
            self.x = self.x + self.xSpeed
        else
            self.xSpeed = 0
        end

        -- check for collisions with walls along the z direction
        if not TileCollisions(GetVoxel(self.x -self.width,self.y,self.z+self.zSpeed +GetSign(self.zSpeed)*self.width))
        and not TileCollisions(GetVoxel(self.x -self.width,self.y+1,self.z+self.zSpeed +GetSign(self.zSpeed)*self.width))
        and not TileCollisions(GetVoxel(self.x +self.width,self.y,self.z+self.zSpeed +GetSign(self.zSpeed)*self.width))
        and not TileCollisions(GetVoxel(self.x +self.width,self.y+1,self.z+self.zSpeed +GetSign(self.zSpeed)*self.width)) then
            -- z values are good, cement them
            self.z = self.z + self.zSpeed
        else
            self.zSpeed = 0
        end
    end

    return t
end

-- the model for the wireframe outline of the block currently selected by ThePlayer in the world
function NewVoxelCursor(x,y,z)
    local t = NewThing(x,y,z)
    t.name = "voxelcursor"
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

    local compmodel = Engine.newModel(model, nil, {0,0,0}, {0,0,0})
    compmodel.wireframe = true
    t:assignModel(compmodel)

    return t
end
