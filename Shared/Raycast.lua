local Raycast = {}
Raycast.__index = Raycast



function Raycast.GetInstanceDownRaycast(instance: Instance, position: Vector3, respectCanCollide: boolean)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {instance}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = respectCanCollide or true
	return workspace:Raycast(position, Vector3.new(0,-100,0), params)
end

function Raycast.penetrateCast(ray: Ray, ignoreList: {[number]: Instance}): {
    hitPart: BasePart,
    hitPoint: Vector3,
    hitNormal: Vector3,
    hitMaterial: Enum.Material,
}
    debug.profilebegin("penetrateCast")
	local tries = 0
	local hitPart, hitPoint, hitNormal, hitMaterial = nil, ray.Origin + ray.Direction, Vector3.new(0, 1, 0), Enum.Material.Air
	while tries < 50 do
		tries = tries + 1
		hitPart, hitPoint, hitNormal, hitMaterial = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList, false, true)
		if hitPart and not hitPart.CanCollide and hitPart.Parent:FindFirstChildOfClass("Humanoid") == nil then
			table.insert(ignoreList, hitPart)
		else
			break
		end
	end
	debug.profileend()
	return {
        hitPart = hitPart,
        hitPoint = hitPoint,
        hitNormal = hitNormal,
        hitMaterial = hitMaterial
    }
end

return Raycast