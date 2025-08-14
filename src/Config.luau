--!strict

local Config = {

    DEBUG_ENABLED = true,

    TRACE_ENABLED = true,

    MAX_COMPONENTS = 256,

    MASK_LENGTH = 32,

}

local Computes = {

    MASKS_PER_ARRAY = math.ceil(Config.MAX_COMPONENTS / Config.MASK_LENGTH),
    MASK_ARRAY_LENGTH = math.ceil(Config.MAX_COMPONENTS / Config.MASK_LENGTH) * math.ceil(Config.MASK_LENGTH / 8),
    MASK_LENGTH_BYTES = math.ceil(Config.MASK_LENGTH / 8),
    
}

for k, v in Computes do
    Config[k] = v
end

return table.freeze(Config):: typeof(Config) & typeof(Computes)