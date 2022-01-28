[environment,inherit ('Global','Database','Guts') ]
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

	myslot: [global] integer := 1;	{ here.people[myslot]... is this player }

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
		sprime := '';
		for i := 1 to length(s) do
			case chartable[s[i]].kind of
			    ct_none:    ;	{ DISCARD }
			    otherwise   sprime := sprime + 
				    chartable[s[i]].lcase;
			end; { case }
		lowcase := sprime;
	end;
end;

[global]
function classify (a: char): class;
begin
   case chartable[a].kind of
	ct_space, ct_none:	classify := space;
	otherwise case a of
	    '"':		classify := string_c;
	    '(',')',',','-':	classify := bracket;             
	    '!':		classify := comment;
	    otherwise		classify := letter;
	end; { case a }
   end; { case chartable }
end;

[global]
function clean_spaces(inbuf: mega_string):mega_string;
var bf: mega_string;
    space_f: boolean;
begin
    bf := ''; 
    space_f := true;
    while inbuf > '' do begin
	if chartable[inbuf [1]].kind = ct_none then  { DISCARD }
	else if chartable[inbuf [1]].kind <> ct_space then begin
	    bf := bf + inbuf [1];
	    space_f := false;
	end else if not space_f then begin
	    bf := bf + ' ';
	    space_f := true;
	end;
	inbuf := substr(inbuf,2,length(inbuf)-1)
    end;      
    if bf > '' then if chartable[bf[length(bf)]].kind = ct_space then
	bf := substr(bf,1,length(bf)-1);
    clean_spaces := bf
end; { clean spaces }

{ write_debug moved to DATABASE.PAS }

[global]
function cut_atom (var main: mega_string; var x: integer;
		    delimeter: char): shortstring;
var start,i,last: integer;
    result,result2: shortstring;
begin    
    write_debug('%cut_atom');
    start := x;               
    if x > length (main) then result := ''
    else begin                  
	if start + shortlen <=  length(main) then 
	    last := start + shortlen-1
	else last := length(main);   
	x := last+1;
	for i := last downto start do
	    if main[i] = delimeter then x := i;
	result := substr(main,start,x-start);
	x := x +1
    end;
    result2 := '';
    for i := 1 to length(result) do
	if chartable[result[i]].kind <> ct_none then 
	    result2 := result2 + result[i];
    cut_atom := result;
end; { cut_atom }

[global]
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
end; { obj_here }

[global]    
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
end; { obj_hold }

type tabletype = array [ 1.. maxroom] of boolean;
     { used in lookup_general and in meta_scan }

function solve_ambiquous(rec: namrec; indx: indexrec;
			 table: tabletype; s: string;
			 var result: integer): boolean;
label quit_label;

    procedure leave;
    begin
	writeln('QUIT - no selection');
	solve_ambiquous := false;
	goto quit_label;
    end;

var mapping : array [ 1 .. maxroom ] of 1 .. maxroom;
    count,i,current: integer;
    line: string;
    ok: boolean; 
begin
    writeln('"',s,'" is ambiquous - Refer you one of following?');
    count := 0;
    for i := 1 to indx.top do 
	if table[i] then begin
		count := count +1;
		writeln(' ',count:3,' ',rec.idents[i]);
		mapping[count] := i;
	end;
    current := 0;
    ok := false;
    writeln('Give number (0 for nothing) or use cursor keys (UP and DOWN) for selection.');
    repeat
	if current = 0 then line := '  0'
	else writev(line,current:3,' ; ',rec.idents[mapping[current]]);
	grab_line('selection: ',line,edit_mode := true,eof_handler := leave);
	if grab_next < 0 then begin
	    current := current -1;
	    if current < 0 then current := count;
	end else if grab_next > 0 then begin
	    current := current +1;
	    if current > count then current := 0;
	end else begin
	    readv(line,i,error:=continue);
	    if statusv = 0 then 
		if (i >= 0) or (i <= count) then begin
		    current := i;
		    ok := true;
	    end;
	end;
    until ok;

    if current = 0 then solve_ambiquous := false
    else begin
	result := mapping[current];
	solve_ambiquous := true;
    end;

    quit_label:
end; { solve_ambiquous }

function solve_ambiquous_list (list : array [ lower .. upper : integer ]
				    of shortstring;
                               table: tabletype;
			       s: string; var result: integer): boolean;
label quit_label;

    procedure leave;
    begin
	writeln('QUIT - no selection');
	solve_ambiquous_list := false;
	goto quit_label;
    end;

var mapping : array [ 1 .. maxroom ] of 1 .. maxroom;
    count,i,current: integer;
    line: string;
    ok: boolean; 

