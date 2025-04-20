-- Import OBS API
local obs = obslua

-- Default settings
local settings = {
    delayBeforeFirstPlayback = 10, -- Delay before first playback (in seconds)
    repeatIntervalMin = 60,        -- Minimum repeat interval (in seconds)
    repeatIntervalMax = 120,       -- Maximum repeat interval (in seconds)
    mediaSourceName = "",          -- Media source name
    autoStartOnStream = true,      -- Auto-start on stream start
    autoStartOnRecord = false,     -- Auto-start on recording start
    repeatForever = true,          -- Repeat indefinitely
    repeatCount = 3,               -- Number of repeats (if not repeating forever)
    stopAfterDelay = 0,            -- Stop media after delay (in seconds)
    randomInterval = false,        -- Use random interval
    mediaVolume = 1.0              -- Media volume (0.0 to 1.0)
}

-- Internal variables
local timerStarted = false
local elapsedTime = 0
local isStreaming = false
local isRecording = false
local currentRepeatCount = 0
local repeatTimerActive = false

-- Function to play media
function playMedia()
    local source = obs.obs_get_source_by_name(settings.mediaSourceName)
    if source then
        -- Set media volume
        obs.obs_source_set_volume(source, settings.mediaVolume)

        -- Check if media should stop after delay
        if settings.stopAfterDelay > 0 then
            obs.timer_add(stopMediaAfterDelay, settings.stopAfterDelay * 1000)
        end

        -- Restart media
        obs.obs_source_media_restart(source)
        obs.obs_source_release(source)
        print("Media played.")
    else
        print("Error: Media source not found!")
    end
end

-- Stop media after delay
function stopMediaAfterDelay()
    local source = obs.obs_get_source_by_name(settings.mediaSourceName)
    if source then
        obs.obs_source_media_stop(source)
        obs.obs_source_release(source)
        print("Media stopped after delay.")
    end
end

-- Timer update
function updateTimer()
    if not timerStarted then
        return
    end

    elapsedTime = elapsedTime + 1

    -- Check if delay before first playback has passed
    if elapsedTime >= settings.delayBeforeFirstPlayback then
        playMedia()
        elapsedTime = 0
        timerStarted = false
        currentRepeatCount = 1 -- Start counting repeats
        startRepeatTimer()    -- Start repeat timer
    end
end

-- Function to repeat media
function repeatMedia()
    if isStreaming or isRecording then
        if settings.repeatForever or currentRepeatCount < settings.repeatCount then
            playMedia()
            currentRepeatCount = currentRepeatCount + 1
        else
            stopRepeatTimer() -- Stop timer when repeat limit is reached
            print("Media completed the specified number of repeats.")
        end
    else
        stopRepeatTimer() -- Stop timer if streaming/recording is stopped
    end
end

-- Start repeat timer
function startRepeatTimer()
    if not repeatTimerActive then
        local interval = settings.randomInterval and math.random(settings.repeatIntervalMin, settings.repeatIntervalMax) or settings.repeatIntervalMin
        obs.timer_add(repeatMedia, interval * 1000)
        repeatTimerActive = true
        print("Repeat timer started with interval " .. interval .. " seconds.")
    end
end

-- Stop repeat timer
function stopRepeatTimer()
    if repeatTimerActive then
        obs.timer_remove(repeatMedia)
        repeatTimerActive = false
        print("Repeat timer stopped.")
    end
end

-- Reset state
function resetState()
    timerStarted = false
    elapsedTime = 0
    currentRepeatCount = 0
    stopRepeatTimer()
end

-- Event handler for stream start
function onStreamStarting()
    isStreaming = true
    if settings.autoStartOnStream then
        startTimer()
    end
end

-- Event handler for stream stop
function onStreamStopping()
    isStreaming = false
    resetState()
end

-- Event handler for recording start
function onRecordingStarting()
    isRecording = true
    if settings.autoStartOnRecord then
        startTimer()
    end
end

-- Event handler for recording stop
function onRecordingStopping()
    isRecording = false
    resetState()
end

-- Start timer
function startTimer()
    timerStarted = true
    elapsedTime = 0
    currentRepeatCount = 0
end

-- Script initialization
function script_load(settingsTable)
    obs.obs_frontend_add_event_callback(onFrontendEvent)
    obs.timer_add(updateTimer, 1000) -- Update timer every second
end

-- Script unload
function script_unload()
    obs.timer_remove(updateTimer)
    stopRepeatTimer()
