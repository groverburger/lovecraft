local loader = require ("/obj/obj_loader")

local function modelLoader(path)
	local mesh = {}

	local objdata = loader.load(path) 

	local vertices = objdata.v
	local uvVertices = objdata.vt
	local normalVertices = objdata.vn
	
	for i,v in ipairs(objdata.f) do
		for ii,vv in ipairs(v) do
			table.insert(mesh, {
				vertices[vv.v].x, vertices[vv.v].y, vertices[vv.v].z, vertices[vv.v].w,
				uvVertices[vv.vt].u, uvVertices[vv.vt].v,
				normalVertices[vv.vn].x, normalVertices[vv.vn].y, normalVertices[vv.vn].z
            })
		end
	end

	return mesh
end

return modelLoader
