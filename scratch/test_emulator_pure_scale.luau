local HttpService = game:GetService("HttpService")

local tests = {
    {name = "iPhone SE Landscape", w = 667, h = 375},
    {name = "iPhone 14 Landscape", w = 844, h = 390},
    {name = "Small Android Landscape", w = 640, h = 360},
}

local results = {}

for _, dev in ipairs(tests) do
    local screenW = dev.w
    local screenH = dev.h
    
    -- 1. LEFT NAV COLUMN
    -- Container: AnchorPoint (0, 0), Position {0.01, 0}, {0.11, 0}, Size {0.12, 0}, {0.64, 0}
    local leftNavX = screenW * 0.01
    local leftNavY = screenH * 0.11
    local leftNavW = screenW * 0.12
    local leftNavH = screenH * 0.64
    
    -- UIListLayout: Vertical, Padding {0.012, 0} relative to LeftNavGroup height
    -- 5 buttons, each Size {1, 0}, {0.18, 0} relative to LeftNavGroup, with UIAspectRatioConstraint 1:1 (DominantAxis Height)
    local btnH = leftNavH * 0.18
    local btnW = btnH -- 1:1 aspect ratio with DominantAxis Height
    -- Min size constraint 44px
    if btnH < 44 then
        btnH = 44
        btnW = 44
    end
    local padH = leftNavH * 0.012
    
    local numButtons = 5
    local totalColumnH = (btnH * numButtons) + (padH * (numButtons - 1))
    local colEndY = leftNavY + totalColumnH
    local colEndYRatio = colEndY / screenH
    
    -- Free badge on Shop button: child of Shop, top center
    -- Index badge on Index button: child of Index, top right corner
    
    -- 2. CURRENCY GROUP
    -- Container: AnchorPoint (0, 1), Position {0.01, 0}, {0.98, 0}, Size {0.26, 0}, {0.20, 0}
    local curW = screenW * 0.26
    local curH = screenH * 0.20
    local curX = screenW * 0.01
    local curY = (screenH * 0.98) - curH -- top of currency group
    local curEndY = screenH * 0.98
    local curStartYRatio = curY / screenH
    
    -- Row A: Friends Boost: Size {1, 0}, {0.42, 0}
    -- Row B: Cash: Size {1, 0}, {0.54, 0}
    -- Vert padding: 0.04
    
    -- 3. RIGHT PROMO GROUP
    -- AnchorPoint (1, 0.5), Position {0.99, 0}, {0.5, 0}, Size {0.14, 0}, {0.30, 0}
    local promoW = screenW * 0.14
    local promoH = screenH * 0.30
    local promoX = (screenW * 0.99) - promoW
    local promoY = (screenH * 0.50) - (promoH * 0.5)
    local promoEndY = promoY + promoH
    
    -- Jump button (bottom-right on mobile touch: ~70px at (screenW - 95, screenH - 95))
    local jumpTopY = screenH - 110
    local jumpClearancePx = jumpTopY - promoEndY
    
    -- 4. ROBUX PRICE BADGE
    -- Pill Frame: Size {0.8, 0}, {0.24, 0} relative to slot
    -- Slot height: promoH * 0.46
    local slotH = promoH * 0.46
    local pillW = slotH * 0.80
    local pillH = slotH * 0.24
    -- Padding 0.08 on left/right -> usable width = pillW * 0.84
    local usablePillW = pillW * 0.84
    -- Icon: height 0.75 of pillH, 1:1 -> iconW = pillH * 0.75
    local iconW = pillH * 0.75
    local listPadW = pillW * 0.06
    -- Label: width 0.55 of pillW
    local lblW = pillW * 0.55
    local totalContentW = iconW + listPadW + lblW
    local priceBadgeFits = totalContentW <= usablePillW + 0.5 -- with rounding
    
    -- OVERLAP CHECKS
    -- Left Nav vs Currency: colEndY must be <= curY
    local leftNavCurOverlap = colEndY > curY
    local gapBetweenNavAndCur = curY - colEndY
    
    -- Left Nav vs Screen bounds: must end <= 0.76
    local colFits = colEndYRatio <= 0.76
    
    -- Promo vs Jump button
    local promoJumpOverlap = jumpClearancePx < 0
    
    table.insert(results, {
        device = dev.name,
        resolution = dev.w .. "x" .. dev.h,
        btnHeightPx = math.floor(btnH),
        columnEndY = string.format("%.2f", colEndYRatio),
        currencyStartY = string.format("%.2f", curStartYRatio),
        gapNavCurPx = math.floor(gapBetweenNavAndCur),
        jumpClearancePx = math.floor(jumpClearancePx),
        leftNavCurOverlap = leftNavCurOverlap,
        priceBadgeFits = priceBadgeFits,
        singleColumn = true,
        status = (not leftNavCurOverlap and not promoJumpOverlap and colFits and priceBadgeFits) and "PASS" or "FAIL"
    })
end

return HttpService:JSONEncode(results)
