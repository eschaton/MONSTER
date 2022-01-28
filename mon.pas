[inherit ('Global','Guts','Database','Cli','Privusers','Parser',
          'Alloc','Custom','Queue','Interpreter')]
program monster(input,output);

{+
COMPONENT: Main program
 
PROGRAM DESCRIPTION:
 
	This is Monster, a multiuser adventure game system
	where the players create the universe.
 
AUTHORS:
 
    Rich Skrenta 
    Juha Laiho
    Antti Leino
    Kari Hurtta

 
CREATION DATE: (unknown) ?.??.1988
 
DESIGN ISSUES:
 
    
 
VERSION:
 
    Monster Helsinki 1.04
    
 
MODIFICATION HISTORY:
 
     Date     |   Name  | Description
--------------+---------+-------------------------------------------------------
    ??.3.1989 |  Hurtta |  Starting of Helsinki version of Monster
    12.2.1991 |         |  This comment header                    
    12.2.1991 |         |  Some help text replace with call command_help
    25.5.1992 |		|  fix_owner: owner check for /FIX -subsystem
    13.6.1992 |  Hurtta |  Distributed as version 1.04
    25.6.1992 |         |  nc_createroom: part of finction createroom to
              |         |  module ALLOC, REBUILD moved to MONSTER_REBUILD.PAS
              |         |  system_view, fix_view_global_flags moved to DATABASE.PAS
              |         |  FIX moved to MONSTER_REBUILD.PAS
-}


{
	This is Monster, a multiuser adventure game system
	where the players create the universe.

	Written by Rich Skrenta at Northwestern University, 1988.

		skrenta@nuacc.acns.nwu.edu
		skrenta@nuacc.bitnet

}
{

	This version modified by
		jlaiho@finuha.bitnet  (jlaiho@cc.Helsinki.FI)
		leino@finuha.bitnet   (leino@cc.Helsinki.FI)
		hurtta@finuha.bitnet  (hurtta@cc.Helsinki.FI)
	Thanks for ready-to-run modifications to
		dahlp@finabo.bitnet
		leino@finuha.bitnet   (leino@cc.Helsinki.FI)
		hurtta@finuha.bitnet  (hurtta@cc.Helsinki.FI)
	Thanks for useful ideas to those who play Monster at finuh.

}

{ all functions in FINUHTIME.PAS moved to PRIVUSERS.PAS }

{ all consts is moved to global.pas }

{ all types is moved to global.pas }