end

-- Frontend event handler
function onFrontendEvent(event)
    if event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED then
        onStreamStarting()
    elseif event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED then
        onStreamStopping()
    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
        onRecordingStarting()
    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
        onRecordingStopping()
    end
end

-- Add settings to OBS interface
function script_properties()
    local props = obs.obs_properties_create()

    -- Delay before first playback
    obs.obs_properties_add_int(props, "delayBeforeFirstPlayback", "Delay before first playback (seconds)", 0, 3600, 1)

    -- Repeat interval
    obs.obs_properties_add_int(props, "repeatIntervalMin", "Minimum repeat interval (seconds)", 1, 3600, 1)
    obs.obs_properties_add_int(props, "repeatIntervalMax", "Maximum repeat interval (seconds)", 1, 3600, 1)

    -- Random interval
    obs.obs_properties_add_bool(props, "randomInterval", "Use random interval")

    -- Number of repeats
    obs.obs_properties_add_int(props, "repeatCount", "Number of repeats (if 'Repeat forever' is off)", 1, 100, 1)

    -- Repeat forever
    obs.obs_properties_add_bool(props, "repeatForever", "Repeat forever")

    -- Stop media after delay
    obs.obs_properties_add_int(props, "stopAfterDelay", "Stop media after delay (seconds)", 0, 3600, 1)

    -- Media volume
    obs.obs_properties_add_float_slider(props, "mediaVolume", "Media volume (0.0 - 1.0)", 0.0, 1.0, 0.01)

    -- Media source selection
    local sourceList = obs.obs_properties_add_list(props, "mediaSourceName", "Media source", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    local sources = obs.obs_enum_sources()
    if sources then
        for _, source in ipairs(sources) do
            local sourceId = obs.obs_source_get_id(source)
            if sourceId == "ffmpeg_source" then
                local name = obs.obs_source_get_name(source)
                obs.obs_property_list_add_string(sourceList, name, name)
            end
        end
        obs.source_list_release(sources)
    end

    -- Auto-start on stream
    obs.obs_properties_add_bool(props, "autoStartOnStream", "Auto-start on stream start")

    -- Auto-start on recording
    obs.obs_properties_add_bool(props, "autoStartOnRecord", "Auto-start on recording start")

    return props
end

-- Save settings
function script_update(settingsTable)
    settings.delayBeforeFirstPlayback = obs.obs_data_get_int(settingsTable, "delayBeforeFirstPlayback")
    settings.repeatIntervalMin = obs.obs_data_get_int(settingsTable, "repeatIntervalMin")
    settings.repeatIntervalMax = obs.obs_data_get_int(settingsTable, "repeatIntervalMax")
    settings.mediaSourceName = obs.obs_data_get_string(settingsTable, "mediaSourceName")
    settings.autoStartOnStream = obs.obs_data_get_bool(settingsTable, "autoStartOnStream")
    settings.autoStartOnRecord = obs.obs_data_get_bool(settingsTable, "autoStartOnRecord")
    settings.repeatForever = obs.obs_data_get_bool(settingsTable, "repeatForever")
    settings.repeatCount = obs.obs_data_get_int(settingsTable, "repeatCount")
    settings.stopAfterDelay = obs.obs_data_get_int(settingsTable, "stopAfterDelay")
    settings.randomInterval = obs.obs_data_get_bool(settingsTable, "randomInterval")
    settings.mediaVolume = obs.obs_data_get_double(settingsTable, "mediaVolume")
end

-- Default settings
function script_defaults(settingsTable)
    obs.obs_data_set_default_int(settingsTable, "delayBeforeFirstPlayback", 10)
    obs.obs_data_set_default_int(settingsTable, "repeatIntervalMin", 60)
    obs.obs_data_set_default_int(settingsTable, "repeatIntervalMax", 120)
    obs.obs_data_set_default_bool(settingsTable, "autoStartOnStream", true)
    obs.obs_data_set_default_bool(settingsTable, "autoStartOnRecord", false)
    obs.obs_data_set_default_bool(settingsTable, "repeatForever", true)
    obs.obs_data_set_default_int(settingsTable, "repeatCount", 3)
    obs.obs_data_set_default_int(settingsTable, "stopAfterDelay", 0)
    obs.obs_data_set_default_bool(settingsTable, "randomInterval", false)
    obs.obs_data_set_default_double(settingsTable, "mediaVolume", 1.0)
end