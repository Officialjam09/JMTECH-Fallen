-- JMTECH Fallen | Project Vector Frame/Cursor Diagnostics
-- Standalone diagnostic: does NOT change aiming, shooting or camera behavior.
-- Based on Project Vector APIs: OnFrame, utility.GetMousePos, utility.GetTickCount.
-- Run separately from the original script for baseline measurements.

local function tick_ms()
    local fn = utility and (utility.GetTickCount or utility.get_tick_count)
    if type(fn) == "function" then
        local ok, value = pcall(fn)
        if ok and type(value) == "number" then return value end
    end
    return math.floor(os.clock() * 1000)
end

local function read_mouse()
    local fn = utility and (utility.GetMousePos or utility.get_mouse_pos)
    if type(fn) ~= "function" then return nil, nil end
    local ok, a, b = pcall(fn)
    if not ok then return nil, nil end
    if type(a) == "table" then
        return tonumber(a.x or a.X or a[1]), tonumber(a.y or a.Y or a[2])
    end
    if type(a) == "number" and type(b) == "number" then return a, b end
    return nil, nil
end

local frames, total, spikes, max_delta = 0, 0, 0, 0
local last_tick, report_at = nil, tick_ms()
local valid_mouse, missing_mouse = 0, 0
local prior_frame = _G.OnFrame

local function diagnostic_frame(...)
    local now = tick_ms()
    if last_tick then
        local dt = now - last_tick
        if dt >= 0 and dt < 10000 then
            frames = frames + 1
            total = total + dt
            if dt > max_delta then max_delta = dt end
            if dt > 33 then spikes = spikes + 1 end
        end
    end
    last_tick = now
    local x, y = read_mouse()
    if x and y then valid_mouse = valid_mouse + 1 else missing_mouse = missing_mouse + 1 end
    if now - report_at >= 5000 then
        local mean = frames > 0 and total / frames or 0
        local fps = mean > 0 and 1000 / mean or 0
        print(string.format("[JMTECH DIAG] FPS(avg)=%.1f frame_avg=%.1fms frame_max=%.1fms >33ms=%d mouse_ok=%d mouse_missing=%d", fps, mean, max_delta, spikes, valid_mouse, missing_mouse))
        frames, total, spikes, max_delta = 0, 0, 0, 0
        valid_mouse, missing_mouse = 0, 0
        report_at = now
    end
    if type(prior_frame) == "function" then
        local ok, err = pcall(prior_frame, ...)
        if not ok then print("[JMTECH DIAG] Previous OnFrame error: " .. tostring(err)) end
    end
end

_G.OnFrame = diagnostic_frame
_G.onFrame = diagnostic_frame
_G.on_frame = diagnostic_frame
print("[JMTECH DIAG] Started. Open console; output every 5 seconds. Does not modify targeting.")
