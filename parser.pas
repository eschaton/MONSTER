[environment,inherit ('Global','Database') ]
Module Parser(Output); 

[hidden] Const 
	maxclass  = 3;
	maxpriv   = 9;
	maxflag   = 3;

	maxtype	  = 5;

const
	PR_manager = 1;
	PR_poof    = 2;
	PR_global  = 4;
	PR_owner   = 8;
	PR_special = 16;
	PR_monster = 32;
	PR_exp     = 64;
	PR_quota   = 128;
	PR_spell   = 256;

	all_privileges = 
	    PR_manager +
	    PR_poof    +
	    PR_global  +
	    PR_owner   +
	    PR_special +
	    PR_monster +
	    PR_exp     +
	    PR_quota   +
	    PR_spell;

type
      class = ( bracket , letter , space, string_c,
		comment );			    { merkkien luokitus	    }

	o_type = (t_none, t_room, t_object, t_spell, t_monster,
		  t_player );

    privrec =
	record
	    name: shortstring;
	    value: unsigned;
	end;

    
    typerec =
	record
	    name: shortstring;
	    plname: shortstring;
	    value: o_type;
	end;
 
   flagrec =
	record
	    name: shortstring;
	    value: integer;
	end;


var
	typetable: [hidden] array [1..maxtype] of typerec :=
	    {   name, plname, value }
	    ( (	'monster', 'monsters', t_monster ),
	      ( 'object',  'objects',  t_object ),
	      ( 'room',	   'rooms',    t_room	),
	      ( 'spell',   'spells',   t_spell	),
	      ( 'player',  'players',  t_player) );


	classtable: [hidden] array [1..maxclass] of classrec :=
	    {   name	    , id }
	    ( ( 'Public'    , ''    ),
	      ( 'Disowned'  , '*'   ),
	      ( 'System'    , '#'   ));

	privtable: [hidden] array [1..maxpriv] of privrec := 

	    {   name	    , value }
	    ( ( 'Manager'   , PR_manager ),
	      ( 'Poof'	    , PR_poof ),
	      ( 'Global'    , PR_global ),
	      ( 'Owner'     , PR_owner ),
	      ( 'Special'   , PR_special ),
	      ( 'Monster'   , PR_monster ),
	      ( 'Experience', PR_exp ),
	      ( 'Quota'     , PR_quota ),
	      ( 'Spell'     , PR_spell ) );

    	flagtable : [hidden] array [1..maxflag] of flagrec := 
	    {   name	    , value }
	    ( ( 'Active'    , GF_ACTIVE),
	      ( 'Valid'	    , GF_VALID),
	      ( 'Wartime'   , GF_WARTIME ) );



	auth_priv: [hidden] unsigned := 0;
	cur_priv: [hidden] unsigned := 0;
	
	direct: [global] array[1..maxexit] of shortstring :=
		('north','south','east','west','up','down');

	show: [global] array[1..maxshow] of shortstring;

	numshow: [global] integer;

	setkey: [global] array[1..maxshow] of shortstring;

	numset: [global] integer;


[external] function player_here(id: integer; var slot: integer): boolean;
		    external;
[external] procedure gethere(n: integer := 0); external;

{ PRIVS }

[global]
function spell_priv: boolean;		
begin
    spell_priv := uand(cur_priv,PR_spell) > 0;
end; 


[global]
function manager_priv: boolean;		
    { Tells if user may use 'system' }
begin
    manager_priv := uand(cur_priv,PR_manager) > 0;
end; 

[global]
function	quota_priv: boolean;		
    { Tells if user may extend quota }
begin
   quota_priv := uand(cur_priv,PR_quota) > 0;
end; 

[global]
function poof_priv: boolean;{ Tells if the user may poof }
begin
    poof_priv := uand(cur_priv,PR_poof) > 0;

end; 

