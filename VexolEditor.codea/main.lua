--# Main
-- Name: Vexol Editor
-- Author: Jaybob

displayMode(OVERLAY)
function setup()
    -- 创建两个单位图形：ghostImg 和 defaultTexture
    imageSetup()
    -- 设置单位立方体宽度为 20
    BLOCKWIDTH = 20
    -- 完整的大纹理贴图，其中包含多个小贴图，具体的坐标由 TEXRANGE 表给定
    TEXTURE = readImage("Space Art:Icon") or defaultTexture -- readImage("Documents:testTex")
    -- 纹理贴图的子区域选取，左下角和右上角
    -- (0,1)-------(1,1)
    --   |           |
    --   |  (.5,.5)  |
    --   |           |
    -- (0,0)-------(1,0)
    -- 后面在 Model 类中可根据对角坐标计算 texCoords
    TEXRANGE = {
    -- {vec2(0,0),vec2(1,1)}
    {vec2(0,0),vec2(.5,.5)},{vec2(.5,0),vec2(1,.5)},
    {vec2(.5,.5),vec2(1,1)},{vec2(0,.5),vec2(.5,1)},{vec2(0,0),vec2(.08,.1)}
    }
    -- 纹理贴图缺省索引
    TEXINDEX = 1
    -- 全局色彩表
    COLORS = {
    color(255, 255, 255, 255),
    color(42, 190, 217, 255),
    color(193, 80, 80, 255),
    color(237, 160, 41, 255),
    color(98, 45, 173, 255),
    color(69, 96, 208, 255),
    color(179, 204, 44, 255),
    color(52, 132, 124, 255),
    color(146, 194, 77, 255)}
    
    parameter.text("SaveAs")
    parameter.action("SaveMesh",function()save()end)
    
    parameter.text("LoadModelName")
    parameter.action("LoadMesh",function()loadModel()end)
    
    loadMesh = nil
    touches = {}
    cam = Camera()
    ls,rs = Stick(10),Stick(3,WIDTH-120)
    
    -- 立方体的颜色设置
    col = COLORS[1]
    
    model = Model()
    ui = Ui()
    mode = "Add"
    myMat=SeeMat()
end

function draw()
    background(40, 40, 50)
    perspective()
    -- 开始摄像机拍摄：动态更新坐标参数，刷新镜头画面
    cam:draw()
    -- 绘制网格线
    drawScene()
    
    --[[ 这段判断处理应放在哪个位置？另外，如何传递加载的全局数据，不能影响正常的 model 处理逻辑
    -- 思考～～～～～～载入存档
    if loadMesh then  
        model.meshVerts,model.meshColors,model.meshTexCoords =
        loadMesh.vertices,loadMesh.colors,loadMesh.texCoords
        loadMesh=nil
    end
    --]]
    myMat:getMat()
    -- 绘制模型
    model:draw()

    ortho()
    viewMatrix(matrix())
    ui:draw()
    ls:draw()
    rs:draw()
    myMat:draw()
end

-- 主流程的 touched 应该主要负责分配触摸数据到各具体模块
function touched(touch)
    -- 连续的触摸数据放入 touches 表，先处理连续触摸，再处理单独触摸
    if touch.state == ENDED then
        touches[touch.id] = nil
    else
        touches[touch.id] = touch
        -- for k,v in pairs(touches) do print(k,v) end
    end
    -- 单独触摸点击处理，根据点击的区域调用对应的触摸处理函数
    -- 点击模型区则调用模型触摸函数，点击菜单区则调用菜单触摸函数
    if touch.y <= HEIGHT-40 then
        model:touched(touch)
    else
        ui:touched(touch)
    end
end

-- 绘制网格线
function drawScene()
    strokeWidth(2)
    stroke(97, 255, 0, 255)
    pushMatrix()
    translate(0,-200,0) rotate(90,1,0,0)
    for i = -5,5 do
        line(-500,i*100,500,i*100)line(i*100,-500,i*100,500)
    end
    popMatrix()
end

function imageSetup()
    pushStyle()
    strokeWidth(4)
    
    -- 影子立方体初始化
    fill(0, 0, 0, 255)
    stroke(255, 255, 255, 255)
    ghostImg = image(50,50)
    
    setContext(ghostImg) rect(-1,-1,52,52) setContext()
    
    fill(255, 255, 255, 255)
    stroke(0, 0, 0, 255)
    defaultTexture = image(50,50)
    
    setContext(defaultTexture) rect(-1,-1,52,52) setContext()
    popStyle()
