function LightingQueueAdd(lthing)
    LightingQueue[#LightingQueue+1] = lthing
    return lthing
end
function LightingRemovalQueueAdd(lthing)
    LightingRemovalQueue[#LightingRemovalQueue+1] = lthing
    return lthing
end
function LightingUpdate()
    while #LightingRemovalQueue > 0 do
        LightingRemovalQueue[1]:query()
        table.remove(LightingRemovalQueue, 1)
    end

    while #LightingQueue > 0 do
        LightingQueue[1]:query()
        table.remove(LightingQueue, 1)
    end
end

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
        and TileSemiLightable(val)
        and dat < self.value then
            cget:setVoxelFirstData(cx,cy,cz, self.value)
            NewSunlightAddition(self.x,self.y-1,self.z, self.value-1)
            NewSunlightAddition(self.x,self.y+1,self.z, self.value-1)
            NewSunlightAddition(self.x+1,self.y,self.z, self.value-1)
            NewSunlightAddition(self.x-1,self.y,self.z, self.value-1)
            NewSunlightAddition(self.x,self.y,self.z+1, self.value-1)
            NewSunlightAddition(self.x,self.y,self.z-1, self.value-1)
        end
    end

    LightingQueueAdd(t)
end

function NewSunlightAdditionCreation(x,y,z)
    local t = {}
    t.x = x
    t.y = y
    t.z = z

    t.query = function (self)
        local cget,cx,cy,cz = GetChunk(self.x,self.y,self.z)
        if cget == nil then
            return
        end
        local val,dat = cget:getVoxel(cx,cy,cz)

        if TileSemiLightable(val)
        and dat > 0 then
            -- cget:setVoxelFirstData(cx,cy,cz, self.value)
            NewSunlightForceAddition(self.x,self.y,self.z, dat)
            -- NewSunlightAddition(self.x,self.y+1,self.z, dat-1)
            -- NewSunlightAddition(self.x+1,self.y,self.z, dat-1)
            -- NewSunlightAddition(self.x-1,self.y,self.z, dat-1)
            -- NewSunlightAddition(self.x,self.y,self.z+1, dat-1)
            -- NewSunlightAddition(self.x,self.y,self.z-1, dat-1)
        end
    end

    LightingQueueAdd(t)
end

function NewSunlightForceAddition(x,y,z, value)
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
        and TileSemiLightable(val) then
            cget:setVoxelFirstData(cx,cy,cz, self.value)
            NewSunlightAddition(self.x,self.y-1,self.z, self.value-1)
            NewSunlightAddition(self.x,self.y+1,self.z, self.value-1)
            NewSunlightAddition(self.x+1,self.y,self.z, self.value-1)
            NewSunlightAddition(self.x-1,self.y,self.z, self.value-1)
            NewSunlightAddition(self.x,self.y,self.z+1, self.value-1)
            NewSunlightAddition(self.x,self.y,self.z-1, self.value-1)
        end
    end

    LightingQueueAdd(t)
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
            cget:setVoxelFirstData(cx,cy,cz, self.value)
            NewSunlightDownAddition(self.x,self.y-1,self.z, self.value)

            NewSunlightAddition(self.x+1,self.y,self.z, self.value-1)
            NewSunlightAddition(self.x-1,self.y,self.z, self.value-1)
            NewSunlightAddition(self.x,self.y,self.z+1, self.value-1)
            NewSunlightAddition(self.x,self.y,self.z-1, self.value-1)
        end
    end

    LightingQueueAdd(t)
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
        and TileSemiLightable(val) then
            if fget < self.value then
                cget:setVoxelFirstData(cx,cy,cz, 0)
                NewSunlightSubtraction(self.x,self.y-1,self.z, fget)
                NewSunlightSubtraction(self.x,self.y+1,self.z, fget)
                NewSunlightSubtraction(self.x+1,self.y,self.z, fget)
                NewSunlightSubtraction(self.x-1,self.y,self.z, fget)
                NewSunlightSubtraction(self.x,self.y,self.z+1, fget)
                NewSunlightSubtraction(self.x,self.y,self.z-1, fget)
            else
                NewSunlightForceAddition(self.x,self.y,self.z, fget)
            end

            return false
        end
    end

    LightingRemovalQueueAdd(t)
end

function NewSunlightDownSubtraction(x,y,z)
    local t = {}
    t.x = x
    t.y = y
    t.z = z

    t.query = function (self)
        if TileSemiLightable(GetVoxel(self.x,self.y,self.z)) then
            SetVoxelFirstData(self.x,self.y,self.z, 0)

            NewSunlightDownSubtraction(self.x,self.y-1,self.z)

            NewSunlightSubtraction(self.x+1,self.y,self.z, 15)
            NewSunlightSubtraction(self.x-1,self.y,self.z, 15)
            NewSunlightSubtraction(self.x,self.y,self.z+1, 15)
            NewSunlightSubtraction(self.x,self.y,self.z-1, 15)
            NewSunlightSubtraction(self.x,self.y,self.z, 15)

            return true
        end
    end

    LightingRemovalQueueAdd(t)
end
