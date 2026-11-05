local Layout = {}
local pitch = workspace:WaitForChild("Lobby"):WaitForChild("_Layout"):WaitForChild("Bounds_Pitch")
Layout.Pitch = pitch
Layout.Length = pitch.Size.Z
Layout.Width = pitch.Size.X
-- normalized: u in [-0.5, 0.5] along the long axis (-0.5 = BOTTOM/tunnel end, +0.5 = TOP/jumbotron end), v in [-0.5, 0.5] across (+ = right when looking toward TOP)
function Layout.point(u, v, y)
    return pitch.CFrame:PointToWorldSpace(Vector3.new(v * Layout.Width, 0.5 + (y or 0), -u * Layout.Length))
end
-- studs from the pitch center: du along the long axis (+ toward TOP), dv across (+ right)
function Layout.pointStuds(du, dv, y)
    return pitch.CFrame:PointToWorldSpace(Vector3.new(dv, 0.5 + (y or 0), -du))
end
function Layout.cfFacing(position, target)
    local flat = Vector3.new(target.X, position.Y, target.Z)
    return CFrame.lookAt(position, flat)
end
Layout.TopDir = function() return pitch.CFrame.LookVector end
Layout.RightDir = function() return pitch.CFrame.RightVector end
function Layout.anchor(name) return workspace.Lobby._Layout:WaitForChild(name).Position end
return Layout
