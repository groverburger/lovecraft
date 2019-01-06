function ReplaceChar(str, pos, r)
    return str:sub(1, pos-1) .. r .. str:sub(pos+#r)
end

function ChunkNoise(x,y,z)
    local freq = 16
    local yfreq = 12
    return love.math.noise(x/freq + Salt[1]*100000,y/yfreq + Salt[2]*100000,z/freq + Salt[3]*100000)
end

function NewChunk(x,z)
    local chunk = NewThing(x,0,z)
    chunk.voxels = {}
    chunk.slices = {}

    -- chunk generation
    local dirt = 4
    local grass = true
    local floor = 48
    local ceiling = 120
    for i=1, ChunkSize do
        chunk.voxels[i] = {}
        for k=1, ChunkSize do
            local temp = {}

            local sunlight = true
            for j=WorldHeight, 1,-1 do
                local xx = (x-1)*ChunkSize + i
                local zz = (z-1)*ChunkSize + k
                local yy = (j-1)*2 +1
                
                temp[yy+1] = string.char(12)
                if sunlight then
                    temp[yy+1] = string.char(15)
                end

                if j < floor then
                    temp[yy] = string.char(1)
                    sunlight = false
                else
                    temp[yy] = string.char(0)

                    if ChunkNoise(xx,j,zz) > (j-floor)/(ceiling-floor) then
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

    chunk.getVoxel = function (self, x,y,z)
        x = math.floor(x)
        y = math.floor(y)
        z = math.floor(z)
        if x <= ChunkSize and x >= 1
        and z <= ChunkSize and z >= 1
        and y >= 1 and y <= WorldHeight then
            return string.byte(self.voxels[x][z]:sub((y-1)*2 +1,(y-1)*2 +1)), string.byte(self.voxels[x][z]:sub((y-1)*2 +2,(y-1)*2 +2))
        end

        return 0, 0
    end

    chunk.setVoxel = function (self, x,y,z, value)
        x = math.floor(x)
        y = math.floor(y)
        z = math.floor(z)
        if x <= ChunkSize and x >= 1
        and z <= ChunkSize and z >= 1
        and y >= 1 and y <= WorldHeight then
            local temp = 0
            local tempLight = 15
            if value == 0 then
                temp, tempLight = self:getVoxel(x,y+1,z)

                if temp ~= 0 then
                    tempLight = 12
                end
            end
            self.voxels[x][z] = ReplaceChar(self.voxels[x][z], (y-1)*2 +1, string.char(value)..string.char(tempLight))
        end
    end

    chunk.updateModel = function (self, x,y,z, mustStop)
        if mustStop == nil then
            mustStop = false
        end
        local sy = (y)%SliceHeight
        local xx,zz = (self.x-1)*ChunkSize + x-1, (self.z-1)*ChunkSize + z-1
        local i = math.floor((y-1)/SliceHeight) +1

        if self.slices[i] ~= nil then
            self.slices[i]:updateModel()
        end
        if true and self.slices[i+1] ~= nil then
            self.slices[i+1]:updateModel()
        end
        if (true or sy == 1) and self.slices[i-1] ~= nil then
            self.slices[i-1]:updateModel()
        end

        if not mustStop then
            local chunkGet = GetChunk(xx-1,y,zz)
            if chunkGet ~= self and chunkGet ~= nil then
                --print("negX")
                chunkGet:updateModel(ChunkSize,y,z, true)
            end
            local chunkGet = GetChunk(xx+1,y,zz)
            if chunkGet ~= self and chunkGet ~= nil then
                --print("posX")
                chunkGet:updateModel(1,y,z, true)
            end
            local chunkGet = GetChunk(xx,y,zz-1)
            if chunkGet ~= self and chunkGet ~= nil then
                --print("negZ")
                chunkGet:updateModel(x,y,ChunkSize, true)
            end
            local chunkGet = GetChunk(xx,y,zz+1)
            if chunkGet ~= self and chunkGet ~= nil then
                --print("posZ")
                chunkGet:updateModel(x,y,1, true)
            end
        end
    end

    chunk.initialize = function (self)
        for i=1, WorldHeight/SliceHeight do
            self.slices[i] = CreateThing(NewChunkSlice(self.x,self.y + (i-1)*SliceHeight,self.z, self))
        end
    end

    return chunk
end

function NewChunkSlice(x,y,z, parent)
    local t = NewThing(x,y,z)
    t.parent = parent

    t.updateModel = function (self)
        local model = {}

        for i=1, ChunkSize do
            for j=math.max(self.y, 1), self.y+SliceHeight do
                for k=1, ChunkSize do
                    local this, thisLight = self.parent:getVoxel(i,j,k)
                    local scale = 1
                    local x,y,z = (self.x-1)*ChunkSize + i-1, 1*j*scale, (self.z-1)*ChunkSize + k-1

                    if this == 0 then
                        -- top
                        local get = self.parent:getVoxel(i,j-1,k)
                        if TileEnums(get).isVisible then
                            local otx,oty = NumberToCoord(TileEnums(get).texture[math.min(2, #TileEnums(get).texture)], 16,16)
                            otx = otx + 16*thisLight
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x, y, z, tx,ty}
                            model[#model+1] = {x+scale, y, z, tx2,ty}
                            model[#model+1] = {x, y, z+scale, tx,ty2}
                            model[#model+1] = {x+scale, y, z+scale, tx2,ty2}
                            model[#model+1] = {x+scale, y, z, tx2,ty}
                            model[#model+1] = {x, y, z+scale, tx,ty2}
                        end

                        -- bottom
                        local get = self.parent:getVoxel(i,j+1,k)
                        if TileEnums(get).isVisible then
                            local otx,oty = NumberToCoord(TileEnums(get).texture[math.min(3, #TileEnums(get).texture)], 16,16)
                            otx = otx + 16*(thisLight-1)
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x, y+scale, z, tx,ty}
                            model[#model+1] = {x+scale, y+scale, z, tx2,ty}
                            model[#model+1] = {x, y+scale, z+scale, tx,ty2}
                            model[#model+1] = {x+scale, y+scale, z+scale, tx2,ty2}
                            model[#model+1] = {x+scale, y+scale, z, tx2,ty}
                            model[#model+1] = {x, y+scale, z+scale, tx,ty2}
                        end

                        -- positive x
                        local get = self.parent:getVoxel(i-1,j,k)
                        if i == 1 then
                            local chunkGet = GetChunk(x-1,y,z)
                            if chunkGet ~= nil then
                                get = chunkGet:getVoxel(ChunkSize,j,k)
                            end
                        end
                        if TileEnums(get).isVisible then
                            local otx,oty = NumberToCoord(TileEnums(get).texture[1], 16,16)
                            otx = otx + 16*(thisLight-1)
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x, y, z, tx,ty2}
                            model[#model+1] = {x, y+scale, z, tx,ty}
                            model[#model+1] = {x, y, z+scale, tx2,ty2}
                            model[#model+1] = {x, y+scale, z+scale, tx2,ty}
                            model[#model+1] = {x, y+scale, z, tx,ty}
                            model[#model+1] = {x, y, z+scale, tx2,ty2}
                        end

                        -- negative x
                        local get = self.parent:getVoxel(i+1,j,k)
                        if i == ChunkSize then
                            local chunkGet = GetChunk(x+1,y,z)
                            if chunkGet ~= nil then
                                get = chunkGet:getVoxel(1,j,k)
                            end
                        end
                        if TileEnums(get).isVisible then
                            local otx,oty = NumberToCoord(TileEnums(get).texture[1], 16,16)
                            otx = otx + 16*(thisLight-1)
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x+scale, y, z, tx,ty2}
                            model[#model+1] = {x+scale, y+scale, z, tx,ty}
                            model[#model+1] = {x+scale, y, z+scale, tx2,ty2}
                            model[#model+1] = {x+scale, y+scale, z+scale, tx2,ty}
                            model[#model+1] = {x+scale, y+scale, z, tx,ty}
                            model[#model+1] = {x+scale, y, z+scale, tx2,ty2}
                        end

                        -- positive z
                        local get = self.parent:getVoxel(i,j,k-1)
                        if k == 1 then
                            local chunkGet = GetChunk(x,y,z-1)
                            if chunkGet ~= nil then
                                get = chunkGet:getVoxel(i,j,ChunkSize)
                            end
                        end
                        if TileEnums(get).isVisible then
                            local otx,oty = NumberToCoord(TileEnums(get).texture[1], 16,16)
                            otx = otx + 16*thisLight
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x, y, z, tx,ty2}
                            model[#model+1] = {x, y+scale, z, tx,ty}
                            model[#model+1] = {x+scale, y, z, tx2,ty2}
                            model[#model+1] = {x+scale, y+scale, z, tx2,ty}
                            model[#model+1] = {x, y+scale, z, tx,ty}
                            model[#model+1] = {x+scale, y, z, tx2,ty2}
                        end

                        -- negative z
                        local get = self.parent:getVoxel(i,j,k+1)
                        if k == ChunkSize then
                            local chunkGet = GetChunk(x,y,z+1)
                            if chunkGet ~= nil then
                                get = chunkGet:getVoxel(i,j,1)
                            end
                        end
                        if TileEnums(get).isVisible then
                            local otx,oty = NumberToCoord(TileEnums(get).texture[1], 16,16)
                            otx = otx + 16*thisLight
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x, y, z+scale, tx,ty2}
                            model[#model+1] = {x, y+scale, z+scale, tx,ty}
                            model[#model+1] = {x+scale, y, z+scale, tx2,ty2}
                            model[#model+1] = {x+scale, y+scale, z+scale, tx2,ty}
                            model[#model+1] = {x, y+scale, z+scale, tx,ty}
                            model[#model+1] = {x+scale, y, z+scale, tx2,ty2}
                        end
                    end
                end
            end
        end

        local visible = true
        -- models can't be deleted easily, so make it invisible when no verts in mesh
        if #model == 0 then
            model[#model+1] = {0, 0, 0}
            model[#model+1] = {1, 0, 0}
            model[#model+1] = {0, 1, 0}
            visible = false
        end
        local compmodel = Engine.newModel(model, LightingTexture, {0,0,0})
        compmodel.visible = visible
        self:assignModel(compmodel)
    end

    t:updateModel()

    return t
end
