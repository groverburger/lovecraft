function ReplaceChar(str, pos, r)
    return str:sub(1, pos-1) .. r .. str:sub(pos+#r)
end

function NewChunk(x,z)
    local chunk = NewThing(x,0,z)
    chunk.voxels = {}
    chunk.slices = {}
    chunk.heightMap = {}
    chunk.name = "chunk"

    chunk.ceiling = 120
    chunk.floor = 48
    chunk.requests = {}

    -- store a list of voxels to be updated on next modelUpdate
    chunk.changes = {}

    for i=1, ChunkSize do
        chunk.heightMap[i] = {}
    end

    GenerateTerrain(chunk, x,z, StandardTerrain)

    local gx,gz = (chunk.x-1)*ChunkSize + rand(0,15), (chunk.z-1)*ChunkSize + rand(0,15)

    if choose{true, false} then
        local caveCount1 = rand(1,3)
        for i=1, caveCount1 do
            NewCave(gx,rand(8,64),gz)
        end
        local caveCount2 = rand(1,2)
        for i=1, caveCount2 do
            NewCave(gx,rand(48,80),gz)
        end
    end

    chunk.sunlight = function (self)
        for i=1, ChunkSize do
            for j=1, ChunkSize do
                local gx,gz = (self.x-1)*ChunkSize + i-1, (self.z-1)*ChunkSize + j-1
                local this = self.heightMap[i][j]

                if i == 1 or this > self.heightMap[i-1][j]+1 then
                    NewSunlightDownAddition(gx-1,this,gz, 15)
                    LightingUpdate()
                end
                if j == 1 or this > self.heightMap[i][j-1] then
                    NewSunlightDownAddition(gx,this,gz-1, 15)
                    LightingUpdate()
                end
                if i == ChunkSize or this > self.heightMap[i+1][j] then
                    NewSunlightDownAddition(gx+1,this,gz, 15)
                    LightingUpdate()
                end
                if j == ChunkSize or this > self.heightMap[i][j+1] then
                    NewSunlightDownAddition(gx,this,gz+1, 15)
                    LightingUpdate()
                end
            end
        end
    end

    -- process all requested blocks upon creation of chunk
    chunk.processRequests = function (self)
        for j=1, #self.requests do
            local block = self.requests[j]
            if not TileCollisions(self:getVoxel(block.x,block.y,block.z)) then
                self:setVoxel(block.x,block.y,block.z, block.value, 15)
                LightingUpdate()
            end
        end
    end

    -- populate chunk with trees and flowers
    chunk.populate = function (self)
        for i=1, ChunkSize do
            for j=1, ChunkSize do
                local height = self.heightMap[i][j]
                local xx = (self.x-1)*ChunkSize + i
                local zz = (self.z-1)*ChunkSize + j

                if TileCollisions(self:getVoxel(i,height,j)) then
                    if love.math.random() < love.math.noise(xx/64,zz/64)*0.02 then
                        -- put a tree here
                        GenerateTree(self, i,height,j)
                        self:setVoxelRaw(i,height,j, 3,15)
                    elseif love.math.noise(xx/32,zz/32) > 0.9 and love.math.random() < 0.2 then
                        -- put a flower here
                        self:setVoxelRaw(i,height+1,j, 38,15)
                    end
                end
            end
        end
    end

    chunk.initialize = function (self)
        for i=1, WorldHeight/SliceHeight do
            self.slices[i] = NewChunkSlice(self.x,self.y + (i-1)*SliceHeight+1,self.z, self)
        end
        self.changes = {}
    end

    -- get voxel id of the voxel in this chunk's coordinate space
    chunk.getVoxel = function (self, x,y,z)
        x = math.floor(x)
        y = math.floor(y)
        z = math.floor(z)
        if x <= ChunkSize and x >= 1
        and z <= ChunkSize and z >= 1
        and y >= 1 and y <= WorldHeight then
            return string.byte(self.voxels[x][z]:sub((y-1)*TileDataSize +1,(y-1)*TileDataSize +1)),
                string.byte(self.voxels[x][z]:sub((y-1)*TileDataSize +2,(y-1)*TileDataSize +2)),
                string.byte(self.voxels[x][z]:sub((y-1)*TileDataSize +3,(y-1)*TileDataSize +3))
        end

        return 0, 0, 0
    end

    chunk.getVoxelFirstData = function (self, x,y,z)
        x = math.floor(x)
        y = math.floor(y)
        z = math.floor(z)
        if x <= ChunkSize and x >= 1
        and z <= ChunkSize and z >= 1
        and y >= 1 and y <= WorldHeight then
            return string.byte(self.voxels[x][z]:sub((y-1)*TileDataSize +2,(y-1)*TileDataSize +2))
        end

        return 0
    end

    chunk.getVoxelSecondData = function (self, x,y,z)
        x = math.floor(x)
        y = math.floor(y)
        z = math.floor(z)
        if x <= ChunkSize and x >= 1
        and z <= ChunkSize and z >= 1
        and y >= 1 and y <= WorldHeight then
            return string.byte(self.voxels[x][z]:sub((y-1)*TileDataSize +3,(y-1)*TileDataSize +3))
        end

        return 0
    end

    chunk.setVoxelRaw = function (self, x,y,z, value,light)
        if x <= ChunkSize and x >= 1
        and z <= ChunkSize and z >= 1
        and y >= 1 and y <= WorldHeight then
            local gx,gy,gz = (self.x-1)*ChunkSize + x-1, y, (self.z-1)*ChunkSize + z-1
            self.voxels[x][z] = ReplaceChar(self.voxels[x][z], (y-1)*TileDataSize +1, string.char(value))

            self.changes[#self.changes+1] = {x,y,z}
        end
    end

    -- set voxel id of the voxel in this chunk's coordinate space
    chunk.setVoxel = function (self, x,y,z, value, manuallyPlaced)
        if manuallyPlaced == nil then
            manuallyPlaced = false
        end
        x = math.floor(x)
        y = math.floor(y)
        z = math.floor(z)
        if x <= ChunkSize and x >= 1
        and z <= ChunkSize and z >= 1
        and y >= 1 and y <= WorldHeight then
            local gx,gy,gz = (self.x-1)*ChunkSize + x-1, y, (self.z-1)*ChunkSize + z-1
            self:setVoxelFirstData(x,y,z, 0)
            self:setVoxelSecondData(x,y,z, 0)

            local sunlight = self:getVoxelFirstData(x,y+1,z)
            local sunget = self:getVoxel(x,y+1,z)

            local inDirectSunlight = TileLightable(sunget) and sunlight == 15
            local placingLocalSource = false
            local destroyLight = false
            if TileLightable(value) then
                -- if removed block or put in lightable block
                if inDirectSunlight then
                    NewSunlightDownAddition(gx,gy,gz, sunlight)
                else
                    NewSunlightAdditionCreation(gx+1,gy,gz)
                    NewSunlightAdditionCreation(gx-1,gy,gz)
                    NewSunlightAdditionCreation(gx,gy+1,gz)
                    NewSunlightAdditionCreation(gx,gy-1,gz)
                    NewSunlightAdditionCreation(gx,gy,gz+1)
                    NewSunlightAdditionCreation(gx,gy,gz-1)
                end

                if manuallyPlaced then
                    local source = TileLightSource(value)
                    if source > 0 then
                        NewLocalLightAddition(gx,gy,gz, source)
                        placingLocalSource = true
                    else
                        NewLocalLightAdditionCreation(gx+1,gy,gz)
                        NewLocalLightAdditionCreation(gx-1,gy,gz)
                        NewLocalLightAdditionCreation(gx,gy+1,gz)
                        NewLocalLightAdditionCreation(gx,gy-1,gz)
                        NewLocalLightAdditionCreation(gx,gy,gz+1)
                        NewLocalLightAdditionCreation(gx,gy,gz-1)
                    end
                end
            else
                -- if placed block remove sunlight beneath it
                NewSunlightDownSubtraction(gx,gy-1,gz)

                if TileSemiLightable(value) and inDirectSunlight and manuallyPlaced then
                    NewSunlightAdditionCreation(gx,gy+1,gz)
                end

                if not TileSemiLightable(value) or manuallyPlaced then
                    -- don't destroy local light if semi lightable
                    destroyLight = not TileSemiLightable(value)

                    local nget = GetVoxelFirstData(gx,gy+1,gz)
                    if nget < 15 then
                        NewSunlightSubtraction(gx,gy+1,gz, nget+1)
                    end
                    local nget = GetVoxelFirstData(gx+1,gy,gz)
                    if nget < 15 then
                        NewSunlightSubtraction(gx+1,gy,gz, nget+1)
                    end
                    local nget = GetVoxelFirstData(gx-1,gy,gz)
                    if nget < 15 then
                        NewSunlightSubtraction(gx-1,gy,gz, nget+1)
                    end
                    local nget = GetVoxelFirstData(gx,gy,gz+1)
                    if nget < 15 then
                        NewSunlightSubtraction(gx,gy,gz+1, nget+1)
                    end
                    local nget = GetVoxelFirstData(gx,gy,gz-1)
                    if nget < 15 then
                        NewSunlightSubtraction(gx,gy,gz-1, nget+1)
                    end
                end
            end

            local source = TileLightSource(self:getVoxel(x,y,z))
            if source > 0
            and TileLightSource(value) == 0 then
                NewLocalLightSubtraction(gx,gy,gz, source+1)
                destroyLight = true
            end

            if manuallyPlaced then
                if destroyLight then
                    local nget = GetVoxelSecondData(gx,gy+1,gz)
                    if nget < 15 then
                        NewLocalLightSubtraction(gx,gy+1,gz, nget+1)
                    end
                    local nget = GetVoxelSecondData(gx,gy-1,gz)
                    if nget < 15 then
                        NewLocalLightSubtraction(gx,gy-1,gz, nget+1)
                    end
                    local nget = GetVoxelSecondData(gx+1,gy,gz)
                    if nget < 15 then
                        NewLocalLightSubtraction(gx+1,gy,gz, nget+1)
                    end
                    local nget = GetVoxelSecondData(gx-1,gy,gz)
                    if nget < 15 then
                        NewLocalLightSubtraction(gx-1,gy,gz, nget+1)
                    end
                    local nget = GetVoxelSecondData(gx,gy,gz+1)
                    if nget < 15 then
                        NewLocalLightSubtraction(gx,gy,gz+1, nget+1)
                    end
                    local nget = GetVoxelSecondData(gx,gy,gz-1)
                    if nget < 15 then
                        NewLocalLightSubtraction(gx,gy,gz-1, nget+1)
                    end
                end

                -- fill empty local light values when placed semi lightable block
                if TileSemiLightable(value) and not placingLocalSource then
                    NewLocalLightAdditionCreation(gx+1,gy,gz)
                    NewLocalLightAdditionCreation(gx-1,gy,gz)
                    NewLocalLightAdditionCreation(gx,gy+1,gz)
                    NewLocalLightAdditionCreation(gx,gy-1,gz)
                    NewLocalLightAdditionCreation(gx,gy,gz+1)
                    NewLocalLightAdditionCreation(gx,gy,gz-1)
                end
            end

            self.voxels[x][z] = ReplaceChar(self.voxels[x][z], (y-1)*TileDataSize +1, string.char(value))

            self.changes[#self.changes+1] = {x,y,z}
        end
    end

    chunk.setVoxelData = function (self, x,y,z, value)
        x = math.floor(x)
        y = math.floor(y)
        z = math.floor(z)
        if x <= ChunkSize and x >= 1
        and z <= ChunkSize and z >= 1
        and y >= 1 and y <= WorldHeight then
            self.voxels[x][z] = ReplaceChar(self.voxels[x][z], (y-1)*TileDataSize +2, string.char(value))

            self.changes[#self.changes+1] = {x,y,z}
        end
    end

    -- sunlight data
    chunk.setVoxelFirstData = function (self, x,y,z, value)
        x = math.floor(x)
        y = math.floor(y)
        z = math.floor(z)
        if x <= ChunkSize and x >= 1
        and z <= ChunkSize and z >= 1
        and y >= 1 and y <= WorldHeight then
            self.voxels[x][z] = ReplaceChar(self.voxels[x][z], (y-1)*TileDataSize +2, string.char(value))

            self.changes[#self.changes+1] = {x,y,z}
        end
    end

    -- local light data
    chunk.setVoxelSecondData = function (self, x,y,z, value)
        x = math.floor(x)
        y = math.floor(y)
        z = math.floor(z)
        if x <= ChunkSize and x >= 1
        and z <= ChunkSize and z >= 1
        and y >= 1 and y <= WorldHeight then
            self.voxels[x][z] = ReplaceChar(self.voxels[x][z], (y-1)*TileDataSize +3, string.char(value))

            self.changes[#self.changes+1] = {x,y,z}
        end
    end


    -- update this chunk's model slices based on what changes it has stored
    chunk.updateModel = function (self)
        local sliceUpdates = {}

        for i=1, WorldHeight/SliceHeight do
            sliceUpdates[i] = {false, false, false, false, false}
        end

        -- find which slices need to be updated
        for i=1, #self.changes do
            local index = math.floor((self.changes[i][2]-1)/SliceHeight) +1
            if sliceUpdates[index] ~= nil then
                sliceUpdates[index][1] = true

                if math.floor((self.changes[i][2])/SliceHeight) +1 > index and sliceUpdates[index+1] ~= nil then
                    sliceUpdates[math.min(index+1, #sliceUpdates)][1] = true
                end
                if math.floor((self.changes[i][2]-2)/SliceHeight) +1 < index and sliceUpdates[index-1] ~= nil then
                    sliceUpdates[math.max(index-1, 1)][1] = true
                end

                --print(self.changes[i][1], self.changes[i][2], self.changes[i][3])
                -- neg x
                if self.changes[i][1] == 1 then
                    sliceUpdates[index][2] = true
                    --print("neg x")
                end
                -- pos x
                if self.changes[i][1] == ChunkSize then
                    sliceUpdates[index][3] = true
                    --print("pos x")
                end
                -- neg z
                if self.changes[i][3] == 1 then
                    sliceUpdates[index][4] = true
                    --print("neg z")
                end
                -- pos z
                if self.changes[i][3] == ChunkSize then
                    sliceUpdates[index][5] = true
                    --print("pos z")
                end
            end
        end

        -- update slices that were flagged in previous step
        for i=1, WorldHeight/SliceHeight do
            if sliceUpdates[i][1] then
                self.slices[i]:updateModel()

                if sliceUpdates[i][2] then
                    local chunk = GetChunkRaw(self.x-1,self.z)
                    if chunk ~= nil then
                        chunk.slices[i]:updateModel()
                    end
                end
                if sliceUpdates[i][3] then
                    local chunk = GetChunkRaw(self.x+1,self.z)
                    if chunk ~= nil then
                        chunk.slices[i]:updateModel()
                    end
                end
                if sliceUpdates[i][4] or sliceUpdates[i][5] then
                    local chunk = GetChunkRaw(self.x,self.z-1)
                    if chunk ~= nil then
                        chunk.slices[i]:updateModel()
                    end
                end
                if sliceUpdates[i][4] or sliceUpdates[i][5] then
                    local chunk = GetChunkRaw(self.x,self.z+1)
                    if chunk ~= nil then
                        chunk.slices[i]:updateModel()
                    end
                end
            end
        end

        self.changes = {}
    end

    return chunk
end

function CanDrawFace(get, thisTransparency)
    local tget = TileTransparency(get)

    -- tget > 0 means can only draw faces from outside in (bc transparency of 0 is air)
    -- must be different transparency to draw, except for tree leaves which have transparency of 1
    return (tget ~= thisTransparency or tget == 1) and tget > 0
end

function NewChunkSlice(x,y,z, parent)
    local t = NewThing(x,y,z)
    t.parent = parent
    t.name = "chunkslice"
    local compmodel = Engine.newModel(nil, LightingTexture, {0,0,0})
    compmodel.culling = true
    t:assignModel(compmodel)

    t.updateModel = function (self)
        local model = {}

        -- iterate through the voxels in this chunkslice's domain
        -- if air block, see if any solid neighbors
        -- then place faces down accordingly with proper texture and lighting value
        for i=1, ChunkSize do
            for j=self.y, self.y+SliceHeight-1 do
                for k=1, ChunkSize do
                    local this, thisSunlight, thisLocalLight = self.parent:getVoxel(i,j,k)
                    -- local thisSunlight = thisData%16
                    -- local thisLocalLight = math.floor(thisData/16)
                    local thisLight = math.max(thisSunlight, thisLocalLight)
                    local thisTransparency = TileTransparency(this)
                    local scale = 1
                    local x,y,z = (self.x-1)*ChunkSize + i-1, 1*j*scale, (self.z-1)*ChunkSize + k-1

                    if thisTransparency < 3 then
                        -- if not checking for tget == 0, then it will render the "faces" of airblocks
                        -- on transparent block edges

                        -- simple plant model (flowers, mushrooms)
                        if TileModel(this) == 1 then
                            local otx,oty = NumberToCoord(TileTextures(this)[1], 16,16)
                            otx = otx + 16*thisLight
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            local diagLong = 0.7071*scale*0.5 + 0.5
                            local diagShort = -0.7071*scale*0.5 + 0.5
                            model[#model+1] = {x+diagShort, y, z+diagShort, tx2,ty2}
                            model[#model+1] = {x+diagLong, y, z+diagLong, tx,ty2}
                            model[#model+1] = {x+diagShort, y+scale, z+diagShort, tx2,ty}
                            model[#model+1] = {x+diagLong, y, z+diagLong, tx,ty2}
                            model[#model+1] = {x+diagLong, y+scale, z+diagLong, tx,ty}
                            model[#model+1] = {x+diagShort, y+scale, z+diagShort, tx2,ty}
                            -- mirror
                            model[#model+1] = {x+diagLong, y, z+diagLong, tx2,ty2}
                            model[#model+1] = {x+diagShort, y, z+diagShort, tx,ty2}
                            model[#model+1] = {x+diagShort, y+scale, z+diagShort, tx,ty}
                            model[#model+1] = {x+diagLong, y+scale, z+diagLong, tx2,ty}
                            model[#model+1] = {x+diagLong, y, z+diagLong, tx2,ty2}
                            model[#model+1] = {x+diagShort, y+scale, z+diagShort, tx,ty}

                            model[#model+1] = {x+diagShort, y, z+diagLong, tx2,ty2}
                            model[#model+1] = {x+diagLong, y, z+diagShort, tx,ty2}
                            model[#model+1] = {x+diagShort, y+scale, z+diagLong, tx2,ty}
                            model[#model+1] = {x+diagLong, y, z+diagShort, tx,ty2}
                            model[#model+1] = {x+diagLong, y+scale, z+diagShort, tx,ty}
                            model[#model+1] = {x+diagShort, y+scale, z+diagLong, tx2,ty}
                            --mirror
                            model[#model+1] = {x+diagLong, y, z+diagShort, tx2,ty2}
                            model[#model+1] = {x+diagShort, y, z+diagLong, tx,ty2}
                            model[#model+1] = {x+diagShort, y+scale, z+diagLong, tx,ty}
                            model[#model+1] = {x+diagLong, y+scale, z+diagShort, tx2,ty}
                            model[#model+1] = {x+diagLong, y, z+diagShort, tx2,ty2}
                            model[#model+1] = {x+diagShort, y+scale, z+diagLong, tx,ty}
                        end

                        -- top
                        local get = self.parent:getVoxel(i,j-1,k)
                        if CanDrawFace(get, thisTransparency) then
                            local otx,oty = NumberToCoord(TileTextures(get)[math.min(2, #TileTextures(get))], 16,16)
                            otx = otx + 16*thisLight
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x, y, z, tx,ty}
                            model[#model+1] = {x+scale, y, z, tx2,ty}
                            model[#model+1] = {x, y, z+scale, tx,ty2}
                            model[#model+1] = {x+scale, y, z, tx2,ty}
                            model[#model+1] = {x+scale, y, z+scale, tx2,ty2}
                            model[#model+1] = {x, y, z+scale, tx,ty2}
                        end

                        -- bottom
                        local get = self.parent:getVoxel(i,j+1,k)
                        if CanDrawFace(get, thisTransparency) then
                            local otx,oty = NumberToCoord(TileTextures(get)[math.min(3, #TileTextures(get))], 16,16)
                            otx = otx + 16*math.max(thisLight-3, 0)
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x+scale, y+scale, z, tx2,ty}
                            model[#model+1] = {x, y+scale, z, tx,ty}
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
                        if CanDrawFace(get, thisTransparency) then
                            local otx,oty = NumberToCoord(TileTextures(get)[1], 16,16)
                            otx = otx + 16*math.max(thisLight-2, 0)
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x, y+scale, z, tx2,ty}
                            model[#model+1] = {x, y, z, tx2,ty2}
                            model[#model+1] = {x, y, z+scale, tx,ty2}
                            model[#model+1] = {x, y+scale, z+scale, tx,ty}
                            model[#model+1] = {x, y+scale, z, tx2,ty}
                            model[#model+1] = {x, y, z+scale, tx,ty2}
                        end

                        -- negative x
                        local get = self.parent:getVoxel(i+1,j,k)
                        if i == ChunkSize then
                            local chunkGet = GetChunk(x+1,y,z)
                            if chunkGet ~= nil then
                                get = chunkGet:getVoxel(1,j,k)
                            end
                        end
                        if CanDrawFace(get, thisTransparency) then
                            local otx,oty = NumberToCoord(TileTextures(get)[1], 16,16)
                            otx = otx + 16*math.max(thisLight-2, 0)
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x+scale, y, z, tx,ty2}
                            model[#model+1] = {x+scale, y+scale, z, tx,ty}
                            model[#model+1] = {x+scale, y, z+scale, tx2,ty2}
                            model[#model+1] = {x+scale, y+scale, z, tx,ty}
                            model[#model+1] = {x+scale, y+scale, z+scale, tx2,ty}
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
                        if CanDrawFace(get, thisTransparency) then
                            local otx,oty = NumberToCoord(TileTextures(get)[1], 16,16)
                            otx = otx + 16*math.max(thisLight-1, 0)
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x, y, z, tx,ty2}
                            model[#model+1] = {x, y+scale, z, tx,ty}
                            model[#model+1] = {x+scale, y, z, tx2,ty2}
                            model[#model+1] = {x, y+scale, z, tx,ty}
                            model[#model+1] = {x+scale, y+scale, z, tx2,ty}
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
                        if CanDrawFace(get, thisTransparency) then
                            local otx,oty = NumberToCoord(TileTextures(get)[1], 16,16)
                            otx = otx + 16*math.max(thisLight-1, 0)
                            local otx2,oty2 = otx+1,oty+1
                            local tx,ty = otx*TileWidth/LightValues,oty*TileHeight
                            local tx2,ty2 = otx2*TileWidth/LightValues,oty2*TileHeight

                            model[#model+1] = {x, y+scale, z+scale, tx2,ty}
                            model[#model+1] = {x, y, z+scale, tx2,ty2}
                            model[#model+1] = {x+scale, y, z+scale, tx,ty2}
                            model[#model+1] = {x+scale, y+scale, z+scale, tx,ty}
                            model[#model+1] = {x, y+scale, z+scale, tx2,ty}
                            model[#model+1] = {x+scale, y, z+scale, tx,ty2}
                        end
                    end
                end
            end
        end

        self.model:setVerts(model)
    end

    t:updateModel()

    return t
end

-- used for building structures across chunk borders
-- by requesting a block to be built in a chunk that does not yet exist
function NewChunkRequest(gx,gy,gz, valueg)
    -- assume structures can only cross one chunk
    local lx,ly,lz = Localize(gx,gy,gz)
    local chunk = GetChunk(gx,gy,gz)

    if chunk ~= nil then
        chunk.requests[#chunk.requests+1] = {x = lx, y = ly, z = lz, value = valueg}
    end
end
