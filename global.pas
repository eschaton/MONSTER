[environment,inherit ('sys$library:starlet')]
Module Global;	    { global definations }

const

        MAX_PING = 5;
                             
	string_len = 80;
	veryshortlen = 12;	{ very short string length for userid's etc }
	shortlen = 20;		{ ordinary short string }
        MEGA_LENGTH = 1000;	{ must be same as string_length }
				{ in module interpreter	}
	RANDOM_EVENT_CYCLE = 80;{ time between random evet checks	}
	maxobjs = 15;		{ max objects allow on floor in a room }
	maxpeople = 10;		{ max people allowed in a room }
	maxplayers = 300;	{ max log entries to make for players }
	maxcmds = 99;		{ top value for cmd keyword slots }
	maxshow = 50;		{ top value for set/show keywords }
	maxexit = 6;		{ 6 exits from each loc: NSEWUD }
	maxroom = 1000;		{ Total maximum ever possible	}
	maxdetail = 5;		{ max num of detail keys/descriptions per room }
	maxevent = 15;		{ event slots per event block }
	maxindex = 10000;	{ top value for bitmap allocation }
	maxhold = 6;		{ max # of things a player can be holding }
	maxerr = 15;		{ # of consecutive record collisions before the
				  the deadlock error message is printed }
	numevnts = 10;		{ # of different event records to be maintained }
	numpunches = 12;	{ # of different kinds of punches there are }
	maxparm = 20;		{ parms for object USEs }
	maxspells = 50;		{ total number of spells available }

	descmax = 10;		{ lines per description block }
        BAD_PUNCH = 10;         { punch for experience people }
				{ hurtta@finuh }
	maxlevels = 50;		{ how many levels there are }
	DEFAULT_LINE = 32000;	{ A virtual one liner record number that
				  really means "use the default one liner
				  description instead of reading one from
				  the file" }


	START_LOCATION = 1;	{ new player start from Great Hall }

{ Mnemonics for directions }

	north = 1;
	south = 2;
	east = 3;
	west = 4;
	up = 5;
	down = 6;


{ Index record mnemonics }

	I_BLOCK = 1;	{ True if description block is not used		}
	I_LINE = 2;	{ True if line slot is not used			}
	I_ROOM = 3;	{ True if room slot is not in use		}
	I_PLAYER = 4;	{ True if slot is not occupied by a player	}
	I_ASLEEP = 5;	{ True if player is not playing			}
	I_OBJECT = 6;	{ True if object record is not being used	}
	I_INT = 7;	{ True if int record is not being used		}
 	I_HEADER = 8;	{ True if interpreter header record not being	}
			{ used (hurtta@finuh)				}
	{I_GLOBAL = 9;}	{ Values of global flags - default: true	}
	I_SPELL  = 10;	{ True if spell not defined			}


{ Integer record mnemonics }

	N_LOCATION = 1;		{ Player's location }
	N_NUMROOMS = 2;		{ How many rooms they've made }
	N_ALLOW = 3;		{ How many rooms they're allowed to make }
	N_ACCEPT = 4;		{ Number of open accept exits they have }
	N_EXPERIENCE = 5;	{ How "good" they are }
	N_SELF = 6;		{ player's self descriptions }
	N_PRIVILEGES = 7;	{ Players' privileges } {leino@finuha}
        N_HEALTH = 8;		{ Players' health } { hurtta@finuh }
	N_SPELL	 = 9;		{ Spell's header number }
        N_GLOBAL = 10;		{ Global flags and values (default: false) }

{ Name record mnemonics }

	T_NAM	= 1;	    { rooms' name }
	T_OWN	= 2;	    { rooms' owner }
	T_PERS	= 3;	    { players' personal name }
	T_USER	= 4;	    { players' userid }
	T_OBJNAM = 5;	    { objects' name }
	T_OBJOWN = 6;	    { objects' owner }
	T_DATE	= 7;	    { players' date of last play }
	T_TIME	= 8;	    { players' time of last play }
	T_PASSWD = 9;	    { players' password }
	T_REAL_USER = 10;   { players' userid }
	T_SPELL_NAME = 11;  { spells' name }

	T_MAX = 11;

{ object kind mnemonics }

	O_BLAND = 0;		{ bland object, good for keys }
	O_WEAPON = 1;
	O_ARMOR = 2;
	O_THRUSTER = 3;		{ use puts player through an exit }
	O_DISGUISE = 4;		{ Don't show player name }
	O_BOOK = 5;		{ learns new spell }


	O_TRAP = 10;		{ use causes attack to player who tries to }
				{ get it (hurtta@finuh) }

	O_BAG = 100;
	O_CRYSTAL = 101;
	O_WAND = 102;
	O_HAND = 103;
	O_TELEPORT_RING = 104;	{ causes random teleporting	}
        O_HEALTH_RING = 105;
        
	O_MAGIC_RING = 200;

{ object parms fiels }
	{ O_BOOK: }
	OP_SPELL = 1;		{ spell number }



{ player kind mnemonics  }

	P_PLAYER = 1;
	P_MONSTER = 2;

{ Command Mnemonics }
	error = 0;
	setnam = 1;
	help = 2;
	quest = 3;
	quit = 4;
	look = 5;
	go = 6;
	form = 7;
	link = 8;
	unlink = 9;
	c_whisper = 10;
	poof = 11;
	desc = 12;                                
        c_dcl = 13;
	dbg = 14;
	say = 15;
        c_scan = 16;
	c_rooms = 17;
	c_system = 18;
	c_disown = 19;
	c_claim = 20;
	c_create = 21;
	c_public = 22;
	c_accept = 23;
	c_refuse = 24;
	c_zap = 25;
	c_hide = 26;
	c_l = 27;
	c_north = 28;
	c_south = 29;
	c_east = 30;
	c_west = 31;
	c_up = 32;
	c_down = 33;
	c_n = 34;
	c_s = 35;
	c_e = 36;
	c_w = 37;
	c_u = 38;
	c_d = 39;
	c_custom = 40;
	c_who = 41;
	c_players = 42;
	c_search = 43;
	c_unhide = 44;
	c_punch = 45;
	c_ping = 46;
	c_health = 47;
	c_get = 48;
	c_drop = 49;
	c_inv = 50;
	c_i = 51;
	c_self = 52;
	c_whois = 53;
	c_duplicate = 54;
	c_score = 55;
	c_version = 56;
	c_objects = 57;
	c_use = 58;
	c_wield = 59;
	c_brief = 60;
	c_wear = 61;
	c_relink = 62;
	c_unmake = 63;
	c_destroy = 64;
	c_show = 65;
	c_set = 66;
	c_monster = 67;
	c_erase = 68;
	c_atmosphere = 69;
	c_reset = 70;
	c_summon = 71;
	c_spells = 72;
	c_monsters = 73;
	{ for alias }
	A_list   = 74;
	A_create = 75;
	A_delete = 76;
	{ ---- }

	e_detail = 100;		{ pseudo command for log_action of desc exit }
	e_custroom = 101;	{ customizing this room }
	e_program = 102;	{ customizing (programming) an object }
	e_usecrystal = 103;	{ using a crystal ball }
	e_custommonster = 104;  { customizing monster }
	e_customspell = 105;    { customizing spell } 


{ Show Mnemonics }
        
	s_exits = 1;
	s_object = 2;
	s_quest = 3;
	s_details = 4;
	s_monster = 5;
	s_priv = 6;
	s_time = 7;
	s_room = 8;
	s_paper = 9;
	s_levels = 10;
	s_quota  = 11;
	s_spell  = 12;

{ Set Mnemonics }

	y_quest = 1;

{	y_altmsg = 2;
	y_group1 = 3;
	y_group2 = 4;	}

	y_passwd = 2;
	y_peace	=  3;
	y_war	=  4;
	y_priv  =  5;
	y_spell =  6;
	y_newplayer = 7;
	y_welcome =8;


{ Event Mnemonics }

	E_EXIT = 1;		{ player left room			}
	E_ENTER = 2;		{ player entered room			}
	E_BEGIN = 3;		{ player joined game here		}
	E_QUIT = 4;		{ player here quit game			}
	
	E_SAY = 5;		{ someone said something		}
	E_SETNAM = 6;		{ player set his personal name		}
	E_POOFIN = 8;		{ someone poofed into this room		}
	E_POOFOUT = 9;		{ someone poofed out of this room	}
	E_DETACH = 10;		{ a link has been destroyed		}
	E_EDITDONE = 11;	{ someone is finished editing a desc	}
	E_NEWEXIT = 12;		{ someone made an exit here		}
	E_BOUNCEDIN = 13;	{ an object "bounced" into the room	}
	E_EXAMINE = 14;		{ someone is examining something	}
	E_CUSTDONE = 15;	{ someone is done customizing an exit	}
	E_FOUND = 16;		{ player found something		}
	E_SEARCH = 17;		{ player is searching room		}
	E_DONEDET = 18;		{ done adding details to a room		}
	E_HIDOBJ = 19;		{ someone hid an object here		}
	E_UNHIDE = 20;		{ voluntarily revealed themself		}
	E_FOUNDYOU = 21;	{ someone found someone else hiding	}
	E_PUNCH = 22;		{ someone has punched someone else	}
	E_MADEOBJ = 23;		{ someone made an object here		}
	E_GET = 24;		{ someone picked up an object		}
	E_DROP = 25;		{ someone dropped an object		}
	E_DROPALL = 26;		{ quit & dropped stuff on way out	}
	E_IHID = 27;		{ tell others that I have hidden (!)	}
	E_NOISES = 28;		{ strange noises from hidden people	}
	E_PING = 29;		{ send a ping to a potential zombie	}
	E_PONG = 30;		{ ping answered				}
	E_HIDEPUNCH = 31;	{ someone hidden is attacking		}
	E_SLIPPED = 32;		{ attack caused obj to drop unwillingly }
	E_ROOMDONE = 33;	{ done customizing this room		}
	E_OBJDONE = 34;		{ done programming an object		}
	E_HPOOFOUT = 35;	{ someone hiding poofed	out		}
	E_FAILGO = 36;		{ a player failed to go through an exit }
	E_HPOOFIN = 37;		{ someone poofed into a room hidden	}
	E_TRYPUNCH = 38;	{ someone failed to punch someone else	}
	E_PINGONE = 39;		{ someone was pinged away . . .		}
	E_CLAIM = 40;		{ someone claimed this room		}
	E_DISOWN = 41;		{ owner of this room has disowned it	}
	E_WEAKER = 42;		{ person is weaker from battle		}
	E_OBJCLAIM = 43;	{ someone claimed an object		}
	E_OBJDISOWN = 44;	{ someone disowned an object		}
	E_SELFDONE = 45;	{ done editing self description		}
	E_WHISPER = 46;		{ someone whispers to someone else	}
	E_WIELD = 47;		{ player wields a weapon		}
	E_UNWIELD = 48;		{ player puts a weapon away		}
	E_DONECRYSTALUSE = 49;	{ done using the crystal ball		}
	E_WEAR = 50;		{ someone has put on something		}
	E_UNWEAR = 51;		{ someone has taken off something	}
	E_DESTROY = 52;		{ someone has destroyed an object	}
	E_HIDESAY = 53;		{ anonymous say				}
	E_OBJPUBLIC = 54;	{ someone made an object public		}
	E_SYSDONE = 55;		{ done with system maint. mode		}
	E_UNMAKE = 56;		{ remove typedef for object		}
	E_LOOKDETAIL = 57;	{ looking at a detail of this room	}
	E_ACCEPT = 58;		{ made an "accept" exit here		}
	E_REFUSE = 59;		{ got rid of an "accept" exit here	}
	E_DIED = 60;		{ someone died and evaporated		}
	E_LOOKYOU = 61;		{ someone is looking at you		}
	E_FAILGET = 62;		{ someone can't get something		}
	E_FAILUSE = 63;		{ someone can't use something		}
	E_CHILL = 64;		{ someone scrys you			}
	E_NOISE2 = 65;		{ say while in crystal ball		}
	E_LOOKSELF = 66;	{ someone looks at themself		}
	E_INVENT = 67;		{ someone takes inventory		}
	E_POOFYOU = 68;		{ MM poofs someone away . . . .		}
	E_WHO = 69;		{ someone does a who			}
	E_PLAYERS = 70;		{ someone does a players		}
	E_VIEWSELF = 71;	{ someone views a self description	}
	E_REALNOISE = 72;	{ make the real noises message print	}
	E_ALTNOISE = 73;	{ alternate mystery message		}
	E_MIDNIGHT = 74;	{ it's midnight now, tell everyone	}
        E_DCLDONE  = 75;        { return from dcl-level			}
        E_ATTACK = 76;          { some attack someone with weapon	}
        E_HATTACK = 77;         { hiding attack ...			}
        E_ADDEXPERIENCE = 78;   { someone get more experience		}
                                { Killed person send this message	}
	E_TRAP = 79;		{ some failure to get trap		}
	E_ERASE = 80;
        E_MONSTERDONE = 81;
        E_BROADCAST = 82;       { NPC interpreter say something		}
	E_SCAN = 83;
	E_LOOKAROUND = 84;
	E_NEWLEVEL = 85;
	E_SUBMIT = 86;		{ NPC interpreter switch control	}
	E_KICK_OUT = 87;	{ Kick out player from Monster		}
	E_ATMOSPHERE = 88;	{ for atmosphere command		}

	{ --------- stolen from monster version 3.0 ------------------- }

	E_ANNOUNCE = 89;	{ message over monster universe		}
	E_SHUTDOWN = 90;	{ shutdown message			}

	{ ------------------------------------------------------------- }

	E_RESET = 91;		{ move object to home }
	E_GLOBAL_CHANGE = 92;   { global flags is changed }
	E_SUMMON = 93;		{ summon spell }
	E_SPELLDONE = 94;	{ finish customizing spell }

	E_ACTION = 100;		{ base command action event		}
        

{ Misc. }                                          

	GOODHEALTH = 7;

      statmax = 8;        { maksimi tilastointi tietueet } 
      sorthmax = 15;
      
      MAXATOM = 500;	{ Ohjelman maksimi koko }


{ Code flags }

    CF_NO_CONTROL = 1;	    { no control access }
    CF_SPELL_MODE = 2;	    { spell mode }

Type global_T = ( G_Flag, G_Int, G_Text, G_Code );

Const

{ Global flags }
    GF_ACTIVE     = 1;	    { Monster database open }
    GF_VALID	  = 2;	    { Monster database is available }
    GF_WARTIME    = 3;      { Violance is allowed }
    GF_NEWPLAYER  = 4;      { New Player starting text }
    GF_STARTGAME  = 5;      { Star palying text }
    GF_CODE	  = 6;	    { Global code }

    GF_MAX	  = 6;

Var GF_Types : array [ 1 .. GF_MAX ] of global_T := 
    ( G_Flag,
      G_Flag,
      G_Flag,
      G_Text,
      G_Text,
      G_Code
    );

Type

	string = varying[string_len] of char;
	veryshortstring = varying[veryshortlen] of char;
	shortstring = varying[shortlen] of char;
	mega_string = varying [ MEGA_LENGTH ] of char;                 

	{ for system services }
	$UWORD = [WORD] 0..65535;   
			{ must declare, because		    }
			{ $UWORD in STARLET is with [HIDDEN]    }
	string_body = packed array (.1..string_len.) of char;
	itmlst_type = record
	    buffer_length : $uword;
	    item_code : $uword;
	    buffer_address : ^string_body;
	    return_length_address : ^integer;
	    itmlst_end : unsigned
	end;


	{ This is a list of description block numbers;
	  If a number is zero, there is no text for that block }
	

	{ exit kinds:
		0: no way - blocked exit
		1: open passageway
		2: object required

		6: exit only exists if player is holding the key
	}

	exit = record
		toloc: integer;		{ location exit goes to }
		kind: integer;		{ type of the exit }
		slot: integer;		{ exit slot of toloc target }

		exitdesc,  { one liner description of exit  }
		closed,    { desc of a closed door }
		fail,	   { description if can't go thru   }
		success,   { desc while going thru exit     }
		goin,      { what others see when you go into the exit }
{		ofail,	}
		comeout:   { what others see when you come out of the exit }
			  integer; { all refer to the liner file }
				   { if zero defaults will be printed }

		hidden: integer;	{ **** about to change this **** }
		objreq: integer;	{ object required to pass this exit }

		alias: veryshortstring; { alias for the exit dir, a keyword }

		reqverb: boolean;	{ require alias as a verb to work }
		reqalias: boolean;	{ require alias only (no direction) to
					  pass through the exit }
		autolook: boolean;	{ do a look when user comes out of exit }
	end;


	{ index record # 1 is block index }
	{ index record # 2 is line index }
	{ index record # 3 is room index }
	{ index record # 4 is player alloc index }
	{ index record # 5 is player awake (in game) index }

	indexrec = record		{ must be same as PARSER -module }
		indexnum: integer;	{ validation number }
		free: packed array[1..maxindex] of boolean;
		top: integer;   { max records available }
		inuse: integer; { record #s in use }
	end;


	{ names are record #1   }
	{ owners are record # 2 }
	{ player pers_names are record # 3 }
	{ userids are record # 4 }
	{ object names are record # 5 }
	{ object creators are record # 6 }
	{ date of last play is # 7 }
	{ time of last play is # 8 }
	{ passwords are # 9 }
	{ real usernames are # 10 }
	{ spell names are #11 }

	namrec = record			{ must be same as PARSER -module }
		validate: integer;
		loctop: integer;
		idents: array[1..maxroom] of shortstring;
	end;

	objectrec = record
		objnum: integer;	{ allocation number for the object }
		onum: integer;		{ number index to objnam/objown }
		oname: shortstring;	{ duplicate of name of object }
		kind: integer;		{ what kind of object this is }
		linedesc: integer;	{ liner desc of object Here }

		home: integer;		{ if object at home, then print the }
		homedesc: integer;	{ home description }

		actindx: integer;	{ action index -- for hook (hurtta@finuh) }
		examine: integer;	{ desc block for close inspection }
		worth: integer;		{ how much it cost to make (in gold) }
		numexist: integer;	{ number in existence }

		sticky: boolean;	{ can they ever get it? }
		getobjreq: integer;	{ object required to get this object }
		getfail: integer;	{ fail-to-get description }
		getsuccess: integer;	{ successful picked up description }

		useobjreq: integer;	{ object require to use this object }
		uselocreq: integer;	{ place have to be to use this object }
		usefail: integer;	{ fail-to-use description }
		usesuccess: integer;	{ successful use of object description }

		usealias: veryshortstring;
		reqalias: boolean;
		reqverb: boolean;

		particle: integer;	{ a,an,some, etc... "particle" is not
					  be right, but hey, it's in the code }

		parms: array[1..maxparm] of integer;

		d1: integer;		{ extra description # 1 }
		d2: integer;		{ extra description # 2 }

		ap: Integer;		{ attack power }
                exreq: Integer;		{ required experiece }
		exp5,exp6: integer;
	end;

	anevent = record
		sender,			{ slot of sender }
		action,			{ what event this is, E_something }
		target,			{ opt target of action }
		parm: integer;		{ expansion parm }
		msg: string;		{ string for SAY and other cmds }
		loc: integer;		{ room that event is targeted for }
	end;

	eventrec = record
		validat: integer;	{ validation number for record locking }
		evnt: array[1..maxevent] of anevent;
		point: integer;		{ circular buffer pointer }
	end;

	peoplerec = record
		kind: integer;		   { 0=none,1=player,2=npc }
		parm: integer;		   { index to npc controller (object?) }

		username: veryshortstring; { actual userid of person }
		name: shortstring;	   { chosen name of person }
		hiding: integer;	   { degree to which they're hiding }
		act,targ: integer;	   { last thing that this person did }

		holding: array[1..maxhold] of integer;	{ objects being held }
		experience: integer;

		wearing: integer;	{ object that they're wearing }
		wielding: integer;	{ weapon they're wielding }
		health: integer;	{ how healthy they are }

		self: integer;		{ self description }

		ex1,ex2,ex3,ex4,ex5: integer;
	end;

	spellrec = record
		recnum: integer;
		level: array[1..maxspells] of integer;
	end;

	descrec = record
		descrinum: integer;
		lines: array[1..descmax] of string;
		desclen: integer;  { number used in this block }
	end;

	linerec = record
		linenum: integer;
		theline: string;
	end;

	room = record		
		valid: integer;		{ validation number for record locking }
		locnum: integer;
		owner: veryshortstring; { who owns the room: userid if private
					{ other values is in module PARSER }
		nicename: string;	{ pretty name for location }
		nameprint: integer;	{ code for printing name:
						0: don't print it
						1: You're in
						2: You're at
					}

		primary: integer;	{ room descriptions }
		secondary: integer;
		which: integer;		{ 0 = only print primary room desc.
					  1 = only print secondary room desc.
					  2 = print both
					  3 = print primary then secondary
						if has magic object }

		magicobj: integer;	{ special object for this room }
		effects: integer;
		parm: integer;

		exits: array[1..maxexit] of exit;

		pile: integer;		{ if more than maxobjs objects here }
		objs: array[1..maxobjs] of integer;	{ refs to object file }
		objhide: array[1..maxobjs] of integer;	{ how much each object
							  is hidden }
							{ see hidden on exitrec
							  above }

		objdrop: integer;	{ where objects go when they're dropped }
		objdesc: integer;	{ what it says when they're dropped }
		objdest: integer;	{ what it says in target room when
					  "bounced" object comes in }

		people: array[1..maxpeople] of peoplerec;

		grploc1,grploc2: integer;
		grpnam1,grpnam2: shortstring;

		detail: array[1..maxdetail] of veryshortstring;
		detaildesc: array[1..maxdetail] of integer;

		trapto: integer;	{ where the "trapdoor" goes }
		trapchance: integer;	{ how often the trapdoor works }

		rndmsg: integer;	{ message that randomly prints }

		xmsg2: integer;		{ another random block }

		Hook: integer;		{ Link to hook code }
		exp3,exp4: integer;
		exitfail: integer;	{ default fail description for exits }
		ofail: integer;		{ what other's see when you fail, default }
	end;


	intrec = record
		intnum: integer;
		int: array[1..maxplayers] of integer;
	end;

	levelrec = record
		name: shortstring;	{ Level name }
		exp:  integer;		{ required experience }
		priv: integer;		{ new privilege }
		health: integer;	{ maximun health }
		factor:	integer;	{ hit factor 0 - 100 }
		maxpower: integer;	{ max power for weapons }
		hidden: boolean;	{ list in show levels? }
	end;

        statrec = record			    { tilastointitietue	    }
                lab: shortstring;			    { label, josta k‰ynistetty}
                runcount: integer;		    { ajokertojen lukum‰‰r‰ }
                errorcount: integer;		    { virheinen lukum‰‰r‰   }
                lastrun: shortstring		    { viimeisen ajokerran aika}
        end;

                                                              
        headerrec = record 
                validate: integer; { validation number }
		runnable: boolean;		    { lippu: saako koodin aja }
		priv: boolean;			    { lippu: onko koodi	    }
						    { privileged -moodissa  }
                interlocker: shortstring; { who write or read code file }
                                       { '' if none}
                owner: shortstring;       { monster owner }
                ctime: shortstring;       { creation time }
                stats: array [1..statmax] of statrec; { running statics }
                author: shortstring;      { code writer }
                wtime: shortstring;       { code loading time }
                running_id: shortstring;  { who running it now }
                                     { '' if none }
                state: mega_string;     { monster 'state' }
		version: integer;    { code version number }
                ex1,ex2,ex3: shortstring; { unused (reserved) string  }
                flags: integer;		  { flags }
		ex5: integer;    { unused (reserved) integer }
                ex6: real;           { unused (reserved) real    }
        end;                               

	classrec = record
		name:	shortstring;
		id:	shortstring;
	end;

var

	{ variables from PRIVUSERS.PAS }
	MM_userid : [global] veryshortstring;
	
		{ The Monster Manager has the most power; this should be
		  the game administrator. }

{	protected_MM : [global] boolean;	}

	gen_debug    : [global] boolean;
		{ this tells whether everyone may use the debug command.
                  it must be able to be disabled because it tells players
                  too much about monsters. On the other hand, it must also 
                  be able to be enabled, if we want to do test runs under
                  an unprivileged userid		}


	REBUILD_OK : [global] boolean;

		{ if this is TRUE, the MM can blow away and reformat the
		  entire universe. It's a good idea to set this to FALSE }

	root : [global] string;
	coderoot : [global] string;
        
		{ This is where the Monster database goes.
		  The root directory must be  world:e  and
		  the  datafiles  Monster  creates  in  it
		  world:rw for people to be able to  play.
		  The  coderoot  directory  is  where  the
		  codefiles for monsters go. The directory
		  must additionally have  an  ACL  default
		  world:rw  for  files  and ACL rw for the
		  managers. This sucks, but we don't  have
		  setgid to games on VMS. }



	leveltable : [global] array [ 1 .. maxlevels ] of levelrec;

	levels		: [global] integer;	{ Levels really used }
	

        maxexperience	: [global] integer;     { maximum experience }
			{ Monster Manager's experience is MaxInt }

	protect_exp  : [global] integer;
				{ gives protection agaist violence }

	debug: [global] boolean;        { minor change by hurtta@finuh }

End.	{ end of module }
