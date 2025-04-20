-- Імпорт API OBS
local obs = obslua

-- Налаштування за замовчуванням
local settings = {
    delayBeforeFirstPlayback = 10, -- Затримка перед першим відтворенням (в секундах)
    repeatIntervalMin = 60,        -- Мінімальний інтервал повторення медіа (в секундах)
    repeatIntervalMax = 120,       -- Максимальний інтервал повторення медіа (в секундах)
    mediaSourceName = "",          -- Назва медіа-джерела
    autoStartOnStream = true,      -- Автоматичний запуск під час початку стріму
    autoStartOnRecord = false,     -- Автоматичний запуск під час початку запису
    repeatForever = true,          -- Повторювати постійно
    repeatCount = 3,               -- Кількість повторень (якщо не постійно)
    stopAfterDelay = 0,            -- Затримка перед зупинкою медіа (в секундах)
    randomInterval = false,        -- Використовувати випадковий інтервал
    mediaVolume = 1.0              -- Гучність медіа (від 0.0 до 1.0)
}

-- Внутрішні змінні
local timerStarted = false
local elapsedTime = 0
local isStreaming = false
local isRecording = false
local currentRepeatCount = 0
local repeatTimerActive = false
local currentMediaVolume = 1.0

-- Функція для відтворення медіа
function playMedia()
    local source = obs.obs_get_source_by_name(settings.mediaSourceName)
    if source then
        -- Змінюємо гучність медіа
        obs.obs_source_set_volume(source, settings.mediaVolume)

        -- Перевіряємо, чи потрібно зупинити медіа після затримки
        if settings.stopAfterDelay > 0 then
            obs.timer_add(stopMediaAfterDelay, settings.stopAfterDelay * 1000)
        end

        -- Відтворюємо медіа
        obs.obs_source_media_restart(source)
        obs.obs_source_release(source)
        print("Медіа відтворено.")
    else
        print("Помилка: Медіа-джерело не знайдено!")
    end
end

-- Зупинка медіа після затримки
function stopMediaAfterDelay()
    local source = obs.obs_get_source_by_name(settings.mediaSourceName)
    if source then
        obs.obs_source_media_stop(source)
        obs.obs_source_release(source)
        print("Медіа зупинено після затримки.")
    end
end

-- Оновлення таймера
function updateTimer()
    if not timerStarted then
        return
    end

    elapsedTime = elapsedTime + 1

    -- Перевірка, чи пройшла затримка перед першим відтворенням
    if elapsedTime >= settings.delayBeforeFirstPlayback then
        playMedia()
        elapsedTime = 0
        timerStarted = false
        currentRepeatCount = 1 -- Починаємо лічити повтори
        startRepeatTimer()    -- Запускаємо таймер для повторення
    end
end

-- Функція для повторення медіа
function repeatMedia()
    if isStreaming or isRecording then
        if settings.repeatForever or currentRepeatCount < settings.repeatCount then
            playMedia()
            currentRepeatCount = currentRepeatCount + 1
        else
            stopRepeatTimer() -- Зупиняємо таймер, коли досягнуто ліміт повторень
            print("Медіа завершило вказану кількість повторень.")
        end
    else
        stopRepeatTimer() -- Зупиняємо таймер, якщо стрім/запис зупинений
    end
end

-- Запуск таймера для повторення
function startRepeatTimer()
    if not repeatTimerActive then
        local interval = settings.randomInterval and math.random(settings.repeatIntervalMin, settings.repeatIntervalMax) or settings.repeatIntervalMin
        obs.timer_add(repeatMedia, interval * 1000)
        repeatTimerActive = true
        print("Таймер повторення запущено з інтервалом " .. interval .. " сек.")
    end
end

-- Зупинка таймера для повторення
function stopRepeatTimer()
    if repeatTimerActive then
        obs.timer_remove(repeatMedia)
        repeatTimerActive = false
        print("Таймер повторення зупинено.")
    end
end

-- Скидання стану
function resetState()
    timerStarted = false
    elapsedTime = 0
    currentRepeatCount = 0
    stopRepeatTimer()
end

-- Обробник події "початок стріму"
function onStreamStarting()
    isStreaming = true
    if settings.autoStartOnStream then
        startTimer()
    end
end

-- Обробник події "зупинка стріму"
function onStreamStopping()
    isStreaming = false
    resetState()
end

-- Обробник події "початок запису"
function onRecordingStarting()
    isRecording = true
    if settings.autoStartOnRecord then
        startTimer()
    end
end

-- Обробник події "зупинка запису"
function onRecordingStopping()
    isRecording = false
    resetState()
end

-- Запуск таймера
function startTimer()
    timerStarted = true
    elapsedTime = 0
    currentRepeatCount = 0
end

-- Функція ініціалізації
function script_load(settingsTable)
    obs.obs_frontend_add_event_callback(onFrontendEvent)
    obs.timer_add(updateTimer, 1000) -- Оновлення таймера кожну секунду
end

-- Функція завершення
function script_unload()
    obs.timer_remove(updateTimer)
    stopRepeatTimer()
end

-- Обробник подій інтерфейсу
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

-- Додавання налаштувань до інтерфейсу OBS
function script_properties()
    local props = obs.obs_properties_create()

    -- Затримка перед першим відтворенням
    obs.obs_properties_add_int(props, "delayBeforeFirstPlayback", "Затримка перед першим відтворенням (сек)", 0, 3600, 1)

    -- Інтервал повторення медіа
    obs.obs_properties_add_int(props, "repeatIntervalMin", "Мінімальний інтервал повторення медіа (сек)", 1, 3600, 1)
    obs.obs_properties_add_int(props, "repeatIntervalMax", "Максимальний інтервал повторення медіа (сек)", 1, 3600, 1)

    -- Випадковий інтервал
    obs.obs_properties_add_bool(props, "randomInterval", "Викор. випадковий інтервал")

    -- Кількість повторень
    obs.obs_properties_add_int(props, "repeatCount", "Кількість повторень (якщо 'Повторювати постійно' вимкнено)", 1, 100, 1)

    -- Повторювати постійно
    obs.obs_properties_add_bool(props, "repeatForever", "Повторювати постійно")

    -- Затримка перед зупинкою медіа
    obs.obs_properties_add_int(props, "stopAfterDelay", "Затримка перед зупинкою медіа (сек)", 0, 3600, 1)

    -- Гучність медіа
    obs.obs_properties_add_float_slider(props, "mediaVolume", "Гучність медіа (0.0 - 1.0)", 0.0, 1.0, 0.01)

    -- Вибір медіа-джерела
    local sourceList = obs.obs_properties_add_list(props, "mediaSourceName", "Медіа-джерело", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
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

    -- Автоматичний запуск під час стріму
    obs.obs_properties_add_bool(props, "autoStartOnStream", "Авто-запуск під час стріму")

    -- Автоматичний запуск під час запису
    obs.obs_properties_add_bool(props, "autoStartOnRecord", "Авто-запуск під час запису")

    return props
end

-- Збереження налаштувань
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

-- Відображення налаштувань за замовчуванням
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