function NewAddition(x,y,z, value)
    local t = {}
    t.x = x
    t.y = y
    t.z = z
    t.value = value

    t.query = function (self)
        if self.value >= 0
        and TileLightable(GetVoxel(self.x,self.y,self.z))
        and GetChunk(self.x,self.y,self.z) ~= nil
        and GetVoxelData(self.x,self.y,self.z) < self.value then
            --print(self.x,self.y,self.z)
            SetVoxelData(self.x,self.y,self.z, self.value)
            LightingQueueAdd(NewAddition(self.x,self.y-1,self.z, self.value-1))
            LightingQueueAdd(NewAddition(self.x,self.y+1,self.z, self.value-1))
            LightingQueueAdd(NewAddition(self.x+1,self.y,self.z, self.value-1))
            LightingQueueAdd(NewAddition(self.x-1,self.y,self.z, self.value-1))
            LightingQueueAdd(NewAddition(self.x,self.y,self.z+1, self.value-1))
            LightingQueueAdd(NewAddition(self.x,self.y,self.z-1, self.value-1))
        end
    end

    return t
end

function NewSunlightAddition(x,y,z, value)
    local t = {}
    t.x = x
    t.y = y
    t.z = z
    t.value = value

    t.query = function (self)
        if TileLightable(GetVoxel(self.x,self.y,self.z))
        and GetChunk(self.x,self.y,self.z) ~= nil
        and GetVoxelData(self.x,self.y,self.z) <= self.value then
            --print(self.x,self.y,self.z)
            SetVoxelData(self.x,self.y,self.z, self.value)
            LightingQueueAdd(NewSunlightAddition(self.x,self.y-1,self.z, self.value))

            LightingQueueAdd(NewAddition(self.x+1,self.y,self.z, self.value-1))
            LightingQueueAdd(NewAddition(self.x-1,self.y,self.z, self.value-1))
            LightingQueueAdd(NewAddition(self.x,self.y,self.z+1, self.value-1))
            LightingQueueAdd(NewAddition(self.x,self.y,self.z-1, self.value-1))
        end
    end

    return t
end

function NewSubtraction(x,y,z, value)
    local t = {}
    t.x = x
    t.y = y
    t.z = z
    t.value = value

    t.query = function (self)
        if TileLightable(GetVoxel(self.x,self.y,self.z)) then
        -- and GetVoxelData(self.x,self.y,self.z) > self.value
        -- and (GetVoxelData(self.x,self.y+1,self.z) < self.value or TileTransparency(GetVoxel(self.x,self.y+1,self.z)) == 0) then
            SetVoxelData(self.x,self.y,self.z, self.value)

            local chunk = GetChunk(self.x,self.y-1,self.z)
            LightingQueueAdd(NewSubtraction(self.x,self.y-1,self.z, self.value))
        end
    end

    return t
end
