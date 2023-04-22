# atref
## Asynchronous Turtle Routine Execution Framework

### Summary
This is a collection of lua programs for the Minecraft [ComputerCraft](https://www.computercraft.info/) mod.
In particular, this repository's code was written for the ComputerCraft fork [CC: Tweaked](https://computercraft.cc/)
with additional features added by the [Advanced Peripherals](https://docs.intelligence-modding.de/) mod.

The main function of this repository is to provide a framework for large scale [turtle](https://www.computercraft.info/wiki/Turtle) operations such as quarrying large areas or construction tasks.

The main feature is an asynchronous scalable controller-worker architecture using a task queuing system,
a custom communication protocol on top of the built-in [modem API](https://tweaked.cc/peripheral/modem.html)
and user facilities for setup and configuration.
Additional components are implemented for logging,
parsing and validation of network messages,
task execution,
positionional tracking using the built-in [gps API](https://tweaked.cc/module/gps.html)
and configuration.

<!-- TODO update this when implemented -->
Also planned is a mining mode capable of fully autonomously and potentionally indefinitely quarrying large regions
(assuming the structures for handling the mined material and providing fuel are still in place).

The code consists of a collection of programs runnable with the in-game computers,
the libraries they require and some development scripts.
These programs can either be executed directly by user interaction or programatically.
They are intended to be used in a survival playthrough to faciliate ressource acquisition and construction.

It is designed to be used in a heavily modded version of Minecraft. Because of this, other systems are expected to handle some elements of its operation (e.g. a logistic system for handling large quantities of in-game items or a fuel source).

<!-- TODO create user instructions -->
Various setup and configuration scripts have been created to speed up and faciliate user operation. See the instructions section for more information.

### Showcase
TODO

### Instructions
TODO

### Development
TODO

### License
Copyright © Marcel Engelke 2023

Licensed unter the GNU General Public License 3. See the [LICENSE](./LICENSE) file for more information.