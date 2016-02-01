/*
*	HLGunGame WarmUp Vote		     v. 0.1
*	by serfreeman1337	http://gf.hldm.org/
*/

#include <amxmodx>
#include <gungame>
#include <time>

#define PLUGIN "HLGunGame WarmUp Vote"
#define VERSION "0.1a"
#define AUTHOR "serfreeman1337"

#include <fun>

// -- DEFINES -- //

// -- PLUGIN VARS -- //

#define TASKID_VOTE		100
#define TASKID_VOTESTART	99889988 // this allows stop this vote throught amx_cancelvote command

enum _:cvarsList {
	CVAR_VOTEMODE,
	
	// HLGunGame cvars
	CVAR_WARMUP,
	CVAR_TEAMPLAY,
	
	// AMXX cvars
	CVAR_VOTETIME,
	CVAR_VOTEANSWERS,
	CVAR_VOTERATIO
}

new cvar[cvarsList],Float:upTime
new voteDM,voteTDM

#define bit_owner_add(%0,%1) %0 |= 1 << (%1 - 1)
#define bit_owner_sub(%0,%1) %0 &= ~(1 << (%1 - 1))
#define bit_owner(%0,%1) %0 & 1 << (%1 - 1)

public plugin_precache(){
	//
	// Vote start mode
	//	0 - vote during warmup
	//
	cvar[CVAR_VOTEMODE] = register_cvar("gg_vote_mode","0")
	
	//
	// HLGunGame cvars pointer
	//
	
	//
	// Warmup time
	//
	cvar[CVAR_WARMUP] = get_cvar_pointer("gg_warmup")
	
	if(!cvar[CVAR_WARMUP]){ // check cvar exists
		log_amx("ERROR! Cvar ^"gg_warmup^" not found!")
		set_fail_state("cvar gg_warmup not found")
	}
	
	//
	// Teamplay mode
	//
	cvar[CVAR_TEAMPLAY] = get_cvar_pointer("gg_teamplay")
	
	if(!cvar[CVAR_TEAMPLAY]){
		log_amx("ERROR! Cvar ^"gg_teamplay^" not found!")
		log_amx("Teamplay support from HLGunGame 2.1")
		
		set_fail_state("cvar gg_teamplay not found")
	}
	
	
	//
	// AMXX cvars pointer
	//
	
	//
	// How long voting session goes on
	// For warmup its sets minimum required time to start vote
	//
	cvar[CVAR_VOTETIME] = get_cvar_pointer("amx_vote_time")
	
	//
	// Display who votes for what option, set to 0 to disable, 1 to enable.
	//
	cvar[CVAR_VOTEANSWERS] = get_cvar_pointer("amx_vote_answers")
	
	//
	// Display who votes for what option, set to 0 to disable, 1 to enable.
	//
	cvar[CVAR_VOTERATIO] = get_cvar_pointer("amx_voteban_ratio")
}

public plugin_init(){
	register_plugin(PLUGIN,VERSION,AUTHOR)
	register_dictionary("gg_teamvote.txt")
	register_dictionary("adminvote.txt")
	register_dictionary("time.txt")
	
	register_clcmd("test","test")
}

public test(id)
	set_user_godmode(id,true)

//
// WarmUp Start
//
public gg_warmup_start(){
	if(get_pcvar_num(cvar[CVAR_VOTEMODE]) == 0){ // vote at warmup
		upTime = get_pcvar_float(cvar[CVAR_WARMUP]) / 2.0 // start vote during half of warmup time
		
		if(upTime < get_pcvar_float(cvar[CVAR_VOTETIME])){ // upTime to low
			log_amx("WARNING! Can't start vote because of low warmup time!")
			return
		}
		
		set_task(upTime,"StartVote",TASKID_VOTE)
	}
}

//
// Start vote for game play type
//
public StartVote(){
	if(!task_exists(TASKID_VOTESTART)){
		voteDM = 0
		voteTDM = 0
		
		if(get_pcvar_num(cvar[CVAR_VOTEMODE]) == 0){
			upTime = get_pcvar_float(cvar[CVAR_WARMUP]) / 2.0 // start vote during half of warmup time
			
			if(upTime < get_pcvar_float(cvar[CVAR_VOTETIME])){ // upTime to low
				log_amx("WARNING! Can't start vote because of low warmup time!")
				return
			}
		}
		
		set_task(1.0,"StartVote",TASKID_VOTESTART,.flags = "b") // Set count down task
		
		// and register
		register_menucmd(
			register_menuid("GGVoteMenu"),
			MENU_KEY_6|MENU_KEY_7,
			"VoteMenu_Handler"
		)
	}
	
	upTime --
	
	if(!upTime){
		remove_task(TASKID_VOTESTART)
		EndVote()
	}
	
	ShowMenu_ForAll()
}

