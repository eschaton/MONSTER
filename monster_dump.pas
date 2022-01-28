[ INHERIT('database', 'guts', 'global' , 'privusers', 'parser')]
PROGRAM MONSTER_DUMP (INPUT, OUTPUT) ;
 
{
PROGRAM DESCRIPTION: 
 
    Image for MONSTER/DUMP and MONSTER/BUILD -command
 
AUTHORS: 
 
    Kari Hurtta
 
CREATION DATE:	9.2.1991
 
 
	    C H A N G E   L O G
 
     Date     |   Name  | Description
--------------+---------+-------------------------------------------------------
   10.02.1991 |         | Some fixing (spelcially to *_PLAYER routines)
   12.02.1991 |         | Added /OUTPUT -qualifier and fixed OBJDROP%
   13.02.1991 |         | read_EXIT : optional exitrec.closed moved 
   13.02.1991 |         | fixed OBJDROP% again!
   19.05.1992 |         | while loop bug fixed in read ROOM and read_ROOM2
              |         | V 1.01    BOOKSPELL%   HIDDEN% was wrong !!
	      |         | obj.numexist bug fixed in read_MONSTER
   28.05.1992 |		| V 1.02    write going field also for exit
}

CONST VERSION = '1.02'; { DUMPER Version }
			{ version numbers MUST be dictionary order !!! }
			{ ie. '1.00' < '1.01' }

var READ_vers_101: boolean;
    READ_vers_102: boolean;
 
{ DUMMY for linker }
[global]
function player_here(id: integer; var slot: integer): boolean;
begin
    player_here := false;
end;

{ DUMMY for linker }
[global]
procedure gethere(n: integer := 0);
begin
end;

{ DUMMY for linker }
[global]
procedure checkevents(silent: boolean := false);
begin
end;

{ ---------- }

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
	userid		: [external] veryshortstring;
	wizard		: [external] boolean;


function cli$get_value (%descr entity_desc: string;
			%descr retdesc: string;
			%ref retlength: word_unsigned): cond_value;
	external;

function cli$present (%descr entity_desc: string): cond_value;
	external;


var dump_file : string := '';
    build_system : boolean := false;
    dump_system  : boolean := false;

procedure params;

var
	qualifier,
	value,
	s		: string;
	value_length	: word_unsigned;
	status1,
	status2		: cond_value;

