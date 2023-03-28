local StartPoinEntity = YaEntity.New(_Level_ChessControl.StartPoint)
local _movableComponent = YaScene:GetComponent(script:GetComponentType("YaMovableComponent"), StartPoinEntity)
local basePosition = _movableComponent:GetPosition()
local baseRotation = _movableComponent:GetRotation()
local startX = basePosition.x
local startY = basePosition.y
local startZ = basePosition.z
local spacing = 1
local height = 0.5
local checkerboards = {}
local isWhiteTurn = true
local selectedPiece = nil

local function CreatePiece(type, Row, Col, posX, posY, posZ)
    -- print("this is" .. Row, Col)
    -- print(tostring(float3.New(posX, posY, posZ)))
    local pieceObj = YaScene:Spawn(type, float3.New(posX, posY, posZ))
    local piece = {}
    piece.entityID = pieceObj.EntityId
    piece.type = type
    piece.row = Row
    piece.col = Col
    if Row > 6 then
        local Color = float3.New(0, 0, 0)
        YaDisplayObjectAPI.SetColor(pieceObj, Color)
        piece.isWhite = false
    elseif Row < 3 then
        local Color = float3.New(0.7, 0.7, 0.7)
        YaDisplayObjectAPI.SetColor(pieceObj, Color)
        piece.isWhite = true
    end
    if piece ~= nil then
        print("fuck~~~~!!!!" .. Row .. "+" .. Col)
    end
    return piece
end

local function CreateBoard()
    local board = {}
    for i = 1, 8 do
        board[i] = {}
        checkerboards[i] = {}
        for j = 1, 8 do
            -- local timer = YaTime:WaitFor((i * j) * 0.01)
            -- EventHelper.AddListener(timer, "TimeEvent", function()
            local isWhite = (i + j) % 2 == 0
            local obj =
                YaScene:Spawn("checkerboard", float3.New(startX + (i * spacing), startY, startZ + (j * spacing)))
            if isWhite then
                local Color = float3.New(1, 1, 1)
                YaDisplayObjectAPI.SetColor(obj, Color)
            else
                local Color = float3.New(0, 0, 0)
                YaDisplayObjectAPI.SetColor(obj, Color)
            end
            local piece = nil

            if (i == 1 and j == 1) or (i == 1 and j == 8) or (i == 8 and j == 1) or (i == 8 and j == 8) then
                piece = CreatePiece("rook", i, j, startX + (i * spacing), startY + height, startZ + (j * spacing))
            elseif (i == 1 and j == 2) or (i == 1 and j == 7) or (i == 8 and j == 2) or (i == 8 and j == 7) then
                piece = CreatePiece("knight", i, j, startX + (i * spacing), startY + height, startZ + (j * spacing))
            elseif (i == 1 and j == 3) or (i == 1 and j == 6) or (i == 8 and j == 3) or (i == 8 and j == 6) then
                piece = CreatePiece("bishop", i, j, startX + (i * spacing), startY + height, startZ + (j * spacing))
            elseif (i == 1 and j == 4) or (i == 8 and j == 4) then
                piece = CreatePiece("queen", i, j, startX + (i * spacing), startY + height, startZ + (j * spacing))
            elseif (i == 1 and j == 5) or (i == 8 and j == 5) then
                piece = CreatePiece("king", i, j, startX + (i * spacing), startY + height, startZ + (j * spacing))
            elseif i == 2 or i == 7 then
                piece = CreatePiece("pawn", i, j, startX + (i * spacing), startY + height, startZ + (j * spacing))
            end
            checkerboards[i][j] = obj
            -- if board ~= nil then
            --     print("isHaveSome")
            -- else
            --     print("isNil")
            -- end
            board[i][j] = piece
            -- end)
        end
    end
    return board
end

local board = CreateBoard()

-- 移动棋子
local function MovePiece(board, fromRow, fromCol, toRow, toCol)
    local target = board[toRow][toCol]
    local piece = board[fromRow][fromCol]
    board[toRow][toCol] = board[fromRow][fromCol]
    board[fromRow][fromCol] = nil

    piece.row = toRow
    piece.col = toCol

    if target ~= nil then
        local newPos = float3.New(0, 0, 0)
        local _movableComponent = YaScene:GetComponent(script:GetComponentType("YaMovableComponent"),
            YaEntity.New(target.entityID))
        _movableComponent:SetPosition(newPos)
    end

    local newPos = float3.New(startX + (toRow * spacing), startY + height, startZ + (toCol * spacing))
    local _movableComponent = YaScene:GetComponent(script:GetComponentType("YaMovableComponent"),
        YaEntity.New(piece.entityID))
    _movableComponent:SetPosition(newPos)
