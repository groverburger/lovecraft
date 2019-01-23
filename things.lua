function CreateThing(thing)
    table.insert(ThingList, thing)
    return thing
end

-- create parent class for all thing objects stored in ThingList
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

-- a parent class for a 2d sprite billboard 3d object
function NewBillboard(x,y,z)
    local t = NewThing(x,y,z)
    t.name = "billboardthing"
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
