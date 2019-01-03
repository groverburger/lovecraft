-- Super Simple 3D Engine v1
-- groverburger 2019

cpml = require "cpml"

local engine = {}
engine.objModelLoader = require "modelLoader"
engine.objFormat = { 
    {"VertexPosition", "float", 4}, 
    {"VertexTexCoord", "float", 2}, 
    {"VertexNormal", "float", 3}, 
}

function engine.luaModelLoader(model)
    local newModel = {}
    for i=1, #model do
        local get = model[i]
        newModel[i] = {}
        local this = newModel[i]

        this[1] = get[1]*1
        this[2] = get[2]*1
        this[3] = get[3]*1

        -- if this doesn't have uv coordinates just put in random ones
        if #get < 5 then
            this[4] = love.math.random()
            this[5] = love.math.random()
        else
            this[4] = get[4]
            this[5] = get[5]
        end

        -- if this doesn't have normals figure them out
        if #get < 8 then
            local polyindex = math.floor((i-1)/3)
            local polyfirst = polyindex*3 +1
            local polysecond = polyindex*3 +2
            local polythird = polyindex*3 +3

            local sn1 = {}
            sn1[1] = model[polythird][1] - model[polysecond][1]
            sn1[2] = model[polythird][2] - model[polysecond][2]
            sn1[3] = model[polythird][3] - model[polysecond][3]

            local sn2 = {}
            sn2[1] = model[polysecond][1] - model[polyfirst][1]
            sn2[2] = model[polysecond][2] - model[polyfirst][2]
            sn2[3] = model[polysecond][3] - model[polyfirst][3]

            local cross = UnitVectorOf(CrossProduct(sn1,sn2))

            this[6] = cross[1]
            this[7] = cross[2]
            this[8] = cross[3]
        else
            this[6] = get[6]
            this[7] = get[7]
            this[8] = get[8]
        end
    end

    return newModel
end

function engine.scaleVerts(verts, sx,sy,sz)
    if sy == nil then
        sy = sx
        sz = sx
    end

    for i=1, #verts do
        local this = verts[i]
        this[1] = this[1]*sx
        this[2] = this[2]*sy
        this[3] = this[3]*sz
    end

    return verts
end
function engine.moveVerts(verts, sx,sy,sz)
    if sy == nil then
        sy = sx
        sz = sx
    end

    for i=1, #verts do
        local this = verts[i]
        this[1] = this[1]+sx
        this[2] = this[2]+sy
        this[3] = this[3]+sz
    end

    return verts
end


