[ INHERIT('database', 'guts', 'global' , 'privusers', 'parser', 'alloc')]
PROGRAM MONSTER_REBULD (INPUT, OUTPUT) ;
 
{
PROGRAM DESCRIPTION: 
 
    Image for MONSTER/REBUILD (and MONSTER/FIX) -command
 
AUTHORS: 
 
    Kari Hurtta
    Rick Skrenta (original REBUILD in MON.PAS)
 
CREATION DATE:	25.6.1992 (moved to MONSTER_REBUILD)
 
 
	    C H A N G E   L O G
 
     Date     |   Name  | Description
--------------+---------+-------------------------------------------------------
   25.06.1992 | Hurtta  | /REBUILD
   26.06.1992 |         | /FIX and /BATCH
   27.06.1992 |         | Module VERSION
    9.07.1992 |         | Fixed some help text
   12.08.1992 |         | Dummy player_here removed (now defined in module
              |         |   PARSER)
   24.10.1992 |		| fix_repair_location uudelleenkirjoitettu
	      |		| fixed dummy gethere !!!!!!!!!!!!!!!!!!!!!!!!!!
}

{ in module KEYS }
[external]
procedure encrypt(key: shortstring; n : integer := 0);
external;

{ DUMMY for linker }
[global]
procedure checkevents(silent: boolean := false);
begin
end;

{ ---------- }

[global]
procedure gethere(n: integer);
begin
    getroom(n);
    freeroom;
end;

const
	cli$_present	= 261401;
	cli$_absent	= 229872;
	cli$_negated	= 229880;
	cli$_defaulted	= 261409;
	ss$_normal	= 1;

type
	word_unsigned	= [word] 0..65535;
	cond_value	= [long] unsigned;

var
	{ userid have in module ALLOC }
	wizard		: [external] boolean;


function cli$get_value (%descr entity_desc: string;
			%descr retdesc: string;
			%ref retlength: word_unsigned): cond_value;
	external;

function cli$present (%descr entity_desc: string): cond_value;
	external;


var 
    rebuild_system : boolean := false;
    fix_system  : boolean := false;
    batch_system : boolean := false;
    name : string := '';

procedure params;

var
	qualifier,
	value,
	s		: string;
	value_length	: word_unsigned;
	status1,
	status2		: cond_value;

