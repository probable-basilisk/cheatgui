![Screenshot of the cheat menu as it appears in Noita](/screenshot.jpg?raw=true)

# Noita Cheat GUI
A basic in-game cheat menu. Note: if you just want to see the alchemy recipes without all the other cheat functionality, [there is a mod for that](https://github.com/probable-basilisk/alchemyrecipes).

## Installation

You can either download the mod manually or clone this Git repo into the Noita `mods` sub-directory.

### (Recommended: opt-in to the Steam beta branch of Noita)
Cheatgui is developed against, and really only tested with, the beta branch. It'll _probably_ work with the non-beta,
but it's not guaranteed.

### Download manually

[Download this repo as a .zip](https://github.com/probable-basilisk/cheatgui/archive/v1.0.zip), 
and extract into your `Noita/mods/` directory (so this README should end up in `Noita/mods/cheatgui/README.md`).

### (or) Clone the Git repo

You can git clone this repo directly into mods:

```
cd {your Noita install dir}/mods/
git clone https://github.com/probable-basilisk/cheatgui.git
```

### Enable the mod in Noita

Enable the 'cheatgui' mod through the in-game pause menu.

You will be prompted that "This mod has requested extra privileges." – see the following section 'Note about scary warnings' for details.

#### Note about scary warnings

Cheatgui asks for scary permissions because it has to do some horrible workarounds in
order to be able to do the type-to-filter thing. Some day I hope the devs will give
us an actual textbox-type GUI component, but until then scary permissions and
hacks are the best we can do. If this permission really scares you, you
can edit `mod.xml` to not request the permission, and it'll mostly still work
except for type-to-filter:

```XML
<Mod
	name="Cheatgui"
	description="Basic cheat menu"
	request_no_api_restrictions="0"
>
</Mod>
```

## Note about paths

Right now I'm having the mod put all its files into the global `data/hax/`
path rather than into the mod-specific path, both because I'm lazy, and
also because I might want to cross-load some of these files from other things.
