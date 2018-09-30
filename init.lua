--chunktest

--grab content IDs -- You need these to efficiently access and set node data.  get_node() works, but is far slower
local c_brick = minetest.get_content_id("default:brick")
local c_cobble= minetest.get_content_id("default:cobble")
local c_air = minetest.get_content_id("air")

function xor(b1,b2)
  if (b1==1 or b2==1) and not(b1==1 and b2==1) then
    return 1
  else return 0
  end --if
end --xor


--This is for testing purposes.  It fills every chunk 0 and above with air, 
--replacing every node that is not air.
--except for the outlines of the chunks which it replaces with cobble or brick
function flatland(minp, maxp, seed)
  if maxp.y<0 or minp.y>200 then return end
  --we only replace chunks between 0 and 200 (that is chunks that CONTAIN 0 to 200)
  minetest.log("flatland: in chunk minp="..minetest.pos_to_string(minp).." maxp="..minetest.pos_to_string(maxp))

  --easy reference to commonly used values
  local t1 = os.clock()
  local x1 = maxp.x
  local y1 = maxp.y
  local ymax=maxp.y
  local z1 = maxp.z
  local x0 = minp.x
  local y0 = minp.y
  local ymin=minp.y
  local z0 = minp.z
  
  local bx=math.floor(x0/80) % 2
  local by=math.floor(y0/80) % 2
  local bz=math.floor(z0/80) % 2
  local b1=xor(bx,by)
  local b2=xor(b1,bz)
  local outlinemat=c_brick
  if b2==1 then outlinemat=c_cobble end
  
  

  --This actually initializes the LVM
  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
  local data = vm:get_data()

 --outline chunk for debugging
  local x
  local z
  local y
  local vi
  local edgez
  local edgey
  local edgex
  
  for z=z0, z1 do
    if z==z0 or z==z1 then edgez=1 else edgez=0 end    
    --minetest.log("flatland: z="..z.." edgez="..edgez)    
   	for y=y0, y1 do      
      if y==y0 or y==y1 then edgey=1 else edgey=0 end    
	    --minetest.log("  flatland: y="..y.." edgey="..edgey)    
      for x=x0, x1 do
        if x==x0 or x==x1 then edgex=1 else edgex=0 end    
		    --minetest.log("    flatland: x="..x.." edgex="..edgex)    
        vi = area:index(x, y, z) -- This accesses the node at a given position
        --if at least 2 of our coords are edge values, then replace with stone or brick for outline
        if (edgez+edgey+edgex)>1 then data[vi]=outlinemat else data[vi]=c_air end
        --minetest.log("      flatland: updated ("..x..","..y..","..z..") = "..data[vi])
      end --for z
    end --for y
  end --for x

  
  -- Wrap things up and write back to map
  --send data back to voxelmanip
  vm:set_data(data)
  --calc lighting
  vm:set_lighting({day=0, night=0})
  vm:calc_lighting()
  --write it to world
  vm:write_to_map(data)
  local chugent = math.ceil((os.clock() - t1) * 1000) --grab how long it took
  minetest.log("flatland: END chunk="..x0..","..y0..","..z0.." - "..x1..","..y1..","..z1.."  "..chugent.." ms") --tell people how long
end -- chunktest


minetest.register_on_generated(flatland)