begin
	qualifier := 'REBUILD';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
		if wizard then begin
			if REBUILD_OK then begin
				writeln('Do you really want to destroy the entire universe?');
				readln(s);
				if length(s) > 0 then
					if substr(lowcase(s),1,1) = 'y' then
						rebuild_system := true;
			end else
				writeln('/REBUILD is disabled.');
		end else
			writeln ('Only the Monster Manager may /REBUILD.');
	end;

	qualifier := 'FIX';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
	    if wizard then begin
		fix_system := true;
	    end else
		writeln ('Only the Monster Manager may /FIX.');
	end;

	qualifier := 'BATCH';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
	    if userid = MM_userid then begin
		status2 := cli$get_value (qualifier, value, value_length);
		if status2 = ss$_normal then begin
		    name := value;
		    batch_system := true { hurtta@finuh }
		end else begin
		    writeln ('Something is wrong with /BATCH.');
		end;
	    end else begin
		writeln ('Only Monster Manager may /BATCH.');
	    end;
	end;

	qualifier := 'DEBUG';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
	    if gen_debug then debug := true
	    else if userid = MM_userid then debug := true
	    else begin
		writeln ('You may not use /DEBUG.');
		debug := false
	    end
	end else debug := false;

	qualifier := 'OUTPUT';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
	    status2 := cli$get_value (qualifier, value, value_length);
	    if status2 = ss$_normal then begin
		close(OUTPUT);
		open(OUTPUT,value,new,default := '.LOG');
		rewrite(OUTPUT);
	    end else begin
		writeln ('Something is wrong with /OUTPUT.');
	    end;
	end else if status1 = cli$_negated then begin
		close(OUTPUT);
		open(OUTPUT,'NLA0:',new);
		rewrite(OUTPUT);
	end;

	qualifier := 'VERSION';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
		{ Don't take this out please... }
	  	writeln('Monster builder, written  by Kari Hurtta  at University of Helsinki,  1992');
		writeln('VERSION:     ',VERSION);
		writeln('DISTRIBUTED: ',DISTRIBUTED);
	end;

end;

var
   { userid is in module ALLOC }

    public_id, disowned_id, system_id: shortstring;


procedure rebuild; { was rebuild_system }
var
	i,j: integer;

begin
	mylog := 0;
	writeln('Creating index file 1-10');
	for i := 1 to 10 do begin
			{ 1 is blocklist
			  2 is linelist
			  3 is roomlist
			  4 is playeralloc
			  5 is player awake (playing game)
			  6 are objects
			  7 is intfile 
			  8 is headerfile
			  9 is ???
			  10 is spells
			}

		locate(indexfile,i);
		for j := 1 to maxindex do
			indexfile^.free[j] := true;
		indexfile^.indexnum := i;
		indexfile^.top := 0; { none of each to start }
		indexfile^.inuse := 0;
		put(indexfile);
	end;
          

	writeln('Initializing roomfile with 10 rooms');
	addrooms(10);

	writeln('Initializing block file with 10 description blocks');
	addblocks(10);

	writeln('Initializing line file with 10 lines');
	addlines(10);

	writeln('Initializing object file with 10 objects');
	addobjects(10);   

	writeln('Initializing header file for monsters with 5 headers');
	addheaders(5);

	writeln('Initializing namfile 1-',T_MAX:1);
	for j := 1 to T_MAX do begin
		locate(namfile,j);
		namfile^.validate := j;
		namfile^.loctop := 0;
		for i := 1 to maxroom do begin
			namfile^.idents[i] := '';
		end;
		put(namfile);
	end;

	writeln('Initializing eventfile');
	for i := 1 to numevnts + 1 do begin
		locate(eventfile,i);
		eventfile^.validat := i;
		eventfile^.point := 1;
		put(eventfile);
	end;

	writeln('Initializing intfile'); { minor changes by leino@finuha, }
 	for i := 1 to 10 do begin	{ hurtta@finuh }
		locate(intfile,i);
 		intfile^.intnum := i;
		put(intfile);
	end;

	getindex(I_INT);
	for i := 1 to 10 do
		indx.free[i] := false;
	indx.top := 10;
	indx.inuse := 10;
	putindex;

	writeln('Initializing global values.'); { Record #10 in intfile }
	getglobal;
	for I := 1 to GF_MAX do global.int[i] := 0;
	putglobal;
	set_global_flag(GF_VALID, TRUE); { Database is valid now }
	set_global_flag(GF_ACTIVE, TRUE); { Database is open }
	set_global_flag(GF_WARTIME, TRUE); { Violance is allowed }

	{ Player log records should have all their slots initially,
	  they don't have to be allocated because they use namrec
	  and intfile for their storage; they don't have their own
	  file to allocate
	}
	getindex(I_PLAYER);
	indx.top := maxplayers;
	putindex;
	getindex(I_ASLEEP);
	indx.top := maxplayers;
	putindex;

	writeln('Creating the Great Hall');
	if not nc_createroom('Great Hall') then begin
	    writeln('Creating the Great Hall FAILED');
	    halt;
	end;
	getroom(1);
	here.owner := public_id;
	putroom;
	getown;
	own.idents[1] := public_id;
	putown;

	writeln('Creating the Void');
	if not nc_createroom('Void') then begin	        { loc 2 }
	    writeln('Creating Void FAILED');
	    halt;
	end;
	getroom(2);
	here.owner := system_id;
	putroom;
	getown;
	own.idents[2] := system_id;
	putown;

	writeln('Creating the Pit of Fire');
	if not nc_createroom('Pit of Fire') then begin		{ loc 3 }
	    writeln('Creating Pit of Fire FAILED');
	    halt;
	end;
	getroom(3);
	here.owner := system_id;
	putroom;
	getown;
	own.idents[3] := system_id;
	putown;

	  		{ note that these are NOT public locations }

	{ spells have constant amount }
	getindex(I_SPELL);
	indx.top := maxspells;
	putindex;

	writeln('Use the SYSTEM command in MONSTER to view and add capacity to the database');
	writeln;
end; { rebuild }


procedure fix_help;     { fix -subsystem by hurtta@finuh }
begin  

   writeln ('A        Clear/create privileges database.');
   writeln ('B        Clear/create health database.');
   writeln ('C        Create event file.');
   writeln ('D        Reallocate describtins');
   writeln ('E        Leave /fix.');
   writeln ('F        Clear/create experience database.');
   writeln ('G        Calculate objects'' number in existence.');
   writeln ('GL       Clear/create global database.');
   writeln ('GS       Mark moster shutdown to global database.');
   writeln ('GU       Mark monster active to global database.');
   writeln ('GV       Show global database.');
   writeln ('G-       Mark monster database as invalid.');
   writeln ('G+       Mark monster database as valid.');
   writeln ('H        This list');
   writeln ('I        Repair index file.');
   writeln ('J        Repair paths.');
   writeln ('K        Reallocate MDL codes.');
   writeln ('L        Repair monsters'' location.');
   writeln ('M        Clear/create MDL database.');
   writeln ('N        Clear/create and recount quota database.');
   writeln ('O        Clear/create object database.');
   writeln ('OW       Check owners of objects, rooms and monsters.');
   writeln ('P        Clear/create player database.');
   writeln ('Q        Leave /fix');
   writeln ('R        Clear/create room database.');
   writeln ('S        Clear/create password database.');
   writeln ('SP       Clear/create spell database.');
   writeln ('V        View database capacity.');
   writeln ('?        This list'); 
   writeln;
   writeln ('Use SYSTEM command in MONSTER to add database capacity.');
end; { fix_help }
          
function fix_sure (s: string; batch: boolean): boolean;
var a: string;
begin
  if batch then begin
    writeln(s,'yes');
    fix_sure := true
  end else begin
    write (s); readln (a); writeln;  
    a := lowcase(a);
    fix_sure := (a = 'y') or (a = 'yes');        
  end;
end;

procedure fix_initialize_event (batch: boolean);
Var i: integer;
begin
   writeln('Initializing eventfile');
   for i := 1 to numevnts + 1 do begin
      locate(eventfile,i);
      eventfile^.validat := i;
      eventfile^.point := 1;
      put(eventfile);
   end;
   writeln ('Ready.');
end; { fix_initialize_event }


procedure fix_clear_monster (batch: boolean); 
var i,j,apu: integer;
begin  
   if fix_sure ('Do you want clear monster (NPC) database ?',batch) then begin
      writeln ('Clearing monster database...');
     
      locate(indexfile,I_HEADER);
      indexfile^.indexnum := I_HEADER;
      indexfile^.top := 0;
      indexfile^.inuse := 0;  
      for i := 1 to maxindex do indexfile^.free[i] := true;
      put(indexfile);    
  
      writeln ('Deleting code files...');
      DELETE_FILE (coderoot+'CODE*.MON.*'); { deleteing all codefiles }

      writeln('Initializing header file for monsters with 5 headers');
      addheaders(5);
  
      getindex (I_ROOM);
      freeindex;
                   
      writeln ('Clearing monsters from room database...');
      for i := 1 to maxroom do
         if not indx.free[i] then begin
   
            getroom (i);
            here.hook := 0;
	
	    for j := 1 to maxpeople do with here.people[j] do  
               if kind = P_MONSTER then begin
                  kind := 0;
                  username := '';
                  name := '';
                  parm := 0;
                end;
            putroom;
         end;          
         
      getuser;
      freeuser;
      getindex(I_player);
      freeindex;
    
      Writeln ('Clearing monsters from player list...');
      for i := 1 to maxplayers do 
         if not indx.free[i] then if user.idents[i] = '' then begin 
              apu := i;
              delete_log(apu)     { delete_log also command } 
                                  { getindex(I_PLAYER)      }
         end else if user.idents[i][1] = ':' then begin
             apu := i;
             delete_log (apu);
         end;

      writeln('Clearing hook from objects...');
      getindex(I_OBJECT);
      freeindex;
      for i := 1 to maxroom do
         if not indx.free[i] then begin
            getobj(i);
            obj.actindx := 0;
            putobj;
         end;

      writeln('Clearing spells...');
      getindex(I_SPELL);
      getint(N_SPELL);
      for i := 1 to maxspells do
          if not indx.free[i] then begin
	    anint.int[i] := 0;
	    indx.free[i] := true;
	    indx.inuse := indx.inuse -1;
	  end;
      putindex;
      putint;

      writeln('Clearing global codes...');
      getglobal;
      for i := 1 to GF_Max do if GF_Types [i] = G_Code then
	 global.int[i] := 0;
      freeglobal;

      writeln ('Ready.');
   end;
end;                

procedure int_in_use (n:integer);
var i: integer;
    free: boolean;
begin
   getindex(I_INT);
   free := false;
   if indx.top < n then begin
      for i := indx.top +1 to n do begin
         locate(intfile,i);
         intfile^.intnum := i;
         put(intfile);
         indx.free[i] := true;
      end;
      indx.top := n;
   end;
   if indx.free[n] then begin
      indx.free[n] := false;
      indx.inuse := indx.inuse +1
   end;
   putindex;
end; { int_in_use }

procedure fix_clear_spell (batch: boolean);
var i,j: integer;
begin
    if fix_sure ('Do you want clear spell database ?',batch) then begin
	writeln('Clearing spell levels...');
	for i := 1 to maxplayers do begin
	    locate(spellfile,i);
	    spellfile^.recnum := i;
	    for j := 1 to maxspells do spellfile^.level[j] := 0;
	    put(spellfile);
	end;
	
	writeln('Clearing spell using database...');
	locate(indexfile,I_SPELL);
	indexfile^.indexnum := I_SPELL;
	indexfile^.top := maxspells;
	indexfile^.inuse := 0;
	for i := 1 to maxindex do indexfile^.free[i] := true;
	put(indexfile);

	writeln ('Clearing spellname database...');
	locate(namfile,T_SPELL_NAME);   
	namfile^.validate := T_SPELL_NAME;
	namfile^.loctop := 0;
	for i := 1 to maxroom do namfile^.idents[i] := '';
	put(namfile);         

	writeln ('Clearing spell link database....');
	int_in_use(N_SPELL);
	getint(N_SPELL);
	for i := 1 to maxspells do anint.int[i] := 0;
	putint;

	writeln('Ready. Reallocate code file.');

    end;
end;

procedure fix_clear_player (batch: boolean);  { don't handle monsters }
var i,j: integer;
begin
  if fix_sure ('Do you want clear player file ?',batch) then begin
     writeln  ('Clearing player database ...');

     locate(indexfile,I_PLAYER);
     indexfile^.indexnum := I_PLAYER;
     indexfile^.top := maxplayers;
     indexfile^.inuse := 0;
     for i := 1 to maxindex do indexfile^.free[i] := true;
     put(indexfile);

     locate(indexfile,I_ASLEEP);
     indexfile^.indexnum := I_ASLEEP;
     indexfile^.top := maxplayers;
     indexfile^.inuse := 0;
     for i := 1 to maxindex do indexfile^.free[i] := true;
     put(indexfile);

     getindex(I_ROOM);
     freeindex;

     writeln ('Reset player names');
     locate(namfile,T_USER);    { players' userids }
     namfile^.validate := T_USER;
     namfile^.loctop := 0;
     for i := 1 to maxroom do namfile^.idents[i] := '';
     put(namfile);         { players' personal names }
     locate(namfile,T_PERS);
     namfile^.validate := T_PERS;
     namfile^.loctop := 0;
     for i := 1 to maxroom do namfile^.idents[i] := '';
     put(namfile);

     writeln ('Disowning rooms...');
     for i := 1 to maxroom do
        if not indx.free[i] then begin
           getown;
	   if own.idents[i] <> system_id then
	       own.idents[i] := disowned_id;
           putown;
   
           getroom (i);
	   if here.owner <> system_id then
	       here.owner := disowned_id;
	   putroom;
        end;          

                
     getindex(I_OBJECT);
     freeindex;
     
                           
     writeln ('Disowning objects ...');
     for i:= 1 to maxroom do if not indx.free[i] then begin

        getobjown;
	if objown.idents[i] <> system_id then
	    objown.idents[i] := disowned_id;
        putobjown;

     end;

     writeln ('Ready.');
     writeln ('Clear monster database and reallocate usage of line and block descriptions.');
     
  end else writeln ('Cancel.');
end;    

procedure fix_owner (batch: boolean);
var i,num: integer;
    rm,ob,code: indexrec;
    s: shortstring;
begin

    getindex(I_ROOM);
    freeindex;
    rm := indx;

     writeln ('Checking rooms ...');
     for i := 1 to maxroom do if not rm.free[i] then begin
	getown;  { locked }
	if (own.idents[i] <> system_id) and 
	      (own.idents[i] <> disowned_id) and
	      (own.idents[i] <> public_id) then
		if not exact_user(num,own.idents[i]) then begin
		    getroom(i); { locked }
		    writeln('Invalid owner of ',here.nicename,': ',
			own.idents[i],', disowning.');
		    own.idents[i] := disowned_id;
		    here.owner := disowned_id;
		    putroom;	{ freed }
		end;
	putown; { freed }
    end;

     getindex(I_OBJECT);
     freeindex; ob := indx;
     getobjnam; freeobjnam;
            
     writeln ('Checking objects ...');
     for i:= 1 to maxroom do if not ob.free[i] then begin
        getobjown; { locked }
	if (objown.idents[i] <> system_id) and 
	    (objown.idents[i] <> disowned_id) and
	    (objown.idents[i] <> public_id) then
	    if not exact_user(num,objown.idents[i]) then begin
		writeln('Invalid owner of ',objnam.idents[i],': ',
		    objown.idents[i],', disowning.');
		objown.idents[i] := disowned_id;
	    end;
	putobjown; { freed }
    end;


    getindex(I_HEADER);
    freeindex; code := indx;

    writeln ('Checking MDL codes (monsters and hooks) ...');
    for i := 1 to code.top do if not code.free[i] then begin
	s := monster_owner(i);
	if (s <> system_id) and  (s <> disowned_id) and (s <> public_id) then
	    if not exact_user(num,s) then begin
		writeln('Invalid owner of MDL code #',i:1,': ',
		    s,', disowning (author: ',monster_owner(i,1),').');
		set_owner(i,0,disowned_id); { don't change author of code }
	    end;
    end;

    writeln('Ready.');
end; { fix_owner }

procedure fix_clear_room (batch: boolean);
label 0;
var i: integer;
begin
  mylog := 0;
  if fix_sure('Do you want clear room database ? ',batch) then begin

     Writeln ('Creating index record for room database.');
     locate(indexfile, I_ROOM);
     for i := 1 to maxindex do indexfile^.free[i] := true;
     indexfile^.indexnum := I_ROOM;
     indexfile^.top := 0; { none of each to start }
     indexfile^.inuse := 0;
     put(indexfile);

     writeln ('Reseting room names');
     locate(namfile,T_NAM);
     namfile^.validate := T_NAM;
     namfile^.loctop := 0;
     for i := 1 to maxroom do namfile^.idents[i] := '';
     put(namfile);

     writeln ('Reset room owners');
     locate(namfile,T_OWN);
     namfile^.validate := T_OWN;
     namfile^.loctop := 0;
     for i := 1 to maxroom do namfile^.idents[i] := '';
     put(namfile);

     writeln('Initializing roomfile with 10 rooms');
     addrooms(10);

     writeln('Creating the Great Hall');
     if not nc_createroom('Great Hall') then begin
	writeln ('Creating of Great Hall FAILED');
	goto 0;
     end;
     getroom(1);
     here.owner := public_id; { public location }
     putroom;
     getown;
     own.idents[1] := public_id;
     putown;

     writeln('Creating the Void');
     if not nc_createroom('Void') then begin			{ loc 2 }
	writeln ('Creating of Void FAILED');
	goto 0;
     end;
     getroom(2);
     here.owner := system_id;
     putroom;
     getown;
     own.idents[2] := system_id;
     putown;


     writeln('Creating the Pit of Fire');
     if not nc_createroom('Pit of Fire') then begin	{ loc 3 }
	writeln ('Creating of Pit of Fire FAILED');
	goto 0;
     end;
     getroom(3);
     here.owner := system_id;
     putroom;
     getown;
     own.idents[3] := system_id;
     putown;

	  		{ note that these are NOT public locations }

     writeln ('Put all players to Great Hall');
     locate(intfile,N_LOCATION);
     intfile^.intnum := N_LOCATION;
     for i := 1 to maxplayers do intfile^.int[i] := 1;
     put(intfile);

     writeln ('Set existence of object to zero.');
     getindex(I_OBJECT);
     freeindex;
     for i := 1 to indx.top do if not indx.free[i] then begin
       getobj(i);
       obj.numexist := 0;
       putobj;
     end;
     writeln ('Ready.');
     writeln ('Clear monster (NPC) database and reallocate block and line descriptions');

  end else writeln ('Cancel.');
  0:
end;

procedure fix_clear_global (batch: boolean);
var i: integer;
begin
   if fix_sure ('Do you want clear global value database ? ',batch) then begin
	writeln ('Clearing global value database ...');

	int_in_use(N_GLOBAL);
	locate(intfile,N_GLOBAL);
	intfile^.intnum := N_GLOBAL;
	for i := 1 to GF_MAX do intfile^.int[i] := 0;
	put(intfile);

	writeln('Ready.');
	writeln('Reallocate code file (NPC database) and desciptions.');
    end;
end; { fix_clear_global }


procedure fix_clear_object (batch: boolean);
var i: integer;
begin
   if fix_sure ('Do you want clear object database ? ',batch) then begin
      writeln ('Clearing object database ...');

      locate(indexfile,I_OBJECT);
      indexfile^.indexnum := I_OBJECT;
      indexfile^.top := 0;
      indexfile^.inuse := 0;
      for i := 1 to maxindex do indexfile^.free[i] := true;
      put(indexfile);

     writeln ('Reseting object names');
     locate(namfile,T_OBJNAM);
     namfile^.validate := T_OBJNAM;
     namfile^.loctop := 0;
     for i := 1 to maxroom do namfile^.idents[i] := '';
     put(namfile);

     writeln ('Reset object owners');
     locate(namfile,T_OBJOWN);
     namfile^.validate := T_OBJOWN;
     namfile^.loctop := 0;
     for i := 1 to maxroom do namfile^.idents[i] := '';
     put(namfile);

      writeln('Initializing object file with 10 objects');
      addobjects(10);   

      writeln ('Ready.');
      writeln ('Reallocate usage of block and line descriptions.');
   end;
end;                            

procedure fix_repair_index (batch: boolean);
var i,j,count,old: integer;
begin
   writeln ('Repairing index file...');
   for i := 1 to 10 do begin
      getindex(i);  
      count := 0;
      for j := 1 to indx.top do 
         if not indx.free[j] then count := count +1;
      old := indx.inuse;
      indx.inuse := count;
      putindex;
      if old <> count then writeln('In index record #',i:1,
         ' is wrong allocation counter. Repaired.');
   end;
   writeln('Ready.');
end;                         


procedure fix_codes (batch: boolean);    
var ro,ob,cd,sp: indexrec;
    i,j: integer; 

    procedure alloc(n: integer);
    begin
      if n > 0 then begin
        cd.free[n] := false;
        cd.inuse := cd.inuse +1
      end;
    end;

begin
  writeln ('Reallacation MDL codes...');
  getindex(I_HEADER);
  freeindex;
  cd := indx;
  cd.inuse := 0;
  for i := 1 to maxindex do cd.free[i] := true;

  getindex(I_ROOM);
  freeindex;
  ro := indx;

  getindex(I_OBJECT);
  freeindex;
  ob := indx;

  getindex(I_SPELL);
  freeindex;
  sp := indx;

  writeln('Scan object file');
  for i := 1 to ob.top do if not ob.free[i] then begin
    getobj(i);
    freeobj;
    with obj do begin
      alloc (actindx);
    end
  end;
  
  writeln ('Scan room file');
  for i := 1 to ro.top do if not ro.free[i] then begin
    getroom(i);
    freeroom;
    alloc (here.hook);
    for j := 1 to maxpeople do with here.people[j] do begin
	if (kind = P_MONSTER) then alloc (parm);
    end
  end;               

  writeln('Scan spell database');
  getint(N_SPELL);
  freeint;
  for i := 1 to sp.top do if not sp.free[i] then 
    if anint.int[i] > 0 then alloc(anint.int[i]);

  locate(indexfile,I_HEADER);
  indexfile^ := cd;
  put(indexfile);

  writeln('Scan global codes');
  getglobal;
  freeglobal;
  for i := 1 to GF_MAX do if GF_Types[i] = G_Code then
    if global.int[i] > 0 then alloc(global.int[i]);
  
  writeln ('Ready.');
end;

procedure fix_descriptions (batch: boolean);    
var pe,ro,ob,ln,bl: indexrec;
    i,j: integer; 

    procedure alloc(n: integer);
    begin
      if (abs(n) = DEFAULT_LINE) or (n = 0) then { no allocate }
      else if n < 0 then begin
        ln.free[-n] := false;
        ln.inuse := ln.inuse +1
      end else begin
        bl.free[n] := false;
        bl.inuse := bl.inuse +1
      end;
    end;

begin
  writeln ('Reallocation descriptions...');
  getindex(I_LINE);
  freeindex;
  ln := indx;

  ln.inuse := 0;
  for i := 1 to maxindex do ln.free[i] := true;

  getindex(I_BLOCK);
  freeindex;
  bl := indx;

  bl.inuse := 0;
  for i := 1 to maxindex do bl.free[i] := true;
        

  getindex (I_PLAYER);
  freeindex;
  pe := indx;

  getindex(I_ROOM);
  freeindex;
  ro := indx;

  getindex(I_OBJECT);
  freeindex;
  ob := indx;

  writeln ('Scan self descriptions');
  getint(N_SELF);
  freeint;
  for i := 1 to pe.top do if not pe.free[i] then alloc (anint.int[i]);

  writeln('Scan object file');
  for i := 1 to ob.top do if not ob.free[i] then begin
    getobj(i);
    freeobj;
    with obj do begin
      alloc (-linedesc);
      alloc (homedesc);
      alloc (examine);
      alloc (getfail);
      alloc (getsuccess); 
      alloc (usefail);
      alloc (usesuccess);
      alloc (d1);
      alloc (d2);
    end
  end;
  
  writeln ('Scan room file');
  for i := 1 to ro.top do if not ro.free[i] then begin
    getroom(i);
    freeroom;
    with here do begin
      for j := 1 to maxexit do with exits[j] do begin
        alloc(-exitdesc);
        { alloc(-closed); This isn't use yet }
        alloc(fail);
        alloc(success); 
        alloc(goin);
        alloc(comeout);     
        alloc(hidden);      { is this in use ? }
      end;                                    
      for j := 1 to maxdetail do alloc(here.detaildesc[j]);
      alloc(primary);
      alloc(secondary);
      alloc(-objdesc);  
      alloc(-objdest);
      alloc(-rndmsg);                       
      alloc(xmsg2);
      alloc(exitfail);
      alloc(ofail);
    end
  end;               

  writeln('Scan global codes');
  getglobal;
  freeglobal;
  for i := 1 to GF_MAX do if GF_Types[i] = G_Text then alloc(global.int[i]);
 
  locate(indexfile,I_LINE);
  indexfile^ := ln;
  put(indexfile);

  locate(indexfile,I_BLOCK);
  indexfile^ := bl;
  put(indexfile);
  
  writeln ('Ready.');
end;

procedure fix_clear_privileges (batch: boolean);
var i,mm: integer;
begin
  if fix_sure('Do you want clear privileges database ? ',batch) then begin
     if not exact_user(mm,MM_userid) then mm := 0;
     int_in_use(N_PRIVILEGES);
     getint(N_PRIVILEGES);
     for i := 1 to maxplayers do anint.int[i] := 0;
     if mm > 0 then anint.int[mm] := all_privileges; 
	{ more privilege for Monster Manager }
     putint;
     writeln ('Ready.');
  end;
end; { fix_clear_privileges }

procedure fix_clear_experience (batch: boolean);
var i,mm: integer;
begin
  if fix_sure('Do you want clear experience database ? ',batch) then begin
     if not exact_user(mm,MM_userid) then mm := 0;
     int_in_use(N_EXPERIENCE);
     getint(N_EXPERIENCE);
     for i := 1 to maxplayers do anint.int[i] := 0;
     if mm > 0 then anint.int[mm] := MaxInt; 
        { Monster Manager is Archwizard }
     putint;
     writeln ('Ready.');
  end;
end; { fix_clear_privileges }

procedure fix_clear_health (batch: boolean);
var i: integer;
    exp: intrec;
begin
  if fix_sure('Do you want clear health database ? ',batch) then begin
     getint(N_EXPERIENCE);
     freeint;
     exp := anint;
     int_in_use(N_HEALTH);
     getint(N_HEALTH);
     for i := 1 to maxplayers do anint.int[i] := 
         leveltable[level(exp.int[i])].health * goodhealth div 10;
     putint;
     writeln ('Ready.');
  end;
end; { fix_clear_health }


procedure fix_clear_password (batch: boolean);
var password: shortstring;
    i: integer;
begin
     if fix_sure('Want you really clear password database ? ',batch) then begin

        writeln('Intializing password record...');
        locate(namfile,T_PASSWD);
        namfile^.validate := T_PASSWD;
        namfile^.loctop := 0;
        for i := 1 to maxroom do namfile^.idents[i] := '';
	put(namfile);

        writeln('Initializing real name record ...');
        locate(namfile,T_REAL_USER);
        namfile^.validate := T_REAL_USER;
        namfile^.loctop := 0;
        for i := 1 to maxroom do namfile^.idents[i] := '';
	put(namfile);

	getuser;
	freeuser;

	writeln ('Making pseudo passowords... (same as virtual userid)');
        for i := 1 to maxplayers do begin
            password := user.idents[i];
            if password > '' then if password[1] = '"' then begin
               encrypt(password,i);
               getpasswd;
               passwd.idents[i] := password;
               putpasswd;
               getreal_user;
               real_user.idents[i] := '';
               putreal_user;
            end;
        end;
        writeln ('Ready.');
     end
end; { fix_clear_password }

procedure fix_clear_quotas(batch: boolean);
var numrooms,allow,accept: intrec;
    room,exit,player,acp,i: integer; 
    roomindx: indexrec;
begin
    writeln('Scanning rooms....');
    for i := 1 to maxplayers do numrooms.int[i] := 0;
    numrooms.intnum := N_NUMROOMS;
    for i := 1 to maxplayers do allow.int[i] := default_allow;
    allow.intnum := N_ALLOW;
    for i := 1 to maxplayers do accept.int[i] := 0;
    accept.intnum := N_ACCEPT;
    getindex(I_ROOM);
    freeindex;
    roomindx := indx;
    for room := 1 to roomindx.top do if not roomindx.free[room] then begin
	gethere(room);
	if exact_user(player,here.owner) then begin
	    acp := 0;
	    for exit := 1 to maxexit do 
		if here.exits[exit].kind = 5 then acp := acp +1;
	    numrooms.int[player] := numrooms.int[player] +1;
	    accept.int[player] := accept.int[player]     +acp;
	end;
    end;
    writeln('Clearing quota database and writing results to it...');
    int_in_use(N_NUMROOMS);
    int_in_use(N_ALLOW);
    int_in_use(N_ACCEPT);

    getint(N_NUMROOMS);
    anint := numrooms;
    putint;

    getint(N_ALLOW);
    anint := allow;
    putint;

    getint(N_ACCEPT);
    anint := accept;
    putint;

    writeln('OK.');
end;


procedure fix_repair_location(batch: boolean);
var id,loc,slot,code,room,true_loc,found_counter: integer;
    ex_indx,sleep_indx,room_indx,header_indx: indexrec;
    locs: intrec;
    temp: namrec;
    c: char;
    del_it: boolean;
begin
    writeln('Scanning monsters...');
    getpers;
    freepers;
    getuser;
    freeuser;
    getindex(I_PLAYER);
    freeindex;
    ex_indx := indx;
    getindex(I_ASLEEP);
    freeindex;
    sleep_indx := indx;
    getindex(I_ROOM);
    freeindex;
    room_indx := indx;
    getindex(I_HEADER);
    freeindex;
    header_indx := indx;
    getint(N_LOCATION);
    freeint;
    locs := anint;
    for id := 1 to ex_indx.top do if not ex_indx.free[id] then begin
	if user.idents[id] = '' then begin
	    writeln('Bad player username record #',id:1);
	    writeln('    player name: ',pers.idents[id]);
	end else if user.idents[id][1] = ':' then begin 
	    del_it := false;

	    readv(user.idents[id],c,code,error := continue); 
	    if statusv <> 0 then begin
		writeln('Bad monster username record #',id:1);
		writeln('    player name: ',pers.idents[id]);
		writeln('    user name:   ',user.idents[id]);
		del_it := true;
		code := 0;
	    end else begin
		found_counter := 0;
		true_loc := 0;
		loc := locs.int[id];

		for room := 1 to room_indx.top do if not room_indx.free[room] 
		    then begin
		    getroom(room); { locking }
		    for slot := 1 to maxpeople do begin
			if (here.people[slot].parm = code) and 
			    (here.people[slot].kind = P_MONSTER) then begin
			    found_counter := found_counter +1;
			    true_loc := room;
			    if here.people[slot].username <> 
				user.idents[id] then begin 
				writeln(pers.idents[id],
				    ': Bad username field in room ',
				    here.nicename,
				    ' (slot #',slot:1,') - fixed.');
				here.people[slot].username := user.idents[id];
			    end; { if }
			end; { if }
		    end; { slot }
		    putroom;       { storing }
		end; { room -loop }
		if (found_counter = 1) and (true_loc = loc) then
		    writeln(pers.idents[id],': ok')
		else if found_counter = 0 then begin
		    writeln(pers.idents[id],': not found from any room.');
		    del_it := true;
		end else if (found_counter = 1) and ( loc <> true_loc) then begin
		    writeln(pers.idents[id],': found from wrong location - updated.');
		    locs.int[id] := true_loc;
		end else if (found_counter > 1) then begin
		    writeln(pers.idents[id],': duplicated monster - deleted.');
		end else writeln('%',pers.idents[id],': bad software error !!');
	    end; { if statusv <> 0 (parsing monster username) }
	    if del_it and (code = 0) then 
		writeln(pers.idents[id],'% can''t delete it !')
	    else if del_it then begin 
		writeln(pers.idents[id],'% deleting.');
		for room := 1 to room_indx.top do 
		    if not room_indx.free[room] then begin
		    getroom(room); { locking }
		    for slot := 1 to maxpeople do begin
			if (here.people[slot].parm = code) and 
			(here.people[slot].kind = P_MONSTER) then begin
			    here.people[slot].username := '';
			    here.people[slot].kind     := 0;
			    here.people[slot].parm     := 0;
			    writeln(pers.idents[id],
				'% deleted from room ',here.nicename,
				' (slot #',slot:1,')');
			end; { if }
		    end; { for slot }
		    putroom;	    { unlocking }
		end; { end of room loop }
		if not header_indx.free[code] then begin
		    header_indx.free[code] := true;
		    header_indx.inuse := sleep_indx.inuse - 1; 
		    delete_program(code);
		    writeln(pers.idents[id],'% MDL code #',code:1,' deleted.');
		end else
		    writeln(pers.idents[id],
			'% MDL code #',code:1,' was already deleted !');

		ex_indx.free[id] := true;
		ex_indx.inuse := ex_indx.inuse - 1;
		if not sleep_indx.free[id] then begin
		    sleep_indx.free[id] := true;
		    sleep_indx.inuse := sleep_indx.inuse - 1; 
			{ onkohan tarpeelista ? }
		end;
		pers.idents[id] := '';
		user.idents[id] := '';
		getint(N_SELF);		{ destroy self description }
		delete_block(anint.int[id]);
		putint;
	    end; { del_it }
	end; { if user.idents[id] }
    end; { for id }
    writeln('Updating database...');

    temp := pers;
    getpers;
    pers := temp;
    putpers;
    
    temp := user;
    getuser;
    user := temp;
    putuser;
    
    getindex(I_PLAYER);
    indx := ex_indx;
    putindex;
    getindex(I_ASLEEP);
    indx := sleep_indx;
    putindex;
    getindex(I_ROOM);
    indx := room_indx;
    putindex;
    getindex(I_HEADER);
    indx := header_indx;
    freeindex;
    getint(N_LOCATION);
    anint := locs;
    putint;
    writeln('Ready.');
end; { fix_repair_location }

procedure fix_calculate_existence(batch: boolean);
var table: array [1 .. maxroom ] of integer;
    i,room,slot,object,old_value,pslot,inv: integer;
begin
    writeln ('Calculate objects'' number in existence');
    for i := 1 to maxroom do table[i] := 0;
    getindex(I_ROOM);
    freeindex;
    writeln ('Scan room file');
    for room := 1 to indx.top do if not indx.free[room] then begin
	gethere (room);
	for slot := 1 to maxobjs do begin
	    i := here.objs[slot];
	    if (i < 0) or (i > maxroom) then
		writeln('Invalid object #',i:1,' entry #',slot:1,
		    ' at room ',here.nicename)
	    else if i > 0 then table[i] := table[i] +1;
	end;
	for pslot := 1 to maxpeople do begin
	    if here.people[pslot].kind > 0 then begin
		for inv := 1 to maxhold do begin
		    i := here.people[pslot].holding[inv];
		    if (i < 0) or (i > maxroom) then
			writeln('Invalid object #',i:1,' entry #',inv:1,
			    ' at monster ',here.people[pslot].name)
		    else if i > 0 then table[i] := table[i] +1;
		end;
	    end;
	end;
    end;
    writeln('Write result to object file');
    getindex(I_OBJECT);
    freeindex;
    for object := 1 to maxroom do begin
	if (object > indx.top) or indx.free[object] then begin
	    if table[object] > 0 then begin
		writeln('Object #',object:1,' not exist but here is');
		writeln('  ',table[object],' entries in room file.');
	    end;
	end else begin
	    getobj(object);
	    old_value := obj.numexist;
	    obj.numexist := table[object];
	    putobj;
	    if old_value <> table[object] then 
		writeln(obj.oname,' fixed: ',old_value:1,' -> ',
		table[object]:1);
	end;
    end;
    writeln ('Ready.');
end;	{ fix_calculate_existence }


procedure fix_repair_paths(batch: boolean);
var room,exit,room_to,second_exit,exit2: integer;

    procedure delete_exit(room,exit: integer);
    begin
	getroom(room);
	writeln('  Removing exit from ',here.nicename,
	    ' to ',direct[exit],'.');
	here.exits[exit].kind  := 0;
	here.exits[exit].toloc := 0;
	here.exits[exit].slot  := 0;
	putroom;
    end; { delete_exit }
	
begin
    writeln('Repairing paths...');
    
    getindex(I_ROOM);
    freeindex;
    for room := 1 to indx.top do if not indx.free[room] then begin
	for exit := 1 to maxexit do begin

	    gethere(room);	{ reread here }
	    if not (here.exits[exit].kind in [0,5]) then begin
		room_to := here.exits[exit].toloc;
		second_exit := here.exits[exit].slot;

		if (second_exit < 0) or (second_exit > maxexit) then begin
		    writeln('Exit from ',here.nicename,' to ',direct[exit],
			' is bad: target slot is out of range');
		    delete_exit(room,exit);
		
		end else if room_to = 0 then begin
		    writeln('Exit from ',here.nicename,' to ',direct[exit],
			' is nowhere.');

		end else if (room_to < 1) or (room_to > indx.top) then begin
		    writeln('Exit from ',here.nicename,' to ',direct[exit],
			' is bad: target room is out of range.');
		    delete_exit(room,exit);

		end else if indx.free[room_to] then begin
		    writeln('Exit from ',here.nicename,' to ',direct[exit],
			' is bad: target room isn''t in use');
		    delete_exit(room,exit);

		end else begin
		    if room = room_to then
			writeln('Exit from ',here.nicename,' to ',direct[exit],
			    ' is loop.');
		    if second_exit = 0 then begin
			writeln('Exit from ',here.nicename,' to ',direct[exit],
			    ' is bad: no target slot');
			delete_exit(room,exit);
		    end else begin
			gethere(room_to);
			if (here.exits[second_exit].toloc <> room) or
			   (here.exits[second_exit].slot <> exit) then begin
			    writeln('Exits from ',here.nicename,' to ',
				direct[second_exit],
				' and');
			    gethere(room);
			    writeln(' from ',here.nicename,' to ',direct[exit],
				' are bad: bad link');
			    delete_exit(room,exit);
			end;
		    end;
		end;
	    end else if here.exits[exit].toloc <> 0 then begin
		writeln('Exit from ',here.nicename,' to ',direct[exit],
		    ' isn''t exit.');
	    end; 
	end;	{ exit }
    end;    { room }
    writeln ('Ready.');
end;

{ fix_view_global_flags moved to DATABASE.PAS }

[global]
function fix
	(batch: string := ''):  { in this procedure you not have logged in }
				{ system ! }
	boolean;
var s: string;
    done: boolean;
    batch_mode: boolean;
begin            	
   done := batch > '';
   fix := true;
   repeat
      if batch > '' then begin
	    s := batch;
	    { writeln('Batch mode: ',s); }
	    batch_mode := true;
      end else begin
	    write ('fix> '); readln (s); writeln;
	    batch_mode := false;
      end;
      s := lowcase(s);
      if s = '' then writeln ('Enter h for help.')
      else case s[1] of  
	'a'	: fix_clear_privileges	    (batch_mode);
	'b'	: fix_clear_health	    (batch_mode);
        'c'	: fix_initialize_event	    (batch_mode);
        'd'     : fix_descriptions	    (batch_mode);
        'f'     : fix_clear_experience	    (batch_mode);
	'g'	: 
	begin
		if s = 'g' then		fix_calculate_existence	(batch_mode)
		else if s = 'gl' then	fix_clear_global	(batch_mode)
		else if s = 'gs' then	set_global_flag(GF_ACTIVE,FALSE)
		else if s = 'gu' then   set_global_flag(GF_ACTIVE,TRUE)
		else if s = 'g-' then	set_global_flag(GF_VALID,FALSE)
		else if s = 'g+' then   set_global_flag(GF_VALID,TRUE)
		else if s = 'gv' then   fix_view_global_flags
		else writeln ('Enter ? for help.');
	end;
        'i'     : fix_repair_index	    (batch_mode);
	'j'	: fix_repair_paths	    (batch_mode);
	'k'	: fix_codes		    (batch_mode);
	'l'	: fix_repair_location	    (batch_mode);
        'm'     : fix_clear_monster	    (batch_mode);
	'n'	: fix_clear_quotas	    (batch_mode);
        'o'     : 
	begin
	    if s = 'o' then fix_clear_object(batch_mode)
	    else if s = 'ow' then fix_owner (batch_mode)
	    else writeln('Enter ? for help.');
	end;
        'p'     : fix_clear_player	    (batch_mode);
        'r'     : fix_clear_room	    (batch_mode);
        's'     : 
	begin
	    if s = 's' then fix_clear_password	    (batch_mode)
	    else if s = 'sp' then fix_clear_spell   (batch_mode)
	    else writeln('Enter ? for help.');
	end;
        'v'     : system_view;
        'h','?' : fix_help;
        'e'     : done := true;
        'q'     : begin
			fix := false;
			done := true;
		end;
        otherwise writeln ('Use ? for help');
      end; { case }
   until done
end;

function batch (file_name: string): boolean;
var line: string;
    pos,errorcode: integer;
    batch_file: text;
    quit: boolean;
begin
    batch := true;
    open(batch_file,file_name,history := readonly, error := continue);
    quit := false;
    errorcode := status(batch_file);
    if errorcode <> 0 then begin
	case errorcode of
	    -1: { PAS$K_EOF } writeln('Batch file is empty.');
	    3:  { PAS$K_FILNOTFOU } writeln('Batch file not foud.');
	    4:  { PAS$K_INVFILSYN } writeln('Illegal name of batch file.');
	    otherwise writeln('Can''t open batch file, error code (status): ',
		errorcode:1);
	end; { case }
	quit := true;
    end else begin
	reset(batch_file);
	while not quit and not eof(batch_file) do begin
	    readln(batch_file,line);
	    writeln(line);
	    if line > '' then begin
		pos := index(line,'!');
		if pos > 0 then line := substr(line,1,pos-1);
	    end;
	    if line > '' then quit := not fix (line);
	end;
    end;
    batch  := not quit;
end; { batch }

BEGIN
    Get_Environment;

    if not lookup_class(system_id,'system') then
	writeln('%error in main program: system');
    if not lookup_class(public_id,'public') then
	writeln('%error in main program: public');
    if not lookup_class(disowned_id,'disowned') then
	writeln('%error in main program: disowned');

    rebuild_system := false;
    fix_system := false;

    Setup_Guts;
    userid := lowcase(get_userid);
    wizard := userid = MM_userid;
    Params;

    if open_database(false) then begin

	if rebuild_system then rebuild;

	if batch_system then batch(name);

	if fix_system then fix;

	close_database;
    end else writeln ('Can''t open database. Maybe someone is playing Monster.');

    Finish_Guts;
END.

