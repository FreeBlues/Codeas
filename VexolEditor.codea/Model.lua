--# Model
Model = class()

function Model:init()
    self.vectors = {vec3(-1,0,0),vec3(1,0,0),vec3(0,-1,0),vec3(0,1,0),vec3(0,0,-1),vec3(0,0,1)}
    self.revVec = {2,1,4,3,6,5}
    self.array = {}
    self.bit = {}
    for i = -50,50 do
        self.bit[i] = {}
        for j = -50,50 do
            self.bit[i][j] = {}
        end
    end
    w = BLOCKWIDTH/2
    W = BLOCKWIDTH
    self.boxVerts = {
    vec3(-w,-w, w),vec3(-w, w, w),vec3( w, w, w),vec3( w,-w, w),
    vec3(-w,-w,-w),vec3(-w, w,-w),vec3( w, w,-w),vec3( w,-w,-w)}
    self.boxFaces = {1,2,3,1,4,3,5,6,7,5,8,7,5,6,2,5,1,2,8,7,3,8,4,3,2,6,7,2,3,7,1,5,8,1,4,8}
    local t = TEXRANGE[TEXINDEX]
    self.texPoints = {vec2(0,0),vec2(0,1),vec2(1,1),vec2(1,0)}
    self.boxTex = {1,2,3,1,4,3,1,2,3,1,4,3,1,2,3,1,4,3,1,2,3,1,4,3,1,2,3,1,4,3,1,2,3,1,4,3}
    self.sel = mesh()
    self.sel.texture = ghostImg
    local tc = {}
    local temp = {}
    for k,v in ipairs(self.boxFaces) do
        temp[#temp+1] = self.boxVerts[v]
        tc[#tc+1] = self.texPoints[self.boxTex[k]]
    end
    self.sel.vertices = temp
    self.sel.texCoords = tc
    self.texPoints = {t[1],vec2(t[1].x,t[2].y),t[2],vec2(t[2].x,t[1].y)}
    self.ghost = {}
    self.meshVerts = {}
    self.meshColors = {}
    self.meshTexCoords = {}
    self.mesh = mesh()
    self.mesh.texture = TEXTURE
    self:addCube(vec3(0,0,0))
    self:updateMesh()
    self.moving = false
end

function Model:addCube(pos)
    table.insert(self.array,pos)
    for i = 1,36 do
        table.insert(self.meshVerts,self.boxVerts[self.boxFaces[i]]+(pos*W))
        table.insert(self.meshColors,col)
        table.insert(self.meshTexCoords,self.texPoints[self.boxTex[i]])
    end
    self.bit[pos.x][pos.y][pos.z] = {1,1,1,1,1,1}
    for k,v in ipairs(self.vectors) do
        local t = pos + v
        local target = self.bit[t.x][t.y][t.z]
        if target then
            self.bit[pos.x][pos.y][pos.z][k] = 0
            self.bit[t.x][t.y][t.z][self.revVec[k]] = 0
        end
    end
end

function Model:deleteCube(pos,idx)
    for k,v in ipairs(self.vectors) do
        local t = pos + v
        local target = self.bit[t.x][t.y][t.z]
        if target then
            self.bit[t.x][t.y][t.z][self.revVec[k]] = 1
        end
    end
    self.bit[pos.x][pos.y][pos.z] = nil
    local idxL = (idx * 36) - 35
    for i = 1,36 do
        table.remove(self.meshVerts,idxL)
        table.remove(self.meshColors,idxL)
        table.remove(self.meshTexCoords,idxL)
    end
    table.remove(self.array,idx)
end

function Model:updateMesh()
    self.mesh.vertices = self.meshVerts
    self.mesh.colors = self.meshColors
    self.mesh.texCoords = self.meshTexCoords
end

function Model:draw()
    local t = TEXRANGE[TEXINDEX]
    self.texPoints = {t[1],vec2(t[1].x,t[2].y),t[2],vec2(t[2].x,t[1].y)}
    fill(0, 129, 255, 255)
    if self.ghost and self.moving then
        for k,v in ipairs(self.ghost) do
            pushMatrix()
            local d = v*W
            translate(d:unpack())
            self.sel:draw()
            popMatrix()
        end
    end
    fill(7, 255, 0, 255)
    if self.anchor and self.moving then
        local d = self.array[self.anchor.key]*W
        pushMatrix()
        translate(d:unpack())
        scale(1.1)
        self.sel:draw()
        popMatrix()
    end
    self.mesh:draw()
    if touches[self.tid] == nil then
        self.tid = nil
    end
end

-- 重设纹理贴图
function Model:reTexture(k)
    local k = (k * 36) - 36
    for i = 1,36 do
        self.meshTexCoords[i+k] = self.texPoints[self.boxTex[i]]
    end
    self:updateMesh()
end

-- 重设颜色：ui模块负责提供选好的颜色，以全局变量 col 传递，model 模块负责确定要重设的立方体，然后使用 col
-- 这里两个模块对于功能的划分非常清晰
function Model:reColor(k)
    local k = (k * 36) - 36
    for i = 1,36 do
        self.meshColors[i+k] = col
    end
    self:updateMesh()
end

function Model:touched(touch)
    -- 手指开始按下
    if touch.state == BEGAN then
        self.anchor = self:getTouched(touch)
        if self.anchor then
            self.tid = touch.id
            self.ghost = {self.anchor.tar}
        end
    -- 手指开始拖动
    elseif touch.state == MOVING then
        if self.anchor then
            if mode == "Add" then
                self.moving = true
                self.ghost = {self.anchor.tar}
                local t = cam:zTouch(touch)+cam.eye
                local hit,int = intersectPlane(self.anchor.tar*W,self.anchor.vec,cam.eye,t)
                if hit then
                    local l = {dist = 0,v = vec3(0,0,0)}
                    for i = 1,6 do
                        local v = self.vectors[i]
                        if self.anchor.vec ~= -v and self.anchor.vec ~= v then
                            local d = (int-(self.anchor.tar*W)):dot(v)
                            d = math.min(20,math.floor(d/W))
                            if d > l.dist then
                                l = {dist = d,v = v}
                            end
                        end
                    end
                    if l.dist ~= 0 then
                        local a,b = self.anchor.tar,self.anchor.tar+(l.v*l.dist)
                        local p = a+l.v
                        while p ~= b do
                            if self.bit[p.x][p.y][p.z] then
                                goto next
                            end
                            table.insert(self.ghost,p)
                            p = p + l.v
                        end
                        if not self.bit[b.x][b.y][b.z] then
                            table.insert(self.ghost,b)
                        end
                        ::next::
                    end
                end
            end
        end
    -- 手指离开
    elseif touch.state == ENDED then
        self.moving = false
        if mode == "Add" then
            if #self.ghost > 0 then
                for k,v in ipairs(self.ghost) do
                    self:addCube(v)
                end
                self:updateMesh()
            end
        elseif mode == "Delete" then
            if self.anchor then
                self:deleteCube(self.array[self.anchor.key],self.anchor.key)
                self:updateMesh()
            end
        elseif mode == "Re-Tex" then
            if self.anchor then
                self:reTexture(self.anchor.key)
            end
        elseif mode == "Re-Col" then
            if self.anchor then
                self:reColor(self.anchor.key)
            end
        end
        self.ghost = {}
        self.anchor = nil
        self.endPoint = nil
    end
end

function Model:getTouched(touch)
    local low = {dist = 100000}
    local t = cam:zTouch(touch)+cam.eye
    for k,v in ipairs(self.array) do
        local bit = self.bit[v.x][v.y][v.z]
        if bit then
        local cen = v * W
        for i = 1,6 do
            if bit[i] == 1 then
                local vec = self.vectors[i]
                if (((v*W)+(vec*w))-cam.eye):dot(vec) < 0 then 
                    local pos = vec*w+cen
                    local hit,int = intersectPlane(pos,vec,cam.eye,t)
                    if hit and int:dist(pos) < w then
                        local d = int:dist(cam.eye)
                        if d < low.dist then
                            low = {key=k,dist=d,tar=v+vec,vec=vec}
                        end
                    end
                end
            end
        end
        end
    end
    if low.dist ~= 100000 then
        return low
    end
end






