function NewAddition(x,y,z, value)
    local t = {}
    t.x = x
    t.y = y
    t.z = z
    t.value = value

    t.query = function (self)
        local transp = TileTransparency(GetVoxel(self.x,self.y,self.z))
        if (transp == 0 or transp == 2)
        and GetVoxelData(self.x,self.y,self.z) < self.value
        and GetVoxelData(self.x,self.y+1,self.z) >= self.value then
            SetVoxelData(self.x,self.y,self.z, self.value)

            local chunk = GetChunk(self.x,self.y-1,self.z)
            LightingQueueAdd(NewAddition(self.x,self.y-1,self.z, self.value))
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
        local transp = TileTransparency(GetVoxel(self.x,self.y,self.z))
        if (transp == 0 or transp == 2)
        and GetVoxelData(self.x,self.y,self.z) < self.value then
            SetVoxelData(self.x,self.y,self.z, self.value)

            local chunk = GetChunk(self.x,self.y-1,self.z)
            LightingQueueAdd(NewAddition(self.x,self.y-1,self.z, self.value))
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
        local transp = TileTransparency(GetVoxel(self.x,self.y,self.z))
        if transp == 0 or transp == 2 then
        -- and GetVoxelData(self.x,self.y,self.z) > self.value
        -- and (GetVoxelData(self.x,self.y+1,self.z) < self.value or TileTransparency(GetVoxel(self.x,self.y+1,self.z)) == 0) then
            SetVoxelData(self.x,self.y,self.z, self.value)

            local chunk = GetChunk(self.x,self.y-1,self.z)
            LightingQueueAdd(NewSubtraction(self.x,self.y-1,self.z, self.value))
        end
    end

    return t
end
