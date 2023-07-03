local const = {}

const.FUEL_TYPES = {
	consumable = true,
	container = true,
}

const.WORKER_TYPES = {
	miner = true,
	loader = true
}

const.SLOT_DUMP = 1
const.SLOT_FUEL = 2

const.SLOT_MASTER_HELPER = 3
const.SLOT_MASTER_MINERS = 4
const.SLOT_MASTER_LOADERS = 5
const.SLOT_MASTER_MODEMS = 6
const.SLOT_MASTER_FIRST_FREE = 7
const.SLOT_MASTER_DEPLOY = 16

const.SLOT_LOADER_SWAP = 3
const.SLOT_LOADER_FIRST_FREE = 4

const.SLOT_MINER_FIRST_FREE = 3

const.WORKER_TYPE_SLOTS = {
	miner = const.SLOT_MASTER_MINERS,
	loader = const.SLOT_MASTER_LOADERS
}

const.CH_GPS = 65534

const.DIRECTIONS = {
	north = true,
	east = true,
	south = true,
	west = true,
}

const.PATH_MINER = "/ccc/miner.lua"
const.PATH_LOADER = "/ccc/loader.lua"

const.ITEM_TURTLE = "computercraft:turtle_advanced"
const.ITEM_CHUNK_CONTROLLER = "advancedperipherals:chunk_controller"
const.LABEL_CHUNK_CONTROLLER = "chunk controller"
const.ITEM_MODEM = "computercraft:wireless_modem_advanced"
const.LABEL_MODEM = "ender modem"
const.ITEM_PICKAXE = "minecraft:diamond_pickaxe"
const.LABEL_PICKAXE = "diamond pickaxe"

const.HEIGHT_BEDROCK = -60

const.TURTLE_MIN_FUEL = 1000

const.SAFE_BREAK_BLACKLIST = {}
const.SAFE_BREAK_BLACKLIST["computercraft:turtle"] = true
const.SAFE_BREAK_BLACKLIST["computercraft:turtle_advanced"] = true
const.SAFE_BREAK_BLACKLIST["computercraft:computer"] = true
const.SAFE_BREAK_BLACKLIST["computercraft:computer_advanced"] = true

return const