begin
    writeln('"',s,'" is ambiquous - Refer you one of following?');
    count := 0;

    for i := lower to upper do if table[i] then begin
	 count := count +1;
	 writeln(' ',count:3,' ',list[i]);
	 mapping[count] := i;
    end;

    current := 0;
    ok := false;
    writeln('Give number (0 for nothing) or use cursor keys (UP and DOWN) for selection.');
    repeat
	if current = 0 then line := '  0'
	else writev(line,current:3,' ; ',list[mapping[current]]);
	grab_line('selection: ',line,edit_mode := true,eof_handler := leave);
	if grab_next < 0 then begin
	    current := current -1;
	    if current < 0 then current := count;
	end else if grab_next > 0 then begin
	    current := current +1;
	    if current > count then current := 0;
	end else begin
	    readv(line,i,error:=continue);
	    if statusv = 0 then 
		if (i >= 0) or (i <= count) then begin
		    current := i;
		    ok := true;
	    end;
	end;
    until ok;

    if current = 0 then solve_ambiquous_list := false
    else begin
	result := mapping[current];
	solve_ambiquous_list := true;
    end;

    quit_label:
end; { solve_ambiquous_list }
			       
function lookup_general(rec: namrec; ind: integer; 
			var id: integer; s: string;
			help: boolean): boolean;
var i,poss,maybe,num: integer;
    temp: string;
    table: tabletype;
begin
    if debug then writeln('lookup_general: ',s);    
    for i := 1 to maxroom do table[i] := false;

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
	    else if (index(temp,s) = 1) or (index(temp,' '+s) > 1) then begin
		maybe := maybe + 1;
		poss := i;
		table[i] := true;
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
	    lookup_general := solve_ambiquous(rec,indx,table,s,id);
	end else lookup_general := false;
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


[global] 
function parse_pers(var pnum: integer;s: string; help: boolean := false): 
    boolean;
var
	i,poss,maybe,num: integer;
	pname: string;

	names: array [ 1 .. maxpeople ] of shortstring;
	table: tabletype;
begin
	gethere;
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxpeople do begin
		table[i] := false;

		if (here.people[i].kind > 0) and 
		    (here.people[i].hiding = 0) then begin
			pname := lowcase(here.people[i].name);
			names [ i ] := here.people[i].name;

			if s = pname then
				num := i
			else if (index(pname,s) = 1) or 
			        (index(pname,' '+s) > 1) then begin
				table[i] := true;
				maybe := maybe + 1;
				poss := i;
			end;
		end;
	end;
	if num <> 0 then begin
		pnum := num;
		parse_pers := true;
	end else if maybe = 1 then begin
		pnum := poss;
		parse_pers := true;
	end else if maybe > 1 then begin
		pnum := 0;
		if help then parse_pers :=
		    solve_ambiquous_list(names,table,s,pnum)
		else parse_pers := false;
	end else begin
		pnum := 0;
		parse_pers := false;
	end;
end; { parse_pers }

{ similar to lookup_obj, but only returns true if the object is in
  this room or is being held by the player }
{ and s may be in the middle of the objact name -- Leino@finuh }

function parse_obj (var pnum: integer;
			s: string; help: boolean := false): boolean;
var
	i,poss,maybe: integer;

	table: tabletype;
	temp: shortstring;

begin
	getobjnam;
	freeobjnam;
	getindex(I_OBJECT);
	freeindex;

        for i := 1 to maxroom do table[i] := false;

	s := lowcase(s);
	pnum := 0;
	maybe := 0;
	for i := 1 to indx.top do begin
		if not(indx.free[i]) then begin
			temp := lowcase(objnam.idents[i]);
			if s =  temp then begin
				if obj_here(i) or obj_hold(i) then
				    pnum := i
			end else if ((index(temp,s) = 1) or
				(index(temp,' '+s) > 0)) then begin
			    if (obj_here(i) or obj_hold(i)) then begin
				maybe := maybe + 1;
				poss := i;
				table[i] := true;
			    end;
			end;
		end;
	end;
	if pnum <> 0 then begin
		parse_obj := true;
	end else if maybe = 1 then begin
		pnum := poss;
		parse_obj := true;
	end else if maybe > 1 then begin
	   if help then parse_obj := solve_ambiquous(objnam,indx,table,s,pnum)
	   else parse_obj := false;
	end else begin
		parse_obj := false;
	end;
end; { parse_obj }