end
-- 检查移动是否合法
local function IsValidMove(board, fromRow, fromCol, toRow, toCol)
    local piece = board[fromRow][fromCol]
    local target = board[toRow][toCol]
    if target and target.isWhite == piece.isWhite then
        return false -- 目标位置已有同色棋子
    end
    local dx = math.abs(toCol - fromCol)
    local dy = math.abs(toRow - fromRow)
    print("第一次" .. dx .. "+" .. dy)
    if piece.type == "pawn" then
        if dx == 0 then
            if target then
                print("前方有其他棋子")
                return false -- 前方有其他棋子
            end
            if (piece.isWhite and toRow <= fromRow) or (not piece.isWhite and toRow >= fromRow) then
                print("不能后退")
                return false -- 不能后退
            end
            if (piece.isWhite and fromRow == 2) or (not piece.isWhite and fromRow == 7) then
                print("第一步")
                if dy > 2 then
                    print("只有第一步可以走两格")
                    return false -- 只有第一步可以走两格
                end
            else
                if dy > 1 then
                    print("只能走一格")
                    return false -- 只能走一格
                end
            end
            return true
        elseif dx == 1 and dy == 1 then
            if not target or target.isWhite == piece.isWhite then
                print("只能斜向吃子")
                return false -- 只能斜向吃子
            end
            return true
        else
            return false
        end
    elseif piece.type == "knight" then
        if dx == 2 and dy == 1 then
            return true
        elseif dx == 1 and dy == 2 then
            return true
        else
            return false
        end
    elseif piece.type == "bishop" then
        if dx ~= dy then
            return false
        end
        local sx, sy = fromCol < toCol and 1 or -1, fromRow < toRow and 1 or -1
        for i = 1, dx - 1 do
            local row, col = fromRow + i * sy, fromCol + i * sx
            if board[row][col] then
                return false -- 中间有棋子阻挡
            end
        end
        return true
    elseif piece.type == "rook" then
        if dx > 0 and dy > 0 then
            return false
        end
        if dx == 0 then
            local sy = fromRow < toRow and 1 or -1
            for i = 1, dy - 1 do
                local row = fromRow + i * sy
                if board[row][fromCol] then
                    return false -- 中间有棋子阻挡
                end
            end
            return true
        else
            local sx = fromCol < toCol and 1 or -1
            for i = 1, dx - 1 do
                local col = fromCol + i * sx
                if board[fromRow][col] then
                    return false -- 中间有棋子阻挡
                end
            end
            return true
        end
    elseif piece.type == "queen" then
        print("queen:" .. dx .. "+" .. dy)
        if dx == dy then
            if dx == dy then
                local sx, sy = fromCol < toCol and 1 or -1, fromRow < toRow and 1 or -1
                for i = 1, dx - 1 do
                    local row, col = fromRow + i * sy, fromCol + i * sx
                    if board[row][col] then
                        print("斜向中间有棋子阻挡")
                        return false -- 中间有棋子阻挡
                    end
                end
            end
            return true
        end
        if dx == 0 or dy == 0 then
            if dx == 0 then
                local sy = fromRow < toRow and 1 or -1
                for i = 1, dy - 1 do
                    local row = fromRow + i * sy
                    if board[row][fromCol] then
                        print("y线上间有棋子阻挡")
                        return false -- 中间有棋子阻挡
                    end
                end
            end
            if dy == 0 then
                local sx = fromCol < toCol and 1 or -1
                for i = 1, dx - 1 do
                    local col = fromCol + i * sx
                    if board[fromRow][col] then
                        print("x线上有棋子阻挡")
                        return false -- 中间有棋子阻挡
                    end
                end
            end
            return true
        end
        return false
    elseif piece.type == "king" then
        if dx > 1 or dy > 1 then
            return false
        end
        return true
    end
    return false
end

