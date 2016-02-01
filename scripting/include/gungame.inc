/*
 * Half-Life GunGame
 * Copyright (c) 2012 - 2014 AGHL.RU Dev Team
 * 
 * http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
 *
 *
 *    This program is free software; you can redistribute it and/or modify it
 *    under the terms of the GNU General Public License as published by the
 *    Free Software Foundation; either version 2 of the License, or (at
 *    your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful, but
 *    WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software Foundation,
 *    Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *    In addition, as a special exception, the author gives permission to
 *    link the code of this program with the Half-Life Game Engine ("HL
 *    Engine") and Modified Game Libraries ("MODs") developed by Valve,
 *    L.L.C ("Valve").  You must obey the GNU General Public License in all
 *    respects for all of the code used other than the HL Engine and MODs
 *    from Valve.  If you modify this file, you may extend this exception
 *    to your version of the file, but you are not obligated to do so.  If
 *    you do not wish to do so, delete this exception statement from your
 *    version.
 *
 */

#if defined _gungame_included
	#endinput
#endif
#define _gungame_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib gungame
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib gungame
#endif
#else
	#pragma library gungame
#endif

/**
* Player data struct.
*/
enum _:playersDataStruct {
	PLAYER_CURRENTLEVEL,	// current level
	PLAYER_LASTLEVEL,	// don't use
	PLAYER_KILLS,		// current level kills
	PLAYER_NEEDKILLS,	// required kills
	PLAYER_WEAPONNAME[32],	// level name
	PLAYER_RANKPOS,		// rank pos
	PLAYER_ICON[32],	// level icon
	PLAYER_TEAM,		// current player team id (only in tdm mode)
	Trie:PLAYER_INFLICTORS,	// inflictors map
	Trie:PLAYER_NOREFIL,	// norefil map
	bool:PLAYER_BOT,	// is player bot
	#if defined AGHL_COLOR	// is player using custom client.dll
	bool:PLAYER_AGHL
	#endif
}

/**
* Level data struct.
*/
enum _:weaponSetStruct {
	WSET_SHOWNAME[32],		// level name
	WSET_KILLS,			// level required kills
	WSET_SKIP,			// skip player
	WSET_ICONSPRITE[32],		// level sprite
	Array:WSET_EQUIP_ITEMS,		// equipment array
	Trie:WSET_INFLICTORS_MAP,	// level inflictors
	Trie:WSET_NOREFIL_MAP,		// no refil map
	bool:WSET_BOTCANT		// whether or not this level will be skipped for bots
	#if defined HLWPNMOD
	,bool:WSET_WPNMOD		// whether or not this level has weapon mod weapon
	#endif
}

/**
* Equipment data struct.
*/
enum _:equipStruct {
	EQUIP_NAME[32],				// equipment classname
	EQUIP_CLIP,				// inital clip
	Float:EQUIP_PRIMARY_REFIL_TIME,		// refil time for primary ammo
	Float:EQUIP_SECONDARY_REFIL_TIME,	// refil time for secondary ammo
	EQUIP_PRIMARY_REFIL_AMMOUNT,		// refil ammount for primary ammo
	EQUIP_SECONDARY_REFIL_AMMOUNT,		// refil ammount for secondary ammo
	bool:EQUIP_FULL_PRIMARY,		// disable full primary ammo on spawn
	bool:EQUIP_FULL_SECONDARY,		// disable full secondary ammo on spawn
}

/**
* Called on match end.
*	@param id		Winner index.
*/
forward gg_win(id)

/**
* Called on level up.
*	@param id		Player index.
*	@param newLevel		Player new level.
*	@param oldLevel		Player previos level.
*/
forward gg_levelup(id,newLevel,oldLevel)

/**
* Called on warmup start.
*	you can return PLUGIN_HANDLED to disable freeze function.
*/
forward gg_warmup_start()

/**
* Called on warmup end.
*	you can return PLUGIN_HANDLED to disable freeze function.
*/
forward gg_warmup_end()

/*
* Called on GunGame mod toggle state.
*	@param	state  = true - gungame enabled.
*				    false - gungame disabled.
*/
forward gg_state(bool:currentState)

/*
* Called on player equip.
*	@param	player - player id.
*/
forward gg_player_equip(id)

/**
* Get number of all levels.
*	@return 	Number of all levels.
*/
native gg_get_max_level()

/**
* Retrieve level params.
*	@param level		The level id.
*	@param weaponSet	Level data struct array.
*
*	@return 		True on success or false on failure.
*/
native gg_get_level_data(level,weaponSet[weaponSetStruct])

/**
* Retriev player level data.
*	@param id		Player index.
*	@param playerData	Level data struct array. (optional)
*
*	@return			Current player level on success or -1 on failure.
*/
native gg_get_player_level(id,playerData[playersDataStruct] = 0)

/**
* Set player level.
*	@param id		Player index.
*	@param newLevel		New level index.
*	@param kills		Level kills.
*
*	@return 		True on success or false on failure.
*/
native gg_set_player_level(id,newLevel,kills)

/*
* Force player equip
*	@param player	Player index.
*/
native gg_equip_force(player)