function meta_scan( indx:  indexrec;
		    name:    namrec;
		    function action(	nameid:	shortstring;
					id:	integer
			):  boolean;
		    line:   mega_string;
		    silent: boolean;
		    function restriction (id: integer): boolean
		    ):	    boolean;

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
	temp: shortstring;
    begin
	write_debug('%sub_scan: ',atom);
	for i := 1 to maxroom do result[i] := false;
	count := 0;
	exact := 0;
	for i := 1 to indx.top do if not indx.free[i] then begin
	    temp := clean_spaces(lowcase(name.idents[i]));
	    if ((index(temp,atom) = 1) or 
		((index(temp,' '+atom) > 0) 
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
	    if silent then error := true
	    else if error then writeln('"',atom,'" is ambiquous.')
	    else error := not solve_ambiquous(name,indx,temp,atom,exact);
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

	table: tabletype;
	temp: shortstring;
begin
    if debug then writeln('lookup_dir: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;

	for i := 1 to maxroom do table[i] := false;

	for i := 1 to maxexit do begin
		temp := lowcase(direct[i]);
		if s = temp then num := i
		else if index(temp,s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
			table[i] := true;
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
	    if help then lookup_dir := solve_ambiquous_list (direct,table,s,dir)
	    else lookup_dir := false;
	end else begin
	    lookup_dir := false;
	end;
end; { lookup_dir }

[global]
function lookup_show(var n: integer;s:string;
    help: boolean := false): boolean;
var
	i,poss,maybe,num: integer;
	table: tabletype;
	temp: shortstring;
begin
    if debug then writeln('lookup_show: ',s);

	for i := 1 to maxroom do table[i] := false;

	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to numshow do begin
		temp := lowcase(show[i]);
		if s = temp then num := i
		else if index(temp,s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
			table[i] := true;
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
	    if help then lookup_show := solve_ambiquous_list(show,table,s,n)
	    else lookup_show := false;
	end else begin
		lookup_show := false;
	end;
end;	{ lookup_show }

[global]
function lookup_set(var n: integer;s:string;
    help: boolean := false): boolean;
var
	i,poss,maybe,num: integer;
	table: tabletype;
	temp: shortstring;
begin
    if debug then writeln('lookup_set: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;

	for i := 1 to maxroom do table[i] := false;

	for i := 1 to numset do begin
		temp := lowcase(setkey[i]);
		if s = temp then num := i
		else if index(temp,s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
			table[i] := true;
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
	    if help then lookup_set := solve_ambiquous_list(setkey,table,s,n)
	    else lookup_set := false;
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
		if lowcase(nam.idents[n]) = lowcase(s) then
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
	ident_cache: [static] integer := -1;
	ident_last: [static] string := '';
	cache_ok: boolean;
begin
	{ because INT_* routines calls so many time, we
	  build one item deep cache for that routine.
	  Cache supposes that new monster/player isn't 
	  get same name as what was asked in last time or
	  name isn't changed. 

	  Chance detect only if player/monster is deleted.
	  I think that, this is enough.
	}

	cache_ok := false;
	if (ident_last = s) and (ident_cache > 0) then begin
	    getindex(I_PLAYER);
		if ident_cache < indx.top then
		    if not indx.free[ident_cache] then cache_ok := true
		    else ident_cache := -1;
	    freeindex;
	end;
		
	if cache_ok then begin
	    n := ident_cache;
	    exact_pers := true;
	end else if lookup_pers(n,s) then begin
		if lowcase(pers.idents[n]) = lowcase(s) then begin
		    ident_cache := n;
		    ident_last := s;
		    exact_pers := true
		end else begin
		    ident_cache := -1;
		    exact_pers := false;
		end;
	end else begin
	    ident_cache := -1;
	    exact_pers := false;
	end;
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
		if lowcase(objnam.idents[n]) = lowcase(s) then
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
	names: array [ 1 .. maxclass ] of shortstring;
	table: tabletype;
	temp: shortstring;
begin
    if debug then writeln('lookup_class: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxclass do begin
		table[i] := false;
		names[i] := classtable[i].name;
		temp := lowcase(classtable[i].name);
		if s = temp then num := i
		else if index(temp,s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
			table[i] := true;
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
	    id := '<error>';
	    lookup_class := false;
	    if help then begin
		if solve_ambiquous_list(names,table,s,num) then begin
		    id := classtable[num].id;
		    lookup_class := true;
		end;
	    end;
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

	names: array [ 1 .. maxpriv ] of shortstring;
	table: tabletype;

begin
    if debug then writeln('lookup_priv: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxpriv do begin
		table[i] := false;
		names[i] := privtable[i].name;
		if s = lowcase(privtable[i].name) then
			num := i
		else if index(lowcase(privtable[i].name),s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
			table[i] := true;
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
	    id := 0;
	    lookup_priv := false;
	    if help then begin
		if solve_ambiquous_list(names,table,s,num) then begin
		    id := privtable[num].value;
		    lookup_priv := true;
		end;
	    end;
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

	names: array [ 1 .. maxtype] of shortstring;
	table: tabletype;
begin
    if debug then writeln('lookup_type: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxtype do begin
		if pl then name :=  typetable[i].plname 
		else name := typetable[i].name;
		names[i] := name;
		table[i] := false;

		if s = name then num := i
		else if index(lowcase(name),s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
			table[i] := true;
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
		id := t_none;
		lookup_type := false;
	    if help then begin
		if solve_ambiquous_list(names,table,s,num) then begin
		    id := typetable[num].value;
		    lookup_type := true;
		end;
	    end;
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

	names: array [ 1 .. maxflag] of shortstring;
	table: tabletype;
begin
    if debug then writeln('lookup_flag: ',s);
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxflag do begin
		table[i] := false;
		names[i] := flagtable[i].name;
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
	    id := 0;
	    lookup_flag := false;
	    if help then begin
		if solve_ambiquous_list(names,table,s,num) then begin
		    id := flagtable[num].value;
		    lookup_flag := true;
		end;
	    end;
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