local function Judgment(EntityId)
    local row = 0
    local col = 0
    for i = 1, 8 do
        for j = 1, 8 do
            local piece = board[i][j]
            local checkerboard = checkerboards[i][j]
            if checkerboard.EntityId == EntityId then
                row = i
                col = j
                break
            elseif piece ~= nil and piece.entityID == EntityId then
                row = i
                col = j
                break
            end
        end
    end

    print("Now num" .. row .. "+" .. col)

    if row + col ~= 0 then
        if selectedPiece ~= nil then
            print("start" .. selectedPiece.row .. "+" .. selectedPiece.col)
            print("To" .. row .. "+" .. col)
            if not IsCheck(board, isWhiteTurn) and IsValidMove(board, selectedPiece.row, selectedPiece.col, row, col) then
                MovePiece(board, selectedPiece.row, selectedPiece.col, row, col)
                isWhiteTurn = not isWhiteTurn
            end
            local pieceObj = YaEntity.New(selectedPiece.entityID)
            local Color
            if selectedPiece.isWhite then
                Color = float3.New(0.7, 0.7, 0.7)
            else
                Color = float3.New(0, 0, 0)
            end
            YaDisplayObjectAPI.SetColor(pieceObj, Color)
            selectedPiece = nil
        else
            print("select" .. row .. "+" .. col)
            local piece = board[row][col]
            if piece and piece.isWhite == isWhiteTurn then
                local pieceObj = YaEntity.New(piece.entityID)
                local Color = float3.New(0, 1, 0)
                YaDisplayObjectAPI.SetColor(pieceObj, Color)
                selectedPiece = piece
            end
        end
    else
        if selectedPiece ~= nil then
            local pieceObj = YaEntity.New(selectedPiece.entityID)
            local Color
            if selectedPiece.isWhite then
                Color = float3.New(0.7, 0.7, 0.7)
            else
                Color = float3.New(0, 0, 0)
            end
            YaDisplayObjectAPI.SetColor(pieceObj, Color)
            selectedPiece = nil
        end
    end
end

function IsCheck(board, isWhite)
    local kingRow, kingCol
    for i = 1, 8 do
        for j = 1, 8 do
            local piece = board[i][j]
            if piece and piece.type == "king" and piece.isWhite == isWhite then
                kingRow, kingCol = i, j
                break
            end
        end
        if kingRow or kingCol then
            break
        end
    end
    for i = 1, 8 do
        for j = 1, 8 do
            local piece = board[i][j]
            if piece and piece.isWhite ~= isWhite and IsValidMove(board, i, j, kingRow, kingCol) then
                return true -- 对方可以攻击到我方国王
            end
        end
    end
    return false
end

YaInputAPI.OnMousePress(function(keycode, screenPos)
    print("OnMousePress keycode" .. tostring(keycode) .. "screen pos: " .. tostring(screenPos))
    if keycode == YaInputCode.LeftMouse then
        local cameraRay = YaCameraAPI.ScreenPointToRay(float3.New(screenPos.x, screenPos.y, 0))
        local query = YaQueryParameter.Instance()
        query = query:QueryPhysicsLayer(0)
        local queryResult = PhysicsAPI.RaycastSingle(cameraRay.origin, cameraRay.direction, query)
        print(tostring(queryResult.Entity.EntityId))
        Judgment(queryResult.Entity.EntityId)
    else
        print("Left mouse is not clicked")
    end
end)

-- YaInputAPI.OnMouseRelease(function(keycode, screenPos)
--     print("OnMouseRelease keycode" .. tostring(keycode) .. "screen pos: " .. tostring(screenPos))
--     if keycode == YaInputCode.LeftMouse then
--         local cameraRay = YaCameraAPI.ScreenPointToRay(float3.New(screenPos.x, screenPos.y, 0))
--         local query = YaQueryParameter.Instance()
--         query = query:QueryAllPhysicsLayer()
--         local queryResult = PhysicsAPI.RaycastSingle(cameraRay.origin, cameraRay.direction, query)
--         print(tostring(queryResult.Entity.EntityId))
--     else
--         print("Left mouse is not clicked")
--     end
-- end)

-- function MovePiece(piece, toRow, toCol)
--     local fromRow, fromCol = piece.row, piece.col
--     local board = piece.gameObject.transform.parent:GetComponent("Board").board
--     local target = board[toRow][toCol]
--     if target and target.type == "king" then
--         -- 对方的国王被将死，游戏结束
--         print(piece.isWhite and "White" or "Black", "wins!")
--         return
--     end
--     board[toRow][toCol] = piece
--     board[fromRow][fromCol] = nil
--     piece.row, piece.col = toRow, toCol
--     local newPos = Vector3(toCol - 4.5, 0, 4.5 - toRow)
--     piece.gameObject.transform.position = newPos
--     if IsCheck(board, not piece.isWhite) then
--         if IsCheckmate(board, not piece.isWhite) then
--             -- 对方被将死，我方胜利
--             print(piece.isWhite and "White" or "Black", "wins!")
--         else
--             -- 对方被将军
--             print(piece.isWhite and "White" or "Black", "is in check.")
--         end
--     end
-- end