var

        { variables in privusers module are available with PRIVUSERS.PEN }

	oldcmd:	string := '';		{ string for '.' command to do last command }

	in_main_prompt : boolean := false;
		    { if in main promp player can throw out monster immediatly }


	{ GUTS.PAS exports old_promp,line and grab_next }

        { system_id, disowned_id and public_id moved to module CUSTOM }


	{ inmem moved to DATABASE.PAS }

  {	starting : boolean := FALSE;	}  { Not yet entered the universe --
 					  hopefully a temporary hack
                                          by leino@finuh }

	brief: boolean := FALSE;	{ brief/verbose descriptions }

	rndcycle: integer;		{ integer for rnd_event }

	{ debug moved to GLOBAL.PAS }

	ping_answered: boolean;		  { flag for ping answers }
	{ hiding moved to module CUSTOM }
	midnight_notyet: boolean := TRUE; { hasn't been midnight yet }
	first_puttoken: boolean := TRUE;  { flag for first place into world }
	{ logged_act moved to module CUSTOM }
    

	cmds: array[1..maxcmds] of shortstring := (

		'name',		{ setnam = 1	}
		'help',		{ help = 2	}
		'?',		{ quest = 3	}
		'quit',		{ quit = 4	}
		'look',		{ look = 5	}
		'go',		{ go = 6	}
		'form',		{ form = 7	}
		'link',		{ link = 8	}
		'unlink',	{ unlink = 9	}
		'whisper',	{ c_whisper = 10}
		'poof',		{ poof = 11	}
		'describe',	{ desc = 12	}
		'dcl',          { c_dcl = 13   }
		'debug',	{ dbg = 14	}
		'say',		{ say = 15	}
		'scan',		{ c_scan = 16	}
		'rooms',	{ c_rooms = 17	}
		'system',	{ c_system = 18	}
		'disown',	{ c_disown = 19	}
		'claim',	{ c_claim = 20	}
		'make',		{ c_create = 21	}
		'public',	{ c_public = 22	}
		'accept',	{ c_accept = 23	}
		'refuse',	{ c_refuse = 24	}
		'zap',		{ c_zap = 25	}
		'hide',		{ c_hide = 26	}
		'l',		{ c_l = 27	}
		'north',	{ c_north = 28	}
		'south',	{ c_south = 29	}
		'east',		{ c_east = 30	}
		'west',		{ c_west = 31	}
		'up',		{ c_up = 32	}
		'down',		{ c_down = 33	}
		'n',		{ c_n = 34	}
		's',		{ c_s = 35	}
		'e',		{ c_e = 36	}
		'w',		{ c_w = 37	}
		'u',		{ c_u = 38	}
		'd',		{ c_d = 39	}
		'customize',	{ c_custom = 40	}
		'who',		{ c_who = 41	}
		'players',	{ c_players = 42}
		'search',	{ c_search = 43	}
		'reveal',	{ c_unhide = 44	}
		'punch',	{ c_punch = 45	}
		'ping',		{ c_ping = 46	}
		'health',	{ c_health = 47	}
		'get',		{ c_get = 48	}
		'drop',		{ c_drop = 49	}
		'inventory',	{ c_inv = 50	}
		'i',		{ c_i = 51	}
		'self',		{ c_self = 52	}
		'whois',	{ c_whois = 53	}
		'duplicate',	{ c_duplicate = 54 }
		'score',	{ c_score = 55	}
		'version',	{ c_version = 56}
		'objects',	{ c_objects = 57}
		'use',		{ c_use = 58	}
		'wield',	{ c_wield = 59	}
		'brief',	{ c_brief = 60	}
		'wear',		{ c_wear = 61	}
		'relink',	{ c_relink = 62	}
		'unmake',	{ c_unmake = 63	}
		'destroy',	{ c_destroy = 64}
		'show',		{ c_show = 65	}
		'set',		{ c_set = 66	}
		'bear',		{ c_monster = 67    }
		'erase',        { c_erase = 68	    }
		'atmosphere',	{ c_atmospehere = 69 }
		'reset',	{ c_reset = 70 }
		'summon',       { c_summon = 71 }
		'spells',	{ c_spells = 72 }
		'monsters',	{ c_monsters = 73 }
		'list',		{ A_list = 74 }
		'create',	{ A_create = 75 }
		'delete',	{ A_delete = 76 }
		'',		{ 77 }
		'',		{ 78 }
		'',		{ 79 }
		'',		{ 80 }
		'',		{ 81 }
		'',		{ 82 }
		'',		{ 83 }
		'',		{ 84 }
		'',		{ 85 }
		'',		{ 86 }
		'',		{ 87 }
		'',		{ 88 }
		'',		{ 89 }
		'',		{ 90 }
		'',		{ 91 }
		'',		{ 92 }
		'',		{ 93 }
		'',		{ 94 }
		'',		{ 95 }
		'',		{ 96 }
		'',		{ 97 }
		'',		{ 98 }
		''		{ 99 }

	);

	{ show moved to parser.pas }

	numcmds: integer;	{ number of got main level commands there are }

	{ numshow moved to parser.pas }

	{ setkey moved to parser.pas }

	{ numset moved to parser.pas }

	{ direct moved to parser.pas }

	spells: array[1..maxspells] of string;	  { names of spells }
	numspells: integer;		{ number of spells there actually are }

	done: [global] boolean;		{ flag for QUIT }
	{ userid moved to module CUSTOM }
	real_userid: veryshortstring;	{ real VMS userid }

	{ location moved to DATABASE.PAS }

	hold_kind: array[1..maxhold] of integer; { kinds of the objects i'm
						   holding }

	{ myslot moved to module CUSTOM }
	myevent: integer;	{ which point in event buffer we are at }
	{ myname moved to module CUSTOM }

	found_exit: array[1..maxexit] of boolean;
				{ has exit i been found by the player? }

	{ mylog moved to DATABASE.PAS }

	mywear: integer;	{ what I'm wearing }
	{ mydisguise moved to module CUSTOM }
	mywield: integer;	{ weapon I'm wielding }
	myhealth: integer;	{ how well I'm feeling }
	myself: integer;	{ self description block }
	{ myexperience moved to module CUSTOM }
	healthcycle: integer;	{ used in rnd_event to control how quickly a
				  player heals }

	{ privs moved to module PARSER }
	{ module GLOBAL exports leveltable }

{ procedures in module CLI is available now with CLI.PEN }

{ in module KEYS }

[external]
procedure encrypt(key: shortstring; n : integer := 0);
external;

{ Routines in module QUEUE are declared in environment file QUEUE.PEN }
		
{ Routines in module GUTS are declared in environment file GUTS.PEN }

{ Routines in module INTERPRETER are declared in environment file 
  INTERPRETER.PEN }


{ ----- }
procedure xpoof(loc: integer); forward;

procedure newlevel(oldlev,newlev: integer); forward;

procedure prevlevel(oldlev,newlev: integer); forward;

procedure do_exit(exit_slot: integer); forward;

{ function put_token declared as external in module CUSTOM }

procedure take_token(aslot, roomno: integer); forward;

procedure maybe_drop; forward;                   

{ procedure do_program moved to module CUSTOM }

function drop_everything(pslot: integer := 0): boolean;
forward;

{ procedures do_y_altmsg, do_group1, do_group2 moved to module CUSTOM }
        
procedure meta_run (label_name,variable: shortstring;
                    value: mega_string); forward;

procedure meta_run_2 (label_name,variable: shortstring;
                    value: mega_string); forward;

{ procedure custom_hook moved to module CUSTOM }

procedure x_unwield; forward;
procedure x_unwear; forward;

procedure leave_universe; forward;

{ function trim_filename moved to module CUSTOM }

function play_allow: boolean; { check when database is open }
begin
    play_allow := manager_priv or (userid = MM_userid)
		    or not work_time;
end;

{ function sysdate moved to module CUSTOM }
          
{ procedure gethere moved to module CUSTOM }

{ alloc_X and delete_X routines moved to module CUSTOM }

{ lowcase moved to parser.pas }

{ lookup_spell reimplemented in module PARSER }

{ alloc_general and delete_general moved to DATABASE.PAS }

{ returns true if object N is in this room. if nohidden is true, not found
  hidden objects (hurtta@finuh) }

function obj_here(n: integer; nohidden: boolean := false): boolean;
var
	i: integer;
	found: boolean;

begin
    i := 1;
    found := false;
    while (i <= maxobjs) and (not found) do begin
	if here.objs[i] = n then begin
	    if not nohidden then found := true
	    else if here.objhide[i] = 0 then found := true
	    else i := i + 1;
	end else i := i + 1;
    end;
    obj_here := found;
end;

[global]    { for PARSER module }
function player_here(id: integer; var slot: integer): boolean;
    { suppose that gethere and getpers have made }
var i: integer;
    name: shortstring;
begin
    slot := 0;
    name := lowcase(pers.idents[id]);
    for i := 1 to maxpeople do
	if here.people[i].kind > 0 then
		if lowcase(here.people[i].name) = name then slot := i;
    player_here := slot > 0;
end; { player_here }


{ returns true if object N is being held by the player (id slot)}

function obj_hold(n: integer; slot: integer := 0): boolean;
var
	i: integer;
	found: boolean;

begin
	if slot = 0 then slot := myslot;
	
	if n = 0 then
		obj_hold := false
	else begin
		i := 1;
		found := false;
		while (i <= maxhold) and (not found) do begin
			if here.people[slot].holding[i] = n then
				found := true
			else
				i := i + 1;
		end;
		obj_hold := found;
	end;
end;



{ return the slot of an object that is HERE }
function find_obj(objnum: integer): integer;
var
	i: integer;

begin
	i := 1;
	find_obj := 0;
	while i <= maxobjs do begin
		if here.objs[i] = objnum then
			find_obj := i;
		i := i + 1;
	end;
end;




{ similar to lookup_obj, but only returns true if the object is in
  this room or is being held by the player }
{ and s may be in the middle of the objact name -- Leino@finuh }

function parse_obj (var pnum: integer;
			s: string;
			override: boolean := false): boolean;
var
	i,poss,maybe,num: integer;
	tmp: string;
	found: boolean;

begin
	getobjnam;
	freeobjnam;
	getindex(I_OBJECT);
	freeindex;

	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	found := false;
	for i := 1 to indx.top do begin
		if not(indx.free[i]) then begin
			if s = objnam.idents[i] then
				num := i
			else if ((index(objnam.idents[i],s) = 1) or
				(index(objnam.idents[i],' '+s) > 0)) and
				(obj_here(i) or obj_hold(i)) then begin
				maybe := maybe + 1;
				poss := i;
			end;
		end;
	end;
	if num <> 0 then begin
		found := obj_here(num) or obj_hold(num);
		if found then
			pnum := num;
		parse_obj := found;
	end else if maybe = 1 then begin
		found := obj_here(poss) or obj_hold(poss);
		if found then
			pnum := poss;
		parse_obj := found;
	end else if maybe > 1 then begin
		if lookup_obj (poss, s) then begin
			found := obj_here(poss) or obj_hold(poss);
			if found then
				pnum := poss;
			parse_obj := found;
		end else parse_obj := false;
	end else begin
		parse_obj := false;
	end;
end;

{ functions parse_pers, is_owner, room_owner, can_alter and can_make moved to 
  module CUSTOM }

{ procedures nice_print, print_short print_line, print_desc and make_line
   moved to module CUSTOM }

{
Return n as the direction number if s is a valid alias for an exit
}
function lookup_alias(var n: integer; s: string): boolean;
var
	i,poss,maybe,num: integer;

begin
	gethere;
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxexit do begin
		if s = here.exits[i].alias then
			num := i
{		else if index(here.exits[i].alias,s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;				}
	end;
	if num <> 0 then begin
		n := num;
		lookup_alias := true;
{	end else if maybe = 1 then begin
		n := poss;
		lookup_alias := true;
	end else if maybe > 1 then begin
		lookup_alias := false;		}
	end else begin
		lookup_alias := false;
	end;
end;

{ procedure exit_default moved to module CUSTOM }

{
Prints out the exits here for DO_LOOK()
}
procedure show_exits;
var
	i: integer;
	one: boolean;
	cansee: boolean;

begin
	one := false;
	for i := 1 to maxexit do begin
		if (here.exits[i].toloc <> 0) or { there is an exit }
		   (here.exits[i].kind = 5) then begin { there could be an exit }
			if (here.exits[i].hidden = 0) or
			   (found_exit[i]) 
                        then cansee := true
			else cansee := false;

			if here.exits[i].kind = 6 then begin
				{ door kind only visible with object }
				if obj_hold( here.exits[i].objreq ) then
					cansee := true
				else cansee := false;
			end;

			if cansee then begin
				if here.exits[i].exitdesc = DEFAULT_LINE then begin
					exit_default(i,here.exits[i].kind);
					{ give it direction and type }
					one := true;
				end else if here.exits[i].exitdesc > 0 then begin
					print_line(here.exits[i].exitdesc);
					one := true;
				end;
			end;
		end;
	end;
	if one then writeln;
end;

procedure setevent;
begin
	getevent;
	freeevent;
	myevent := event.point;
end;

{ functions isnum and number moved to module CUSTOM }

{ log_event moved to DATABASE.PAS }

{ function log_name moved to module CUSTOM }

function desc_action(theaction,thetarget: integer): string;
var s: string;
begin
	case theaction of	{ use command mnemonics }
		look:      s:= ' looking around the room.';
		form:      s:= ' creating a new room.';
		desc:      s:= ' editing the description to this room.';
		e_detail:  s := ' adding details to the room.';
		c_custom:  s := ' customizing an exit here.';
		e_custroom:s := ' customizing this room.';
		e_program: s := ' customizing an object.';
		c_self:	   s := ' editing a self-description.';
		e_usecrystal: s := ' hunched over a crystal orb, immersed in its glow.';
		link:	   s := ' creating an exit here.';
		c_system:  s := ' in system maintenance mode.';
                c_dcl:     s := ' executing dcl.';
		e_custommonster: s := ' customizing a monster.';
		e_customspell: s := ' customizing a spell.';

		otherwise s := ' here.'
	end;
	desc_action := s;
end;

[global]
function protected(n: integer := 0): boolean;
var tmp: objectrec;			{ is this necessary ? }
begin
	protected := false;
	if n = 0 then n := myslot;
	tmp := obj;
	if here.people[n].wielding > 0 then begin
		getobj(here.people[n].wielding);
		freeobj;
		if obj.kind = O_MAGIC_RING then protected := true;
	end;
	if here.people[n].act in [e_detail,c_custom,
				  e_custroom,e_program,
				  c_self,c_system,c_dcl,
				  e_custommonster,
				  e_customspell] then
		protected := true;

	obj := tmp;
end;

{ ------- Stolen from MONSTER Version 3.0 ---------------------------------- }

procedure do_s_announce (s:string);
var
   lcv : integer;
begin
    if (s<>'') and (s <> '?') then
	for lcv :=1 to numevnts do
          log_event(0,E_ANNOUNCE,0,0,s,lcv)
    else writeln('Usage: w <message>');
end; {do_announce}

procedure do_s_shutdown (s:string);
var
   lcv : integer;
begin
      if (s<>'') and (s <> '?') then
	for lcv :=1 to numevnts do
          log_event(0,E_SHUTDOWN,0,0,s,lcv)
      else writeln('Usage: d <message>')
end; {do_shutdown}


{ --------------------------------------------------------------------------- }


{
user procedure to designate an exit for acceptance of links
}
procedure do_accept(s: string);
label exit_label;
var
	dir,owner: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	if s = '' then grab_line('Direction? ',s,eof_handler := leave);

	if lookup_dir(dir,s,true) then begin
		if can_make(dir) then begin
			getroom;
			here.exits[dir].kind := 5;
			putroom;

			if exact_user(owner,here.owner) then
			    add_counter(N_ACCEPT,owner);

			log_event(myslot,E_ACCEPT,0,0);
			writeln('Someone will be able to make an exit ',direct[dir],'.');
		end;
	end else
		writeln('To allow others to make an exit, type ACCEPT <direction of exit>.');
    exit_label:
end;

{
User procedure to refuse an exit for links
Note: may be unlink
}
procedure do_refuse(s: string);
label exit_label;
var
	dir,owner: integer;
	ok: boolean;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	if s = '' then grab_line('Direction? ',s,eof_handler := leave);

	if not(is_owner) then
		{ is_owner prints error message itself }
	else if lookup_dir(dir,s,true) then begin
		getroom;
		with here.exits[dir] do begin
			if (toloc = 0) and (kind = 5) then begin
				kind := 0;
				ok := true;
			
			    if exact_user(owner,here.owner) then
				sub_counter(N_ACCEPT,owner);

			end else
				ok := false;
		end;
		putroom;
		if ok then begin
			log_event(myslot,E_REFUSE,0,0);
			writeln('Exits ',direct[dir],' will be refused.');
		end else
			writeln('Exits were not being accepted there.');
	end else
		writeln('To undo an Accept, type REFUSE <direction>.');
    exit_label:
end;

{ function systime moved to module CUSTOM }

{ substitute a parameter string for the # sign in the source string }
function subs_parm(s,parm: string): mega_string;
var
	right,left: mega_string;
	i: integer;		{ i is point to break at }
begin
	i := index(s,'#');
	if (i > 0) and ((length(s) + length(parm)) 
	    <= terminal_line_len) then begin
		if i >= length(s) then begin
			right := '';
			left := s;
		end else if i < 1 then begin
			right := s;
			left := '';
		end else begin
			right := substr(s,i+1,length(s)-i);
			left := substr(s,1,i);
		end;
		if length(left) <= 1 then
			left := ''
		else
			left := substr(left,1,length(left)-1);

		subs_parm := left + parm + right;
	end else begin
		subs_parm := s;
	end;
end;

{ function level moved to database module }

procedure time_health;
var tmp: objectrec;
    tmp2: intrec;
    mylevel,good,rel: integer;
begin
	mylevel:=level(myexperience);
	good := leveltable[mylevel].health * 7 div 10;
	if healthcycle > 0 then begin		{ how quickly they heal }
		if myhealth < good then begin	{ heal a little bit }
			myhealth := myhealth + (good div 10) +1;

			if mywield > 0 then begin
				tmp := obj;
				getobj(mywield);
				freeobj;
				if (obj.kind = O_HEALTH_RING) and
				   (myhealth < leveltable[mylevel].health) then
					myhealth := myhealth + good div 5;
				obj := tmp;
			end;

			getroom;
			here.people[myslot].health := myhealth;
			putroom;

			tmp2 := anint;
			getint(N_HEALTH);	{ hurtta@finuh }
			anint.int[mylog] := myhealth;
			putint;
			anint := tmp2;

			{show new health rating }
			rel := myhealth * 10 div leveltable[mylevel].health;
			if rel > 9 then rel := 9;
                if myhealth = 0 then writeln('You are still dead.')
		else case rel of
			9: writeln('You are now in exceptional health.');
			8: writeln('You feel much stronger.  You are in better than average condition.');
			7: writeln('You are now in perfect health.');
			6: writeln('You only feel a little bit dazed now.');
			5: begin
				writeln('You only have some minor cuts and abrasions now.  Most of your serious wounds');
				writeln('have healed.');
			   end;
			4: writeln('You are only suffering from some minor wounds now.');
			3: writeln('Your most serious wounds have healed, but you are still in bad shape.');
			2: writeln('You have healed somewhat, but are still very badly wounded.');
			0,1: writeln('You are in critical condition, but there may be hope.');
			otherwise writeln('You don''t seem to be in any condition at all.');
		end;

		reprint_grab;

		end;
		healthcycle := 0;
	end else
		healthcycle := healthcycle + 1;
end;


procedure time_noises;
var
	n: integer;

begin
	if rnd100 <= 2 then begin
		n := rnd100;
		if n in [0..40] then
			log_event(0,E_NOISES,rnd100,0)
		else if n in [41..60] then
			log_event(0,E_ALTNOISE,rnd100,0);
	end;
end;

procedure time_trapdoor(silent: boolean);
var fall: boolean;
begin                   
	if (rnd100-1) < here.trapchance then begin
			{ trapdoor fires! }
		if here.trapto > 0 then begin
				{ logged action should cover (protected) }
			if (protected) or (logged_act) then
				fall := false
			else if here.magicobj = 0 then
				fall := true
			else if obj_hold(here.magicobj) then
				fall := false
			else
				fall := true;
		end else
			fall := false;

	  	if fall then begin
			do_exit(here.trapto);
			if not(silent) then
			    reprint_grab;
		end;
	end;
end;

procedure time_teleport;
var	tmp: objectrec;
	target,i: integer;
begin
	tmp := obj;
	if mywield > 0 then begin
		getobj(mywield);
		freeobj;
		if (obj.kind = O_TELEPORT_RING) and not protected then begin
			target := location;
			getindex(I_ROOM);
			freeindex;
			for i := 1 to indx.top do if not indx.free[i] then
				if rnd100 < 30 then target := i;
			if location <> target then begin
				if obj.d1 > 0 then print_desc(obj.d1);
				xpoof(target);
				reprint_grab;
			end;
		end;
	end;
	obj := tmp;
end;

procedure time_midnight;
begin
  if systime = '12:00am' then log_event(0,E_MIDNIGHT,rnd100,0);
end;

{ cause random events to occurr (ha ha ha) }

procedure rnd_event(silent: boolean := false);
var n: integer;
begin
	if rndcycle >= RANDOM_EVENT_CYCLE then begin { inside here 6 times/min }
		time_noises;
		time_health;
		time_trapdoor(silent);         
		time_midnight;
		time_teleport;

		rndcycle := 0;
	end else
		rndcycle := rndcycle + 1;
end;

{ handle levels }

function droplevel(score: integer): integer;
var cur: integer;
begin
   cur := level(score);
   if (cur > 1) and (not leveltable[cur].hidden) then cur := cur -1;
   droplevel := leveltable[cur].exp;
   if score >= protect_exp then droplevel := score;
      { works even though we show Manager levels }
end;

{ function lookup_level moved to module CUSTOM }

procedure do_die (killer : integer := 0);
var
	some: boolean;
	tmp: intrec;
	oldlevel,newlevel: integer;

begin
        if killer > 0 then log_event (myslot,E_ADDEXPERIENCE,killer,
                                      (myexperience div 6) + 1);

        oldlevel := level(myexperience);
	writeln;
	writeln('        *** You are dead ***');
	writeln;
	some := drop_everything;
	{ changes by hurtta@finuh }

        tmp := anint;
        myexperience := droplevel(myexperience);
	newlevel := level(myexperience);
        getint(N_EXPERIENCE);
        anint.int[mylog] := myexperience;
        putint; 
        if newlevel < oldlevel then prevlevel(oldlevel,newlevel);
	anint := tmp;

	take_token(myslot,location);
	log_event(0,E_DIED,0,0,log_name);
	if put_token(2,myslot) then begin
		location := 2;
		inmem := false;
		setevent;
{ log entry to death loc }
{ perhaps turn off refs to other people }
	end else begin
		writeln('The Monster universe regrets to inform you that you cannot be ressurected at');
		writeln('the moment.');
		finish_interpreter;
		halt;
	end;
end;

procedure poor_health(p: integer; killer : integer := 0);
var
	some: boolean;
	tmp: intrec;
	rel,mylevel: integer;

begin
	mylevel := level(myexperience);
	if myhealth > p then begin
		myhealth := myhealth - 1;
		getroom;
		here.people[myslot].health := myhealth;
		putroom;

		tmp := anint;
		getint(N_HEALTH);
		anint.int[mylog] := myhealth;
		putint;
		anint := tmp;

		log_event(myslot,E_WEAKER,myhealth,0);

		{ show new health rating }
		rel := myhealth * 10 div leveltable[mylevel].health;
		if rel > 9 then rel := 9;
		write('You ');
                if myhealth = 0 then writeln('are dead.')
                else if myhealth = 1 then writeln('will be die.')
		else case rel of
			9: writeln('are still in exceptional health.');
			8: writeln('feel weaker, but are in better than average condition.');
			7: writeln('are somewhat weaker, but are in perfect health.');
			6: writeln('feel a little bit dazed.');
			5: writeln('have some minor cuts and abrasions.');
			4: writeln('have some wounds, but are still fairly strong.');
			3: writeln('are suffering from some serious wounds.');
			2: writeln('are very badly wounded.');
			0,1: writeln('have many serious wounds, and are near death.');
			otherwise writeln('don''t seem to be in any condition at all.');
		end;
	end else begin { they died }
		do_die (killer);
	end;
end;

{ count objects here }

function find_numobjs: integer;
var
	sum,i: integer;
begin
	sum := 0;
	for i := 1 to maxobjs do
		if here.objs[i] <> 0 then
			sum := sum + 1;
	find_numobjs := sum;
end;

{ optional parameter is slot of player's objects to count }

function find_numhold(player: integer := 0): integer;
var sum,i: integer;
begin
	if player = 0 then player := myslot;

	sum := 0;
	for i := 1 to maxhold do
		if here.people[player].holding[i] <> 0 then
			sum := sum + 1;
	find_numhold := sum;
end;

procedure take_hit(p: integer; killer : integer := 0 );
var                           
	i: integer;
	objtemp: objectrec;
	pro: integer;

begin        
	if protected then p := 0               
	else if mywear > 0 then begin
		objtemp := obj; { is this necessary ? }

		getobj (mywear); 
		freeobj;         
                     
		pro := trunc(obj.ap*random);	{ He he He }
		p := p - pro;
		if p < 0 then p := 0;

		obj := objtemp;
	end;

	if p > 0 then begin
		if rnd100 < (55 + (p-1) * 30) then { chance that they're hit }
			poor_health(p, killer);

		if find_numobjs < maxobjs + 1 then begin
			{ maybe they drop something if they're hit }
			for i := 1 to p do
				maybe_drop;
		end;
	end;
end;

function punch_force(sock: integer): integer;
var
	p: integer;

begin
	if sock in [2,3,6,7,8,11,12] then	{ no punch or a graze }
		p := 0
	else if sock in [4,9,10] then	{ hard punches }
		p := 2
	else	{ 1,5,13,14,15 }
		p := 1;		{ all others are medium punches }
	punch_force := p;
end;

procedure put_punch(sock: integer;s: string);
begin
	case sock of
		1: writeln('You deliver a quick jab to ',s,'''s jaw.');
		2: writeln('You swing at ',s,' and miss.');
		3: writeln('A quick punch, but it only grazes ',s,'.');
		4: writeln(s,' doubles over after your jab to the stomach.');
		5: writeln('Your punch lands square on ',s,'''s face!');
		6: writeln('You swing wild and miss.');
		7: writeln('A good swing, but it misses ',s,' by a mile!');
		8: writeln('Your punch is blocked by ',s,'.');
		9: writeln('Your roundhouse blow sends ',s,' reeling.');
		10:writeln('You land a solid uppercut on ',s,'''s chin.');
		11:writeln(s,' fends off your blow.');
		12:writeln(s,' ducks and avoids your punch.');
		13:writeln('You thump ',s,' in the ribs.');
		14:writeln('You catch ',s,'''s face on your elbow.');
		15:writeln('You knock the wind out of ',s,' with a punch to the chest.');
	end;
end;

procedure get_punch(sock: integer;s: string);
begin
	case sock of
		1: writeln(s,' delivers a quick jab to your jaw!');
		2: writeln(s,' swings at you but misses.');
		3: writeln(s,'''s fist grazes you.');
		4: writeln('You double over after ',s,' lands a mean jab to your stomach!');
		5: writeln('You see stars as ',s,' bashes you in the face.');
		6: writeln('You only feel the breeze as ',s,' swings wildly.');
		7: writeln(s,'''s swing misses you by a yard.');
		8: writeln('With lightning reflexes you block ',s,'''s punch.');
		9: writeln(s,'''s blow sends you reeling.');
		10:writeln('Your head snaps back from ',s,'''s uppercut!');
		11:writeln('You parry ',s,'''s attack.');
		12:writeln('You duck in time to avoid ',s,'''s punch.');
		13:writeln(s,' thumps you hard in the ribs.');
		14:writeln('Your vision blurs as ',s,' elbows you in the head.');
		15:writeln(s,' knocks the wind out of you with a punch to your chest.');
	end;
end;

procedure view_punch(a,b: string;p: integer);
begin
	case p of
		1: writeln(a,' jabs ',b,' in the jaw.');
		2: writeln(a,' throws a wild punch at the air.');
		3: writeln(a,'''s fist barely grazes ',b,'.');
		4: writeln(b,' doubles over in pain with ',a,'''s punch');
		5: writeln(a,' bashes ',b,' in the face.');
		6: writeln(a,' takes a wild swing at ',b,' and misses.');
		7: writeln(a,' swings at ',b,' and misses by a yard.');
		8: writeln(b,'''s punch is blocked by ',a,'''s quick reflexes.');
		9: writeln(b,' is sent reeling from a punch by ',a,'.');
		10:writeln(a,' lands an uppercut on ',b,'''s head.');
		11:writeln(b,' parrys ',a,'''s attack.');
		12:writeln(b,' ducks to avoid ',a,'''s punch.');
		13:writeln(a,' thumps ',b,' hard in the ribs.');
		14:writeln(a,'''s elbow connects with ',b,'''s head.');
		15:writeln(a,' knocks the wind out of ',b,'.');
	end;
end;

procedure desc_health(n: integer;header:shortstring := '');
var tmp: objectrec;
    hide : boolean;
    wear,lev,rel: integer;
begin
	lev := level(here.people[n].experience);

	if header = '' then begin
		hide := false;
		wear := here.people[n].wearing;
		if wear > 0 then begin
			tmp := obj;

			getobj(wear);
			freeobj;
			if obj.kind = O_DISGUISE then hide := true;

			obj := tmp;
		end;
		if hide then write ('Someone ')
		else write(here.people[n].name,' ')
	end else
		write(header);

	rel := here.people[n].health * 10 div leveltable[lev].health;
	if rel > 9 then rel := 9;
        if here.people[n].health = 0 then writeln('is dead.')
	else case rel of
		9: writeln('is in exceptional health, and looks very strong.');
		8: writeln('is in better than average condition.');
		7: writeln('is in perfect health.');
		6: writeln('looks a little dazed.');
		5: writeln('has some minor cuts and abrasions.');
		4: writeln('has some minor wounds.');
		3: writeln('is suffering from some serious wounds.');
		2: writeln('is very badly wounded.');
		0,1: writeln('has many serious wounds, and is near death.');
		otherwise writeln('doesn''t seem to be in any condition at all.');
	end;
end;


function obj_part(objnum: integer;doread: boolean := TRUE): string;
var
	s: string;

begin
	if doread then begin
		getobj(objnum);
		freeobj;
	end;
	s := obj.oname;
	case obj.particle of
		0:;
		1: s := 'a ' + s;
		2: s := 'an ' + s;
		3: s := 'some ' + s;
		4: s := 'the ' + s;
	end;
	obj_part := s;
end;


procedure print_subs(n: integer;s: string);

begin
	if (n > 0) and (n <> DEFAULT_LINE) then begin
		getline(n);
		freeline;
		writeln(subs_parm(oneliner.theline,s));
	end else if n = DEFAULT_LINE then
		writeln('%<default line> in print_subs');
end;

{ print out a (up to) 10 line description block, substituting string s for
  up to one occurance of # per line }

procedure block_subs(n: integer;s: string);
var
	p,i: integer;
	len: integer;
begin
	if n < 0 then
		print_subs(abs(n),s)
	else if (n > 0) and (n <> DEFAULT_LINE) then begin
		getblock(n);
		freeblock;
		i := 1;
		len := 0;
		while i <= block.desclen do begin
			p := index(block.lines[i],'#');
			if (p > 0) then
			    if terminal_line_len < 80 then
				print_short(subs_parm(block.lines[i],s),
				    i = block.desclen,len)
			    else
				writeln(subs_parm(block.lines[i],s))
			else
			    if terminal_line_len < 80 then
				print_short(block.lines[i],
				    i = block.desclen,len)
			    else
				writeln(block.lines[i]);
			i := i + 1;
		end;
	end;
end;

{ list_privileges moved to PARSER.PAS }

{  function custom_privileges moved to module CUSTOM }

procedure newlevel { (oldlev,newlev: integer) };
var newpriv,oldpriv,sum: unsigned;
    tmp: intrec;
    i: integer;
begin
  tmp := anint;
  writeln ('You are now ',leveltable[newlev].name,'.');
  log_event(myslot,E_NEWLEVEL,,,leveltable[newlev].name);

  { health }
  myhealth := leveltable[newlev].health * 7 div 10;
  getint(N_HEALTH);	
  anint.int[mylog] := myhealth;
  putint;	
  getroom;
  here.people[myslot].health := myhealth;
  putroom;

  { privileges }
  getint(N_PRIVILEGES);
  freeint;
  oldpriv := anint.int[mylog];

  sum := 0;
  for i := oldlev+1 to newlev do sum := uor(sum,leveltable[i].priv);
  newpriv := uor(oldpriv,sum);
  getint(N_PRIVILEGES);
  anint.int[mylog] :=  int(newpriv);
  putint;

  if newpriv > oldpriv then begin
     write ('You have now follow privileges: ');
     list_privileges(newpriv);
     set_auth_priv(newpriv);
     set_cur_priv(newpriv);
  end;

  anint := tmp;
end; { newlevel }

procedure prevlevel { (oldlev,newlev: integer) };
var newpriv,oldpriv: unsigned;
    tmp: intrec;
    sum: unsigned;
    i: integer;
begin
  tmp := anint;
  writeln ('You are now only ',leveltable[newlev].name,'.');

  { health }
  myhealth := leveltable[newlev].health * 7 div 10;
  getint(N_HEALTH);	
  anint.int[mylog] := myhealth;
  putint;	
  getroom;
  here.people[myslot].health := myhealth;
  putroom;

  { privileges }
  getint(N_PRIVILEGES);
  freeint;
  oldpriv := anint.int[mylog];

  sum := 0;
  for i := newlev+1 to oldlev do sum := uor(sum,leveltable[i].priv);
  newpriv := uand(oldpriv,unot(sum));
  getint(N_PRIVILEGES);
  anint.int[mylog] := int(newpriv);
  putint;

  if newpriv < oldpriv then begin
     writeln('You have lost some privileges.');
     set_auth_priv(newpriv);
  end;
  anint := tmp;
end; { prevlevel }

procedure show_noises(n: integer);
begin
	if n < 33 then
		writeln('There are strange noises coming from behind you.')
	else if n < 66 then
		writeln('You hear strange rustling noises behind you.')
	else
		writeln('There are faint noises coming from behind you.');
end;


procedure show_altnoise(n: integer);
begin
	if n < 33 then
		writeln('A chill wind blows, ruffling your clothes and chilling your bones.')
	else if n < 66 then
		writeln('Muffled scuffling sounds can be heard behind you.')
	else
		writeln('A loud crash can be heard in the distance.');
end;

procedure show_midnight(n: integer;var printed: boolean);
begin
	if midnight_notyet then begin
		if n < 50 then begin
			writeln('A voice booms out of the air from all around you!');
			writeln('The voice says,  " It is now midnight. "');
		end else begin
			writeln('You hear a clock chiming in the distance.');
			writeln('It rings twelve times for midnight.');
		end;
		midnight_notyet := false;
	end else
		printed := false;
end;

procedure low_experience (amount: integer);
var prev,nlevel: integer;
    tmp: intrec;
Begin
  prev := level(myexperience);
  if myexperience >= protect_exp then { Protected }
  else if myexperience - amount > 0 then
     myexperience := myexperience - amount
  else myexperience := 0;
  tmp := anint;
  getint (N_EXPERIENCE);
  anint.int[mylog] := myexperience;
  putint;
  anint := tmp;

  getroom;		{ write experience also to here }
  here.people[myslot].experience := myexperience;
  putroom;
  inmem := true;	{ right 'here' IS in memory }

  nlevel := level(myexperience);
  if nlevel < prev then prevlevel(prev,nlevel);
End;     

Procedure add_experience (amount: integer); { hurtta@finuh }
var prev,nlevel: integer;
    tmp: intrec;
Begin
  prev := level(myexperience);
  if myexperience > maxexperience then { Monster Manager }
  else if myexperience + amount < maxexperience then
     myexperience := myexperience + amount
  else myexperience := maxexperience;
  tmp := anint;
  getint (N_EXPERIENCE);
  anint.int[mylog] := myexperience;
  putint;
  anint := tmp;

  getroom;		{ write experience also to here }
  here.people[myslot].experience := myexperience;
  putroom;
  inmem := true;	{ right 'here' IS in memory }

  nlevel := level(myexperience);
  if nlevel > prev then newlevel(prev,nlevel);
End;     

Procedure p_getattack (att: String; mess: Integer);
begin
  if (mess = 0) or (mess = DEFAULT_LINE) Then
    WriteLn (Att,' attacks you.')
  else block_subs(mess,att)
end;

Procedure p_viewattack (att: String; mess: Integer);
begin                         
  if (mess = 0) or (mess = DEFAULT_LINE) Then
    WriteLn (Att,' attacks someone.')
  else block_subs(mess,att)
end;

Procedure get_hideattack (attacker,victim,weapon:integer);
var objtemp: objectrec;
    ath: string; 
    power: Integer;
begin 
  objtemp := obj; { is this necessary ? }

  getobj (weapon); 
  freeobj;         
  
  if here.people[attacker].experience > (rnd100 * 3) then            
    power := obj.ap + 3    { <<<<< }
  else power := obj.ap +1; { Ha Ha }

  ath := here.people[attacker].name;  
  if victim = myslot then begin { oh }
	Writeln (ath,' jumps from shadows and ...');
	p_getattack (ath,obj.d1);
        take_hit (power,attacker);
  end else begin
	Writeln (ath,' jumps from shadow and ...');
	p_viewattack(ath,obj.d2);
  end;   
                 
{ relic, but not harmful }		ping_answered := true;
					healthcycle := 0;

  obj := objtemp;
end;

Procedure get_attack (attacker,victim,weapon:integer);
var objtemp: objectrec;
    ath: string; 
    power: Integer;
begin     
  objtemp := obj; { is this necessary ? }

  getobj (weapon); 
  freeobj;        
  
  if here.people[attacker].experience > (rnd100 * 10) then
    power := obj.ap + 1
  else power := obj.ap;
  ath := here.people[attacker].name;
  if victim = myslot then begin { oh }
	p_getattack (ath,obj.d1);
        take_hit (power ,attacker);
  end else begin
	p_viewattack(ath,obj.d2);
  end;   
                     
{ relic, but not harmful }		ping_answered := true;
					healthcycle := 0;

  obj := objtemp; 
end;

procedure see_trap (victim,message: integer; object: string);
var	name: string;                                      
begin
	name := here.people[victim].name;
	if message <> 0 then
		if message = DEFAULT_LINE then
			Writeln (name,' tries to get ',object,', but ',object,
				' bites ',name,' !')
		else block_subs (message,name);
end;
	
procedure handle_event(var printed: boolean);
var
	n,send,act,targ,p: integer;
	s: string;
	sendname: string;
	tmp: objectrec;
	tmp2: intrec;
	wear: integer;
begin
	{ WARNING ! myslot (and sometimes mylog ) is 0 during log_ping
	    and login password }

	printed := true;
	if debug then
		writeln('%handling event ',myevent);
	with event.evnt[myevent] do begin
		send := sender;
		act := action;
                targ := target;
		p := parm;
		s := msg;
	end;
	if ((send <> 0) and 
	    ( not ((act=E_DIED) or (act=E_ANNOUNCE)
		 or (act=E_GLOBAL_CHANGE)))) then begin
		tmp := obj;
		sendname := here.people[send].name;
		wear := here.people[send].wearing;
		if wear > 0 then begin
			getobj(wear);
			freeobj;
			if obj.kind = O_DISGUISE then sendname := 'Someone';
		end;
		obj := tmp;
	end else
		sendname := 'Unknown';


	case act of
		E_SUMMON: begin
			    if (send > 0) and (targ = myslot) then begin
				tmp2 := anint; { is this necessary ? }
				getint(N_SPELL);
				freeint;
				getspell_name;
				freespell_name;
				writeln(sendname,' summons ',
				    spell_name.idents[p],' to you.');
				printed := run_monster('',anint.int[p],
				    'summon', '','',
				    sysdate + ' ' + systime,
				    spell_name.idents[p],
				    here.people[send].name);
				anint := tmp2;
			    end else begin
				getspell_name;
				freespell_name;
				writeln(sendname,' summons ',
				    spell_name.idents[p],' to someone.');
				end;
			end;
                E_SUBMIT: begin
				get_submit(targ,s,p);
				printed := false;
			end;
		E_EXIT: begin
				if here.exits[targ].goin = DEFAULT_LINE then
					writeln(s,' has gone ',direct[targ],'.')
				else if (here.exits[targ].goin <> 0) and
				(here.exits[targ].goin <> DEFAULT_LINE) then begin
					block_subs(here.exits[targ].goin,s);
				end else
					printed := false;
			end;
		E_ENTER: begin
				if here.exits[targ].comeout = DEFAULT_LINE then
					writeln(s,' has come into the room from: ',direct[targ])
				else if (here.exits[targ].comeout <> 0) and
				(here.exits[targ].comeout <> DEFAULT_LINE) then begin
					block_subs(here.exits[targ].comeout,s);
				end else
					printed := false;
			end;
		E_BEGIN:writeln(s,' appears in a brilliant burst of multicolored light.');
		E_QUIT:writeln(s,' vanishes in a brilliant burst of multicolored light.');
		E_SAY: begin
			if length(s) + length(sendname) > 73 then begin
				writeln(sendname,' says,');
				writeln('"',s,'"');
			end else begin
				if (rnd100 < 50) or (length(s) > 50) then
					writeln(sendname,': "',s,'"')
				else
					writeln(sendname,' says, "',s,'"');
			end;
		       end;
		E_HIDESAY: begin
				writeln('An unidentified voice speaks to you:');
				writeln('"',s,'"');
			   end;
		E_SETNAM: writeln(s);
		E_POOFIN: writeln('In an explosion of orange smoke ',s,' poofs into the room.');
		E_POOFOUT: writeln(s,' vanishes from the room in a cloud of orange smoke.');
		E_DETACH: begin
				writeln(s,' has destroyed the exit ',direct[targ],'.');
			  end;
		E_EDITDONE:begin
				writeln(sendname,' is done editing the room description.');
			   end;
		E_NEWEXIT: begin
				writeln(s,' has created an exit here.');
			   end;
		E_CUSTDONE:begin
				writeln(sendname,' is done customizing an exit here.');
			   end;
		E_SEARCH: writeln(sendname,' seems to be looking for something.');
		E_FOUND: writeln(sendname,' appears to have found something.');
		E_DONEDET:begin
				writeln(sendname,' is done adding details to the room.');
			  end;
		E_ROOMDONE: begin
				writeln(sendname,' is finished customizing this room.');
			    end;
		E_OBJDONE: begin
				writeln(sendname,' is finished customizing an object.');
			   end;
		E_UNHIDE:writeln(sendname,' has stepped out of the shadows.');
		E_FOUNDYOU: begin
				if targ = myslot then begin { found me! }
					writeln('You''ve been discovered by ',sendname,'!');
					hiding := false;
					getroom;
{ they're not hidden anymore }		here.people[myslot].hiding := 0;
					putroom;
				end else
					writeln(sendname,' has found ',here.people[targ].name,' hiding in the shadows!');
			    end;
		E_PUNCH: begin
				if targ = myslot then begin { punched me! }
					get_punch(p,sendname);
					take_hit( punch_force(p),send );
{ relic, but not harmful }		ping_answered := true;
					healthcycle := 0;
				end else
					view_punch(sendname,here.people[targ].name,p);
			 end;
		E_MADEOBJ: writeln(s);
		E_GET: writeln(s);
		E_DROP: begin
				writeln(s);
				if here.objdesc <> 0 then
					print_subs(here.objdesc,obj_part(p));
			end;
		E_BOUNCEDIN: begin
				if (targ = 0) or (targ = DEFAULT_LINE) then
					writeln(obj_part(p),' has bounced into the room.')
				else begin
					print_subs(targ,obj_part(p));
				end;
			     end;
		E_DROPALL: writeln('Some objects drop to the ground.');
		E_EXAMINE: writeln(s);
		E_IHID: writeln(sendname,' has hidden in the shadows.');
		E_NOISES: begin
				if (here.rndmsg = 0) or
				   (here.rndmsg = DEFAULT_LINE) then begin
					show_noises(rnd100);
				end else
					print_line(here.rndmsg);
			  end;
		E_ALTNOISE: begin
				if (here.xmsg2 = 0) or
				   (here.xmsg2 = DEFAULT_LINE) then
					show_altnoise(rnd100)
				else
					block_subs(here.xmsg2,myname);
			    end;
		E_REALNOISE: show_noises(rnd100);
		E_HIDOBJ: writeln(sendname,' has hidden the ',s,'.');
		E_PING: begin
				if targ = myslot then begin
					writeln(sendname,' is trying to ping you.');
					log_event(myslot,E_PONG,send,0);
				end else
					writeln(sendname,' is pinging ',here.people[targ].name,'.');
			end;
		E_PONG: begin
				ping_answered := true;
			end;
		E_HIDEPUNCH: begin
				if targ = myslot then begin
					writeln(sendname,' pounces on you from the shadows!');
					take_hit(2,send);
				end else begin
					writeln(sendname,' jumps out of the shadows and attacks ',here.people[targ].name,'.');
				end;
			     end;
		E_SLIPPED: begin
				writeln('The ',s,' has slipped from ',
					sendname,'''s hands.');
			   end;
		E_HPOOFOUT:begin
				if rnd100 > 50 then
					writeln('Great wisps of orange smoke drift out of the shadows.')
				else
					printed := false;
			   end;
		E_HPOOFIN:begin
				if rnd100 > 50 then
					writeln('Some wisps of orange smoke drift about in the shadows.')
				else
					printed := false;
			  end;
		E_FAILGO: begin
				if targ > 0 then begin
					write(sendname,' has failed to go ');
					writeln(direct[targ],'.');
				end;
			  end;
		E_TRYPUNCH: begin
				if targ = myslot then
					writeln(sendname,' fails to punch you.')
				else
					writeln(sendname,' fails to punch ',here.people[targ].name,'.');
			    end;
		E_PINGONE:begin
				if targ = myslot then begin { ohoh---pinged away }
					writeln('The Monster program regrets to inform you that a destructive ping has');
					writeln('destroyed your existence.  Please accept our apologies.');
					finish_interpreter;
					halt; { uggg }
				end else
					writeln(s,' shimmers and vanishes from sight.');
			  end;
		E_CLAIM: writeln(sendname,' has claimed this room.');
		E_DISOWN: writeln(sendname,' has disowned this room.');
		E_WEAKER: begin
{				inmem := false;
				gethere;		}

				here.people[send].health := targ;

{ This is a hack for efficiency so we don't read the room record twice;
  we need the current data now for desc_health, but checkevents, our caller,
  is about to re-read it anyway; we make an incremental fix here so desc_health
  is happy, then checkevents will do the real read later }

				desc_health(send);
			  end;
		E_SCAN: writeln(sendname,' scans some object from universe.');
		E_RESET: writeln(sendname,' has moved ',s,' to home position.');
		E_OBJCLAIM: writeln(sendname,' is now the owner of the ',s,'.');
		E_OBJDISOWN: writeln(sendname,' has disowned the ',s,'.');
		E_SELFDONE: writeln(sendname,'''s self-description is finished.');
		E_WHISPER: begin
				if targ = myslot then begin
					if length(s) < 39 then
						writeln(sendname,' whispers to you, "',s,'"')
					else begin
						writeln(sendname,' whispers something to you:');
						write(sendname,' whispers, ');
						if length(s) > 50 then
							writeln;
						writeln('"',s,'"');
					end;
				end else if (manager_priv) or (rnd100 > 85) then begin { minor change by leino@finuha }
					writeln('You overhear ',sendname,' whispering to ',here.people[targ].name,'!');
					write(sendname,' whispers, ');
					if length(s) > 50 then
						writeln;
					writeln('"',s,'"');
				end else
					writeln(sendname,' is whispering to ',here.people[targ].name,'.');
			   end;
		E_WIELD: writeln(sendname,' is now wielding the ',s,'.');
		E_UNWIELD: writeln(sendname,' is no longer wielding the ',s,'.');
		E_WEAR: writeln(sendname,' is now wearing the ',s,'.');
		E_UNWEAR: writeln(sendname,' has taken off the ',s,'.');
		E_DONECRYSTALUSE: begin
					writeln(sendname,' emerges from the glow of the crystal.');
					writeln('The orb becomes dark.');
				  end;
		E_DESTROY: writeln(s);
		E_OBJPUBLIC: writeln('The ',s,' is now public.');
		E_SYSDONE: writeln(sendname,' is no longer in system maintenance mode.');
		E_UNMAKE: writeln(sendname,' has unmade ',s,'.');
		E_LOOKDETAIL: writeln(sendname,' is looking at the ',s,'.');
		E_LOOKAROUND: writeln(sendname,' is looking around here.');
		E_NEWLEVEL: writeln(sendname,' is now ',s,'.');
		E_ACCEPT: writeln(sendname,' has accepted an exit here.');
		E_REFUSE: writeln(sendname,' has refused an Accept here.');
		E_DIED: writeln(s,' expires and vanishes in a cloud of greasy black smoke.');
		E_LOOKYOU: begin
				if targ = myslot then begin
					writeln(sendname,' is looking at you.')
				end else
					writeln(sendname,' looks at ',here.people[targ].name,'.');
			   end;
		E_LOOKSELF: writeln(sendname,' is making a self-appraisal.');
		E_FAILGET: writeln(sendname,' fails to get ',obj_part(targ),'.');
		E_FAILUSE: writeln(sendname,' fails to use ',obj_part(targ),'.');
		E_CHILL: if (targ = 0) or (targ = DEFAULT_LINE) then
				writeln('A chill wind blows over you.')
			 else
				print_desc(targ);
		E_NOISE2:begin
				case targ of
					1: writeln('Strange, guttural noises sound from everywhere.');
					2: writeln('A chill wind blows past you, almost whispering as it ruffles your clothes.');
					3: writeln('Muffled voices speak to you from the air!');
					4: writeln('The air vibrates with a chill shudder.');
					otherwise begin
						writeln('An unidentified voice speaks to you:');
						writeln('"',s,'"');
					   end;
				end;
			 end;
		E_INVENT: writeln(sendname,' is taking inventory.');
		E_POOFYOU: begin
				if targ = myslot then begin
					writeln;
					writeln(sendname,' directs a firey burst of bluish energy at you!');
					writeln('Suddenly, you find yourself hurtling downwards through misty orange clouds.');
					writeln('Your descent slows, the smoke clears, and you find yourself in a new place...');
					xpoof(p);
					writeln;
				end else begin
					writeln(sendname,' directs a firey burst of energy at ',here.people[targ].name,'!');
					writeln('A thick burst of orange smoke results, and when it clears, you see');
					writeln('that ',here.people[targ].name,' is gone.');
				end;
			   end;
		E_WHO: begin
			case p of
				0: writeln(sendname,' produces a "who" list and reads it.');
				1: writeln(sendname,' is seeing who''s playing Monster.');
				otherwise writeln(sendname,' checks the "who" list.');
			end;
		       end;
		E_PLAYERS:begin
				writeln(sendname,' checks the "players" list.');
			  end;
		E_VIEWSELF: writeln(sendname,' is reading ',s,'''s self-description.');
	  	E_MIDNIGHT: show_midnight(targ,printed);
                E_DCLDONE: writeln(sendname,' is no longer in dcl-level.');
                E_ADDEXPERIENCE: begin
                                   if targ = myslot then add_experience(p)
                                   else { some message ? }
                                 end;
                E_HATTACK: get_hideattack (send,targ,p);
		E_ATTACK: get_attack (send,targ,p);
		E_TRAP: see_trap (send,p,s);
                E_ERASE: writeln (sendname,' is destroying monster here.');
                E_MONSTERDONE: writeln(sendname,' is done customizing monster.');
                E_SPELLDONE: writeln(sendname,' is done customizing spell.');
		E_BROADCAST: writeln(s); { NPC broadcasting }

		E_ATMOSPHERE: writeln(s); { s.c. atmosphere command }


		E_ACTION:writeln(sendname,' is',desc_action(p,targ));

		{ in that events targ is player's log - NOT player's slot }
		E_KICK_OUT: begin
		    if targ = mylog then begin
			if s > '' then writeln(s)
			else writeln('System throw you out from Monster.');
			quit_monster; { generate eof }
		    end else begin
			getpers;
			freepers;
			writeln('System throw ',pers.idents[targ],
			    ' out from Monster.');
		    end;
		end;
		E_ANNOUNCE: if (((targ=0) and (p=0)) {For all} or
				(targ=mylog) {For me} 
				{or (p=md_grp)} )  {My group}
			    then writeln(s)
			    else printed:=false;
		E_SHUTDOWN: if manager_priv then writeln('SHUTDOWN: ',s)
			    else begin
				writeln('MONSTER SHUTDOWN: ',s);
				quit_monster;
			    end;
		E_GLOBAL_CHANGE: begin
		    if s <> '' then writeln(s)
		    else if manager_priv then writeln
			('Global flags are changed.')
		    else printed := false;
		    read_global := true; { need read }
		end;

		otherwise writeln('*** Bad Event ***');
	end;
end;


[global]
procedure checkevents(silent: boolean := false);
var
	gotone: boolean;
	tmp,printed: boolean;

begin
{ if not starting then begin }
	getevent;
	freeevent;

	event := eventfile^;
	gotone := false;
	printed := false;
	while myevent <> event.point do begin
		myevent := myevent + 1;
		if myevent > maxevent then
			myevent := 1;

		if debug then begin
			writeln('%checking event ',myevent);
			if event.evnt[myevent].loc = location then
				writeln('  - event here')
			else
				writeln('  - event elsewhere');
			writeln('  - event number = ',event.evnt[myevent].action:1);
		end;

		if (event.evnt[myevent].loc = location) or
		   (event.evnt[myevent].action = E_ANNOUNCE) or
		   (event.evnt[myevent].action = E_SHUTDOWN) or 
		   (event.evnt[myevent].action = E_GLOBAL_CHANGE) then begin
			if (event.evnt[myevent].sender <> myslot) then begin

						{ if sent by me don't look at it }
						{ will use global record event }
				gethere; 	{ we possible need this }
				handle_event(tmp);
				if tmp then
					printed := true;

				inmem := false;	{ re-read important data that }
				gethere;	{ may have been altered }

	  			gotone := true;
			end;
		end;
	end;

	if myslot > 0 then
	    printed := time_check or printed;	{ run submit queue }
	    { myslot is 0 during log_ping and during login password }

	if (printed) {and (gotone)} and not(silent) then begin
	  	reprint_grab;
	end;

	rnd_event(silent);
{    end; } { if not starting } 
end;


{ function find_numpeople moved to module CUSTOM }

{ procedure noisehide moved to module CUSTOM }

{ function checkhide moved to module CUSTOM }

procedure clear_command;

begin
	if logged_act then begin
		getroom;
		here.people[myslot].act := 0;
		putroom;
		logged_act := false;
	end;
end;

{ forward procedure take_token(aslot, roomno: integer); }
procedure take_token;
			{ remove self from a room's people list }

begin
	getroom(roomno);
	with here.people[aslot] do begin
		kind := 0;
		username:= '';
		{ name := '';
			prevents null messages when player exits rooms 
			(hurtta@finuh)
		}
	end;
	putroom;
end;


[global] function put_token(room: integer;var aslot:integer;
	hidelev:integer := 0):boolean; {
			 put a person in a room's people list
			 returns myslot }
var
	i,j: integer;
	found: boolean;
	savehold: array[1..maxhold] of integer;

begin
	if first_puttoken then begin
		for i := 1 to maxhold do
			savehold[i] := 0;
		first_puttoken := false;
	end else begin
		gethere;
		for i := 1 to maxhold do
			savehold[i] := here.people[myslot].holding[i];
	end;

	getroom(room);
	i := 1;
	found := false;
	while (i <= maxpeople) and (not found) do begin
		if here.people[i].kind = 0 then
			{ minor change by hurtta@finuh }
			found := true
		else
			i := i + 1;
	end;
	put_token := found;
	if found then begin
		here.people[i].kind := P_PLAYER;	{ I'm a real player }
		here.people[i].name := myname;
		here.people[i].username := userid;
		here.people[i].hiding := hidelev;
			{ hidelev is zero for most everyone
			  unless you want to poof in and remain hidden }

		here.people[i].wearing := mywear;
		here.people[i].wielding := mywield;
		here.people[i].health := myhealth;
	  	here.people[i].self := myself;
		here.people[i].experience := myexperience;
			{ write experience also to here (hurtta@finuh) }

		here.people[i].act := 0;

		here.people[i].parm := 0; 	{ hurtta@finuh }

		for j := 1 to maxhold do
			here.people[i].holding[j] := savehold[j];
		putroom;

		aslot := i;
		for j := 1 to maxexit do	{ haven't found any exits in }
			found_exit[j] := false;	{ the new room }

		{ note the user's new location in the logfile }
		getint(N_LOCATION);
		anint.int[mylog] := room;
		putint;
		if debug then 
		    writeln('%puttoken: <',mylog:1,'> => ',
			room,'(',aslot:1,')');
	end else
		freeroom;
end;

procedure log_exit(direction,room,sender_slot: integer);

begin
 	log_event(sender_slot,E_EXIT,direction,0,log_name,room);
end;

procedure log_entry(direction,room,sender_slot: integer);

begin
	log_event(sender_slot,E_ENTER,direction,0,log_name,room);
end;

procedure log_begin(room:integer := 1);

begin
	log_event(0,E_BEGIN,0,0,log_name,room);
end;

procedure log_quit(room:integer;dropped:boolean);

begin
	log_event(0,E_QUIT,0,0,log_name,room);
	if dropped then
		log_event(0,E_DROPALL,0,0,log_name,room);
end;




{ return the number of people you can see here }

function n_can_see: integer;
var
	sum: integer;
	i: integer;
	selfslot: integer;

begin
	if here.locnum = location then
		selfslot := myslot
	else
		selfslot := 0;

	sum := 0;
	for i := 1 to maxpeople do
		if ( i <> selfslot ) and
		   ( here.people[i].kind > 0 ) and	{ hurtta@finuh }
		   ( here.people[i].hiding = 0 ) then
			sum := sum + 1;
	n_can_see := sum;
	if debug then
		writeln('%n_can_see = ',sum:1);
end;



function next_can_see(var point: integer): string;
var
	found: boolean;
	selfslot: integer;
	wear: integer;

begin
	if here.locnum <> location then
		selfslot := 0
	else
		selfslot := myslot;
	found := false;
	while (not found) and (point <= maxpeople) do begin
		if (point <> selfslot) and
		   (here.people[point].kind > 0) and	{ hurtta@finuh }
		   (here.people[point].hiding = 0) then
			found := true
		else
			point := point + 1;
	end;

	if found then begin
		next_can_see := here.people[point].name;
		wear := here.people[point].wearing;
		if wear > 0 then begin
			getobj(wear);
			freeobj;
			if obj.kind = O_DISGUISE then 
				next_can_see := 'Someone (with '+
					obj_part(wear,false)+')';
		end;
		point := point + 1;
	end else begin
		next_can_see := myname;	{ error!  error! }
		writeln('%searching error in next_can_see; notify the Monster Manager');
	end;
end;



procedure people_header(where: shortstring);
var
	point: integer;
	tmp: string;
	i: integer;
	n: integer;
	len: integer;

begin
	point := 1;
	n := n_can_see;
	case n of
		0:;
		1: begin
			writeln(next_can_see(point),' is ',where);
		   end;
		2: begin
			writeln(next_can_see(point),' and ',next_can_see(point),
				' are ',where);
		   end;
		otherwise begin
			len := 0;
			for i := 1 to n - 1 do begin { at least 1 to 2 }
				tmp := next_can_see(point);
				if i <> n - 1 then
					tmp := tmp + ', ';
				niceprint(len,tmp);
			end;

			niceprint(len,' and ');
			niceprint(len,next_can_see(point));
			niceprint(len,' are ' + where);
			writeln;
		end;
	end;
end;


procedure desc_person(i: integer);
var
	pname : string;
	wear: integer;
	lev,rel: integer;
begin
	pname  := here.people[i].name;
	wear   := here.people[i].wearing;
	lev    := level(here.people[i].experience);

	if wear > 0 then begin
		getobj(wear);
		freeobj;
		if obj.kind = O_DISGUISE then begin
			pname := 'Someone';
			writeln('Someone is hiding behind ',obj_part(wear,false),'.');
		end;
	end;


	if here.people[i].act <> 0 then begin
		write(pname,' is');
		writeln(desc_action(here.people[i].act,
			here.people[i].targ));
					{ describes what person last did }
	end;

	rel := here.people[i].health * 10 div leveltable[lev].health;

	if rel <> GOODHEALTH then desc_health(i,pname+' ');

	if (wear > 0) and (pname <> 'Someone') then
		writeln(pname,' is wearing ',obj_part(wear),'.');

	if here.people[i].wielding > 0 then
		writeln(pname,' is wielding ',obj_part(here.people[i].wielding),'.');

end;


procedure show_people;
var
	i: integer;

begin
	people_header('here.');
	for i := 1 to maxpeople do begin
		if (here.people[i].kind > 0) and
		    { minor change by hurtta@finuh }
		   (i <> myslot) and
		   (here.people[i].hiding = 0) then
				desc_person(i);
	end;
end;


procedure show_group;
var
	gloc1,gloc2: integer;
	gnam1,gnam2: shortstring;

begin
	gloc1 := here.grploc1;
	gloc2 := here.grploc2;
	gnam1 := here.grpnam1;
	gnam2 := here.grpnam2;

	if gloc1 <> 0 then begin
		gethere(gloc1);
		people_header(gnam1);
	end;
	if gloc2 <> 0 then begin
		gethere(gloc2);
		people_header(gnam2);
	end;
	gethere;
end;


procedure desc_obj(n: integer);

begin
	if n <> 0 then begin
		getobj(n);
		freeobj;
		if (obj.linedesc = DEFAULT_LINE) then begin
			writeln('On the ground here is ',obj_part(n,FALSE),'.');

				{ the FALSE means obj_part shouldn't do its
				  own getobj, cause we already did one }
		end else
			print_line(obj.linedesc);
	end;
end;


procedure show_objects;

var
	i: integer;

begin
	for i := 1 to maxobjs do begin
		if (here.objs[i] <> 0) and (here.objhide[i] = 0) then
			desc_obj(here.objs[i]);
	end;
end;

{ function lookup_detail moved to module CUSTOM }

function look_detail(s: string): boolean;
var
	n: integer;

begin
	if lookup_detail(n,s) then begin
		if here.detaildesc[n] = 0 then
			look_detail := false
		else begin
			print_desc(here.detaildesc[n]);
			log_event(myslot,E_LOOKDETAIL,0,0,here.detail[n]);
			look_detail := true;
			if here.hook > 0 then
				run_monster('',here.hook,'look detail',
					'detail',here.detail[n],
					sysdate+' '+systime);
		end;
	end else
		look_detail := false;
end;


function look_person(s: string; silent: boolean := false): boolean;
label 0; { for panic }
var
	objnum,i,n,lev,oldloc: integer;
	first: boolean;

    function restriction(slot: integer): boolean;
    begin
	restriction := here.people[slot].hiding = 0;
	{ can't see hiding people }
    end;

    function action(s: shortstring; n: integer): boolean;
    begin
	if n = myslot then begin
	    log_event(myslot,E_LOOKSELF,n,0);
	    writeln('You step outside of yourself for a moment to get an objective self-appraisal:');
	    writeln;
	end else log_event(myslot,E_LOOKYOU,n,0);

	if here.people[n].self <> 0 then begin
	    print_desc(here.people[n].self);
	    writeln;
	    
	end;

	if (here.people[n].kind = P_MONSTER) and 
	    (here.people[n].parm > 0) then
	    run_monster(here.people[n].name,
		here.people[n].parm,'look you','','',
		    sysdate+' '+systime);
	if oldloc <> location then goto 0; { panic }

	desc_health(n);

	lev := level(here.people[n].experience);
	if here.people[n].kind = P_PLAYER then
	    writeln(here.people[n].name,' is ',leveltable[lev].name,'.');

		{ Do an inventory of person S }
		{ What is he wearing? }
	if here.people[n].wearing <> 0 then
	    writeln(here.people[n].name,' is wearing ',obj_part(here.people[n].wearing),'.');
		{ What is he wielding? }
	if here.people[n].wielding <> 0 then
	    writeln(here.people[n].name,' is wielding ',obj_part(here.people[n].wielding),'.');
	if here.people[n].act <> 0 then begin
	    write(here.people[n].name,' is');
	    writeln(desc_action(here.people[n].act,
			here.people[n].targ));
		{ describes what person last did }
	end;


			{ What other stuff does he carry? }
	first := true;
	for i := 1 to maxhold do begin
	    objnum := here.people[n].holding[i];
	    { Show only once those things he wears or wields }
	    if (objnum <> 0) then begin
		if (objnum <> here.people[n].wearing) and
		    (objnum <> here.people[n].wielding) then begin
		    if first then begin
			writeln(here.people[n].name,' is holding:');
			first := false;
		    end;
		    writeln('   ',obj_part(objnum));
		end;
	    end;
	end;
	if first then
	    writeln(here.people[n].name,' is empty handed.');
	action := true;
	checkevents(TRUE);
	if oldloc <> location then goto 0; { panic }
    end;    { action }


begin
    look_person := false;
    oldloc := location;
    if scan_pers_slot(action,s,silent,restriction) then begin
	look_person := true;
    end else
	look_person := false;
    0: { for panic }
end;


procedure do_examine(s: string;var three: boolean;silent:boolean := false);
label 0;
var
	n,oldloc: integer;
	msg: string;

    function action(s: shortstring; n: integer): boolean;
    begin
	    three := true;

		getobj(n);
		freeobj;
		msg := log_name + ' is examining ' + obj_part(n) + '.';
		log_event(myslot,E_EXAMINE,0,0,msg);
		if (obj.home = location) and (obj.homedesc <> 0) 
		    and obj_here (n,TRUE) then
		    print_desc(obj.homedesc)
		else if obj.examine = 0 then
		    writeln('You see nothing special about the ',
			objnam.idents[n],'.')
		else
		    print_desc(obj.examine);
		if obj.actindx > 0 then
		    run_monster('',obj.actindx,
			'look you','','',
			sysdate+' '+systime);
		action := true;
	    checkevents (TRUE);
	    if oldloc <> location then goto 0; { panic }
       end; { action }

    function restriction (n: integer): boolean;
	begin
	    restriction := obj_here(n,true) or obj_hold(n);
	    { true = not found hidden objects }
	end;

begin
	{ if s = '' then grab_line('Object? ',s); }

	three	:= false;
	oldloc	:= location;
	if scan_obj(action,s,silent,restriction) then begin
	end else
		if not(silent) then
			writeln('That object cannot be seen here.');
	0: { for panic }
end;



procedure print_room;

begin
	case here.nameprint of
		0:;	{ don't print name }
		1: writeln('You''re in ',here.nicename);
		2: writeln('You''re at ',here.nicename);
		3: writeln('You''re in the ',here.nicename);
		4: writeln('You''re at the ',here.nicename);
		5: writeln('You''re in a ',here.nicename);
		6: writeln('You''re at a ',here.nicename);
		7: writeln('You''re in an ',here.nicename);
		8: writeln('You''re at an ',here.nicename);
	end;

	if not(brief) then begin
	case here.which of
		0: print_desc(here.primary);
		1: print_desc(here.secondary);
		2: begin
			print_desc(here.primary);
			print_desc(here.secondary);
		   end;
		3: begin
			print_desc(here.primary);
			if here.magicobj <> 0 then
				if obj_hold(here.magicobj) then
					print_desc(here.secondary);
		   end;
		4: begin
			if here.magicobj <> 0 then begin
				if obj_hold(here.magicobj) then
					print_desc(here.secondary)
				else
					print_desc(here.primary);
			end else
				print_desc(here.primary);
		   end;
	end;
	writeln;
	end;   { if not(brief) }
end;



procedure do_look(s: string := '');
label 1;
var
	n: integer;
	one,two,three: boolean;
	oldloc : integer;
begin
	gethere;
	if s = '' then begin	{ do an ordinary top-level room look }
		oldloc := location;
		if hiding then begin
			writeln('You can''t get a very good view of the details of the room from where');
			writeln('you are hiding.');
			noisehide(67);
		end else begin
			log_event(myslot,E_LOOKAROUND);
			print_room;
			show_exits;
		end;		{ end of what you can't see when you're hiding }
		show_people;   if oldloc <> location then goto 1;
		show_group;
		show_objects;  if oldloc <> location then goto 1;
		if here.hook > 0 then 
			run_monster('',here.hook,'look around','','',
				sysdate+' '+systime);
		if oldloc <> location then goto 1;
		meta_run('look','','');
	end else begin		{ look at a detail in the room }
                oldloc := location;
		one := look_detail(s);
		two := look_person(s,TRUE); if oldloc <> location then goto 1;
		do_examine(s,three,TRUE); if oldloc <> location then goto 1;
		if not(one or two or three) then
			writeln('There isn''t anything here by that name to look at.')
		else meta_run('look','','')
	end;
	1:
end;


procedure init_exit(dir: integer);

begin
	with here.exits[dir] do begin
		exitdesc := DEFAULT_LINE;
		fail := DEFAULT_LINE;		{ default descriptions }
		success := 0;			{ until they customize }
		comeout := DEFAULT_LINE;
		goin := DEFAULT_LINE;
		closed := DEFAULT_LINE;

		objreq := 0;		{ not a door (yet) }
		hidden := 0;		{ not hidden }
		reqalias := false;	{ don't require alias (i.e. can use
					  direction of exit North, east, etc. }
		reqverb := false;
		autolook := true;
		alias := '';
	end;
end;



procedure remove_exit(dir: integer);
var
	targroom,targslot,owner: integer;
	hereacc,targacc: boolean;

begin
		{ Leave residual accepts if player is not the owner of
		  the room that the exit he is deleting is in }

	getroom;
	targroom := here.exits[dir].toloc;
	targslot := here.exits[dir].slot;
	here.exits[dir].toloc := 0;
	init_exit(dir);

	if (here.owner = userid) or 
	    (owner_priv and (here.owner <> system_id)) or
	    manager_priv then { minor change by leino@finuha and hurtta@finuha }
		hereacc := false
	else
		hereacc := true;

	if hereacc then begin
		here.exits[dir].kind := 5;	{ put an "accept" in its place }
		
		if exact_user(owner,here.owner) then
		    add_counter(N_ACCEPT,owner);

	end else
		here.exits[dir].kind := 0;

	putroom;
	log_event(myslot,E_DETACH,dir,0,log_name,location);

	getroom(targroom);
	here.exits[targslot].toloc := 0;

	if (here.owner = userid) or (owner_priv) then { minor change by leino@finuha }
		targacc := false
	else
		targacc := true;

	if targacc then
		here.exits[targslot].kind := 5	{ put an "accept" in its place }
	else
		here.exits[targslot].kind := 0;

	putroom;

	if targroom <> location then
		log_event(0,E_DETACH,targslot,0,log_name,targroom);
	writeln('Exit destroyed.');
end;


{
User procedure to unlink a room
}
procedure do_unlink(s: string);
label exit_label;
var
	dir: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


begin
	if s = '' then grab_line('Direction? ',s,eof_handler := leave);

	gethere;
	if checkhide then begin
	if lookup_dir(dir,s,true) then begin
		if can_alter(dir) then begin
			if here.exits[dir].toloc = 0 then
				writeln('There is no exit there to unlink.')
			else
				remove_exit(dir);
		end else
			writeln('You are not allowed to remove that exit.');
	end else
		writeln('To remove an exit, type UNLINK <direction of exit>.');
	end;
	exit_label:
end;

{ slead and bite moved to PARSER.PAS }

{ function desc_allowed moved to module CUSTOM }



{ procedure do_descibe moved to module CUSTOM }

procedure del_room(n: integer);
var
	i,oldowner: integer;

begin
	getnam;
	nam.idents[n] := '';	{ blank out name }
	putnam;

	getown;
	own.idents[n] := '';	{ blank out owner }
	putown;

	getroom(n);
	if not exact_user(oldowner,here.owner) then oldowner := 0;
	change_owner(oldowner,0);

	for i := 1 to maxexit do begin
		with here.exits[i] do begin
			delete_line(exitdesc);
			delete_block(fail);
			delete_block(success);
			delete_block(comeout);
			delete_block(goin);
			delete_block(hidden);
		end;
	end;
	for i := 1 to maxdetail do begin
		delete_block(here.detaildesc[i]);
	end;
	delete_block(here.primary);
	delete_block(here.secondary);
        delete_line(here.objdesc);
        delete_line(here.objdest);
        delete_line(here.rndmsg);
        delete_block(here.xmsg2);
        delete_block(here.exitfail);
        delete_block(here.ofail);
	if here.hook > 0 then begin	{ delete hook -code }
		delete_program(here.hook);
		delete_general(I_HEADER,here.hook);
	end;
	putroom;
	delete_room(n);	{ return room to free list }
end;



procedure createroom(s: string);	{ create a room with name s }
var
	roomno: integer;
	dummy: integer;
	i:integer;
	rand_accept: integer;

begin
	if length(s) = 0 then begin
		writeln('Please specify the name of the room you wish to create as a parameter to FORM.');
	end else if length(s) > shortlen then begin
		writeln('Please limit your room name to a maximum of ',shortlen:1,' characters.');
	end else if exact_room(dummy,s) then begin
		writeln('That room name has already been used.  Please give a unique room name.');
	end else if nc_createroom(s) then begin
		{ nc_createroom have in module ALLOC }
		log_action(form,0);
		writeln('Room created.');
	end;
end;




function lookup_cmd(s: string):integer;
var
	i,		{ index for loop }
	poss,		{ a possible match -- only for partial matches }
	maybe,		{ number of possible matches we have: > 2 is ambig. }
	num		{ the definite match }
		: integer;


begin
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to numcmds do begin
		if s = cmds[i] then
			num := i
		else if index(cmds[i],s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;
	end;
	if num <> 0 then begin
		lookup_cmd := num;
	end else if maybe = 1 then begin
		lookup_cmd := poss;
	end else if maybe > 1 then
		lookup_cmd := error	{ "Ambiguous" }
	else
		lookup_cmd := error;	{ "Command not found " }
end;

{ addrooms moved to module DATABASE }

{ addints moved to module DATABASE }

{ addlines moved to module DATABASE }

{ addblocks moved to module DATABASE }

{ addobjects moved to module DATABASE }

procedure dist_list;
var
	i,j: integer;
	f: text;
	where_they_are: intrec;

begin
	writeln('Writing distribution list . . .');
	open(f,'monsters.dis',history := new);
	rewrite(f);

	getindex(I_PLAYER);	{ Rec of valid player log records  }
	freeindex;		{ False if a valid player log }

	getuser;		{ Corresponding userids of players }
	freeuser;

	getreal_user;		{ real usernames of players }
	freereal_user;

	getpers;		{ Personal names of players }
	freepers;

	getdate;		{ date of last play }
	freedate;

	if manager_priv then begin { minor change by leino@finuha }
		getint(N_LOCATION);
		freeint;
		where_they_are := anint;

		getnam;
		freenam;
	end;

	for i := 1 to maxplayers do begin
		if not(indx.free[i]) then begin
			if user.idents[i] = '' then write(f,'! <null>        ')
			else if user.idents[i][1] = ':' then 
				write(f,'! <monster>     ')
			else if user.idents[i][1] = '"' then begin
                                write(f,real_user.idents[i]);
				for j := length(real_user.idents[i]) to 15 do
					write(f,' ');
			end else begin 
{ if we have username, don't use real_username, because it can be of 	}
{ Monster Manager 							}
				write(f,user.idents[i]);
				for j := length(user.idents[i]) to 15 do
					write(f,' ');
			end;
			write(f,'! ',pers.idents[i]);
			for j := length(pers.idents[i]) to 21 do
				write(f,' ');

			write(f,adate.idents[i]);
				if length(adate.idents[i]) < 19 then
					for j := length(adate.idents[i]) to 18 do
						write(f,' ');
			if anint.int[i] <> 0 then
				write(f,' * ')
			else
				write(f,'   ');

			if manager_priv then begin { minor change by leino@finuha }
				write(f,nam.idents[ where_they_are.int[i] ]);
			end;
			writeln(f);

		end;
	end;
	writeln('Done.');
end;


{ system_view moved to DATABASE.PAS }


{ remove a user from the log records (does not handle ownership) }

procedure kill_user(s:string);
var
	n: integer;

begin
	if length(s) = 0 then
		writeln('No user specified')
	else begin
		if lookup_user(n,s,true) then begin
			getindex(I_ASLEEP);
			freeindex;                
                        { variable user is reading in lookup_user }
                        if user.idents[n][1] = ':' then begin
 				writeln ('That is monster, not player.');
				writeln ('Use ERASE <monster name> to delete monster.')
			end else if indx.free[n] then begin
				delete_log(n);
				writeln('Player deleted.');
	  		end else
				writeln('That person is playing now.');
		end else
			writeln('No such userid found in log information.');
	end;
end;


{ disown everything a player owns }

procedure disown_user(s:string);
var
	n: integer;
	i,count: integer;
	tmp: string;
	theuser: string;

begin

	if length(s) > 0 then begin
	    if not lookup_user(n,s) then begin
		    writeln('User not in log info, attempting to disown anyway.');
		    theuser := s;
	    end else begin
		    theuser := user.idents[n];

	    end;
	    { first disown all their rooms }

	    getown;
	    freeown;
	    getindex(I_ROOM);
	    freeindex;
	    for i := 1 to indx.top do if not indx.free[i] then
			if own.idents[i] = theuser then begin
				    getown;
				    own.idents[i] := disowned_id;
				    putown;

				    getroom(i);
				    tmp := here.nicename;
				    here.owner := disowned_id;
				    putroom;

				    writeln('Disowned room ',tmp);
			end;
	    writeln;

	    getobjown;
	    freeobjown;
	    getobjnam;
	    freeobjnam;

	    getindex(I_OBJECT);
	    freeindex;
	    for i := 1 to indx.top do if not indx.free[i] then
				if objown.idents[i] = theuser then begin
				    getobjown;
				    objown.idents[i] := disowned_id;
				    putobjown;

				    tmp := objnam.idents[i];
				    writeln('Disowned object ',tmp);
				end;

	    { writeln('Disown codes ...'); }
	    count := 0;
	    getindex(I_HEADER);
	    freeindex;
	    for i := 1 to indx.top do if not indx.free[i] then
			    if monster_owner(i) = theuser then begin
				set_owner(i,,disowned_id);
				count := count +1;
			    end;
	    if count > 0 then 
			writeln('Disowned ',count:1,' codes.');
		    
	    sub_counter(N_NUMROOMS,n,get_counter(N_NUMROOMS,n));
	    sub_counter(N_ACCEPT,n,get_counter(N_ACCEPT,n));
	end else
		writeln('No user specified.');
end;

procedure move_asleep (s : string);
label exit_label;
var
	pname,rname:string;	{ player & room names }
	newroom,n: integer;	{ room number & player slot number }

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


begin
	if s = '' then grab_line('Player name? ',pname,
	    eof_handler := leave)
	else pname := s;
	if lookup_user(n,pname,true) then begin
		grab_line('Room name?   ',rname,
		    eof_handler := leave);
		if lookup_room(newroom,rname,true) then begin
			getindex(I_ASLEEP);
			freeindex;
			if indx.free[n] then begin
				getint(N_LOCATION);
				anint.int[n] := newroom;
				putint;
				writeln('Player moved.');
			end else
				writeln('That player is not asleep.');
		end else
			writeln('No such room found.');
	end else
		writeln('User not found.');
    exit_label:
end;

      

procedure authorize (param: string);
label exit_label;
{ leino@finuha }

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


var
	s, prompt, pname: string;
	cmd: char;
	done: boolean;
	n, i, j: integer;
   	privs,
	system,
	poof,
	room,
	object,
	special,
	monster,
	exp		: integer;
	granted : unsigned;

begin
	prompt:= 'Authorize> ';
	if param = '' then grab_line ('Player name? ', pname,
	    eof_handler := leave)
	else pname := param;
	if lookup_user(n, pname, true) then begin

		getint (N_PRIVILEGES);
		freeint;

		privs:= anint.int [n];

		granted := all_privileges;
		if userid <> MM_userid  then 
		    granted := uand(granted,unot(PR_manager));

		if custom_privileges(privs,granted) then begin
		    
		    getint (N_PRIVILEGES);
		    anint.int [n] := privs;
		    putint;
		    writeln ('Database updated.');

		end else writeln('Database not updated.');


(*  		system:= privs mod 2;
|		poof:= (privs mod 4) div 2;
|		room:= (privs mod 8) div 4;
|		object:= (privs mod 16) div 8;
|		special:= (privs mod 32) div 16;
|		monster:= (privs mod 64) div 32;
|		exp:= (privs mod 128) div 64;
|
|		done:= false;
|	  	repeat
|			repeat
|				grab_line(prompt,s,eof_handler := leave);
|				s := slead(s);
|			until length(s) > 0;
|			s := lowcase(s);
|			cmd := s[1];
|
|			case cmd of
|			'h','?': begin       
|					writeln ('C - Experience privilege');
|					writeln ('D - Monster privilege');
|					writeln ('E - Exit');
|					writeln ('H - Help (this list)');
|					if userid = MM_userid then
|						writeln ('M - Manager rights');
|					writeln ('O - Object privilege');
|					writeln ('P - Poof privilege');
|					writeln ('Q - Quit (do not save changes)');
|					writeln ('R - Room privilege');
|					writeln ('S - Special object privilege');
|					writeln ('V - View current privileges');
|					writeln ('? - This list'); 
|				end;
|			    'v': begin
|					writeln ('Current privileges:');
|					privs := system+ 2*poof+ 4*room+ 8*object+ 16*special+ 32*monster+ 64*exp;
|					list_privileges (privs); end;
|			    'm': 	if userid <> MM_userid then
|						writeln ('Only the Monster Manager can grant manager rights.')
|				else 	if system=1 then begin
|						if n=mylog then
|							writeln('You cannot remove your own manager rights.')
|						else begin
|							system:=0;
|							writeln ('User has lost manager rights.');
|						end;
|				     	end  else begin
|				     		system:=1;
|				      	    	writeln ('User now has manager rights.');
|				     	end;
|			    'p':	if poof=1 then begin
|						poof:=0;
|						writeln ('User has lost poof privilege.');
|					end else begin
|						poof:=1;
|				    		writeln ('User now has poof privilege.');
|			     		end;                               
|			    'r':	if room=1 then begin
|						room:=0;
|						writeln ('User has lost room privilege.');
|					end else begin
|						room:=1;
|				    		writeln ('User now has room privilege.');
|				     	end;
|			    'o':	if object=1 then begin
|						object:=0;
|						writeln ('User has lost object privilege.');
|					end else begin
|						object:=1;
|				    		writeln ('User now has object privilege.');
|			     		end;
|			    's':	if special=1 then begin
|						special:=0;
|						writeln ('User has lost special privilege.');
|					end else begin
|						special:=1;
|				    		writeln ('User now has special privilege.');
|				     	end;
|			    'd':	if monster=1 then begin
|						monster:=0;
|						writeln ('User has lost monster privilege');
|					end else begin
|						monster:=1;
|				    		writeln ('User now has monster privilege.');
|				     	end;
|			    'c':	if exp=1 then begin
|						exp:=0;
|						writeln ('User has lost experience privilege.');
|					end else begin
|						exp:=1;
|				    		writeln ('User now has experience privilege.');
|				     	end;
|			'q': begin
|					writeln ('Database not updated');
|					done := true;
|					end;
|			'e': begin
|		 			privs := system+ 2*poof+ 4*room+ 8*object+ 16*special+ 32*monster+ 64*exp;
|					getint (N_PRIVILEGES);
|					anint.int [n]:= privs;
|					putint;
|					writeln ('Database updated.');
|					done := true;
|					end;
|			otherwise writeln('-- bad command, type ? for a list.');
|			end;
|		until done;
*)

	end else if (pname = '*') or (pname = 'all') then begin

		getindex(I_PLAYER);	{ Rec of valid player log records  }
		freeindex;		{ False if a valid player log }

		getuser;		{ Corresponding userids of players }
		freeuser;

		getpers;		{ Personal names of players }
		freepers;

		getint (N_PRIVILEGES);	{ Privileges }
		freeint;

		for i := 1 to maxplayers do begin
			if not(indx.free[i]) then begin
				write (user.idents[i]);
				for j := length(user.idents[i]) to 16 do
					write (' ');
				write(pers.idents[i]);
				for j := length(pers.idents[i]) to 21 do
					write (' ');
				list_privileges (anint.int [i]);
			end;
		end;
	end else
		writeln('No such player.');
    exit_label:
end;



{ *************** FIX_STUFF ******************** }

procedure fix_p_passwd(n: integer; s: string);
label exit_label;
var key: shortstring;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
   if s = '' then grab_line('Player''s password? ',s,eof_handler := leave);
   if length(s) > shortlen then 
      writeln('Limit password to ',shortlen:1,' characters.')
   else begin
      key := s;
      encrypt(key,n);
      getpasswd;
      passwd.idents[n] := key;
      putpasswd;
      writeln('Database updated.');
   end;
   exit_label:
end; { fix_p_passwd }

procedure fix_p_pers(n: integer; s: string);
label exit_label;
var dummy: integer;
    ok: boolean;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
   if s = '' then grab_line('Player''s personal name? ',s,
      eof_handler := leave);
   s := slead(s);
   if s = '' then
      writeln('No changes.')
   else if length(s) > shortlen then 
      writeln('Limit password to ',shortlen:1,' characters.')
   else begin
      if exact_pers(dummy,s) then 
         if dummy = n then ok := true
         else ok := false
      else ok := true;
      if not ok then 
         writeln('That persoanal name is already in use.')
      else begin
         getpers;
         pers.idents[n] := s;
         putpers;
         writeln('Database updated.');
      end;
   end;
   exit_label:
end; { fix_p_pers }

procedure fix_p_health(n: integer; s: string);
label exit_label;
var exp,lev, top: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
   getint(N_EXPERIENCE);
   freeint;
   exp := anint.int[n];
   lev := level(exp);
   top := leveltable[lev].health;

   if s = '' then begin
      writeln('Enter health 0 - ',top:1);
      grab_line('Player''s health? ',s,eof_handler := leave);
   end;

   if s = '' then writeln ('No changes.')
   else if not isnum(s) then
      writeln('No such health.')
   else if (number(s) < 0) or (number(s)> top) then
      writeln('Out of range.')
   else begin
      getint(N_HEALTH);
      anint.int[n] := number(s);
      putint;
      writeln('Database updated.');
   end;
   exit_label:
end; { fix_p_health }


procedure fix_p_quota(n: integer; s: string);
label exit_label;
var exp,lev, top: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin

   if s = '' then begin
      writeln('Enter quota 0 - ',maxroom:1);
      grab_line('Player''s room quota? ',s,eof_handler := leave);
   end;

   if s = '' then writeln ('No changes.')
   else if not isnum(s) then
      writeln('No such quota.')
   else if (number(s) < 0) or (number(s)> maxroom) then
      writeln('Out of range.')
   else begin
      getint(N_ALLOW);
      anint.int[n] := number(s);
      putint;
      writeln('Database updated.');
   end;
   exit_label:
end; { fix_p_quota }



procedure fix_p_level(n: integer; s: string);
label exit_label;
var exp,lev,i: integer;
    ok : boolean;
    prevlevel,nextlevel: integer;
    prevpriv,nextpriv: unsigned;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
  if s = '' then begin
     writeln('Enter player''s level ',leveltable[1].name,
        ' - ',leveltable[levels].name);
     writeln('or enter player experience 0 - ',maxexperience:1);
     grab_line('Player''s level or experience? ',s,eof_handler := leave);
  end;

  if s = '' then writeln('No changes.')
  else begin
     ok := true;
     if lookup_level(lev,s) then exp := leveltable[lev].exp
     else if not isnum(s) then begin
        writeln('No such level or experience.');
        ok := false;
     end else begin 
        exp := number(s);
        if (exp < 0) or (exp > maxexperience) then begin
           writeln('Out of range.');
           ok := false;
        end;
     end;

     getint(N_EXPERIENCE);
     freeint;
     prevlevel := level(anint.int[n]);
     nextlevel := level(exp);
     if ok and (leveltable[prevlevel].hidden or leveltable[nextlevel].hidden) 
         and (userid <> MM_userid) then begin
            writeln('Only Monster Manager can make this change.');
            ok := false;
     end;

     if ok then begin
        getint(N_PRIVILEGES);
        freeint;
        prevpriv := uint(anint.int[n]);
        
        nextpriv := 0;
        for i := 1 to nextlevel do nextpriv := uor(nextpriv,
            leveltable[i].priv);

        getint(N_PRIVILEGES);
        anint.int[n] := int(nextpriv);
        putint;

        if (prevpriv <> nextpriv) then begin
           write('Privileges changed from: '); list_privileges(int(prevpriv));
           write('to:                      '); list_privileges(int(nextpriv));
        end;

	if (prevlevel <> nextlevel) then begin
	    getint(N_HEALTH);
	    anint.int[n] := leveltable[nextlevel].health * 7 div 10;
	    putint;
	    writeln('Health database updated.');
	end;

        getint(N_EXPERIENCE);
        anint.int[n] := exp;
        putint;
        writeln('Experience database updated.');
     end;
  end;
  exit_label:
end; { fix_p_level }

procedure fix_p_view(n: integer);
var exp,lev: integer;
begin
   getpers;
   freepers;
   getuser;
   freeuser;
   writeln('Player''s personal name : ',pers.idents[n]);
   writeln('         userident     : ',user.idents[n]);
   getint(N_EXPERIENCE);
   freeint;
   writeln('         experience    : ',anint.int[n]:1);
   writeln('         level         : ',leveltable[level(anint.int[n])].name);
   getint(N_HEALTH);
   freeint;
   writeln('         health        : ',anint.int[n]:1);
   getint(N_PRIVILEGES);
   freeint;
   write  ('         privileges    : '); list_privileges(anint.int[n]);
   writeln('         room quota    : ',get_counter(N_ALLOW,n):1);
   writeln('         rooms         : ',get_counter(N_NUMROOMS,n):1);
   writeln('         accepts       : ',get_counter(N_ACCEPT,n):1);
end; { fix_p_view }

procedure fix_stuff(s: string);
label exit_label;
var player_id: integer;
    param,raw: string;

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;

begin
  if s = '' then grab_line('Player''s (user)name? ',s,
    eof_handler := leave);
  if (s = '') or (s = '?') then 
     writeln('To customize player data in database, type 1 <player''s name>')
  else if not lookup_user(player_id,s,true) then
     writeln ('No such player name.')
  else begin
     getindex(I_ASLEEP);
     freeindex;
     if s[1] = ':' then
        writeln('That isn''t player.')
     else if not indx.free[player_id] then
        writeln('This player playing now.')
     else repeat
        grab_line('Custom player> ',s,eof_handler := leave);

        raw := slead(s); if bite(raw) > '' then;

        param := slead(lowcase(s));
        s := bite(param);

        if s = '' then writeln ('Type ? for help.')
        else case s[1] of
          '?','h' : command_help('*fix p help*');
          'a'     : fix_p_health(player_id,param);
          'l'     : fix_p_level(player_id,param);
          'v'     : fix_p_view(player_id);
          'p'     : fix_p_passwd(player_id,raw);
	  'r'	  : fix_p_quota(player_id,param);
          'n'     : fix_p_pers(player_id,raw);
          'e','q' : ;
          otherwise writeln ('Type ? for help.');
        end
     until (s = 'e') or ( s = 'q');
  end;
  exit_label:
end; 

procedure system_2(s: string); forward;


procedure throw_player(s: string); forward;

function complete(s: string; n: integer): string;
begin
   while length(s) < n do s := s + ' ';
   complete := s
end;

procedure system_who;
label 1;
var i,count: integer;
    more: string;

    procedure leave;
    begin
	writeln('EXIT');
	goto 1;
    end;

begin
    getindex(I_PLAYER);	{ Rec of valid player log records  }
    freeindex;		{ False if a valid player log }

    getpers;		{ player names }
    freepers;

    getuser;		{ userids }
    freeuser;

    getreal_user;	{ real userids for virtual userid }
    freereal_user;

    getint(N_EXPERIENCE);
    freeint;

    write(complete('Username',15));
    write(complete('Real userid',15));
    write(complete('Personal name',20));
    writeln ('Level');

             
    count := 1;
    for i := 1 to indx.top do if not indx.free[i] then begin
	if user.idents[i][1] <> ':' then begin
	    write(complete(user.idents[i],15));
	    if user.idents[i][1] = '"' then 
		write(complete(real_user.idents[i],15))
	    else
		write(complete('',15));
	    write(complete(pers.idents[i],20));
	    writeln(leveltable[level(anint.int[i])].name);
	    count := count +1;
	    if count > terminal_page_len -2 then begin
		grab_line('-more-',more,erase := true,
		    eof_handler := leave);
		if more > '' then goto 1;
		count := 0;
	    end;
	end;
    end;
    1:
end;

procedure do_system(s: string);
var
	prompt: string;
	done: boolean;
	cmd: char;
	n: integer;
	p: string;

    procedure leave;
    begin
	writeln('EXIT');
	s := 'e';
    end;

begin
	if (manager_priv) or (wizard { and privd }) then begin { minor change by leino@finuha }
		log_action(c_system,0);
		prompt := 'System> ';
		done := false;
		repeat
			repeat
				grab_line(prompt,s,eof_handler := leave);
				s := slead(s);
			until length(s) > 0;
			s := lowcase(s);
			cmd := s[1];

			n := 0;
			p := '';
			if length(s) > 1 then begin
				p := slead( substr(s,2,length(s)-1) );
				n := number(p)
			end;
			if debug then begin
		       		writeln('p = ',p);
			end;
       
			case cmd of
	  			'?': command_help('*system help*');
	  			'1': fix_stuff(p);
  				'a': authorize(p); { leino@finuha }
{remove a user}			'k': kill_user(p);
				'c': system_2(p);
{disown}			'd': disown_user(p);
{dist list of players}		'p': dist_list;
{move where user will wakeup}	'm': move_asleep (p);
{add rooms}			'r': begin
	  				if n > 0 then begin
						addrooms(n);
					end else
						writeln('To add rooms, say R <# to add>');
				     end;
{add ints}	   {		'i': begin
					if n > 0 then begin
						addints(n);
					end else
						writeln('To add integers, say I <# to add>');
				     end;	}
{add description blocks}	'b': begin
					if n > 0 then begin
						addblocks(n);
					end else
						writeln('To add description blocks, say B <# to add>');
				     end;
{add objects}			'o': begin
					if n > 0 then begin
						addobjects(n);
					end else
						writeln('To add object records, say O <# to add>');
				     end;
{add one-liners}		'l': begin
					if n > 0 then begin
						addlines(n);
					end else
						writeln('To add one liner records, say L <# to add>');
	  			     end;
{add header records }		'h': begin
					if n > 0 then begin
						addheaders(n)
					end else 
						writeln('To add header records, say H <# to add>.');
                                     end;
{view current stats}		'v': begin
					system_view;
				     end;
				't': begin
					throw_player(p);
				     end;
				'w': system_who;
{quit}				'q','e': done := true;
			otherwise writeln('-- bad command, type ? for a list.');
			end;
		until done;
		log_event(myslot,E_SYSDONE,0,0);
	end else
		writeln('Only the Monster Manager may enter system maintenance mode.');
end;


procedure do_version(s: string);
begin
	monster_version;
end;



procedure do_score(s: string);
label 1; { for out }
var n: integer;
    header_printed: boolean;
    print_count: integer;
    short_line: boolean;

    sort_table : array [ 1 .. maxplayers ] of 0 .. maxplayers;
    used : 0 .. maxplayers;

    scorerec: intrec;

    procedure sort_score;
    var i,j,sco,loc: integer;
	break: boolean;
    begin
	used := 0;
	for i := 1 to indx.top do if not indx.free[i] then 
	    if user.idents[i] > '' then if user.idents[i][1] <> ':' then begin
		sco := scorerec.int[i];
		loc := 1;
		break := false;
		while ( loc < used ) and not break do begin
		    if scorerec.int[sort_table[loc]] >= sco then break := true
		    else loc := loc +1;
		end;
		for j := used downto loc do sort_table[j+1] := sort_table[j];
		used := used +1;
		sort_table[loc] := i;
	    end;
    end; { sort_score }      

    procedure leave;
    begin
	writeln('EXIT');
	goto 1;
    end;

   procedure write_line(i: integer);
   var s: string;
       c: char;
   begin
      if not header_printed then begin
         if not short_line then write('  Level                 ');
	 writeln('Name                   Score');
         header_printed := true;         
      end;          
      if scorerec.int[i] > protect_exp then c := '*'
      else c := ' ';
      if not short_line then 
	write(c,' ',complete(leveltable[level(scorerec.int[i])].name,22));
      write(complete(pers.idents[i],20));
      if scorerec.int[i] > maxexperience then writeln('-':8)
      else writeln(scorerec.int[i]:8);
      print_count := print_count +1;
      if print_count > terminal_page_len -2 then begin
	    grab_line('-more-',s,erase := true,eof_handler := leave);
	    if s > '' then goto 1;
	    print_count := 0;
      end;
   end;

   procedure write_level(l: integer);
   var i,j : integer;
   begin
      for j := used downto 1 do begin
	i := sort_table[j];
        if (level(scorerec.int[i]) = l) and (user.idents[i][1] <> ':') then
           write_line(i);
      end;
   end;

begin
  short_line := terminal_line_len < 54;
  print_count := 0;
  header_printed := false;
  getint(N_EXPERIENCE); freeint; scorerec := anint;
  getuser;
  freeuser;
  if s = '?' then begin
    command_help('score');
  end else if s = '' then begin
      getpers;
      freepers;
      write_line(mylog);
   end else if (s = '*') or (s = 'all') then begin
      getpers;
      freepers;
      getindex(I_PLAYER);
      freeindex;
      sort_score;
      for n := used downto 1 do write_line(sort_table[n]);
   end else if length(s) > shortlen then 
      writeln('Limit name and level to ',shortlen:1,' characters.')
   else if lookup_pers(n,s) then
      write_line(n)
   else if lookup_level(n,s) then begin
      sort_score;
      write_level(n);
      if not header_printed then writeln('No players on this level.')
   end else writeln('No such player or level.');
   1:
end;


{ REBUILD moved to MONSTER_REBUILD.PAS }

{ FIX moved to MONSTER_REBUILD.PAS }

{ put an object in this location
  if returns false, there were no more free object slots here:
  in other words, the room is too cluttered, and cannot hold any
  more objects
}
function place_obj(n: integer;silent:boolean := false): boolean;
var
	found: boolean;
	i: integer;
begin
	if here.objdrop = 0 then getroom
	else getroom(here.objdrop);
	i := 1;
	found := false;
	while (i <= maxobjs) and (not found) do begin
		if here.objs[i] = 0 then found := true
		else i := i + 1;
	end;
	place_obj := found;
	if found then begin
		here.objs[i] := n;
		here.objhide[i] := 0;
		putroom;

		gethere;


		{ if it bounced somewhere else then tell them }

		if (here.objdrop <> 0) and (here.objdest <> 0) then
			log_event(0,E_BOUNCEDIN,here.objdest,n,'',here.objdrop);


		if not(silent) then begin
			if here.objdesc <> 0 then
				print_subs(here.objdesc,obj_part(n))
			else
				writeln('Dropped ',obj_part(n),'.');
		end;
	end else
		freeroom;
end;


{ remove an object from this room }
function take_obj(objnum,slot: integer): boolean;
begin
	getroom;
	if here.objs[slot] = objnum then begin
		here.objs[slot] := 0;
		here.objhide[slot] := 0;
		take_obj := true;
	end else
		take_obj := false;
	putroom;
end;


function can_hold: boolean;

begin
	if find_numhold < maxhold then
		can_hold := true
	else
		can_hold := false;
end;


function can_drop: boolean;

begin
	if find_numobjs < maxobjs then
		can_drop := true
	else
		can_drop := false;
end;


function find_hold(objnum: integer;slot:integer := 0): integer;
var
	i: integer;

begin
	if slot = 0 then
		slot := myslot;
	i := 1;
	find_hold := 0;
	while i <= maxhold do begin
		if here.people[slot].holding[i] = objnum then
			find_hold := i;
		i := i + 1;
	end;
end;



{ put object number n into the player's inventory; returns false if
  he's holding too many things to carry another }

function hold_obj(n: integer): boolean;
var
	found: boolean;
	i: integer;

begin
	getroom;
	i := 1;
	found := false;
	while (i <= maxhold) and (not found) do begin
		if here.people[myslot].holding[i] = 0 then
			found := true
		else
			i := i + 1;
	end;
	hold_obj := found;
	if found then begin
		here.people[myslot].holding[i] := n;
		putroom;

		getobj(n);
		freeobj;
		hold_kind[i] := obj.kind;
	end else
		freeroom;
end;



{ remove an object (hold) from the player record, given the slot that
  the object is being held in }

procedure drop_obj(slot: integer;pslot: integer := 0);

begin
	if pslot = 0 then
		pslot := myslot;
	getroom;
	here.people[pslot].holding[slot] := 0;
	putroom;

	hold_kind[slot] := 0;
end;



{ maybe drop something I'm holding if I'm hit }

procedure maybe_drop;
var
	i: integer;
	objnum: integer;
	s: string;

begin
	i := 1 + (rnd100 mod maxhold);
	objnum := here.people[myslot].holding[i];

	if (objnum <> 0) and (mywield <> objnum) and (mywear <> objnum) then begin
		{ drop something }

		drop_obj(i);
		if place_obj(objnum,TRUE) then begin
		    getobj(objnum);
		    freeobj;

		    writeln('The ',obj.oname,' has slipped out of your hands.');
			
		    log_event(myslot,E_SLIPPED,0,0,obj.oname);

		    if obj.actindx > 0 then
			run_monster('',obj.actindx,'drop you','','',
			    sysdate+' '+systime);

		end else
		    writeln('%error in maybe_drop; unsuccessful place_obj; notify Monster Manager');

	end;
end;

{ function obj_owner moved to module CUSTOM }

procedure do_duplicate(s: string);
label 0; { for panic }
var
	objnum,oldloc: integer;

    function action(s: shortstring; objnum: integer): boolean;
    begin
	if obj_owner(objnum,TRUE) then begin
	    if not(place_obj(objnum,TRUE)) then begin
			{ put the new object here }
		writeln('There isn''t enough room here to make that.');
		goto 0; { leave loop }
	    end else begin
{ keep track of how many there }	getobj(objnum);
{ are in existence }			obj.numexist := obj.numexist + 1;
					putobj;

		log_event(myslot,E_MADEOBJ,0,0,log_name + ' has created an object here.');
		writeln('Object ',s,' created.');
	    end;
	end else
	    writeln('Power to create ',s,' belongs to someone else.');
	action := true;
	checkevents(true);
	if oldloc <> location then goto 0; { panic }
    end;
    
    function restriction (n: integer): boolean;
	begin
		restriction := true;
	end;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto 0;
    end;


begin
    if s = '' then grab_line('Object? ',s,eof_handler := leave);
    oldloc := location;
    if length(s) > 0 then begin
	if not is_owner(location,TRUE) then begin
	    { only let them make things if they're on their home turf }
	    writeln('You may only create objects when you are in one of your own rooms.');
	end else begin
	    if scan_obj(action,s,,restriction) then begin
	    end else
		writeln('There is no object by that name.');
	end;
   end else
	writeln('To duplicate an object, type DUPLICATE <object name>.');
    0: { for panic }
end;


{ make an object }
procedure do_makeobj(s: string);
label exit_label;
var
	objnum: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


begin
	if s = '' then grab_line('Object? ',s,eof_handler := leave);

	gethere;
	if checkhide then begin
	if not is_owner(location,TRUE) then begin
		writeln('You may only create objects when you are in one of your own rooms.');
	end else if s <> '' then begin
		if length(s) > shortlen then
			writeln('Please limit your object names to ',shortlen:1,' characters.')
		else if exact_obj(objnum,s) then begin	{ object already exits }
			writeln('That object already exits.  If you would like to make another copy of it,');
			writeln('use the DUPLICATE command.');
		end else begin
			if debug then
				writeln('%beggining to create object');
			if find_numobjs < maxobjs then begin
				if alloc_obj(objnum) then begin
					if debug then
						writeln('%alloc_obj successful');
					getobjnam;
					objnam.idents[objnum] := lowcase(s);
					putobjnam;
					if debug then
						writeln('%getobjnam completed');
					getobjown;
					objown.idents[objnum] := userid;
					putobjown;
					if debug then
						writeln('%getobjown completed');

					getobj(objnum);
						obj.onum := objnum;
						obj.oname := s;	{ name of object }
						obj.kind := 0; { bland object }
						obj.linedesc := DEFAULT_LINE;
						obj.actindx := 0;
						obj.examine := 0;
						obj.numexist := 1;
						obj.home := 0;
						obj.homedesc := 0;

						obj.sticky := false;
						obj.getobjreq := 0;
						obj.getfail := 0;
						obj.getsuccess := DEFAULT_LINE;

						obj.useobjreq := 0;
						obj.uselocreq := 0;
						obj.usefail := DEFAULT_LINE;
						obj.usesuccess := DEFAULT_LINE;

						obj.usealias := '';
						obj.reqalias := false;
						obj.reqverb := false;

			if s[1] in ['a','A','e','E','i','I','o','O','u','U'] then
						obj.particle := 2  { an }
			else
						obj.particle := 1; { a }

						obj.d1 := 0;
						obj.d2 := 0;
						obj.ap := 0;
						obj.exreq := 0;

						obj.exp5 := DEFAULT_LINE;
						obj.exp6 := DEFAULT_LINE;
					putobj;


					if debug then
						writeln('putobj completed');
				end;
					{ else: alloc_obj prints errors by itself }
				if not(place_obj(objnum,TRUE)) then
					{ put the new object here }
					writeln('%error in makeobj - could not place object; notify the Monster Manager.')
				else begin
					log_event(myslot,E_MADEOBJ,0,0,
						log_name + ' has created an object here.');
					writeln('Object created.');
				end;

			end else
				writeln('This place is too crowded to create any more objects.  Try somewhere else.');
		end;
	end else
		writeln('To create an object, type MAKE <object name>.');
	end;
    exit_label:
end;

procedure do_summon(s: string);
label exit_label;
var
	n: integer;
	sname: string;
	vname: string;

	sid: integer;
	vslot: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	if s = '' then grab_line('Spell? ',s,eof_handler := leave);
	sname := s;
	grab_line('Victim? ',s,eof_handler := leave);
	vname := s;

	if not lookup_spell(sid,sname) then writeln('Unkown spell.')
	else if not parse_pers(vslot,vname) then writeln('Victim isn''t here.')
	else begin
	    getspell(mylog);
	    freespell;
	    if spell.level[sid] = 0 then writeln('Unkown spell.')
	    else if vslot = myslot then begin
		writeln('Spell summoned.');
		log_event(myslot,E_SUMMON,vslot,sid);
		getint(N_SPELL);
		freeint;
		getspell_name;
		freespell_name;
		run_monster('',anint.int[sid],
		    'summon', '','',sysdate + ' ' + systime,
		    spell_name.idents[sid], here.people[myslot].name);
	    end else begin
		log_event(myslot,E_SUMMON,vslot,sid);
		writeln('Spell summoned.');
	    end;
	end;
    exit_label:
end;

{ remove the type block for an object; all instances of the object must
  be destroyed first }

procedure do_unmake(s: string);
label exit_label;
var
	n: integer;
	tmp: string;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	if s = '' then grab_line('Object? ',s,eof_handler := leave);

	if not(is_owner(location,TRUE)) then
		writeln('You must be in one of your own rooms to UNMAKE an object.')
	else if lookup_obj(n,s,true) then begin
		tmp := obj_part(n);
			{ this will do a getobj(n) for us }

		if obj.numexist = 0 then begin
			delete_obj(n);
                        delete_line(obj.linedesc);
                        delete_block(obj.homedesc);
			delete_block(obj.examine);
                        delete_block(obj.getfail);
                        delete_block(obj.getsuccess);
			delete_block(obj.usefail);
			delete_block(obj.usesuccess);
                        delete_block(obj.d1);
                        delete_block(obj.d2);
			if obj.actindx > 0 then begin { delete hook (hurtta@finuh) }
				delete_program(obj.actindx);
				delete_general(I_HEADER,obj.actindx);
			end;

			log_event(myslot,E_UNMAKE,0,0,tmp);
			writeln('Object removed.');
		end else
			writeln('You must DESTROY all instances of the object first.');
	end else
		writeln('There is no object here by that name.');
    exit_label:
end;



{ destroy a copy of an object }

procedure do_destroy(s: string);
label 0;    { for panic }
var
	slot,n,oldloc: integer;
	pub: shortstring;

    function action(s: shortstring; n: integer): boolean;
    begin
	getobjown;
	freeobjown;
	if (objown.idents[n] <> userid) and (objown.idents[n] <> public_id) and
       (not owner_priv) then begin { minor change by leino@finuha }
	    writeln('You must be the owner of ',s,' or');
	    writeln(s,' must be public to destroy it.');
	    action := true;
	end else if obj_hold(n) then begin
	    if mywear = n then x_unwear;
	    if mywield = n then x_unwield;

	    slot := find_hold(n);
	    drop_obj(slot);

	    log_event(myslot,E_DESTROY,0,0,
		log_name + ' has destroyed ' + obj_part(n) + '.');
	    writeln('Object destroyed.');

	    getobj(n);
	    obj.numexist := obj.numexist - 1;
	    putobj;
	    action := true;
	end else if obj_here(n) then begin
	    slot := find_obj(n);
	    if not take_obj(n,slot) then
		writeln('Someone picked ',s,' up before you could destroy it.')
	    else begin
		log_event(myslot,E_DESTROY,0,0,
		log_name + ' has destroyed ' + obj_part(n,FALSE) + '.');
		writeln('Object ',s,', destroyed.');

		getobj(n);
		obj.numexist := obj.numexist - 1;
		putobj;
	    end;
	    action := true;
	end else action := false;
	checkevents(TRUE);
	if location <> oldloc then goto 0;  { panic }
    end; { action }

    function restriction (n: integer): boolean;
	begin
	    restriction := obj_here(n,true) or obj_hold(n);
	    { true = not found hidden objects }
	end;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto 0;
    end;

begin
	if s = '' then grab_line('Object? ',s,eof_handler := leave);

	oldloc := location;
	if length(s) = 0 then	
		writeln('To destroy an object you own, type DESTROY <object>.')
	else if not is_owner(location,TRUE) then
		writeln('You must be in one of your own rooms to destroy an object.')
	else if scan_obj(action,s,,restriction) then begin
	end else
		writeln('No such thing can be seen here.');
	0: { for panic }
end;


function links_possible: boolean;
var
	i: integer;

begin
	gethere;
	links_possible := false;
	if is_owner(location,TRUE) then
		links_possible := true
	else begin
		for i := 1 to maxexit do
			if (here.exits[i].toloc = 0) and (here.exits[i].kind = 5) then
				links_possible := true;
	end;
end;



{ make a room }
procedure do_form(s: string);
label exit_label;
    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	gethere;
	if checkhide then begin
		if (get_counter(N_NUMROOMS,mylog) 
		    >= get_counter(N_ALLOW,mylog))
		    and not quota_priv then begin
		    writeln('Yow haven''t room quota left.');
		    writeln('Use SHOW QUOTA to check limits.');
		end else if (get_counter(N_NUMROOMS,mylog) >= min_room) and 
			(get_counter(N_ACCEPT,mylog) < min_accept) and
			not quota_priv then begin
		    writeln('You haven''t made Accepts enaugh.');
		    writeln('Use SHOW QUOTA to check limits.');

		end else if links_possible then begin
			if s = '' then begin
				grab_line('Room name? ',s,eof_handler := leave);
			end;
			s := slead(s);

			createroom(s);

		end else begin
			writeln('You may not create any new exits here.  Go to a place where you can create');
			writeln('an exit before FORMing a new room.');
		end;
	end;
    exit_label:
end;





procedure xpoof; { loc: integer; forward }
label 0; { panic }
var
	targslot: integer;
	oldloc: integer;
	prevcode: integer;

begin
	getnam;		{ rooms' names }
	freenam;

	oldloc := location;
	prevcode := here.hook;
        if here.hook > 0 then
           run_monster('',here.hook,'poof out','target',nam.idents[loc],
               sysdate+' '+systime);

        if oldloc = location then meta_run('leave','target',nam.idents[loc]);

	if put_token(loc,targslot,here.people[myslot].hiding) then begin
		if hiding then begin
			log_event(myslot,E_HPOOFOUT,0,0,log_name,location);
			log_event(myslot,E_HPOOFIN,0,0,log_name,loc);
		end else begin
			log_event(myslot,E_POOFOUT,0,0,log_name,location);
			log_event(targslot,E_POOFIN,0,0,log_name,loc);
		end;

		take_token(myslot,location);
		myslot := targslot;
		location := loc;
		setevent;

		{ one trap }
                oldloc := location;		
		if prevcode > 0 then 
		    run_monster('',prevcode,'escaped','','',
			sysdate+' '+systime);
		if oldloc <> location then goto 0; { panic }

		do_look; if oldloc <> location then goto 0;
  
              if here.hook > 0 then
			run_monster('',here.hook,'poof in','','',
				sysdate+' '+systime);

		if location = oldloc then meta_run('enter','','');

	end else
		writeln('There is a crackle of electricity, but the poof fails.');
	0: { for panic }
end;

procedure poof_monster(n: integer; s: string); forward;

procedure poof_other(n: integer);
label exit_label;
var
	loc: integer;
	s: string;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	if not protected(n) then begin
		grab_line('What room? ',s,eof_handler := leave);
		if here.people[n].kind <> P_PLAYER then 
		    if here.people[n].kind = P_MONSTER then
			poof_monster(n,s)
		    else writeln('%error in poof_other.')
		else if protected(n) then writeln ('You can''t poof ',here.people[n].name,' now.')
		    {   !!! necessary double checking !! }
		else if lookup_room(loc,s) then begin
			log_event(myslot,E_POOFYOU,n,loc);
			writeln;
			writeln('You extend your arms, muster some energy, and ',here.people[n].name,' is');
			writeln('engulfed in a cloud of orange smoke.');
			writeln;
		end else
			writeln('There is no room named ',s,'.');
	end else writeln ('You can''t poof ',here.people[n].name,' now.');
    exit_label:
end;

procedure do_poof(s: string);
label exit_label;
var
	n,loc: integer;
        sown,town: veryshortstring;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	if poof_priv then begin { minor change by leino@finuha }
		gethere;
		if ((lookup_room(loc,s) and parse_pers(n,s)) or (s='')) then begin
			grab_line('Poof who? (<RETURN> for yourself) ',s,
			    eof_handler := leave);
			if s='' then begin
				grab_line('What room? ',s,
					eof_handler := leave);
				if lookup_room(loc,s) then
					xpoof(loc);
			end else if parse_pers(n,s) then
					poof_other(n)
				else
					writeln('I can see no-one named ',s,' here.');
		end else if lookup_room(loc,s) then
			xpoof(loc)
		else if parse_pers(n,s) then
			poof_other(n)
		else
			writeln('There is no room named ',s,'.');

	end else begin { unprivileged poof (hurtta@finuh) }
            gethere;
            sown := here.owner;
            if s = '' then grab_line('What room? ',s,eof_handler := leave);
            if (s = '') or (s='?') then command_help('poof')
            else if lookup_room(loc,s) then begin
              gethere(loc);
              town := here.owner;
              if (sown <> userid) or (town <> userid) then
                 writeln ('Only Monster Manager may poof in other people''s rooms.')
              else xpoof(loc);
            end else writeln ('No such room');
	end;	
    exit_label:
end;



procedure link_room(origdir,targdir,targroom: integer);
var owner: integer;
begin
	{ since exit creation involves the writing of two records,
	  perhaps there should be a global lock around this code,
	  such as a get to some obscure index field or something.
	  I haven't put this in because I don't believe that if this
	  routine fails it will seriously damage the database.

	  Actually, the lock should be on the test (do_link) but that
	  would be hard	}

	getroom;
	with here.exits[origdir] do begin

		if (kind = 5) and exact_user(owner,here.owner) then
		    sub_counter(N_ACCEPT,owner);

		toloc := targroom;
		kind := 1; { type of exit, they can customize later }
		slot := targdir; { exit it comes out in in target room }

		init_exit(origdir);
	end;
	putroom;

	log_event(myslot,E_NEWEXIT,0,0,log_name,location);
	if location <> targroom then
		log_event(0,E_NEWEXIT,0,0,log_name,targroom);

	getroom(targroom);
	with here.exits[targdir] do begin

		if (kind = 5) and exact_user(owner,here.owner) then
		    sub_counter(N_ACCEPT,owner);

		toloc := location;
		kind := 1;
		slot := origdir;

		init_exit(targdir);
	end;
	putroom;
	writeln('Exit created.  Use CUSTOM ',direct[origdir],' to customize your exit.');
end;


{
User procedure to link a room
}
procedure do_link(s: string);
label exit_label;
var
	ok: boolean;
	orgexitnam,targnam,trgexitnam: string;
	targroom,	{ number of target room }
	targdir,	{ number of target exit direction }
	origdir: integer;{ number of exit direction here }
	firsttime: boolean;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


begin

{	gethere;	! done in links_possible }

   if links_possible then begin
	log_action(link,0);
	if checkhide then begin
	writeln('Hit return alone at any prompt to terminate exit creation.');
	writeln;

	if s = '' then
		firsttime := false
	else begin
		orgexitnam := bite(s);
		firsttime := true;
	end;

	repeat
		if not(firsttime) then
			grab_line('Direction of exit? ',orgexitnam,
				eof_handler := leave)
		else
			firsttime := false;

		ok :=lookup_dir(origdir,orgexitnam,true);
		if ok then
			ok := can_make(origdir);
	until (orgexitnam = '') or ok;

	if ok then begin
		if s = '' then
			firsttime := false
		else begin
			targnam := s;
			firsttime := true;
		end;

		repeat
			if not(firsttime) then
				grab_line('Room to link to? ',targnam,
				    eof_handler := leave)
			else
				firsttime := false;

			ok := lookup_room(targroom,targnam,true);
		until (targnam = '') or ok;
	end;

	if ok then begin
		repeat
			writeln('Exit comes out in target room');
			grab_line('from what direction? ',trgexitnam,
				eof_handler := leave);
			ok := lookup_dir(targdir,trgexitnam,true);
			if ok then
				ok := can_make(targdir,targroom);
		until (trgexitnam='') or ok;
	end;

	if ok then begin { actually create the exit }
		link_room(origdir,targdir,targroom);
	end;
	end;
   end else
	writeln('No links are possible here.');
    exit_label:
end;


procedure relink_room(origdir,targdir,targroom: integer);
var
	tmp: exit;
	copyslot,
	copyloc,owner: integer;

begin
	gethere;
	tmp := here.exits[origdir];
	copyloc := tmp.toloc;
	copyslot := tmp.slot;

	getroom(targroom);
	here.exits[targdir] := tmp;
	putroom;

	getroom(copyloc);
	here.exits[copyslot].toloc := targroom;
	here.exits[copyslot].slot := targdir;
	putroom;

	getroom;
	here.exits[origdir].toloc := 0;
	init_exit(origdir);
	putroom;
end;


procedure do_relink(s: string);
label exit_label;
var
	ok: boolean;
	orgexitnam,targnam,trgexitnam: string;
	targroom,	{ number of target room }
	targdir,	{ number of target exit direction }
	origdir: integer;{ number of exit direction here }
	firsttime: boolean;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	log_action(c_relink,0);
	gethere;
	if checkhide then begin
	writeln('Hit return alone at any prompt to terminate exit relinking.');
	writeln;

	if s = '' then
		firsttime := false
	else begin
		orgexitnam := bite(s);
		firsttime := true;
	end;

	repeat
		if not(firsttime) then
			grab_line('Direction of exit to relink? ',orgexitnam,
			    eof_handler := leave)
		else
			firsttime := false;

		ok :=lookup_dir(origdir,orgexitnam,true);
		if ok then
			ok := can_alter(origdir);
	until (orgexitnam = '') or ok;

	if ok then begin
		if s = '' then
			firsttime := false
		else begin
			targnam := s;
			firsttime := true;
		end;

		repeat
			if not(firsttime) then
				grab_line('Room to relink exit into? ',targnam,
				    eof_handler := leave)
			else
				firsttime := false;

			ok := lookup_room(targroom,targnam,true);
		until (targnam = '') or ok;
	end;

	if ok then begin
		repeat
			writeln('New exit comes out in target room');
			grab_line('from what direction? ',trgexitnam,
			    eof_handler := leave);
			ok := lookup_dir(targdir,trgexitnam,true);
			if ok then
				ok := can_make(targdir,targroom);
		until (trgexitnam='') or ok;
	end;

	if ok then begin { actually create the exit }
		relink_room(origdir,targdir,targroom);
	end;
	end;
    exit_label:
end;


{ print the room default no-go message if there is one;
  otherwise supply the generic "you can't do that." }

procedure default_fail;

begin
	if (here.exitfail <> 0) and (here.exitfail <> DEFAULT_LINE) then
		print_desc(here.exitfail)
	else
		writeln('You can''t do that.');
end;

procedure  exit_fail(dir: integer);
var
	tmp: string;

begin
	if (dir < 1) or (dir > maxexit) then
		default_fail
	else if (here.exits[dir].fail = DEFAULT_LINE) then begin
		case here.exits[dir].kind of
			5: writeln('There isn''t an exit there yet.');
			6: writeln('You don''t have the power to go there.');
			otherwise default_fail;
		end;
	end else if here.exits[dir].fail <> 0 then
		block_subs(here.exits[dir].fail,myname);


{ now print the exit failure message for everyone else in the room:
	if they tried to go through a valid exit,
	  and the exit has an other-person failure desc, then
		substitute that one & use;

	if there is a room default other-person failure desc, then
		print that;

	if they tried to go through a valid exit,
	  and the exit has no required alias, then
		print default exit fail
	else
		print generic "didn't leave room" message

cases:
1) valid/alias exit and specific fail message
2) valid/alias exit and blanket fail message
3) valid exit (no specific or blanket) "x fails to go [direct]"
4) alias exit and blanket fail
5) blanket fail
6) generic fail
}

	if dir <> 0 then
		log_event(myslot,E_FAILGO,dir,0);
end;



procedure do_exit; { (exit_slot: integer)-- declared forward }
label	0;
var
	orig_slot,
	targ_slot,
	orig_room,
	enter_slot,
	targ_room,
	old_loc,prevcode: integer;
	doalook: boolean;

begin
	getnam;		{ rooms' names }
	freenam;

	if (exit_slot < 1) or (exit_slot > 6) then
		exit_fail(exit_slot)
	else if here.exits[exit_slot].toloc > 0 then begin

		orig_slot := myslot;
		orig_room := location;
		targ_room := here.exits[exit_slot].toloc;
		enter_slot := here.exits[exit_slot].slot;
		doalook := here.exits[exit_slot].autolook;

		old_loc := location;
		prevcode := here.hook;
		if here.hook > 0 then
			run_monster('',here.hook,'leave',
				'target',nam.idents[targ_room],
				sysdate+' '+systime);
		if old_loc = location then meta_run('leave',
				'target',nam.idents[targ_room]);
		if old_loc = location then meta_run_2('leave',
				'target',nam.idents[targ_room]);
		if location <> old_loc then begin
			{ writeln ('You must interrupt walking.'); }
			goto 0
		end;

		block_subs(here.exits[exit_slot].success,myname);
                
				{ optimization for exit that goes nowhere;
				  why go nowhere?  For special effects, we
				  don't want it to take too much time,
				  the logs are important because they force the
				  exit descriptions, but actually moving the
				  player is unnecessary }

		if orig_room = targ_room then begin
			log_exit(exit_slot,orig_room,orig_slot);
			log_entry(enter_slot,targ_room,orig_slot);
				{ orig_slot in log_entry 'cause we're not
				  really going anwhere }
			old_loc := location;
			if doalook then
				do_look;
			if here.hook > 0 then
				run_monster('',here.hook,'enter','','',
					sysdate+' '+systime);
			if old_loc = location then meta_run('enter','','');
			if old_loc = location then meta_run_2('enter','','');
		end else begin
			take_token(orig_slot,orig_room);
			if not put_token(targ_room,targ_slot) then begin
					{ no room in room! }
{ put them back! Quick! }	if not put_token(orig_room,myslot) then begin
					writeln('%Oh no!');
					halt;
				end;
			end else begin
				log_exit(exit_slot,orig_room,orig_slot);
				log_entry(enter_slot,targ_room,targ_slot);

				myslot := targ_slot;
				{ one trap }
				location := targ_room;
				old_loc := location;
				setevent;

				if prevcode > 0 then 
				    run_monster('',prevcode,'escaped','','',
				    sysdate+' '+systime);
				if old_loc <> location then goto 0; { panic }

				if doalook then
					do_look;
				if old_loc <> location then goto 0;

				if here.hook > 0 then
					run_monster('',here.hook,'enter',
						'','',
       						sysdate+' '+systime);
				if old_loc = location then meta_run('enter','','');
                                if old_loc = location then meta_run_2('enter','','');

			end;
		end;
	end else
	  	exit_fail(exit_slot);
	0: { if monster (NPC) trow player to somewhere }
end;



function cycle_open: boolean;
var
	ch: char;
	s: string;

begin
	s := systime;
	ch := s[5];
	if ch in ['1','3','5','7','9'] then
		cycle_open := true
	else
		cycle_open := false;                    
end;


function which_dir(var dir:integer;s: string): boolean;
var
	aliasdir, exitdir: integer;
	aliasmatch,exitmatch,
	aliasexact,exitexact: boolean;
	exitreq: boolean;

begin
	s := lowcase(s);
	if lookup_alias(aliasdir,s) then
		aliasmatch := true
	else
		aliasmatch := false;
	if lookup_dir(exitdir,s) then
		exitmatch := true
	else
		exitmatch := false;
	if aliasmatch then begin
		if s = here.exits[aliasdir].alias then
			aliasexact := true
		else
			aliasexact := false;
	end else
		aliasexact := false;
	if exitmatch then begin
		if (s = direct[exitdir]) or (s = substr(direct[exitdir],1,1)) then
			exitexact := true
		else
			exitexact := false;
	end else
		exitexact := false;
	if exitmatch then
		exitreq := here.exits[exitdir].reqalias
	else
		exitreq := false;

	dir := 0;
	which_dir := true;
	if aliasexact and exitexact then
		dir := aliasdir
	else if aliasexact then
		dir := aliasdir
	else if exitexact and not exitreq then
		dir := exitdir
	else if aliasmatch then
		dir := aliasdir
	else if exitmatch and not exitreq then
		dir := exitdir
	else if exitmatch and exitreq then begin
		dir := exitdir;
		which_dir := false;
	end else begin
		which_dir := false;
	end;
end;


procedure exit_case(dir: integer);

begin
	case here.exits[dir].kind of
		0: exit_fail(dir);
		1: do_exit(dir);  { more checking goes here }

		3: if obj_hold(here.exits[dir].objreq) then
			exit_fail(dir)
		   else
			do_exit(dir);
		4: if rnd100 < 34 then
			do_exit(dir)
		   else
			exit_fail(dir);

		2: begin
			if obj_hold(here.exits[dir].objreq) then
				do_exit(dir)
			else
				exit_fail(dir);
		   end;
		6: if obj_hold(here.exits[dir].objreq) then
			do_exit(dir)
		     else
			exit_fail(dir);
		7: if cycle_open then
			do_exit(dir)
		   else
		exit_fail(dir);
	end;
end;

{
Player wants to go to s
Handle everthing, this is the top level procedure

Check that he can go to s
Put him through the exit	( in do_exit )
Do a look for him		( in do_exit )
}
procedure do_go(s: string;verb:boolean := true);
label exit_label;
var
	dir: integer;                

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

    procedure exit_fail2(dir: integer);
    begin
	if here.hook = 0 then exit_fail(dir)
	else if not run_monster (
	    '',here.hook,'wrong dir','direction',
	    s,sysdate+' '+systime) then exit_fail(dir);
    end; { exit_fail2 }

begin
    if s = '' then grab_line('Direction? ',s,eof_handler := leave);

    gethere;
    if checkhide then begin
	if length(s) = 0 then
	    writeln('You must give the direction you wish to travel.')
	else begin
	    if which_dir(dir,s) then begin
		if (dir >= 1) and (dir <= maxexit) then begin
		    if here.exits[dir].toloc = 0 then exit_fail2(dir)
		    else if here.exits[dir].reqverb and not verb then 
			exit_fail2(dir)
		    else exit_case(dir);

		end else exit_fail2(dir);
	    end else exit_fail2(dir);
	end;
    end;
    exit_label:
end;


procedure nice_say(var s: string);

begin
		{ capitalize the first letter of their sentence }

	if s[1] in ['a'..'z'] then
		s[1] := chr( ord('A') + (ord(s[1]) - ord('a')) );

			{ put a period on the end of their sentence if
			  they don't use any punctuation. }

	if s[length(s)] in ['a'..'z','A'..'Z'] then
		s := s + '.';
end;


procedure do_say(s:string);
label exit_label;
var	old_loc: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	if s = '' then grab_line('Message? ',s,
	    eof_handler := leave);

	if length(s) > 0 then begin

{		if length(s) + length(myname) > 79 then begin
			s := substr(s,1,75-length(myname));
			writeln('Your message was truncated:');
			writeln('-- ',s);
		end;					}

		nice_say(s);
		if hiding then
			log_event(myslot,E_HIDESAY,0,0,s)
		else
	  		log_event(myslot,E_SAY,0,0,s);

		old_loc := location;
		if here.hook > 0 then 
			run_monster('',here.hook,'say','speech',s,
				sysdate+' '+systime);
		if old_loc = location then meta_run('say','speech',s);
	end else
		writeln('To talk to others in the room, type SAY <message>.');
    exit_label:
end;

procedure do_setname(s: string);
var
	notice: string;
	ok: boolean;
	dummy: integer;
	sprime: string;

begin
  { if s = '' then grab_line('Name? ',s); }

  gethere;
  if s <> '' then begin
     if length(s) <= shortlen then begin
         sprime := lowcase(s);
	 if (sprime = 'monster manager') and (userid <> MM_userid) then begin
            writeln('Only the Monster Manager can have that personal name.');
            ok := false;
         end else ok := true;
         if ok then begin
            if exact_pers(dummy,sprime) then begin
               if dummy = mylog then ok := true
               else begin 
                  writeln('Someone already has that name.  Your personal name must be unique.');
                  ok := false;
               end;
            end;
         end;
         if ok then begin
            myname := s;
            getroom;
            notice := here.people[myslot].name;
            here.people[myslot].name := s;
            putroom;
            notice := notice + ' is now known as ' + s;
            if not(hiding) then log_event(0,E_SETNAM,0,0,notice);
            { slot 0 means notify this player also }
            getpers;	{ note the new personal name in the logfile }
            pers.idents[mylog] := s; { don't lowcase it }
            putpers;
         end;
     end else writeln('Please limit your personal name to ',shortlen:1,' characters.');
  end else writeln('You are known to others as ',myname);
end;

procedure meta_run; { (label_name,variable: shortstring;
                    value: mega_string); forward }
label 1;
var i: integer;
    oldloc: integer;
begin     
   oldloc := location;
   gethere;
   for i:= 1 to maxpeople do
      if here.people[i].kind = P_MONSTER then 
         if here.people[i].health > 0 then begin
            run_monster (here.people[i].name,
                                  here.people[i].parm,
                                  label_name,variable,value,
                                  sysdate+' '+systime);
            if location <> oldloc then goto 1; { oobss !! }
	    gethere;	    { this is necessary }
         end;
  1:
end;

procedure meta_run_2; { (label_name,variable: shortstring;
                    value: mega_string); forward }
label 1;
var i: integer;
    oldloc,num: integer;
begin     
   oldloc := location;
   gethere;
   for i:= 1 to maxobjs do begin
      num := here.objs[i];
      if num > 0 then begin
         getobj(num);
         freeobj;
         if obj.actindx > 0 then
            run_monster ('',obj.actindx,
                                  label_name,variable,value,
                                  sysdate+' '+systime);
         if location <> oldloc then goto 1; { oobss !! }
	 gethere;	    { this is neccessary }
      end;
  end;
  1:
end;

   
procedure attack_monster(mslot,power: integer);
var health,mid,old_health: integer;
    tmp: intrec;
begin
   getroom;
   if here.people[mslot].kind <> P_MONSTER then begin
      freeroom;
      writeln ('%trap_1 in attack_monster. Notify Monster Manager.');
      writeln ('% I mean that really !!');
   end else begin
      if not exact_user(mid,here.people[mslot].username) then begin
           freeroom;
           writeln('%trap_2 in attack_monster. Notify Monster Manager.');
           writeln('% It is best for you !');
      end else begin
         health := here.people[mslot].health;
	 old_health := health;
         health := health - power; if health < 0 then health := 0;
         here.people[mslot].health := health;
         putroom;           

         tmp := anint;
         getint(N_HEALTH);
         anint.int[mid] := health;
         putint;
         anint := tmp;

         if health = 0 then begin
	    drop_everything(mslot);
	    if old_health > 0 then 
		if monster_owner(here.people[mslot].parm) <> userid then
		    add_experience(here.people[mslot].experience div 6 +1);
	 end;
         if power > 0 then desc_health(mslot);
         if health > 0 then 
            run_monster (here.people[mslot].name,
                                  here.people[mslot].parm,
                               'attack','','',
                               sysdate+' '+systime);
      end
   end
end;


{
1234567890123456789012345678901234567890
example display for alignment:

       Monster Status
    19-MAR-1988 08:59pm

}

procedure do_who (param: string);
label 1,2; { exit }
var
	i,j: integer;
	ok: boolean;
	metaok: boolean;
	roomown: veryshortstring;
        code: integer;
	c: char;
	s: shortstring;
	play,exist: indexrec;
	write_this: boolean;
	count: integer;
	s1: string;
	type_players,type_monsters: boolean;

    procedure leave;
    begin
	writeln('EXIT');
	goto 2;
    end;


var short_line : boolean;
begin

    short_line := terminal_line_len < 50;

    param := lowcase(param);
    if param = '' then param := 'players';

    type_monsters := index(param,'mon') > 0;
    type_players  := index(param,'pla') > 0;
    if param = 'all' then begin
	type_monsters := true;
	type_players := true;
    end;
    if param = '?' then begin
	command_help('who');
    end else if not type_monsters and not type_players then
	    writeln ('Type WHO ? for help.')
    else begin

	log_event(myslot,E_WHO,0,(rnd100 mod 4));
	count := 0;

	{ we need just about everything to print this list:
		player alloc index, userids, personal names,
		room names, room owners, and the log record	}

	getindex(I_ASLEEP);	{ Get index of people who are playing now }
	freeindex;
	play := indx;
	getindex(I_PLAYER);
	freeindex;
	exist := indx;
	getuser;
	freeuser;
	getpers;
	freepers;
	getnam;
	freenam;
	getown;
	freeown;
	getint(N_LOCATION);	{ get where they are }
	freeint;
	if not short_line then write('              ');
	writeln('     Monster Status');
	if not short_line then write('              ');
	writeln('  ',sysdate,' ',systime);
	writeln;
	if not short_line then write('Username        ');
	writeln('Game Name                 Where');


	if (poof_priv or owner_priv) { or has_kind(O_ALLSEEING) } then { minor change by leino@finuha }
		metaok := true
	else
		metaok := false;

	for i := 1 to exist.top do begin
		if not(exist.free[i]) then begin

			write_this := not play.free[i];
                        if user.idents[i] = '' then begin
                           if write_this and not short_line then 
			    write('<unknown>       ')
                        end else if user.idents[i][1] <> ':' then begin
			   if not type_players then write_this := false;
			   if write_this and not short_line then begin
				write(user.idents[i]);
				for j := length(user.idents[i]) to 15 do
				    write(' ');
			   end;
                        end else begin
			   readv(user.idents[i],c,code);
			   write_this := write_this or monster_runnable(code);
			   if not type_monsters then write_this := false;
			   if write_this and not short_line then begin
			      s := monster_owner(code);
			      write('<',class_out(s),'>');
                              for j := length(class_out(s)) to 13 do write(' ');
                           end;
                        end;
                        
                        if write_this then begin
			   write(pers.idents[i]);
			   j := length(pers.idents[i]);
			   while j <= 25 do begin
			      write(' ');
			      j := j + 1;
			   end;
                                                    
			   if not(metaok) then begin
			      roomown := own.idents[anint.int[i]];

{ if a person is in a public or disowned room, or
  if they are in the domain of the WHOer, then the player should know
  where they are  }

			      if (roomown = public_id) or
				    (roomown = disowned_id) or
				    (roomown = userid) then
					ok := true
			      else
					ok := false;


			   end;


			   if ok or metaok then begin
				writeln(nam.idents[anint.int[i]]);
			   end else
				writeln('n/a');
			  count := count +1;
			  if count mod ( terminal_page_len - 2) = 0 then begin
				grab_line('-more-',s1,erase := true,
				    eof_handler := leave);
				if s1 > '' then goto 1;
			  end;
                       end; { write_this }
		end;
	end;
	1:  { for quit }
    end;
    2:
end;


procedure list_rooms(s: shortstring; PROCEDURE more);
var
	first: boolean;
	i,j,posit: integer;

	columns: integer;
begin
	columns := terminal_line_len div 24;
	if columns < 1 then columns := 1;

	first := true;
	posit := 0;
	for i := 1 to indx.top do begin
		if (not indx.free[i]) and (own.idents[i] = s) then begin
			if posit = columns then begin
				posit := 1;
				writeln;
				more;
			end else
				posit := posit + 1;
			if first then begin
				first := false;
				writeln(class_out(s),':');
				more;
			end;
			write('    ',nam.idents[i]);
			for j := length(nam.idents[i]) to 21 do
				write(' ');
		end;
	end;
	if posit <> 3 then begin
		writeln;
		more;
	end;

	if first then
		writeln('No rooms owned by ',class_out(s))
	else
		writeln;
	more;
end;


procedure list_all_rooms;
label 1;

    procedure leave;
    begin
	writeln('EXIT');
	goto 1;
    end;

var
	i,j: integer;
	tmp: packed array[1..maxroom] of boolean;
	linecount: integer;

    procedure more;
    var s: string;
    begin
	linecount := linecount +1;
	if linecount > terminal_page_len -2 then begin
	    grab_line('-more-',s,erase:=true,
		eof_handler := leave);
	    if s > '' then goto 1;
	    linecount := 0
	end;
    end;

begin

	linecount := 0;
	tmp := zero;

	list_rooms(public_id,more); 	{ public rooms first }
	list_rooms(system_id,more); 	{ system rooms }
	list_rooms(disowned_id,more); 	{ disowned rooms next }
	for i := 1 to indx.top do begin
		if not(indx.free[i]) and not(tmp[i]) and
		   (own.idents[i] <> system_id) and 
		   (own.idents[i] <> disowned_id) and
		   (own.idents[i] <> public_id) then begin
				list_rooms(own.idents[i],more);	{ player rooms }
				for j := 1 to indx.top do
					if own.idents[j] = own.idents[i] then
						tmp[j] := TRUE;
		end;
	end;
    1: { out } 
end;

procedure do_rooms(s: string);
label 1;

    procedure leave;
    begin
	writeln('EXIT');
	goto 1;
    end;

var
	cmd: string;
	id: shortstring;
	listall: boolean;
	linecount: integer;

    procedure more;
    var s: string;
    begin
	linecount := linecount +1;
	if linecount > terminal_page_len -2 then begin
	    grab_line('-more-',s,erase:=true,
		eof_handler := leave);
	    if s > '' then goto 1;
	    linecount := 0
	end;
    end;


begin
    linecount := 0;
    getnam;
    freenam;
    getown;
    freeown;
    getindex(I_ROOM);
    freeindex;

    listall := false;
    s := lowcase(s);
    cmd := bite(s);
    if cmd = '?' then begin
	command_help('rooms');
    end else begin
	if cmd = '' then
		id := userid
	else if lookup_class(id,cmd) then   { hurtta@finuh }
	else if (cmd = '*') or (cmd = 'all') then
		listall := true
	else if length(cmd) > veryshortlen then
		id := substr(cmd,1,veryshortlen)
	else
		id := cmd;

	if listall then begin
		if poof_priv or owner_priv then { minor change by leino@finuha }
			list_all_rooms
		else
			writeln('You may not obtain a list of all the rooms.');
	end else begin
		if poof_priv or owner_priv or 
			(userid = id) or 
			(id = public_id) or 
			(id = disowned_id) then
			{ minor change by leino@finuha }
			list_rooms(id,more)
		else
			writeln('You may not list rooms that belong to another player.');
	end;
    end;
    1: { out }
end;



procedure do_objects (param: string);
label 0; { out }
var
	i: integer;
	total,public,disowned,private,system: integer;
	id: shortstring;
	print_count: integer;
	s1: string;
	all: boolean; 
	player: shortstring;
	myindex: indexrec;

    procedure leave;
    begin
	writeln('EXIT');
	goto 0;
    end;

begin
    param := lowcase(param);
    all := false;
    if param = '' then player := userid
    else if (param = '*') or (param = 'all') then begin
	player := '<all objects>';
	all := true
    end else if lookup_class(player,param) then
    else if length(param) > shortlen then 
	player := substr(param,1,shortlen)
    else player := param;
	
    if param = '?' then begin
	command_help('objects');
    end else if (player <> public_id) and (player <> disowned_id) and
	(player <> userid) and not owner_priv then
	writeln('You can only get list of your own objects.')
    else begin
	if all then writeln('Objects:')
	else writeln('Objects of ',class_out(player),':');
	print_count := 0;
	getobjnam;
	freeobjnam;
	getobjown;
	freeobjown;
	getindex(I_OBJECT);
	freeindex; myindex := indx;

	total := 0;
	public := 0;
	disowned := 0;
	private := 0;
	system := 0;

	writeln;
	for i := 1 to myindex.top do 
	    if not(myindex.free[i]) then begin
		total := total + 1;
		id := objown.idents[i];
		if id = public_id then public := public + 1
		else if id = disowned_id then  disowned := disowned + 1
		else if id = system_id then system := system + 1
		else private := private + 1;

		if (id = player) or (all) then  begin 
			writeln(i:4,'    ',
			    class_out(id):12,'    ',
			    objnam.idents[i]);
			print_count := print_count +1;
			if print_count > terminal_page_len -2 then begin
			    grab_line('-more-',s1,erase := true,
				eof_handler := leave);
			    if s1 > '' then goto 0;
			    print_count := 0;
			end;
		    end;
	    end;
	writeln;
	writeln('Public:      ',public:4);
	writeln('Disowned:    ',disowned:4);
	writeln('Private:     ',private:4);
	writeln('System:      ',system:4);
	writeln('             ----');
	writeln('Total:       ',total:4);
    end;
    0:
end;

procedure do_monsters (param: string);
label 0; { out }
var
	i: integer;
	total,public,disowned,private,system,mid: integer;
	id: shortstring;
	print_count: integer;
	s1: string;
	all: boolean; 
	player: shortstring;
	myindex: indexrec;
	c,x: char;

    procedure leave;
    begin
	writeln('EXIT');
	goto 0;
    end;

begin
    param := lowcase(param);
    all := false;
    if param = '' then player := userid
    else if (param = '*') or (param = 'all') then begin
	player := '<all monsters>';
	all := true
    end else if lookup_class(player,param) then
    else if length(param) > shortlen then 
	player := substr(param,1,shortlen)
    else player := param;
	
    if param = '?' then begin
	command_help('monsters');
    end else if (player <> public_id) and (player <> disowned_id) and
	(player <> userid) and not owner_priv then
	writeln('You can only get list of your own monsters.')
    else begin
	if all then writeln('Monsters:')
	else writeln('Monsters of ',class_out(player),':');
	print_count := 0;
	getuser;
	freeuser;
	getpers;
	freepers;
	getindex(I_PLAYER);
	freeindex; myindex := indx;

	total := 0;
	public := 0;
	disowned := 0;
	private := 0;
	system := 0;

	writeln;
	for i := 1 to myindex.top do 
	    if not(myindex.free[i]) then begin
		id := user.idents[i];
		if id > '' then if id[1] = ':' then begin
		    total := total + 1;
		    readv(id,c,mid);
		    id := monster_owner(mid);

		    if monster_runnable(mid) then x := '*'
		    else x := ' ';

		    if id = public_id then public := public + 1
		    else if id = disowned_id then  disowned := disowned + 1
		    else if id = system_id then system := system + 1
		    else private := private + 1;

		    if (id = player) or (all) then  begin 
			writeln(i:4,' ',x,'  ',
			    class_out(id):12,'    ',
			    pers.idents[i]);
			print_count := print_count +1;
			if print_count > terminal_page_len -2 then begin
			    grab_line('-more-',s1,erase := true,
				eof_handler := leave);
			    if s1 > '' then goto 0;
			    print_count := 0;
			end;
		    end;
		end;
	    end;
	writeln;
	writeln('Public:      ',public:4);
	writeln('Disowned:    ',disowned:4);
	writeln('Private:     ',private:4);
	writeln('System:      ',system:4);
	writeln('             ----');
	writeln('Total:       ',total:4);
    end;
    0:
end; { do_monsters }

procedure do_spells (param: string);
label 0; { out }
var
	i: integer;
	total,public,disowned,private,system: integer;
	id: shortstring;
	print_count: integer;
	s1: string;
	all: boolean; 
	player: shortstring;

	myindex: indexrec;
	myint:   intrec;

    procedure leave;
    begin
	writeln('EXIT');
	goto 0;
    end;

begin
    param := lowcase(param);
    all := false;
    if param = '' then player := userid
    else if (param = '*') or (param = 'all') then begin
	player := '<all spells>';
	all := true
    end else if lookup_class(player,param) then
    else if length(param) > shortlen then 
	player := substr(param,1,shortlen)
    else player := param;
	
    if param = '?' then begin
	command_help('spells');
    end else if (player <> public_id) and (player <> disowned_id) and
	(player <> userid) and not owner_priv then
	writeln('You can only get list of your own spells.')
    else begin
	if all then writeln('Spells:')
	else writeln('Spells of ',class_out(player),':');
	print_count := 0;
	getspell_name;
	freespell_name;
	getint(N_SPELL);
	freeint; myint := anint;

	getindex(I_SPELL);
	freeindex; myindex := indx;

	total := 0;
	public := 0;
	disowned := 0;
	private := 0;
	system := 0;

	writeln;
	for i := 1 to myindex.top do 
	    if not(myindex.free[i]) then begin
		total := total + 1;
		id := monster_owner(myint.int[i]);
		if id = public_id then public := public + 1
		else if id = disowned_id then  disowned := disowned + 1
		else if id = system_id then system := system + 1
		else private := private + 1;

		if (id = player) or (all) then  begin 
			writeln(i:4,'    ',
			    class_out(id):12,'    ',
			    spell_name.idents[i]);
			print_count := print_count +1;
			if print_count > terminal_page_len -2 then begin
			    grab_line('-more-',s1,erase := true,
				eof_handler := leave);
			    if s1 > '' then goto 0;
			    print_count := 0;
			end;
		    end;
	    end;
	writeln;
	writeln('Public:      ',public:4);
	writeln('Disowned:    ',disowned:4);
	writeln('Private:     ',private:4);
	writeln('System:      ',system:4);
	writeln('             ----');
	writeln('Total:       ',total:4);
    end;
    0:
end;


procedure do_claim(s: string);
var
	n,code,mslot: integer;
	ok: boolean;
	tmp: string;
	oldowner : integer;

begin
	if length(s) = 0 then begin	{ claim this room }
		getroom;
		if not exact_user(oldowner,here.owner) then oldowner := 0;
		if (here.owner = disowned_id) or 
		    (owner_priv and (here.owner <> system_id)) or
		    manager_priv then begin { minor change by leino@finuha }
					    { and hurtta@finuh }
			here.owner := userid;
			putroom;
			change_owner(oldowner,mylog);
			if here.hook > 0 then set_owner(here.hook,0,userid);
			getown;
			own.idents[location] := userid;
			putown;
			log_event(myslot,E_CLAIM,0,0);
			writeln('You are now the owner of this room.');
		end else begin
			freeroom;
			if here.owner = public_id then
				writeln('This is a public room.  You may not claim it.')
			else if here.owner = system_id then
				writeln('The system own this room.  You may not claim it.')
			else
				writeln('This room has an owner.');
		end;
	end else if lookup_obj(n,s) then begin
		getobjown;
		freeobjown;
      	  	{*** Let the MM claim any object ***}
		{ jlaiho@finuh }
		if ( (objown.idents[n] = public_id) 
		    and (not owner_priv) ) then { minor change by leino@finuha }
		    writeln('That is a public object.  You may DUPLICATE it, but may not CLAIM it.')
		else if ( (objown.idents[n] = system_id) 
		    and (not manager_priv) ) then { minor change by hurtta@finuha }
		    writeln('That is a system''s object. ')
		else if ( (objown.idents[n] <> disowned_id) 
		    and (not owner_priv) ) then { minor change by leino@finuha }
		    writeln('That object has an owner.')
		else begin
			getobj(n);
			freeobj;
			if obj.numexist = 0 then
				ok := true
			else begin
				if obj_hold(n) or obj_here(n) then
					ok := true
				else
					ok := false;
			end;
                        
			if ok then begin
				getobjown;
				objown.idents[n] := userid;
				putobjown;
				if obj.actindx > 0 then
					set_owner(obj.actindx,0,userid);
				tmp := obj.oname;
				log_event(myslot,E_OBJCLAIM,0,0,tmp);
				writeln('You are now the owner of ',tmp,'.');
			end else
				writeln('You must have one to claim it.');
		end;
	end else if lookup_pers(n,s) then begin
		if parse_pers(mslot,s) then begin   { parse_pers make gethere }
			if here.people[mslot].kind = P_MONSTER then begin
          			code := here.people[mslot].parm;
				if ( (monster_owner(code) = public_id) 
				    and (not owner_priv) ) then 
				    writeln('That is a public monster.')
				else if ( (monster_owner(code) = system_id) 
				    and (not manager_priv) ) then
				    writeln('That is a system''s monster.')
				else if ( (monster_owner(code) <> disowned_id) 
				    and (not owner_priv) ) then 
				    writeln('That monster has an owner.')
				else begin
					set_owner(code,0,userid);
					tmp := here.people[mslot].name;
					log_event(myslot,E_OBJCLAIM,0,0,tmp);
					writeln('You are now the owner of ',tmp,'.');
				end;
			end else writeln ('That isn''t a monster.');			
                end else writeln ('That monster isn''t here.');
	end else if lookup_spell(n,s) then begin
	    if ( (spell_owner(n) = public_id) and (not owner_priv) ) then 
				    writeln('That is a public spell.')
	    else if ( (spell_owner(n) = system_id) and (not manager_priv) ) then
				    writeln('That is a system''s spell.')
	    else if ( (spell_owner(n) <> disowned_id) and (not owner_priv) ) then 
				    writeln('That spell has an owner.')
	    else begin
					getint(N_SPELL);
					freeint;
					code := anint.int[n];
					set_owner(code,0,userid);
					tmp := spell_name.idents[n];
					log_event(myslot,E_OBJCLAIM,0,0,tmp);
					writeln('You are now the owner of ',tmp,'.');
	    end;
	end else writeln('There is nothing here by that name to claim.');
end;

procedure do_disown(s: string);
var
	n,mslot,code,oldowner: integer;
	tmp: string;
begin

	if length(s) = 0 then begin	{ claim this room }
		getroom;
		if not exact_user(oldowner,here.owner) then oldowner := 0;
		if (here.owner = userid) or 
		    (owner_priv and (here.owner <> system_id)) or
		    manager_priv then begin { minor change by leino@finuha }
			getroom;
			here.owner := disowned_id;
			putroom;
			change_owner(oldowner,0);
			if here.hook > 0 then set_owner(here.hook,0,disowned_id);
			getown;
			own.idents[location] := disowned_id;
			putown;
			log_event(myslot,E_DISOWN,0,0);
			writeln('You have disowned this room.');
		end else begin
			freeroom;
			if here.owner = system_id then
			    writeln('Owner of this room is system.')
			else writeln('You are not the owner of this room.');
		end;
	end else begin	{ disown an object }
		if lookup_obj(n,s) then begin
			getobj(n);
			freeobj;
			tmp := obj.oname;

			getobjown;
			if (objown.idents[n] = userid) or 
			    (owner_priv and ( objown.idents[n] <> system_id))
			    or manager_priv then begin
				objown.idents[n] := disowned_id;
				putobjown;
				if obj.actindx > 0 then
					set_owner(obj.actindx,0,disowned_id);
				log_event(myslot,E_OBJDISOWN,0,0,tmp);
				writeln('You are no longer the owner of the ',tmp,'.');
			end else begin
				freeobjown;
				if objown.idents[n] = system_id then
				    writeln('System is owner of this.')
				else writeln('You are not the owner of any such thing.');
			end;
		end else if lookup_pers(n,s) then begin
			if parse_pers(mslot,s) then begin   { parse_pers make gethere }		  
				if here.people[mslot].kind = P_MONSTER then begin
				    code := here.people[mslot].parm;
				    if (monster_owner(code) = system_id)
					and not manager_priv then
					    writeln('The owner of this monster is system.') 	
				    else if  (monster_owner(code) <> userid) 
					and not owner_priv then 
					    writeln('You are not the owner of this monster')
				    else begin
					set_owner(code,0,disowned_id);
					tmp := here.people[mslot].name;
					log_event(myslot,E_OBJDISOWN,0,0,tmp);
					writeln('You are no longer the owner of the ',tmp,'.');
				    end;
				end else writeln ('That isn''t monster.');
                	end else writeln ('Here isn''t that monster.');
		end else if lookup_spell(n,s) then begin
		    if (spell_owner(n) = system_id) and not manager_priv then
			writeln('The owner of this spell is system.') 	
		    else if (spell_owner(n) <> userid) and not owner_priv then 
			writeln('You are not the owner of this spell')
		    else begin
			getint(N_SPELL);
			freeint;
			code := anint.int[n];
			set_owner(code,0,disowned_id);
			tmp := spell_name.idents[n];
			log_event(myslot,E_OBJDISOWN,0,0,tmp);
			writeln('You are no longer the owner of the ',tmp,'.');
		    end;
		end else writeln('You are not the owner of any such thing.');
	end;
end;


procedure do_public(s: string);
var
	ok: boolean;
	tmp: string;
	n,mslot,code,oldowner: integer;
	pub: shortstring;

begin

	if manager_priv then begin { minor change by leino@finuha }
		if length(s) = 0 then begin
			getroom;
			if not exact_user(oldowner,here.owner) then oldowner := 0;
			here.owner := public_id;
			putroom;
			change_owner(oldowner,0);
			if here.hook > 0 then set_owner(here.hook,0,public_id);
			getown;
			own.idents[location] := public_id;
			putown;
			writeln('This room is now public.');

		end else if lookup_obj(n,s) then begin
			getobj(n);
			freeobj;
			if obj.numexist = 0 then ok := true
			else begin
			    if obj_hold(n) or obj_here(n) then ok := true
			    else ok := false;
			end;

			if ok then begin
			    getobjown;
			    objown.idents[n] := public_id;
			    putobjown;
			    if obj.actindx > 0 then
				set_owner(obj.actindx,0,public_id);

			    tmp := obj.oname;
			    log_event(myslot,E_OBJPUBLIC,0,0,tmp);
			    writeln('The ',tmp,' is now public.');
			end else
				    writeln('You must have one to claim it.');
		end else if lookup_pers(n,s) then begin
			if parse_pers(mslot,s) then begin   { parse_pers make gethere }		  
				if here.people[mslot].kind = P_MONSTER then begin
				    code := here.people[mslot].parm;
				    set_owner(code,0,public_id);
				    tmp := here.people[mslot].name;
				    log_event(myslot,E_OBJPUBLIC,0,0,tmp);
				    writeln('The ',tmp,' is now public.');
				end else writeln ('That isn''t monster.');
                	end else writeln ('Here isn''t that monster.');
		end else if lookup_spell(n,s) then begin
		    getint(N_SPELL);
		    freeint;
		    code := anint.int[n];
		    set_owner(code,0,public_id);
		    tmp := spell_name.idents[n];
		    log_event(myslot,E_OBJPUBLIC,0,0,tmp);
		    writeln('The ',tmp,' is now public.');
		end else writeln('There is nothing here by that name to make public.');
	end else
		writeln('Only the Monster Manager may make things public.');
end;



{ sum up the number of real exits in this room }

function find_numexits: integer;
var
	i: integer;
	sum: integer;

begin
	sum := 0;
	for i := 1 to maxexit do
		if here.exits[i].toloc <> 0 then
			sum := sum + 1;
	find_numexits := sum;
end;



{ clear all people who have played monster and quit in this location
  out of the room so that when they start up again they won't be here,
  because we are destroying this room }

procedure clear_people(loc: integer);
var
	i: integer;

begin
	getint(N_LOCATION);
	for i := 1 to maxplayers do
		if anint.int[i] = loc then
			anint.int[i] := 1;
	putint;
end;


procedure do_zap(s: string);
label exit_label;
var
	loc: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	if s = '' then grab_line('Room? ',s,eof_handler := leave);

	gethere;
	if checkhide then begin
	if lookup_room(loc,s,true) then begin
		gethere(loc);
		if (here.owner = userid) or (owner_priv) then begin { minor change by leino@finuha }
			clear_people(loc);
			if find_numpeople = 0 then begin
				if find_numexits = 0 then begin
					if find_numobjs = 0 then begin
						del_room(loc);
						writeln('Room deleted.');
					end else
						writeln('You must remove all of the objects from that room first.');
				end else
					writeln('You must delete all of the exits from that room first.');
			end else
				writeln('Sorry, you cannot destroy a room if people are still in it.');
		end else
			writeln('You are not the owner of that room.');
	end else
		writeln('There is no room named ',s,'.');
	end;
    exit_label:
end;

{ custom_room moved to module CUSTOM }


{ procedure do_custom moved to module CUSTOM }

procedure reveal_people(var three: boolean);
var
	retry,i: integer;

begin
	if debug then
		writeln('%revealing people');
	three := false;
	retry := 1;

	repeat
		retry := retry + 1;
		i := (rnd100 mod maxpeople) + 1;
		if (here.people[i].hiding > 0) and
				(i <> myslot) then begin
			three := true;
			writeln('You''ve found ',here.people[i].name,' hiding in the shadows!');
			log_event(myslot,E_FOUNDYOU,i,0);
		end;
	until (retry > 7) or three;
end;



procedure reveal_objects(var two: boolean);
var
	tmp: string;
	i: integer;
	modified: boolean;

begin
    if debug then
	writeln('%revealing objects');
    two := false;
    modified := false;
    getroom;
    for i := 1 to maxobjs do begin
	if here.objs[i] <> 0 then	{ if there is an object here }
	    if (here.objhide[i] <> 0) then begin
		two := true;

		if here.objhide[i] = DEFAULT_LINE then 
		    writeln('You''ve found ',obj_part(here.objs[i]),'.')
		else begin
		    print_desc(here.objhide[i]);
		    delete_block(here.objhide[i]);
		end;
		here.objhide[i] := 0; { mark them unhidden }
		{ delete_block make this also - but writeln not ! }
		modified := true;   { mark: must write to database }
	    end;
    end;
    if modified then putroom else freeroom;
end;


procedure reveal_exits(var one: boolean);
var
	retry,i: integer;

begin
	if debug then
		writeln('%revealing exits');
	one := false;
	retry := 1;

	repeat
		retry := retry + 1;
		i := (rnd100 mod maxexit) + 1;  { a random exit }
		if (here.exits[i].hidden <> 0) and (not found_exit[i]) then begin
			one := true;
			found_exit[i] := true;	{ mark exit as found }

			if here.exits[i].hidden = DEFAULT_LINE then begin
				if here.exits[i].alias = '' then
					writeln('You''ve found a hidden exit: ',direct[i],'.')
				else
					writeln('You''ve found a hidden exit: ',here.exits[i].alias,'.');
			end else
				print_desc(here.exits[i].hidden);
		end;
	until (retry > 4) or (one);
end;


procedure do_search(s: string);
var
	chance: integer;
	found,dummy: boolean;

begin
	if checkhide then begin
		chance := rnd100;
		found := false;
		dummy := false;

		if chance in [1..20] then
			reveal_objects(found)
		else if chance in [21..40] then
			reveal_exits(found)
		else if chance in [41..60] then
			reveal_people(dummy);

		if found then begin
			log_event(myslot,E_FOUND,0,0);
		end else if not(dummy) then begin
			log_event(myslot,E_SEARCH,0,0);
			writeln('You haven''t found anything.');
		end;
	end;
end;

procedure do_unhide(s: string);

begin
	if s = '' then begin
		if hiding then begin
			hiding := false;
			log_event(myslot,E_UNHIDE,0,0);
			getroom;
			here.people[myslot].hiding := 0;
			putroom;
			writeln('You are no longer hiding.');
		end else
			writeln('You were not hiding.');
	end;
end;


procedure do_hide(s: string);
label 0; { for panic }
var
	slot,n,oldloc: integer;
	founddsc: integer;
	tmp: string;

    function action(s: shortstring; n: integer): boolean;
    begin
	if obj_here(n) then begin
	    writeln('Enter the description the player will see when the ',s,' is found:');
	    writeln('(if no description is given a default will be supplied)');
	    writeln;
	    writeln('[ Editing the "object found" description ]');

	    founddsc := 0;
	    if edit_desc(founddsc) then ;
	    if founddsc = 0 then
		founddsc := DEFAULT_LINE;
   
	    if oldloc <> location then begin
		delete_block(founddsc);
		goto 0; { panic }
	    end;

	    getroom;
	    slot := find_obj(n);
	    here.objhide[slot] := founddsc;
	    putroom;

	    tmp := obj_part(n);
	    log_event(myslot,E_HIDOBJ,0,0,tmp);
	    writeln('You have hidden ',tmp,'.');
	    action := true;
	end else if obj_hold(n) then begin
	    writeln('You''ll have to put ',s,' down before it can be hidden.');
	    action := true;
	end else action := false;
	checkevents(TRUE);
	if oldloc <> location then goto 0; { panic }
    end; { action }

    function restriction (n: integer): boolean;
	begin
	    restriction := obj_here(n,false) or obj_hold(n);
	    { false = found also hidden objects }
	end;

begin
	gethere;
	if s = '' then begin	{ hide yourself }

			{ don't let them hide (or hide better) if people
			  that they can see are in the room.  Note that the
			  use of n_can_see instead of find_numpeople will
			  let them hide if other people are hidden in the
			  room that they have not seen.  The previously hidden
			  people will see them hide }

		if n_can_see > 0 then begin
			if hiding then
				writeln('You can''t hide any better with people in the room.')
			else
				writeln('You can''t hide when people are watching you.');
		end else if (rnd100 > 25) then begin
			if here.people[myslot].hiding >= 4 then
				writeln('You''re pretty well hidden now.  I don''t think you could be any less visible.')
			else begin
				getroom;
				here.people[myslot].hiding := 
						here.people[myslot].hiding + 1;
				putroom;
				if hiding then begin
					log_event(myslot,E_NOISES,rnd100,0);
					writeln('You''ve managed to hide yourself a little better.');
				end else begin
					log_event(myslot,E_IHID,0,0);
					writeln('You''ve hidden yourself from view.');
					hiding := true;
				end;
			end;
		end else begin { unsuccessful }
			if hiding then
				writeln('You could not find a better hiding place.')
			else
				writeln('You could not find a good hiding place.');
		end;
	end else begin	{ Hide an object }
		oldloc := location;
		if scan_obj(action,s,,restriction) then begin
		end else
			writeln('I see no such object here.');
	end;
	0:  { for panic }
end;


procedure do_punch(s: string);
label exit_label;
var
	sock,n: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


begin
	if s = '' then grab_line('Victim? ',s,eof_handler := leave);

	if not read_global_flag(GF_WARTIME) then
	    writeln('Don''t you dare disturb the Pax Monstruosa!')
	else if s <> '' then begin
		if parse_pers(n,s) then begin
	  		if n = myslot then
				writeln('Self-abuse will not be tolerated in the Monster universe.')
			else if protected(n) then begin
				log_event(myslot,E_TRYPUNCH,n,0);
				writeln('A mystic shield of force prevents you from attacking.');
			end else if (here.people[n].experience >= protect_exp) { and protected_MM } then begin
				log_event(myslot,E_TRYPUNCH,n,0);
				writeln('You can''t punch that person.');
	  		end else begin
				if hiding then begin
					hiding := false;

	  				getroom;
					here.people[myslot].hiding := 0;
					putroom;
                                 
					log_event(myslot,E_HIDEPUNCH,n,0);
	  				writeln('You pounce unexpectedly on ',here.people[n].name,'!');
                                        if here.people[n].kind = P_MONSTER then attack_monster(n,2);
				end else begin
					if myexperience < (rnd100 div 3) then
                                          sock := (rnd100 mod numpunches)+1
                                        else sock := BAD_PUNCH;

					log_event(myslot,E_PUNCH,n,sock);
					put_punch(sock,here.people[n].name);
                                        if here.people[n].kind = P_MONSTER then attack_monster(n,punch_force(sock));
	  			end;
				wait(1+random*3);	{ Ha ha ha }
			end;
		end else
			writeln('That person cannot be seen in this room.');
	end else
		writeln('To punch somebody, type PUNCH <personal name>.');
    exit_label:
end;

{ procedure do_program moved to module CUSTOM }

{ returns TRUE if anything was actually dropped }
function drop_everything;
{ forward function drop_everything(pslot: integer := 0): boolean; }
var
	i: integer;
	slot: integer;
	didone: boolean;
	theobj: integer;
	tmp: string;

begin
	if pslot = 0 then
		pslot := myslot;

	gethere;
	didone := false;

	mywield := 0;
	mywear := 0;
	mydisguise := 0;

	for i := 1 to maxhold do begin
		if here.people[pslot].holding[i] <> 0 then begin
			didone := true;
			theobj := here.people[pslot].holding[i];
			slot := i;
			if place_obj(theobj,TRUE) then begin
			    
			    drop_obj(slot,pslot);
			    
			    getobj(theobj);
			    freeobj;

			    if obj.actindx > 0 then begin
				run_monster('',obj.actindx,'drop you','','',
				    sysdate+' '+systime);

				gethere;	{ necessary after run_monster }
			    end;

			end else begin	{ no place to put it, it's lost .... }
				getobj(theobj);
				obj.numexist := obj.numexist - 1;
				putobj;
				tmp := obj.oname;
				writeln('The ',tmp,' was lost.');
			end;
		end;
	end;

	drop_everything := didone;
end;

procedure do_endplay(lognum: integer;ping:boolean := FALSE);

{ If update is true do_endplay will update the "last play" date & time
  we don't want to do this if this endplay is called from a ping }

begin
	if not(ping) then begin
			{ Set the "last date & time of play" }
		getdate;
		adate.idents[lognum] := sysdate + ' ' + systime;
		putdate;
	end;


	{ Put the player to sleep.  Don't delete his information,
	  so it can be restored the next time they play. }

	getindex(I_ASLEEP);
	indx.free[lognum] := true;	{ Yes, I'm asleep }
	putindex;
end;


function check_person(n: integer;id: string):boolean;

begin
	inmem := false;
	gethere;
	if here.people[n].username = id then
		check_person := true
	else
		check_person := false;
end;


function nuke_person(n: integer;id: string): boolean;
var
	lognum: integer;
	tmp: string;

begin
	getroom;
	if here.people[n].username = id then begin

			{ drop everything they're carrying }
		drop_everything(n);

		tmp := here.people[n].username;
			{ we'll need this for do_endplay }

			{ Remove the person from the room }
		here.people[n].kind := 0;
		here.people[n].username := '';
		here.people[n].name := '';
		putroom;

			{ update the log entries for them }
			{ but first we have to find their log number
			  (mylog for them).  We can do this with a lookup_user
			  give the userid we got above }

		if lookup_user(lognum,tmp) then begin
			do_endplay(lognum,TRUE);
				{ TRUE tells do_endplay not to update the
				  "time of last play" information 'cause we
				  don't know how long the "zombie" has been
				  there. }
		end else
			writeln('%error in nuke_person; can''t fing their log number; notify the Monster Manager');

		nuke_person := true;
	end else begin
		freeroom;
		nuke_person := false;
	end;
end;


function ping_player(n:integer;silent: boolean := false): boolean;
var
	retry: integer;
	id: string;
	idname: string;
        kind: integer;

begin
	ping_player := false;

	id := here.people[n].username;
	idname := here.people[n].name;
        kind := here.people[n].kind;

	if kind = P_PLAYER then begin
		retry := 0;
		ping_answered := false;

		repeat
			retry := retry + 1;
			if not(silent) then
	    			writeln('Sending ping # ',retry:1,' to ',idname,' . . .');
        
			log_event(myslot,E_PING,n,0,myname);
			{ leaving here myname, not replace it with log_name }

			wait(1);
			checkevents(TRUE);
				{ TRUE = don't reprint prompt }

			if not(ping_answered) then
				if check_person(n,id) then begin
					wait(1);
					checkevents(TRUE);
				end else
					ping_answered := true;

			if not(ping_answered) then
				if check_person(n,id) then begin
					wait(1);
					checkevents(TRUE);
				end else
					ping_answered := true;

		until (retry >= MAX_PING) or ping_answered;

		if not(ping_answered) then begin
			if not(silent) then

				writeln('That person is not responding to your pings . . .');
         
			if nuke_person(n,id) then begin
				ping_player := true;
				if not(silent) then
					writeln(idname,' shimmers and vanishes from sight.');
				log_event(myslot,E_PINGONE,n,0,idname);
			end else
				if not(silent) then
					writeln('That person is not a zombie after all.');
		end else
			if not(silent) then
				writeln('That person is alive and well.');
	end else if not(silent) then
		writeln ('This isn''t player. You can only ping player.')
end;


procedure do_ping(s: string);
label exit_label;
var
	n: integer;
	dummy: boolean;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


begin
	if s = '' then grab_line('Player? ',s,eof_handler := leave);

	if s <> '' then begin
		if parse_pers(n,s) then begin
			if n = myslot then
				writeln('Don''t ping yourself.')
			else dummy := ping_player(n);
		end else
			writeln('You see no person here by that name.');
	end else
		writeln('To see if someone is really alive, type PING <personal name>.');
    exit_label:
end;

procedure list_get;
var
	first: boolean;
	i: integer;

begin
	first := true;
	for i := 1 to maxobjs do begin
		if (here.objs[i] <> 0) and
		   (here.objhide[i] = 0) then begin
			if first then begin
				writeln('Objects that you see here:');
				first := false;
			end;
			writeln('   ',obj_part(here.objs[i]));
		end;
	end;
	if first then
		writeln('There is nothing you see here that you can get.');
end;



{ print the get success message for object number n }

procedure p_getsucc(n: integer);

begin
	{ we assume getobj has already been done }
	if (obj.getsuccess = 0) or (obj.getsuccess = DEFAULT_LINE) then
		writeln('Taken ',obj_part(n,FALSE),'.')
	else
		print_desc(obj.getsuccess);
end;


procedure do_meta_get(n: integer);
var
	slot: integer;

begin
	if obj_here(n) then begin
		if can_hold then begin
			slot := find_obj(n);
			if take_obj(n,slot) then begin
				hold_obj(n);
				log_event(myslot,E_GET,0,0,
{ >>> }		log_name + ' has picked up ' + obj_part(n) + '.');
				p_getsucc(n);
			end else
				writeln('Someone got to it before you did.');
		end else
			writeln('Your hands are full.  You''ll have to drop something you''re carrying first.');
	end else if obj_hold(n) then
		writeln('You''re already holding that item.')
	else
		writeln('That item isn''t in an obvious place.');
end;      


procedure do_get(s: string);
label 0;    { for panic }
var
	n,oldloc: integer;
	ok: boolean;                                      

	procedure trapget;
	begin
        	log_event(myslot,E_TRAP,,obj.d1,obj.oname);
		if (obj.getfail=0) or (obj.getfail=DEFAULT_LINE) then
			writeln('You try get ',obj.oname,' but it bites you.')
	  	else print_desc(obj.getfail);
		take_hit(obj.ap);
	end;

    function action(s: shortstring; n: integer): boolean;
    begin
	if obj_here(n) then begin
	    getobj(n);
	    freeobj;
	    ok := true;

	    if obj.sticky then begin
		ok := false;   
		if obj.kind = O_TRAP then trapget
		else begin
		    log_event(myslot,E_FAILGET,n,0);
		    if (obj.getfail = 0) or (obj.getfail = DEFAULT_LINE) then
			writeln('You can''t take ',obj_part(n,FALSE),'.')
		    else
			print_desc(obj.getfail);
		end;
		if obj.actindx > 0 then
		    run_monster('',obj.actindx,
			'get fail','','',
			sysdate+' '+systime);
	    end else if obj.getobjreq > 0 then begin
		if not(obj_hold(obj.getobjreq)) then begin
		    ok := false;
		    if obj.kind = O_TRAP then trapget
		    else begin
			log_event(myslot,E_FAILGET,n,0);
			if (obj.getfail = 0) or (obj.getfail = DEFAULT_LINE) then
			    writeln('You''ll need something first to get the ',obj_part(n,FALSE),'.')
			else
			    print_desc(obj.getfail);
		    end;
		    if obj.actindx > 0 then
			run_monster('',obj.actindx,
			    'get fail','','',
			    sysdate+' '+systime);
		    end;
	    end;	{ obj sticky }

	    if ok then begin
		do_meta_get(n);		{ get the object }
		if obj.actindx > 0 then
		    run_monster('',obj.actindx,
			'get succeed','','',
		    sysdate+' '+systime);
	    end;
	    action := true;
	end { else if obj_hold(n) then begin
	    writeln('You have already ',obj_part(n),'.');
	    action := true;
	end } else action := false;
	checkevents(TRUE);
	if oldloc <> location then goto 0; { panic }
    end; { action }
	   
    function restriction (n: integer): boolean;
	begin
	    restriction := obj_here(n,true) or obj_hold(n);
	    { true = not found hidden objects }
	end;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto 0;
    end;



begin
	if s = '' then begin                              
		list_get;
		writeln;
		grab_line('Object? ',s,eof_handler := leave);
	end;
	oldloc := location;

	if scan_obj(action,s,,restriction) then begin
	    { functin action make all }
	end else if lookup_detail(n,s) then begin
			writeln('That detail of this room is here for the enjoyment of all Monster players,');
			writeln('and may not be taken.');
	end else
		writeln('There is no object here by that name.');
	0:  { panic }
end;


procedure do_drop(s: string);
label	0;  { for panic }
var
	slot,n,oldloc: integer;

    function action(s: shortstring; n: integer): boolean;
    begin
	if obj_hold(n) then begin
	    getobj(n);
	    freeobj;
	    if obj.sticky then
		writeln(obj_part(n),': You can''t drop sticky objects.')
	    else if can_drop then begin
		slot := find_hold(n);
		if place_obj(n) then begin
		    drop_obj(slot);
		    log_event(myslot,E_DROP,0,n,
			log_name + ' has dropped '+obj_part(n) + '.');

		    if mywield = n then x_unwield;
		    if mywear = n then x_unwear;
		    if obj.actindx > 0 then
			run_monster('',obj.actindx,
			    'drop succeed','','',
			    sysdate+' '+systime);

		end else
		    writeln('Someone took the spot where your were going to drop ',obj_part(n),'.');
	    end else
		writeln('It is too cluttered here.  Find somewhere else to drop your things.');
	    action := true;
	end else begin
	    action := false;
	end;
	checkevents(TRUE);
	if oldloc <> location then goto 0; { panic }
    end; { action }

    function restriction (n: integer): boolean;
	begin
		restriction := obj_hold(n);
	end;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto 0;
    end;



begin
    if s = '' then grab_line('Object? ',s,eof_handler := leave);
    oldloc := location;
    if s = '' then begin
	writeln('To drop an object, type DROP <object name>.');
	writeln('To see what you are carrying, type INV (inventory).');
    end else if scan_obj(action,s,,restriction) then begin
    end else
	writeln('You''re not holding that item.  To see what you''re holding, type INVENTORY.');
    0:	{ for panic }
end;


procedure do_inv(s: string);
label 0; { for panic }
var
	first: boolean;
	i,n: integer;
	objnum,oldloc: integer;

	function restriction(slot: integer): boolean;
	begin
	    restriction := here.people[slot].hiding = 0;
	    { can't se people when he is hiding }
	end;

	function action(s: shortstring; n: integer): boolean;
	begin
	    first := true;
	    log_event(myslot,E_LOOKYOU,n,0);
	    for i := 1 to maxhold do begin
		objnum := here.people[n].holding[i];
		if objnum <> 0 then begin
		    if first then begin
			writeln(here.people[n].name,' is holding:');
			first := false;
		    end;
		    write('   ',obj_part(objnum));
		    if objnum = here.people[n].wielding then write(' wielded');
		    if objnum = here.people[n].wearing then write(' worn');
		    writeln;
		end;
	    end;
	    if first then
		writeln(here.people[n].name,' is empty handed.');
	    action := true;
	    checkevents(TRUE);
	    if oldloc <> location then goto 0; { panic }
	end;

begin
	gethere;
	oldloc := location;
	if s = '' then begin
		noisehide(50);
		first := true;
		log_event(myslot,E_INVENT,0,0);
		for i := 1 to maxhold do begin
		    objnum := here.people[myslot].holding[i];
		    if objnum <> 0 then begin
			if first then begin
			    writeln('You are holding:');
			    first := false;
			end;
			write('   ',obj_part(objnum));
			if objnum = mywield then write(' wielded');
			if objnum = mywear then write(' worn');
			writeln;
		    end;
		end;
		if first then
	  		writeln('You are empty handed.');
	end else if scan_pers_slot(action,s,,restriction) then begin
	end else
		writeln('To see what someone else is carrying, type INV <personal name>.');
	0: { for panic }
end;


{ translate a personal name into a real userid on request }

procedure do_whois(s: string);
label exit_label;
var
	n: integer;

    function action(s: shortstring; n: integer): boolean;
    begin
	if user.idents[n] = '' then 
	    writeln (s,' no have userid.')
	else if user.idents[n][1] = ':' then
	    writeln(s,' isn''t player, it is a monster.')
	else writeln(s,' is ',user.idents[n],'.');
	action := true;
    end; { action }

    function restriction (n: integer): boolean;
	begin
		restriction := true;
	end;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	if s = '' then grab_line('Player? ',s,eof_handler := leave);

	getuser;
	freeuser;

	if scan_pers(action,s,,restriction) then begin
                
	end else
		writeln('There is no one playing with that personal name.');
    exit_label:
end;


procedure do_players(param: string);
label 1,2; { for quit }
var
	i,j: integer;
	tmpasleep: indexrec;
	where_they_are: intrec;
	ok: boolean;
	c : char;
	code : integer;
	count: integer;
	s1: string;
	str: shortstring;
	type_monsters,type_players,write_this: boolean;

    procedure leave;
    begin
	writeln('EXIT');
	goto 2;
    end;

var short_line: boolean;

begin

    short_line :=  terminal_line_len < 80;
    
    param := lowcase(param);
    if param = '' then param := 'players';

    type_monsters := index(param,'mon') > 0;
    type_players  := index(param,'pla') > 0;
    if param = 'all' then begin
	type_monsters := true;
	type_players := true;
    end;
    if param = '?' then begin
	command_help('players');
    end else if not type_monsters and not type_players then
	writeln ('Type PLAYERS ? for help.')
    else begin

	count := 0;
	log_event(myslot,E_PLAYERS,0,0);
	getindex(I_ASLEEP);	{ Rec of bool; False if playing now }
	freeindex;
	tmpasleep := indx;

	getindex(I_PLAYER);	{ Rec of valid player log records  }
	freeindex;		{ False if a valid player log }

	getuser;		{ Corresponding userids of players }
	freeuser;

	getpers;		{ Personal names of players }
	freepers;

	getdate;		{ date of last play }
	freedate;

	getint(N_LOCATION);
	freeint;
	where_they_are := anint;

	getnam;			{ room names }
	freenam;

	getown;			{ room owners }
	freeown;

	getint(N_SELF);
	freeint;

	writeln;
	if not short_line then write ('Userid          ');
	write ('Personal Name          ');
	if not short_line then write ('    Last Play     ');
	writeln ('   Where');
	for i := 1 to maxplayers do begin
		if not(indx.free[i]) then begin
			write_this := true;
                        if user.idents[i] = '' then begin
			    if not short_line then write('<unknown>       ')
                        end else if user.idents[i][1] <> ':' then begin
			   if not type_players then write_this := false
			   else if not short_line then begin
			       write(user.idents[i]);
			       for j := length(user.idents[i]) to 15 do
				    write(' ');
			   end;
                        end else begin
			   if not type_monsters then write_this := false
			   else if not short_line then begin
			       readv(user.idents[i],c,code);
			       str := class_out(monster_owner(code));
			       write('<',str,'>');
			       for j := length(str) to 13 do write(' ');
			   end;
                        end;

			if write_this then begin
			    write(pers.idents[i]);
			    for j := length(pers.idents[i]) to 21 do
				write(' ');

			    if not short_line then begin
				if tmpasleep.free[i] then begin
				    write(adate.idents[i]);
				    if length(adate.idents[i]) < 19 then
					for j := length(adate.idents[i]) to 18 do
					    write(' ');
				end else
					write('   -playing now-   ');
			    end;

			    if (anint.int[i] <> 0) and (anint.int[i] <> DEFAULT_LINE) then
				write(' * ')
			    else
				write('   ');

{ let people see, who have quitted in their rooms }
			    if (own.idents[where_they_are.int[i]] =
				    public_id) or
			       (own.idents[where_they_are.int[i]] =
				    disowned_id) or
			       (own.idents[where_they_are.int[i]] =
				    userid) then
				    ok := true
			    else
				ok := false;


{ let the Monster wizards see ev'rything.. }
			    if manager_priv or 
			       ( (poof_priv or owner_priv) 
				and (here.owner <> system_id)) then 
				{ minor change by leino@finuha }
				{ and hurtta@finuh }
				ok := true;


			    if ok then begin
				    write(nam.idents[ where_they_are.int[i] ]);
			    end else
				    write('n/a');


			    writeln;
			    count := count +1;
			    if count mod (terminal_page_len -2) = 0 then begin
				grab_line('-more-',s1,erase := true,
				    eof_handler := leave);
				if s1 > '' then goto 1;
			    end;
			end;
		end;
	end;
	writeln;
	1:
    end;
    2:
end;


procedure do_self(s: string);
label 0; { for panic }
var
	n,oldloc: integer;

    function action(s: shortstring; n: integer): boolean;
    begin
	writeln(s,':');
	getint(N_SELF);
	freeint;
	if (anint.int[n] = 0) or (anint.int[n] = DEFAULT_LINE) then
	    writeln('That person has not made a self-description.')
	else begin
	    print_desc(anint.int[n]);
	    log_event(myslot,E_VIEWSELF,0,0,pers.idents[n]);
	end;
	action := true;
	checkevents(true);
	if oldloc <> location then goto 0; { panic }
    end; { action }

    function restriction (n: integer): boolean;
	begin
		restriction := true;
	end;


begin
	oldloc := location;
	if length(s) = 0 then begin
		log_action(c_self,0);
		writeln('[ Editing your self description ]');
		if edit_desc(myself) then begin
			getroom;
			here.people[myslot].self := myself;
			putroom;
			getint(N_SELF);
			anint.int[mylog] := myself;
			putint;
			log_event(myslot,E_SELFDONE,0,0);
		end;
	end else if scan_pers(action,s,,restriction) then begin
	end else
		writeln('There is no person by that name.');
	0: { for panic }
end;


procedure do_health(s: string);
var lev,rel: integer;
begin
	lev := level(myexperience);
	rel := myhealth * 10 div leveltable[lev].health;

	writeln('Your health rate is ',myhealth:1,'/',
	    leveltable[lev].health:1,'.');
	if rel > 9 then rel := 9;
	write('You ');
        if  myhealth = 0 then writeln('are dead.')
	else case rel of
		9: writeln('are in exceptional health.');
		8: writeln('are in better than average condition.');
		7: writeln('are in perfect health.');
		6: writeln('feel a little bit dazed.');
		5: writeln('have some minor cuts and abrasions.');
		4: writeln('have some wounds, but are still fairly strong.');
		3: writeln('are suffering from some serious wounds.');
		2: writeln('are very badly wounded.');
		1,0: writeln('have many serious wounds, and are near death.');
		otherwise writeln('don''t seem to be in any condition at all.');
	end;
end;


procedure crystal_look(chill_msg: integer);
var
	numobj,numppl,numsee: integer;
	i: integer;
	yes: boolean;

begin
	writeln;
	print_desc(here.primary);
	log_event(0,E_CHILL,chill_msg,0,'',here.locnum);
	numppl := find_numpeople;
	numsee := n_can_see + 1;

	if numppl > numsee then
		writeln('Someone is hiding here.')
	else if numppl = 0 then begin
		writeln('Strange, empty shadows swirl before your eyes.');
	end;
	if rnd100 > 50 then
		people_header('at this place.')
	else case numppl of
			0: writeln('Vague empty forms drift through your view.');
			1: writeln('You can make out a shadowy figure here.');
			2: writeln('There are two dark figures here.');
			3: writeln('You can see the silhouettes of three people.');
			otherwise
				writeln('Many dark figures can be seen here.');
	end;

	numobj := find_numobjs;
	if rnd100 > 50 then begin
		if rnd100 > 50 then
			show_objects
		else if numobj > 0 then
			writeln('Some objects are here.')
		else
			writeln('There are no objects here.');
	end else begin
		yes := false;
		for i := 1 to maxobjs do
			if here.objhide[i] <> 0 then
				yes := true;
		if yes then
			writeln('Something is hidden here.');
	end;
	writeln;
end;


procedure use_crystal(objnum: integer);
label exit_label;
var
	done: boolean;
	s: string;
	n: integer;
	done_msg,chill_msg: integer;
	tmp: string;
	i: integer;

    procedure leave;
    begin
	writeln('EXIT');
	gethere;
	log_event(myslot,E_DONECRYSTALUSE,0,0);
	print_desc(done_msg);
	goto exit_label;
    end;



begin
	if obj_hold(objnum) then begin
		log_action(e_usecrystal,0);
		getobj(objnum);
		freeobj;
		done_msg := obj.d1;
		chill_msg := obj.d2;

		grab_line('',s,eof_handler := leave);
		if lookup_room(n,s) then begin
			gethere(n);
			crystal_look(chill_msg);
			done := false;
		end else
			done := true;

		while not(done) do begin
			grab_line('',s,eof_handler := leave);
			if lookup_dir(n,s) then begin
				if here.exits[n].toloc > 0 then begin
					gethere(here.exits[n].toloc);
					crystal_look(chill_msg);
				end;
			end else begin
				s := lowcase(s);
				tmp := bite(s);
				if tmp = 'poof' then begin
					if lookup_room(n,s) then begin
						gethere(n);
						crystal_look(chill_msg);
					end else
						done := true;
				end else if tmp = 'say' then begin
					i := (rnd100 mod 4) + 1;
					log_event(0,E_NOISE2,i,0,'',n);
				end else
					done := true;
			end;
		end;

	  	gethere;
		log_event(myslot,E_DONECRYSTALUSE,0,0);
		print_desc(done_msg);
	end else
		writeln('You must be holding it first.');
    exit_label:
end;



procedure p_usefail(n: integer);

begin
	{ we assume getobj has already been done }
	if (obj.usefail = 0) or (obj.usefail = DEFAULT_LINE) then
   		writeln('It doesn''t work for some reason.')
	else
		print_desc(obj.usefail);
end;


procedure p_usesucc(n: integer);

begin
	{ we assume getobj has already been done }
	if (obj.usesuccess = 0) or (obj.usesuccess = DEFAULT_LINE) then
	  	writeln('It seems to work, but nothing appears to happen.')
	else
		print_desc(obj.usesuccess);
end;                   

procedure p_attack (n,victim: integer);                                  
Var vs: string;
begin
	{ we assume getroom has already been done }
        getobj (n);	{    can we remove this ? }
	freeobj; 	{ -> (what happen in grab_line) }
        vs := here.people[victim].name;
	if (obj.usesuccess = 0) or (obj.usesuccess = DEFAULT_LINE) then
		writeln('You attack ',vs)
	else
		block_subs(obj.usesuccess,vs);
end;                                                               


procedure use_weapon (n: integer);
label exit_label;
var done: boolean;
    victim,factor: integer;
    s,last: string;

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;

begin
   factor := leveltable[level(myexperience)].factor;
   Writeln ('Use weapon - Whom do you attack ?');
   done := False; last := '<unknown>';
   repeat
     
     if not read_global_flag(GF_WARTIME) then begin
	writeln('Don''t you dare disturb the Pax Monstruosa!');
	done := true
     end else if mywield <> n then begin
	writeln ('You are no longer wielding that weapon.');
	done := true;
     end else begin
	grab_line ('Victim? ',s,eof_handler := leave); 
	if s = '.' then s := last;
	last := s;

	if s = '' then done := true
	else if not parse_pers(victim,s) then begin
	    Writeln (s,' isn''t here.');
	    victim := 0
	end;
     end;

     if not done and (victim > 0) then
       if victim = myslot Then Writeln ('Suicide is not allowed.')
       else if protected (victim) or (rnd100 > factor) then begin { Ha Ha }
		log_event(myslot,E_FAILUSE,n,0);
		p_usefail(n);
       end else if (here.people[victim].experience >= protect_exp) 
       {	and protected_MM } then begin
		log_event(myslot,E_FAILUSE,n,0);
		writeln('You can''t attack that person.');
       end else begin
		if hiding then begin
			hiding := false;

			getroom;   
			here.people[myslot].hiding := 0;
			putroom;
                                 
                        log_event(myslot,E_HATTACK,victim,n);
                        Writeln ('You step out from shadows and ...');
                        p_attack (n,victim);
		       	if here.people[victim].kind = P_MONSTER then begin
				getobj(n);
				freeobj;
				attack_monster(victim,obj.ap);
			end; 
		end else begin
       	      		log_event(myslot,E_ATTACK,victim,n);
			p_attack (n,victim);
		       	if here.people[victim].kind = P_MONSTER then begin
				getobj(n);
				freeobj;
				attack_monster(victim,obj.ap);
			end; 
		end;
		wait (1+random*4); { Ha Ha Ha }
	end;
   until done;
   exit_label:
end;

procedure use_book(n: integer);
var p: integer;
begin
    p := obj.parms[OP_SPELL];
    if p > 0 then begin
	getint(N_SPELL);
	freeint;
	getspell_name;
	freespell_name;
	run_monster('',anint.int[p],'learn', 
	    'book name',objnam.idents[n],
	    sysdate + ' ' + systime,
	    spell_name.idents[p],myname);
    end;
end; { use_book }

procedure do_use(s: string);
label exit_label;
var
	n: integer;

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;

begin
	if s = '' then grab_line('Object? ',s,eof_handler := leave);

	if length(s) = 0 then
		writeln('To use an object, type USE <object name>')
	else if parse_obj(n,s) then begin
		getobj(n);
		freeobj;

		if (obj.useobjreq > 0) and not(obj_hold(obj.useobjreq)) then begin
			log_event(myslot,E_FAILUSE,n,0);
			p_usefail(n);
		end else if (obj.uselocreq > 0) and (location <> obj.uselocreq) then begin
			log_event(myslot,E_FAILUSE,n,0);
			p_usefail(n);
		end else if (obj.kind = O_WEAPON) and 
                            ((obj.exreq > myexperience) or
                            (n <> mywield)) then begin  { Ha Ha Ha }
			log_event(myslot,E_FAILUSE,n,0);
			p_usefail(n);
		end else if (obj.kind = O_BOOK) and 
                            ((obj.exreq > myexperience)) then begin
			log_event(myslot,E_FAILUSE,n,0);
			p_usefail(n);
                end else begin
			case obj.kind of
				O_BLAND: p_usesucc(n);
				O_CRYSTAL: begin
                                             p_usesucc(n);
			                     use_crystal(n);
                                           end;
                                O_WEAPON: use_weapon (n);
				O_BOOK:	  begin
					    p_usesucc(n);
					    use_book(n);
					  end;
				otherwise p_usesucc(n);
			end;
			if obj.actindx > 0 then
				run_monster('',obj.actindx,
					'use succeed','','',
					sysdate+' '+systime);

		end;
	end else
		writeln('There is no such object here.');
    exit_label:
end;


procedure do_whisper(s: string);
label exit_label;
var
	n: integer;

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;

begin
	if s = '' then grab_line('Player? ',s,eof_handler := leave);

	if length(s) = 0 then begin
		writeln('To whisper to someone, type WHISPER <personal name>.');
	end else if parse_pers(n,s) then begin
		if n = myslot then
		    writeln('You can''t whisper to yourself.')
		else begin
		    grab_line('>> ',s,eof_handler := leave);
		    if length(s) > 0 then begin
			nice_say(s);
			log_event(myslot,E_WHISPER,n,0,s);
			if here.people[n].kind = P_MONSTER then
			    if here.people[n].health > 0 then begin
				run_monster (here.people[n].name,
				    here.people[n].parm,
				    'say','speech',s,
				    sysdate+' '+systime);
			    end;
		    end else
			    writeln('Nothing whispered.');
		end;
	end else
		writeln('No such person can be seen here.');

    exit_label:
end;

procedure health_player; { hurtta@finuh }
var tmp: intrec;
    lev: integer;
begin
  if rnd100 > 70 then begin
     lev := level(myexperience);
     myhealth := myhealth + leveltable[lev].health div 3;
     if myhealth > leveltable[lev].health then 
        myhealth := leveltable[lev].health;

     getroom;
     here.people[myslot].health := myhealth;
     putroom;

     tmp := anint;
     getint(N_HEALTH);
     anint.int[mylog] := myhealth;
     putint;
     anint := tmp;

  end;
end;

procedure x_unwield;
var tmp: shortstring;
begin
    getobj(mywield);
    freeobj;
    tmp := obj.oname;
    if obj.kind = O_MAGIC_RING then reset_queue;
    { action queue must reset, because it not in }
    { runnning when use MAGIC RING }
    log_event(myslot,E_UNWIELD,0,0,tmp);
    writeln('You are no longer wielding the ',tmp,'.');

    mywield := 0;
    getroom;
    here.people[myslot].wielding := 0;
    putroom;
end;


procedure do_wield(s: string);
var
	tmp: string;
	slot,n: integer;

begin
	if length(s) = 0 then begin	{ no parms means unwield }
		if mywield = 0 then
			writeln('You are not wielding anything.')
		else begin
		    x_unwield;
		end;
	end else if parse_obj(n,s) then begin
		if mywield <> 0 then begin
			writeln('You are already wielding ',obj_part(mywield),'.');
		end else begin
			getobj(n);
			freeobj;
			tmp := obj.oname;
			if obj.kind in [O_WEAPON,O_MAGIC_RING,
				O_TELEPORT_RING,O_HEALTH_RING] then begin
				if obj_hold(n) then begin
					mywield := n;
					getroom;
					here.people[myslot].wielding := n;
					putroom;

					if (obj.kind = O_HEALTH_RING) then
						health_player;

					log_event(myslot,E_WIELD,0,0,tmp);
					writeln('You are now wielding the ',tmp,'.');
				end else
					writeln('You must be holding it first.');
			end else
			writeln('That is not a weapon.');
		end;
	end else
		writeln('No such weapon can be seen here.');
end;

procedure x_unwear;
var tmp: shortstring;
begin
    getobj(mywear);
    freeobj;
    tmp := obj.oname;
    log_event(myslot,E_UNWEAR,0,0,tmp);
    writeln('You are no longer wearing the ',tmp,'.');

    mywear := 0;
    mydisguise := 0;
    getroom;
    here.people[myslot].wearing := 0;
    putroom;
end;


procedure do_wear(s: string);
var
	tmp: string;
	slot,n: integer;

begin
	if length(s) = 0 then begin	{ no parms means unwear }
		if mywear = 0 then
	  		writeln('You are not wearing anything.')
		else begin
		    x_unwear;
		end;
	end else if parse_obj(n,s) then begin
		if mywear > 0 then begin
		    getobj(mywear);
		    freeobj;
		    writeln('You are already wearing the ',obj.oname,'.');
		end else begin
		    getobj(n);
		    freeobj;
		    tmp := obj.oname;
		    if (obj.kind in [O_ARMOR, O_DISGUISE] ) then begin
			if obj_hold(n) then begin
				mywear := n;
				if obj.kind = O_DISGUISE then
					mydisguise := n;
				getroom;
				here.people[myslot].wearing := n;
				putroom;

				log_event(myslot,E_WEAR,0,0,tmp);
				writeln('You are now wearing the ',tmp,'.');
			end else
				writeln('You must be holding it first.');
		    end else
			writeln('That cannot be worn.');
		end;
	end else
		writeln('No such thing can be seen here.');
end;


procedure do_brief;
begin
	brief := not(brief);
	if brief then writeln('Brief descriptions.')
	else writeln('Verbose descriptions.');
end;


function p_door_key(n: integer): string;

begin
	if n = 0 then
		p_door_key := '<none>'
	else
		p_door_key := objnam.idents[n];
end;



procedure anal_exit(dir: integer);

begin
	if (here.exits[dir].toloc = 0) and (here.exits[dir].kind <> 5) then
		{ no exit here, don't print anything }
	else with here.exits[dir] do begin
		write(direct[dir]);
		if length(alias) > 0 then begin
			write('(',alias);
			if reqalias then
				write(' required): ')
			else
				write('): ');
		end else
			write(': ');

		if (toloc = 0) and (kind = 5) then
			write('accept, no exit yet')
		else if toloc > 0 then begin
			write('to ',nam.idents[toloc],', ');
			case kind of
				0: write('no exit');
				1: write('open passage');
				2: write('door, key=',p_door_key(objreq));
				3: write('~door, ~key=',p_door_key(objreq));
				4: write('exit open randomly');
				5: write('potential exit');
				6: write('xdoor, key=',p_door_key(objreq));
				7: begin
					write('timed exit, now ');
					if cycle_open then
						write('open')
					else
						write('closed');
				   end;
			end;
			if hidden <> 0 then
				write(', hidden');
			if reqverb then
				write(', reqverb');
			if not(autolook) then
				write(', autolook off');
			if here.trapto = dir then
				write(', trapdoor (',here.trapchance:1,'%)');
		end;
		writeln;
	end;
end;

procedure do_s_exits;
var
	i: integer;
	accept,one: boolean;	{ accept is true if the particular exit is
				  an "accept" (other players may link there)
				  one means at least one exit was shown }

begin
	one := false;
	gethere;

	for i := 1 to maxexit do begin
		if (here.exits[i].toloc = 0) and (here.exits[i].kind = 5) then
			accept := true
		else
			accept := false;

		if (can_alter(i)) or (accept) then begin
			if not(one) then begin	{ first time we do this then }
				getnam;		{ read room name list in }
				freenam;
				getobjnam;
				freeobjnam;
			end;
			one := true;
			anal_exit(i);
		end;
	end;

	if not(one) then
		writeln('There are no exits here which you may inspect.');
end;


{ Return object owner as value (I hope)		jlaiho@finuh }
function tell_owner(n: integer):shortstring;
var
 	s: string;

begin
	getobjown;
	freeobjown;
	s := objown.idents[n];
	s := class_out(s);	
	if substr(s,1,1)<>'<' then begin
		if lookup_user(n,objown.idents[n]) then begin
			getpers;
			freepers;
			tell_owner := pers.idents[n];
		end else
			tell_owner := '<Unknown>';
	end else if s.length>shortlen then begin
		tell_owner := substr(s,1,shortlen);
	end else
		tell_owner := substr(s,1,s.length);
end;


procedure do_s_object(s: string);
label 0;    { for panic }
var
	n,oldloc: integer;
	x: objectrec;

    function action(s: shortstring; n: integer): boolean;
    begin
	write(obj_part(n),': ');
	if objown.idents[n] = public_id then write('public')
	else if objown.idents[n] = disowned_id then write('disowned')
	else write(class_out(objown.idents[n]),' is owner');

	if obj_owner(n,TRUE) then begin
	    write(', ');
	    show_kind(obj.kind,false);
	    x := obj;

	    if x.sticky then
		write(', sticky');
	    if x.getobjreq > 0 then
		write(', ',obj_part(x.getobjreq),' required to get');
	    if x.useobjreq > 0 then
		write(', ',obj_part(x.useobjreq),' required to use');
	    if x.uselocreq > 0 then begin
		getnam;
		freenam;
		write(', used only in ',nam.idents[x.uselocreq]);
	    end;
	    if x.usealias <> '' then begin
		write(', use="',x.usealias,'"');
		if x.reqalias then
		    write(' (required)');
	    end;
	end;
	writeln;
	action := true;
	checkevents(TRUE);
	if oldloc <> location then goto 0; { panic }
    end;    { action }

    function restriction (n: integer): boolean;
	begin
		restriction := true;
	end;

    procedure leave;
    begin
	writeln('EXIT - No changes.');
	goto 0;
    end;


begin

	if length(s) = 0 then begin
		grab_line('Object? ',s,eof_handler := leave);
	end;
	getobjown;
	freeobjown;

	oldloc := location;
	if scan_obj(action,s,,restriction) then begin
	end else
		writeln('There is no such object.');
	0: { for panic }
end;

procedure do_s_monster(s: string);
label 0; { for panic }
var	n,code,oldloc: integer;
	owner, coder,name,dis,pub: shortstring;

    function restriction (n: integer): boolean;
    begin
	restriction := here.people[n].kind = P_MONSTER;
	{ can see monster even it is hiding }
    end; 

    function action(s: shortstring; n: integer): boolean;
    begin
	name := here.people[n].name;
	code := here.people[n].parm;
	owner := monster_owner(code);
	coder := monster_owner(code,1);
	write (name,': ');
	if owner = public_id then write('public')
	else if owner = disowned_id then write('disowned')
	else write (class_out(owner),' is owner');
	if ((owner = userid) or
	    (coder = userid) or 
	    (owner_priv and (owner <> system_id)) or
	    manager_priv)
	    and (coder > '') then begin
	    if coder = owner then write(' and writer')
	    else write(', ',coder,' is writer');
	end;
	writeln('.');
	action := true;
	checkevents(TRUE);
	if oldloc <> location then goto 0; { for panic }
    end;

    procedure leave;
    begin
	writeln('EXIT - No changes.');
	goto 0;
    end;

begin

	if length(s) = 0 then begin
		grab_line('Monster? ',s,eof_handler := leave);
	end;

	oldloc := location;
	if scan_pers_slot(action,s,,restriction) then begin
	end else writeln ('There is no such monster.');
	writeln;
	0: { for panic }
end;



procedure do_s_details;
var
	i: integer;
	one: boolean;

begin
	gethere;
	one := false;
	for i := 1 to maxdetail do
		if (here.detail[i] <> '') and (here.detaildesc[i] <> 0) then begin
			if not(one) then begin
				one := true;
				writeln('Details here that you may inspect:');
			end;
			writeln('    ',here.detail[i]);
		end;
	if not(one) then
		writeln('There are no details of this room that you can inspect.');
end;

procedure do_s_privs;
begin
	write ('Your authorized privileges: ');
	    list_privileges(read_auth_priv);
	write ('Your current privileges: ');
	    list_privileges(read_cur_priv);
end;

procedure do_s_time;
begin
	writeln(sysdate,'  ',systime);
end;

procedure do_s_room(s: string);
label 0;    { for panic }
var	room,oldloc: integer;

    function action(s: shortstring; room: integer): boolean;
    begin
	gethere(room);
	if here.owner = public_id then writeln(s,' is public.')
	else if here.owner = disowned_id then writeln(s,' is disowned.')
	else writeln('Owner of ',s,' is ',class_out(here.owner));
	checkevents(TRUE);
	action := true;
	if oldloc <> location then goto 0; { panic }
    end; { action }

    function restriction (n: integer): boolean;
	begin
		restriction := true;
	end;

begin

	oldloc := location;
	if s = '' then action('this room',location)
	else if not scan_room(action,s,,restriction) then begin
		writeln('No such room.');
	end;
	0: { for panic }
end;

procedure do_s_levels;
label	1;
var i,j,n,line: integer;
	s: string;

    procedure leave;
    begin
	writeln('EXIT');
	goto 1;
    end;
    
begin
    line := 1;
   write('  Name                 Score     '); { 34 }
       {  123456789012345678901234567890123 }
   if terminal_line_len > 50 then
	write('Power MaxHealth '); { 50 }
	    {  4567890123456789 }
   if terminal_line_len >= 80 then
	write('Privilege');
   writeln;
                     
   for i := 1 to levels do with leveltable[i] do 
	if not hidden or manager_priv then begin
		if hidden then write('* ') else write('  ');
		write(name);
		for j := 1 to 17-length(name) do write(' ');
		if exp > maxexperience then write('-':9,' ')
		else write(exp:9,' ');
		if terminal_line_len > 50 then begin
		    write(maxpower:9,' ');
		    write(health:9,' ');
		end;
		if (i < levels) and (terminal_line_len >= 80) then
			list_privileges(uint(priv))
		else writeln;
		line := line + 1;
		if line > terminal_page_len - 2 then begin
		    line := 0;
		    grab_line('-more-',s,erase := true,
			eof_handler := leave); if s > '' then goto 1;
		end;
	end;
    1:
end; { do_s_levels }

{ procedure type_paper moved to module CUSTOM }

procedure do_s_quota;
begin
   writeln('Counters: ');
   writeln('  Number of rooms:            ',get_counter(N_NUMROOMS,mylog):1);
   writeln('  Room quota:                 ',get_counter(N_ALLOW,mylog):1);
   writeln('  Number of accepts:          ',get_counter(N_ACCEPT,mylog):1);
   writeln('Consts: ');
   writeln('  Minimun rooms'' number:      ',min_room:1);
   writeln('  Required amount of accepts: ',min_accept:1);
   writeln('    (if more rooms than minimum rooms'' number)');
   if manager_priv then
      writeln('  Default room quota:         ',default_allow:1);
end; { do_s_quota }

procedure do_s_spell(name: string);
label	1;
var i,j,n,line: integer;
	s: string;

    myspell: spellrec;

    procedure leave;
    begin
	writeln('EXIT');
	goto 1;
    end;
var header: boolean;

    procedure spell_data(sid: integer);
    var j: integer;
    begin
	if not header then begin
	    writeln('  Spell''s name     Level');
	    {        1234567890123456  }
	    header := true;
	    line := line + 1;
	end;
	write('  ',spell_name.idents[sid]);
	for j := 1 to 17-length(spell_name.idents[sid]) do write(' ');
	writeln(myspell.level[sid]:5);
	line := line + 1;
	if line > terminal_page_len - 2 then begin
	    line := 0;
	    grab_line('-more-',s,erase := true,
		eof_handler := leave); if s > '' then goto 1;
	end;
    end;

    procedure list_spell;
    var I :integer;
	myindex: indexrec;
    begin
	getindex(I_SPELL);
	freeindex;
	myindex := indx;
	for i := 1 to myindex.top do if not myindex.free[i] then
	    if myspell.level[i] > 0 then spell_data(i);
	if not header then writeln('You don''t know any spell.');
    end;
    
begin
    line := 0;
    header := false;
    getspell_name;
    freespell_name;
    getspell(mylog);
    freespell;
    myspell := spell;
    name := lowcase(name);

    if (name = '') or (name = '*') or (name = 'all') then list_spell
    else if lookup_spell(i,name) then spell_data(i)
    else writeln('Unkown spell.');
    1:
end;

procedure s_show(n: integer;s: string);

begin
	case n of
		s_exits: do_s_exits;
		s_object: do_s_object(s);
		s_quest: command_help('*do s help*');
		s_details: do_s_details;
		s_monster: do_s_monster(s);
		s_priv: do_s_privs;
		s_time: do_s_time;
		s_room: do_s_room(s);
		s_paper: type_paper;
		s_levels: do_s_levels;
		s_quota:  do_s_quota;
		s_spell:  do_s_spell (s);
	end;
end;

{ procedures do_y_altmsg, do_group1 and do_group2 moved to module CUSTOM }

procedure do_passwd;
label exit_label;
var oldpwd,pwd,pwd_check: shortstring;
    s:  string;
    ok: boolean;

    procedure leave;
    begin
	writeln('EXIT - No changes');
	goto exit_label;
    end;

begin
	grab_line ('Old password: ', s, false,eof_handler := leave);
	if length(s) > shortlen then
		oldpwd := substr(s,1,shortlen)
	else oldpwd := s;
	encrypt(oldpwd);
	getpasswd;
	freepasswd;
	ok := passwd.idents [mylog] = oldpwd;

	if ok then begin
		grab_line ('New password: ', s, false,eof_handler := leave);
		if length(s) > shortlen then
			pwd := substr(s,1,shortlen)
		else pwd := s;
		while (pwd = '') and (userid[1] = '"') do begin
			writeln ('Sorry, you must have a password for ', myname, '.');
			grab_line ('New password: ', s, false,eof_handler := leave);
			if length(s) > shortlen then
				pwd := substr(s,1,shortlen)
			else pwd := s;
		end;
		grab_line ('Verification: ', s, false,eof_handler := leave);
		if length(s) > shortlen then
			pwd_check := substr(s,1,shortlen)
		else pwd_check := s;
		if pwd = pwd_check then begin
			ok := true;
			encrypt (pwd);

			getpasswd;
			passwd.idents [mylog] := pwd;
			putpasswd;

			writeln('Database updated.');
		end else begin
			ok := false;
			writeln ('You seem to have made a mistake. ');
			writeln ('Password not changed.');
		end;
	end else begin
			writeln ('Old password verification error.');
			writeln ('Password not changed.');
	end;
    exit_label:
end;

procedure do_y_priv(s: string);
type action = (activate, reset);
var direction: action;
    mask,prev: unsigned;
    mask2: integer;
begin
    direction := activate;
    s := slead(s);
    if s = '' then begin
	mask2 := int(read_cur_priv);
	if custom_privileges(mask2,read_auth_priv) then begin
	    set_cur_priv(uint(mask2));
	    write('Setting follow privileges: ');
	    list_privileges(read_cur_priv);
	end else writeln('Not changed.');
    end else if (s = '?') then begin
	writeln('Use set privileges + <privilege> to set privilege');
	writeln('Use set privileges - <privilege> to reset privilege');
    end else begin
	if s[1] = '+' then begin
	    direction := activate;
	    if length(s) > 1 then
		s := slead(substr(s,2,length(s)-1));
	end else if s[1] = '-' then begin
	    direction := reset;
	    if length(s) > 1 then
		s := slead(substr(s,2,length(s)-1));
	end;

	mask := 0;
	if (s = 'all') or (s = '*') then mask := all_privileges
	else if not lookup_priv(mask,s,true) then begin
	    mask := 0;
	    writeln('Unknown privilege: ',s);
	end;

	if mask > 0 then begin
	    prev := read_cur_priv;
	    if direction = reset then begin
		set_cur_priv(uand(prev,unot(mask)));
		write('Resetting follow privileges: ');
		    list_privileges(uand(prev,unot(read_cur_priv)));
	    end else begin
		set_cur_priv(uor(prev,mask));
		write('Setting follow privileges: ');
		    list_privileges(uand(read_cur_priv,unot(prev)));
	    end;
	end;
    end;

end;

procedure s_set(n: integer;s: string);

begin
	case n of
		y_quest: command_help('*do y help*');

{		y_altmsg: do_y_altmsg;
		y_group1: do_group1;
		y_group2: do_group2;	}
	
		y_passwd: do_passwd;
		y_peace: if not global_priv then 
			writeln('There is too much hate in the world.')
		    else if not read_global_flag(GF_WARTIME,TRUE) then
			writeln('The war is over already.')
		    else set_global_flag(GF_WARTIME,FALSE,
		'...And on earth peace, good will toward men (and monsters).');
		y_war: if not global_priv then 
			writeln('You are not angry enough.')
		    else if read_global_flag(GF_WARTIME,TRUE) then
			writeln('You call this peace?')
		    else set_global_flag(GF_WARTIME,TRUE,
'Go your ways, and pour out the vials of the wrath of God upon the earth.');
		y_priv: do_y_priv(s);
		y_spell: custom_spell(s);
		y_newplayer: custom_global_desc(GF_NEWPLAYER);
		y_welcome: custom_global_desc(GF_STARTGAME);
	end;
end;


procedure do_show(s: string);
label exit_label;
var
	n: integer;
	cmd: string;

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;

begin
	cmd := bite(s);
	if length(cmd) = 0 then
		grab_line('Show what attribute? (type ? for a list) ',cmd,
		    eof_handler := leave);

	if length(cmd) = 0 then
	else if lookup_show(n,cmd,true) then
		s_show(n,s)
	else
		writeln('Invalid show option, type SHOW ? for a list.');
    exit_label:
end;


procedure do_set(s: string);
label exit_label;
var
	n: integer;
	cmd: string;

    procedure leave;
    begin
	writeln('EXIT - No changes.');
	goto exit_label;
    end;

begin
	cmd := bite(s);
	if length(cmd) = 0 then
		grab_line('Set what attribute? (type ? for a list) ',cmd,
		    eof_handler := leave);
          
	if length(cmd) = 0 then
	else if lookup_set(n,cmd,true) then
		s_set(n,s)
	else
		writeln('Invalid set option, type SET ? for a list.');

    exit_label:
end;   

procedure go_dcl (s: string);
Var changed: boolean;
begin  
  log_action (c_dcl,0);
  do_dcl (s);   { Spawn subprocess .. }
  log_event (myslot,E_DCLDONE,0,0,'');
  
  { check database }
  getindex (I_ASLEEP);         
  freeindex;
  if indx.free [mylog] then { Oops ! I am in asleep ... }
    begin
      WriteLn ('You are throw out from Monster-universe during your stay on DCL-level.');
	finish_interpreter;
	halt;
    end;
          
  { Because only my process update my situation, I can suppose that
     datatabase and data in memory is valid - I hope so ...        }

end;                                                                 
          
{ hurtta@finuh }       

function x_where (player: shortstring; var pr: integer): integer;
begin
  if debug then writeln('%x_where: ',player);
  if exact_pers(pr,player) then begin
     getint(N_LOCATION);
     freeint;
     x_where := anint.int[pr]
  end else x_where := 0
end; { x_where }

procedure x_add(var string: mega_string; adding: shortstring);
begin
  if debug then writeln('%x_add: ... <- ',adding);
  if string = '' then string := adding
  else if length(string) < MEGA_LENGTH - shortlen - 3 then
    string := string + ', ' + adding
end; { x_add }

function x_slot (player: shortstring): integer;
var i: integer;
begin  
  if debug then writeln('%x_slot: ',player);
  player := lowcase(player);
  x_slot := 0;
  for i := 1 to maxpeople do 
	if here.people[i].kind > 0 then 
    		if lowcase(here.people[i].name) = player then x_slot := i
end; { x_slot }

function x_hold(n,slot: integer): boolean;
var
	i: integer;
	found: boolean;

begin
   if debug then writeln('%x_hold');
	if n = 0 then
		x_hold := false
	else begin
		i := 1;
		found := false;
		while (i <= maxhold) and (not found) do begin
			if here.people[slot].holding[i] = n then
				found := true
			else
				i := i + 1;
		end;
		x_hold := found;
	end;
end;    

function x_puttoken (from,mlog,mslot,room: integer; var aslot: integer;
                   first_x_puttoken : boolean := false;
                   a_kind: integer := P_MONSTER;
                   a_name: shortstring := ''; 
                   mcode : integer := 0): boolean;
var
	i,j: integer;
	found: boolean;
	savehold: array[1..maxhold] of integer;
        var kind,parm,hiding,wearing,wielding,health,self,
            experience: integer;
            name: shortstring;
            username: veryshortstring;
begin
   if debug then writeln('%x_puttoken');
	if first_x_puttoken then begin
		for i := 1 to maxhold do
			savehold[i] := 0;
                kind := a_kind;
                parm := mcode;
                hiding := 0;
                wearing := 0;
                wielding := 0;
                health := GOODHEALTH;
		experience := 0;
                self := 0;
                writev(username,':',mcode:1);
                name := a_name;

	end else begin
		gethere (from);               
		for i := 1 to maxhold do
			savehold[i] := here.people[mslot].holding[i];
                kind := here.people[mslot].kind;
                parm := here.people[mslot].parm;
                hiding := here.people[mslot].hiding;
                wearing := here.people[mslot].wearing;
                wielding := here.people[mslot].wielding;
                health  := here.people[mslot].health;
                self    := here.people[mslot].self;  
                name    := here.people[mslot].name;  
		experience := here.people[mslot].experience;
                username := here.people[mslot].username; { what ? }

	end;

	getroom(room);
	i := 1;
	found := false;
	while (i <= maxpeople) and (not found) do begin
		if here.people[i].kind = 0 then	{ hurtta@finuh }
			found := true
		else
			i := i + 1;
	end;
	if found and (kind <> 0) then begin
		here.people[i].kind := kind;   { probably monster }
		here.people[i].name := name;
	  	here.people[i].username := username;
		here.people[i].hiding := hiding;
			{ hidelev is zero for most everyone
			  unless you want to poof in and remain hidden }

		here.people[i].wearing := wearing;
		here.people[i].wielding := wielding;
		here.people[i].health := health;
		here.people[i].experience := experience;
		here.people[i].self := self;
		here.people[i].parm := parm;
		here.people[i].act := 0;

		for j := 1 to maxhold do
			here.people[i].holding[j] := savehold[j];
		putroom;

		aslot := i;

		{ note the user's new location in the logfile }
		getint(N_LOCATION); 
		anint.int[mlog] := room;
		putint;              
                x_puttoken := true;
	end else begin
		freeroom;
		x_puttoken := false
        end;
end;     

procedure do_monster(s: string);
label exit_label;
var mid,aslot,i,mcode: integer;
    muserid: veryshortstring;

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;

begin
   if s = '' then grab_line('Monster? ',s,eof_handler := leave);

   gethere;
   if checkhide then begin
      if not is_owner(location,TRUE) then begin
         writeln('You may only create monsters when you are in one of your own rooms.');
      end else if s <> '' then begin
         if length(s) > shortlen then
            writeln('Please limit your monster names to ',shortlen:1,' characters.')
         else if exact_pers(mid,s) then begin	{ monster already exits }
            writeln('That monster or player already exits.')
         end else begin
            if debug then
               writeln('%beggining to create monster');
            if alloc_log(mid) then begin
               if alloc_general(I_HEADER,mcode) then begin
                  if x_puttoken (0,mid,0,location,aslot,true,2,s,mcode) then begin
                     
                     create_program (mcode,userid,sysdate+' '+systime);

                     getuser;
                     writev(user.idents[mid],':',mcode:1);
                     putuser;   
                             
                     getpers;
                     pers.idents[mid] := s;
                     putpers;
          
                     getdate;
                     adate.idents[mid] := sysdate + ' ' + systime;
                     putdate;

                     getindex(I_ASLEEP);
                     indx.free[mid] := true; { Yes. Monster isn't active now }
                     putindex;
                                                                   
                     getint(N_EXPERIENCE);
                     anint.int[mid] := 0;
                     putint;
		  
                     getint(N_PRIVILEGES); { leino@finuha } 
                     anint.int[mid] := 0;  { this is ridiculous }
                     putint;

                     getint(N_SELF);
                     anint.int[mid] := 0;
                     putint;

                     getint(N_HEALTH);
                     anint.int[mid] := GOODHEALTH;
                     putint;

                     { initialize the record containing the
                       level of each spell they have to start;
                       all start at zero; since the spellfile is
                       directly parallel with mylog, we can hack
                       init it here without dealing with SYSTEM }

                     locate(spellfile,mid);
                     for i := 1 to maxspells do
                        spellfile^.level[i] := 0;
                     spellfile^.recnum := mid;
                     put(spellfile);

                     log_event(myslot,E_MADEOBJ,0,0,log_name + ' has created a monster here.');
                     writeln('Monster created.');
                  end else begin
                     writeln('This place is too crowded to create any more monsters.  Try somewhere else.');
                     delete_log (mid);
                     delete_general (I_HEADER,mcode);
                  end;
               end else begin
                   writeln ('There is no place for any more monsters in this universe.');
                   delete_log (mid);
               end;
	    end else writeln ('There is no place for any more monsters or players in this universe.') 
         end
      end else writeln('To create a monster, type BEAR <monster name>.');
   end;
   exit_label:
end; { do_monster }

procedure do_erase(s: string);
label exit_label;
var mslot,mid: integer;
    mname: shortstring;
    reply: string;
    ok,dropped: boolean;

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;

begin
  if s = '' then grab_line('Monster? ',s,eof_handler := leave);

  if length(s) = 0 then	
     writeln('To destroy a monster you own, type ERASE <monster name>.')
  else if not is_owner(location,TRUE) then { is_owner make gethere }
     writeln('You must be in one of your own rooms to destroy a monster.')
  else if parse_pers(mslot,s) then begin
     mname := here.people[mslot].name;
     if exact_pers(mid,mname) then begin    
        if here.people[mslot].kind = P_MONSTER then begin
           if (monster_owner(here.people[mslot].parm) = userid) 
              or owner_priv then begin
              getindex(I_ASLEEP);
              freeindex;
              if indx.free[mid] then ok := true
              else begin
                 writeln ('Monster is active now (or there is some problem)');
                 grab_line ('Enter [C]ontinue or [A]bort: ',reply,
		    eof_handler := leave);
                 if (reply = 'c') or (reply = 'C') then ok := true
                 else ok := false
              end;
              if ok then begin
                 dropped := drop_everything(mslot);
		 delete_program(here.people[mslot].parm);
                 delete_general(I_HEADER,
                    here.people[mslot].parm);  { release header  }
		 delete_block(here.people[mslot].self); { release       }
                                                      { selfdescription }
                 getint(N_SELF);
                 anint.int[mid] := 0;                   { also in here  }
                 putint;

                 take_token(mslot,location);
                 delete_log(mid);                                     
                 writeln ('Monster deleted.');
              end
           end else writeln ('You are not the owner of this monster.');
        end else writeln ('You can only erase monsters.');
     end else writeln ('%serious error in do_erase. Notify monster manager.');
  end else writeln ('Here isn''t that monster.');
  exit_label:
end;

{ procedure custom_monster moved to module CUSTOM }

{ procedure custom_hook moved to module CUSTOM }

procedure do_atmosphere(s: string);
begin
    if length(myname) + length(s) > string_len-2 then
	writeln('Too long atmosphere text.')
    else if s > '' then log_event(0,E_ATMOSPHERE,,,myname+' '+s);
end;

procedure do_scan(s: string);
label 0; { for panic }
var	oid: integer;
	room,i,j,num,pcarry,mcarry,oldloc: integer;
	found: Boolean;

    function action(s: shortstring; oid: integer): boolean;
    begin
	getobjown;
	freeobjown;

	if not obj_owner(oid,true) then 
	    writeln('You aren''t the owner of ',s,'.')
	else begin
	    log_event(myslot,E_SCAN);
	    getindex(I_ROOM);
	    freeindex;
	    found := false;
	    pcarry := 0;
	    mcarry := 0;
	    for room := 1 to indx.top do if not indx.free[room] then begin
		gethere(room);
				
		num := 0;
		for i := 1 to maxobjs do
		    if here.objs[i] = oid then num := num +1;

		for i := 1 to maxpeople do
		    case here.people[i].kind of 
			P_PLAYER: for j := 1 to maxhold do
			    if here.people[i].holding[j] = oid then
				pcarry := pcarry +1;
		
			P_MONSTER: for j := 1 to maxhold do
			    if here.people[i].holding[j] = oid then
				mcarry := mcarry +1;

			otherwise;
		    end; {case} 
	
		if num > 0 then begin
		    if not found then writeln (s,' found from the following rooms:');
		    found := true;
	
		    if not manager_priv and
			(((here.owner <> userid) and 
			(here.owner <> public_id) and 
			(not owner_priv)) or
			(here.owner = system_id)) then
			writeln(num:3,' n/a')
		    else writeln (num:3,' ',here.nicename);
		end;
	    end;
	    if (pcarry > 0) or (mcarry > 0) then begin
		if not found then
		    writeln(s,' found from someone:');
		if pcarry > 0 then
		    writeln(pcarry:3,' carrying by some player(s).');
		if mcarry > 0 then
		    writeln(mcarry:3,' carrying by some monster(s).');
		found := true;
	    end;
	    if not found then writeln (s,' not found.');
	end;	
	action := true;
	checkevents(TRUE);
	if oldloc <> location then goto 0; { panic }
    end; { action }

    function restriction (n: integer): boolean;
	begin
		restriction := true;
	end;

    procedure leave;
    begin
	writeln('EXIT');
	goto 0;
    end;

begin

	if s = '' then grab_line('Object? ',s,eof_handler := leave);

	oldloc := location;
	if not is_owner(location,TRUE) then begin
		writeln('You may only work on your objects when you are in one of your own rooms.');
	end else if scan_obj(action,s,,restriction) then begin
	end else writeln ('To search object use SCAN <object name>');
	0:  { for panic }
end;

function reset_object(oid: integer): boolean; { put object to it home }
var found: boolean;
    num,room,i,j: integer;
    error: boolean;
    owner: veryshortstring;
begin
    getindex(I_ROOM);	    
    freeindex;		    { not full safety - but I don't want
				lock index to whole time }

    getobj(oid);	    { lock obj -record ************************* }

    found := false;
    if obj.home = 0 then begin
	{ no home !!! }
	freeobj;	    { free obj }
    end else begin
	num := 0;
	for room := 1 to indx.top do if not indx.free[room] then begin
	    getroom(room);			    { lock room }
				
	    if not manager_priv and
			(((here.owner <> userid) and 
			(here.owner <> public_id) and 
			(not owner_priv)) or
			(here.owner = system_id)) then
			{ NO ACTION }
	    else for i := 1 to maxobjs do
		    if here.objs[i] = oid then begin
			num := num +1;
			here.objs[i] := 0;		    { RESET }
			here.objhide[i] := 0;
		    end;

		    for i := 1 to maxpeople do
			case here.people[i].kind of 
		    
			    P_MONSTER: begin
				owner := monster_owner(here.people[i].parm);
				if not manager_priv and
				    (((owner <> userid) and 
				    (owner <> public_id) and 
				    (not owner_priv)) or
				    (owner = system_id)) then
				    { NO ACTION }
				else for j := 1 to maxhold do
				    if here.people[i].holding[j] = oid then begin
					num := num +1;
					here.people[i].holding[j] := 0; { RESET }
				    end;
			    end;
			    otherwise;
			end; {case} 
	    putroom;				    { free room }
	end; { for room }
	error := false;
	found := num > 0;

	if found then begin

	    getroom(obj.home);			    { lock room }
	    i := 1;
	    found := false;
	    while (i <= maxobjs) and (not found) do begin
		if here.objs[i] = 0 then
			found := true
		else
			i := i + 1;
	    end;
	    if found then begin
		here.objs[i] := oid;
		here.objhide[i] := 0;
		num := num -1;
	    end;
	    putroom;		{ free room location }

	end;

	obj.numexist := obj.numexist -num;
	if obj.numexist < 0 then begin
	    obj.numexist := 0;
	    error := true;
	end;

	putobj;					    { free obj }

	if error then begin
	    writeln('%Database invalid. Object count of ',
		obj.oname,' is wrong.');
	    writeln('%Notify Monster Manager.');
	end;
    end;
    reset_object := found;
end;

procedure do_reset(s: string);
label 0; { for panic }
var	oid: integer;
	room,i,oldloc: integer;
	found: Boolean;

    function action(s: shortstring; oid: integer): boolean;
    begin
	getobjown;
	freeobjown;

	if not obj_owner(oid,true) then 
	    writeln('You aren''t the owner of ',s,'.')
	else begin
	    log_event(myslot,E_RESET,s := s);

	    if reset_object(oid) then writeln(s,' moved to home position.')
	    else writeln('Failing to reset ',s);

	end;
	action := true;
	checkevents(TRUE);
	if oldloc <> location then goto 0; { panic }
    end; { action }

    function restriction (n: integer): boolean;
	begin
		restriction := true;
	end;

    procedure leave;
    begin
	writeln('EXIT');
	goto 0;
    end;

begin

	if s = '' then grab_line('Object? ',s,eof_handler := leave);

	oldloc := location;
	if not is_owner(location,TRUE) then begin
		writeln('You may only work on your objects when you are in one of your own rooms.');
	end else if scan_obj(action,s,,restriction) then begin
	end else writeln ('To move object to home position use RESET <object name>');
	0:  { for panic }
end; { do_reset }

{ alaises }

procedure alias_list(s: string);
label 0;
    procedure leave;
    begin
	writeln('QUIT');
	goto 0;
    end;
var what: shortstring;
    g: o_type;

begin
    if s = '' then grab_line('List what? ',s,eof_handler := leave);
    if s > '' then begin
	what := bite(s);
	if lookup_type(g,what,true,true) then case g of
	    t_room:	do_rooms(s);
	    t_object:	do_objects(s);
	    t_monster:	do_monsters(s);
	    t_spell:	do_spells(s);
	    t_player:   do_players(s);
	end { case }
	else writeln('You can''t do that.');
    end else writeln('You can''t do that.');
    0: 
end;

procedure alias_create(s: string);
label 0;
    procedure leave;
    begin
	writeln('QUIT');
	goto 0;
    end;
var what : shortstring;
    g: o_type;
begin
    if s = '' then grab_line('Create what? ',s,eof_handler := leave);
    if s > '' then begin
	what := bite(s);
	if lookup_type(g,what,false,true) then case g of
	    t_room:	do_form(s);
	    t_object:	do_makeobj(s);
	    t_monster:	do_monster(s);
	    t_spell:	writeln('You can''t do that.');
	    t_player:	writeln('You can''t do that.');
	end { case }
	else writeln('You can''t do that.');
    end else writeln('You can''t do that.');
    0: 
end;

procedure alias_delete(s: string);
label 0;
    procedure leave;
    begin
	writeln('QUIT');
	goto 0;
    end;
var what : shortstring;
    g: o_type;
begin
    if s = '' then grab_line('Delete what? ',s,eof_handler := leave);
    if s > '' then begin
	what := bite(s);
	if lookup_type(g,what,false,true) then case g of
	    t_room:	do_zap(s);
	    t_object:	do_destroy(s);
	    t_monster:	do_erase(s);
	    t_spell:	writeln('You can''t do that.');
	    t_player:	writeln('You can''t do that.');
	end { case }
	else writeln('You can''t do that.');
    end else writeln('You can''t do that.');
    0: 
end;

{ -------- }


procedure do_error(cmd,param: string);
label 0; { for panic }
var error: boolean;
    n,oldloc: integer;

    function action_obj(s: shortstring; n: integer): boolean;
    begin
	    getobj(n);
	    freeobj;
	    if obj.actindx = 0 then action_obj := false
	    else action_obj := run_monster('',obj.actindx,'command','command',
		cmd,sysdate+' '+systime);
	checkevents(TRUE);
	if oldloc <> location then goto 0; { panic }
    end; { action_obj }

    function restriction (n: integer): boolean;
    begin
	restriction := obj_here(n,false) or obj_hold(n);
	{ false = found also hidden objects }
    end;

    function res_monster (n: integer): boolean;
    begin
	res_monster := here.people[n].kind = P_MONSTER;
	{ can found also hiding monster's }
    end;

    function action_monster(s: shortstring; n: integer): boolean;
    begin
       if here.people[n].parm = 0 then action_monster := false
       else action_monster := run_monster(here.people[n].name,
          here.people[n].parm,'command','command',cmd,sysdate+' '+systime);
	checkevents(TRUE);
	if oldloc <> location then goto 0; { panic }
    end;

begin
   error := false;
   oldloc := location;
   cmd := lowcase(cmd);
   if length(param) > shortlen then error := true
   else if param = '' then begin
      gethere;
      if here.hook = 0 then error := true
      else error := not run_monster('',here.hook,'command','command',
         cmd,sysdate+' '+systime);
   end else if scan_obj(action_obj,param,true,restriction) or
	      scan_pers_slot(action_monster,param,true,res_monster) then begin
   end else error := true;
   if error then writeln('You can''t do that.');
   0: { for panic }
end; 

procedure parser;
label 9999;
var
	s: string;
	cmd: string;
	n,i: integer;
	dummybool: boolean;

        procedure leave;
	begin
	    writeln('QUIT');
	    in_main_prompt := false;
	    done := true;
	    goto 9999;
	end;

       
begin
   in_main_prompt := true;
   repeat
	if hiding then grab_line('(>) ',s,eof_handler := leave)
	else grab_line('> ',s,eof_handler := leave);
	s := slead(s);
   until length(s) > 0;
   in_main_prompt := false;


	if s = '.' then
		s := oldcmd
	else
	  	oldcmd := s;
          
	if (s[1]='''') and (length(s) > 1) then
		do_say(substr(s,2,length(s)-1))
	else if (s[1]=':') and (length(s) > 1) then
		do_atmosphere(substr(s,2,length(s)-1))
	else if (lookup_alias(n,s)) or
	        (lookup_dir(n,s)) then begin
		do_go(s);
	end else begin
		cmd := bite(s);

		{ for help: }
		if s = '?' then begin

		    i := lookup_cmd(cmd);
		    if i = error then command_help(cmd)
		    else command_help(cmds[i]);

		end else case lookup_cmd(cmd) of
			error: do_error(cmd,s);
			setnam: do_setname(s);
	  		help,quest: command_help('*show help*');
			quit: done := true;
			c_l,look: do_look(s);
			c_atmosphere: do_atmosphere(s);
			c_summon: do_summon(s);
			go: do_go(s,FALSE);	{ FALSE = dir not a verb }
			form: do_form(s);
			link: do_link(s);
			unlink: do_unlink(s);
			poof: do_poof(s);
			desc: do_describe(s);
			say: do_say(s);
			c_scan: do_scan(s);
			c_rooms: do_rooms(s);
			c_claim: do_claim(s);
			c_disown: do_disown(s);
			c_public: do_public(s);
			c_accept: do_accept(s);
			c_refuse: do_refuse(s);
			c_zap: do_zap(s);

			c_north,c_n,
			c_south,c_s,
			c_east,c_e,
			c_west,c_w,
			c_up,c_u,
			c_down,c_d: do_go(cmd);

			c_who: do_who (s);
			c_custom: do_custom(s);
			c_search: do_search(s);
			c_system: do_system(s);
			c_hide: do_hide(s);
			c_unhide: do_unhide(s);
			c_punch: do_punch(s);
			c_ping: do_ping(s);
			c_create: do_makeobj(s);
			c_get: do_get(s);
			c_drop: do_drop(s);
			c_i,c_inv: do_inv(s);
			c_whois: do_whois(s);
			c_players: do_players(s);
			c_health: do_health(s);
			c_duplicate: do_duplicate(s);
			c_score: do_score(s);
			c_version: do_version(s);
			c_objects: do_objects (s);
			c_spells: do_spells(s);
			c_self: do_self(s);
			c_use: do_use(s);
			c_whisper: do_whisper(s);
			c_wield: do_wield(s);
			c_brief: do_brief;
			c_wear: do_wear(s);
			c_destroy: do_destroy(s);
			c_relink: do_relink(s);
			c_unmake: do_unmake(s);
			c_show: do_show(s);
			c_set: do_set(s);
                                          
			c_monster: do_monster(s);
			c_monsters: do_monsters(s);
                        c_erase: do_erase(s);
			c_reset: do_reset(s);

			A_list:   alias_list(s);
			A_delete: alias_delete(s);
			A_create: alias_create(s);

			dbg: begin
				if debug then begin
					debug := false;
					writeln('Debugging is off.')
				end else begin
					if manager_priv or gen_debug then begin
						debug := true;
						writeln('Debugging is on.');
					end else writeln ('DEBUG isn''t for you.');
			        end;
                             end;
                        
                        c_dcl: go_dcl (s);

			otherwise begin
	  			writeln('%Parser error, bad return from lookup');
			end;
		end;
		clear_command;
	end;
	9999:
end;

procedure very_init;
begin

	rndcycle := 0;
	location := 1;		{ Great Hall }

	mywield := 0;		{ not initially wearing or weilding any weapon }
	mywear := 0;
	mydisguise := 0;
	myhealth := GOODHEALTH;	{ how healthy they are to start }
	healthcycle := 0;	{ pretty much meaningless at the start }
        myexperience := 0;
        userid := lowcase(get_userid);

	real_userid := userid;
	{*** Some minor changes below. jlaiho@finuh ***}
{	privd := false;  }
	if (userid = MM_userid) then begin
		myname := 'Monster Manager';
		wizard := true;
 	end else begin
 		myname := lowcase(userid);
 		if myname[1] >= 'a' then 
			myname[1] := chr( ord('A') + 
			    (ord(myname[1]) - ord('a')));
	end;
end;

function init: boolean;
var
	i: integer;
	s: string;

begin
	{ MOVED to very_init }

	{*** End of changed area. jlaiho@finuh ***}
	numcmds:= 76; { minor change by hurtta@finuh }

	show[s_exits] := 'exits';
	show[s_object] := 'object';
	show[s_quest] := '?';
	show[s_details] := 'details';
	show[s_monster] := 'monster';
	show[s_priv] := 'privileges';
	show[s_time] := 'time';
	show[s_room] := 'room';
	show[s_paper] := 'commands.paper';
	show[s_levels] := 'levels';
	show[s_quota] := 'quota';
	show[s_spell] := 'spells';
	
	numshow := 12;

	setkey[y_quest] := '?';

{	setkey[y_altmsg] := 'altmsg';
	setkey[y_group1] := 'group1';
	setkey[y_group2] := 'group2';	}
       
	setkey[y_passwd] := 'password';
	setkey[y_peace]  := 'peace';
	setkey[y_war]	 := 'war';
	setkey[y_priv]   := 'privileges';
	setkey[y_spell]  := 'spell';
	setkey[y_newplayer] := 'newplayer';
	setkey[y_welcome] := 'welcome';
	numset := 8;

	init := open_database;
end;


procedure welcome_back(var mylog: integer);
var
	tmp: string;
	sdate,stime: shortstring;

begin
	getdate;
	freedate;

	write('Welcome back, ',myname,'.');
	if length(myname) > 18 then
		writeln;

	write('  Your last play was on');

	if length(adate.idents[mylog]) < 11 then begin
		writeln(' ???');
	end else begin
		sdate := substr(adate.idents[mylog],1,11);	{ extract the date }
		if length(adate.idents[mylog]) = 19 then
			stime := substr(adate.idents[mylog],13,7)
		else
			stime := '???';

		if sdate[1] = ' ' then
			tmp := sdate
		else
			tmp := ' ' + sdate;

		if stime[1] = ' ' then
			tmp := tmp + ' at' + stime
		else
			tmp := tmp + ' at ' + stime;
		writeln(tmp,'.');
	end;
	writeln;
end;


function loc_ping:boolean;
var
	i: integer;
	found: boolean;

begin
	if debug then begin
	    writeln('%loc_ping: location = ',location:1);
	    writeln('%          myname   = ',myname);
	end;
	inmem := false;
	gethere;

	i := 1;
	found := false;

		{ first get the slot that the supposed "zombie" is in }
	while (not found) and (i <= maxpeople) do begin
		if here.people[i].kind = P_PLAYER then { hurtta@finuh }
			if here.people[i].name = myname then
				found := true
			else
				i := i + 1
		else i := i + 1;
	end;

	myslot := 0;	{ setup for ping_player }

	if found then begin
		setevent;
		loc_ping := ping_player(i,TRUE);  { TRUE = silent operation }
	end else
		loc_ping := true;
			{ well, if we can't find them, let's assume
			  that they're not in any room records, so they're
			  ok . . . Let's hope... }
end;



{ attempt to fix the player using loc_ping if the database incorrectly
  shows someone playing who isn' playing }

function fix_player:boolean;
var
	ok: boolean;

begin
	writeln('There may have been some trouble the last time you played.');
	writeln('Trying to fix it . . .');
	if loc_ping then begin
		writeln('All should be fixed now.');
		writeln;
		fix_player := true;
	end else begin
		writeln('Either someone else is playing Monster on your account, or something is');
		writeln('very wrong with the database.');
		writeln;
		fix_player := false;
	end;
end;


function revive_player(var mylog: integer): boolean;
var
	ok: boolean;
	i,n: integer;
	s: string;
	pwd, pwd_check: shortstring;
	privs, lev: integer;

        procedure panic;
	begin
	    writeln('--- NO ---');
	    halt;
	end;


begin
	if exact_user(mylog,userid) then begin	{ player has played before }
		if userid[1] = '"' then begin
			if wizard then begin
				wizard := false;
				ok := true;
			end else begin
			{	starting := true; }
				myslot := 0;
				setevent;    { for  grab_line }
				i := 0;
				ok := false;
				getpasswd;
				freepasswd;
				repeat
					grab_line ('Password: ', s, FALSE,
					    eof_handler := panic);
					if length(s) > shortlen then
						pwd := substr(s,1,shortlen)
					else pwd := s;
					encrypt (pwd);
					if pwd = passwd.idents [mylog] then
						ok := true;
					i := i + 1;
				until (ok) or (i > 2);
			{	starting := false;   }
			end
		end else
			ok := true;
		if ok then begin
			getint(N_LOCATION);
			freeint;
			location := anint.int[mylog];	{ Retrieve their old loc }
	
			{ make unique userid - that is fast bug fixing }
			getuser;
			freeuser;
			userid := user.idents[mylog];

			getpers;
			freepers;
			myname := pers.idents[mylog];	{ Retrieve old personal name }
	
			getint(N_EXPERIENCE);
			freeint;
			myexperience := anint.int[mylog];
	
			getint(N_SELF);
			freeint;
			myself := anint.int[mylog];
	
			getint(N_HEALTH);		{ hurtta@finuh }
			freeint;
			myhealth := anint.int[mylog];

			getindex(I_ASLEEP);
			freeindex;
	
			getint(N_PRIVILEGES);
			freeint;
			privs := anint.int(.mylog.);
			set_auth_priv(uint(privs)); { here is call ready }
			set_cur_priv(uint(privs));

			if indx.free[mylog] then begin
					{ if player is asleep, all is well }
				ok := true;
			end else begin
					{ otherwise, there is one of two possibilities:
						1) someone on the same account is
						   playing Monster
						2) his last play terminated abnormally
					}
				ok := fix_player;
			end;
	
			if ok then
				welcome_back(mylog);
		end;

	end else begin	{ must allocate a log block for the player }

	 
		if alloc_log(mylog) then begin


			gethere (START_LOCATION);

			writeln('Welcome to Monster, ',myname,'!');
			writeln('You will start in the ',here.nicename,'.');
			writeln;


			{ Store their userid }
			getuser;
			user.idents[mylog] := lowcase(userid);
			putuser;

			{ Store their userid }
			getreal_user;
			real_user.idents[mylog] := lowcase(real_userid);
			putreal_user;

			{ Store their names }
			getpers;
			pers.idents[mylog] := myname;
			putpers;


			{ Set their initial location }
			getint(N_LOCATION);
			anint.int[mylog] := START_LOCATION;	
				    { Start out in Great Hall }
			putint;
			location := START_LOCATION;

			if (userid = MM_userid) then 
				myexperience := MaxInt
			else myexperience := 0;
	 		getint(N_EXPERIENCE);
	 		anint.int[mylog] := myexperience;
			putint;
			myexperience := 0;

	 		getint(N_PRIVILEGES); { leino@finuha }
			if userid = MM_userid then
				anint.int[mylog] := all_privileges
			else
				anint.int[mylog] := 0;
			putint;

			set_auth_priv(uint(anint.int[mylog])); { here is call ready }
			set_cur_priv(uint(anint.int[mylog]));


			getint(N_SELF);
			anint.int[mylog] := 0;
			putint;
			myself := 0;

			{ quotas hurtta@finuh }
			getint(N_NUMROOMS);
			anint.int[mylog] := 0;
			putint;
			getint(N_ALLOW);
			anint.int[mylog] := default_allow;
			putint;
			getint(N_ACCEPT);
			anint.int[mylog] := 0;
			putint;

			lev := level(myexperience);
			myhealth := leveltable[lev].health * 7 div 10;
			getint(N_HEALTH);
			anint.int[mylog] := myhealth;
			putint;

				{ initialize the record containing the
				  level of each spell they have to start;
				  all start at zero; since the spellfile is
				  directly parallel with mylog, we can hack
				  init it here without dealing with SYSTEM }

			locate(spellfile,mylog);
			for i := 1 to maxspells do
				spellfile^.level[i] := 0;
			spellfile^.recnum := mylog;
			put(spellfile);

			if userid[1] = '"' then begin
				{starting := true;  }
				setevent;
				myslot := 0; { for grab_line }
				wizard := false;
				repeat
					grab_line ('New password: ', s, false,
					    eof_handler := panic);
					if length(s) > shortlen then
						pwd := substr(s,1,shortlen)
					else pwd := s;
					while pwd = '' do begin
						writeln ('Sorry, you must have a password for ', myname, '.');
						grab_line ('New password: ', s
						    , false,eof_handler := panic);
						if length(s) > shortlen then
							pwd := substr(s,1,shortlen)
						else pwd := s;
					end;
					grab_line ('Verification: ', s, false,
					    eof_handler := panic);
					if length(s) > shortlen then
						pwd_check := substr(s,1,shortlen)
					else pwd_check := s;
					if pwd = pwd_check then begin
						ok := true;
						encrypt (pwd);
					end else begin
						ok := false;
						writeln ('You seem to have made a mistake. Please try again.');
					end;
				until ok;
			{	starting := false;  }
			end else pwd := '';

			{ Store their password }
			getpasswd;
			passwd.idents [mylog] := pwd;
			putpasswd;

			ok := true;
		end else
			ok := false;
	end;

	if ok then begin { Successful, MYLOG is my log slot }

		{ Wake up the player }
		getindex(I_ASLEEP);
		indx.free[mylog] := false;	{ I'm NOT asleep now }
		putindex;

		{ Set the "last date of play" }
		getdate;
		adate.idents[mylog] := sysdate + ' ' + systime;
		putdate;
	end else
		writeln('There is no place for you in Monster.  Contact the Monster Manager.');
	revive_player := ok;
end;


function enter_universe:boolean;
var
	orignam: string;
	dummy,i,old_loc: integer;
	ok: boolean;

begin


		{ take MYNAME given to us by init or revive_player and make
		  sure it's unique.  If it isn't tack _1, _2, etc onto it
		  until it is.  Code must come before alloc_log, or there
		  will be an invalid pers record in there cause we aren't in yet
		}
		orignam := myname;
		i := 0;
		repeat	{ tack _n onto pers name until a unique one is found }
			ok := true;

{*** Should this use exact_pers instead?  Is this a copy of exact_pers code? }

			if lookup_pers(dummy,myname) then
				if lowcase(pers.idents[dummy]) = lowcase(myname) then begin
					ok := false;
					i := i + 1;
					writev(myname,orignam,'_',i:1);
				end;
		until ok;

	if revive_player(mylog) then begin

	    if not play_allow then begin	{ don't play work time }

		write_message;

		{ mark player not play yet }
		getindex(I_ASLEEP);
		indx.free[mylog] := TRUE;	{ I'm asleep now }
		putindex;

		enter_universe := false;

	    end else if not read_global_flag(GF_ACTIVE) 
		and not manager_priv then begin
		    writeln('Monster is shutdown.');
		    writeln('Notify Monster Manager.');
		    Enter_universe := False;

		    { mark player not play yet }
		    getindex(I_ASLEEP);
		    indx.free[mylog] := TRUE;	{ I'm asleep now }
		    putindex;
	    end else if put_token(location,myslot) then begin
		enter_universe := true;
		log_begin(location);
		setevent;
		old_loc := location;

		if (location = START_LOCATION) and
		   (myexperience = 0) then 
		       print_global(GF_NEWPLAYER,FALSE)
		else print_global(GF_STARTGAME,FALSE);
		    
		do_look;
		exec_global(GF_CODE,FORCE_READ := TRUE,LABEL_NAME := 'start');
		if (old_loc = location) and (here.hook > 0) then
			run_monster('',here.hook,'start',
				'','',
       				sysdate+' '+systime);
		if old_loc = location then meta_run('enter','','');
		if old_loc = location then meta_run_2('start','','');

		if not read_global_flag(GF_ACTIVE) then
		    writeln('WARNING: Monster is shutdown!');

	    end else begin
		writeln('put_token failed.');
		enter_universe := false;
	    end;
	end else begin
		writeln('revive_player failed.');
		enter_universe := false;
	end;
end;

procedure leave_universe;
var
	diddrop: boolean;
	temp: integer;

begin
	meta_run('leave','target','');
	exec_global(GF_CODE,LABEL_NAME := 'quit');
	temp := mydisguise;
	diddrop := drop_everything;
	mydisguise := temp;	{ this is wrong information but necessary }
	log_quit(location,diddrop);
	take_token(myslot,location);
	do_endplay(mylog);

	writeln('You vanish in a brilliant burst of multicolored light.');
	if diddrop then
		writeln('All of your belongings drop to the ground.');
end;


{ global procedures for module interpreter } { hurtta@finuh }

{ int_lookup_player moved to PARSER.PAS }

{ int_lookup_object moved to PARSER.PAS }

{ int_lookup_room moved to PARSER.PAS }
 
[global]
function int_heal(player: shortstring; amount: integer): boolean;
var room,pid,lev,top,mslot,health: integer;
begin
   if debug then begin
      writeln('%int_heal: ',player);
      writeln('%                 : ',amount);
   end;
   int_heal := false;
   if player > '' then begin
      room := x_where(player,pid);
      if room > 0 then begin
         getroom(room);			{ locking }
         mslot := x_slot(player);
         if mslot = 0 then freeroom 	{ unlocking }
         else if here.people[mslot].kind = P_MONSTER then begin
            lev := level(here.people[mslot].experience);
            top := leveltable[lev].health;
            health := here.people[mslot].health;
            health := health + amount;
            if health > top then health := top;
            here.people[mslot].health := health;
            int_heal := true;
            putroom;			{ writing }
            getint(N_HEALTH);
            anint.int[pid] := health;
            putint;
         end else if pid = mylog then begin 
           if (myexperience >= protect_exp) { and protected_MM } then 
              freeroom			{ unlocking }
           else begin                         
              lev := level(myexperience);
              top := leveltable[lev].health;
              myhealth := myhealth + amount;
              if myhealth > top then myhealth := top;
              here.people[mslot].health := myhealth;
              int_heal := true;
              putroom;			{ writing }
              getint(N_HEALTH);
              anint.int[pid] := myhealth;
              putint;
           end;
         end else begin
           freeroom; 			{ unlocking }
           writeln('%serious error in int_heal. Notify Monster Manager.');
         end;
      end;
   end;
end; { int_heal }


[global]
function int_ask_privilege(player,privilege: shortstring): boolean;
var room,pid,priv: integer;
    mask: unsigned;
begin
   if debug then begin
      writeln('%int_ask_privilege: ',player);
      writeln('%                 : ',privilege);
   end;
   int_ask_privilege := false;
   room := x_where(player,pid);
   if room > 0 then begin
      getint(N_PRIVILEGES);
      freeint;
      priv := anint.int[pid];
      if lookup_priv(mask,privilege) then
	int_ask_privilege := uand(mask,uint(priv)) > 0
      else if privilege = 'wizard' then begin  { pseudo privilege : Monster Manager }
         getuser;
         freeuser;
         int_ask_privilege := user.idents[pid] = MM_userid;
      end; 
   end;
end; { int_ask_privilege }

[global]
function int_set_experience(player: shortstring; amount: integer): boolean;
var pid,pslot,room,adding: integer;
begin
   if debug then begin
      writeln('%int_set_experience: ',player);
      writeln('%                  : ',amount:1);
   end;
   if player = '' then int_set_experience := false
   else begin
      room := x_where(player,pid);
      if room = 0 then int_set_experience := false
      else begin
         gethere(room);
         pslot := x_slot(player);
         if pslot = 0 then int_set_experience := false
         else if (here.people[pslot].kind <> P_MONSTER) and (pid <> mylog) then begin
            writeln('%serious error in int_set_experience.');
            writeln('%notify Monster Manager.');
         end else begin
            if pid = mylog then begin
               if amount > myexperience then 
                  add_experience(amount - myexperience)
               else
                  low_experience(myexperience - amount);
            end else begin
               getroom(room);   { locking }
               if lowcase(here.people[pslot].username) <> lowcase(player) then freeroom
               else begin
                  here.people[pslot].experience := amount;
                  putroom;
               end;
               getint(N_EXPERIENCE);
               anint.int[pid] := amount;
               putint;
               int_set_experience := true;
            end;
         end;
      end;
   end;
end; { int_set_experience }

[global]
function int_get_experience(player: shortstring): integer; { = -1 not found }
var pid: integer;
begin
   if debug then writeln('%int_get_experience: ',player);
   if exact_pers(pid,player) then begin
     getint(N_EXPERIENCE);
     freeint;
     int_get_experience := anint.int[pid];
   end else int_get_experience := -1;
end; { int_get_experience }

[global]
function int_get_health(player: shortstring): integer; { = -1 not found }
var pid,room: integer;
begin
   if debug then writeln('%int_get_health: ',player);
   if exact_pers(pid,player) then begin
     getint(N_HEALTH);
     freeint;
     int_get_health := anint.int[pid];
   end else int_get_health := -1;
end; { int_get_health }

[global]
function int_userid(player: shortstring): shortstring; { = "" not found }
var pid: integer;
begin
   if debug then writeln('%int_get_health: ',player);
   if exact_pers(pid,player) then begin
       getuser;
       freeuser;
       int_userid := user.idents[pid];
   end else int_userid := '';
end; { int_get_health }
      
[global]  
function int_inv (player: shortstring): mega_string;
var result: mega_string;
    room,i,pid,oid,slot: integer;     
begin 
   if debug then writeln('%int_inv: ',player);
   getobjnam;
   freeobjnam;
   result := '';
   if player > '' then begin
      room := x_where (player,pid);
      if room > 0 then begin
         gethere(room);
         slot := x_slot(player);
         if slot > 0 then
            for i := 1 to maxhold do begin
               oid := here.people[slot].holding[i];
               if oid > 0 then x_add(result,objnam.idents[oid])
            end;
      end;
   end;
   int_inv := result
end; { int_inv }

[global]
function int_get_code(player: shortstring): integer; { = 0 not found }
var pid,room,slot: integer;
begin
   if debug then writeln('%int_get_code: ',player);
   room := x_where(player,pid);
   if room = 0 then int_get_code := 0
   else begin
      gethere(room);
      slot := x_slot(player);
      if slot > 0 then int_get_code := here.people[slot].parm
      else int_get_code := 0;
   end;
end; { int_get_code}

[global]  
function int_objects (player: shortstring): mega_string;
var result: mega_string;
    room,i,pid,oid,slot: integer;     
begin 
   if debug then writeln('%int_objects: ',player);
   getobjnam;
   freeobjnam;
   result := '';
   if player > '' then begin
      room := x_where (player,pid);
      if room > 0 then begin
         gethere(room);
         slot := x_slot(player);
         if slot > 0 then
            for i := 1 to maxobjs do begin
               oid := here.objs[i];
               if oid > 0 then x_add(result,objnam.idents[oid])
            end;
      end;
   end;
   int_objects := result
end; { int_objects }

[global]       
function int_l_object: mega_string;
var result: mega_string;
    i: integer;
begin
   if debug then writeln('%int_l_object');
   getindex(I_OBJECT);
   freeindex;
   getobjnam;
   freeobjnam;
   result := '';
   for i := 1 to indx.top do if not indx.free[i] then
     x_add(result,objnam.idents[i]);
   int_l_object := result;
end;

[global]
function int_l_player: mega_string;
var result: mega_string;
    i: integer;
begin
   if debug then writeln('%int_l_player');
   getindex(I_PLAYER);
   freeindex;
   getpers;
   freepers;
   result := '';
   for i := 1 to indx.top do if not indx.free[i] then
     x_add(result,pers.idents[i]);
   int_l_player := result;
end; 

[global]
function int_l_room: mega_string;
var result: mega_string;
    i: integer;
begin
   if debug then writeln('%int_list_room');
   getindex(I_ROOM);
   freeindex;
   getnam;
   freenam;
   result := '';
   for i := 1 to indx.top do if not indx.free[i] then
     x_add(result,nam.idents[i]);
   int_l_room := result;
end; 


[global] 
procedure int_broadcast(player: shortstring; s: string; to_other: boolean);
var room,i,pid,oid,code: integer;     
begin
   if debug then begin 
      writeln('%int_broadcast: ',player);
      writeln('%             : ',s);
      writeln('%             : ',to_other);
   end;
   if player = '' then room := location
   else room := x_where (player,pid);
   code := 0;
   if to_other then code := myslot;
   if room > 0 then log_event(code,E_BROADCAST,,,s,room);
   checkevents(true);
end; { int_broadcast }                      

[global]
function int_players(player: shortstring): mega_string;
var result: mega_string;
    room,i,pid: integer;
    name: shortstring;     
begin               
   if debug then writeln('%int_players: ',player);
   result := '';
   if player = '' then room := location
   else room := x_where (player,pid);
   if room > 0 then
      gethere(room);
      for i := 1 to maxpeople do begin
          name := here.people[i].name; 
          if here.people[i].kind <> P_PLAYER then name := '';
                             { don't get monsters }
          if name > '' then x_add(result,name)
      end;
  int_players := result
end; { int_players }                      

[global] 
function int_remote_players (room: shortstring): mega_string;
var result: mega_string;
    n,i: integer;
    name: shortstring;     
begin               
   if debug then writeln('%int_remote_players: ',room);
   result := '';
   if exact_room(n,room) then begin
      gethere(n);
      for i := 1 to maxpeople do begin
          name := here.people[i].name; 
          if here.people[i].kind <> P_PLAYER then name := '';
                             { don't get monsters }
          if name > '' then x_add(result,name)
      end;
   end;
   int_remote_players := result;
end; { int_remote_players }

[global] 
function int_remote_objects (room: shortstring): mega_string;
var result: mega_string;
    n,i,oid: integer;
    name: shortstring;     
begin               
   if debug then writeln('%int_remote_objects: ',room);
   getobjnam;
   freeobjnam;
   result := '';
   if exact_room(n,room) then begin
      gethere(n);
      for i := 1 to maxobjs do begin
         oid := here.objs[i];
         if oid > 0 then x_add(result,objnam.idents[oid])
      end;
   end;
   int_remote_objects := result;
end; { int_remote_objects }

[global]
function int_duplicate(player,object,owner: shortstring;
                       privileged: boolean): boolean;
var room,i,pid,oid,slot,mslot: integer;     
    found : boolean;
begin                                     
   if debug then begin
      writeln('%int_duplicate: ',player);
      writeln('%             : ',object);
      writeln('%             : ',owner);
      writeln('%             : ',privileged);
   end;                            
   if player > '' then begin
      room := x_where (player,pid);         
      if room > 0 then begin
         gethere(room); 
         if exact_obj (oid,object) then begin
            getobjown;
            freeobjown;
            if (objown.idents[oid] <> owner) and not privileged then oid := 0;
         end else oid := 0;

         mslot := x_slot(player);          { monster slot }
         if mslot = 0 then int_duplicate := false
         else if here.people[mslot].kind = P_MONSTER then begin { monster }
            if oid > 0 then begin
               if mslot > 0 then begin
	          getroom(room);                    { locking }
                  i := 1;
	          found := false;
	          while (i <= maxhold) and (not found) do begin
		     if here.people[mslot].holding[i] = 0 then
			found := true
		     else
			i := i + 1;
	          end;
	          if found then begin
	       	     here.people[mslot].holding[i] := oid;
	       	     putroom;        
                     getobj(oid);
                     obj.numexist := obj.numexist +1;
                     putobj;
                     int_duplicate := true;
	          end else begin
		     freeroom;
                     int_duplicate := false
                  end
               end
            end else int_duplicate := false    { someone is moving monster ? }
         end else if pid = mylog then begin { player }
            if oid > 0 then begin
               if hold_obj(oid) then begin
                     getobj(oid);
                     obj.numexist := obj.numexist +1;
                     putobj;
                     int_duplicate := true;
               end else int_duplicate := false;
            end else int_duplicate := false
         end else begin          
            writeln ('%serious error in int_duplicate. Notify Monster Manager.');
            int_duplicate := false;
         end
      end else int_duplicate := false;
   end else int_duplicate := false;
end;

[global]
function int_destroy(player,object,owner: shortstring;
	 privileged: boolean): boolean;
var room,i,pid,oid,slot,mslot: integer;     
    found : boolean;
begin
   if debug then begin
      writeln('%int_destroy: ',player);
      writeln('%           : ',object);
      writeln('%           : ',owner);
      writeln('%           : ',privileged);
   end;
   if player > '' then begin
      room := x_where (player,pid);
      if room > 0 then begin
         gethere(room);  
         mslot := x_slot(player);  
         if mslot = 0 then oid := 0    { is  monster moving ? }
         else if exact_obj (oid,object) then begin
            getobjown;
            freeobjown;
            if (objown.idents[oid] <> owner) and not privileged then oid := 0
            else if not x_hold (oid,mslot) then oid := 0
         end else oid := 0;
     
         if mslot = 0 then int_destroy := false
         else if here.people[mslot].kind = P_MONSTER then begin { monster }
            if oid > 0 then begin
               slot := find_hold(oid,mslot);     { object current slot }
	       if slot > 0 then begin            { is object here yet ? }
                  getroom(room);                    { locking }
	          if here.people[mslot].holding[slot] = oid then begin
	       	     here.people[mslot].holding[slot] := 0;
                     if here.people[mslot].wielding = oid then
                        here.people[mslot].wielding := 0;
                     if here.people[mslot].wearing = oid then
                        here.people[mslot].wearing := 0;
	       	     putroom;           
                     getobj(oid);
                     obj.numexist := obj.numexist -1;
                     putobj;
                     int_destroy := true;
	          end else begin            
		     freeroom;
                     int_destroy := false
                  end
               end
            end else int_destroy := false { someone is droping object ? }
                                       { two user must run same monster }
         end else if pid = mylog then begin { player }
            if oid > 0 then begin
               slot := find_hold(oid);
               if slot > 0 then begin
                  drop_obj(slot); 
                  getobj(oid);
                  obj.numexist := obj.numexist -1;
                  putobj;
                  int_destroy := true;
                  if mywield = oid then x_unwield;
                  if mywear = oid then x_unwear;
               end else int_destroy := false
            end else int_destroy := false
         end else begin          
            writeln ('%serious error in int_destroy. Notify Monster manager');
            int_destroy := false;
         end
      end else int_destroy := false;
   end else int_destroy := false;
end; { int_destroy }

[global]                   
function int_get(player,object: shortstring): boolean;
var room,i,pid,oid,slot,mslot: integer;     
    found : boolean;
begin                                     
   if debug then begin
      writeln('%int_get: ',player);
      writeln('%       : ',object);
   end;                            
   if player > '' then begin
      room := x_where (player,pid);         
      if room > 0 then begin
         gethere(room); 
         if exact_obj (oid,object) then begin
            if not obj_here (oid) then oid := 0
         end else oid := 0;

         mslot := x_slot(player);          { monster slot }
         if mslot = 0 then int_get := false
         else if here.people[mslot].kind = P_MONSTER then begin { monster }
            if oid > 0 then begin
               slot := find_obj(oid);            { object current slot }
               if mslot > 0 then begin
	          getroom(room);                    { locking }
                  i := 1;
	          found := false;
	          while (i <= maxhold) and (not found) do begin
		     if here.people[mslot].holding[i] = 0 then
			found := true
		     else
			i := i + 1;
	          end;
	          if found and (here.objs[slot] = oid) then begin
	       	     here.people[mslot].holding[i] := oid;
                     here.objs[slot] := 0;
                     here.objhide[slot] := 0;
	       	     putroom;           
                     int_get := true;
	          end else begin
		     freeroom;
                     int_get := false
                  end
               end
            end else int_get := false        { someone is moving monster ? }
         end else if pid = mylog then begin { player }
            if oid > 0 then begin
               if can_hold then begin
                  slot := find_obj(oid);
                  if take_obj(oid,slot) then begin
                     hold_obj(oid); 
                     int_get := true
                  end else int_get := false
               end else int_get := false
            end else int_get := false
         end else begin          
            writeln ('%serious error in int_get. Notify Monster Manager.');
            int_get := false;
         end
      end else int_get := false;
   end else int_get := false;
end;

[global]
function int_drop(player,object: shortstring): boolean;
var room,i,pid,oid,slot,mslot: integer;     
    found : boolean;
begin
   if debug then begin
      writeln('%int_drop: ',player);
      writeln('%        : ',object);
   end;
   if player > '' then begin
      room := x_where (player,pid);
      if room > 0 then begin
         gethere(room);  
         mslot := x_slot(player);  
         if mslot = 0 then oid := 0    { is  monster moving ? }
         else if exact_obj (oid,object) then begin
            if not x_hold (oid,mslot) then oid := 0
         end else oid := 0;
     
         if mslot = 0 then int_drop := false
         else if here.people[mslot].kind = P_MONSTER then begin { monster }
            if oid > 0 then begin
               slot := find_hold(oid,mslot);     { object current slot }
	       if slot > 0 then begin            { is object here yet ? }
                  getroom(room);                    { locking }
                  i := 1;
	          found := false;
	          while (i <= maxobjs) and (not found) do begin
		     if here.objs[i] = 0 then
			found := true
		     else
			i := i + 1;
	          end;
	          if found and (here.people[mslot].holding[slot] = oid) then begin
	       	     here.people[mslot].holding[slot] := 0;
                     if here.people[mslot].wielding = oid then
                        here.people[mslot].wielding := 0;
                     if here.people[mslot].wearing = oid then
                        here.people[mslot].wearing := 0;
                     here.objs[i] := oid;
                     here.objhide[i] := 0;
	       	     putroom;           
                     int_drop := true;
	          end else begin            
		     freeroom;
                     int_drop := false
                  end
               end
            end else int_drop := false { someone is droping object ? }
                                       { two user must run same monster }
         end else if pid = mylog then begin { player }
            if oid > 0 then begin
               if can_drop then begin
                  slot := find_hold(oid);
                  if place_obj(oid,TRUE) then begin
                     drop_obj(slot); 
                     int_drop := true;
                     if mywield = oid then x_unwield;
                     if mywear = oid then x_unwear;
                  end else int_drop := false
               end else int_drop := false
            end else int_drop := false
         end else begin          
            writeln ('%serious error in int_drop. Notify Monster manager');
            int_drop := false;
         end
      end else int_drop := false;
   end else int_drop := false;
end;

[global]
function int_poof (player,room,owner: shortstring; 
                   general,own: boolean): boolean;
var pid,cur,loc,targslot,code,apu,mslot: integer;
    pub,dis: shortstring;
begin
  if debug then begin
     writeln('%int_poof: ',player);
     writeln('%        : ',room);
     writeln('%        : ',owner);
     writeln('%        : ',general); { poof privilegio }
     writeln('%        : ',own);     { privileged code }
  end;

  if player > '' then begin
     cur := x_where(player,pid);
     if cur > 0 then begin
        gethere(cur);
        mslot := x_slot(player);
        if (mslot >0) then begin
           if exact_room(loc,room) then begin
              if cur = loc then int_poof := true
              else if here.people[mslot].kind = P_MONSTER then begin { monster }
                  code := here.people[mslot].parm;
                  gethere(loc);                         { target room }
                  if (owner = here.owner) or 
                     (here.owner = disowned_id) or 
		     (here.owner = public_id) or general then begin
                     if x_puttoken (cur,pid,mslot,loc,targslot) then begin
                        take_token(mslot,cur);
                        int_poof := true
                     end else int_poof := false
                  end else int_poof := false
              end else if pid = mylog then begin       { player }
                 if own then begin                     
                    gethere(loc);                      { target room }
                    if (owner = here.owner) or 
			(here.owner = disowned_id) or
			(here.owner = public_id) or
                       general then begin
                       if put_token (loc,targslot,0) then begin
                          take_token(mslot,cur);
                          myslot := targslot;
                          location := loc;
                          setevent;
                          do_look;
                          int_poof := true 
                       end else int_poof := false;
                    end else int_poof := false;
                 end else int_poof := false;
              end else begin
                 writeln ('%seriuos error in int_poof. Notify Monster Manager.');
                 int_poof := false;
              end;
           end else int_poof := false
        end else int_poof := false
      end else int_poof := false
   end else int_poof := false
end; { int_poof }
         
[global]
function int_login (player: shortstring; force: boolean): integer;
{ 0 = no such player name }
{ 1 = login ok }
{ 2 = monster is already logged in }    
{ 3 = miscelagous failure }
var room,pid,mslot: integer;
begin
  if debug then begin
     writeln('%int_login: ',player);
     writeln('%         : ',force);
  end;   
  if player = '' then int_login := 1		{ pseudo login }
  else begin
     room := x_where(player,pid);
     if room = 0 then int_login := 0
     else begin
        gethere(room);
        mslot := x_slot(player);
        if mslot = 0 then int_login := 3
        else if here.people[mslot].kind < P_MONSTER then begin
           writeln('%serious error in int_login. Notify Monster Manager.');
           int_login := 3;
        end else begin
           getindex(I_ASLEEP);         { locking }
           if indx.free[pid] or force then begin     { ok }
              indx.free[pid] := false;
              putindex;
              int_login := 1
           end else begin
              freeindex;               
              int_login := 2
           end
       end
     end  
   end
end; { int_login }

[global]
procedure int_logout (player: shortstring);
var pid,room,mslot: integer;
begin
  if debug then writeln('%int_logout: ',player);
  if player > '' then begin 
     room := x_where(player,pid);
     if room > 0 then begin
        gethere(room);
        mslot := x_slot(player);
        if mslot > 0 then 
           if here.people[mslot].kind < P_MONSTER then begin
              writeln('%serious error in int_logout. Notify Monster Manager.');
           end else do_endplay (pid)               
     end
   end
end; { int_logout }

[global]
function int_attack(player: shortstring; power: integer): boolean;
var cur,pid,mslot,health,lev: integer;
begin
  if debug then begin
     writeln('%int_attack: ',player);
     writeln('%          : ',power:1);
  end;
  if not read_global_flag(GF_WARTIME) then int_attack := false
  else if player > '' then begin
     cur := x_where(player,pid);
     if cur > 0 then gethere(cur);                       
     mslot := x_slot(player);
     if (cur > 0) and (mslot >0) then begin
        if here.people[mslot].kind = P_MONSTER then begin { monster }
           getroom;              
           if here.people[mslot].kind <> P_MONSTER then begin { is this }
              int_attack := false;                   { double cheking ? }
              freeroom           
           end else begin
              health := here.people[mslot].health;
              health := health - power;
              if health < 0 then health := 0;      
              here.people[mslot].health := health;
              int_attack := true;
              putroom;
              getint(N_HEALTH);
              anint.int[pid] := health;
              putint;
           end;
        end else if pid = mylog then begin        { player }
           if (myexperience >= protect_exp) { and protected_MM } then int_attack := false
           else begin                         
              take_hit(power);          
              int_attack := true;
           end
        end else begin 
           writeln ('%serious error in int_attack. Notify Monster Manager.');
           int_attack := false;
        end;
      end else int_attack := false
   end else int_attack := false
end; { int_poof }
         


[global]
function int_where(player: shortstring): shortstring;
var room,pid: integer;
begin
  if debug then writeln('%int_where: ',player);
  room := x_where(player,pid);
  if room = 0 then int_where := ''
  else begin
    getnam;   { room names }
    freenam;
    int_where := nam.idents[room];
  end
end; { int_where }

[global]
function player_room(player: shortstring): integer;
var unused: integer;
begin
  player_room := x_where(player,unused);
end;

procedure poof_monster { (n: integer; s: string) declared forward } ;
var name: shortstring;
    loc: integer;
begin
    name := here.people[n].name;
    if lookup_room(loc,s) then begin
	log_event(myslot,E_POOFYOU,n,loc);
	writeln;
	writeln('You extend your arms, muster some energy, and ',name,' is');
	writeln('engulfed in a cloud of orange smoke.');
	writeln;
	wait(1);	{ try fixing event problem - yes - that isn't good }
	int_poof(name,nam.idents[loc],'',true,true);
	checkevents;
    end else
	writeln('There is no room named ',s,'.');
end; { poof monster }

procedure block_monster(s: string);
var room,pid,mslot,parm: integer;
begin       
   if (s = '') or (length(s) > shortlen) then writeln('USAGE: A <monster>')
   else if lookup_pers(pid,s,true) then begin
      getint(N_LOCATION);
      freeint;
      room := anint.int[pid];
      getpers;
      freepers;
      s := pers.idents[pid];
      gethere(room);    
      mslot := x_slot (s);
      if mslot = 0 then writeln ('%error')
      else if here.people[mslot].kind <> P_MONSTER then writeln ('No monster')
      else begin
         parm := here.people[mslot].parm;
         if parm = 0 then writeln ('%error')
         else begin
            set_runnable(parm,false);
            writeln('Blocked.');
         end
      end
   end else writeln ('No such monster.');
end;

procedure block_spell(s: string);
var n,parm: integer;
begin       
   if (s = '') or (length(s) > shortlen) then writeln('USAGE: G <spell>')
   else if lookup_spell(n,s,true) then begin
	getint(N_SPELL);
	freeint;
	parm := anint.int[n];
	if parm = 0 then writeln ('%error')
	else begin
            set_runnable(parm,false);
            writeln('Blocked.');
	end
   end else writeln ('No such spell.');
end;

procedure block_object(s: string);
var room,pid,mslot,parm,oid: integer;
begin       
   if (s = '') or (length(s) > shortlen) then writeln('USAGE: B <object>')
   else if lookup_obj(oid,s,true) then begin
      getobj(oid);
      freeobj;
      if obj.actindx > 0 then begin
         set_runnable(obj.actindx,false);
         writeln('Blocked.');
      end else writeln ('No hook defined.')
   end else writeln('No such room.');
end;

procedure block_room (s: string);
var room,pid,mslot,parm: integer;
begin       
   if (s = '') or (length(s) > shortlen) then writeln('USAGE: C <room>')
   else if lookup_room(room,s,true) then begin
      gethere(room);
      if here.hook > 0 then begin
         set_runnable(here.hook,false);
         writeln('Blocked.');
      end else writeln ('No hook defined.')
   end else writeln ('No such room.')
end;

procedure system_claim_room(s: string);
var room,pid,mslot,parm,oldowner: integer;
begin       
    if (s = '') or (length(s) > shortlen) then writeln('USAGE: R <room>')
    else if lookup_room(room,s,true) then begin
	getroom(room);
	if not exact_user(oldowner,here.owner) then oldowner := 0;
	here.owner := system_id;
	putroom;
	getown;
	own.idents[room] := system_id;
	putown;
	change_owner(oldowner,0);
	if here.hook > 0 then set_owner(here.hook,,system_id);
	writeln('System is now owner of ',here.nicename,'.');
    end else writeln('No such room.');
end;

procedure system_claim_object(s: string);
var pid,mslot,parm,oid: integer;
begin       
   if (s = '') or (length(s) > shortlen) then writeln('USAGE: O <object>')
   else if lookup_obj(oid,s,true) then begin
      getobj(oid);
      putobj;
      getobjown;
      objown.idents[oid] := system_id;
      putobjown;
      if obj.actindx > 0 then set_owner(obj.actindx,,system_id);
      writeln('System is now owner of ',obj.oname,'.');
    end else writeln('No such object.');
end;

procedure system_claim_monster(s: shortstring);
var room,pid,mslot,parm: integer;
begin       
   if (s = '') or (length(s) > shortlen) then writeln('USAGE: M <monster>')
   else if lookup_pers(pid,s,true) then begin
      getint(N_LOCATION);
      freeint;
      room := anint.int[pid];
      getpers;
      freepers;
      s := pers.idents[pid];
      gethere(room);    
      mslot := x_slot (s);
      if mslot = 0 then writeln ('%error')
      else if here.people[mslot].kind <> P_MONSTER then writeln ('No monster')
      else begin
         parm := here.people[mslot].parm;
         if parm = 0 then writeln ('%error')
         else begin
            set_owner(parm,,system_id);
	    writeln('System is now owner of ',here.people[mslot].name,'.');
         end
      end
   end else writeln ('No such monster.');
end;

procedure system_claim_spell(s: shortstring);
var room,n,parm: integer;
begin       
   if (s = '') or (length(s) > shortlen) then writeln('USAGE: S <spell>')
   else if lookup_spell(n,s,true) then begin
      getint(N_SPELL);
      freeint;
      parm := anint.int[n];
      if parm = 0 then writeln ('%error')
      else begin
            set_owner(parm,,system_id);
	    writeln('System is now owner of ',spell_name.idents[n],'.');
      end
   end else writeln ('No such spell.');
end;

procedure system_2 {(s: string); forward };
var continue: boolean;
    a: string;

    procedure leave;
    begin
	writeln('EXIT');
	s := 'q';
    end;

    procedure null;
    begin
	writeln('QUIT');
	s := '';
    end;

begin
   continue := true;
   if s = '' then grab_line('Subsystem> ',s,eof_handler := leave)
   else continue := false;
   repeat
       s := lowcase(s);
       a := bite(s);
       if a > '' then case a[1] of
	    '?','h': command_help('*system 2 help*');
	    'a': block_monster(s);
	    'b': block_object(s);
	    'c': block_room(s);
	    'd': begin
		    if s = '' then grab_line('Message? ',s,eof_handler := null);
		    do_s_shutdown(s);
		    set_global_flag(GF_ACTIVE,FALSE);
		 end;
	    'f': set_global_flag(GF_ACTIVE,TRUE);
	    'g': block_spell(s);
	    'i': custom_global_code(GF_CODE);
	    'o': system_claim_object(s);
	    'r': system_claim_room(s);
	    'w': begin
		    if s = '' then grab_line('Message? ',s,eof_handler := null);
		    do_s_announce(s);
		 end;
	    'm': system_claim_monster(s);
	    's': system_claim_spell(s);
	    'v': fix_view_global_flags;
	    'e','q': continue := false;
	    otherwise 
		if continue then writeln('Type ? for help.')
		else writeln('Type C ? for help.');
       end;
       if continue then grab_line('Subsystem> ',s,eof_handler := leave);
   until not continue;
end;

procedure throw_player {(s: string)};
label exit_label;
var mess: string;
    room,pid,count: integer;
    done: boolean;

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;

begin
    if s = '' then grab_line('Player''s (personal) name? ',s,
	eof_handler := leave);
    if (s = '') or (s = '?') then 
	writeln ('Usage: T <Player''s personal name>')
    else if length(s) > shortlen then writeln('Limit name to ',
	shortlen:1,' characters.')
    else begin
	grab_line('Message? ',mess,
	    eof_handler := leave);
	room := x_where(s,pid);
	if pid = mylog then 
	    writeln ('You can''t throw yourself out from Monster.')
	else if room = 0 then writeln('Player isn''t in Monster now.')
	else begin
	    log_event(0,E_KICK_OUT,pid,,mess,room);
	    done := false;
	    count := 0;
	    while not done and (count < 20) do begin
		wait(2);
		checkevents(TRUE);
		getindex(I_ASLEEP);
		freeindex;
		done := indx.free[pid];
		count := count +1;
	    end;
	    if done then writeln('Ok.');
	end;
    end;
    exit_label:
end;



begin	    { main program }
    Get_Environment;

    if not lookup_class(system_id,'system') then
	writeln('%error in main program: system');
    if not lookup_class(public_id,'public') then
	writeln('%error in main program: public');
    if not lookup_class(disowned_id,'disowned') then
	writeln('%error in main program: disowned');

    done := false;
    setup_guts;
    if terminal_line_len < 40 then begin { to avoid run time errors }
	writeln('Monster requires, that');
	writeln('terminal width is at');
	writeln('least 40 chars.');
    end else if terminal_page_len < 5 then begin { to avoid run time errors }
	writeln('Monster requires, that');
	writeln('terminal height is at');
	writeln('least 5 lines.');
    end else begin

      very_init;
      very_prestart;  { very_prestart reopen OUTPUT }
      if init then begin

	init_interpreter;
	prestart; 
			
	if not(done) then begin
	    if not read_global_flag(GF_VALID) then begin
		writeln('Can''t enter Monster universe.');
		writeln('Database marked as invalid by Monster Manager.');
		if userid = MM_userid then
		    writeln('Use /FIX option to mark database as valid.');

	    end else if enter_universe then begin
		repeat
			parser;
			if not read_global_flag(GF_ACTIVE) then begin
			    if manager_priv then 
				writeln('WARNING: Monster is shutdown.')
			    else begin
				writeln('Monster is shutdown.');
				done := true;
			    end;
			end;
		until done;
		leave_universe;
	    end else
		writeln('You attempt to enter the Monster universe, but a strange force repels you.');
	end;
	finish_interpreter;
	close_database;
      end else if work_time then write_message   { now is work time }
      else writeln('Monster is ill, please notify Monster Manager.');
	    { file protection problem }
    end;
    finish_guts;
end.

{ Notes to other who may inherit this program:

	Change all occurances in this file of dolpher to the account which
	you will use for maintenance of this program.  That account will
	have special administrative powers.

	This program uses several data files.  These files are in a directory
	specified by the variable root in procedure init.  In my implementation,
	I have a default ACL on the directory allowing everyone READ and WRITE
	access to the files created in that directory.  Whoever plays the game
	must be able to write to these data files.


Written by Rich Skrenta, 1988.




Brief program organization overview:
------------------------------------

Monster's Shared Files:

Monster uses several shared files for communication.
Each shared file is accessed within Monster by a group of 3 procedures of the
form:	getX(), freeX and putX.

getX takes an integer and attempts to get and lock that record from the
appropriate data file.  If it encounters a "collision", it waits a short
random amount of time and tries again.  After maxerr collisions it prints
a deadlock warning message.

If data is to be read but not changed, a freeX should immediately follow
the getX so that other Monster processes can access the record.  If the
record is to be written then a putX must eventually follow the getX.


Monster's Record Allocation:

Monster dynamically allocates some resources such as description blocks and
lines and player log entries.  The allocation is from a bitmap.  I chose a
bitmap over a linked list to make the multiuser access to the database
more stable.  A particular resource (such as log entries) will have a
particular bitmap in the file INDEXFILE.  A getindex(I_LOG) will retrieve
the bitmap for it.

Actually allocation and deallocation is done through the group of functions
alloc_X and delete_X.  If alloc_X returns true, the allocation was successful,
and the integer parameter is the number of the block allocated.

The top available record in each group is stored in indexrec.  To increase
the top, the new records must be initially written so that garbage data is
not in them and the getX routines can locate them.  This can be done with
the addX(n) group of routines, which add capacity to resources.



Parsing in Monster:

The main parser(s) use a first-unique-characters method to lookup command
keywords and parameters.  The format of these functions is lookup_x(n,s).
If it returns true, it successfully found an unambiguous match to string s.
The integer index will be in n.

If an unambiguating match is needed (for example, if someone makes a new room,
the match to see if the name exists shouldn't disambiguate), the group of
routines exact_X(n,s) are called.  They function similarly to lookup_x(n,s).

The customization subsystems and the editor use very primitive parsers
which only use first character match and integer arguments.



Asynchronous events in Monster:

When someone comes into a room, the other players in that room need
to be notified, even if they might be typing a command on their terminal.

This is done in a two part process (producer/consumer problem):

When an event takes place, the player's Monster that caused the event
makes a call to log_event.  Parameters include the slot of the sender (which
person in the room caused the event), the actual event that occurred
(E_something) and parameters.  Log_event works by sticking the event
into a circular buffer associated with the room (room may be specified on
log_event).

Note: there is not an event record for every room; instead, the event
      record used is  ROOM # mod ACTUAL NUMBER of EVENT RECORDS

The other half of the process occurrs when a player's Monster calls
grab_line to get some input.  Grab line looks for keystrokes, and if
there are none, it calls checkevent and then sleeps for a short time
(.1 - .2 seconds).  Checkevent loads the event record associated with this
room and compare's the player's buffer pointer with the record's buffer
pointer.  If they are different, checkevent bites off events and sends them
to handle_event until there are no more events to be processed.  Checkevent
ignores events logged by it's own player.

}
