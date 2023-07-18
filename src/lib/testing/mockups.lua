---@diagnostic disable: undefined-global

local os = {
	pullEvent = testing.fn("pullEvent"),
	queueEvent = testing.fn("queueEvent"),
	getComputerLabel = testing.fn("getComputerLabel"),
	setComputerLabel = testing.fn("setComputerLabel"),
}
---@cast os os

local turtle = {
	detect = testing.fn("detect"),
	detectUp = testing.fn("detectUp"),
	detectDown = testing.fn("detectDown"),
	inspect = testing.fn("inspect"),
	inspectUp = testing.fn("inspectUp"),
	inspectDown = testing.fn("inspectDown"),
	dig = testing.fn("dig"),
	digUp = testing.fn("digUp"),
	digDown = testing.fn("digDown"),
	place = testing.fn("place"),
	placeUp = testing.fn("placeUp"),
	placeDown = testing.fn("placeDown"),
	turnLeft = testing.fn("turnLeft"),
	turnRight = testing.fn("turnRight"),
	refuel = testing.fn("refuel"),
	getFuelLevel = testing.fn("getFuelLevel"),
	select = testing.fn("select"),
	getSelectedSlot = testing.fn("getSelectedSlot"),
	getItemCount = testing.fn("getItemCount"),
	getItemDetail = testing.fn("getItemDetail"),
	transferTo = testing.fn("transferTo"),
	equipLeft = testing.fn("equipLeft"),
	equipRight = testing.fn("equipRight"),
	drop = testing.fn("drop"),
	dropUp = testing.fn("dropUp"),
	dropDown = testing.fn("dropDown"),
	suck = testing.fn("suck"),
	suckUp = testing.fn("suckUp"),
	suckDown = testing.fn("suckDown")
}
---@cast turtle turtle

return {
	os = os,
	turtle = turtle
}
