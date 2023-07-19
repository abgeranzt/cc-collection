---@diagnostic disable: undefined-global

local os = {
	pullEvent = Testing.fn("os.pullEvent"),
	queueEvent = Testing.fn("os.queueEvent"),
	getComputerLabel = Testing.fn("os.getComputerLabel"),
	setComputerLabel = Testing.fn("os.setComputerLabel"),
}
---@cast os os

local turtle = {
	detect = Testing.fn("turtle.detect"),
	detectUp = Testing.fn("turtle.detectUp"),
	detectDown = Testing.fn("turtle.detectDown"),
	inspect = Testing.fn("turtle.inspect"),
	inspectUp = Testing.fn("turtle.inspectUp"),
	inspectDown = Testing.fn("turtle.inspectDown"),
	forward = Testing.fn("turtle.forward"),
	back = Testing.fn("turtle.back"),
	up = Testing.fn("turtle.up"),
	down = Testing.fn("turtle.down"),
	dig = Testing.fn("turtle.dig"),
	digUp = Testing.fn("turtle.digUp"),
	digDown = Testing.fn("turtle.digDown"),
	place = Testing.fn("turtle.place"),
	placeUp = Testing.fn("turtle.placeUp"),
	placeDown = Testing.fn("turtle.placeDown"),
	turnLeft = Testing.fn("turtle.turnLeft"),
	turnRight = Testing.fn("turtle.turnRight"),
	refuel = Testing.fn("turtle.refuel"),
	getFuelLevel = Testing.fn("turtle.getFuelLevel"),
	select = Testing.fn("turtle.select"),
	getSelectedSlot = Testing.fn("turtle.getSelectedSlot"),
	getItemCount = Testing.fn("turtle.getItemCount"),
	getItemDetail = Testing.fn("turtle.getItemDetail"),
	transferTo = Testing.fn("turtle.transferTo"),
	equipLeft = Testing.fn("turtle.equipLeft"),
	equipRight = Testing.fn("turtle.equipRight"),
	drop = Testing.fn("turtle.drop"),
	dropUp = Testing.fn("turtle.dropUp"),
	dropDown = Testing.fn("turtle.dropDown"),
	suck = Testing.fn("turtle.suck"),
	suckUp = Testing.fn("turtle.suckUp"),
	suckDown = Testing.fn("turtle.suckDown")
}
---@cast turtle turtle

local sleep = Testing.fn("sleep")

return {
	os = os,
	turtle = turtle,
	sleep = sleep
}
