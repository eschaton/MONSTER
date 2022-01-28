[environment,inherit ('Global','Guts')]
MODULE database (output);
{+
COMPONENT: Tietokannan liittymä
 
PROGRAM DESCRIPTION:
 
    
 
AUTHORS:
 
    Rich Skrenta (when code was in MON.PAS)
    Kari Hurtta
 
CREATION DATE: Unknown
 
DESIGN ISSUES:
 
    Saada MON.PAS pienemmäksi

 
MODIFICATION HISTORY:
 
     Date     |   Name  | Description
--------------+---------+-------------------------------------------------------
    31.5.1992 |	Hurtta	| Tämä headeri, add* rutiineihin ylärajan tarkistus
    26.6.1992 |         | monster_owner, set_owner, delete_program moved from INTERPRETER.PAS
              |         | write_debug moved from PARSER.PAS
              |         | system_view moved from MON.PAS
-}

Var
    root: [external] string;	{ database root }
    mylog: [global] integer;	{ which log entry this player is }
    location: [global] integer := 0;	{ current place number }

    inmem: [global] boolean := FALSE;	
			 { Is this rooms roomrec (here....) in memory?
			   We call gethere many times to make sure
			   here is current.  However, we only want to
			   actually do a getroom if the roomrec has been
			   modified	}


    { Tietueet : }

    header: [global] headerrec;	    { koodin header -tietue }
    here:   [global] room;		{ current room record }
    event:  [global] eventrec;
	nam,			{ record 1 is room names }
	own,			{ rec 2 is room owners }
	pers,			{  3 is player personal names }
	user,			{  4 is player userid	}
	objnam,			{  5 is object name }
	objown,			{  6 is object owner }
	adate,			{  7 is date of last play }
	atime,			{  8 is time of last play }
	passwd,			{  9 is player password }
	real_user,		{ 10 is real VMS username }
	spell_name		{ 11 is spell's name }
 		: [global] namrec;

	anint   : [global] intrec;  { info about game players }
	obj:      [global] objectrec;
	spell   : [global] spellrec;

	block: [global] descrec;    { a text block of descmax lines }
	indx: [global] indexrec;    { an record allocation record }
	global: intrec;		    { for global flags and values }
	read_global: [global] boolean := TRUE; { global flags not in valid }
	oneliner: [global] linerec; { a line record }

	heredsc: [global] descrec;


    { Tiedostot : }

        headerfile: [global] file of headerrec;	    { tiedosto header -tietueille    }
	roomfile :  [global] file of room;
	eventfile:  [global] file of eventrec;
	namfile:    [global] file of namrec;
	descfile:   [global] file of descrec;
	linefile:   [global] file of linerec;
	indexfile:  [global] file of indexrec;
	intfile:    [global] file of intrec;
	objfile:    [global] file of objectrec;
	spellfile:  [global] file of spellrec;


[global]
procedure collision_wait;
var
	wait_time: real;

begin
	wait_time := random;
	if wait_time < 0.001 then
		wait_time := 0.001;
	wait(wait_time);
end;


{ increment err; if err is too high, suspect deadlock }
{ this is called by all getX procedures to ease deadlock checking }
[global]
procedure deadcheck(var err: integer; s:string);

begin
	err := err + 1;
	if err > maxerr then begin
		writeln('%warning- ',s,' seems to be deadlocked; notify the Monster Manager');
		finish_guts;
		halt;
		err := 0;
	end;
end;

procedure open_playing;
begin
    open(headerfile,root+'HEADER.MON',access_method := direct,
	sharing := readwrite,
	history := old,
    error := continue);
    
    open(roomfile,root+'ROOMS.MON',access_method := direct,
	sharing := readwrite,
	history := old,
	error := continue);

    open(namfile,root+'NAMS.MON',access_method := direct,
	sharing := readwrite,
	history := old,
	error := continue);

    open(eventfile,root+'EVENTS.MON',access_method := direct,
	sharing := readwrite,
	history := old,
	error := continue);

    open(descfile,root+'DESC.MON',access_method := direct,
	sharing := readwrite,
	history := old,
	error := continue);

    open(indexfile,root+'INDEX.MON',access_method := direct,
	sharing := readwrite,
	history := old,
	error := continue);

    open(linefile,root+'LINE.MON',access_method := direct,
	sharing := readwrite,
	history := old,
	error := continue);

    open(intfile,root+'INTFILE.MON',access_method := direct,
	sharing := readwrite,
	history := old,
	error := continue);

    open(objfile,root+'OBJECTS.MON',access_method := direct,
	sharing := readwrite,
	history := old,
	error := continue);

    open(spellfile,root+'SPELLS.MON',access_method := direct,
	sharing := readwrite,
	history := old,
	error := continue);

end;

procedure open_modify;
begin
    open(headerfile,root+'HEADER.MON',access_method := direct,
	sharing := none,
	history := unknown,
    error := continue);
    
    open(roomfile,root+'ROOMS.MON',access_method := direct,
	sharing := none,
	history := unknown,
	error := continue);

    open(namfile,root+'NAMS.MON',access_method := direct,
	sharing := none,
	history := unknown,
	error := continue);

    open(eventfile,root+'EVENTS.MON',access_method := direct,
	sharing := none,
	history := unknown,
	error := continue);

    open(descfile,root+'DESC.MON',access_method := direct,
	sharing := none,
	history := unknown,
	error := continue);

    open(indexfile,root+'INDEX.MON',access_method := direct,
	sharing := none,
	history := unknown,
	error := continue);

    open(linefile,root+'LINE.MON',access_method := direct,
	sharing := none,
	history := unknown,
	error := continue);

    open(intfile,root+'INTFILE.MON',access_method := direct,
	sharing := none,
	history := unknown,
	error := continue);

    open(objfile,root+'OBJECTS.MON',access_method := direct,
	sharing := none,
	history := unknown,
	error := continue);

    open(spellfile,root+'SPELLS.MON',access_method := direct,
	sharing := none,
	history := unknown,
	error := continue);

end;



[global]
function open_database(playing : boolean := true): boolean;
begin
    if debug then writeln('%open_database:',playing);

    if playing then open_playing
    else open_modify;

    if ((status(roomfile)<>0) or
	(status(namfile)<>0) or
	(status(eventfile)<>0) or
	(status(descfile)<>0) or
	(status(indexfile)<>0) or
	(status(intfile)<>0) or
	(status(objfile)<>0) or
	(status(spellfile)<>0) or
	(status(headerfile)<>0) )
    then begin
	if debug then writeln('%open_database: fail');
	open_database :=false
    end else begin
	if debug then writeln('%open_database: succeed');
	open_database :=true
    end;

end;	{ open_database }

[global] procedure close_database;
begin
    close(roomfile);
    close(namfile);
    close(eventfile);
    close(descfile);
    close(indexfile);
    close(intfile);
    close(objfile);
    close(spellfile);
    close(headerfile);
end;

[global]
procedure getheader(n: integer);
var
    err: integer;
begin
    headerfile^.validate := 0;
    err := 0;
    if debug then
	writeln('%getheader(',n:1,')');
    find(headerfile,n,error := continue);
    while status(headerfile) > 0 do begin
	deadcheck(err,'getheader');
	collision_wait;
	find(headerfile,n,error := continue);
    end;

    if headerfile^.validate <> n then begin
	writeln('%Fatal error in getheader');
	writeln('%Wrong validate code');
	writeln('%Record number = ',n:1);
	writeln('%Validate code = ',headerfile^.validate:1);
	unlock (headerfile, error := continue);
	halt;
    end;

    header := headerfile^;
end;	{ getheader }

[global]
procedure putheader;
begin
    locate(headerfile,header.validate);
    headerfile^ := header;
    put(headerfile);
end; { putheader }

[global]
procedure freeheader;	{ unlock the record if you're not going to write it }
begin
    unlock(headerfile);
end;

{ first procedure of form getX
  attempts to get given room record
  resolves record access conflicts, checks for deadlocks
  Locks record; use freeroom immediately after getroom if data is
  for read-only
}
[global]
procedure getroom(n: integer:= 0);
var
    err: integer;
begin
    if n = 0 then
	n := location;
    roomfile^.valid := 0;
    err := 0;
    if debug then
	    writeln('%getroom(',n:1,')');
    find(roomfile,n,error := continue);
    while status(roomfile) > 0 do begin
	deadcheck(err,'getroom');
	collision_wait;
	find(roomfile,n,error := continue);
    end;
   
    if roomfile^.valid <> n then begin
	writeln('%Fatal error in getroom');
	writeln('%Wrong validate code');
	writeln('%Record number = ',n:1);
	writeln('%Validate code = ',roomfile^.valid:1);
	unlock (roomfile, error := continue);
	halt;
    end;

    here := roomfile^;

    inmem := false;
		{ since this getroom could be doing anything, we will
		  assume that it is bozoing the correct here record for
		  this room.  If this getroom called by gethere, then
		  gethere will correct inmem immediately.  Otherwise
		  the next gethere will restore the correct here record. }
end;	{ getroom }

[global]
procedure putroom;
begin
    locate(roomfile,here.valid);
    roomfile^ := here;
    put(roomfile);
end;	{ putroom }

[global]
procedure freeroom;	{ unlock the record if you're not going to write it }
begin
    unlock(roomfile);
end;

{ generic namfile handlic procedures: hurtta@finuh }

procedure get_namfile(reccode: integer; var rec: namrec);
var err: integer;
begin
    namfile^.validate := 0;
    err := 0; 
    find(namfile,reccode,error := continue);
    while status(namfile) > 0 do begin
	deadcheck(err,'get_namfile');
	collision_wait;
	find(namfile,reccode,error := continue);
    end;
    if namfile^.validate <> reccode then begin
	writeln('%Fatal error in get_namfile');
	writeln('%Wrong validate code');
	writeln('%Record number = ',reccode:1);
	writeln('%Validate code = ',namfile^.validate:1);
	unlock (namfile, error := continue);
	halt;
    end;
    rec := namfile^;
end; { get_namfile }

procedure put_namfile(reccode: integer; rec: namrec);
begin
    if rec.validate <> reccode then begin
	writeln('%Fatal error in put_namfile');
	writeln('%Wrong validate code');
	writeln('%Record number = ',reccode:1);
	writeln('%Validate code = ',rec.validate:1);
	unlock(namfile, error := continue);
	halt;
    end;
    locate(namfile,reccode);
    namfile^:= rec;
    put(namfile);
end; { put_namfile }

[global]
procedure getown;
begin
    get_namfile(T_OWN,own);
end; { getown }

[global]
procedure freeown;
begin
    unlock(namfile);
end; { freeown }

[global]
procedure putown;
begin
    put_namfile(T_OWN,own);
end; { putown }


[global]
procedure getnam;   { rooms' name }
begin
    get_namfile(T_NAM,nam);
end; { getnam }

[global]
procedure freenam;
begin
    unlock(namfile);
end; { freenam }

[global]
procedure putnam;
begin
    put_namfile(T_NAM,nam);
end; { putnam }

[global]
procedure getobj(n: integer);
var
	err: integer;

begin
    if n = 0 then
	n := location;
    objfile^.objnum := 0;
    err := 0;
    find(objfile,n,error := continue);
    while status(objfile) > 0 do begin
	deadcheck(err,'getobj');
	collision_wait;
	find(objfile,n,error := continue);
    end;
    if objfile^.objnum <> n then begin
	writeln('%Fatal error in getobj');
	writeln('%Wrong validate code');
	writeln('%Record number = ',n:1);
	writeln('%Validate code = ',objfile^.objnum:1);
	unlock (objfile, error := continue);
	halt;
    end;

    obj := objfile^;
end;	{ getobj }

[global]
procedure putobj;
begin
    locate(objfile,obj.objnum);
    objfile^ := obj;
    put(objfile);
end;	{ putobj }

[global]
procedure freeobj;	{ unlock the record if you're not going to write it }
begin
    unlock(objfile);
end;	{ freeobj }


[global]
procedure getint(n: integer);
var
    err: integer;
begin
    intfile^.intnum := 0;
    err := 0;
    find(intfile,n,error := continue);
    while status(intfile) > 0 do begin
	deadcheck(err,'getint');
	collision_wait;
	find(intfile,n,error := continue);
    end;

    if intfile^.intnum <> n then begin
	writeln('%Fatal error in getint');
	writeln('%Wrong validate code');
	writeln('%Record number = ',n:1);
	writeln('%Validate code = ',intfile^.intnum:1);
	unlock (intfile, error := continue);
	halt;
    end;

    anint := intfile^;
end;	{ getint }


[global]
procedure freeint;
begin
    unlock(intfile);
end;	{ getint }

[global]
procedure putint;
var
    n: integer;
begin
    n := anint.intnum;
    locate(intfile,n);
    intfile^:= anint;
    put(intfile);
end;	{ putint }


[global]
procedure getspell(n: integer := 0);
var
    err: integer;
begin
    if n = 0 then
	n := mylog;

    spellfile^.recnum := 0;
    err := 0;
    find(spellfile,n,error := continue);
    while status(spellfile) > 0 do begin
	deadcheck(err,'getspell');
	collision_wait;
	find(spellfile,n,error := continue);
    end;
    
    if spellfile^.recnum <> n then begin
	writeln('%Fatal error in getspell');
	writeln('%Wrong validate code');
	writeln('%Record number = ',n:1);
	writeln('%Validate code = ',spellfile^.recnum:1);
	unlock (spellfile, error := continue);
	halt;
    end;

    spell := spellfile^;
end;	{ getspell }

[global]
procedure freespell;
begin
    unlock(spellfile);
end;	{ freespell }

[global]
procedure putspell;
var
    n: integer;
begin
    n := spell.recnum;
    locate(spellfile,n);
    spellfile^:= spell;
    put(spellfile);
end;	{ putspell }


[global]
procedure getuser;	{ get log rec with everyone's userids in it }
begin
    get_namfile(T_USER,user);
end;	{ getuser }

[global]
procedure freeuser;
begin
    unlock(namfile);
end;	{ freeuser }

[global]
procedure putuser;
begin
    put_namfile(T_USER,user);
end;	{ putuser }

[global]
procedure getpasswd;	{ get log rec with everyone's password in it }
begin
    get_namfile(T_PASSWD,passwd);
end;	{ getpasswd }

[global]
procedure freepasswd;
begin
    unlock(namfile);
end;	{ freepasswd }

[global]
procedure putpasswd;
begin
    put_namfile(T_PASSWD,passwd);
end;	{ putpasswd }


[global]
procedure getreal_user;	{ get log rec with everyone's userids in it }
begin
    get_namfile(T_REAL_USER,real_user);
end;	{ getreal_user }

[global]
procedure freereal_user;
begin
    unlock(namfile);
end;	{ freereal_user }

[global]
procedure putreal_user;
begin
    put_namfile(T_REAL_USER,real_user);
end;	{ putreal_user }

[global]
procedure getspell_name;	{ get spell name rec }
begin
    get_namfile(T_SPELL_NAME,spell_name);
end;	{ getspell_name }

[global]
procedure freespell_name;
begin
    unlock(namfile);
end;	{ freespell_name }

[global]
procedure putspell_name;
begin
    put_namfile(T_SPELL_NAME,spell_name);
end;	{ putspell_name }


[global]
procedure getdate;	{ get log rec with date of last play in it }
begin
    get_namfile(T_DATE,adate);
end;	{ getdate }

[global]
procedure freedate;
begin
    unlock(namfile);
end;	{ freedate }

[global]
procedure putdate;
begin
    put_namfile(T_DATE,adate);
end;	{ freedate }

[global]
procedure gettime;	{ get log rec with time of last play in it }
begin
    get_namfile(T_TIME,atime);
end;	{ gettime }

[global]
procedure freetime;
begin
    unlock(namfile);
end;	{ freetime }

[global]
procedure puttime;
begin
    put_namfile(T_TIME,atime);
end;	{ puttime }

[global]
procedure getobjnam;
begin
    get_namfile(T_OBJNAM,objnam);
end;	{ getobjnam }

[global]
procedure freeobjnam;
begin
    unlock(namfile);
end;	{ freeobjnam }

[global]
procedure putobjnam;
begin
    put_namfile(T_OBJNAM,objnam);
end;	{ putobjnam }

[global]
procedure getobjown;
begin
    get_namfile(T_OBJOWN,objown);
end;	{ getobjown }

[global]
procedure freeobjown;
begin
    unlock(namfile);
end;	{ freeobjown }

[global]
procedure putobjown;
begin
    put_namfile(T_OBJOWN,objown);
end;	{ putobjown }

[global]
procedure getpers;	{ get log rec with everyone's pers names in it }
begin
    get_namfile(T_PERS,pers);
end;	{ getpers }

[global]
procedure freepers;
begin
    unlock(namfile);
end;	{ freepers }

[global]
procedure putpers;
begin
    put_namfile(T_PERS,pers);
end;	{ putpers }

[global]
procedure getevent(n: integer := 0);
var
    err: integer;
begin
    if n = 0 then
	    n := location;

    n := (n mod numevnts) + 1;

    eventfile^.validat := 0;
    err := 0;
    find(eventfile,n,error := continue);
    while status(eventfile) > 0 do begin
	deadcheck(err,'getevent');
	collision_wait;
	find(eventfile,n,error := continue);
    end;

    if eventfile^.validat <> n then begin
	writeln('%Fatal error in getevent');
	writeln('%Wrong validate code');
	writeln('%Record number = ',n:1);
	writeln('%Validate code = ',eventfile^.validat:1);
	unlock (eventfile, error := continue);
	halt;
    end;

    event := eventfile^;
end;	{ getevent }

[global]
procedure freeevent;
begin
    unlock(eventfile);
end;	{ freeevent }

[global]
procedure putevent;
begin
    locate(eventfile,event.validat);
    eventfile^:= event;
    put(eventfile);
end;	{ putevent }

[global]
procedure getblock(n: integer);
var
    err: integer;
begin
    if debug then
	writeln('%getblock: ',n:1);
    descfile^.descrinum := 0;
    err := 0;
    find(descfile,n,error := continue);
    while status(descfile) > 0 do begin
	deadcheck(err,'getblock');
	collision_wait;
	find(descfile,n,error := continue);
    end;

    if descfile^.descrinum <> n then begin
	writeln('%Fatal error in getblock');
	writeln('%Wrong validate code');
	writeln('%Record number = ',n:1);
	writeln('%Validate code = ',descfile^.descrinum:1);
	unlock (descfile, error := continue);
	halt;
    end;

    block := descfile^;
end;	{ getblock }

[global]
procedure putblock;
var
    n: integer;
begin
    n := block.descrinum;
    if debug then
	writeln('%putblock: ',n:1);
    if n <> 0 then begin
	locate(descfile,n);
	descfile^ := block;
	put(descfile);
    end;
end;	{ putblock }

[global]
procedure freeblock;	{ unlock the record if you're not going to write it }
begin
    unlock(descfile);
end;	{ freeblock }


[global]
procedure getline(n: integer);
var
    err: integer;
begin
    if n = -1 then begin
	oneliner.theline := '';
    end else begin
	err := 0;
	linefile^.linenum := 0;
	find(linefile,n,error := continue);
	while status (linefile) > 0 do begin
	    deadcheck(err,'getline');
	    collision_wait;
	    find(linefile,n,error := continue);
	end;

	if linefile^.linenum <> n then begin
	    writeln('%Fatal error in getline');
	    writeln('%Wrong validate code');
	    writeln('%Record number = ',n:1);
	    writeln('%Validate code = ',linefile^.linenum:1);
	    unlock (descfile, error := continue);
	    halt;
	end;

	oneliner := linefile^;
    end;
end;	{ getline }

[global]
procedure putline;
begin
    if oneliner.linenum > 0 then begin
	locate(linefile,oneliner.linenum);
	linefile^ := oneliner;
	put(linefile);
    end;
end;	{ putline }

[global]
procedure freeline;	{ unlock the record if you're not going to write it }
begin
    unlock(linefile);
end;	{ freeline }

{
Index record 1 -- Description blocks that are free
Index record 2 -- One liners that are free
}

[global]
procedure getindex(n: integer);
var
    err: integer;
begin
    indexfile^.indexnum := 0;
    err := 0;
    find(indexfile,n,error := continue);
    while status(indexfile) > 0 do begin
	deadcheck(err,'getindex');
	collision_wait;
	find(indexfile,n,error := continue);
    end;

    if indexfile^.indexnum <> n then begin
	writeln('%Fatal error in getindex');
	writeln('%Wrong validate code');
	writeln('%Record number = ',n:1);
	writeln('%Validate code = ',indexfile^.indexnum:1);
	unlock (indexfile, error := continue);
	halt;
    end;

    indx := indexfile^;
end;	{ getindex }

[global]
procedure putindex;
begin
    locate(indexfile,indx.indexnum);
    indexfile^ := indx;
    put(indexfile);
end;	{ putindex }

[global]
procedure freeindex;	{ unlock the record if you're not going to write it }
begin
    unlock(indexfile);
end;	{ freeindex }

procedure getglobal;
var
    err: integer;
begin
    intfile^.intnum := 0;
    err := 0;
    find(intfile,N_GLOBAL,error := continue);
    while status(intfile) > 0 do begin
	deadcheck(err,'getglobal');
	collision_wait;
	find(intfile,N_GLOBAL,error := continue);
    end;

    if intfile^.intnum <> N_GLOBAL then begin
	writeln('%Fatal error in getglobal');
	writeln('%Wrong validate code');
	writeln('%Record number = ',N_GLOBAL:1);
	writeln('%Validate code = ',intfile^.intnum:1);
	unlock (intfile, error := continue);
	halt;
    end;

    global := intfile^;
end;	{ getglobal }

procedure putglobal;
begin
    locate(intfile,global.intnum);
    intfile^ := global;
    put(intfile);
end;	{ putglobal }

procedure freeglobal;
begin 
    unlock(intfile);
end;	{ freeglobal }

[global]
procedure log_event(	send: integer := 0;	{ slot of sender }
			act:integer;		{ what event occurred }
			targ: integer := 0;	{ target of event }
			p: integer := 0;	{ expansion parameter }
			s: string := '';	{ string for messages }
			room: integer := 0	{ room to log event in }
		   );

begin
	if room = 0 then
		room := location;
	getevent(room);
	event.point := event.point + 1;
	if debug then
		writeln('%logging event ',act:1,' to point ',event.point:1);
	if event.point > maxevent then
		event.point := 1;
	with event.evnt[event.point] do begin
		sender := send;
		action := act;
		target := targ;
		parm := p;
		msg := s;
		loc := room;
	end;
	putevent;
end; { log_event }


[global]
function read_global_flag (flag: integer; force_read: boolean := false): boolean;
begin
    if Gf_Types [ flag] <> G_Flag then begin
	writeln('%Error in function read_global_flag:');
        writeln('%Global value #',flag:1,' isn''t boolean flag.');
	writeln('%Notify Monster Manager.');
    end;
    if read_global or force_read then begin
	getglobal;
	freeglobal;
	read_global := false;
    end;
    read_global_flag := global.int[ flag ]>0;
end; { read_global-flag }

[global]
procedure set_global_flag (flag: integer; value: boolean;
			    message: string := '');
var lcv: integer;
begin
    if Gf_Types [ flag] <> G_Flag then begin
	writeln('%Error in function set_global_flag:');
        writeln('%Global value #',flag:1,' isn''t boolean flag.');
	writeln('%Notify Monster Manager.');
    end else begin

	getglobal;
	if value then global.int[flag] := 1
	else global.int[flag] := 0;
	putglobal;
	read_global := false;
   
	for lcv :=1 to numevnts do
          log_event(0,E_GLOBAL_CHANGE,0,0,message,lcv);

    end;
end; { set_global_flag }


[global]
function view_global_value (flag: integer; force_read: boolean := false): 
	string;
begin
    
   if read_global or force_read then begin
	getglobal;
	freeglobal;
	read_global := false;
    end;

    case Gf_Types [ flag] of 
	G_Flag: begin
	    if global.int [flag] > 0 then
		view_global_value := 'Boolean: TRUE'
	    else view_global_value := 'Boolean: FALSE'
	end;
	G_Int: begin
	    if global.int [flag] = 0 then
		view_global_value := 'Integer: Zero'
	    else view_global_value := 'Integer: NonZero'
	end;
	G_Text: begin
	    if global.int [flag] > 0 then
		view_global_value := 'Description: Block'
	    else if global.int [flag] < 0 then
		view_global_value := 'Desription: Line'
	    else view_global_value := 'Description: None'
	end;
	G_Code: begin
	    if global.int [flag] > 0 then
		view_global_value := 'Clobal Code: Exist'
	    else view_global_value := 'Clobal Code: None'
	end;
        otherwise view_global_value := 'Unknown';
 
    end;
end; { view_global_value }


[global]
function alloc_general(class: integer; 
			var n: integer):boolean; { hurtta@finuh }
var
	found: boolean;

begin
	getindex(class);
	if indx.inuse = indx.top then begin
		freeindex;
		n := 0;
		alloc_general := false
	end else begin
		n := 1;
		found := false;
		while (not found) and (n <= indx.top) do begin
			if indx.free[n] then
				found := true
			else
				n := n + 1;
		end;
		if found then begin
			indx.free[n] := false;
			alloc_general := true;
			indx.inuse := indx.inuse + 1;
			putindex;
		end else begin
			freeindex;
		       	writeln('%serious error in alloc_general; notify Monster Manager');
			alloc_general := false;
		end;
	end;
end;                              

[global]
procedure delete_general(class: integer; var n: integer); { hurtta@finuh }

begin
	if n <> 0 then begin
		getindex(class);
		indx.inuse := indx.inuse - 1;
		indx.free[n] := true;
		putindex;
                n := 0;
	end;
end;


[global]
function level(score: integer): integer;
var i : integer;
begin
  level := 1;
  for i := 1 to levels do if leveltable[i].exp <= score then
     level := i;
end; { level }

[global]
procedure command_help(command: shortstring);
var fd: text;
    line: string;
    found: boolean;
    count: integer;

    procedure leave;
    begin
	writeln('EXIT');
	line := '-';
    end;

begin
    open(fd,root+'monster.help',readonly,error:=continue);
    if status(fd) > 0 then begin
	writeln('Can''t open monster.help. Notify Monster Manager');
    end else begin
	found := false;
	reset(fd);
	while not eof(fd) and not found do begin
	    readln(fd,line);
	    if line = ':'+command then found := true
	end;
	
	if not found then
	    writeln ('No entry for ''',command,'''.');
	    
	count := 0;
	while not eof(fd) and found do begin
	    readln(fd,line);
	    if line > '' then begin
		if line[1] = ':' then found := false
		else writeln(line);
	    end else writeln;
	    count := count + 1;
	    if count > terminal_page_len-2 then begin
		count := 0;
		grab_line('-more-',line,erase := true,eof_handler := leave);
		if line > '' then found := false;
	    end;
	end;
	close(fd);
    end;
end; { command_help }

[global]
procedure add_counter(rec: integer; player: integer; n: integer := 1);
begin
    getint(rec);
    anint.int[player] := anint.int[player] +n;
    putint;   
end;

[global]
procedure sub_counter(rec: integer; player: integer; n: integer := 1);
begin
    getint(rec);
    anint.int[player] := anint.int[player] -n;
    putint;   
end;

[global]
function get_counter(rec: integer; player: integer): integer;
begin
    getint(rec);
    freeint;
    get_counter := anint.int[player];
end;

[global] 
procedure change_owner(source,target: integer);
var i: integer;
    acp: integer;
begin

    acp := 0;
    for i := 1 to maxexit do
	if here.exits[i].kind = 5 then acp := acp +1;

    if source > 0 then begin
	sub_counter(N_NUMROOMS,source);
	sub_counter(N_ACCEPT,source,acp);
    end ;

    if target > 0 then begin
	add_counter(N_NUMROOMS,target);
	add_counter(N_ACCEPT,target,acp);
    end;
end; { change_owner }

{ for /REBUILD and /BUILD }

[global]
procedure addrooms(n: integer);
var	i: integer;
begin
	getindex(I_ROOM);
	if indx.top + n > maxroom then begin { maxroom limits all kind names }
	    writeln('Number for identifiers limited to ',maxroom:1,'.');
	    writeln('Can''t add ',n:1,' rooms.');
	    n := maxroom - indx.top;
	    writeln('Adding only ',n:1,' rooms.');
	end;

	if indx.top + n > maxindex then begin { maxindex limits all kind blocks }
	    writeln('Number for blocks limited to ',maxindex:1,'.');
	    writeln('Can''t add ',n:1,' rooms.');
	    n := maxindex - indx.top;
	    writeln('Adding only ',n:1,' rooms.');
	end;

	for i := indx.top+1 to indx.top+n do begin
		locate(roomfile,i);
		roomfile^.valid := i;
		roomfile^.locnum := i;
		roomfile^.primary := 0;
		roomfile^.secondary := 0;
		roomfile^.which := 0;
		put(roomfile);
	end;
	indx.top := indx.top + n;
	putindex;
end;

[global]
procedure addints(n: integer);
var	i: integer;
begin
	getindex(I_INT);
	if indx.top + n > maxindex then begin { maxindex limits all kind blocks }
	    writeln('Number for blocks limited to ',maxindex:1,'.');
	    writeln('Can''t add ',n:1,' integertables.');
	    n := maxindex - indx.top;
	    writeln('Adding only ',n:1,' integertables.');
	end;
	for i := indx.top+1 to indx.top+n do begin
		locate(intfile,i);
		intfile^.intnum := i;
		put(intfile);
	end;
	indx.top := indx.top + n;
	putindex;
end;

[global]
procedure addlines(n: integer);
var	i: integer;
begin
	getindex(I_LINE);
	if indx.top + n > maxindex then begin { maxindex limits all kind blocks }
	    writeln('Number for blocks limited to ',maxindex:1,'.');
	    writeln('Can''t add ',n:1,' line descriptions.');
	    n := maxindex - indx.top;
	    writeln('Adding only ',n:1,' line descriptions.');
	end;
	for i := indx.top+1 to indx.top+n do begin
		locate(linefile,i);
		linefile^.linenum := i;
		put(linefile);
	end;
	indx.top := indx.top + n;
	putindex;
end;

[global]
procedure addblocks(n: integer);
var	i: integer;
begin
	getindex(I_BLOCK);
	if indx.top + n > maxindex then begin { maxindex limits all kind blocks }
	    writeln('Number for blocks limited to ',maxindex:1,'.');
	    writeln('Can''t add ',n:1,' block descriptions.');
	    n := maxindex - indx.top;
	    writeln('Adding only ',n:1,' block descriptions.');
	end;
	for i := indx.top+1 to indx.top+n do begin
		locate(descfile,i);
		descfile^.descrinum := i;
		put(descfile);
	end;
	indx.top := indx.top + n;
	putindex;
end;

[global]
procedure addobjects(n: integer);
var	i: integer;
begin
	getindex(I_OBJECT);
	if indx.top + n > maxroom then begin { maxroom limits all kind names }
	    writeln('Number for identifiers limited to ',maxroom:1,'.');
	    writeln('Can''t add ',n:1,' objects.');
	    n := maxroom - indx.top;
	    writeln('Adding only ',n:1,' objects.');
	end;
	if indx.top + n > maxindex then begin { maxindex limits all kind blocks }
	    writeln('Number for blocks limited to ',maxindex:1,'.');
	    writeln('Can''t add ',n:1,' objects.');
	    n := maxindex - indx.top;
	    writeln('Adding only ',n:1,' objects.');
	end;
	for i := indx.top+1 to indx.top+n do begin
		locate(objfile,i);
		objfile^.objnum := i;
		put(objfile);
	end;
	indx.top := indx.top + n;
	putindex;
end;

[global]
function file_name(code: integer): mega_string;
var apu: mega_string;
begin
  writev(apu,coderoot,'CODE',code:1,'.MON');
  file_name := apu
end; { file_name }


[global]  
procedure addheaders(amount: integer);
var i: integer;
    fl: text;
begin                    
   getindex(I_HEADER);
    if indx.top + amount > maxindex then begin { maxindex limits all kind blocks }
	writeln('Number for blocks limited to ',maxindex:1,'.');
	writeln('Can''t add ',amount:1,' MDL headers.');
	amount := maxindex - indx.top;
	writeln('Adding only ',amount:1,' MDL headers.');
    end;
   for i := indx.top +1 to indx.top + amount  do begin
      indx.free[i] := true;  

      locate(headerfile,i);
      headerfile^.validate := i;
      put(headerfile);             
                                
      open(fl,file_name(i),new, record_length := mega_length +20);
      rewrite(fl);
      close(fl)                 
   end;                         

   indx.top := indx.top + amount;
   putindex;                    
end;

[global]
procedure write_debug(a: string; b: mega_string := '');
begin
   if debug then begin
      write(a,'   ');
      if length(b) > 200 then	{ system limit printable string }
                                { about 200 characters          }
         writeln('(PARAMETER TOO LONG FOR PRINTING)')
      else writeln(b);
   end;
end;

[global] 
function monster_owner  (code: integer; class : integer := 0): shortstring;
begin  
  write_debug ('%monster_owner');
  getheader(code);
  freeheader;
  case class of
    0: monster_owner := header.owner;
    1: monster_owner := header.author;
  end; { case }
end; { monster_owner }

[global] 
procedure set_owner (code: integer; class : integer := 0; owner: shortstring);
begin  
  write_debug ('%set_owner');
  getheader(code);
  case class of
    0: header.owner := owner;
    1: header.author := owner;
  end; { case }
  putheader
end; { set_owner }

[global]                                 
procedure delete_program (code: integer);
label 1;  
var fl: text;
    count,apu,errorcode: integer;
begin
  write_debug ('%delete_program');
  apu := code;
  count := 0;
  repeat
    open (fl,file_name(code),old,sharing:=NONE,error := continue,
          record_length := mega_length +20);
    errorcode := status(fl);
    if errorcode > 0 then begin
       count := count +1;
       write_debug ('%collision in delete_program'); 
       if count > 10 then  begin
          if debug then begin
	     writeln ('%Deadlock in delete_program.');
	     writeln ('% Error code (status): ',errorcode:1);
	  end;
          goto 1
       end;
       wait (0.2);      { collision is very rare in here }
    end
  until errorcode <= 0;
  reset (fl);
  truncate(fl);
  close(fl);
1:
end; { delete_program }

[global]
procedure system_view;
var
	used,free,total: integer;

begin
	writeln;
	getindex(I_BLOCK);
	freeindex;
	used := indx.inuse;
	total := indx.top;
	free := total - used;

	writeln('               used   free   total');
	writeln('Block file   ',used:5,'  ',free:5,'   ',total:5);

	getindex(I_LINE);
	freeindex;
	used := indx.inuse;
	total := indx.top;
	free := total - used;
	writeln('Line file    ',used:5,'  ',free:5,'   ',total:5);

	getindex(I_ROOM);
	freeindex;
	used := indx.inuse;
	total := indx.top;
	free := total - used;
	writeln('Room file    ',used:5,'  ',free:5,'   ',total:5);

	getindex(I_OBJECT);
	freeindex;
	used := indx.inuse;
	total := indx.top;
	free := total - used;
	writeln('Object file  ',used:5,'  ',free:5,'   ',total:5);

	getindex(I_INT);
	freeindex;
	used := indx.inuse;
	total := indx.top;
	free := total - used;
	writeln('Integer file ',used:5,'  ',free:5,'   ',total:5);

	getindex(I_HEADER);
	freeindex;
	used := indx.inuse;
	total := indx.top;
	free := total - used;
	writeln('Header file  ',used:5,'  ',free:5,'   ',total:5);

	getindex(I_SPELL);
	freeindex;
	used := indx.inuse;
	total := indx.top;
	free := total - used;
	writeln('Spells       ',used:5,'  ',free:5,'   ',total:5);

	getindex(I_PLAYER);
	freeindex;
	used := indx.inuse;
	total := indx.top;
	free := total - used;
	writeln('Players      ',used:5,'  ',free:5,'   ',total:5);

	writeln;              
end; { system_view }

[ global ]
procedure fix_view_global_flags;
begin
    writeln('Global flags and values:');
    writeln;
    writeln('Monster active: ',view_global_value(GF_ACTIVE,TRUE));
    writeln('Database valid: ',view_global_value(GF_VALID));
    writeln('Wartime:        ',view_global_value(GF_WARTIME));
    writeln('Welcome text:   ',view_global_value(GF_STARTGAME));
    writeln('NewPlayer text: ',view_global_value(GF_NEWPLAYER));
    writeln('Global Hook:    ',view_global_value(GF_CODE));
end;

end. { enf of module }
