--!strict

local Config = require(script.Parent.Config)

local Logger = {}

Logger.warn = "[WARN]"
Logger.info = "[INFO]"

function Logger.debug(mode: string, prefix: string, ...)
    if not Config.DEBUG_ENABLED then return end
    if mode == Logger.warn then
        warn(`[REVY][DEBUG][${prefix}][WARN]: ${...}`)
        return
    end
    print(`[REVY][DEBUG][${prefix}][INFO]: ${...}`)
end

function Logger.print(mode: string, prefix: string, ...)
    if mode == Logger.warn then
        warn(`[REVY][${prefix}][WARN]: ${...}`)
        return
    end
    print(`[REVY][${prefix}][INFO]: ${...}`)
end

function Logger.error(prefix: string, msg: string): never
    error(`[REVY][${prefix}][ERROR]: ${msg}`)
end


return Logger