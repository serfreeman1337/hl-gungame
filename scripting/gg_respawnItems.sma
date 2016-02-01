/*
	GG Respawn Items On WarmUP End		      v.0.1
	by serfreeman1337		http://gf.hldm.org/
*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <gungame>

#define PLUGIN "HLGG Respawn Items"
#define VERSION "0.2"
#define AUTHOR "serfreeman1337"

new const respawnItems[][] = {
	"item_battery",
	"item_healthkit",
	"item_longjump"
}

new const wallChargers[][] = {
	"func_healthcharger",
	"func_recharge"
}

#define	m_iJuice	62   // healthcharger capacity

public plugin_init(){
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public gg_warmup_end(){
	new ent,i
	
	for(i = 0; i < sizeof respawnItems ; i++)
		while((ent = find_ent_by_class(ent,respawnItems[i])))
			ExecuteHamB(Ham_Think,ent)
			
	ent = 0
			
	for(i = 0; i < sizeof wallChargers ; i++)
		while((ent = find_ent_by_class(ent,wallChargers[i]))){
			entity_set_float(ent,EV_FL_frame,0.0)
			set_pdata_int(ent,m_iJuice,30,4)
		}
}