//
// End vote
//
public EndVote(){
	new players[32],pnum
	get_players(players,pnum,"ch")
	
	new forDm = countVote(0)
	new forTdm = countVote(1)
	
	new Float:voters = float(forDm + forTdm) / float(pnum)* 100.0
	
	if(voters >= get_pcvar_float(cvar[CVAR_VOTERATIO])){
		client_print(0,print_chat,"%L",LANG_PLAYER,"VOTING_SUCCESS")
		
		if(forTdm > forDm){
			client_print(0,print_chat,"%L",LANG_PLAYER,"TDMSELECT")
			set_pcvar_num(cvar[CVAR_TEAMPLAY],1) // enable team play
		}else{
			client_print(0,print_chat,"%L",LANG_PLAYER,"DMSELECT")
			set_pcvar_num(cvar[CVAR_TEAMPLAY],0) // disable team play
		}
	}else{
		client_print(0,print_chat,"%L",LANG_PLAYER,"VOTING_FAILED")
	}
}

public VoteMenu_Handler(id,key){
	if(checkPlayerVote(id)){ // player already voted
		ShowMenu(id)
		
		return
	}
	
	switch(key){
		case 5: bit_owner_add(voteDM,id) // count as dm
		case 6: bit_owner_add(voteTDM,id) // count as tdm
	}
	
	// Display who votes for what option
	if(get_pcvar_num(cvar[CVAR_VOTEANSWERS])){
		new voterName[32]
		get_user_name(id,voterName,charsmax(voterName))
		
		client_print(0,print_chat,"%L %L",
			LANG_PLAYER,"VOTED_FOR",
			voterName,
			LANG_PLAYER,key == 5 ? "FORDM" : "FORTDM"
		)
	}
	
	// Update menu for all players
	ShowMenu_ForAll()
}

//
// Show vote menu for player
//
ShowMenu(id){
	if(!task_exists(TASKID_VOTESTART)){
		show_menu(0,0,"^n",1)
		return
	}
	
	new menuText[256],len
	
	len += formatex(menuText[len],charsmax(menuText) - len,"^n^n\y%L\w^n^n",id,"MENU_TITLE")
	
	if(!checkPlayerVote(id)){ // player not voted yet
		len += formatex(menuText[len],charsmax(menuText) - len,"\r6. \w%L^n",id,"MENU_DM")
		len += formatex(menuText[len],charsmax(menuText) - len,"\r7. \w%L",id,"MENU_TDM")
	}else{ // player already voted, mark his choise and show vote results
		len += formatex(menuText[len],charsmax(menuText) - len,"\d6. \w%L%s \y[%.0f%%]^n",
			id,"MENU_DM",
			bit_owner(voteDM,id) ? " \r*" : "", // vote mark
			getVotePercent(0)
		)
		
		len += formatex(menuText[len],charsmax(menuText) - len,"\d7. \w%L%s \y[%.0f%%]",
			id,"MENU_TDM",
			bit_owner(voteTDM,id) ? " \r*" : "", // vote mark
			getVotePercent(1)
		)
	}
	
	new timeRem[30]
	get_time_length(id,floatround(upTime),timeunit_seconds,timeRem,charsmax(timeRem))
	
	len += formatex(menuText[len],charsmax(menuText) - len,"^n^n\y%L: \w%s.",id,"TIMELEFT",timeRem)
	
	if(!checkPlayerVote(id))
		show_menu(id,MENU_KEY_6|MENU_KEY_7,menuText,.title = "GGVoteMenu")
	else
		show_menu(id,MENU_KEY_0,menuText,.title = "GGVoteMenu")
}

//
// Show vote menu for all players
//
ShowMenu_ForAll(){
	new players[32],pnum
	get_players(players,pnum,"ch")
	
	for(new i ; i < pnum ; i++)
		ShowMenu(players[i])
}

//
// Check player vote
//
checkPlayerVote(id)
	return bit_owner(voteDM,id) | bit_owner(voteTDM,id)
	
//
// Count vote
//
countVote(wat){
	new r

	for(new i = 1; i <= 32 ; i++){
		if(wat){
			if(bit_owner(voteTDM,i))
				r++
		}else{
			if(bit_owner(voteDM,i))
				r ++
		}
	}
		
	return r
}

//
// Get vote percent
//
Float:getVotePercent(what){
	new dm = countVote(0)
	new tdm = countVote(1)

	new Float:dmp = (float(dm) / float(dm + tdm)) * 100.0
	new Float:tdmp = (float(tdm) / float(dm + tdm)) * 100.0
	
	return what ? tdmp : dmp
}
