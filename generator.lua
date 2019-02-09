function DefaultGeneration(chunk, x,z)
    -- chunk generation
    local dirt = 4
    local grass = true
    local floor = 48
    local ceiling = 120

    -- iterate through chunk
    -- voxel data is stored in strings in a 2d array to simulate a 3d array of bytes
    for i=1, ChunkSize do
        chunk.voxels[i] = {}
        for k=1, ChunkSize do
            local temp = {}
            chunk.heightMap[i][k] = 0

            -- for every x and z value start at top of world going down
            -- when hit first solid block is grass, next four are dirt
            local sunlight = true
            for j=WorldHeight, 1,-1 do
                local xx = (x-1)*ChunkSize + i
                local zz = (z-1)*ChunkSize + k
                local yy = (j-1)*2 +1

                temp[yy+1] = string.char(0)
                if sunlight then
                    temp[yy+1] = string.char(15)
                end

                if j < floor then
                    temp[yy] = string.char(1)
                    sunlight = false
                else
                    temp[yy] = string.char(0)

                    if ChunkNoise(xx,j,zz) > (j-floor)/(ceiling-floor)*(Noise2D(xx,zz, 128,5)*0.75 +0.75) then
                        if not grass then
                            if dirt > 0 then
                                dirt = dirt - 1
                                temp[yy] = string.char(3)
                            else
                                temp[yy] = string.char(1)
                            end
                        else
                            grass = false
                            temp[yy] = string.char(2)
                            -- if love.math.noise(xx/32,zz/32) > 0.9 and love.math.random() < 0.2 then
                                -- temp[yy+2] = string.char(38)
                            -- end
                            -- if love.math.random() < love.math.noise(xx/64,zz/64)*0.02 and sunlight then
                            --     genTree(i,j,k)
                            --     temp[yy] = string.char(3)
                            -- end
                        end

                        if sunlight then
                            chunk.heightMap[i][k] = j
                        end
                        sunlight = false
                    else
                        grass = true
                        dirt = 4
                    end
                end
            end

            chunk.voxels[i][k] = table.concat(temp)
        end
    end
end

function ClassicGeneration(chunk, x,z)
    -- chunk generation
    local dirt = 4
    local grass = true
    local floor = 0
    local waterLevel = 32
    local ceiling = 120

    local genTree = function (x,y,z)
        local treeHeight = 4 + math.floor(love.math.random()*2 +0.5)

        for tr = 1, treeHeight do
            NewChunkRequest(chunk.x,chunk.z, x,y+tr,z, 17)
        end

        local leafWidth = 2
        for lx = -leafWidth, leafWidth do
            for ly = -leafWidth, leafWidth do
                local chance = 1
                if math.abs(lx) == leafWidth and math.abs(ly) == leafWidth then
                    chance = 0.5
                end

                if love.math.random() < chance then
                    NewChunkRequest(chunk.x,chunk.z, x+lx,y+treeHeight-2,z+ly, 18)
                end
                if love.math.random() < chance then
                    NewChunkRequest(chunk.x,chunk.z, x+lx,y+treeHeight-1,z+ly, 18)
                end
            end
        end
        local leafWidth = 1
        for lx = -leafWidth, leafWidth do
            for ly = -leafWidth, leafWidth do
                local chance = 1
                if math.abs(lx) == leafWidth and math.abs(ly) == leafWidth then
                    chance = 0.5
                end

                if love.math.random() < chance then
                    NewChunkRequest(chunk.x,chunk.z, x+lx,y+treeHeight,z+ly, 18)
                end
                if chance == 1 then
                    NewChunkRequest(chunk.x,chunk.z, x+lx,y+treeHeight+1,z+ly, 18)
                end
            end
        end
    end

    local noise1 = NewCombinedNoise(NewOctaveNoise(8, 2,3), NewOctaveNoise(8, 4,5))
    local noise2 = NewCombinedNoise(NewOctaveNoise(8, 6,7), NewOctaveNoise(8, 8,9))
    local noise3 = NewOctaveNoise(6, 10,11)

    -- iterate through chunk
    -- voxel data is stored in strings in a 2d array to simulate a 3d array of bytes
    for i=1, ChunkSize do
        chunk.voxels[i] = {}
        for k=1, ChunkSize do
            local xx = (x-1)*ChunkSize + i
            local zz = (z-1)*ChunkSize + k
            local temp = {}
            local sunlight = true

            local scalar = 1.3
            local heightLow = noise1:query(xx*scalar, zz*scalar)/6 -4
            local heightHigh = noise2:query(xx*scalar, zz*scalar)/5 -6
            local heightResult = heightLow

            if noise3:query(xx,zz)/8 <= 0 then
                heightResult = math.max(heightLow, heightHigh)
            end

            heightResult = heightResult*0.5
            if heightResult < 0 then
                heightResult = heightResult * 0.8
            end

            heightResult = heightResult + waterLevel


            -- for every x and z value start at top of world going down
            -- when hit first solid block is grass, next four are dirt
            for j=WorldHeight, 1,-1 do
                local yy = (j-1)*2 +1

                temp[yy+1] = string.char(12)
                if sunlight then
                    --temp[yy+1] = string.char(15)
                end

                if j < floor then
                    temp[yy] = string.char(1)
                    sunlight = false
                else
                    temp[yy] = string.char(0)

                    if j <= heightResult then
                        if not grass then
                            if dirt > 0 then
                                dirt = dirt - 1
                                temp[yy] = string.char(3)
                            else
                                temp[yy] = string.char(1)
                            end
                        else
                            grass = false
                            temp[yy] = string.char(2)
                            if love.math.random() < 0.02 and love.math.noise(i/32,k/32) > 0.6 and sunlight then
                                genTree(i,j,k)
                                temp[yy] = string.char(3)
                            end
                        end
                        sunlight = false
                    else
                        grass = true
                        dirt = 4
                    end
                end
            end

            chunk.voxels[i][k] = table.concat(temp)
        end
    end