begin
	qualifier := 'DUMP_FILE';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
	    status2 := cli$get_value (qualifier, value, value_length);
	    if status2 = ss$_normal then begin
		dump_file := value;
	    end else begin
		writeln ('Something is wrong with /DUMP_FILE.');
		dump_file := '';
	    end;
	end else dump_file := '';

	qualifier := 'BUILD';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
		if wizard then begin
			if REBUILD_OK then begin
				writeln('Do you really want to destroy the entire universe?');
				readln(s);
				if length(s) > 0 then
					if substr(lowcase(s),1,1) = 'y' then
						build_system := true;
			end else
				writeln('/BUILD is disabled.');
		end else
			writeln ('Only the Monster Manager may /BUILD.');
	end;

	qualifier := 'DUMP';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
	    if wizard then begin
		dump_system := true;
	    end else
		writeln ('Only the Monster Manager may /DUMP.');
	end;

	qualifier := 'VERSION';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
		{ Don't take this out please... }
	  	writeln('Monster dumper, written  by Kari Hurtta  at University of Helsinki,  1991-1992');
                writeln('Version: ',VERSION);
		writeln;
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
end;

{ --------------- }

{ ITEM }

procedure write_ITEM(var f: TEXT; header,data : string);
begin
    writeln(f,header+data);
end; { write_ITEM }

function read_ITEM(var f: TEXT; header: string; var data : string): boolean;
var readed : [static] boolean := false;
    line   : [static] string := '';
begin
    if not readed and not eof(f) then begin
	readln(f,line);
	readed := true;
    end;
    if not readed then read_ITEM := false
    else if index(line,header) = 1 then begin
	data := substr(line,1+length(header),length(line)-length(header));
	readed := false;
	read_ITEM := true;
    end else read_ITEM := false;
end; { read_ITEM }

{ DESCLINE }

procedure write_DESCLINE(var f: text; linenum: integer);
var error: boolean;
begin

    if linenum = DEFAULT_LINE then 
	write_ITEM(f,'DEFAULT*DESCLINE','!')
    else if linenum = 0 then 
	write_ITEM(f,'NULL*DESCLINE','!')
    else begin
	getindex (I_LINE); freeindex;
	error := false;
	if (linenum < 0) or (linenum > indx.top) then error := true
	else if indx.free[linenum] then error := true;

	if not error then begin
	    getline(linenum);
	    write_ITEM(f,'DESCLINE%',oneliner.theline);
	    freeline;
	end else begin
	    writeln('Nonexisted description line #',linenum:1);
	    write_ITEM(f,'DEFAULT*DESCLINE','!')
	end;
    end;
end; { write_DESCLINE }

function read_DESCLINE(var f: text; var linenum: integer): boolean;
var data: string;
begin
    if read_ITEM(f,'DEFAULT*DESCLINE',data) then begin
	linenum := DEFAULT_LINE;
	read_DESCLINE := true;
    end else if read_ITEM(f,'NULL*DESCLINE',data) then begin
	linenum := 0;
	read_DESCLINE := true;
    end else if read_ITEM(f,'DESCLINE%',data) then begin
	if alloc_general(I_LINE,linenum) then begin
	    getline(linenum);
	    oneliner.theline := data;
	    putline;
	    read_DESCLINE := true;
	end else read_DESCLINE := false;
    end else read_DESCLINE := false;
end; { read_DESCLINE }

{ BLOCK }

procedure write_BLOCK(var f: text; code: integer);
var i : integer;
    error: boolean;
begin
    if code < 0 then write_DESCLINE(f,-code)
    else if code = DEFAULT_LINE then 
	write_ITEM(f,'DEFAULT*BLOCK','!')
    else if code = 0 then 
	write_ITEM(f,'NULL*BLOCK','!')
    else begin
	getindex (I_BLOCK); freeindex;
	error := false;
	if (code < 0) or (code > indx.top) then error := true
	else if indx.free[code] then error := true;

	if not error then begin
	    getblock(code);
	    write_ITEM(f,'START*BLOCK','!');
	    for i := 1 to block.desclen do 
		write_ITEM(f,'BLOCK%',block.lines[i]);
	    freeblock;
	end else begin
	    writeln('Nonexisted block desciption #',code:1);
	    write_ITEM(f,'NULL*BLOCK','!')
	end;
    end;
end; { write_BLOCK }

function read_BLOCK(var f: text; var code: integer): boolean;
var data: string;
begin
    if read_DESCLINE(f,code) then begin
	code := -code;
	read_BLOCK := true;
    end else if read_ITEM(f,'DEFAULT*BLOCK',data) then begin
	code := DEFAULT_LINE;
	read_BLOCK := true;
    end else if read_ITEM(f,'NULL*BLOCK',data) then begin
	code := 0;
	read_BLOCK := true;
    end else if read_ITEM(f,'START*BLOCK',data) then begin
	if alloc_general(I_block,code) then begin
	    getblock(code);
	    block.desclen := 0;
	    while read_ITEM(f,'BLOCK%',data) do begin
		block.desclen := block.desclen +1;
		block.lines[block.desclen] := data;
	    end;
	    putblock;
	    read_BLOCK := true;
	end else read_BLOCK := false;
    end else read_BLOCK := false;
end; { read_BLOCK }

{ MEGA }

procedure write_MEGA(var f: text; mega: mega_string);
var len, i, cut: integer;
begin
    if mega = '' then write_ITEM(f,'NULL*MEGA','!')
    else if length(mega) < string_len - 10 then
	write_ITEM(f,'SHORTMEGA%',mega)
    else begin
	write_ITEM(f,'START*MEGA','!');
	i := 1;
	len := length(mega);
	repeat
	    if i + string_len - 10 <= len then cut := string_len - 10
	    else cut := len - i +1;
	    if cut > 0 then write_ITEM(f,'MEGA%',substr(mega,i,cut));
	    i := i + cut;
	until cut = 0;
    end;
end; { write_MEGA }

function read_MEGA(var f: text; var mega: mega_string): boolean;
var data: string;
begin
    mega := '';
    if read_ITEM(f,'NULL*MEGA',data) then read_MEGA := true
    else if read_ITEM(f,'SHORTMEGA%',data) then begin
	mega := data;
	read_MEGA := true;
    end else if not read_ITEM(f,'START*MEGA',data) then read_MEGA := false
    else begin
	mega := '';
	while read_ITEM(f,'MEGA%',data) do mega := mega + data;
	read_MEGA := true;
    end;
end; { read_MEGA }

{ INTEGER }

procedure write_INTEGER(var f: text; header: string; code: integer);
var data: string;
begin
  writev(data,code:1);
  write_ITEM(f,header,data);
end;

function read_INTEGER(var f: text; header: string; var code: integer): BOOLEAN;
var data: string;
begin
    if read_ITEM(f,header,data) then begin
	readv(data,code);
	read_INTEGER := true;
    end else read_INTEGER := false;
end;

{ BINARY }

procedure write_BINARY(var f: TEXT; header,data : string);
var i: integer;
begin
    write_INTEGER(f,header,length(data));
    for i:= 1 to length(data) do
	write_INTEGER(f,'BIN%',ord(data[i]));
end;

function read_BINARY(var f: TEXT; header: string; var data: string): boolean;
var i,len,c: integer;
    flag: boolean;
begin
    if not read_INTEGER(f,header,len) then
	read_BINARY := false
    else begin
	flag := true;
	data := '';
	for i := 1 to len do begin
	    if not read_INTEGER(f,'BIN%',c) then flag := false;
	    data := data + chr(c);
	end;
	if not flag then writeln('Error in reading binary string.');
	read_BINARY := true;
    end;
end;

{ BOOLEAN }

procedure write_BOOLEAN(var f: text; header: string; code: boolean);
var data: string;
begin
  writev(data,code:1);
  write_ITEM(f,header,data);
end;

function read_BOOLEAN(var f: text; header: string; var code: boolean): BOOLEAN;
var data: string;
begin
    if read_ITEM(f,header,data) then begin
	readv(data,code);
	read_BOOLEAN := true;
    end else read_BOOLEAN := false;
end;

{ NAME }

procedure write_NAME(var f: text; header: string; class: integer; name: integer);
var rec: namrec;
begin
    if name = 0 then write_ITEM(f,header,'%%NULL%%')
    else begin
	get_namfile(class,rec);
	unlock(namfile);
	write_ITEM(f,header,rec.idents[name]);
    end
end; { write_NAME }

function read_NAME(var f: text; header: string; class,iclass: integer; 
    var name: integer): boolean;
var code,i: integer;
    data: string;
    rec: namrec;
begin
    if not read_ITEM(f,header,data) then read_NAME := false
    else begin
	if data = '%%NULL%%' then name := 0
	else if data = '' then begin
	    writeln('Empty name for class ',class:1,'/',iclass:1);
	    writeln(' Treated as null name.');
	    name := 0;
	end else begin
	    get_namfile(class,rec);
	    unlock(namfile);
	    getindex(iclass);
	    freeindex;
	    name := 0;
	    for i := 1 to indx.top do 
		if not indx.free[i] then
		    if rec.idents[i] = data then name := i;
	    if name = 0 then writeln('Reference error in class ',
		    class:1,'/',iclass:1, ' name ',data);
	end;
	read_NAME := true;
    end;
end;

function read_NEWNAME(var f: text; header: string; class,iclass: integer; 
    var name: integer): boolean;
var code,i: integer;
    data: string;
    rec: namrec;
begin
    if not read_ITEM(f,header,data) then read_NEWNAME := false
    else begin
	if data = '%%NULL%%' then name := 0
	else if data = '' then begin
	    writeln('Empty name for class ',class:1,'/',iclass:1);
	    writeln(' Treated as null name.');
	    name := 0;
	end else begin
	    get_namfile(class,rec);
	    getindex(iclass);
	   
	    name := 0;
	    for i := 1 to indx.top do 
		if indx.free[i] and (name = 0) then name := i;
	    { must to come same order as original so that 
		Great Hall, Void and Pit of Fire gets right number }

	    if name = 0 then writeln('Overflow error in class ',
		    class:1,'/',iclass:1, ' name ',data)
	    else begin
		indx.free[name] := false;
		indx.inuse := indx.inuse +1;
		rec.idents[name] := data;
	    end;
	    putindex;
	    put_namfile(class,rec);

	end;
	read_NEWNAME := true;
    end;
end;

{ MDL }

procedure write_MDL(var f: text; code: integer);
var i : integer;
    mdl: text;
    line: mega_string;
    error : boolean;
begin
   if code = 0 then write_ITEM(f,'NULL*MDL','!')
   else begin
	getindex (I_HEADER); freeindex;
	error := false;
	if (code < 0) or (code > indx.top) then error := true
	else if indx.free[code] then error := true;

	if not error then begin      
	    write_ITEM(f,'START*MDL','!');
	    open(mdl,file_name(code),old,RECORD_LENGTH := mega_length + 20);
	    reset(mdl);
	    while not eof(mdl) do begin
		readln(mdl,line);
		write_MEGA(f,line);
	    end;
	    close(mdl);
	    getheader(code);
	    freeheader;
	    write_BOOLEAN(f,'RUNNABLE%',header.runnable);
	    write_BOOLEAN(f,'PRIV%',header.priv);
	    write_ITEM(f,'OWNER%',header.owner);
	    write_ITEM(f,'CTIME%',header.ctime);
	    for i := 1 to statmax do if header.stats[i].lab <> '' then
	    begin
		write_ITEM(f,'STATLAB%',header.stats[i].lab);
		write_INTEGER(f,'RCOUNT%',header.stats[i].runcount);
		write_INTEGER(f,'ECOUNT%',header.stats[i].errorcount);
		write_ITEM(f,'LASTRUN%',header.stats[i].lastrun);
	    end;
	    write_ITEM(f,'AUTHOR%',header.author);
	    write_ITEM(f,'WTIME%',header.wtime);
	    write_MEGA(f,header.state);
	    write_INTEGER(f,'FLAGS%',header.flags);
	end else begin
	    writeln('Nonexisted MDL code #',code:1);
	    write_ITEM(f,'NULL*MDL','!')
	end;
   end;
end; { write_MDL }

function read_MDL(var f: text; var code: integer): boolean;
var data: string;
    flag: boolean;
    mdl: text;
    line: mega_string;
    i: integer;
begin
    if read_ITEM(f,'NULL*MDL',data) then begin
	code := 0;
	read_MDL := true;
    end else if not read_ITEM(f,'START*MDL',data) then read_mdl := false
    else begin
	getindex(I_HEADER);
	flag := true;
	code := 0;
	for i := 1 to indx.top do 
	    if indx.free[i] then code := i;

	if code = 0 then writeln('Overflow error in mdl store.')
	else begin
	    indx.free[code] := false;
	    indx.inuse := indx.inuse +1;
	    
	    getheader(code);

	    open(mdl,file_name(code),old,RECORD_LENGTH := mega_length + 20);
	    rewrite(mdl);
	    while read_MEGA(f,line) do writeln(mdl,line);
	    close(mdl);
	    if not read_BOOLEAN(f,'RUNNABLE%',header.runnable) then flag := false;
	    if not read_BOOLEAN(f,'PRIV%',header.priv) then flag := false;
	    header.interlocker := '';
	    if not read_ITEM(f,'OWNER%',data) then flag := false;
	    header.owner := data;
	    if not read_ITEM(f,'CTIME%',data) then flag := false;
	    header.ctime := data;
	    
	    for i := 1 to statmax do header.stats[i].lab := '';
	    i := 1;
	    while read_ITEM(f,'STATLAB%',data) do begin
		header.stats[i].lab := data;
		if not read_INTEGER(f,'RCOUNT%',header.stats[i].runcount) then flag := false;
		if not read_INTEGER(f,'ECOUNT%',header.stats[i].errorcount) then flag := false;
		if not read_ITEM(f,'LASTRUN%',data) then flag := false;
		header.stats[i].lastrun := data;
		i := i +1;
	    end;
	    if not read_ITEM(f,'AUTHOR%',data) then flag := false;
	    header.author := data;
	    if not read_ITEM(f,'WTIME%',data) then flag := false;
	    header.wtime := data;
	    header.running_id := '';
	    if not read_MEGA(f,header.state) then flag := false;
	    header.version := 1;
	    header.ex1 := '';
	    header.ex2 := '';
	    header.ex3 := '';
	    if not read_INTEGER(f,'FLAGS%',header.flags) then flag := false;
	    header.ex5 := 0;
	    header.ex6 := 0.0;
	    putheader;
	end;
	putindex;
	if not flag then writeln('Error in reading mdl code.');
	read_MDL := true;
    end;
end;

{ OBJECT }

procedure write_OBJECT(var f: text; object: integer);
begin
   if debug then writeln('Writing object #',object:1);
   write_NAME(f,'OBJECT%',T_OBJNAM,object); { write object name }

   getobjown; freeobjown;
   write_ITEM(f,'OWNER%',objown.idents[object]);

   getobj(object);
   freeobj;
   write_ITEM(f,'NAME%',obj.oname);  { duplicate name }
   write_INTEGER(f,'KIND%',obj.kind);
   write_DESCLINE(f,obj.linedesc);
   { *** home must write later }
   write_BLOCK(f,obj.homedesc);
   write_MDL(f,obj.actindx);
   write_BLOCK(f,obj.examine);
   write_INTEGER(f,'VALUE%',obj.worth);
   { don't write numexit }
   write_BOOLEAN(f,'STICKY%',obj.sticky);
   { *** getobjreq must write later }
   write_BLOCK(f,obj.getfail);
   write_BLOCK(f,obj.getsuccess);
   { *** useobjreq must write later }
   { *** uselogreq must write later }
   write_BLOCK(f,obj.usefail);
   write_BLOCK(f,obj.usesuccess);
   write_ITEM(f,'USEALIAS%',obj.usealias);
   write_BOOLEAN(f,'REQALIAS%',obj.reqalias);
   write_BOOLEAN(f,'REQVERB%',obj.reqverb);
   write_INTEGER(f,'PARTICLE%',obj.particle);
   case obj.kind of
	O_BOOK:
	    write_NAME(f,'BOOKSPELL%',T_SPELL_NAME,obj.parms[OP_SPELL]);
	otherwise ;
   end;

   write_BLOCK(f,obj.d1);
   write_BLOCK(f,obj.d2);
   write_INTEGER(f,'POWER%',obj.ap);
   write_INTEGER(f,'EXP%',obj.exreq);
   { *** exp5, exp6 not dumped }
end; { write_OBJECT }

function read_OBJECT(var f: text; var object: integer): boolean;
var id: integer;
    flag : boolean;
    s: string;
begin
   if not read_NEWNAME(f,'OBJECT%',T_OBJNAM,I_OBJECT,object) then read_OBJECT := false
   else if object = 0 then begin
      writeln('Object with empty/null name!');
      read_ITEM(f,'OWNER%',s);
      read_ITEM(f,'NAME%',s);
      writeln('  Name: ',s);
      read_INTEGER(f,'KIND%',id);
      read_DESCLINE(f,id);
      read_BLOCK(f,id);
      read_MDL(f,id);
      read_BLOCK(f,id);
      read_INTEGER(f,'VALUE%',id);
      read_BOOLEAN(f,'STICKY%',flag);
      read_BLOCK(f,id);
      read_BLOCK(f,id);
      read_BLOCK(f,id);
      read_BLOCK(f,id);
      read_ITEM(f,'USEALIAS%',s);
      read_BOOLEAN(f,'REQALIAS%',flag);
      read_BOOLEAN(f,'REQVERB%',flag);
      read_INTEGER(f,'PARTICLE%',id);
	{ one possible parms: }
	read_NAME(f,'BOOKSPELL%',T_SPELL_NAME,I_SPELL,id);
      read_BLOCK(f,id);
      read_BLOCK(f,id);
      read_INTEGER(f,'POWER%',id);
      read_INTEGER(f,'EXP%',id);

      read_OBJECT := true;
   end else begin
      getobjnam; freeobjnam;
      if debug then writeln('Reading object ',objnam.idents[object]);
      flag := true;

      getobjown;
      if not read_ITEM(f,'OWNER%',s) then flag := false;
      objown.idents[object] := s;
      putobjown;

      getobj(object);
      obj.onum := object; { !! }
      if not read_ITEM(f,'NAME%',s) then flag := false;
      obj.oname := s;
      if not read_INTEGER(f,'KIND%',obj.kind) then flag := false;
      if not read_DESCLINE(f,obj.linedesc) then flag := false;
      obj.home := 0;
      if not read_BLOCK(f,obj.homedesc) then flag := false;
      if not read_MDL(f,obj.actindx) then flag := false;
      if not read_BLOCK(f,obj.examine) then flag := false;
      if not read_INTEGER(f,'VALUE%',obj.worth) then flag := false;
      obj.numexist := 0;
      if not read_BOOLEAN(f,'STICKY%',obj.sticky) then flag := false;
      obj.getobjreq := 0;
      if not read_BLOCK(f,obj.getfail) then flag := false;
      if not read_BLOCK(f,obj.getsuccess) then flag := false;
      obj.useobjreq := 0;
      obj.uselocreq := 0;
      if not read_BLOCK(f,obj.usefail) then flag := false;
      if not read_BLOCK(f,obj.usesuccess) then flag := false;
      if not read_ITEM(f,'USEALIAS%',s) then flag := false;
      obj.usealias := s;
      if not read_BOOLEAN(f,'REQALIAS%',obj.reqalias) then flag := false;
      if not read_BOOLEAN(f,'REQVERB%',obj.reqverb) then flag := false;
      if not read_INTEGER(f,'PARTICLE%',obj.particle) then flag := false;
      for id := 1 to maxparm do obj.parms[id] := 0;
      case obj.kind of 
	    O_BOOK: if READ_vers_101 then { BOOKSPELL% was in version 1.01 !! }
		if not read_NAME(f,'BOOKSPELL%',T_SPELL_NAME,I_SPELL,
		    obj.parms[OP_SPELL]) then flag := false;
	    otherwise ;
      end;
      if not read_BLOCK(f,obj.d1) then flag := false;
      if not read_BLOCK(f,obj.d2) then flag := false;
      if not read_INTEGER(f,'POWER%',obj.ap) then flag := false;
      if not read_INTEGER(f,'EXP%',obj.exreq) then flag := false;
      putobj;
      if not flag then writeln('Error in reading object ',
	objnam.idents[object]);
      read_OBJECT := true;
   end;
end; { read_OBJECT }

{ OBJECT2 }

procedure write_OBJECT2(var f: text; object: integer);
begin
   write_NAME(f,'OBJECT2%',T_OBJNAM,object); { write object name }
   getobj(object);
   freeobj;
   write_NAME(f,'HOME%',T_NAM,obj.home); { write room name }
   write_NAME(f,'GETOBJREQ%',T_OBJNAM,obj.getobjreq); { write object name }
   write_NAME(f,'USEOBJREQ%',T_OBJNAM,obj.useobjreq); { write object name }
   write_NAME(f,'USELOC%',T_NAM,obj.uselocreq); { write room name }

   case obj.kind of
      O_BOOK: write_name(f,'SPELLREF%',T_SPELL_NAME,obj.parms[OP_SPELL]);
      otherwise ;
   end; { case }

end; { write_OBJECT2 }

function read_OBJECT2(var f: text; var object: integer): boolean;
var id: integer;
    flag : boolean;
    s: string;
begin
   if not read_NAME(f,'OBJECT2%',T_OBJNAM,I_OBJECT,object) then read_OBJECT2 := false
   else if object = 0 then begin
	writeln('Empty/null/unknown object name!');
      read_NAME(f,'HOME%',T_NAM,I_ROOM,id);
      read_NAME(f,'GETOBJREQ%',T_OBJNAM,I_OBJECT,id);
      read_NAME(f,'USEOBJREQ%',T_OBJNAM,I_OBJECT,id);
      read_NAME(f,'USELOC%',T_NAM,I_ROOM,id);
      read_NAME(f,'SPELLREF%',T_SPELL_NAME,I_SPELL,id);
      read_OBJECT2 := true;
   end else begin
      getobjnam; freeobjnam;
      if debug then writeln('Reading object ',objnam.idents[object]);
      flag := true;
      getobj(object);
      if not read_NAME(f,'HOME%',T_NAM,I_ROOM,obj.home) then flag := false; { room name }
      if not read_NAME(f,'GETOBJREQ%',T_OBJNAM,I_OBJECT,obj.getobjreq) then flag := false; { object name }
      if not read_NAME(f,'USEOBJREQ%',T_OBJNAM,I_OBJECT,obj.useobjreq) then flag := false; { object name }
      if not read_NAME(f,'USELOC%',T_NAM,I_ROOM,obj.uselocreq) then flag := false;

      case obj.kind of
	O_BOOK: begin
	    if not read_NAME(f,'SPELLREF%',T_SPELL_NAME,I_SPELL,obj.parms[OP_SPELL]) then flag := false;
	end;
	otherwise ;
      end; { case }

      putobj;
      if not flag then writeln('Error in reading object ',
	    objnam.idents[object]);
      read_OBJECT2 := true;
   end;
end; { read_OBJECT2 }

{ MONSTER }

procedure write_MONSTER(var f: text; rec: peoplerec);
var i: integer;
    c: char;
    id: integer;
    
begin
    write_INTEGER(f,'MONSTERKIND%',rec.kind);
    write_MDL(f,rec.parm);
    { don't write rec.username - it's :<rec.parm> }
    write_ITEM(f,'NAME%',rec.name);
    write_INTEGER(f,'HIDING%',rec.hiding);
    for i := 1 to maxhold do if rec.holding[i] <> 0 then
	write_NAME(f,'HOLD%',T_OBJNAM,rec.holding[i]); { write object name }
    write_NAME(f,'WEAR%',T_OBJNAM,rec.wearing); { write object name }
    write_NAME(f,'WIELD%',T_OBJNAM,rec.wielding); { write object name }
    { don't write self desc }
end; { write_MONSTER }

function read_MONSTER(var f: text; var rec: peoplerec): boolean;
var i,a,id: integer;
    flag : boolean;
    data: string;
begin
    if not read_INTEGER(f,'MONSTERKIND%',rec.kind) then read_MONSTER := false
    else begin
	getpers; freepers;
	flag := true;
	if not read_MDL(f,rec.parm) then flag := false;
	writev(rec.username,':',rec.parm:1); { username is MDL code number }

	if not read_ITEM(f,'NAME%',data) then flag := false;
	rec.name := data;
    	id := 0; { monster's number }
	getpers; freepers; getindex(I_PLAYER); freeindex;
	for i := 1 to indx.top do if not indx.free[i] then
	    if pers.idents[i] = data then id := i;
	if id = 0 then writeln('Monster''s name ',data,' not found.');

	getuser;
	if id > 0 then writev(user.idents[id],':',rec.parm:1); { update username }
	putuser;

	if not read_INTEGER(f,'HIDING%',rec.hiding) then flag := false;
	rec.act  := 0;
	rec.targ := 0;
	for i := 1 to maxhold do rec.holding[i] := 0;
	i := 1;
	while read_NAME(f,'HOLD%',T_OBJNAM,I_OBJECT,a) do begin
	    rec.holding[i] := a;

	    getobj(a);   
	    obj.numexist := obj.numexist + 1;   { Update counter }
	    putobj;


	    i := i +1;
	end;
	getint(N_EXPERIENCE); freeint;
	if id > 0 then rec.experience := anint.int[id];

	if not read_NAME(f,'WEAR%',T_OBJNAM,I_OBJECT,rec.wearing) then flag := false; { object name }
	if not read_NAME(f,'WIELD%',T_OBJNAM,I_OBJECT,rec.wielding) then flag := false; { object name }

	getint(N_HEALTH); freeint;
	if id > 0 then rec.health := anint.int[id];

	getint(N_SELF); freeint;
	if id > 0 then rec.self := anint.int[id];

	if not flag then writeln('Error in loading monster ',rec.name);
	read_MONSTER := true;
    end;
end; { read_MONSTER }

{ PLAYER }

procedure write_PLAYER(var f: text; player: integer);
var i,owner: integer;
    c: char;
begin
    getuser; freeuser; 
    if debug then writeln('Writing player ',user.idents[player]);
    write_NAME(f,'PLAYER%',T_PERS,player);

    if user.idents[player][1] = ':' then begin { monster ? }
	{ what we can write - real username is MDL number }
	{ read_MONSTER will be update this data when reading }
    end else write_ITEM(f,'USER%',user.idents[player]);

    getdate; freedate;
    write_ITEM(f,'DATE%',adate.idents[player]);

    gettime; freetime;
    write_ITEM(f,'TIME%',atime.idents[player]);

    getpasswd; freepasswd;
    if passwd.idents[player] > '' then
	write_BINARY(f,'PASSWD%',passwd.idents[player]);

    getreal_user; freereal_user;
    if real_user.idents[player] > '' then
	write_ITEM(f,'REAL%',real_user.idents[player]);

    { location must write later }
    { don't write numrooms }

    getint(N_ALLOW); freeint;
    write_INTEGER(f,'ALLOW%',anint.int[player]); 

    { don't write accept }

    getint(N_EXPERIENCE); freeint;
    write_INTEGER(f,'EXP%',anint.int[player]); 

    getint(N_SELF); freeint;
    write_BLOCK(f,anint.int[player]); 
    
    getint(N_PRIVILEGES); freeint;
    write_INTEGER(f,'PRIV%',anint.int[player]); 

    getint(N_HEALTH); freeint;
    write_INTEGER(f,'HEALTH%',anint.int[player]); 

    getint(N_LOCATION); freeint;
    write_NAME(f,'LOC%',T_NAM,anint.int[player]); 

    getspell(player); freespell;
    for i := 1 to maxspells do begin
	if spell.level[i] > 0 then begin
	    write_NAME(f,'SPELL%',T_SPELL_NAME,i);
	    write_INTEGER(f,'LEVEL%',spell.level[i]);
	end;
    end;

end; { write_PLAYER }

function read_PLAYER(var f: text; var name: integer): boolean;
var sp,i,owner: integer;
    flag: boolean;
    data: string;
begin
    if not read_NEWNAME(f,'PLAYER%',T_PERS,I_PLAYER,name) then read_PLAYER := false
    else if name = 0 then begin
	writeln('Empty/null player name!');
	read_ITEM(f,'USER%',data);
	read_ITEM(f,'DATE%',data);
	read_ITEM(f,'TIME%',data);
	read_BINARY(f,'PASSWD%',data);
	read_ITEM(f,'REAL%',data);
	read_INTEGER(f,'ALLOW%',i);
	read_INTEGER(f,'EXP%',i);
	read_BLOCK(f,i);
	read_INTEGER(f,'PRIV%',i);
	read_INTEGER(f,'HEALTH%',i);
	read_NAME(f,'LOC%',T_NAM,I_ROOM,i);
	while read_NAME(f,'SPELL%',T_SPELL_NAME,I_SPELL,i) do begin
	    read_INTEGER(f,'LEVEL%',i);
	end;
	read_PLAYER := true;
    end else begin

	getpers; freepers;
	if debug then writeln('Reading player ',pers.idents[name]);
	flag := true;

	getuser;
	if not read_ITEM(f,'USER%',data) then begin
	    { monster: username is :<MDL code number> }
	    { read_MONSTER update this later }
	    data := ':0';
	end;
	user.idents[name] := data;
	putuser;

	getdate;
	if not read_ITEM(f,'DATE%',data) then flag := false;
	adate.idents[name] := data;
	putdate;

	gettime;
	if not read_ITEM(f,'TIME%',data) then flag := false;
	atime.idents[name] := data;
	puttime;

	if read_BINARY(f,'PASSWD%',data) then begin
	    getpasswd;
	    passwd.idents[name] := data;
	    putpasswd;
	end;

	if read_ITEM(f,'REAL%',data) then begin
	    getreal_user;
	    real_user.idents[name] := data;
	    putreal_user;
	end;

	getint(N_ALLOW);
	if not read_INTEGER(f,'ALLOW%',anint.int[name]) then flag := false;
	putint;

	getint(N_EXPERIENCE);
	if not read_INTEGER(f,'EXP%',anint.int[name]) then flag := false;
	putint;

	getint(N_SELF);
	if not read_BLOCK(f,anint.int[name]) then flag := false;
	putint;

	getint(N_PRIVILEGES);
	if not read_INTEGER(f,'PRIV%',anint.int[name]) then flag := false;
	putint;

	getint(N_HEALTH);
	if not read_INTEGER(f,'HEALTH%',anint.int[name]) then flag := false;
	putint;

	getint(N_LOCATION);
	if not read_NAME(f,'LOC%',T_NAM,I_ROOM,anint.int[name]) then flag := false;
	putint;

                     { initialize the record containing the
                       level of each spell they have to start;
                       all start at zero; since the spellfile is
                       directly parallel with mylog, we can hack
                       init it here without dealing with SYSTEM }

                     locate(spellfile,name);
                     for i := 1 to maxspells do
                        spellfile^.level[i] := 0;
                     spellfile^.recnum := name;
                     put(spellfile);

	getspell(name);
	for sp := 1 to maxspells do spell.level[sp] := 0;
	while read_NAME(f,'SPELL%',T_SPELL_NAME,I_SPELL,sp) do begin
	    if not read_INTEGER(f,'LEVEL%',spell.level[sp]) then flag := false;
	end;
	putspell;

	if not flag then writeln('Error in reading player ',pers.idents[name]);
	read_PLAYER := true;
    end;
end; { read_PLAYER }

{ EXIT }

procedure write_EXIT(var f: text; from,slot: integer; exitrec: exit);
begin
    if debug then writeln('Writing exit #',from:1,'/',slot:1);
    write_NAME(f,'EXITFROM%',T_NAM,from);
    write_INTEGER(f,'SLOT%',slot);	    { must be same slot in }
					    { in BUILDed database }

    write_NAME(f,'TO%',T_NAM,exitrec.toloc);
    write_INTEGER(f,'KIND%',exitrec.kind);
    write_INTEGER(f,'TOSLOT%',exitrec.slot);

    write_DESCLINE(f,exitrec.exitdesc);
    write_BLOCK(f,exitrec.fail);
    write_BLOCK(f,exitrec.success);
    write_BLOCK(f,exitrec.goin);	{  new for dump version 1.02 }
    write_BLOCK(f,exitrec.comeout);

    
    { write_INTEGER(f,'HIDDEN%',exitrec.hidden); WRONG !! }
    write_BLOCK(f,exitrec.hidden);
    
    write_NAME(f,'OBJREQ%',T_OBJNAM,exitrec.objreq);
    write_ITEM(f,'ALIAS%',exitrec.alias);
    write_BOOLEAN(f,'REQVERB%',exitrec.reqverb);
    write_BOOLEAN(f,'REQALIAS%',exitrec.reqalias);
    write_BOOLEAN(f,'AUTOLOOK%',exitrec.autolook);
    { write_DESCLINE(f,exitrec.closed); not used yet ? }
end;

function read_EXIT(var f: text; var from,slot: integer;
	    var exitrec: exit): boolean;
var flag: boolean;
    data: string;
    tmp: integer;
begin
    if not read_NAME(f,'EXITFROM%',T_NAM,I_ROOM,from) then
	read_EXIT := false
    else begin
	flag := true;
	getnam; freenam;
	if not read_INTEGER(f,'SLOT%',slot) then flag := false;
	if debug and (from > 0) then writeln('Reading exit ',
	    nam.idents[from],'/',direct[slot]);
	
	if not read_NAME(f,'TO%',T_NAM,I_ROOM,exitrec.toloc) then flag := false;
	if not read_INTEGER(f,'KIND%',exitrec.kind) then flag := false;
	if not read_INTEGER(f,'TOSLOT%',exitrec.slot) then flag := false;

	if not read_DESCLINE(f,exitrec.exitdesc) then flag := false;
	if not read_BLOCK(f,exitrec.fail) then flag := false;
	if not read_BLOCK(f,exitrec.success) then flag := false;
	if READ_vers_102 then begin	    { new for version 1.02 }
	    if not read_BLOCK(f,exitrec.goin) then flag := false;
	end else begin
	    exitrec.goin := 0;	    { none }
	end;

	if not read_BLOCK(f,exitrec.comeout) then flag := false;

	if READ_vers_101 then begin	{ was wrong in version 1.00 !! }
	    if not read_BLOCK(f,exitrec.hidden) then flag := false;
	end else begin
	    if not read_INTEGER(f,'HIDDEN%',tmp) then flag := false;
	    if tmp <> 0 then writeln('Warning: Bad hidden field of exit in dump due bug in database version 1.00');
	    exitrec.hidden := 0;
	end;
	if not read_NAME(f,'OBJREQ%',T_OBJNAM,I_OBJECT,exitrec.objreq) then flag := false;

	if not read_ITEM(f,'ALIAS%',data) then flag := false;
	exitrec.alias := data;
	if not read_BOOLEAN(f,'REQVERB%',exitrec.reqverb) then flag := false;
	if not read_BOOLEAN(f,'REQALIAS%',exitrec.reqalias) then flag := false;
	if not read_BOOLEAN(f,'AUTOLOOK%',exitrec.autolook) then flag := false;
	if not read_DESCLINE(f,exitrec.closed) then 
	    exitrec.closed := 0; { not used yet }
	
	if not flag then begin
	    if (from > 0) then writeln('Error in loading exit ',
		nam.idents[from],'/',direct[slot])
	    else writeln('Error in loading exit #',from:1,'/',direct[slot]);
	end;
	read_EXIT := true;
    end;
end; 

{ SPELL }

procedure write_SPELL(var f: text; spell: integer);
begin
    if debug then writeln('Writing spell #',spell:1);
    write_NAME(f,'SPELL%',T_SPELL_NAME,spell);
    getint(N_SPELL); freeint;
    write_MDL(f,anint.int[spell]);
end;

function read_SPELL(var f: text; var spell: integer): boolean;
var flag: boolean;
    j: integer;
begin
    if not read_NEWNAME(f,'SPELL%',T_SPELL_NAME,I_SPELL,spell) then
	read_SPELL := false
    else if spell = 0 then begin
	writeln('Empty/null spell name!');
	read_MDL(f,j);
	read_SPELL := true;
    end else begin
	getspell_name;freespell_name;
	if debug then writeln('Reading spell ',spell_name.idents[spell]);
	flag := true;
	if not read_MDL(f,j) then flag := false;
	getint(N_SPELL);
	anint.int[spell] := j;
	putint;

	if not flag then writeln('Error in reading spell ',spell_name.idents[spell]);
	read_SPELL := true;
    end;
end;

{ ROOM }

procedure write_ROOM(var f: text; id: integer);
var i: integer;
begin
    getroom(id); freeroom;
    if debug then writeln('Writing room ',here.nicename);
    
    write_NAME(f,'ROOM%',T_NAM,id);
    { dont't write locnum }
    write_ITEM(f,'OWNER%',here.owner);
    write_ITEM(f,'NICENAME%',here.nicename);
    write_INTEGER(f,'NAMEPRINT%',here.nameprint);

    write_BLOCK(f,here.primary);
    write_BLOCK(f,here.secondary);
    write_INTEGER(f,'WHICH%',here.which);
    
    write_NAME(f,'MAGICOBJ%',T_OBJNAM,here.magicobj);
    { don't write effects }
    { don't write parm }
    
    { write exits later }

    { don't write pile }
    for i := 1 to maxobjs do if here.objs[i] > 0 then begin
	write_NAME(f,'OBJHERE%',T_OBJNAM,here.objs[i]);
	write_INTEGER(f,'OBJHIDE%',here.objhide[i]);
    end;

    { write objdrop later }

    write_DESCLINE(f,here.objdesc);
    write_DESCLINE(f,here.objdest);
    
    { write monsters later }
    
    { write grploc1 later }
    { write grploc2 later }
    write_ITEM(f,'GRPNAM1%',here.grpnam1);
    write_ITEM(f,'GRPNAM2%',here.grpnam2);

    for i := 1 to maxdetail do if here.detaildesc[i] <> 0 then begin
	write_ITEM(f,'DETAIL%',here.detail[i]);
	write_BLOCK(f,here.detaildesc[i]);
    end;

    write_INTEGER(f,'TRAPTO%',here.trapto); { exit numbers are same also
					      in BUILDed database }
    write_INTEGER(f,'TRAPCHANCE%',here.trapchance);
    write_DESCLINE(f,here.rndmsg);
    write_BLOCK(f,here.xmsg2);
    write_MDL(f,here.hook);
    { don't write exp3, exp4 }
    write_BLOCK(f,here.exitfail);   { is this in use ? }
    write_BLOCK(f,here.ofail);      { is this in use ? }
end;

function read_ROOM(var f: text; var id: integer): boolean;
var flag: boolean;
    data: string;
    i: integer;
    intdata: integer;
begin
    if not read_NEWNAME(f,'ROOM%',T_NAM,I_ROOM,id) then
	read_ROOM := false
    else if id = 0 then begin 
	writeln('Empty/null room name!');
	read_ITEM(f,'OWNER%',data);
	read_ITEM(f,'NICENAME%',data);
	writeln(' Name: ',data);
	read_INTEGER(f,'NAMEPRINT%',i);
	read_BLOCK(f,i);
	read_BLOCK(f,i);
	read_INTEGER(f,'WHICH%',i);
	read_NAME(f,'MAGICOBJ%',T_OBJNAM,I_OBJECT,i);
	while read_NAME(f,'OBJHERE%',T_OBJNAM,I_OBJECT,i) do begin
	    read_INTEGER(f,'OBJHIDE%',i);
	end;
	read_DESCLINE(f,here.objdesc);
	read_DESCLINE(f,i);
	read_ITEM(f,'GRPNAM1%',data);
	read_ITEM(f,'GRPNAM2%',data);
	while read_ITEM(f,'DETAIL%',data) do begin
    	    read_BLOCK(f,i);
	end;
	read_INTEGER(f,'TRAPTO%',i);
	read_INTEGER(f,'TRAPCHANCE%',i);
	read_DESCLINE(f,i);
	read_BLOCK(f,i);
	read_MDL(f,i);
	read_BLOCK(f,i);
	read_BLOCK(f,i);
	read_ROOM := true;
    end else begin
	getnam; freenam;
	if debug then writeln('Reading room ',nam.idents[id]);
	flag := true;
	getroom(id);
	if not read_ITEM(f,'OWNER%',data) then flag := false;
	here.owner := data;
	getown; 
	own.idents[id] := data;  { update owner }
	putown;
	if not read_ITEM(f,'NICENAME%',data) then flag := false;
	here.nicename := data;
	if not read_INTEGER(f,'NAMEPRINT%',here.nameprint) then flag := false;

	if not read_BLOCK(f,here.primary) then flag := false;
	if not read_BLOCK(f,here.secondary) then flag := false;
	if not read_INTEGER(f,'WHICH%',here.which) then flag := false;

	if not read_NAME(f,'MAGICOBJ%',T_OBJNAM,I_OBJECT,here.magicobj) then flag := false;

	for i := 1 to maxobjs do begin
	    here.objs[i] := 0;
	    here.objhide[i] := 0;
	end;
	i := 1;
	while read_NAME(f,'OBJHERE%',T_OBJNAM,I_OBJECT,intdata) do begin
	    here.objs[i] := intdata;
	    if not read_INTEGER(f,'OBJHIDE%',here.objhide[i]) then flag := false;

	    getobj(here.objs[i]);   
	    obj.numexist := obj.numexist + 1;   { Update counter }
	    putobj;

	    i := i+1;
	end;

	if not read_DESCLINE(f,here.objdesc) then flag := false;
	if not read_DESCLINE(f,here.objdest) then flag := false;
	
	for i := 1 to maxpeople do here.people[i].kind := 0;

	if not read_ITEM(f,'GRPNAM1%',data) then flag := false;
	here.grpnam1 := data;
	if not read_ITEM(f,'GRPNAM2%',data) then flag := false;
	here.grpnam2 := data;

	for i := 1 to maxdetail do begin
	    here.detaildesc[i] := 0;
	    here.detail[i] := '';
	end;

	i := 1;
	while read_ITEM(f,'DETAIL%',data) do begin
	    here.detail[i] := data;
	    if not read_BLOCK(f,here.detaildesc[i]) then flag := false;
	    i := i +1;
	end;

	if not read_INTEGER(f,'TRAPTO%',here.trapto) then flag := false;
	if not read_INTEGER(f,'TRAPCHANCE%',here.trapchance) then flag := false;
	if not read_DESCLINE(f,here.rndmsg) then flag := false;
	if not read_BLOCK(f,here.xmsg2) then flag := false;
	if not read_MDL(f,here.hook) then flag := false;
	if not read_BLOCK(f,here.exitfail) then flag := false;
	if not read_BLOCK(f,here.ofail) then flag := false;

	putroom;
	if not flag then writeln('Error in reading room ',here.nicename);
	read_ROOM := true;
    end;
end;

{ ROOM2 }

procedure write_ROOM2(var f: text; id: integer);
var i: integer;
begin
    getroom(id); freeroom;
    if debug then writeln('Writing room ',here.nicename);
    write_NAME(f,'ROOM2%',T_NAM,id);
    for i := 1 to maxexit do write_EXIT(f,id,i,here.exits[i]);
    write_NAME(f,'OBJDROP%',T_NAM,here.objdrop);
    write_NAME(f,'GRPLOC1%',T_NAM,here.grploc1);
    write_NAME(f,'GRPLOC2%',T_NAM,here.grploc2);

    for i := 1 to maxpeople do if here.people[i].kind = P_MONSTER then
	write_MONSTER(f,here.people[i]);

end; 

function read_ROOM2(var f: text; var id: integer): boolean;
var i,j,k: integer;
    flag : boolean;
    tmp: exit;
    tmp2: peoplerec;
    ownerid: integer;
begin
    if not read_NAME(f,'ROOM2%',T_NAM,I_ROOM,id) then
	read_ROOM2 := false
    else if id = 0 then begin
	writeln('Empty/null/unknown room name!');

	for i := 1 to maxexit do begin
	    read_EXIT(f,j,k,tmp);
	end;
	read_NAME(f,'OBJDROP%',T_NAM,I_ROOM,i);
	read_NAME(f,'GRPLOC1%',T_NAM,I_ROOM,i);
	read_NAME(f,'GRPLOC2%',T_NAM,I_ROOM,i);

	while read_MONSTER(f,tmp2) do;
	read_ROOM2 := true;
    end else begin
	getroom(id);
	if debug then writeln('Reading room ',here.nicename);
	flag := true;

	getuser; freeuser; getindex(I_PLAYER); freeindex;
	ownerid := 0;
	for i := 1 to indx.top do if not indx.free[i] then
	    if user.idents[i] = here.owner then ownerid := i;

	for i := 1 to maxexit do begin
	    if not read_EXIT(f,j,k,here.exits[i]) then flag := false;
	    if j <> id then flag := false;
	    if k <> i then flag := false;
	end;

	change_owner(0,ownerid); { update owner's counters }

	if not read_NAME(f,'OBJDROP%',T_NAM,I_ROOM,here.objdrop) then flag := false;
	if not read_NAME(f,'GRPLOC1%',T_NAM,I_ROOM,here.grploc1) then flag := false;
	if not read_NAME(f,'GRPLOC2%',T_NAM,I_ROOM,here.grploc2) then flag := false;

	i := 1;
	while read_MONSTER(f,tmp2) do begin
	    here.people[i] := tmp2;
	    i := i+1;
	end;
	
	putroom;
	if not flag then writeln('Error in reading room ',here.nicename);
	read_ROOM2 := true;
    end;
end;

{ GVAL }
procedure write_GVAL(var f: text; id: integer);
begin
    if debug then writeln('Writing global #',id);
    write_INTEGER(f,'GLOBAL%',id);
    getglobal; freeglobal;
    case GF_Types[id] of
	G_Flag: write_BOOLEAN(f,'GBOOL%',global.int[id] > 0);
	G_Int:  write_INTEGER(f,'GINT%',global.int[id]);
	G_Text: write_BLOCK(f,global.int[id]);
	G_Code: write_MDL(f,global.int[id]);
    end; { cases }
end;

function read_GVAL(var f: text; var id: integer): boolean;
var flag: boolean;
    tmp: boolean;
begin
    if not read_INTEGER(f,'GLOBAL%',id) then
	read_GVAL := false
    else begin
	if debug then writeln('Reading global #',id:1);
	getglobal;
	case Gf_Types[id] of
	    g_flag: begin
		flag := read_BOOLEAN(f,'GBOOL%',tmp);
		if tmp then global.int[id] := 1 else global.int[id] := 0;
	    end;
	    G_Int: flag := read_INTEGER(f,'GINT%',global.int[id]);
	    G_text: flag := read_BLOCK(f,global.int[id]);
	    G_Code: flag := read_MDL(f,global.int[id]);
	end { cases };
	putglobal;

	if not flag then writeln('Error in reading global #',id);
	read_GVAL := true;
    end;
end;

{ DATABASE }

procedure write_DATABASE(var f: text);
var block_use,
    line_use,
    room_use,
    object_use,
    header_use: integer;
    tmp: indexrec;
    i: integer;
begin
    writeln('Database writing to ',dump_file,' started.');
    write_ITEM(f,'DATABASE%',VERSION);
    write_ITEM(f,'BY%',userid);

    getindex(I_BLOCK); freeindex; block_use := indx.inuse;
    getindex(I_LINE); freeindex; line_use := indx.inuse;
    getindex(I_ROOM); freeindex; room_use := indx.inuse;
    getindex(I_OBJECT); freeindex; object_use := indx.inuse;
    getindex(I_HEADER); freeindex; header_use := indx.inuse;

    writeln('Block descriptions: ',block_use:3);
    writeln('Line descriptions:  ',line_use:3);
    writeln('Rooms:              ',room_use:3);
    writeln('Objects:            ',object_use:3);
    writeln('MDL codes:          ',header_use:3);

    write_INTEGER(f,'BLOCKCOUNT%',block_use);
    write_INTEGER(f,'LINECOUNT%',line_use);
    write_INTEGER(f,'ROOMCOUNT%',room_use);
    write_INTEGER(f,'OBJECTCOUNT%',object_use);
    write_INTEGER(f,'HEADERCOUNT%',header_use);

    writeln('Writing spells');
    getindex(I_SPELL); freeindex; tmp := indx;
    for i := 1 to tmp.top do if not tmp.free[i] then write_SPELL(f,i);

    writeln('Writing objects, pass 1');
    getindex(I_OBJECT); freeindex; tmp := indx;
    for i := 1 to tmp.top do if not tmp.free[i] then write_OBJECT(f,i);

    writeln('Writing rooms, pass 1');
    getindex(I_ROOM); freeindex; tmp := indx;
    for i := 1 to tmp.top do if not tmp.free[i] then write_ROOM(f,i);

    writeln('Writing players');
    getindex(i_PLAYER); freeindex; tmp := indx;
    getuser; freeuser;
    for i := 1 to tmp.top do if not tmp.free[i] then write_PLAYER(f,i);

    writeln('Writing objects, pass 2');
    getindex(I_OBJECT); freeindex; tmp := indx;
    for i := 1 to tmp.top do if not tmp.free[i] then write_OBJECT2(f,i);

    writeln('Writing rooms, pass 2');
    getindex(I_ROOM); freeindex; tmp := indx;
    for i := 1 to tmp.top do if not tmp.free[i] then write_ROOM2(f,i);

    writeln('Writing global data');
    for i := 1 to GF_max do write_GVAL(f,i);

end;

procedure read_DATABASE(var f: text);
label loppu;
var block_use,
    line_use,
    room_use,
    object_use,
    header_use: integer;
    tmp: indexrec;
    i,j: integer;
    ver,user: string;
    error: boolean;
begin
    writeln('Database reading from ',dump_file,' started.');
    error := false;
    if not read_ITEM(f,'DATABASE%',ver) then begin
	error := true;
	goto loppu;
    end;
    if not read_ITEM(f,'BY%',user) then begin
	error := true;
	goto loppu;
    end;
    writeln('Database (version ',ver,') written by ',user);

    READ_vers_101 := ver >= '1.01';
    READ_vers_102 := ver >= '1.02';
    if (ver > VERSION) then writeln('Unknown version!');

    if not read_INTEGER(f,'BLOCKCOUNT%',block_use) then begin
	error := true;
	goto loppu;
    end;
    if not read_INTEGER(f,'LINECOUNT%',line_use) then begin
	error := true;
	goto loppu;
    end;
    if not read_INTEGER(f,'ROOMCOUNT%',room_use) then begin
	error := true;
	goto loppu;
    end;
    if not read_INTEGER(f,'OBJECTCOUNT%',object_use) then begin
	error := true;
	goto loppu;
    end;
    if not read_INTEGER(f,'HEADERCOUNT%',header_use) then begin
	error := true;
	goto loppu;
    end;
    writeln('Block descriptions: ',block_use:3);
    writeln('Line descriptions:  ',line_use:3);
    writeln('Rooms:              ',room_use:3);
    writeln('Objects:            ',object_use:3);
    writeln('MDL codes:          ',header_use:3);

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
          
    writeln('Initializing roomfile with ',room_use:1,' rooms');
    addrooms(room_use);

    writeln('Initializing block file with ',block_use:1,' description blocks');
    addblocks(block_use);

    writeln('Initializing line file with ',line_use:1,' lines');
    addlines(line_use);

    writeln('Initializing object file with ',object_use:1,' objects');
    addobjects(object_use);   

    writeln('Initializing header file for monsters with ',header_use:1,' headers');
    addheaders(header_use);

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

    { spells have constant amount }
    getindex(I_SPELL);
    indx.top := maxspells;
    putindex;

    writeln('Reading spells');
    j := 0;
    while read_SPELL(f,i) do j := j +1;
    writeln(j:3,' spells readed.');
    
    writeln('Reading objects, pass 1');
    j := 0;
    while read_OBJECT(f,i) do j := j +1;
    writeln(j:3,' objects readed.');


    writeln('Reading rooms, pass 1');
    j := 0;
    while read_ROOM(f,i) do j := j +1;
    writeln(j:3,' rooms readed.');

    writeln('Reading players');
    j := 0;
    while read_PLAYER(f,i) do j := j + 1;
    writeln(j:3,' players readed.');

    writeln('Reading objects, pass 2'); 
    j := 0;
    while read_OBJECT2(f,i) do j := j +1;
    writeln(j:3,' objects readed.');

    writeln('Reading rooms, pass 2');
    j := 0;
    while read_ROOM2(f,i) do j := j +1;
    writeln(j:3,' rooms readed.');

    writeln('Reading global data');
    j := 0;
    while read_GVAL(f,i) do j := j +1;
    writeln(j:3,' global data readed.');

loppu:
    if error then writeln('Dump file is invalid.');
end;

var play,exist: indexrec;
    userid: [global] veryshortstring;	{ userid of this player }

    public_id, disowned_id, system_id: shortstring;

    active: boolean; 

    dump: text;

BEGIN
    Get_Environment;

    if not lookup_class(system_id,'system') then
	writeln('%error in main program: system');
    if not lookup_class(public_id,'public') then
	writeln('%error in main program: public');
    if not lookup_class(disowned_id,'disowned') then
	writeln('%error in main program: disowned');

    Setup_Guts;
    userid := lowcase(get_userid);
    wizard := userid = MM_userid;
    Params;

    if open_database(false) then begin
	if dump_system then begin
	    open(dump,dump_file,new,default := '.DMP');
	    rewrite(dump);
	    write_DATABASE(dump);
	    close(dump);
	end;

	if build_system then begin
	    open(dump,dump_file,readonly,default := '.DMP');
	    reset(dump);
	    read_DATABASE(dump);
	    close(dump);
	end;

	close_database;
    end else writeln ('Can''t open database. Maybe someone is playing Monster.');

    Finish_Guts;
END.

