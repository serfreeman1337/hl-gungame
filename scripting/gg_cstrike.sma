/*
*	HLGunGame CStrike		     v. 0.2
*	by serfreeman1337	http://gf.hldm.org/
*/

/*
*	Features:
*		- buy zone lock
*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>

#include <gungame>

#define PLUGIN "HLGunGame CStrike"
#define VERSION "0.2"
#define AUTHOR "serfreeman1337"

forward csdm_PostSpawn(player, bool:fake)

//
// Plugin vars
//

#define m_fClientMapZone 235
#define MAPZONE_BUYZONE (1<<0)

#define HIDE_HUD_TIMER (1<<4)
#define HIDE_HUD_MONEY (1<<5)

new hudHideFlags

//
// Plugin cvars
//
enum _:cvarsList {
	CVAR_NOMONEY,
	CVAR_NOTIMER,
	CVAR_NOOBJECT,
	
	CVAR_GIVEARMOR,
	CVAR_GIVEHELMET
}

new cvar[cvarsList]

new const mapLockedItems[][] = {
	"func_buyzone",
	"func_bomb_target",
	"info_bomb_target",
	"func_vip_safetyzone",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"hostage_entity",
	"monster_scientist"
}

public plugin_init(){
	register_plugin(PLUGIN,VERSION,AUTHOR)
	
	//
	// Disable money display on HUD
	//
	cvar[CVAR_NOMONEY] = register_cvar("gg_disable_money","1")
	
	//
	// Disable timer display on HUD
	//
	cvar[CVAR_NOTIMER] = register_cvar("gg_disable_timer","1")
	
	//
	// Disable map objects
	//
	cvar[CVAR_NOOBJECT] = register_cvar("gg_disable_object","1")
	
	//
	// Bonus armor on spawn
	//
	cvar[CVAR_GIVEARMOR] = register_cvar("gg_give_armor","100")
	
	//
	// Equip armor with helmet
	//
	cvar[CVAR_GIVEHELMET] = register_cvar("gg_give_helmet","1")
}

new HamHook:restart_hook

public gg_state(bool:isActive){
	static StatusIcon,HideWeapon,hookStatusIcon,hookHideWeapon
	static Array:blockedItems
	
	if(!StatusIcon || !HideWeapon){ // get message ids
		StatusIcon = get_user_msgid("StatusIcon")
		HideWeapon = get_user_msgid("HideWeapon")
	}
	
	// Set hooks for GunGame Active
	if(isActive){
		hookStatusIcon = register_message(StatusIcon, "MSG_StatusIcon")
		
		//
		// HUD hide settings
		//
		if(get_pcvar_num(cvar[CVAR_NOMONEY]))
			hudHideFlags |= HIDE_HUD_MONEY
			
		if(get_pcvar_num(cvar[CVAR_NOTIMER]))
			hudHideFlags |= HIDE_HUD_TIMER
			
		if(hudHideFlags){
			hookHideWeapon = register_message(HideWeapon,"MSG_HideWeapon")
		
			// update hide flags
			message_begin(MSG_ALL,HideWeapon)
			write_byte(hudHideFlags)
			message_end()
		}
		
		if(get_pcvar_num(cvar[CVAR_NOOBJECT])){ // remove map objects
			// get pointer to blocked items array in main plugin
			new xvarItemArray = get_xvar_id("ggblockedItems")
			
			if(xvarItemArray == -1){
				log_amx("ERROR! Can't locate items array in HLGunGame!")
				set_fail_state("items array locate fail")
			}
			
			blockedItems = Array:get_xvar_num(xvarItemArray)
			
			if(!blockedItems){ // create new array
				blockedItems = ArrayCreate(32)
				set_xvar_num(xvarItemArray,_:blockedItems)
			}
			
			// set remove items
			if(blockedItems){
				for(new i ; i < sizeof mapLockedItems ; i++){
					ArrayPushString(blockedItems,mapLockedItems[i])
				}
			}
			
			if(restart_hook)
			{
				EnableHamForward(restart_hook)
			}
			else
			{
				restart_hook = RegisterHam(Ham_CS_Restart,"armoury_entity","Item_ResetHook",true)
			}
		}
		
		server_cmd("sv_restart 1")
	}else{ // reset hooks on GunGame disable
		if(hookStatusIcon)
			unregister_message(StatusIcon,hookStatusIcon)
		
		if(hookHideWeapon){
			unregister_message(HideWeapon,hookHideWeapon)
			
			// update hide flags
			message_begin(MSG_ALL,HideWeapon)
			write_byte(0)
			message_end()
		}
		
		if(get_pcvar_num(cvar[CVAR_NOOBJECT])){
			if(!blockedItems) // create new array
				return
			
			// reset remove items
			if(blockedItems){
				new itemName[32]
				
				for(new i,length = ArraySize(blockedItems) ; i < length ; i++){
					ArrayGetString(blockedItems,i,itemName,charsmax(itemName))
					
					for(new z ; z < sizeof mapLockedItems ; z++){
						if(strcmp(itemName,mapLockedItems[z]) == 0){
							ArrayDeleteItem(blockedItems,i)
							i--
							length--
							
							continue
						}
					}
				}
			}
		}
		
		DisableHamForward(restart_hook)
		server_cmd("sv_restart 1")
	}
}

public Item_ResetHook(ent)
{
	if(callfunc_begin("Item_SpawnHook","gungame.amxx"))
	{
		callfunc_push_int(ent)
		callfunc_end()
	}
}

new xVarEquipSpawn = -2

public csdm_PostSpawn(player, bool:fake){
	if(xVarEquipSpawn == -2)
		if((xVarEquipSpawn = get_xvar_id("ggSpawnEquip")) == -1)
			log_error(AMX_ERR_NOTFOUND,"Can't locate ggSpawnEquip xVar!")
			
	if(xVarEquipSpawn > -1){
		set_xvar_num(xVarEquipSpawn)
		gg_equip_force(player)
	}

}

public gg_player_equip(id){
	if(get_pcvar_num(cvar[CVAR_GIVEARMOR]))
		cs_set_user_armor(id,get_pcvar_num(cvar[CVAR_GIVEARMOR]),get_pcvar_num(cvar[CVAR_GIVEHELMET]) ? CS_ARMOR_VESTHELM : CS_ARMOR_KEVLAR)
}

//
// Hide buy icon and block buy zone
//
public MSG_StatusIcon(MsgID,DEST,id){
	static icon[5] 
	get_msg_arg_string(2, icon, charsmax(icon))
	
	if(icon[0] == 'b' && icon[2] == 'y' && icon[3] == 'z'){
		set_pdata_int(id, m_fClientMapZone, get_pdata_int(id, m_fClientMapZone) &~ MAPZONE_BUYZONE)
		return PLUGIN_HANDLED
	}else if(icon[0] == 'c' && icon[1] == '4' && get_msg_arg_int(1)){ // drop c4 away
		if(user_has_weapon(id,CSW_C4) && get_pcvar_num(cvar[CVAR_NOOBJECT])){
			set_task(0.1,"strip_c4",id);
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}

public strip_c4(id){
	if(is_user_connected(id)) // i am zaebalsya s cs 1.6
		ham_strip_weapon(id,"weapon_c4")
}

//
// Hide money indicator
//
public MSG_HideWeapon(MsgID,DEST,id){
	set_msg_arg_int(1,ARG_BYTE,
		get_msg_arg_int(1) | hudHideFlags
	)
}

public gg_warmup_end(){
	server_cmd("sv_restart 1")
	
	return PLUGIN_HANDLED
}

//
// Part of GunGame plugin by Avalanche
//
// takes a weapon from a player efficiently
stock ham_strip_weapon(id,const weapon[])
{
 	if(!equal(weapon,"weapon_",7)) return 0;

	new wId = get_weaponid(weapon);
	if(!wId) return 0;

	new wEnt;
	while((wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname",weapon)) && pev(wEnt,pev_owner) != id) {}
	if(!wEnt) return 0;

	if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt);

	if(!ExecuteHamB(Ham_RemovePlayerItem,id,wEnt)) return 0;
	ExecuteHamB(Ham_Item_Kill,wEnt);

	set_pev(id,pev_weapons,pev(id,pev_weapons) & ~(1<<wId));
	
	if(wId == CSW_C4)
	{
		cs_set_user_plant(id,0,0);
		cs_set_user_bpammo(id,CSW_C4,0);
	}
	else if(wId == CSW_SMOKEGRENADE || wId == CSW_FLASHBANG || wId == CSW_HEGRENADE)
		cs_set_user_bpammo(id,wId,0);

	return 1;
}
