function GenerateTerrain(chunk, x,z, generationFunction)
    -- chunk generation
    local dirt = 4
    local grass = true

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
                local yy = (j-1)*TileDataSize +1

                for a=1, TileDataSize-1 do
                    temp[yy+a] = string.char(0)
                end
                if sunlight then
                    temp[yy+1] = string.char(15)
                end

                if j < chunk.floor then
                    temp[yy] = string.char(1)
                    sunlight = false
                else
                    temp[yy] = string.char(0)

                    if generationFunction(chunk, xx,j,zz) then
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

function StandardTerrain(chunk, xx,j,zz)
    return ChunkNoise(xx,j,zz) > (j-chunk.floor)/(chunk.ceiling-chunk.floor)*(Noise2D(xx,zz, 128,5)*0.75 +0.75)
end

function ClassicTerrain(chunk, xx,j,zz)
    local scalar = 1.3
    local heightLow = (OctaveNoise(xx*scalar, zz*scalar, 8, 2,3) + OctaveNoise(xx*scalar, zz*scalar, 8, 4,5))/6 -4
    local heightHigh = (OctaveNoise(xx*scalar, zz*scalar, 8, 6,7) + OctaveNoise(xx*scalar, zz*scalar, 8, 8,9))/5 -6
    local heightResult = heightLow

    if OctaveNoise(xx,zz, 6, 10,11)/8 <= 0 then
        heightResult = math.max(heightLow, heightHigh)
    end

    heightResult = heightResult * 0.5
    if heightResult < 0 then
        heightResult = heightResult * 0.8
    end

    heightResult = heightResult + 64 -- water level

    return j <= heightResult --ChunkNoise(xx,j,zz) > (j-chunk.floor)/(chunk.ceiling-chunk.floor)*(Noise2D(xx,zz, 128,5)*0.75 +0.75)
end

function GenerateTree(chunk, x,y,z)
    local treeHeight = 4 + math.floor(love.math.random()*2 +0.5)

    for tr = 1, treeHeight do
        local gx,gy,gz = Globalize(chunk.x,chunk.z, x,y+tr,z)
        NewChunkRequest(gx,gy,gz, 17)
    end

    local leafWidth = 2
    for lx = -leafWidth, leafWidth do
        for ly = -leafWidth, leafWidth do
            local chance = 1
            if math.abs(lx) == leafWidth and math.abs(ly) == leafWidth then
                chance = 0.5
            end

            if love.math.random() < chance then
                local gx,gy,gz = Globalize(chunk.x,chunk.z, x+lx,y+treeHeight-2,z+ly)
                NewChunkRequest(gx,gy,gz, 18)
            end
            if love.math.random() < chance then
                local gx,gy,gz = Globalize(chunk.x,chunk.z, x+lx,y+treeHeight-1,z+ly)
                NewChunkRequest(gx,gy,gz, 18)
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
                local gx,gy,gz = Globalize(chunk.x,chunk.z, x+lx,y+treeHeight,z+ly)
                NewChunkRequest(gx,gy,gz, 18)
            end
            if chance == 1 then
                local gx,gy,gz = Globalize(chunk.x,chunk.z, x+lx,y+treeHeight+1,z+ly)
                NewChunkRequest(gx,gy,gz, 18)
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

function OctaveNoise(x,y, octaves, seed1,seed2)
    local ret = 0

    local freq = 1
    local amp = 1
    for i=1, octaves do
        ret = ret + love.math.noise(x*freq + Salt[seed1]*100000,y*freq + Salt[seed2]*100000)*amp -amp/2
        freq = freq * 0.5
        amp = amp * 2
    end

    return ret
end
