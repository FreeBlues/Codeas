--# Camera
-- 因为要根据用户触摸来设置摄像机的各项参数，所以 Camera 类和 Stick 类耦合比较深
Camera = class()

function Camera:init(eX,eY,eZ,lX,lY,lZ)
    self.eye = vec3(eX or 0, eY or 0, eZ or 400)
    self.lat = vec3(lX or 0, lY or 0, lZ or 0)
    self.dist = self.lat:dist(self.eye)
    self.angH = 90
    self.angV = -90
    self.fix = true
    self.crosshair = true
end

function Camera:draw()
    -- 根据右下角操纵杆 rs 的坐标调整摄像机角度
    self.angH = self.angH + rs.x
    self.angV = self.angV + rs.y
    -- 根据左下角操纵杆 ls 的坐标移动摄像机，只在 xoz 平面移动()，y轴不变
    self:moveLocal(ls.x,nil,ls.y)
    -- 归一化
    self.Z = (self.lat-self.eye):normalize()
    self.X = self.Z:cross(vec3(0,1,0)):normalize()
    self.Y = self.X:cross(self.Z):normalize()
    -- 设置摄像机垂直夹角的范围
    self.angV = math.min(-1,math.max(-179,self.angV))
    if self.fix then
        self.eye = -self:rotatePoint() + self.lat
    else
        self.lat =  self:rotatePoint() + self.eye
    end
    -- 把以上实时计算好的参数提供给 camera 函数
    camera(self.eye.x, self.eye.y, self.eye.z,self.lat.x, self.lat.y, self.lat.z)
    -- 绘制立体十字线
    self:drawCrosshair() 
    self.mat = modelMatrix()*viewMatrix()*projectionMatrix()
end

function Camera:moveLocal(x,y,z)
    if x and x ~= 0 then
        local xVel = self.X * x
        self.eye = self.eye + xVel
        self.lat = self.lat + xVel
    end
    if y and y ~= 0 then
        local yVel = self.Y * y
        self.eye = self.eye + yVel
        self.lat = self.lat + yVel
    end
    if z and z ~= 0 then
        local zVel = self.Z * z
        self.eye = self.eye + zVel
        self.lat = self.lat + zVel
    end
end

function Camera:rotatePoint()
    -- calculate y and z from angV at set distance
    local y = math.cos(math.rad(self.angV))*self.dist
    local O = math.sin(math.rad(self.angV))*self.dist
    -- calculate x and z from angH using O as the set distance
    local x = math.cos(math.rad(self.angH))*O
    local z = math.sin(math.rad(self.angH))*O
    return vec3(x,y,z)
end

function Camera:drawCrosshair(w)
    local w = w or 50
    pushMatrix()pushStyle()
    translate(self.lat.x,self.lat.y, self.lat.z)
    strokeWidth(2)
    stroke(38, 255, 0, 255)
    line(-w/2,0,w/2,0)
    stroke(255, 187, 0, 255)
    line(0,-w/2,0,w/2) rotate(90,1,0,0)
    stroke(73, 0, 255, 255)
    line(0,-w/2,0,w/2)
    popMatrix()popStyle()
end

function Camera:screenPos(p)
    local m = self.mat
    m = m:translate(p.x, p.y, p.z)
    local X, Y = (m[13]/m[16]+1)*WIDTH/2, (m[14]/m[16]+1)*HEIGHT/2
    return vec2(X,Y)
end

function Camera:zTouch(touch,depth)
    local depth = depth or 2000
    local zDepth = 0.9086 -- adjust for different fov
    local x = depth / zDepth * cam.X * ( touch.x / WIDTH - 0.5)
    local y = depth / zDepth * cam.Y * ((touch.y / HEIGHT - 0.5) / (WIDTH/HEIGHT))
    return x + y + (depth * cam.Z)
end

-- 操纵杆类
Stick = class()

function Stick:init(ratio,x,y)
    self.ratio = ratio or 1
    self.i = vec2(x or 120,y or 120)
    self.v = vec2(0,0)
    self.b = b or 180
    self.s = s or 100
    self.d = d or 50
    self.a = 0
    self.touchId = nil
    self.x,self.y = 0,0
end

function Stick:draw()
    -- 若触摸表为空
    if touches[self.touchId] == nil then
        for i,t in pairs(touches) do
            if vec2(t.x,t.y):dist(self.i) < self.b/2 then self.touchId = i end
        end
        self.v = vec2(0,0)
    else
        self.v = vec2(touches[self.touchId].x,touches[self.touchId].y) - self.i
        self.a = math.deg(math.atan2(self.v.y,self.v.x))
    end
    self.t = math.min(self.b/2,self.v:len())
    if self.t >= self.b/2 then
        self.v = vec2(math.cos(math.rad(self.a))*self.b/2,math.sin(math.rad(self.a))*self.b/2)
    end
    fill(127, 127, 127, 150)
    -- 分别绘制小圆，大圆
    ellipse(self.i.x,self.i.y,self.b)
    ellipse(self.i.x+self.v.x,self.i.y+self.v.y,self.s)
    self.v = self.v/(self.b/2)*self.ratio
    self.t = self.t/(self.b/2)*self.ratio
    self.x,self.y = self.v.x,self.v.y
end

