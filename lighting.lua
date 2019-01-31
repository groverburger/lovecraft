function NewSunlightAddition(x,y,z, value)
    local t = {}
    t.x = x
    t.y = y
    t.z = z
    t.value = value

    t.query = function (self)
        local cget,cx,cy,cz = GetChunk(self.x,self.y,self.z)
        if cget == nil then
            return
        end
        local val,dat = cget:getVoxel(cx,cy,cz)

        if self.value >= 0
        and TileLightable(val)
        and dat < self.value then
            --print(self.x,self.y,self.z)
            cget:setVoxelFirstData(cx,cy,cz, self.value)
            LightingQueueAdd(NewSunlightAddition(self.x,self.y-1,self.z, self.value-1))
            LightingQueueAdd(NewSunlightAddition(self.x,self.y+1,self.z, self.value-1))
            LightingQueueAdd(NewSunlightAddition(self.x+1,self.y,self.z, self.value-1))
            LightingQueueAdd(NewSunlightAddition(self.x-1,self.y,self.z, self.value-1))
            LightingQueueAdd(NewSunlightAddition(self.x,self.y,self.z+1, self.value-1))
            LightingQueueAdd(NewSunlightAddition(self.x,self.y,self.z-1, self.value-1))
        end
    end

    return t
end

function NewSunlightDownAddition(x,y,z, value)
    local t = {}
    t.x = x
    t.y = y
    t.z = z
    t.value = value

    t.query = function (self)
        local cget,cx,cy,cz = GetChunk(self.x,self.y,self.z)
        if cget == nil then
            return
        end
        local val,dat = cget:getVoxel(cx,cy,cz)

        if TileLightable(val) and dat <= self.value then
            --print(self.x,self.y,self.z)
            cget:setVoxelFirstData(cx,cy,cz, self.value)
            LightingQueueAdd(NewSunlightDownAddition(self.x,self.y-1,self.z, self.value))

            LightingQueueAdd(NewSunlightAddition(self.x+1,self.y,self.z, self.value-1))
            LightingQueueAdd(NewSunlightAddition(self.x-1,self.y,self.z, self.value-1))
            LightingQueueAdd(NewSunlightAddition(self.x,self.y,self.z+1, self.value-1))
            LightingQueueAdd(NewSunlightAddition(self.x,self.y,self.z-1, self.value-1))
        end
    end

    return t
end

function NewSunlightSubtraction(x,y,z, value)
    local t = {}
    t.x = x
    t.y = y
    t.z = z
    t.value = value

    t.query = function (self)
        local cget,cx,cy,cz = GetChunk(self.x,self.y,self.z)
        if cget == nil then
            return
        end
        local val,dat = cget:getVoxel(cx,cy,cz)
        local fget = cget:getVoxelFirstData(cx,cy,cz)

        if fget > 0
        and self.value >= 0
        and TileLightable(val) then
            if fget < self.value then
                --print(self.x,self.y,self.z)
                cget:setVoxelFirstData(cx,cy,cz, 0)
                LightingRemovalQueueAdd(NewSunlightSubtraction(self.x,self.y-1,self.z, fget))
                LightingRemovalQueueAdd(NewSunlightSubtraction(self.x,self.y+1,self.z, fget))
                LightingRemovalQueueAdd(NewSunlightSubtraction(self.x+1,self.y,self.z, fget))
                LightingRemovalQueueAdd(NewSunlightSubtraction(self.x-1,self.y,self.z, fget))
                LightingRemovalQueueAdd(NewSunlightSubtraction(self.x,self.y,self.z+1, fget))
                LightingRemovalQueueAdd(NewSunlightSubtraction(self.x,self.y,self.z-1, fget))
            else
                LightingQueueAdd(NewSunlightAddition(self.x,self.y,self.z, fget))
            end

            return false
        end
    end

    return t
end

function NewSunlightDownSubtraction(x,y,z)
    local t = {}
    t.x = x
    t.y = y
    t.z = z

    t.query = function (self)
        if TileLightable(GetVoxel(self.x,self.y,self.z)) then
        -- and GetVoxelData(self.x,self.y,self.z) > self.value
        -- and (GetVoxelData(self.x,self.y+1,self.z) < self.value or TileTransparency(GetVoxel(self.x,self.y+1,self.z)) == 0) then
            SetVoxelFirstData(self.x,self.y,self.z, math.max(GetVoxelFirstData(self.x,self.y,self.z)-1, 0))

            --local chunk = GetChunk(self.x,self.y-1,self.z)
            LightingRemovalQueueAdd(NewSunlightDownSubtraction(self.x,self.y-1,self.z))

            LightingRemovalQueueAdd(NewSunlightSubtraction(self.x+1,self.y,self.z, 15))
            LightingRemovalQueueAdd(NewSunlightSubtraction(self.x-1,self.y,self.z, 15))
            LightingRemovalQueueAdd(NewSunlightSubtraction(self.x,self.y,self.z+1, 15))
            LightingRemovalQueueAdd(NewSunlightSubtraction(self.x,self.y,self.z-1, 15))

            return true
        end
    end

    return t
end