end

-- 圆角矩形绘制函数
function rRect(w,h,r)
    strokeWidth(0)
    local img = image(w,h)
    fill(255, 255, 255, 255)
    setContext(img)
    pushMatrix()
    ellipse(r/2,h-r/2,r)ellipse(w-r/2,h-r/2,r)
    ellipse(r/2,r/2,r)ellipse(w-r/2,r/2,r)
    rect(0,r/2,w,h-r) rect(r/2,0,w-r,h)
    popMatrix()
    setContext()
    return img
end

function intersectPlane(planePos,planeNorm,a,b)
    local b = b or vec3(0,0,0)
    local ad = (a-planePos):dot(planeNorm)
    local bd = (b-planePos):dot(planeNorm)
    if ad > 0 and bd < 0 or ad < 0 and bd > 0 then
        local intersection = a+((a-b):normalize()*(a:dist(b)/(a-b):dot(-planeNorm)*ad))
        return true,intersection
    end
    return false
end

function save()
    if SaveAs ~= "" then
        local s = saveMesh()
        saveGlobalData(SaveAs,s)
        output.clear()
        print('Done, saved to global data using key "'..SaveAs..'"')
        print("Load mesh into a project using...")
        print(
        'data = loadstring(readGlobalData("'..SaveAs..'"))()\n'..
        "m = mesh()\n"..
        "m.vertices = data.vertices\n"..
        "m.colors = data.colors\n"..
        'm.texture = "someTexture"\n'..
        "m.texCoords = data.texCoords"
        )
    else
        print("No name given to save as")
    end
end

function saveMesh()
    print("Copying Data")
    local tempVert,tempCol,tempTex = {},{},{}
    for i = 1,#model.meshVerts do
        table.insert(tempVert,model.meshVerts[i])
        table.insert(tempCol,model.meshColors[i])
        table.insert(tempTex,model.meshTexCoords[i])
    end
    print("Checking Doubles")
    local r = {}
    for i = 1,#tempVert-3,3 do
        local a,b,c = tempVert[i],tempVert[i+1],tempVert[i+2]
        for j = i+3,#tempVert,3 do
            if a == tempVert[j] and b == tempVert[j+1] and c == tempVert[j+2] then
                table.insert(r,i)
                table.insert(r,j)
            end
        end
    end
    print("Sorting")
    table.sort(r,function(a,b)
        return a > b
    end)
    print("Deleting Doubles")
    for k,v in ipairs(r) do
        for i = 1,3 do
            table.remove(tempVert,v)
            table.remove(tempCol,v)
            table.remove(tempTex,v)
        end
    end
    print("Saving")
    
    -- 构造输出字符串，依次追加表 tempVert tempCol tempTex 的内容
    local s = "return {"
    s = s.."vertices = {"
    for l,n in ipairs(tempVert) do
        s = s.."vec3("..n.x..","..n.y..","..n.z.."),"
    end
    s = s.."},"
    print("Verts Saved")
    s = s.."colors = {"
    for l,n in ipairs(tempCol) do
        s = s.."color("..n.r..","..n.g..","..n.b..","..n.a.."),"
    end
    s = s.."},"
    print("Colors Saved")
    s = s.."texCoords = {"
    for l,n in ipairs(tempTex) do
        s = s.."vec2("..n.x..","..n.y.."),"
    end
    s = s.."}"
    print("TexCoords Saved")
    s = s.."}"
    return s
end

function loadModel()
    if LoadModelName ~= "" then
        -- local data = loadstring(readGlobalData("Tree"))()
        local data = loadstring(readGlobalData(LoadModelName))()
        local m = mesh()
        m.vertices = data.vertices
        m.colors = data.colors
        m.texCoords = data.texCoords
        loadMesh = m
        return m
    else
        print("No name given to load, please select one below:")
        local modelList = listGlobalData()
        for k,v in pairs(modelList) do
            print(v)
        end
    end
end

desc = [[
usage:
    data = loadstring(readGlobalData("Tree"))()
    m = mesh()
    m.vertices = data.vertices
    m.colors = data.colors
    m.texCoords = data.texCoords
]]


