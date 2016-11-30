--# Ui
-- Ui 的设计思路，一是绘制界面，二是确定并保持用户的选择
Ui = class()

function Ui:init()
    self.smallBtn = rRect(30,30,10)
    self.largeBtn = rRect(100,30,10)
    self.tools = {"Add","Delete","Re-Col","Re-Tex"}
    -- 纹理贴图的子贴图列表，可以搞一张大图，其中依次排列多个 50*50 的小贴图
    self.texImg = {}
    -- 整个纹理贴图的宽度，高度
    local texW,texH = TEXTURE.width,TEXTURE.height
    -- 根据子贴图区域坐标向量表 TEXRANGE，计算每个子贴图的宽度/高度，依次绘制后插入 self.texImg 表中保存
    for k,v in ipairs(TEXRANGE) do
        local w,h = texW*(v[2].x-v[1].x),texH*(v[2].y-v[1].y)
        local img = image(w,h)
        setContext(img)
        sprite(TEXTURE,(texW/2)-(texW*v[1].x),(texH/2)-(texH*v[1].y))
        setContext()
        table.insert(self.texImg,img)
    end
    
    -- 增加纯色子贴图
    -- 注意，这里修改的只是菜单区的显示，模型操作区的贴图显示还需要处理
    table.remove(self.texImg,5)
    table.insert(self.texImg,defaultTexture)
    print(#self.texImg,TEXINDEX)
end

function Ui:draw()
    -- 绘制顶部菜单区矩形
    noStroke()
    fill(59, 59, 59, 126)
    rect(-1,HEIGHT-40,WIDTH+1,41)
    
    pushMatrix()
    -- 绘制按钮，选中颜色变为暗色
    for k,v in ipairs(self.tools) do
        if mode == v then
            tint(47, 47, 47, 255)
        else
            tint(96, 96, 96, 255)
        end
        -- 向右平移，保持间距为 105
        translate(105,0)
        sprite(self.largeBtn,0,HEIGHT-20)
        fill(214, 214, 214, 255)
        text(v,0,HEIGHT-20)
    end
    popMatrix()
    
    -- 绘制中间的纹理贴图选择按钮块
    tint(127, 127, 127, 255)
    sprite(self.largeBtn,590,HEIGHT-20)
    tint(255, 255, 255, 255)
    sprite(self.texImg[TEXINDEX],590,HEIGHT-20,28,28)
    
    -- 绘制右上角的颜色选择按钮，选中者变大一圈
    for k,v in ipairs(COLORS) do
        fill(v)
        local s
        if v == col then
            s = 30
        else
            s = 20
        end
        ellipse(k*35+685,HEIGHT-20,s)
    end
end

function Ui:touched(touch)
    if touch.state == ENDED then
        -- 处理顶部菜单按钮事件
        if touch.y > HEIGHT-40 then
            -- 处理前面4个按钮，根据用户的选择设置对应的 mode 值
            for i = 1,4 do
                local x = i * 110 - 50
                if touch.x > x and touch.x < x + 100 then
                    mode = self.tools[i]
                end
            end
            -- 处理中间的纹理贴图选择按钮，设置子贴图索引，用来选择子贴图
            if touch.x > 540 and touch.x < 540 + 100 then
                if TEXINDEX == #TEXRANGE then
                    TEXINDEX = 1
                else
                    TEXINDEX = TEXINDEX + 1
                end
                print(#self.texImg,TEXINDEX)
            end
            -- 处理颜色选择按钮，根据用户的选择设置对应的 col 值
            for k,v in ipairs(COLORS) do
                local x = k * 35 + 685 - 15
                if touch.x > x and touch.x < x + 30 then
                    col = v
                end
            end
        end
    end
end