end

function GenerateTree(chunk, x,y,z)
    local treeHeight = 4 + math.floor(love.math.random()*2 +0.5)

    for tr = 1, treeHeight do
        NewChunkRequest(chunk.x,chunk.z, x,y+tr,z, 17)
    end

    local leafWidth = 2
    for lx = -leafWidth, leafWidth do
        for ly = -leafWidth, leafWidth do
            local chance = 1
            if math.abs(lx) == leafWidth and math.abs(ly) == leafWidth then
                chance = 0.5
            end

            if love.math.random() < chance then
                NewChunkRequest(chunk.x,chunk.z, x+lx,y+treeHeight-2,z+ly, 18)
            end
            if love.math.random() < chance then
                NewChunkRequest(chunk.x,chunk.z, x+lx,y+treeHeight-1,z+ly, 18)
            end
        end
    end
    local leafWidth = 1
    for lx = -leafWidth, leafWidth do
        for ly = -leafWidth, leafWidth do
            local chance = 1
            if math.abs(lx) == leafWidth and math.abs(ly) == leafWidth then
                chance = 0.5
            end

            if love.math.random() < chance then
                NewChunkRequest(chunk.x,chunk.z, x+lx,y+treeHeight,z+ly, 18)
            end
            if chance == 1 then
                NewChunkRequest(chunk.x,chunk.z, x+lx,y+treeHeight+1,z+ly, 18)
            end
        end
    end
end

-- noise function used in chunk generation
function ChunkNoise(x,y,z)
    return Noise(x,y,z, 20,12, 1)
end

function Noise(x,y,z, freq,yfreq, si)
    return love.math.noise(x/freq + Salt[si]*100000,y/yfreq + Salt[si+1]*100000,z/freq + Salt[si+2]*100000)
end
function Noise2D(x,z, freq,si)
    return love.math.noise(x/freq + Salt[si]*100000,z/freq + Salt[si+2]*100000)
end

function NewOctaveNoise(octaves, seed1,seed2)
    local t = {}
    t.octaves = octaves
    t.seed1 = seed1
    t.seed2 = seed2

    t.query = function (self, x,y)
        local ret = 0

        local freq = 1
        local amp = 1
        for i=1, self.octaves do
            ret = ret + love.math.noise(x*freq + Salt[self.seed1]*100000,y*freq + Salt[self.seed2]*100000)*amp -amp/2
            freq = freq * 0.5
            amp = amp * 2
        end

        return ret
    end

    return t
end

function NewCombinedNoise(noise1,noise2)
    local t = {}
    t.noise1 = noise1
    t.noise2 = noise2

    t.query = function (self, x,y)
        return self.noise1:query(x,y) + self.noise2:query(x,y)
    end

    return t
end