function engine.newModel(verts, texture, coords, color, format)
    local m = {}

    if coords == nil then
        coords = {0,0,0}
    end
    if color == nil then
        color = {1,1,1}
    end
    if format == nil then
        format = { 
            {"VertexPosition", "float", 3}, 
            {"VertexTexCoord", "float", 2}, 
            {"VertexNormal", "float", 3}, 
        }
    end

    for i=1, #verts do
        verts[i][1] = verts[i][1] + coords[1]
        verts[i][2] = verts[i][2] + coords[2]
        verts[i][3] = verts[i][3] + coords[3]
    end

    if texture == nil then
        texture = love.graphics.newCanvas(1,1)
        love.graphics.setCanvas(texture)
        love.graphics.clear(unpack(color))
        love.graphics.setCanvas()
    end
	m.mesh = love.graphics.newMesh(format, verts, "triangles")
    m.mesh:setTexture(texture)
    m.verts = verts
    m.transform = TransposeMatrix(cpml.mat4.identity())
    m.color = color
    m.visible = true
    m.dead = false
    m.lightable = true
    m.wireframe = false

    m.setTransform = function (self, coords, rotations)
        if angle == nil then
            angle = 0
            axis = cpml.vec3.unit_y
        end
        self.transform = cpml.mat4.identity()
        self.transform:translate(self.transform, cpml.vec3(unpack(coords)))
        if rotations ~= nil then
            for i=1, #rotations, 2 do
                self.transform:rotate(self.transform, rotations[i],rotations[i+1])
            end
        end
        self.transform = TransposeMatrix(self.transform)
    end

    m.getVerts = function (self)
        local ret = {}
        for i=1, #self.verts do
            ret[#ret+1] = {self.verts[i][1], self.verts[i][2], self.verts[i][3]}
        end

        return ret
    end

    m.printVerts = function (self)
        local verts = self:getVerts()
        for i=1, #verts do
            print(verts[i][1], verts[i][2], verts[i][3])
            if i%3 == 0 then
                print("---")
            end
        end
    end

    m.setTexture = function (self, tex)
        self.mesh:setTexture(tex)
    end

    m.deathQuery = function (self)
        return not self.dead
    end

    return m
end


function engine.newScene(renderWidth,renderHeight)
	love.graphics.setDepthMode("lequal", true)
    local scene = {}

    local vertexShader = [[
        uniform mat4 view;
        uniform mat4 model_matrix;
        uniform mat4 model_matrix_inverse;

        varying mat4 modelView;
        varying mat4 modelViewProjection;
        varying vec3 normal;
        varying vec3 vposition;
        
        attribute vec4 VertexNormal;

        vec4 position(mat4 transform_projection, vec4 vertex_position) 
        {
            modelView = view * model_matrix;
            modelViewProjection = view * model_matrix * transform_projection;
            
            normal = vec3(model_matrix_inverse * vec4(VertexNormal));
            vposition = vec3(model_matrix * vertex_position);

            return view * model_matrix * vertex_position;
        }
    ]]

    local fragmentShader = [[

        uniform mat4 view;
        uniform mat4 model_matrix;
        uniform mat4 model_matrix_inverse;

        varying mat4 modelView;
        varying mat4 modelViewProjection;
        varying vec3 normal;
        varying vec3 vposition;

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) 
        {
            vec3 light = vec3(0,0,0);
            float diffuse = 0;
            vec4 texturecolor = Texel(texture, texture_coords);

            //if the alpha here is close to zero just don't draw anything here
            if (texturecolor.a == 0.0)
            {
                discard;
            }

            return texturecolor;
        }
    ]]

    scene.threeShader = love.graphics.newShader(vertexShader, fragmentShader)

    scene.camera = {
        pos = cpml.vec3(0, 0, 0),
        angle = cpml.vec3(0, 0, 0),
        perspective = TransposeMatrix(cpml.mat4.from_perspective(60, love.graphics.getWidth()/love.graphics.getHeight(), 0.1, 10000)),
        transform = cpml.mat4(),
    }

    scene.modelList = {}
    scene.lightList = {}
    scene.lightListLength = 128

    scene.renderWidth = renderWidth
    scene.renderHeight = renderHeight
    scene.threeCanvas = love.graphics.newCanvas(renderWidth, renderHeight)
    scene.twoCanvas = love.graphics.newCanvas(renderWidth, renderHeight)
    scene.ambientLight = 0.5

    scene.newLight = function (self, x,y,z)
        local l = {}
        l.dead = false
        l.x = x
        l.y = y
        l.z = z
        l.power = 1000
        l.scatter = 1
        l.vector = {1,1,1}
        l.hasVector = false
        l.color = {1,1,1}

        l.destroy = function (self)
            self.dead = true
        end

        l.deathQuery = function (self)
            return not self.dead
        end

        table.insert(self.lightList, l)
        return l
    end

    scene.update = function (self)
        local i = 1
        while i<=#(self.lightList) do
            local thing = self.lightList[i]
            if thing:deathQuery() then
                i=i+1
            else
                table.remove(self.lightList, i)
            end
        end

        local i = 1
        while i<=#(self.modelList) do
            local thing = self.modelList[i]
            if thing:deathQuery() then
                i=i+1
            else
                table.remove(self.modelList, i)
            end
        end
    end

    scene.basicCamera = function (self, dt)
        local speed = 5 * dt
        if love.keyboard.isDown("lctrl") then
            speed = speed * 10
        end
        local Camera = engine.camera
        local pos = Camera.pos
        
        local mul = love.keyboard.isDown("w") and 1 or (love.keyboard.isDown("s") and -1 or 0)
        pos.x = pos.x + math.sin(-Camera.angle.x) * mul * speed
        pos.z = pos.z + math.cos(-Camera.angle.x) * mul * speed
        
        local mul = love.keyboard.isDown("d") and -1 or (love.keyboard.isDown("a") and 1 or 0)
        pos.x = pos.x + math.cos(Camera.angle.x) * mul * speed
        pos.z = pos.z + math.sin(Camera.angle.x) * mul * speed

        local mul = love.keyboard.isDown("lshift") and 1 or (love.keyboard.isDown("space") and -1 or 0)
        pos.y = pos.y + mul * speed
    end

    scene.render = function (self, drawArg)
        love.graphics.setColor(1,1,1)
        love.graphics.setCanvas({self.threeCanvas, depth=true})
        love.graphics.clear(0,0,0,0)
        love.graphics.setShader(self.threeShader)

        local Camera = self.camera
        Camera.transform = cpml.mat4()
        local t, a, p = Camera.transform, Camera.angle, CopyTable(Camera.pos)
        p.x = p.x * -1
        p.y = p.y * -1
        p.z = p.z * -1
        t:rotate(t, a.y, cpml.vec3.unit_x)
        t:rotate(t, a.x, cpml.vec3.unit_y)
        t:rotate(t, a.z, cpml.vec3.unit_z)
        t:translate(t, p)
        self.threeShader:send("view", Camera.perspective * TransposeMatrix(Camera.transform))
        
        local lightPos = {}
        local lightPower = {}
        local lightColor = {}
        local lightVector = {}
        local lightScatter = {}
        local lightHasVector = {}
        for i=1, self.lightListLength do
            lightPos[i] = nil
            lightPower[i] = nil
            lightColor[i] = nil
            lightVector[i] = nil
            lightScatter[i] = nil
            lightHasVector[i] = nil

            if i <= #self.lightList then
                local this = self.lightList[i]
                if this ~= nil then
                    lightPos[i] = {this.x,this.y,this.z}
                    lightPower[i] = this.power
                    lightColor[i] = this.color
                    lightVector[i] = this.vector
                    lightScatter[i] = this.scatter
                    lightHasVector[i] = this.hasVector
                end
            end
        end

        --self.threeShader:send("light_count", #self.lightList)
        if #self.lightList > 0 then
            --self.threeShader:send("light_source", unpack(lightPos))
            --self.threeShader:send("light_power", unpack(lightPower))
            --self.threeShader:send("light_color", unpack(lightColor))
            --self.threeShader:send("light_vector", unpack(lightVector))
            --self.threeShader:send("light_scatter", unpack(lightScatter))
            --self.threeShader:send("light_hasVector", unpack(lightHasVector))
        end
        --self.threeShader:send("ambient", self.ambientLight)
        
        for i=1, #self.modelList do
            local model = self.modelList[i]
            if model ~= nil and model.visible then
                self.threeShader:send("model_matrix", model.transform)
                -- need the inverse to compute normals when model is rotated
                self.threeShader:send("model_matrix_inverse", TransposeMatrix(InvertMatrix(model.transform)))
                --self.threeShader:send("modelLightable", model.lightable)
                love.graphics.setWireframe(model.wireframe)
                love.graphics.draw(model.mesh, -self.renderWidth/2, -self.renderHeight/2)
                love.graphics.setWireframe(false)
            end
        end

        love.graphics.setShader()
        love.graphics.setCanvas()

        love.graphics.setColor(1,1,1)
        if drawArg == nil or drawArg == true then
            love.graphics.draw(self.threeCanvas, self.renderWidth/2,self.renderHeight/2, 0, 1,-1, self.renderWidth/2, self.renderHeight/2)
        end
    end

    scene.renderFunction = function (self, func, drawArg)
        love.graphics.setColor(1,1,1)
        love.graphics.setCanvas(Scene.twoCanvas)
        love.graphics.clear(0,0,0,0)
        func()
        love.graphics.setCanvas()

        if drawArg == nil or drawArg == true then
            love.graphics.draw(Scene.twoCanvas, self.renderWidth/2,self.renderHeight/2, 0, 1,1, self.renderWidth/2, self.renderHeight/2)
        end
    end

    scene.mouseLook = function (self, x, y, dx, dy)
        local Camera = self.camera
        Camera.angle.x = Camera.angle.x + math.rad(dx * 0.5)
        Camera.angle.y = math.max(math.min(Camera.angle.y + math.rad(dy * 0.5), math.pi/2), -1*math.pi/2)
    end

    return scene
end

function TransposeMatrix(mat)
	local m = cpml.mat4.new()
	return cpml.mat4.transpose(m, mat)
end
function InvertMatrix(mat)
	local m = cpml.mat4.new()
	return cpml.mat4.invert(m, mat)
end

function CopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[CopyTable(orig_key)] = CopyTable(orig_value)
        end
        setmetatable(copy, CopyTable(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function GetSign(n)
    if n > 0 then return 1 end
    if n < 0 then return -1 end
    return 0
end

function CrossProduct(v1,v2)
    local a = {x = v1[1], y = v1[2], z = v1[3]}
    local b = {x = v2[1], y = v2[2], z = v2[3]}

    local x, y, z
    x = a.y * (b.z or 0) - (a.z or 0) * b.y
    y = (a.z or 0) * b.x - a.x * (b.z or 0)
    z = a.x * b.y - a.y * b.x
    return { x, y, z } 
end

function UnitVectorOf(vector)
    local ab1 = math.abs(vector[1])
    local ab2 = math.abs(vector[2])
    local ab3 = math.abs(vector[3])
    local max = VectorLength(ab1, ab2, ab3)
    if max == 0 then max = 1 end

    local ret = {vector[1]/max, vector[2]/max, vector[3]/max}
    return ret
end

function VectorLength(x2,y2,z2) 
    local x1,y1,z1 = 0,0,0
    return ((x2-x1)^2+(y2-y1)^2+(z2-z1)^2)^0.5 
end

return engine
