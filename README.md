# atref
### Asynchronous Turtle Routine Execution Framework

## Summary
This is a collection of lua programs for the Minecraft [ComputerCraft](https://www.computercraft.info/) mod.
In particular, this repository's code was written for the ComputerCraft fork [CC: Tweaked](https://computercraft.cc/)
with additional features added by the [Advanced Peripherals](https://docs.intelligence-modding.de/) mod.

The goal of this repository is to provide a framework for large scale [turtle](https://www.computercraft.info/wiki/Turtle) operations such as quarrying large areas or construction tasks.

The main feature is an asynchronous scalable controller-worker architecture using a task queuing system,
a custom communication protocol on top of the built-in [modem API](https://tweaked.cc/peripheral/modem.html)
and user facilities for setup and configuration.
Additional components are implemented for logging,
parsing and validation of network messages,
task execution,
positionional tracking using the built-in [gps API](https://tweaked.cc/module/gps.html)
and configuration.

<!-- TODO document this -->
Included is a mining mode capable of fully autonomously and potentionally indefinitely quarrying large regions
(assuming the structures for handling the mined material and providing fuel are still in place).

The code consists of a collection of programs runnable with the in-game computers,
the libraries they require and some development scripts.
These programs can either be executed directly by user interaction or programatically.
They are intended to be used in a survival playthrough to facilitate ressource acquisition and construction.

It is designed to be used in a heavily modded version of Minecraft. Because of this, other systems are expected to handle some elements of its operation (e.g. a logistic system for handling large quantities of in-game items or a fuel source).

<!-- TODO create user instructions -->
Various setup and configuration scripts have been created to speed up and facilitate user operation. See the instructions section for more information.

## Showcase
TODO

## Installation
### Automatic Installation
The recommended way to install atref is to run the installation script directly from pastebin. Simply paste and execute the following command inside a computer:
```
pastebin run eNzmgc5c
```

### Manual Installation
If the computer is not able to connect to the internet for some reason (i.e. disabled by the server you are playing on), you may also go to the [releases page]("https://github.com/marcel-engelke/atref/releases/tag/master") and download the packed source code (the file named "packed") and put it on the computer. Do the same for the [installation script](install.lua), execute it and pass the file name as an argument.

Note: This requires access to your Minecraft world directory; if you are playing on a server, ask your admin to help you out.

To avoid having to this for every computer you want to use atref on, consider using the [built-in drives]("https://tweaked.cc/peripheral/drive.html").
```
/path/to/install.lua /path/to/packed
```

### Advanced Installation
Since files on a ComputerCraft computer are actually real files on the host's filesystem, it is possible to symlink the source files into the computer's root directory. This is especially useful for development where the files and their content changes regularly.

To do this, simply create a symbolic link `.local` pointing to the computercraft directory of your world and execute the `link.sh` script. If the computercraft directory does not exist, create it by setting the label of any computer in the world.

Note: The script only works on Unix-like operating systems, the process should similar on Windows, however. A PR with a batch file analogous to link.sh would be appreciated.
```
.local -> /path/to/minecraft/saves/worldname/computercraft
```

## Instructions
TODO

## Development
TODO

## License
Copyright © Marcel Engelke 2023

Licensed unter the GNU General Public License 3. See the [LICENSE](./LICENSE) file for more information.