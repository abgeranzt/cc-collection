---@diagnostic disable: undefined-global

local os = {
	pullEvent = Testing.fn("pullEvent"),
	queueEvent = Testing.fn("queueEvent"),
	getComputerLabel = Testing.fn("getComputerLabel"),
	setComputerLabel = Testing.fn("setComputerLabel"),
}
---@cast os os

local turtle = {
	detect = Testing.fn("detect"),
	detectUp = Testing.fn("detectUp"),
	detectDown = Testing.fn("detectDown"),
	inspect = Testing.fn("inspect"),
	inspectUp = Testing.fn("inspectUp"),
	inspectDown = Testing.fn("inspectDown"),
	dig = Testing.fn("dig"),
	digUp = Testing.fn("digUp"),
	digDown = Testing.fn("digDown"),
	place = Testing.fn("place"),
	placeUp = Testing.fn("placeUp"),
	placeDown = Testing.fn("placeDown"),
	turnLeft = Testing.fn("turnLeft"),
	turnRight = Testing.fn("turnRight"),
	refuel = Testing.fn("refuel"),
	getFuelLevel = Testing.fn("getFuelLevel"),
	select = Testing.fn("select"),
	getSelectedSlot = Testing.fn("getSelectedSlot"),
	getItemCount = Testing.fn("getItemCount"),
	getItemDetail = Testing.fn("getItemDetail"),
	transferTo = Testing.fn("transferTo"),
	equipLeft = Testing.fn("equipLeft"),
	equipRight = Testing.fn("equipRight"),
	drop = Testing.fn("drop"),
	dropUp = Testing.fn("dropUp"),
	dropDown = Testing.fn("dropDown"),
	suck = Testing.fn("suck"),
	suckUp = Testing.fn("suckUp"),
	suckDown = Testing.fn("suckDown")
}
---@cast turtle turtle

return {
	os = os,
	turtle = turtle
}
