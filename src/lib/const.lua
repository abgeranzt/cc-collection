local const = {}

const.SLOT_DUMP = 1
const.SLOT_FUEL = 2
const.SLOT_HELPER = 3
const.SLOT_MINERS = 4
const.SLOT_LOADERS = 5
const.SLOT_DEPLOY = 16

const.CH_GPS = 65534

const.DIRECTIONS = {
	north = true,
	east = true,
	south = true,
	west = true,
}

-- TODO change this
const.PATH_MINER = "/ccc/worker.lua"

const.ITEM_MODEM = "computercraft:wireless_modem_advanced"
const.LABEL_MODEM = "ender modem"
const.ITEM_PICKAXE = "minecraft:diamond_pickaxe"
const.LABEL_PICKAXE = "diamond pickaxe"

return const
