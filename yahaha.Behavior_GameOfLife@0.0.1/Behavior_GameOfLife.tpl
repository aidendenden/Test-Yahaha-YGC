local selfEntity = script:SelfEntity()
-- Parameters of the Game of Life
local grid_size = 100
local cell_size = 1
local cell_spacing = 0
local interval = 0.1 -- update interval
local cellName = {}
local Generated = false
-- cell state
local grid = {}

local function randomGrid()
    for i = 1, grid_size do
        grid[i] = {}
        for j = 1, grid_size do
            grid[i][j] = math.random(0, 1)
        end
    end
end

-- draw cells
local function draw_cells()
    for i = 1, grid_size do
        cellName[i] = {}
        for j = 1, grid_size do
            local timer = YaTime:WaitFor((i * j) * 0.01)
            EventHelper.AddListener(timer, "TimeEvent", function()
                local cell = YaScene:Spawn("cell", float3.New(0, 0, 0))
                local movableComponent = YaScene:GetComponent(script:GetComponentType("YaMovableComponent"), cell)
                movableComponent:SetPosition(float3.New(i * (cell_size + cell_spacing), i * (cell_size + cell_spacing),
                    j * (cell_size + cell_spacing)))
                cellName[i][j] = cell
                if grid[i][j] == 1 then
                    local Color = float3.New(0, 0, 0)
                    YaDisplayObjectAPI.SetColor(cell, Color)
                else
                    local Color = float3.New(1, 1, 1)
                    YaDisplayObjectAPI.SetColor(cell, Color)
                end
                if i == grid_size and j == grid_size then
                    Generated = true
                end
            end)
        end
    end
end
-- Count the number of live cells around the cell
local function count_neighbors(x, y)
    local count = 0
    for i = -1, 1 do
        for j = -1, 1 do
            if i == 0 and j == 0 then
                -- jump over itself
            elseif x + i < 1 or x + i > grid_size or y + j < 1 or y + j > grid_size then
                -- out of bounds, not counted
            else
                count = count + grid[x + i][y + j]
            end
        end
    end
    return count
end
-- update cell state
local function update_cells()
    local next_grid = {}
    for i = 1, grid_size do
        next_grid[i] = {}
        for j = 1, grid_size do
            local neighbors = count_neighbors(i, j)
            if grid[i][j] == 1 and (neighbors == 2 or neighbors == 3) then
                next_grid[i][j] = 1
            elseif grid[i][j] == 0 and neighbors == 3 then
                next_grid[i][j] = 1
            else
                next_grid[i][j] = 0
            end
        end
    end
    grid = next_grid
end
-- main loop
local function update()
    if Generated == true then
        update_cells()
        for i = 1, grid_size do
            for j = 1, grid_size do
                local cell = cellName[i][j]
                if grid[i][j] == 1 then
                    local Color = float3.New(0, 0, 0)
                    YaDisplayObjectAPI.SetColor(cell, Color)
                else
                    local Color = float3.New(1, 1, 1)
                    YaDisplayObjectAPI.SetColor(cell, Color)
                end
            end
        end
    end
end
-- initialization
local function Start()
    randomGrid()
    draw_cells()
    local timer = YaTime:ScheduleAtInterval(0, interval)
    EventHelper.AddListener(timer, "TimeEvent", update)
end

local function ReStart()
    if Generated == true then
        local timer = YaTime:WaitFor(0.01)
        EventHelper.RemoveListener(timer, "TimeEvent", update)
        randomGrid()
        for i = 1, grid_size do
            for j = 1, grid_size do
                local cell = cellName[i][j]
                if grid[i][j] == 1 then
                    local Color = float3.New(0, 0, 0)
                    YaDisplayObjectAPI.SetColor(cell, Color)
                else
                    local Color = float3.New(1, 1, 1)
                    YaDisplayObjectAPI.SetColor(cell, Color)
                end
            end
        end
        local timer = YaTime:ScheduleAtInterval(0.1, interval)
    EventHelper.AddListener(timer, "TimeEvent", update)
    end
end

Start()

PhysicsAPI.Instance(selfEntity):OnHitEnter(ReStart)