[global]
function owner_priv: boolean; { Tells if the user may custom others' stuff }
begin
    owner_priv := uand(cur_priv,PR_owner) > 0;
end; 

[global]
function global_priv: boolean; 
begin
    global_priv := uand(cur_priv,PR_global) > 0;
end; 

[global]
function special_priv: boolean; { Tells if the user may create 'special' objects or exits }
begin
    special_priv := uand(cur_priv, PR_special) > 0;
end; 

[global]
function monster_priv: boolean; { tells if the user may create evil monsters }
begin
    monster_priv := uand(cur_priv,PR_monster) > 0;
end; 

[global]
function exp_priv: boolean;	{ Tells if the user may alter experience }
begin
    exp_priv := uand(cur_priv,PR_exp) > 0;
end; 

var  wizard: [global] boolean;
				{ Tells if user has rights to rebuild }


[global]
procedure set_auth_priv(priv: unsigned);
begin
    auth_priv := priv;
    cur_priv  := uand(cur_priv,priv);
end;

[global]
procedure set_cur_priv(priv: unsigned);
begin
    cur_priv := uand(priv, auth_priv);
end;

[global]
function read_cur_priv: unsigned;
begin
    read_cur_priv := cur_priv;
end;

[global]
function read_auth_priv: unsigned;
begin
    read_auth_priv := auth_priv;
end;

procedure list_privileges (privs: unsigned);
var i: integer;
begin
    if privs = 0 then write('None')
    else for i := 1 to maxpriv do
	if uand(privtable[i].value,privs) > 0 then 
	    write(privtable[i].name,' ');
    writeln;
end;

{ ---- }



[global]
function lowcase(s: string):string;
var
	sprime: string;
	i: integer;

begin
	if length(s) = 0 then
		lowcase := ''
	else begin
		sprime := s;
		for i := 1 to length(s) do
			if sprime[i] in ['A'..'Z'] then
			   sprime[i] := chr(ord('a')+(ord(sprime[i])-ord('A')));
		lowcase := sprime;
	end;
end;

[global]
function classify (a: char): class;
begin
   case a of
	' ',''(9):	classify := space;
	'"':		classify := string_c;
	'(',')',',','-':classify := bracket;             
	'!':		classify := comment;
	otherwise	classify := letter;
   end;
end;

[global]
function clean_spaces(inbuf: mega_string):mega_string;
var bf: mega_string;
    space_f: boolean;
begin
    bf := ''; 
    space_f := true;
    while inbuf > '' do begin
	if classify(inbuf [1]) <> space then bf := bf + inbuf [1]
	else if not space_f then bf := bf + ' ';
	space_f := classify(inbuf [1]) = space;
	inbuf := substr(inbuf,2,length(inbuf)-1)
    end;      
    if bf > '' then if classify(bf[length(bf)]) = space then
	bf := substr(bf,1,length(bf)-1);
    clean_spaces := bf
end; { clean spaces }

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
function cut_atom (var main: mega_string; var x: integer;
		    delimeter: char): shortstring;
var start,i,last: integer;
begin    
    write_debug('%cut_atom');
    start := x;               
    if x > length (main) then cut_atom := ''
    else begin                  
	if start + shortlen <=  length(main) then 
	    last := start + shortlen-1
	else last := length(main);   
	x := last+1;
	for i := last downto start do
	    if main[i] = delimeter then x := i;
	cut_atom := substr(main,start,x-start);
	x := x +1
    end
end; { cut_atom }

function lookup_general(rec: namrec; ind: integer; 
			var id: integer; s: string;
			help: boolean): boolean;
var i,poss,maybe,num: integer;
    temp: string;
begin
    if debug then writeln('lookup_general: ',s);    
    getindex(ind);
    freeindex;
    s := lowcase(s);
    i := 1;
    maybe := 0;
    num := 0;
    for i := 1 to indx.top do begin
	if not(indx.free[i]) then begin
	    temp := lowcase(rec.idents[i]);
	    if s = temp then num := i
	    else if index(temp,s) = 1 then begin
		maybe := maybe + 1;
		poss := i;
	    end;
	end;
    end;
    if debug then writeln ('lookup_general: (',num:1,',',maybe:1,')');
    if num <> 0 then begin
	id := num;
	lookup_general := true;
    end else if maybe = 1 then begin
	id := poss;
	lookup_general := true;
    end else if maybe > 1 then begin
	if help then begin
	    writeln('Ambiguous - Refer you one of following?');
	    for i := 1 to indx.top do 
		if not(indx.free[i]) then 
		    if index(lowcase(rec.idents[i]),s) = 1 then 
			writeln('          ',rec.idents[i]);
	end;
	lookup_general := false;
    end else begin
	lookup_general := false;
    end;
end; { lookup_general }

[global]
function lookup_user(var pnum: integer;s: string;
    help: boolean := false): boolean;
begin
    getuser;
    freeuser;
    lookup_user := lookup_general(user,i_PLAYER,pnum,s,help);
end;

[global]
function lookup_room(var n: integer; s: string;
    help: boolean := false): boolean;
begin
   if s <> '' then begin
	getnam;
	freenam;
	lookup_room := lookup_general(nam,I_ROOM,n,s,help);
   end else lookup_room := false;
end; { lookup_room }

[global]
function lookup_pers(var pnum: integer;s: string;
    help: boolean := false): boolean;
begin
    getpers;
    freepers;
    lookup_pers := lookup_general(pers,I_PLAYER,pnum,s,help);
end; { lookup_pers }

[global]
function lookup_obj(var pnum: integer;s: string;
    help: boolean := false): boolean;
begin
    getobjnam;
    freeobjnam;
    lookup_obj := lookup_general(objnam,I_OBJECT,pnum,s,help);
end;

[global]
function lookup_spell(var sp: integer;s: string;
    help: boolean := false): boolean;
begin
    getspell_name;
    freespell_name;
    lookup_spell := lookup_general(spell_name,I_SPELL,sp,s,help);
end;

function meta_scan( indx:  indexrec;
		    name:    namrec;
		    function action(	nameid:	shortstring;
					id:	integer
			):  boolean;
		    line:   mega_string;
		    silent: boolean;
		    function restriction (id: integer): boolean
		    ):	    boolean;
type tabletype = array [ 1.. maxroom] of boolean;

var table,temp:  tabletype;
    i,cur,count,exact: integer;
    result: boolean;
    atom: shortstring;
    unambiqous,error: boolean;


    function sub_scan(	indx: indexrec; 
			name: namrec;
			atom: shortstring;
		    var	result: tabletype;
		    var	exact:	integer): integer;
    var i,count: integer;
    begin
	write_debug('%sub_scan: ',atom);
	for i := 1 to maxroom do result[i] := false;
	count := 0;
	exact := 0;
	for i := 1 to indx.top do if not indx.free[i] then begin
	    if ((index(clean_spaces(lowcase(name.idents[i])),atom) = 1) or 
		((index(clean_spaces(lowcase(name.idents[i])),' '+atom) > 0) 
		 and unambiqous) ) and restriction(i) then begin
		result[i] := true;
		count := count +1;
	    end;
	    if (lowcase(name.idents[i]) = atom) and restriction(i)
		then exact := i;
	end;
	sub_scan := count;
    end;    { sub_scan }



begin
    write_debug('%meta_scan: ',line);
    if length(line) = 3 then	{ we can't do direct check because line can }
	if lowcase(line) = 'all' then line := '*';   { be over 80 characters }
    result := false;
    error  := false;
    for i := 1 to maxroom do table[i] := false;
    cur := 1;
    while cur <= length(line) do begin
	atom := lowcase(cut_atom(line,cur,','));
	unambiqous := true;
	if atom > '' then if atom[length(atom)] = '*' then begin
	    atom := substr(atom,1,length(atom)-1);
	    unambiqous := false;
	end;
	atom := clean_spaces(atom);
	count := sub_scan(indx,name,atom,temp,exact);
	if unambiqous and (exact = 0) and (count > 1) then begin
	    error := true;
	    if not silent then writeln('"',atom,'" is ambiguous.');
	end;
	if (count = 0) and unambiqous then begin
	    error := true;
	    if not silent then writeln('"',atom,'" not exist.');
	end;
	if unambiqous and (exact > 0) then
	    table[exact] := true
	else for i := 1 to maxroom do
	    table[i] := table[i] or temp[i];
    end;
    { action part }
    if not error then
	for i := 1 to maxroom do
	    if table[i] then
		result := result or action(name.idents[i],i);
    meta_scan := result;
end; { meta_scan }

[global]
function scan_room(	function action(    nameid:	shortstring;
					    id:	integer
			):  boolean;
		    line:   mega_string;
		    silent: boolean := false;
		    function restriction (id: integer): boolean
		    ):	    boolean;
begin
    getnam;
    freenam;
    getindex(I_ROOM);
    freeindex;
    scan_room := meta_scan(indx,nam,action,line,silent,restriction);
end;

[global]
function scan_pers(	function action(    nameid:	shortstring;
					    id:	integer
			):  boolean;
		    line:   mega_string;
		    silent: boolean := false;
		    function restriction (id: integer): boolean
		    ):	    boolean;
begin
    getpers;
    freepers;
    getindex(I_PLAYER);
    freeindex;
    scan_pers := meta_scan(indx,pers,action,line,silent,restriction);
end;

[global]
function scan_obj(	function action(    nameid:	shortstring;
					    id:	integer
			):  boolean;
		    line:   mega_string;
		    silent: boolean := false;
		    function restriction (id: integer): boolean
		    ):	    boolean;
begin
    getobjnam;
    freeobjnam;
    getindex(I_OBJECT);
    freeindex;
    scan_obj := meta_scan(indx,objnam,action,line,silent,restriction);
end;

[global]
function scan_pers_slot(function action(	nameid:	    shortstring;
						slot:	    integer
			    ):	boolean;
			line:	mega_string;
			silent: boolean := false;
			function restriction (slot: integer): boolean
			):	boolean;

    function real_res(id: integer): boolean;
    var slot: integer;
    begin
	if player_here(id,slot) then
	    real_res := restriction(slot)
	else real_res := false;
    end; { real_res }

    function real_action(   nameid: shortstring;
			    id:	    integer
			    ):	    boolean;
    var slot: integer;
    begin
	gethere;	{ we need this here because action can change 'here' }
	if player_here(id,slot) then
	    real_action := action(nameid,slot)
	else real_action := false;
    end; { real_acttion }


begin

    gethere;
    scan_pers_slot := scan_pers (real_action,line,silent,real_res);

end; { scan_pers_obj }


{ translate a direction s [north, south, etc...] into the integer code }

[global]
function lookup_dir(var dir: integer;s:string;
    help: boolean := false): boolean;
var
	i,poss,maybe,num: integer;

begin
    if debug then writeln('lookup_dir: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxexit do begin
		if s = direct[i] then
			num := i
		else if index(direct[i],s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;
	end;
	if debug then writeln ('lookup_dir: (',num:1,',',maybe:1,')');

	if num <> 0 then begin
		dir := num;
		lookup_dir := true;
	end else if maybe = 1 then begin
		dir := poss;
		lookup_dir := true;
	end else if maybe > 1 then begin
	    if help then begin
		writeln('Ambiguous - Refer you one of following?');
		for i := 1 to maxexit do  
			if index(lowcase(direct[i]),s) = 1 then 
			    writeln('          ',direct[i]);
	    end;
	    lookup_dir := false;
	end else begin
	    lookup_dir := false;
	end;
end; { lookup_dir }

[global]
function lookup_show(var n: integer;s:string;
    help: boolean := false): boolean;
var
	i,poss,maybe,num: integer;

begin
    if debug then writeln('lookup_show: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to numshow do begin
		if s = show[i] then
			num := i
		else if index(show[i],s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;
	end;
	if debug then writeln ('lookup_show: (',num:1,',',maybe:1,')');

	if num <> 0 then begin
		n := num;
		lookup_show := true;
	end else if maybe = 1 then begin
		n := poss;
		lookup_show := true;
	end else if maybe > 1 then begin
	    if help then begin
		writeln('Ambiguous - Refer you one of following?');
		for i := 1 to numshow do 
		    if index(lowcase(show[i]),s) = 1 then 
			writeln('          ',show[i]);
	    end;
	    lookup_show := false;
	end else begin
		lookup_show := false;
	end;
end;	{ lookup_show }

[global]
function lookup_set(var n: integer;s:string;
    help: boolean := false): boolean;
var
	i,poss,maybe,num: integer;

begin
    if debug then writeln('lookup_set: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to numset do begin
		if s = setkey[i] then
			num := i
		else if index(setkey[i],s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;
	end;
	if debug then writeln ('lookup_set: (',num:1,',',maybe:1,')');
	if num <> 0 then begin
		n := num;
		lookup_set := true;
	end else if maybe = 1 then begin
		n := poss;
		lookup_set := true;
	end else if maybe > 1 then begin
	    if help then begin
		writeln('Ambiguous - Refer you one of following?');
		for i := 1 to numset do 
		if index(lowcase(setkey[i]),s) = 1 then 
			writeln('          ',setkey[i]);
	    end;
	    lookup_set := false;
	end else begin
		lookup_set := false;
	end;
end;

[global]
function exact_room(var n: integer;s: string): boolean;
var
	match: boolean;

begin
	if debug then
		writeln('%exact room: s = ',s);
	if lookup_room(n,s) then begin
		if nam.idents[n] = lowcase(s) then
			exact_room := true
		else
			exact_room := false;
	end else
		exact_room := false;
end;	{ exact_room }

[global]
function exact_pers(var n: integer;s: string): boolean;
var
	match: boolean;

begin
	if lookup_pers(n,s) then begin
		if lowcase(pers.idents[n]) = lowcase(s) then
			exact_pers := true
		else
			exact_pers := false;
	end else
		exact_pers := false;
end;	{ exact_user }

[global]
function exact_user(var n: integer;s: string): boolean;
var
	match: boolean;

begin
	if lookup_user(n,s) then begin
		if lowcase(user.idents[n]) = lowcase(s) then
			exact_user := true
		else
			exact_user := false;
	end else
		exact_user := false;
end;	{ exact_user }

[global]
function exact_obj(var n: integer;s: string): boolean;
var
	match: boolean;

begin
	if lookup_obj(n,s) then begin
		if objnam.idents[n] = lowcase(s) then
			exact_obj := true
		else
			exact_obj := false;
	end else
		exact_obj := false;
end;	{ exact_obj }

[global]
function lookup_class(var id: shortstring; s:string;
    help: boolean := false): boolean;
var
	i,poss,maybe,num: integer;

begin
    if debug then writeln('lookup_class: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxclass do begin
		if s = lowcase(classtable[i].name) then
			num := i
		else if index(lowcase(classtable[i].name),s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;
	end;
	if debug then writeln ('lookup_class: (',num:1,',',maybe:1,')');

	if num <> 0 then begin
		id := classtable[num].id;
		lookup_class := true;
	end else if maybe = 1 then begin
		id := classtable[poss].id;
		lookup_class := true;
	end else if maybe > 1 then begin
	    if help then begin
		writeln('Ambiguous - Refer you one of following?');
		for i := 1 to maxclass do 
		    if index(lowcase(classtable[i].name),s) = 1 then 
			writeln('          ',classtable[i].name);
	    end;
	    id := '<error>';
	    lookup_class := false;
	end else begin
		id := '<error>';
		lookup_class := false;
	end;
end;

[global]
function lookup_priv(var id: unsigned; s:string;
    help: boolean := false): boolean;
var
	i,poss,maybe,num: integer;

begin
    if debug then writeln('lookup_priv: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxpriv do begin
		if s = lowcase(privtable[i].name) then
			num := i
		else if index(lowcase(privtable[i].name),s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;
	end;
	if debug then writeln ('lookup_priv: (',num:1,',',maybe:1,')');

	if num <> 0 then begin
		id := privtable[num].value;
		lookup_priv := true;
	end else if maybe = 1 then begin
		id := privtable[poss].value;
		lookup_priv := true;
	end else if maybe > 1 then begin
	    if help then begin
		writeln('Ambiguous - Refer you one of following?');
		for i := 1 to maxpriv do 
		    if index(lowcase(privtable[i].name),s) = 1 then 
			writeln('          ',privtable[i].name);
	    end;
	    id := 0;
	    lookup_priv := false;
	end else begin
		id := 0;
		lookup_priv := false;
	end;
end;

[global]
function lookup_type(var id: o_type; s:string; pl: boolean;
    help: boolean := false): boolean;
var
	i,poss,maybe,num: integer;
	name: shortstring;

begin
    if debug then writeln('lookup_type: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxtype do begin
		if pl then name :=  typetable[i].plname 
		else name := typetable[i].name;

		if s = name then num := i
		else if index(lowcase(name),s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;
	end;
	if debug then writeln ('lookup_type: (',num:1,',',maybe:1,')');

	if num <> 0 then begin
		id := typetable[num].value;
		lookup_type := true;
	end else if maybe = 1 then begin
		id := typetable[poss].value;
		lookup_type := true;
	end else if maybe > 1 then begin
	    if help then begin
		writeln('Ambiguous - Refer you one of following?');
		if pl then begin
		    for i := 1 to maxtype do 
			if index(lowcase(typetable[i].plname),s) = 1 then 
			    writeln('          ',typetable[i].plname);
		end else begin
		    for i := 1 to maxtype do 
			if index(lowcase(typetable[i].name),s) = 1 then 
			    writeln('          ',typetable[i].name);
		end;
	    end;

		id := t_none;
		lookup_type := false;
	end else begin
		id := t_none;
		lookup_type := false;
	end;
end;

[global]
function lookup_flag(var id: integer; s:string;
    help: boolean := false)   : boolean;
var
	i,poss,maybe,num: integer;

begin
    if debug then writeln('lookup_flag: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxflag do begin
		if s = lowcase(flagtable[i].name) then
			num := i
		else if index(lowcase(flagtable[i].name),s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;
	end;
	if debug then writeln ('lookup_flag: (',num:1,',',maybe:1,')');

	if num <> 0 then begin
		id := flagtable[num].value;
		lookup_flag := true;
	end else if maybe = 1 then begin
		id := flagtable[poss].value;
		lookup_flag := true;
	end else if maybe > 1 then begin
	    if help then begin
		writeln('Ambiguous - Refer you one of following?');
		for i := 1 to maxflag do 
		    if index(lowcase(flagtable[i].name),s) = 1 then 
			writeln('          ',flagtable[i].name);
	    end;
	    id := 0;
	    lookup_flag := false;
	end else begin
		id := 0;
		lookup_flag := false;
	end;
end; { lookup_flag }


[global]
function class_out(id: shortstring): shortstring;
var i: integer;
begin
    class_out := id;
    for i := 1 to maxclass do
	if id = classtable[i].id then class_out := classtable[i].name;
end; { class_out }

{ global procedures for module interpreter }

[global]
function int_spell_level(pname: shortstring; sname: shortstring): integer;
   { -1 = error }
var pid: integer;
    sid: integer;
begin
    if debug then begin
	writeln('%int_spell_level: ',pname);
	writeln('%               : ',sname);
    end;
    if not lookup_pers(pid,pname) then int_spell_level := -1
    else if not lookup_spell(sid,sname) then int_spell_level := -2
    else begin
	getspell(pid);
	freespell;
	int_spell_level := spell.level[sid];
    end;
end; { int_spell_level }

[global]
function int_set_spell_level(pname: shortstring; sname: shortstring;
    lev: integer): boolean;
var pid: integer;
    sid: integer;
begin
    if debug then begin
	writeln('%int_set_spell_level: ',pname);
	writeln('%                   : ',sname);
	writeln('%                   : ',lev:1);
    end;
    if not lookup_pers(pid,pname) then int_set_spell_level := false
    else if not lookup_spell(sid,sname) then int_set_spell_level := false
    else begin
	getspell(pid);
	spell.level[sid] := lev;
	putspell;
	int_set_spell_level := true;
    end;
end; { int_set_spell_level }

[global]
function int_lookup_player(name: shortstring): shortstring;
var i: integer;
begin
   if debug then writeln('%int_lookup_player: ',name);
   if lookup_pers(i,name) then int_lookup_player := pers.idents[i]
   else int_lookup_player := '';
end; { int_lookup_player }

[global]
function int_lookup_object(name: shortstring): shortstring;
var i: integer;
begin
   if debug then writeln('%int_lookup_object: ',name);
   if lookup_obj(i,name) then int_lookup_object := objnam.idents[i]
   else int_lookup_object := '';
end; { int_lookup_object }

[global]
function int_lookup_room(name: shortstring): shortstring;
var i: integer;
begin
   if debug then writeln('%int_lookup_room: ',name);
   if lookup_room(i,name) then int_lookup_room := nam.idents[i]
   else int_lookup_room := '';
end; { int_lookup_room }

[global]
function int_lookup_direction(name: shortstring): shortstring;
var i: integer;
begin
   if debug then writeln('%int_lookup_direction: ',name);
   if lookup_dir(i,name) then int_lookup_direction := direct[i]
   else int_lookup_direction := '';
end; { int_lookup_direction }

[global]
function slead(s: string):string;
var
	i: integer;
	going: boolean;

begin
	if length(s) = 0 then begin
		slead := '';
		if debug then writeln('slead: ');
	end else begin
		i := 1;
		going := true;
		while going do begin
			if i > length(s) then
				going := false
			else if (s[i]=' ') or (s[i]=chr(9)) then
				i := i + 1
			else
				going := false;
		end;

		if i > length(s) then begin
		    slead := '';
		    if debug then writeln('slead: ');
		end else begin
		    slead := substr(s,i,length(s)+1-i);
		    if debug then writeln('slead: ',substr(s,i,length(s)+1-i));
		end;
	end;
end;

[global]
function bite(var s: string): string;
var
	i: integer;

begin
	if length(s) = 0 then
		bite := ''
	else begin
		i := index(s,' ');
		if i = 0 then begin
			bite := s;
			s := '';
		end else begin
			bite := substr(s,1,i-1);
			s := slead(substr(s,i+1,length(s)-i));
		end;
	end;
end;

end. { module parser }
