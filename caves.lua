function UpdateCaves()
    local continue = true

    while continue do
        continue = false

        local i = 1
        while i <= #CaveList do
            continue = continue or CaveList[i]:query()

            if CaveList[i].lifeTimer > 0 then
                i=i+1
            else
                table.remove(CaveList, i)
            end
        end
    end
end

function NewCave(x,y,z)
    local t = {}
    t.x = x
    t.y = y
    t.z = z
    t.lifeTimer = rand(64,256)

    t.theta = love.math.random()*math.pi*2
    t.deltaTheta = 0
    t.phi = love.math.random()*math.pi*2
    t.deltaPhi = 0

    t.radius = rand(2,3, 0.1)
    t.carveIndex = 0

    t.query = function (self)
        local chunk, cx,cy,cz = GetChunk(self.x,self.y,self.z)

        if chunk == nil then
            return false
        end

        self.x = self.x + math.sin(self.theta)*math.cos(self.phi)
        self.y = self.y + math.sin(self.phi)
        self.z = self.z + math.cos(self.theta)*math.cos(self.phi)

        self.theta = self.theta + self.deltaTheta*0.2
        self.deltaTheta = self.deltaTheta*0.9 + love.math.random() - love.math.random()
        self.phi = self.phi/2 + self.deltaPhi/4
        self.deltaPhi = self.deltaPhi*0.75 + love.math.random() - love.math.random()

        if self.carveIndex >= self.radius then
            self:carve()
            self.carveIndex = 0
        end
        self.carveIndex = self.carveIndex + 1

        self.lifeTimer = self.lifeTimer - 1
        if self.lifeTimer <= 0 then
            return false
        end

        return true
    end

    t.carve = function (self)
        if GetVoxel(self.x,self.y,self.z) ~= 0 then
            for i=-self.radius, self.radius do
                for j=-self.radius, self.radius do
                    for k=-self.radius, self.radius do
                        if math.dist3d(i,j,k, 0,0,0)+love.math.random()/2 < self.radius then
                            local gx,gy,gz = self.x+i,self.y+j,self.z+k
                            local chunk, cx,cy,cz = GetChunk(gx,gy,gz)

                            if chunk ~= nil then
                                chunk:setVoxelRaw(cx,cy,cz, 0,0)

                                if cy == chunk.heightMap[cx][cz] then
                                    NewSunlightDownAddition(gx,gy,gz, 15)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    CaveList[#CaveList+1] = t
    return t
end
