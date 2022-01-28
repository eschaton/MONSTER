[inherit ('Global','Guts','Database','Parser'),environment]
module interpreter (output);			    { hurtta@finuh }
{+
COMPONENT: Interpreter for MDL
	   MDL = Monster Definition Language

PROGRAM DESCRIPTION:
 
    
 
AUTHORS:
 
    Kari Hurtta
 
CREATION DATE: (unknown) about ?.3.1989
 
DESIGN ISSUES:
 

 
VERSION:


 
MODIFICATION HISTORY:
 
     Date     |   Name  | Description
--------------+---------+-------------------------------------------------------
   11.2.1991  |         | This comment header created
   26.5.1992  | Hurtta  | Now parser print error line also (LINE_* in parse)
--------------+---------+-------------------------------------------------------

-}
 
{ Interpreter for MDL }
{ MDL = Monster Definition Language }

{ Kooditiedoston rakenne:

Yksi atomi (= yksi rivi kooditiedostossa):

Tapaus 1:

<atomin numero>,
kaksoispiste,
<parametrin 1 numero>,
kaksoispiste,
<parametrin 2 numero>,
kaksoispiste,
<parametrin 3 numero>,
kaksoispiste,
<funktion nimi>,
EOLN

Tapaus 2:

<atomin numero negatiivisena>,
kaksoispiste,
<parametrin 1 numero>,
kaksoispiste,
<parametrin 2 numero>,
kaksoispiste,
<parametrin 3 numero>,
kaksoispiste,
<funktion numero>,
EOLN

Tapaus 3:

<atomin numero negatiivisena>,
kaksoispiste,
<parametrin 1 numero>,
kaksoispiste,
<parametrin 2 numero>,
kaksoispiste,
<parametrin 3 numero>,
kaksoispiste,
<funktion numero>,
kaksoispiste,
<parametrien lukum‰‰r‰ - 3>,
kaksoispiste,
<loput parametrit kaksoipistell‰ erotettuina>,
EOLN

Tapaus 4:
H,
<header -funktion numero>,
kaksoispiste,
<parametrien lukum‰‰r‰>,
kaksoispiste,
<parametrit kaksoispisteell‰ erotettuina>,
kaksoispiste,
label_kentt‰,
EOLN

Tapaus 5:
J,
<hyppyosoite>,
kaksoispiste,
<parametrien lukum‰‰r‰>,
kaksoispiste,
<parametrit kaksoispisteell‰ erotettuina>,
EOLN

}


const atom_length = shortlen;   


      string_length = mega_length;

 
      max_functions = 80;  { esimerkiksi null,get, ...   }
      max_headers   = 10;  { esimerkiksi SUBMIT, FOR ... }
      max_labels    = 50; 

	max_flag = 5;
	max_param = 30;

	new_line_limit = 3;	{ kuinka monta parametria pit‰‰ olla ett‰ }
				{ parametrit tulostetaan kukin omalle 
				    rivilleen }

	max_buffer = 5;		{ Puskurien lukum‰‰r‰ }

	ERROR_ID = 70;		{ virheen numero }
	LABEL_ID = 6;		{ LABEL headerin numero }
	GOSUB_ID = 3;		{ GOSUB headerin numero }
                      
type  atom_t = shortstring; 			    { Muuttujat ja k‰skyt   }
						    { ja listan alkiot	    }
      string_t = mega_string;                       { merkkijonot	    }
      string_l = string;			{ rivin pituiset merkkijonot }
	{ class moved to parser.pas }

      name_type = (n_function, n_header, n_const, n_comment,
		   n_head, n_error,n_variable, n_gosub);
						    { loodin k‰skyjen tyyppi }

      paramtable = array [ 1 .. max_param ] of integer;


      atom = record				    { yksi ohjelman k‰sky   }
		nametype: name_type;
                name: integer;
                long_name: ^string_t;
		params: paramtable
                { p1,p2,p3: integer }
             end;                 

     tabletyp = array [ 1 .. MAXATOM ] of atom;	{ Ohjelman talletuspaikka   }
     
     buffer = record
	table: tabletyp;
	used: 0 .. MAXATOM;			{ Ohjelman koko		    }
	current_program: integer;		{ T‰m‰nhetkinen ohjelmakood }
	current_version: integer;		{ ja sen versionumero	    }
	time: 0 .. maxint;			{ Kuinka paljon aikaa	    }
						{ k‰ytˆst‰ }
    end; { buffer }
                      
Var	line_i: string_t := '';
      code_running : boolean := false; { est‰‰ p‰‰lekk‰isen suorittamisen }
      cursor: integer := 0;
      cl,ql: class;       
      error_counter : integer := 0;

	pool : array [ 1 .. max_buffer ] of buffer;
	current_buffer : 1 .. max_buffer;

	monster_level: integer;	    { 0 jos ei tasoa } 
	used_attack:   integer;
	attack_limit:  integer;

      privilegion: boolean;	    { lippu: onko koodi privileged-moodissa }
      system_code: boolean;	    { lippu: omistaako systeemi koodin	    }
      spell_mode:  boolean;	    { lippu: onko spell-moodissa            }
          
      ftable: array [ 1 .. max_functions ] of record
	    name: atom_t;
	    min:  0 .. max_param;
	    max:  0 .. max_param
      end;

      htable: array [ 1 .. max_headers ]   of record
	    name: atom_t;
	    min:  0 .. max_param;
	    max:  0 .. max_param
      end;

      flagtable: array [1 .. max_flag ] of record
		value: unsigned;
		off: string_l;
		on: string_l;
	    end;

Value ftable := (
	('+',		2,  max_param),	    { 1 }
	('=',		2,  2),		    { 2 }
	('inv',		0,  0),		    { 3 }
	('pinv',	0,  0),		    { 4 }
	('players',	0,  0),		    { 5 }
	('objects',	0,  0),		    { 6 }
	('get',		1,  1),		    { 7 }
	('pget',	1,  1),		    { 8 }
	('drop',	1,  1),		    { 9 }
	('pdrop',	1,  1),		    { 10 }
	('and',		2,  2),		    { 11 }
	('or',		1,  3),		    { 12 }
	('move',	1,  1),		    { 13 }
	('pmove',	1,  1),		    { 14 }
	('pprint',	0,  max_param),	    { 15 }
	('print',	0,  max_param),	    { 16 }
	('oprint',	0,  max_param),	    { 17 }
	('pprint raw',	0,  max_param),	    { 18 }
	('print raw',	0,  max_param),	    { 19 }
	('oprint raw',	0,  max_param),	    { 20 }
	('print null',	1,  max_param),	    { 21 }
	('if',		2,  3),		    { 22 }
	('where',	1,  1),		    { 23 }
	('null',	0,  max_param),	    { 24 }
	('attack',	1,  1),		    { 25 }
	('heal',	1,  1),		    { 26 }
	('not',		1,  1),		    { 27 }
	('random',	1,  1),		    { 28 }
	('strip',	1,  1),		    { 29 }
	('experience',	1,  1),		    { 30 }
	('plus',	2,  2),		    { 31 }
	('difference',	2,  2),		    { 32 }
	('times',	2,  2),		    { 33 }
	('quotient',	2,  2),		    { 34 }
	('set experience',  1,	1),	    { 35 }
	('get state',	0,  0),		    { 36 }
	('set state',	1,  1),		    { 37 }
	('less',	2,  2),		    { 38 }
	('number',	1,  1),		    { 39 }
	('health',	1,  1),		    { 40 }
	('all objects',	0,  0),		    { 41 }
	('all rooms',	0,  0),		    { 42 }
	('all players',	0,  0),		    { 43 }
	('control',	2,  2),		    { 44 }
	('exclude',	2,  2),		    { 45 }
	('get remote state',	1,  1),	    { 46 }
	('set remote state',	2,  2),	    { 47 }
	('remote players',	1,  1),	    { 48 }
	('remote objects',	1,  1),	    { 49 }
	('duplicate',	1,  1),		    { 50 }
	('pduplicate',	1,  1),		    { 51 }
	('destroy',		1,  1),	    { 52 }
	('pdestroy',		1,  1),	    { 53 }
	('string head',		1,  1),	    { 54 }
	('string tail',		1,  1),	    { 55 }
	('head',		1,  1),	    { 56 }
	('tail',		1,  1),	    { 57 }
	('lookup object',	1,  1),	    { 58 }
	('lookup player',	1,  1),	    { 59 }
	('lookup room',		1,  1),	    { 60 }
	('privilege',		2,  2),	    { 61 }
	('parse player',	1,  1),	    { 62 }
	('parse object',	1,  1),	    { 63 }
	('parse room',		1,  1),	    { 64 }
	('userid',		1,  1),	    { 65 }
	('list',	1,  max_param),	    { 66 }
	('mattack',	2,  2),		    { 67 }
	('mheal',	2,  2),		    { 68 }
	('include',	2,  2),		    { 69 }
	('-ERROR-',		0,  0),	    { 70 }
	('lookup direction',	1,1),	    { 71 }
	('prog',1, max_param),		    { 72 }
	('get global flag',1,1),	    { 73 }
	('==',2,2),			    { 74 }
	('===',2,2),			    { 75 }
	('spell level',0,0),		    { 76 }
	('set spell level',1,1),	    { 77 }
	('',0,0),		{ 78 }
	('',0,0),		{ 79 }
	('',0,0)		{ 80 }
    ); 

    htable := (
	('SUBMIT ',	2,2),	{ 1 }
	('FOR ',	2,2),	{ 2 }
	('GOSUB ',	0,max_param),	{ 3 }
	('DEFINE ',	1,1),	{ 4 }
	('SET ',	1,1),	{ 5 }
	('LABEL ',	0,max_param),	{ 6 }
	('',0,0),		{ 7 }
	('',0,0),		{ 8 }
	('',0,0),		{ 9 }
	('',0,0)		{ 10 }
	);
    

    flagtable := (
	( 1, 'Control access enabled', 'Control access disabled' ),
	( 2, 'Spell mode disabled', 'Spell mode enabled' ),
	( 4, '', '' ),
	( 8, '', '' ),
	( 16, '', '' ));

{ muduulissa QUEUE olevia proseduureja }
[external]
function send_submit (monster: atom_t; code: integer;
	label_name: atom_t; deltatime: integer; player: atom_t): boolean;
external;
                
{ moduulissa GUTS olevia proseduureja }

{ moduulissa MON olevia globaaleja muuttujia }
var  myname : [external] atom_t;     
     { debug ja indx on nyt DATABASE.PASiissa }
     userid: [external] varying [12] of char; { pit‰‰ ola yht‰ pitk‰ kuin }
						{ weryshortstring }

{ moduulissa MON olevia globaaleja rutiineja }

[external]                                                         
procedure checkevents (silent: boolean := false); external;
[external]
function alloc_general(class: integer; var n: integer): boolean; external;
[external]
procedure delete_general(class: integer; var n: integer); external;

[external]
function int_userid(player: atom_t): atom_t; { = "" not found }
external;
[external]
function int_set_experience(player: atom_t; amount: integer): boolean;
external;
[external]
function int_get_experience(player: atom_t): integer; external;
[external]
function int_get_code(player: atom_t): integer; external;

[external]
function int_ask_privilege(player,privilege: atom_t): boolean; external;

[external]
function int_get_health(player: atom_t): integer; external;

{ int_lookup_X functions are in PARSER.PAS and no longer need definations }

[external] 
function int_inv (player: atom_t): string_t; external;
[external]
function int_objects(player: atom_t): string_t; external;


[external]
function int_l_object: string_t; external;

[external]
function int_l_player: string_t; external;

[external]
function int_l_room: string_t; external;


[external]
function int_players(player: atom_t): string_t; external;
[external]
function int_remote_objects(room: atom_t): string_t; external;
[external]
function int_remote_players(room: atom_t): string_t; external;



[external]
function int_get(player,object: atom_t): boolean; external;
[external]
function int_drop(player,object: atom_t): boolean; external;
[external]
function int_duplicate(player,object,owner: atom_t; privileged: boolean):
         boolean; external;
function int_destroy(player,object,owner: atom_t; privileged: boolean):
         boolean; external;

[external]
function int_poof (player,room,owner: atom_t; 
         general,own: boolean): boolean; external;
[external]
function int_login (player: atom_t; force: boolean): integer; external;
[external]
procedure int_logout (player: atom_t); external;
[external]
function int_where (player: atom_t): atom_t; external;
function int_attack(player: atom_t; power: integer): boolean; external;
[external]
function int_heal(player: atom_t; amount: integer): boolean; external;
[external]
procedure int_broadcast(player: atom_t; s: string_l; to_other: boolean); 
external;


{ write_debug moved to parser.pas }

{ cut_atom moved to parser.pas }

function exact_function (var x: integer; s: atom_t): boolean;
var i: integer;
begin
    write_debug('%exact_function : s = ',s);
    x := 0;
    for i := 1 to max_functions do
	if ftable[i].name > '' then
	    if EQ (s,ftable[i].name) then x := i;
    exact_function := x <> 0;
    if x > 0 then write_debug('%exact_function : ok');
end;

function exact_header (var x: integer; s: atom_t): boolean;
var i: integer;
begin
    write_debug('%exact_header : s = ',s);
    x := 0;
    for i := 1 to max_headers do
	if htable[i].name > '' then
	    if index (s,htable[i].name) = 1 then x := i;
    exact_header := x <> 0;
    if x > 0 then write_debug('%exact_header : ok');
end;

function x_monster_owner (code: integer; class : integer := 0): atom_t;
forward; { sama kuin monster_owner, muutta yht‰aikaa global & forward }
         { ei onnistunut }

function x_get_flag(code: integer; flag: integer): boolean; forward;

{ classify moved to parser.pas }    

{ clean_spaces moved to parser.pas }

function count_params(params: paramtable): integer;
var i,count: integer;	
begin			    	{ lasketaan parametrien m‰‰r‰ }
    write_debug('%count_params');
    count := 0;
    for i := 1 to max_param do if params[i] <> 0 then count := i;
    count_params := count;
end;	{ count_params }

procedure clear_program (buffer: integer);
var ln,i: integer;
begin
    with pool[buffer] do begin
	for ln := 1 to used do with table [ ln ] do begin
	    for i := 1 to max_param do params[i] := 0;
	    if long_name <> nil then dispose(long_name);
	    long_name := nil;
	    nametype := n_comment;
	    name := 0;
	end;
	used := 0;
	time := 0;
	current_program := 0;
	current_version := 0;
    end;
end; { clear program }
   

procedure parse (var source,result: text);       
label 999;
var atom_count: integer;
    atom_readed: boolean;
    current_atom: string_t;
    error_flag: boolean;
    label_count: integer;
    labels : array [ 1 .. max_labels ] of
	record
	    name: atom_t;
	    loc: integer;
	end;

    line: string_t;
    linep,atom_line_p: integer;
    linecount: integer;

    procedure read_line;
    begin
	if EOF(source) then begin
	    line := '';
	    linep := 0;
	    linecount := linecount +1;
	    atom_line_p := -1;
	end else begin
	    READLN(source,line);
	    linep := 1;
	    atom_line_p := -1;
	    linecount := linecount +1;
	end;
    end; { read_line }

    function LINE_EOF: boolean;
    begin
	if linep > 0 then LINE_EOF := false
	else LINE_EOF := eof(source);
    end; { LINE_EOF }

    function LINE_EOLN: boolean;
    begin
	LINE_EOLN := length(line) < linep;
    end; { LINE_EOLN }

    function LINE_C : char;
    begin
	if length(line) < linep then LINE_C := ' '
	else LINE_C := line[linep];
    end; { LINE_C }

    procedure LINE_GET;
    begin
	if length(line) < linep then read_line
	else linep := linep  +1;
    end; { LINE_GET }
	
    procedure LINE_error; 
    var I: integer;
    begin
	writeln;
	write(linecount:4,' ');
	for I := 1 to length(line) do
	    if classify(line[i]) = space then write (' ')
	    else write (line[i]);
	writeln;
	if linep > 0 then begin
	    if atom_line_p > 0 then writeln('     ','!':atom_line_p)
	    else 		    writeln('near ','!':linep);
	end;
    end; { LINE_error }

    procedure replace_GOSUB;
    var i,j,loc: integer;
    begin
	for i := 1 to atom_count do
	    with pool[current_buffer].table[i] do
		if nametype = n_header then if name = GOSUB_ID then begin
		    loc := 0;
		    for j := 1 to label_count do
			if EQ(long_name^,labels[j].name) then loc := j;

		    if loc = 0 then begin
			LINE_error;
			writeln('Error: GOSUB ',long_name^);
			writeln('       without LABEL ',long_name^);
			error_flag := true;
		    end else begin
			dispose(long_name);
			long_name := nil;
			nametype := n_gosub;
			name := labels[loc].loc;
		    end;
		end;
    end; { replace_GOSUB }

	  procedure write_comment; forward;

	  function read_comment: string_t;
             var bf: string_t; 
                 ok: boolean;
		 too_long: boolean;
	  begin
		write_debug('%read_comment');
		too_long := false;
                bf := LINE_C;
                if classify(LINE_C) <> comment then halt;
                LINE_GET; 
                ok := LINE_EOF;
                if not ok then
                   if LINE_EOLN then ok := true;

                while not ok do begin
                   if length(bf) >= string_length-2 then too_long := true 
                   else if classify(LINE_C) = space then bf := bf + ' '
                   else bf := bf + LINE_C;
                   LINE_GET;
                   ok := LINE_EOF;
                   if not ok then
                      if LINE_EOLN then ok := true;

                end;  
                if too_long then begin
		   error_flag := true;
		   LINE_error;
                   Writeln ('Error: Too long comment.');
                   Writeln ('       Limit comments to ',string_length-2:1,' characters.');
                end;
		read_comment := bf;
		write_debug('%read_comment = ',bf);
	  end; { read_comment }



          function atom:string_t;
          var a: string_t;                 

	
             function read_string: string_t;
             var bf: string_t; 
                 ok,detec: boolean;
		 too_long: boolean;
             begin
		write_debug('%read_string');
		too_long := false;
                bf := '';
                repeat
                   if classify(LINE_C) <> string_c then halt;
                   LINE_GET; 
                   ok := LINE_EOF;
                   if not ok then
                      if LINE_eoln then ok := true
                      else if classify (LINE_C) = string_c then ok := true
		      else if classify (LINE_C) = comment then begin
			write_comment;
			ok := true;
		      end;
                   while not ok do begin
                      if length(bf) >= string_length-2 then too_long := true
                      else if classify(LINE_C) = space then bf := bf + ' '
                      else bf := bf + LINE_C;
                      LINE_GET;
                      ok := LINE_EOF;
                      if not ok then
                         if LINE_EOLN then ok := true
                         else if classify (LINE_C) = string_c then ok := true;
                   end;  
                   if not(LINE_EOF) then LINE_GET;
                   if not(LINE_EOF) then if LINE_C = '&' then begin
                      LINE_GET;
                      detec := false;
                      repeat
                         if LINE_EOF then detec := true
                         else if LINE_EOLN then LINE_GET
                         else if classify(LINE_C) = space then LINE_GET
			 else if classify(LINE_C) = comment then begin
			    write_comment;
                         end else detec := true;
                      until detec;
                      if not(LINE_EOF) then 
                         if classify(LINE_C) = string_c then ok := false;
                   end;
                until ok;
                read_string := '"' + bf + '"';
                if too_long then begin
		   error_flag := true;
		   LINE_error;
                   writeln('Error: String constant is too long.');
                   writeln('       Limit it to ',string_length-2:1,' characters.');
                end;
		write_debug('%read_string = ','"' + bf + '"');
             end; { read_string }

             function read_letter: atom_t;
             var bf: string_t; 
                 ok: boolean;
             begin
		write_debug('%read_letter');
                bf := LINE_C;
                if classify(LINE_C) <> letter then halt;
                LINE_GET; 
                ok := LINE_EOF;
                if not ok then
                   if LINE_EOLN then ok := true
                   else ok := not (classify (LINE_C) in [letter, space ]);
                while not ok do begin
                   if length(bf) >= string_length-2 then { too_long := true }
                   else if classify(LINE_C) = space then bf := bf + ' '
                   else bf := bf + LINE_C;
                   LINE_GET;
                   ok := LINE_EOF;
                   if not ok then
                      if LINE_EOLN then ok := true
                      else ok := not (classify (LINE_C) in [letter, space ]);
                end;  
                if length(bf) <= atom_length then read_letter := bf 
                else begin
		   LINE_error;
                   Writeln ('Error: Too long symbol.');
                   Writeln ('       Limit symbols to ',atom_length:1,' characters.');
		   error_flag := true;
                   read_letter := substr(bf,1,atom_length)
                end;
		write_debug('%read_letter = ',bf);
             end; { read_letter }


      var ok : boolean;

      begin { atom }
	write_debug('%atom');
	atom_line_p := -1;
        ok := classify (LINE_C) <> space;
	if classify(LINE_C) = comment then begin
	    write_comment;
	    ok := LINE_EOF;
	end;
        while not ok do begin 
          LINE_GET;
          if LINE_EOF then ok := true
          else if classify (LINE_C) = comment then begin
	    write_comment;
	    ok := LINE_EOF;
	  end else ok :=  classify (LINE_C) <> space;
        end;
        
        atom := '';
        if not (LINE_EOF) then begin
	   atom_line_p := linep;
           case classify(LINE_C) of
              space: halt;
	      comment: halt;
              string_c: atom := read_string;
              bracket: begin
                 atom := LINE_C;
                 LINE_GET;
              end;
             letter: atom := clean_spaces(read_letter);
           end;
        end;
      end; { atom }

          procedure read_atom;	  
          begin
	    write_debug('%read_atom');
            if not atom_readed then begin
               if LINE_EOF then begin
		  LINE_error;
                  writeln('Error: END OF FILE detected');
		  error_flag := true;

                  goto 999
               end;
               current_atom := atom;
               if current_atom > '' then if current_atom [1] = '_' then begin
		  error_flag := true;
		  LINE_error;
                  writeln('Error: Symbol can''t start with _');

	       end;
            end;
	    write_debug('%read_atom : current_atom = ',current_atom);
            atom_readed := true
          end;

	  function search_atom: integer;
	  var i,j,loc: integer;
	    flag: boolean;
	  begin
	    loc := 0;
	    for i := 1 to atom_count -1 do
		if pool[current_buffer].table[atom_count].nametype =
		    pool[current_buffer].table[i].nametype  
		then if pool[current_buffer].table[atom_count].name =
		    pool[current_buffer].table[i].name 
		then if (pool[current_buffer].table[atom_count].long_name 
			= nil) =
		    (pool[current_buffer].table[i].long_name = nil) 
		then begin
		   if pool[current_buffer].table[i].long_name = nil then flag 
			:= true
		   else flag := 
		    EQ(pool[current_buffer].table[atom_count].long_name^,
			pool[current_buffer].table[i].long_name^);
		    { EQ: NonPadding comparison }

		    if flag then for j := 1 to max_param do
			if pool[current_buffer].table[atom_count].params[j] <>
			    pool[current_buffer].table[i].params[j] then
				flag := false;

		    if flag then loc := i;

		end;
	    
		if loc = 0 then search_atom := atom_count
		else begin
		    with pool[current_buffer].table [ atom_count ] do begin
			for i := 1 to max_param do params[i] := 0;
			    if long_name <> nil then dispose(long_name);
			long_name := nil;
			nametype := n_comment;
			name := 0;
		    end;
		    atom_count := atom_count -1;
		    search_atom := loc;
		end;
	  end;
            
          function put_atom (name:string_t; p1,p2,p3: integer := 0): integer;
          begin    
	    write_debug('%put_atom');
            if atom_count >= MAXATOM then begin
	       LINE_error;
               WriteLn ('Error: Too many atom in program.');
               WriteLn ('       Limit atom number to ',MAXATOM:1,
                       ' atoms.');
	       error_flag := true;
               goto 999
            end;
            atom_count := atom_count + 1;
	    pool[current_buffer].table[atom_count].params[1] := p1;
	    pool[current_buffer].table[atom_count].params[2] := p2;
	    pool[current_buffer].table[atom_count].params[3] := p3;
	    pool[current_buffer].table[atom_count].name := 0;
	    new(pool[current_buffer].table[atom_count].long_name);
            pool[current_buffer].table[atom_count].long_name^ := '!!!';

	    case name[1] of
		'_': begin
		    pool[current_buffer].table[atom_count].nametype  
			:= n_variable;

		    pool[current_buffer].table[atom_count].long_name^
			:= substr(name,2,length(name)-1);
		end;
		'"': begin
		    pool[current_buffer].table[atom_count].nametype  
			:= n_const;

		    pool[current_buffer].table[atom_count].long_name^      
			    := substr(name,2,length(name)-2);



		end;
		'!':  begin
		    pool[current_buffer].table[atom_count].nametype := n_comment;
		    pool[current_buffer].table[atom_count].long_name^ := name

		end;
		'-':  begin
		    pool[current_buffer].table[atom_count].nametype := n_head;
		    pool[current_buffer].table[atom_count].long_name^ := name

		end;
	    end; { case }

            put_atom := search_atom;
          end;

	  procedure write_comment;
	  begin
	    put_atom(read_comment);
	  end; { write_comment }

	  function put_atom_H(code:integer; params: paramtable; atom: string):
	    integer;
	  var i,count,result,loc: integer;
	  begin
	    write_debug('%put_atom_H');    
            if atom_count >= MAXATOM then begin
	       LINE_error;
               WriteLn ('Error: Too many atom in program.');
               WriteLn ('       Limit atom number to ',MAXATOM:1,
                       ' atoms.');
	       error_flag := true;
               goto 999
            end;
            atom_count := atom_count + 1;
	    pool[current_buffer].table[atom_count].name     := code;
	    pool[current_buffer].table[atom_count].nametype := n_header;
	    pool[current_buffer].table[atom_count].params   := params;
	    new(pool[current_buffer].table[atom_count].long_name);
	    pool[current_buffer].table[atom_count].long_name^     := atom;
	    if code = LABEL_ID then begin 
		if label_count >= max_labels then begin
		    LINE_error;
		    WriteLn ('Error: Too many LABELs in program.');
		    WriteLn ('       Limit label number to ',max_labels:1,
                       ' labels.');
		    error_flag := true;
		    goto 999
		end;
		loc := 0;
		for i := 1 to label_count do 
		    if EQ(labels[i].name,atom) then loc := i;
		if loc > 0 then begin
		    LINE_error;
		    writeln('Error: Dublicate LABEL ',atom);
		    error_flag := true;
		end;
		label_count := label_count +1;
		labels[label_count].name := atom;
		result := search_atom;
		labels[label_count].loc := result;
		put_atom_H := result;
	    end else put_atom_H := search_atom;;
	end; 

          function put_atom_2 (code:integer; params: paramtable): integer;
	  var i,count: integer;
          begin
	    write_debug('%put_atom_2');    
            if atom_count >= MAXATOM then begin
	       LINE_error;
               WriteLn ('Error: Too many atom in program.');
               WriteLn ('       Limit atom number to ',MAXATOM:1,
                       ' atoms.');
	       error_flag := true;
               goto 999
            end;
            atom_count := atom_count + 1;
	    pool[current_buffer].table[atom_count].name := code;
	    pool[current_buffer].table[atom_count].nametype := n_function;
	    pool[current_buffer].table[atom_count].params := params;
            put_atom_2 := search_atom;
          end;

	  function put_error(message: string_t): integer;
	  var params: paramtable;
	      counter: integer;
	  begin
	    for counter := 1 to max_param do params[counter] := 0;
	    params[1] := put_atom('"'+message+'"');
	    put_error := put_atom_2(ERROR_ID,params);
	    error_flag := true;

	  end; { put_error }  
	              
          function eval: integer;
          var params: paramtable;
	      counter: integer;   
              name,refer: string_t;
	      fcode: integer;
	      min,max:	integer;

	      function_type: name_type;

          begin 
	    write_debug('%eval');
	    for counter := 1 to max_param do params[counter] := 0;
	    counter := 0;
	    fcode := 0;
            read_atom;
            if current_atom = '-' then begin
		LINE_error;
		writeln ('Error: Parameter expected.');
		writeln ('       ''-'' detected.');
		eval := put_error ('Parameter expected.');

            end else if current_atom = ')' then begin
		LINE_error;
		writeln ('Error: Parameter expected.');
		writeln ('       '')'' detected.');
		eval := put_error ('Parameter expected.');

            end else if current_atom = ',' then begin
	       LINE_error;
               writeln ('Error: Parameter expected.');
               writeln ('       '','' detected.');
               eval := put_error ('Parameter expected.');

            end else begin   
               name := clean_spaces (current_atom);
               atom_readed := false;
               if name = '' then begin
		  LINE_error;
                  writeln ('Error: Empty parameter detected.');
                  writeln ('       Internal error or end of file.');
                  eval := put_error ('Empty parameter detected.');

               end else if (name = '(') or (name = ')') or 
		           (name = ',') or (name = '-') then begin
		    LINE_error;
		    writeln('Error: ''',name,''' detected.');
		    writeln('       Function, variable or string expected.');
		    error_flag := true;

		    if (name = '(') then begin
			atom_readed := false;
			eval := eval;
			if current_atom = ')' then atom_readed := false
			else begin
			    LINE_error;
			    writeln('Error: ''',current_atom,''' detected');
			    writeln('       '')''expected.');
			    error_flag := true;

			end;
		    end else eval := 
			put_error('Function, variable or string expected.');

	       end else begin    
                  if name[1] = '"' then 
                     eval := put_atom(name)
                  else begin
		     refer := '';

                     read_atom;
                     if current_atom <> '(' then 
                        eval := put_atom('_'+name)
                     else begin
			if length(name) > atom_length then begin
			    LINE_error;
			    writeln('Error: Too long function name.');
			    writeln('       Internal error.');
			    error_flag := true;

			    fcode := 0;
			    function_type := n_error;

			end else if exact_header (fcode,name) then begin
			    min := htable[fcode].min;
			    max := htable[fcode].max;
			    function_type := n_header;
			    refer := substr(name,length(htable[fcode].name)+1,
				    length(name)-length(htable[fcode].name));

			end else if exact_function(fcode,name) then begin
			    min := ftable[fcode].min;
			    max := ftable[fcode].max;
			    function_type := n_function;

			end else begin
			    LINE_error;
			    writeln ('Error: Unrecognized function: ',name);
			    writeln ('       Check validity and spelling.');
			    error_flag := true;
			    min := 0;
			    max := maxint;
			    fcode := 0;
			    function_type := n_error;

			end;
                        atom_readed := false;
                        
			read_atom;
			while (current_atom <> ')') and
			      (current_atom <> '-') and
			      (current_atom <> '') 
			  do begin
			    counter := counter +1;
			    if counter > max_param then
				eval
			    else params[counter] := eval;
			    if counter = max_param +1 then begin
				LINE_error;
				writeln('Error: Too many parameters');
				writeln('       at function ',name,'.');
				writeln('       Limit parameters to ',
				    max_param:1,'.');
				error_flag := true;

			    end; { if counter }
			    read_atom;
			    if current_atom = ')' then { ok }
			    else if current_atom = ',' then 
				atom_readed := false	{ ok }
			    else begin
				LINE_error;
				writeln ('Error: '')'' or '','' expected');
				writeln ('       ''',current_atom,''' detected.');
				writeln ('       at function ',name,'.');
				error_flag := true;

				if counter < max_param then begin
				    counter := counter +1;
				    params[counter] := put_error
				    	(''')'' or '','' expected.');
				end;
			
			    end;    { else }

			    read_atom;
			end;	{ while }
 
                        if current_atom = ')' then atom_readed := false
                        else begin
			    LINE_error;
			    writeln ('Error: '')'' expected');
			    writeln ('       at function ',name,'.');
			    error_flag := true;

			    if counter < max_param then begin
				counter := counter +1;
				params[counter] := put_error
				    (''')'' expected.');
			    end;

			end;	{ else }
			if count_params(params) < min then begin
			    LINE_error;
			    writeln('Error: Too few parameters');
			    writeln('       at function ',name,'.');
			    error_flag := true;

			    if counter < max_param then begin
				counter := counter +1;
				params[counter] := put_error(
				    'Too few parameters.');
			    end;

			end else if count_params(params) > max then begin
			    LINE_error;
			    writeln('Error: Too many parameters');
			    writeln('       at function ',name,'.');
			    error_flag := true;

			    if counter < max_param then begin
				counter := counter +1;
				params[counter] := put_error(
				    'Too many parameters.');
			    end;

			end;    { if }
			case function_type of
			    n_function: eval := put_atom_2 (fcode,params);
			    n_header: eval := put_atom_h (fcode,params,refer);
			    otherwise eval := put_error(
				'Unrecognized function: '+name);

			end;	{ else }
                     end;   { else }
                  end	{ else }
               end  { else }
            end	{ else }
          end;
        
	  procedure dump_buffer;
	  var count,num,i: integer;
	  begin 
	    rewrite(result);
	    with pool[current_buffer] do 		
	    	for count := 1 to atom_count do with table [ count ] do 
		begin
		used := count;
	        { --- }		
		case nametype of
		    n_comment: begin
			writeln(result,count:1,':0:0:0:',long_name^)
		    end;
		    n_head: begin
			writeln(result,count:1,':',params[1]:1,':0:0:-');
		    end;
		    n_const: begin
			write(result,count:1,':0:0:0:"');
			writeln(result,long_name^,'"');
		    end;
		    n_variable: begin
			writeln(result,count:1,':0:0:0:_',long_name^);
		    end;
		    n_gosub: begin
			num := count_params(params);
			write(result,'J',name:1,':',num:1);
			for i := 1 to num do write(result,':',params[i]:1);
			writeln(result);
		    end;
		    n_header: begin
			num := count_params(params);
			write(result,'H',name:1,':',num:1);
			for i := 1 to num do write(result,':',params[i]:1);
			writeln(result,':',long_name^);
		    end;
		    n_function: begin
			write(result,-count:1,':',params[1]:1,':',
			    params[2]:1,':',params[3]:1,':',name:1);
			num := count_params(params);
			if num <= 3 then writeln(result)
			else begin
			    write(result,':',num-3);
			    for i := 4 to num do write(result,':',params[i]:1);
			    writeln(result);
			end;
		    end;
		end; { case }
	    { ---- }
	    end;
	  end;
  
      begin { parse }
	write_debug('%parse');

	clear_program(current_buffer);
	reset (source);

	line := '';
	linecount := 0;
	linep := 1;
	read_line;

	error_flag := false;
        atom_readed := false;  
        atom_count := 0;
	label_count := 0;

        while not LINE_EOF do begin
           read_atom; if current_atom = '-' then atom_readed := false;
           put_atom ('-',eval);
           read_atom; if (current_atom = '(') or
              (current_atom = ')') or (current_atom=',') then begin
	      LINE_error;
              writeln('Error: ''',current_atom,''' detected as function start.');
	      writeln('       ''',current_atom,''' skipped.');
	      error_flag := true;

	      put_atom('-',
		 put_error(''''+current_atom+''' detected as function start.'));

	      atom_readed := false
           end;
        end;
	replace_GOSUB;
        999:
	if error_flag then begin
	    LINE_error;
	    writeln('FATAL: Error(s) occured. Code not produced.');
	    clear_program(current_buffer);
	end else dump_buffer;

        close(source);
end; { parse }
         
function alloc_buffer(program_number: integer): integer;
var i: integer;
    found: integer;
    biggest: integer;
begin
    write_debug('%alloc_buffer');
    found := 0;
    biggest := 1;
    for i := 1 to max_buffer do with pool[i] do begin
	if used > 0 then begin
	    if current_program = program_number then found := i;
	    if pool[biggest].time < time then biggest := i;
	    if time < maxint then time := time+1;
	end else if found = 0 then found := i;
    end; { for }
    if found = 0 then found := biggest;
    if debug then writeln('%alloc_buffer : result ',found:1);
    alloc_buffer := found;
end; { alloc buffer }
          
             
procedure read_program (var source: text; buffer: integer);
var ln,i,cn: integer;
       prms: paramtable;
       atom: string_t;           
       a,b,c,d: char;
       code: integer;
       code_index: integer;
       code_type:  name_type;
       dataline: boolean;
       linetype: char;
begin
    reset (source);
    with pool[buffer] do begin
	used := 0;
	time := 0;
	while not (eof(source)) do begin
	    for i := 1 to max_param do prms[i] := 0;
	    dataline := false;
	    linetype := ' ';
	    if eoln(source) then ln := 0
	    else if source^ in [ '0' .. '9' , ' ' , '-' ] then read (source,ln)
	    else if source^ = '!' then ln := 0
	    else begin
		ln := used +1;		{ default value - not check }
		read(source,linetype);
	    end;

	    if ln = 0 then readln(source)   { skip end of line }
	    else dataline := true;

	    code_index := 0;
	    code_type  := n_error;

	     if dataline then begin


		case linetype of

		    ' ':
		    begin 
			if ln > 0 then
			    readln(source,a,prms[1],b,prms[2],c,prms[3],d,atom)
			else begin
			    read(source,a,prms[1],b,prms[2],c,prms[3],d,code);
			    if eoln(source) then readln(source)
			    else begin
				read(source,a,cn);
				for i := 1 to cn do 
				    read(source,a,prms[i+3]);
				readln(source);
			    end;
			    { atom := ftable[name].name; }
			    code_index := code;
			    code_type  := n_function;
			    ln := -ln;
			end;
		
			{ koodin tunnistus }
			if code_index = 0 then begin
			    if atom[1] = '!' then begin
				code_type  := n_comment;
				code_index := 1;
			    end else if atom = '-' then begin
				code_type := n_head;
				code_index := 1;
				atom := '';
			    end else if atom[1] = '"' then begin
				code_type := n_const;
				code_index := 1;
				atom := substr(atom,2,length(atom)-2);
			    end else if atom[1] = '_' then begin
				code_type := n_variable;
				code_index := 1;
				atom := substr(atom,2,length(atom)-1);
			    end else if exact_header(code,atom) then begin
				code_type := n_header;
				code_index := code;
				atom := substr(atom,length(htable[code].name)+1,
				    length(atom)-length(htable[code].name));
			    end else if exact_function(code,atom) then begin
				code_type  := n_function;
				code_index := code;
				atom := '';
			    end else code_type := n_error;
			end else atom := '';
		    end;

		    'H':
		    begin
			code_type := n_header;
			read(source,code_index,a,cn);

			for i := 1 to cn do 
			    read(source,a,prms[i]);
			readln(source,a,atom);
		    end;

		    'J':
		    begin
			code_type := n_gosub;
			read(source,code_index,a,cn);

			for i := 1 to cn do 
			    read(source,a,prms[i]);
			readln(source);
			atom := '';
		    end;

		    otherwise begin
			writeln('%Bad program file #2. Notify Monster Manager.');
			halt;
		    end;

		end; { case }

		if ln <> used+1 then begin
		    writeln ('%Bad program file #1. Notify Monster Manager.');
		    halt
		end else if ln > MAXATOM then begin
		    writeln ('Error: Maximum number of atoms exceeded.');
		    halt
		end;

		used := ln;
		with table [ln] do begin
		    params := prms;
		    nametype := code_type;
		    name := code_index;
		    case code_type of 
			n_function,n_head,n_error,n_gosub: long_name := nil;
			n_header,n_variable,n_const,n_comment: begin
			    new(long_name);
			    long_name^ := atom;
			end;
		    end; { case }
		end
	    end; { if dataline }
	end; { while }
    end; { with }
    close(source)
end; { read_program }
                    
procedure print_program (buffer: integer;
			procedure print(l: string_t); len: integer := 80);
var line_i: string_t;
    i:    integer;

     procedure l_print(s: string_t);
     begin
	while length(s) > len do begin
	    print(substr(s,1,len));
	    s := substr(s,len+1,length(s)-len);
	end;
	print(s);
     end; { l_print }

     procedure put_atom (item,level: integer);

        procedure nice_print(c: string_t);
        var i,cut: integer;
            subline: string_t;
        begin
	    cut := terminal_line_len - 30;
	    if cut < 10 then cut := 10;

           if length(line_i) + length(c) < terminal_line_len -10 then
		line_i := line_i + c  
           else if c[1] = '"' then repeat
              if length(c) < cut + 5 then begin 
                 subline := c; c := '';
              end else begin
                 subline := substr(c,1,cut) + '"&';
                 c := '"' + substr(c,cut+1,length(c) -cut);
              end;
              l_print(line_i);
              line_i := '';
              for i := 1 to level do line_i := line_i + '   ';
              line_i := line_i + subline
           until c = '' else begin 
              l_print(line_i);
              line_i := '';
              for i := 1 to level do line_i := line_i + '   ';
              line_i := line_i + c
           end
        end; { nice_print }
         
    var atom_name : string_t;
	count,i,j: integer;

    begin with pool [buffer] do begin
	if item = 0 then nice_print('""')
        else with table[item] do begin
           if long_name = nil then atom_name := ''
           else atom_name := long_name^;

	   case nametype of 
		n_function: begin
		    if name = ERROR_ID then begin
			if line_i >'' then l_print(line_i);

			line_i := 'Error: ';
			put_atom(params[1],0);

			l_print(line_i);
			line_i := '';
		
		    end else begin
			nice_print(ftable[name].name);
			count := count_params(params);
			nice_print('(');
			for i := 1 to count do begin
			    put_atom(params[i],level+1);
			    if i <> count then begin
				nice_print(',');
				if count >= new_line_limit then begin
				    if line_i >'' then l_print(line_i);
				    line_i := '';
				    for j := 1 to level do line_i := line_i 
					+ '   ';
				end;
			    end;
			end; { for }
			nice_print(')')
		    end;
		end;
		n_header:    begin
		    nice_print(htable[name].name + atom_name);
		    count := count_params(params);
		    nice_print('(');
		    for i := 1 to count do begin
			put_atom(params[i],level+1);
			if i <> count then begin
			    nice_print(',');
			    if count >= new_line_limit then begin
				if line_i >'' then l_print(line_i);
				line_i := '';
				for j := 1 to level do line_i := line_i 
				    + '   ';
			    end;
			end;
		    end; { for }
		    nice_print(')')
		end;
		n_variable:  nice_print(atom_name);
		n_const:     nice_print('"' + atom_name + '"');
		n_comment:;
		n_head:	     begin
		    nice_print('- ');
		    put_atom(params[1],level+1)
		end;
		n_error: nice_print( '/' + atom_name + '/');
		n_gosub: begin
		    nice_print('GOSUB '+table[name].long_name^);
		    count := count_params(params);
		    nice_print('(');
		    for i := 1 to count do begin
			put_atom(params[i],level+1);
			if i <> count then begin
			    nice_print(',');
			    if count >= new_line_limit then begin
				if line_i >'' then l_print(line_i);
				line_i := '';
				for j := 1 to level do line_i := line_i 
				    + '   ';
			    end;
			end;
		    end; { for }
		    nice_print(')');
		end;
	   end; { case }
        end
    end; { with } end; { put_atom }

begin { print_program }
    with pool[buffer] do begin
	line_i := '';
	for i := 1 to used do if table [i].nametype = n_head then begin
	    if line_i >'' then l_print(line_i);
	    line_i := '';
	    print('');
	    put_atom(i,0)
	end else if table [i].nametype = n_comment then begin
	    if line_i >'' then l_print(line_i);
	    if table[i].long_name <> nil then line_i := table[i].long_name^
	    else line_i := '<error>';
	end;
	l_print(line_i);
    end; { with }
end; { print_program }
 

function exec_program (label_name: atom_t; monster: atom_t;
                          variable: atom_t := '' ; value: string_t := '';
			  buffer: integer; 
			  spell_name: atom_t := '';
			  summoner_name: atom_t := ''
                         ): boolean;
   
      label 1;               { minne hyp‰t‰‰n virheen sattuessa }
      
                  
      const EVENT_CHECK = 50; { tarkista tapahtumat joka 50 evaluointi }
             MAXEVAL = 500;    { Maksimi evaluointien lum‰‰r‰ }
             MAX_VARIABLE = 30;                    

      type charset = set of char;

      var eval_count: integer;
          var_count : 0 .. MAX_VARIABLE;   { very big variable using }
                                           { 30 kB                   }

          vars : array [ 1 .. MAX_VARIABLE ] of 
                   record
                      value: string_t;
                      name: atom_t
                   end;
   
                                                       
      function eval_atom(item: integer): string_t; forward;


      function goto_label(label_name: atom_t; var found: boolean): string_t;
      var i,position : integer;
         result: string_t;

      begin 
         write_debug ('%goto_label: ',label_name);
         label_name := clean_spaces (label_name);
         result := '';
         position := 0;
	 with pool[buffer] do begin
	    for i:= 1 to used do if table[i].nametype = n_header then
		    if table[i].name = 6 { LABEL } then
			if table[i].long_name^ = label_name then 
			    position := i;
	    if position > 0 then begin
		found := true; { t‰m‰ pit‰‰ olla ennen eval_atom:ia koska }
			    { sen suoritus voidaan keskeytt‰‰          }
		result := eval_atom(position);
	    end else begin
		found := false;
		error_counter := error_counter +1
	    end;
	 end; { with }
         write_debug ('%goto_label result: ',result);	
         goto_label := result
      end;
                                                        
      function eval_variable( variable: atom_t): string_t;             
      var i : integer;
          result: string_t;
      begin           
         write_debug('%eval_variable: ',variable);
         variable := clean_spaces(variable);
         result := '';                
         for i := 1 to var_count do if variable = vars [i].name then
            result := vars[i].value;
         write_debug('%eval_variable result: ',result);	
         eval_variable := result
      end; { eval variable }                            

      procedure set_variable ( variable: atom_t; value: string_t);
      var i,point : integer;
      begin           
        write_debug ('%set_variable: ',variable);
        write_debug ('%       value: ',value);
        variable := clean_spaces(variable);
        point := 0;                                         
        for i := 1 to var_count do if variable = vars [i].name then
           point := i;
        if point > 0 then vars[point].value := value
        else write_debug('%set variable - no variable');
      end; { eval variable }                                     

      procedure define_variable (variable: atom_t);    
      begin
         write_debug('%define_variable: ',variable);
         if var_count < MAX_VARIABLE then begin
            var_count := var_count +1;
            vars[var_count].value := '';
            vars[var_count].name := clean_spaces(variable)
         end
      end; { define_variable }               

      procedure strim(var s: string_t; a: string_t; raw: boolean := false);
      begin
	write_debug('%strim: ',s);
	write_debug('%     : ',a);
	if raw then write_debug('%      - raw mode');
	if (a > '') and (s > '') and not raw then 
	    if (a[1] in [ 'a'..'z', 'A'..'Z', '0'..'9', 
		    '.', ',', '?', ';', '!' ]) and
		not (s[length(s)] in [ '''', '"', ' ']) 
			    or 
		(s[length(s)] in [ 'a'..'z', 'A'..'Z', '0'..'9', 
		    '.', ',', '?', ';', '!' ]) and
		not (a[1] in [ '''', '"', ' ']) then
		    if length(s) < string_length then
			s := s + ' ';
	if length(s) + length(a) < string_length then
	    s := s + a;
	write_debug('%  -> : ',s);
      end;

      function e_plus (params: paramtable): string_t;
      var a,result: string_t;
	    i: integer;
      begin             
         write_debug('%e_plus');
	 result := '';
	 for i := 1 to count_params(params) do begin
	    a := eval_atom (params[i]);
	    write_debug('%e_eval - .. ',a);
	    strim (result,a);
	 end;
         write_debug ('%e_plus result: ',result);
         e_plus := result;
      end; { e_plus }       
     
      function cut_string ( var main: string_t; var index: integer;
                            chars: charset; max: integer): string_t;
      var start,i,upper: integer;
      begin
        write_debug ('%cut_string');
        start := index;
        if start + max <= length(main) then upper := start + max
        else upper := length(main);
        index := upper;
        for i := start to upper do if main [i] in chars then index := i;
        cut_string := substr(main,start,index-start+1);
        index := index+1       
      end; { cut_string }

      function meta_print(params: paramtable;
			     procedure print(s: string_t);
			     raw: boolean; 
			     len : integer := 80
			 ): string_t;
      var a: string_t;   
	  a1: string_t;
          base,i: integer;

	    procedure make_upper(var s: string_t);
	    var i: integer;
		upcase: boolean;
	    begin
		upcase := true;
		for i := 1 to length(s) do begin
		    if (s[i] in [ 'a' .. 'z' ]) and upcase then
			s[i] := chr(ord(s[i]) - ord('a') + ord('A'));
		    if s[i] in [ '.','?','!',':' ] then
			upcase := true
		    else if classify(s[i]) <> space then upcase := false;
		end;
	    end;

      begin   
        write_debug('%meta_print');
	if raw then write_debug('%           - raw_mode');
	a := '';
	for i := 1 to count_params(params) do begin
	    a1 := eval_atom(params[i]); 
	    write_debug('%meta_print - .. ',a1);
	    strim (a,a1,raw);
	end;
	if (a > '') and not raw then if length(a) < string_length then
	    if a[length(a)] in [ 'a' .. 'z', 'A' .. 'Z', '0' .. '9' ] then
		a := a + '.';
	if length(a) < string_length then a := a + ' ';
	if not raw then make_upper(a);

        base := 1;
        while base <= length(a) do
          print (cut_string(a,base, [ '.', ',', ' '], len-5 ));
        write_debug('%meta_print - result: ',a);
        meta_print := a;
      end; { meta_print }                 

      function e_pprint(params: paramtable; raw: boolean): string_t;

	    procedure print(s: string_t);
	    begin
		writeln(s);
	    end;

      begin   
        write_debug('%e_pprint');
        e_pprint := meta_print(params,print,raw,terminal_line_len);
      end; { e_pprint }                 

      function e_print(params:paramtable; raw: boolean): string_t;

	    procedure print(s: string_t);
	    begin
		int_broadcast(monster,s,false);
	    end;

      begin   
        write_debug('%e_print');
        e_print := meta_print(params,print,raw,80);
      end; { e_print }                 

      function e_oprint(params:paramtable; raw: boolean): string_t;

	    procedure print(s: string_t);
	    begin
		int_broadcast(monster,s,true);
	    end;

      begin   
        write_debug('%e_oprint');
        e_oprint := meta_print(params,print,raw,80);
      end; { e_oprint }                 

      function e_print_null (params: paramtable): string_t;

	    procedure print(s: string_t);
	    begin
	    end;

      begin   
        write_debug('%e_print');
        e_print_null := meta_print(params,print,false,132);
      end; { e_print }                 

      function e_if (p1,p2,p3: integer): string_t;
      var result: string_t;
      begin
        write_debug('%e_if');
        if eval_atom(p1) > '' then result := eval_atom(p2)
        else result := eval_atom(p3);
        write_debug('%e_if result: ',result);
        e_if := result
      end; { e_if }                         

      function e_inv: string_t;                       
      var result: string_t;
      begin                
        write_debug('%e_inv');
        result := int_inv (monster);
        write_debug('%e_inv result: ',result);
        e_inv := result;
      end; { e_inv }

      function e_pinv: string_t;
      var result: string_t;
      begin
        write_debug('%e_pinv');
        result := int_inv (myname);
        write_debug('%e_pinv result: ',result);
        e_pinv := result;
      end; { e_pinv }
      
                     
      procedure add_atom (var main:string_t; atom: atom_t);
      begin
        write_debug('%add_atom');
        if main = '' then main := atom
        else if length(main) + length (atom) < string_length -3 then
          main := main + ', ' + atom
      end; { add_atom }

      function meta_do (p1: integer;
			function action(atom: atom_t): atom_t
		       ): string_t;
      var list,result: string_t;
          atom: atom_t;
          index: integer;
      begin
         write_debug('%meta_do');
         list := eval_atom (p1);
         write_debug('%meta_do - param: ',list);
         index := 1;
         result := '';
         while index <= length(list) do
            begin
               atom := clean_spaces(cut_atom(list,index,','));
	       if atom > '' then atom := action(atom);
	       if atom > '' then add_atom(result,atom);
            end;
         write_debug('%meta_do result: ',result);
         meta_do := result
      end; { meta_do }

      function e_get_global_flag(p1: integer): string_t;
      var result: string;

	    function action(atom: atom_t): atom_t;
	    var value: INTEGER;
	    begin
		if lookup_flag(value,atom) then 
		    if read_global_flag(value) then action := 'TRUE'
		    else action := ''
		else action := '';
	    end;

      begin
         write_debug('%e_get_global_flag');
	 result := meta_do(p1,action);
         write_debug('%e_get_global_flag result: ',result);
         e_get_globaL_FLAG := result
      end; { e_get_get_global_flag }

     
      function e_get (p1: integer): string_t;
      var result: string_t;

	    function action(atom: atom_t): atom_t;
	    begin
		if int_get(monster,atom) then action := atom
		else action := '';
	    end;

      begin
         write_debug('%e_get');
	 result := meta_do(p1,action);
         write_debug('%e_get result: ',result);
         e_get := result
      end; { e_get }

      function e_pget (p1: integer): string_t;
      var result: string_t;

	    function action(atom: atom_t): atom_t;
	    begin
		if int_get(myname,atom) then action := atom
		else action := '';
	    end;

      begin
         write_debug('%e_pget');
         result := '';
         if privilegion then begin
	    result := meta_do(p1,action);
         end;
         write_debug('%e_pget result: ',result);
         e_pget := result
      end; { e_pget }                                    

      function list_include(list: string_t; atom: atom_t): boolean;
      var a: atom_t;
          i: integer;
          result: boolean;

      begin
         write_debug('%list_include');
         write_debug('%list_include - list: ',list);
         write_debug('%               atom: ',atom);
         result := false;
         i := 1;
         while i <= length(list) do begin
            a := clean_spaces(cut_atom(list,i,','));
            if a = atom then result := true;
         end;
         write_debug('%list_include - ready.');
         list_include := result;
      end; { list_include }

      function e_exclude(p1,p2: integer): string_t;
      var a1,a2,result: string_t;
          atom: atom_t;
          i: integer;

      begin
         write_debug('%e_exclude');
         result := '';
         a1 := eval_atom(p1);
         a2 := eval_atom(p2);
         write_debug('%e_and - p1: ',a1);
         write_debug('%      - p2: ',a2);
         i := 1;
         while i <= length(a1) do begin
            atom := clean_spaces(cut_atom(a1,i,','));
            if not list_include(a2,atom) then add_atom(result,atom);
         end;
         write_debug('%e_exclude - result: ',result);
         e_exclude := result;
      end; { e_exclude }

      function e_and (p1,p2: integer): string_t;
      var result,first,second: string_t;
          i: integer;
          atom: atom_t;
      begin
         write_debug('%e_and');
         result := '';
         first := eval_atom (p1);
         second := eval_atom (p2);
         write_debug('%e_and - p1: ',first);
         write_debug('%        p2: ',second);
         i := 1;
         while i <= length(first) do
            begin
               atom := clean_spaces(cut_atom(first,i,','));
               if list_include(second,atom) and not list_include(result,atom) then
                 add_atom(result,atom)
            end;
        write_debug('%e_and result: ',result);
        e_and := result
      end; { e_and }

      function e_or (p1,p2,p3: integer): string_t;
      var result: string_t;

	function action (atom: atom_t): atom_t;
	begin
	    if not list_include(result,atom) then add_atom(result,atom);
	    action := ''
	end;

      begin
	write_debug('%e_or');
	result := '';
	meta_do(p1,action);
	meta_do(p2,action);
	meta_do(p3,action);
        write_debug('%e_or result: ',result);
        e_or := result
      end; { e_and }
      
      function e_drop (p1: integer): string_t;
      var result: string_t;

	    function action(atom: atom_t): atom_t;
	    begin
		if int_drop(monster,atom) then action := atom
		else action := '';
	    end;

      begin
         write_debug('%e_drop');
	 result := meta_do(p1,action);
         write_debug('%e_drop result: ',result);
         e_drop := result
      end; { e_drop }
                
      function e_pdrop (p1: integer): string_t;
      var result: string_t;

	    function action(atom: atom_t): atom_t;
	    begin
		if int_drop(myname,atom) then action := atom
		else action := '';
	    end;

      begin
         write_debug('%e_pdrop');
	 result := '';
         if privilegion then begin                    
	    result := meta_do(p1,action);
         end;
         write_debug('%e_pdrop result: ',result);
         e_pdrop := result
      end; { e_pdrop }

      function e_duplicate (p1: integer): string_t;
      var result: string_t;
          owner: atom_t;
          priv: boolean;

	    function action(atom: atom_t): atom_t;
	    begin
                if int_duplicate (monster,atom,owner,priv) then action := atom
	        else action := '';
	    end;

      begin
         write_debug('%e_duplicate');
         owner := x_monster_owner(pool[buffer].current_program);
         priv := int_ask_privilege(monster,'owner') or 
		system_code or spell_mode;
	 result := meta_do(p1,action);
         write_debug('%e_duplicate result: ',result);
         e_duplicate := result
      end; { e_duplicate }
                
      function e_pduplicate (p1: integer): string_t;
      var result: string_t;
          owner: atom_t;
          priv: boolean;

	    function action(atom: atom_t): atom_t;
	    begin
                if int_duplicate (myname,atom,owner,priv) then action := atom
	        else action := '';
	    end;

      begin
         write_debug('%e_pduplicate');
         owner := x_monster_owner(pool[buffer].current_program);
         priv := int_ask_privilege(monster,'owner') or 
	    system_code or spell_mode;
         result := '';
         if privilegion then begin
	    result := meta_do(p1,action);
         end;
         write_debug('%e_pduplicate result: ',result);
         e_pduplicate := result
      end; { e_pduplicate }

      function e_destroy (p1: integer): string_t;
      var result: string_t;
          owner: atom_t;
          priv: boolean;

	    function action(atom: atom_t): atom_t;
	    begin
                if int_destroy (monster,atom,owner,priv) then action := atom
	        else action := '';
	    end;


      begin
         write_debug('%e_destroy');
         owner := x_monster_owner(pool[buffer].current_program);
         priv := int_ask_privilege(monster,'owner') or 
	    system_code or spell_mode;
         result := meta_do (p1,action);
         write_debug('%e_destroy result: ',result);
         e_destroy := result
      end; { e_destroy }
                
      function e_pdestroy (p1: integer): string_t;
      var result: string_t;
          owner: atom_t;
          priv: boolean;

	    function action(atom: atom_t): atom_t;
	    begin
                if int_destroy (myname,atom,owner,priv) then action := atom
	        else action := '';
	    end;

      begin
         write_debug('%e_pdestroy');
         owner := x_monster_owner(pool[buffer].current_program);
         priv := int_ask_privilege(monster,'owner') or 
	    system_code or spell_mode;
         result := '';
         if privilegion then begin
	    result := meta_do(p1,action);
         end;
         write_debug('%e_pdestroy result: ',result);
         e_pdestroy := result
      end; { e_pdestroy }

      function e_move (p1: integer): string_t;
      var result, line_i: string_t;
      begin
         write_debug('%e_move');
         line_i := eval_atom (p1);
         write_debug('%e_move - p1: ',line_i);
         if length(line_i) > atom_length then 
            line_i := substr(line_i,1,atom_length);
         if int_poof(monster,line_i,x_monster_owner(pool[buffer].current_program),
            int_ask_privilege(monster,'poof')
	    or system_code or spell_mode,privilegion) then result := line_i
         else result := '';
         write_debug('%e_move result: ',result);
         e_move := result
      end; { e_move }

      function e_pmove (p1: integer): string_t;
      var result, line_i: string_t;
      begin
         write_debug ('%e_pmove');
         line_i := eval_atom (p1);
         write_debug('%e_pmove - p1: ',line_i);
         if length(line_i) > atom_length then 
            line_i := substr(line_i,1,atom_length);
         if int_poof(myname,line_i,x_monster_owner(pool[buffer].current_program),
            int_ask_privilege(monster,'poof')
	    or system_code or spell_mode,privilegion) then result := line_i
         else result := '';
         write_debug('%e_pmove result: ',result);
         e_pmove := result
      end; { e_pmove }

      function e_players: string_t;
      var result: string_t;
      begin
        write_debug('%e_players');
        result := int_players (monster);
        write_debug('%e_players result: ',result);
        e_players := result
      end; { e_players }                    


      function e_objects: string_t;
      var result: string_t;
      begin
        write_debug('%e_objects');
        result := int_objects (monster);
        write_debug('%e_objects result: ',result);
        e_objects := result
      end; { e_onjects }

      function e_remote_objects(p1: integer): string_t;
      var result,a1: string_t;
      begin
         write_debug('%e_remote_objects');
         a1 := eval_atom(p1);
         write_debug('%e_remote_objects - p1: ',a1);
         if length (a1) > atom_length then
            line_i := substr(a1,1,atom_length);
         result := int_remote_objects (a1);
         write_debug('%e_objects result: ',result);
         e_remote_objects := result
      end; { e_remote_objects }
                          
      function e_remote_players(p1: integer): string_t;
      var result,a1: string_t;
      begin
         write_debug('%e_remote_players');
         a1 := eval_atom(p1);
         write_debug('%e_remote_players - p1: ',a1);
         if length (a1) > atom_length then
            a1 := substr(a1,1,atom_length);
         result := int_remote_players (a1);
         write_debug('%e_remote_players - result: ',result);
         e_remote_players := result
      end; { e_remote_players }
                          
      function e_where(p1: integer): atom_t;
      var line_i,result: string_t;
      begin
        write_debug('%e_where');
        line_i := eval_atom (p1);
        write_debug('%e_where - p1: ',line_i);
        if length (line_i) > atom_length then
           line_i := substr(line_i,1,atom_length);
        result := int_where (line_i);
        write_debug('%e_where result: ',result);
        e_where := result;
      end; { e_where }                                   

      function e_equal(p1,p2: integer): string_t;
      var a,b: string_t;
      begin
        write_debug('%e_equal');
        a := eval_atom (p1);
        b := eval_atom (p2);
        write_debug('%e_equal - p1: ',a);
        write_debug('%          p2: ',b);
        if a = b then e_equal := a
        else e_equal := '';
        write_debug ('%e_equal leaving');
      end; { e_equal }

      function e_equal2(p1,p2: integer): string_t;
      var a,b: string_t;
      begin
        write_debug('%e_equal2');
        a := eval_atom (p1);
        b := eval_atom (p2);
        write_debug('%e_equal - p1: ',a);
        write_debug('%          p2: ',b);
        if EQ (a,b) then e_equal2 := a
        else e_equal2 := '';
        write_debug ('%e_equal2 leaving');
      end; { e_equal }

      function e_equal3(p1,p2: integer): string_t;
      var a,b: string_t;
      begin
        write_debug('%e_equal3');
        a := lowcase(clean_spaces(eval_atom (p1)));
        b := lowcase(clean_spaces(eval_atom (p2)));
        write_debug('%e_equal - p1: ',a);
        write_debug('%          p2: ',b);
        if a = b then e_equal3 := a
        else e_equal3 := '';
        write_debug ('%e_equal2 leaving');
      end; { e_equal }

      function e_null(params: paramtable): string_t;
      var i,count: integer;
      begin
        write_debug('%e_null');
	count := count_params(params);
	for i := 1 to count do eval_atom(params[i]);
        write_debug('%e_null leaving');
        e_null := ''
      end; { e_null }                             

      function e_attack(p1: integer): string_t;
      var a,result: string_t;
          value : integer;
	  left  : integer;
      begin
        write_debug('%e_attack');
	left := attack_limit - used_attack;
        a := eval_atom (p1);
        write_debug('%e_attack - p1: ',a);  
        readv(a,value,error:=continue);
	if left <= 0 then result := ''
        else if statusv <> 0 then result := ''
        else if value < 0 then result := ''
        else if not privilegion and 
		(attack_limit = maxint) then result := ''   
        else begin
	    if debug then writeln('%e_attack - power left: ',left:1);
	    if value > left then value := left;
	    if int_attack(myname,value) then begin 
		writev(result,value:1);
		used_attack := used_attack + value;
	    end else result := '';
	    if debug then writeln('%e_attack - used power: ',used_attack:1);
	end;
        write_debug('%e_attack - result: ',result);
        e_attack := result;
      end; { e_attack }

      function e_not(p1: integer): string_t;
      var a: string_t;
          value : integer;
      begin
        write_debug('%e_not');
        a := eval_atom (p1);
        write_debug('%e_not - p1: ',a);  
        if a > '' then e_not := ''
        else e_not := 'TRUE';
        write_debug('%e_not leaving');
      end; { e_not }

      function e_random(p1: integer): string_t;
      const max_item = 100;
      var a,result: string_t;
          table: array [1 .. max_item] of atom_t;
          count: integer;
          value: integer;

	function action(atom: atom_t): atom_t;	{ meta_do ei kutsu t‰t‰	}
	begin					{ kun atom = ''		}
	    table[count] := atom;
	    count := count +1;
	    action := '';
	end;

      begin
         write_debug('%e_random');
         result := '';
         count := 1;
	 meta_do(p1,action);
         count := count -1;
         if count > 0 then 
            begin
               value := trunc (random * count) + 1;
               if debug then writeln ('%e_random - value: ',value);
               result := table [value];
            end;
         write_debug('%e_random result: ',result);
         e_random := result;
      end; { e_random }

      function e_strip(p1: integer): string_t;
      var a,result: string_t;
          index: integer;
          value: integer;
      begin
         write_debug('%e_strip');
         a := eval_atom (p1);
         write_debug('%e_strip - p1: ',a);
         result := '';
         for index := 1 to length(a) do begin
             if (a[index] >= 'A') and (a[index] <= 'Z') then 
                result := result + chr(ord(a[index]) - ord('A') + ord('a'))
             else if (a[index] >= 'a') and (a[index] <= 'z') then
                result := result + a[index]
             else if a[index] in ['0'..'9'] then
                result := result + a[index]
             else result := result + ' ';
         end;
         { result := clean_spaces(result); }
         write_debug('%e_strip result: ',result);
         e_strip := result;
      end; { e_strip }

      function e_control(p1,p2: integer): string_t;
      var name,result: string_t;
          code: integer;
          old_monster: atom_t;
      begin
         old_monster := monster;
         write_debug('%e_control');
         name := eval_atom(p1);
         write_debug('%e_control - p1: ',name);
         if length(name) > atom_length then
            name := substr(name,1,atom_length);
         if name = '' then result := '' 
         else begin
            code := int_get_code(name);
            if code = 0 then result := ''
            else if (x_monster_owner(pool[buffer].current_program) <> 
			x_monster_owner(code) ) 
		    and not int_ask_privilege(monster,'manager') 
		    and not system_code then 
		result := ''
            else if x_get_flag(code,CF_NO_CONTROL) then begin
		result := '';
		write_debug('%e_control - control disabled.');
	    end else if int_login(name,false) <> 1 then { mark running }
		result := ''	     { monster is already active }
	    else begin
               monster := name;
               set_variable('monster name',monster);
               result := eval_atom(p2);
               int_logout(name);
            end;
         end;
         monster := old_monster;
         set_variable('monster name',monster);
         write_debug('%e_control - result: ',result);
         e_control := result;
      end; { e_control }

      function e_experience(p1: integer): string_t;
      var name,result: string_t;
          exp: integer;
      begin
         write_debug('%e_experience');
         name := eval_atom(p1);
         write_debug('%e_experience - p1: ',name);
         if length(name) > atom_length then
            name := substr(name,1,atom_length);
         if name = '' then result := '' 
         else begin
            exp := int_get_experience(name);
            if exp = -1 then result := ''
            else writev(result,exp:1);
         end;
         write_debug('%e_experience - result: ',result);
         e_experience := result;
      end; { e_experience }

      function e_health(p1: integer): string_t;
      var name,result: string_t;
          hel: integer;
      begin
         write_debug('%e_health');
         name := eval_atom(p1);
         write_debug('%e_health - p1: ',name);
         if length(name) > atom_length then
            name := substr(name,1,atom_length);
         if name = '' then result := '' 
         else begin
            hel := int_get_health(name);
            if hel = -1 then result := ''
            else writev(result,hel:1);
         end;
         write_debug('%e_health - result: ',result);
         e_health := result;
      end; { e_health }

      function eval_number(param: integer; var result: integer): boolean;
      var str: string_t;
      begin
         write_debug('%eval_number');
         result := 0;
         str := eval_atom(param);
         write_debug('%eval_number - param: ',str);
         if str = '' then eval_number := false
         else begin
            readv(str,result,error := continue);
            if statusv = 0 then eval_number := true
            else begin
               result := 0;
               eval_number := false
            end;
         end;
      end; { eval_number }

      function e_plus_n(p1,p2: integer): string_t;
      var result: string_t;
          a1,a2: integer;
      begin
        write_debug('%e_plus_n');
        result := '';
        if eval_number(p1,a1) and eval_number(p2,a2) then begin
           if abs((a1 div 3) + (a1 div 3)) > ((maxint div 3)-1) then
              result := ''
           else writev(result,a1+a2:1);
        end;                            
        write_debug('%e_plus_n - result: ',result);
        e_plus_n := result;
      end; { e_plus_n }

      function e_difference_n(p1,p2: integer): string_t;
      var result: string_t;
          a1,a2: integer;
      begin
        write_debug('%e_difference_n');
        result := '';
        if eval_number(p1,a1) and eval_number(p2,a2) then begin
           if abs((a1 div 3) - (a1 div 3)) > ((maxint div 3)-1) then
              result := ''
           else writev(result,a1-a2:1);
        end;                            
        write_debug('%e_difference_n - result: ',result);
        e_difference_n := result;
      end; { e_difference_n }

      function e_times_n(p1,p2: integer): string_t;
      var result: string_t;
          a1,a2: integer;
      begin
        write_debug('%e_times_n');
        result := '';
        if eval_number(p1,a1) and eval_number(p2,a2) then begin
           if ln(abs(a1)) + ln(abs(a2)) > (ln(maxint)-1) then result := ''
           else writev(result,a1*a2:1);
        end;                            
        write_debug('%e_times_n - result: ',result);
        e_times_n := result;
      end; { e_times_n }

      function e_quotient_n(p1,p2: integer): string_t;
      var result: string_t;
          a1,a2: integer;
      begin
        write_debug('%e_quotient_n');
        result := '';
        if eval_number(p1,a1) and eval_number(p2,a2) then begin
           if a2 <> 0 then writev(result,a1 div a2:1);
        end;                            
        write_debug('%e_quotient_n - result: ',result);
        e_quotient_n := result;
      end; { e_quotient_n }

      function e_set_experience(p1: integer): string_t;
      var result: string_t;
          exp: integer;
          owner,owner2: atom_t;
      begin
        write_debug('%e_set_experience');
        result := '';
        owner  := x_monster_owner(pool[buffer].current_program); { get owner of this }
        owner2 := x_monster_owner(pool[buffer].current_program,1); { and code owner }
        if eval_number(p1,exp) and 
           (  (int_ask_privilege(monster,'experience') and 
              (userid <> owner) and (userid <> owner2)) 
	      or system_code	{ system override check }
           ) then
           if exp >= 0 then
              if int_set_experience(myname,exp) then writev(result,exp:1);
        write_debug('%e_set_experience - result: ',result);
        e_set_experience := result;
      end; { e_set_experience }

      function e_get_state: string_t;
      var result: string_t;
      begin
         write_debug ('%e_get_state');
         getheader(pool[buffer].current_program);
         freeheader;
         result := header.state;
         write_debug ('%e_get_state - result: ',result);
         e_get_state := result;
      end; { e_get_state }

      function e_set_state(p1: integer): string_t;
      var a: string_t;
      begin
         write_debug('%e_set_state');
         a := eval_atom(p1);
         write_debug('%e_set_state - p1: ',a);
         getheader(pool[buffer].current_program);
         header.state := a;
         putheader;   
         write_debug('e_set_state - result: ',a);
         e_set_state := a;
      end; { e_set_state }

      function e_get_remote_state(p1: integer): string_t;
      var result: string_t;
          a1: string_t;
          code: integer;
	  pub: atom_t;
      begin
	 if not lookup_class(pub,'public') then
	    writeln('%error in e_get_remote_state');
         write_debug ('%e_get_remote_state');
         a1 := eval_atom(p1);
         write_debug ('%e_get_remote_state - p1: ',a1);
         if length(a1) > atom_length then a1 := substr(a1,1,atom_length);
         code := int_get_code(a1);
         if code = 0 then result := ''
         else if (x_monster_owner(code) <> 
		x_monster_owner(pool[buffer].current_program))
	    and ((x_monster_owner(code) <> pub) or 
		 not int_ask_privilege(monster,'owner')) 
	    and not system_code then result := ''
         else begin
            getheader(code);
            freeheader;
            result := header.state;
         end;
         write_debug ('%e_get_remote_state - result: ',result);
         e_get_remote_state := result;
      end; { e_get_remote_state }

      function e_set_remote_state(p1,p2: integer): string_t;
      var result: string_t;
          a1,a2: string_t;
          code: integer;
	  pub: atom_t;
      begin
         write_debug ('%e_set_remote_state');
	 if not lookup_class(pub,'public') then
	    writeln('%error in e_set_remote_state');

         a1 := eval_atom(p1);
         a2 := eval_atom(p2);
         write_debug ('%e_set_remote_state - p1: ',a1);
         write_debug ('%                     p2: ',a2);
         if length(a1) > atom_length then a1 := substr(a1,1,atom_length);
         code := int_get_code(a1);
         if code = 0 then result := ''
         else if (x_monster_owner(code) <> 
		x_monster_owner(pool[buffer].current_program))
	    and ((x_monster_owner(code) <> pub) or 
		not int_ask_privilege(monster,'owner')) 
	    and not system_code then result := ''
         else begin
            getheader(code);
            header.state := a2;
            putheader;
            result := a2;
         end;
         write_debug ('%e_set_remote_state - result: ',result);
         e_set_remote_state := result;
      end; { e_set_remote_state }

      function e_less_n(p1,p2: integer): atom_t;
      var result: atom_t;
          a1,a2: integer;
      begin
        write_debug('%e_less_n');
        result := '';
        if eval_number(p1,a1) and eval_number(p2,a2) then begin
           if a1 < a2 then result := 'TRUE';
        end;                            
        write_debug('%e_less_n - result: ',result);
        e_less_n := result;
      end; { e_less_n }

      function e_number_n(p1: integer): string_t;
      var result: string_t;
          a1: integer;
      begin
        write_debug('%e_number_n');
        result := '';
        if eval_number(p1,a1) then writev(result,a1:1);
        write_debug('%e_number_n - result: ',result);
        e_number_n := result;
      end; { e_number_n }

      function e_heal(p1: integer): string_t;
      var result: string_t;
         a1: integer;
      begin
         write_debug('%e_heal');
         result := '';
         if eval_number(p1,a1) and privilegion then
            if a1 >= 0 then
               if int_heal(myname,a1) then writev(result,a1:1);
         write_debug('%e_heal - result: ',result);
         e_heal := result;
      end; { e_heal }

      function e_all_players: string_t;
      var result: string_t;
      begin
         write_debug('%e_all_players');
         result := int_l_player;
         write_debug('%e_all_players - result: ',result);
         e_all_players := result;
      end;


      function e_all_objects: string_t;
      var result: string_t;
      begin
         write_debug('%e_all_objects');
         result := int_l_object;
         write_debug('%e_all_objects - result: ',result);
         e_all_objects := result;
      end;

      function e_all_rooms: string_t;
      var result: string_t;
      begin
         write_debug('%e_all_rooms');
         result := int_l_room;
         write_debug('%e_all_rooms - result: ',result);
         e_all_rooms := result;
      end; 

      function e_include(p1,p2: integer): string_t;
      var a1,a2,result: string_t;
      begin
         write_debug('%e_include');
         a1 := eval_atom(p1);
         a2 := eval_atom(p2);
         write_debug('%e_include - p1: ',a1);
         write_debug('%            p2: ',a2);
         if index(a1,a2) >0 then result := a2
         else result := '';
         write_debug('%e_include - result: ',result);
         e_include := result;
      end; { e_include }

      function e_string_head(p1: integer; c: char): string_t;
      var a1,result: string_t;
          i: integer;
      begin
         write_debug('%e_string_head');
         a1 := eval_atom(p1);
         write_debug('%e_string_head - p1: ',a1);
	 write_debug('%                char: ',c);
         i := index(a1,c);
         if i = 0 then i := length(a1)+1;
         result := substr(a1,1,i-1);
         write_debug('%string_head - result: ',result);
         e_string_head := result;
      end; { e_string_head }

      function e_string_tail(p1: integer; c: char): string_t;
      var a1,result: string_t;
          i,n: integer;
      begin
         write_debug('%e_string_tail');
         a1 := eval_atom(p1);
         write_debug('%e_string_tail - p1: ',a1);
	 write_debug('%                char: ',c);
         i := index(a1,c);
         if i = 0 then i := length(a1)+1;
         n := length(a1) - i;
         if n <= 0 then result := ''
         else result := substr(a1,i+1,n);
         write_debug('%string_tail - result: ',result);
         e_string_tail := result;
      end; { e_string_tail }

      function e_lookup_player (p1: integer): string_t;
      var result: string_t;
      begin
         write_debug('%e_lookup_player');
	 result := meta_do(p1,int_lookup_player);
         write_debug('%e_lookup_player result: ',result);
         e_lookup_player := result
      end; { e_lookup_player }

      function e_lookup_object (p1: integer): string_t;
      var result: string_t;
      begin
         write_debug('%e_lookup_object');
	 result := meta_do(p1,int_lookup_object);
         write_debug('%e_lookup_player result: ',result);
         e_lookup_object := result
      end; { e_lookup_object }

      function e_lookup_room (p1: integer): string_t;
      var list,result: string_t;
          atom,fill: atom_t;
          index: integer;
      begin
         write_debug('%e_lookup_room');
	 result := meta_do(p1,int_lookup_room);
         write_debug('%e_lookup_room result: ',result);
         e_lookup_room := result
      end; { e_lookup_room }

      function e_lookup_direction (p1: integer): string_t;
      var list,result: string_t;
          atom,fill: atom_t;
          index: integer;
      begin
         write_debug('%e_lookup_direction');
	 result := meta_do(p1,int_lookup_direction);
         write_debug('%e_lookup_direction result: ',result);
         e_lookup_direction := result
      end; { e_lookup_direction }

    function same_room(player: atom_t): boolean;
    var room: atom_t;
    begin
	write_debug('%same_room: ',player);
	room := int_where(player);
	same_room := 
	    (int_where(myname) = room) or
	    (int_where(monster) = room);
    end; { same_room }
	    
      function e_submit(p1,p2: integer; label_name: atom_t): string_l;
      var r2,result: string_l;
          r1: integer;
      begin
         write_debug('%e_submit');
         write_debug('%e_submit - label_name:',label_name);
         if eval_number(p1,r1) then begin
            r2 := eval_atom(p2);
            write_debug('%e_submit - p2: ',r2);
            if length (r2) > atom_length then 
               r2 := substr(r2,1,atom_length);
            if not same_room (r2) and
               not int_ask_privilege(monster,'manager') and
	       not system_code then
               result := ''
            else if send_submit(monster,
		pool[buffer].current_program,label_name,r1,r2) then
               writev(result,r1:1)
            else result := '';           
         end else result := '';
         write_debug('%e_submit - result:',result);
         e_submit := result;
      end; { e_submit }

      function e_privilege (p1,p2: integer): string_t;
      var result,name: string_t;

	function action(atom: atom_t): atom_t;
	begin
	    if int_ask_privilege(name,atom) then action := atom
	    else action := '';
	end;

      begin
         write_debug('%e_privilege');
         name := eval_atom (p1);
         write_debug('%e_privilege - p1: ',name);
	 result := meta_do(p2,action);
         write_debug('%e_privilege result: ',result);
         e_privilege := result
      end; { e_privilege }

      function e_parse_player(p1: integer): string_t;
      var list,result: string_t;

	    function action(s: atom_t; id: integer): boolean;
	    begin
		add_atom(result,s);
		action := true;
	    end;

	    function undo(id: integer): boolean;
	    begin undo := true; end;

      begin
	    write_debug('%e_parse_player');
	    list := eval_atom(p1);
	    write_debug('%e_parse_player - p1: ',list);
	    result := '';
	    scan_pers(action,list,TRUE,undo);
	    write_debug('%e_parse_player result: ',result);
	    e_parse_player := result;
      end; { e_parse_player }

      function e_parse_object(p1: integer):string_t;
      var list,result: string_t;

	    function action(s: atom_t; id: integer): boolean;
	    begin
		add_atom(result,s);
		action := true;
	    end;

	    function undo(id: integer): boolean;
	    begin undo := true; end;

      begin
	    write_debug('%e_parse_object');
	    list := eval_atom(p1);
	    write_debug('%e_parse_object - p1: ',list);
	    result := '';
	    scan_obj(action,list,TRUE,undo);
	    write_debug('%e_parse_object result: ',result);
	    e_parse_object := result;
      end; { e_parse_object }

      function e_parse_room(p1: integer):string_t; 
      var list,result: string_t;

	    function action(s: atom_t; id: integer): boolean;
	    begin
		add_atom(result,s);
		action := true;
	    end;

	    function undo(id: integer): boolean;
	    begin undo := true; end;

      begin
	    write_debug('%e_parse_room');
	    list := eval_atom(p1);
	    write_debug('%e_parse_room - p1: ',list);
	    result := '';
	    scan_room(action,list,TRUE,undo);
	    write_debug('%e_parse_room result: ',result);
	    e_parse_room := result;
      end; { e_parse_room }

    function e_for(variable: atom_t; p1,p2: integer): string_t;
    var result: string_t;

	function action(atom: atom_t): atom_t;
	begin
	    set_variable(variable,atom);
	    if eval_atom(p2) > '' then action := atom
	    else action := '';
	end;

    begin
	write_debug('%e_for');
	write_debug('%e_for - variable: ',variable);
	define_variable(variable);
	result := meta_do(p1,action);
	write_debug('%e_for result: ',result);
	e_for := result;
    end; { e_for }
	
    function e_userid (p1: integer): string_t;
    var result: string_t;
    begin
	write_debug('%e_userid');
        result := '';
        if int_ask_privilege(monster,'experience') or system_code then
	    result := meta_do(p1,int_userid);
        write_debug('%e_userid result: ',result);
        e_userid := result
    end; { e_userid }

    function e_list(params: paramtable): string_t;
    var result: string_t;
	i: integer;

	function action(atom: atom_t): atom_t;
	begin
	    add_atom(result,atom);
	    action := '';
	end;

    begin
	write_debug('%e_list');
	result := '';
	for i := 1 to count_params(params) do 
	    meta_do(params[i],action);
	write_debug('%e_list result: ',result);
	e_list := result;
    end;

    function e_mattack(p1,p2: integer):string_t;
    var a,result: string_t;
	b: integer;
	manager: boolean;
    begin
	write_debug('%e_mattack');
	a := eval_atom(p1);
	write_debug('%e_mattack - p1: ',a);
	manager := int_ask_privilege(monster,'manager') or system_code;
	if length(a) > atom_length then a := substr(a,1,atom_length);
	if (int_get_code(a) = 0) or 
	    not privilegion or
	    ( not same_room(a) and
	      not manager )
	    then result := ''
	else if not eval_number(p2,b) then result := ''
	else if b < 0 then result := ''
	else if not int_attack(a,b) then result := ''
	else writev(result,b:1);
	write_debug('%e_mattack result : ',result);
	e_mattack := result
    end; { e_mattack }
	    
    function e_mheal(p1,p2: integer):string_t;
    var a,result: string_t;
	b,code: integer;
	manager: boolean;
    begin
	write_debug('%e_mheal');
	a := eval_atom(p1);
	write_debug('%e_mheal - p1: ',a);
	manager := int_ask_privilege(monster,'manager') or system_code;
	if length(a) > atom_length then a := substr(a,1,atom_length);
	code := int_get_code(a);
	if (code = 0) or
	    not privilegion or
	    ((code = pool[buffer].current_program) and 
	      not manager
	    ) or 
	    ( not same_room(a) and
	      not manager
	    ) then result := ''
	else if not eval_number(p2,b) then result := ''
	else if b < 0 then result := ''
	else if not int_heal(a,b) then result := ''
	else writev(result,b:1);
	write_debug('%e_mheal result : ',result);
	e_mheal := result
    end; { e_mheal }

    function e_prog(params: paramtable): string_t;
    var i: integer;
	result : string_t;
    begin
	write_debug('%e_prog');
	result := '';
	for i := 1 to count_params(params) do result := eval_atom(params[i]);
	write_debug('%e_prog result : ',result);
	e_prog := result;
    end; { e_prog }

    function e_spell_level: string_t;
    var lev: integer;
	result : string_t;
    begin
	write_debug('%e_spell_level');
	if spell_name = '' then result := ''
        else begin
	    lev := int_spell_level(summoner_name,spell_name);
	    if lev = -1 then result := ''
	    else writev(result,lev:1);
	end;
	write_debug('%e_spell_level result : ',result);
	e_spell_level := result;
    end; { e_spell_level }

    function e_set_spell_level(p: integer): string_t;
    var lev: integer;
	result : string_t;
    begin
	write_debug('%e_set_spell_level');
	if spell_name = '' then result := ''
	else if not eval_number(p,lev) then result := ''
	else if lev < 0 then result := ''
        else if not int_set_spell_level(summoner_name,spell_name,lev) then result := ''
	else  writev(result,lev:1);
	write_debug('%e_set_spell_level result : ',result);
	e_set_spell_level := result;
    end; { e_set_spell_level }


      {	    
      function eval_function (name: atom_t; params: paramtable): string_t;
      var result: string_t;
          found: boolean;
	  r1,r2,r3: string_t;
	  p1,p2,p3: integer;
      begin
         write_debug('%eval_function: ',name);
	 p1 := params[1];
	 p2 := params[2];
	 p3 := params[3];
         result := '';
         if name = '+' then result := e_plus(params)
         else if name = '=' then result := e_equal(p1,p2)
         else if name = 'inv' then result := e_inv
         else if name = 'pinv' then result := e_pinv
         else if name = 'players' then result := e_players
         else if name = 'objects' then result := e_objects
         else if name = 'get' then result := e_get (p1)
         else if name = 'pget' then result := e_pget (p1)
         else if name = 'drop' then result := e_drop (p1)
         else if name = 'pdrop' then result := e_pdrop (p1)
         else if name = 'and' then result := e_and (p1,p2)
         else if name = 'or' then result := e_or (p1,p2,p3)
         else if name = 'move' then result := e_move (p1)
         else if name = 'pmove' then result := e_pmove (p1)
         else if name = 'pprint' then result := e_pprint (params,false)
         else if name = 'print' then result := e_print (params,false)
         else if name = 'oprint' then result := e_oprint (params,false)
         else if name = 'pprint raw' then result := e_pprint (params,true)
         else if name = 'print raw' then result := e_print (params,true)
         else if name = 'oprint raw' then result := e_oprint (params,true)
         else if name = 'print null' then result := e_print_null (params)
         else if name = 'if' then result := e_if (p1,p2,p3)
         else if name = 'where' then result := e_where (p1)
         else if name = 'null' then result := e_null (params)
         else if name = 'attack' then result := e_attack (p1)
         else if name = 'heal' then result := e_heal (p1)
         else if name = 'not' then result := e_not (p1)
         else if name = 'random' then result := e_random (p1)
         else if name = 'strip' then result := e_strip(p1)
         else if name = 'experience' then result := e_experience(p1)
         else if name = 'plus' then result := e_plus_n(p1,p2)
         else if name = 'difference' then result := e_difference_n(p1,p2)
         else if name = 'times' then result := e_times_n(p1,p2)
         else if name = 'quotient' then result := e_quotient_n(p1,p2)
         else if name = 'set experience' then result := e_set_experience(p1)
         else if name = 'get state' then result := e_get_state
         else if name = 'set state' then result := e_set_state(p1)
         else if name = 'less' then result := e_less_n(p1,p2)
         else if name = 'number' then result := e_number_n(p1)
         else if name = 'health' then result := e_health(p1)

         else if name = 'all objects' then result := e_all_objects
         else if name = 'all rooms' then result := e_all_rooms
         else if name = 'all players' then result := e_all_players 

         else if name = 'control' then result := e_control(p1,p2)
         else if name = 'include' then result := e_include(p1,p2)
         else if name = 'exclude' then result := e_exclude(p1,p2)
         else if name = 'get remote state' then 
            result := e_get_remote_state(p1)
         else if name = 'set remote state' then
            result := e_set_remote_state(p1,p2)
         else if name = 'remote players' then result := e_remote_players(p1)
         else if name = 'remote objects' then result := e_remote_objects(p1)

         else if name = 'duplicate'  then result := e_duplicate(p1)
         else if name = 'pduplicate' then result := e_pduplicate(p1)
         else if name = 'destroy'    then result := e_destroy(p1)
         else if name = 'pdestroy'   then result := e_pdestroy(p1)
         else if name = 'string head' then result := e_string_head(p1,' ')
         else if name = 'string tail' then result := e_string_tail(p1,' ')
         else if name = 'head' then result := e_string_head(p1,',')
         else if name = 'tail' then result := e_string_tail(p1,',')
         else if name = 'lookup object' then result := e_lookup_object(p1)
         else if name = 'lookup player' then result := e_lookup_player(p1)
         else if name = 'lookup room' then result := e_lookup_room(p1)
	 else if name = 'privilege' then result := e_privilege(p1,p2)
	 else if name = 'parse player' then result := e_parse_player(p1)
	 else if name = 'parse object' then result := e_parse_object(p1)
	 else if name = 'parse room' then result   := e_parse_room(p1)
	 else if name = 'userid' then result       := e_userid(p1)
	 else if name = 'list' then result	   := e_list(params)
	 else if name = 'mattack' then result      := e_mattack(p1,p2)
	 else if name = 'mheal' then result        := e_mheal(p1,p2)

         else if index(name,'SUBMIT ') = 1 then
            if length(name) > 7 then begin 
               result := e_submit(p1,p2,substr(name,8,length(name)-7));
            end else begin
                 result := '';
                 error_counter := error_counter +1
            end      
         else if index(name,'FOR ') = 1 then
            if length(name) > 4 then begin 
               result := e_for(substr(name,5,length(name)-4),p1,p2);
            end else begin
                 result := '';
                 error_counter := error_counter +1
            end      
         else if index(name,'GOSUB ') = 1 then           
            if length(name) > 6 then begin
               r1 := eval_atom(p1);
               r2 := eval_atom(p2);
               r3 := eval_atom(p3);
               define_variable('p1');
               define_variable('p2');
               define_variable('p3');
               set_variable('p1',r1);
               set_variable('p2',r2);
               set_variable('p3',r3);
		
               result := goto_label (substr(name,7,length(name)-6),found)
            end else begin
                 result := '';
                 error_counter := error_counter +1
            end      
         else if index(name,'DEFINE ') = 1 then begin
            if length(name) > 7 then
               define_variable (substr(name,8,length(name)-7))
            else begin
                 result := '';
                 error_counter := error_counter +1
            end;
            result := eval_atom(p1)
         end else if index(name,'SET ') = 1 then begin
            result := eval_atom(p1);
            if length(name) > 4 then
              set_variable (substr(name,5,length(name)-4),result)
            else begin
                 result := '';
                 error_counter := error_counter +1
            end
         end else if index(name,'LABEL ') = 1 then
            result := eval_atom(p1)
         else begin
                 result := '';
                 error_counter := error_counter +1
            end;
         write_debug('%eval_function result: ',result);
         if debug then writeln('%                  ec: ',error_counter:1);
         eval_function:= clean_spaces (result);
      end;
      }

    function eval_function (name: integer; params: paramtable): string_t;
    var result: string_t;
	found: boolean;
	r1,r2,r3: string_t;
	p1,p2,p3: integer;
    begin
	write_debug('%eval_function: ',ftable[name].name);
	p1 := params[1];
	p2 := params[2];
	p3 := params[3];
	result := '';
	case name of
	    1: { + }	result := e_plus(params);
	    2: { = }	result := e_equal2(p1,p2);
	    3: { inv }	result := e_inv;
	    4: { pinv }	result := e_pinv;
	    5: { players }  result := e_players;
	    6: { objects }  result := e_objects;
	    7: { get }	result	:= e_get (p1);
	    8: { pget } result	:= e_pget (p1);
	    9: { drop } result	:= e_drop (p1);
	    10: { pdrop }   result := e_pdrop (p1);
	    11: { and } result	:= e_and (p1,p2);
	    12: { or }	result := e_or (p1,p2,p3);
	    13: { move }    result := e_move (p1);
	    14: { pmove }   result := e_pmove (p1);
	    15: { pprint }  result := e_pprint (params,false);
	    16: { print }   result := e_print (params,false);
	    17: { oprint }  result := e_oprint (params,false);
	    18: { pprint raw }	result := e_pprint (params,true);
	    19: { print raw }	result := e_print (params,true);
	    20: { oprint raw }	result := e_oprint (params,true);
	    21: { print null }	result := e_print_null (params);
	    22: {if }	result := e_if (p1,p2,p3);
	    23: { where }   result := e_where (p1);
	    24: { null }    result := e_null (params);
	    25: { attack }  result := e_attack (p1);
	    26: { heal }    result := e_heal (p1);
	    27: { not }	    result := e_not (p1);
	    28: { random }  result := e_random (p1);
	    29: { strip }   result := e_strip(p1);
	    30: { experience }	    result := e_experience(p1);
	    31: { plus }	    result := e_plus_n(p1,p2);
	    32: { difference }	    result := e_difference_n(p1,p2);
	    33: { times }	    result := e_times_n(p1,p2);
	    34: { quotient }	    result := e_quotient_n(p1,p2);
	    35: { set experience }  result := e_set_experience(p1);
	    36: { get state }	    result := e_get_state;
	    37: { set state }	    result := e_set_state(p1);
	    38: { less }	    result := e_less_n(p1,p2);
	    39: { number }	    result := e_number_n(p1);
	    40: { health }	    result := e_health(p1);

	    41: { all objects }	    result := e_all_objects;
	    42: { all rooms }	    result := e_all_rooms;
	    43: { all players }	    result := e_all_players;

	    44: { control }	    result := e_control(p1,p2);
	    69: { include }	    result := e_include(p1,p2);
	    45: { exclude }	    result := e_exclude(p1,p2);
	    46: { get remote state } 
		result := e_get_remote_state(p1);
	    47: { set remote state }
		result := e_set_remote_state(p1,p2);
	    48: { remote players }  result := e_remote_players(p1);
	    49: { remote objects }  result := e_remote_objects(p1);

	    50: { duplicate }	result := e_duplicate(p1);
	    51: { pduplicate }	result := e_pduplicate(p1);
	    52: { destroy }	result := e_destroy(p1);
	    53: { pdestroy }	result := e_pdestroy(p1);
	    54: { string head }	result := e_string_head(p1,' ');
	    55: { string tail }	result := e_string_tail(p1,' ');
	    56: { head }	result := e_string_head(p1,',');
	    57: { tail }	result := e_string_tail(p1,',');
	    58: { lookup object }   result := e_lookup_object(p1);
	    59: { lookup player }   result := e_lookup_player(p1);
	    60: { lookup room }	result := e_lookup_room(p1);
	    61: { privilege }	result := e_privilege(p1,p2);
	    62: { parse player }    result := e_parse_player(p1);
	    63: { parse object }    result := e_parse_object(p1);
	    64: { parse room }	    result := e_parse_room(p1);
	    65: { userid }	    result := e_userid(p1);
	    66: { list }	    result := e_list(params);
	    67: { mattack }	    result := e_mattack(p1,p2);
	    68: { mheal }	    result := e_mheal(p1,p2);
	    ERROR_ID: { -ERROR- }  begin
		result := '';
		error_counter := error_counter +1;
	    end;
	    71: { lookup direction } result := e_lookup_direction(p1);
	    72: { prog } result := e_prog (params);
	    73: { get global flag } result := e_get_global_flag(p1);
	    74: { == } result := e_equal(p1,p2);
	    75: { === } result := e_equal3(p1,p2);
	    76: { spell level } result := e_spell_level;
	    77: { set spell level } result := e_set_spell_level(p1);
	end; { case }

	write_debug('%eval_function result: ',result);
	if debug then writeln('%                  ec: ',error_counter:1);
	eval_function:= clean_spaces (result);
    end; { eval_function }
      
    function eval_header(code: integer; par: atom_t; params: paramtable): 
	string_t;
    var	result: string_t;
	 found: boolean;
	 r: array [ 1 .. max_param] of string_t;
	 p1,p2,p3,i,n: integer;
	 temp: atom_t;
    begin
	 write_debug('%eval_header: ',htable[code].name);
	 write_debug('%           : ',par);
	 p1 := params[1];
	 p2 := params[2];
	 p3 := params[3];
	 result := '';
	case(code) of
	    1: { SUBMIT } result := e_submit(p1,p2,par);
	    2: { FOR }	result := e_for(par,p1,p2);
	    3: { GOSUB  } begin
		for i := 1 to max_param do r[i] := '';
		n := count_params(params);
		for i := 1 to n do r[i] := eval_atom(params[i]);
		define_variable('p1');
		define_variable('p2');
		define_variable('p3');
		for i := 4 to n do begin
		    writev(temp,'p',i:1);
		    define_variable(temp);
		end;
		set_variable('p1',r[1]);
		set_variable('p2',r[2]);
		set_variable('p3',r[3]);
		for i := 4 to n do begin
		    writev(temp,'p',i:1);
		    set_variable(temp,r[i]);
		end;
		result := goto_label (par,found)
            end;
	    4: { DEFINE } begin
		define_variable (par);
		result := eval_atom(p1);
	    end;
	    5: { SET } begin
		result := eval_atom(p1);
		set_variable (par,result);
            end;
	    6: { LABEL  } result := e_prog (params);
	end; { case }
	write_debug('%eval_header result: ',result);
	if debug then writeln('%                  ec: ',error_counter:1);
	eval_header:= clean_spaces (result);
      end;
      
	function eval_gosub(address: integer; params: paramtable): string_t;
	var result: string_t;
	    temp: atom_t;
	    r: array [ 1 .. max_param] of string_t;
	    i,n: integer;
	begin
	    if debug then writeln('%eval_gosub: ',address:1);
	    for i := 1 to max_param do r[i] := '';
	    n := count_params(params);
		for i := 1 to n do r[i] := eval_atom(params[i]);
		define_variable('p1');
		define_variable('p2');
		define_variable('p3');
		for i := 4 to n do begin
		    writev(temp,'p',i:1);
		    define_variable(temp);
		end;
		set_variable('p1',r[1]);
		set_variable('p2',r[2]);
		set_variable('p3',r[3]);
		for i := 4 to n do begin
		    writev(temp,'p',i:1);
		    set_variable(temp,r[i]);
		end;
		result := eval_atom(address);
		write_debug('%eval_gosub result: ',result);
		eval_gosub := clean_spaces (result);
	end; { eval_gosub }
                               
      function eval_atom; { (item: integer): string_t; }
      var bf: string_t;                               

         var_pointer: integer;

         procedure eval_step;                               
         begin
            write_debug('%eval_step');
            eval_count := eval_count +1;
            if eval_count mod event_check = 0 then checkevents(true);
            if eval_count >= MAXEVAL then begin            
               WriteLn ('Error in monster code - out of time.');
               goto 1
            end
         end; { eval_step }

      begin
         write_debug('%eval_atom ENTER');
         var_pointer := var_count; 
         eval_step;
         if item = 0 then eval_atom := ''
         else with pool[buffer].table[item] do begin
	    {
            if long_name=nil then atom_name := name
            else atom_name := long_name^;
            if atom_name = '' then eval_atom := ''
            else if atom_name = '-' then 
               eval_atom := eval_atom(params[1])
            else if atom_name[1] = '"' then 
               eval_atom := clean_spaces
		    (substr(atom_name,2,length(atom_name)-2))
            else if atom_name[1] = '_' then 

               eval_atom := eval_variable(substr(atom_name,2,
                  length(atom_name)-1))
            else eval_atom := clean_spaces(eval_function (atom_name,params)); 
	    }
	    case nametype of 
		n_function: eval_atom := eval_function(name,params);
		n_header:   eval_atom := eval_header(name,long_name^,params);
		n_variable: eval_atom := eval_variable(long_name^);
		n_gosub:    eval_atom := eval_gosub(name,params);
		n_const:    eval_atom := long_name^;
		otherwise error_counter := error_counter +1;
	    end;
         end;                     
         var_count := var_pointer; { remove all inner variables }
         write_debug('%eval_atom LEAVE');
      end; { eval_atom }
   
   var result: string_t;
       found: boolean;
   begin { exec_program }
     write_debug('%exec_program');
     eval_count := 0;
     var_count := 0;
  
     { ennaltam‰‰ritelt‰v‰t muuttujat: }
     define_variable ('monster name');
     set_variable ('monster name',monster);
     define_variable ('player name');
     set_variable ('player name',myname);

     if variable > '' then begin
        define_variable(variable);
        set_variable(variable,value)
     end;

     if spell_name > '' then begin
	define_variable('spell name');
	set_variable('spell name',spell_name);
	define_variable('summoner name');
	set_variable('summoner name',summoner_name);
     end;

     result := goto_label (label_name,found);
     1: 
     exec_program := found
end; { exec program }

{ file_name moved to module DATABASE }

[global]
function current_run: integer;
begin
  if not code_running then current_run := 0
  else current_run := pool[current_buffer].current_program;
end; { current_run }

[global]
function monster_runnable(code: integer): boolean;
begin
   getheader(code);
   freeheader;
   monster_runnable := header.runnable;
end;


[global] 
function monster_owner  (code: integer; class : integer := 0): atom_t;
begin  
  write_debug ('%monster_owner');
  getheader(code);
  freeheader;
  case class of
    0: monster_owner := header.owner;
    1: monster_owner := header.author;
  end; { case }
end; { monster_owner }

function x_monster_owner { (code: integer; class : integer := 0): atom_t };
begin
  x_monster_owner := monster_owner(code,class);
end; { x_monster_owner }


[global] 
procedure set_owner (code: integer; class : integer := 0; owner: atom_t);
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
procedure set_runnable(code: integer; value: boolean);
begin
  getheader(code);
  header.runnable := value;
  putheader
end;

[global]
procedure monsterpriv(code: integer);
var priv: boolean;
begin
  getheader(code);
  priv := not header.priv;
  header.priv := priv;
  putheader;
  if priv then writeln ('Monster/Hook is now privileged.')
  else writeln ('Monster/Hook is no longer privileged.');
end;

[global]
procedure set_flag(code: integer; flag: integer; turn_on: boolean);
var bit,old: unsigned;
begin
  write_debug('%set_flag');
  bit := flagtable[flag].value;
  getheader(code);
  old := uint(header.flags);
  if turn_on then header.flags := int(uor(old,bit))
  else  header.flags := int(uand(old,unot(bit)));
  putheader;
  if turn_on and (old <> uint(header.flags)) then
    writeln(flagtable[flag].on);
  if (not turn_on) and (old <> uint(header.flags)) then
    writeln(flagtable[flag].off);
end;

[global]
function get_flag(code: integer; flag: integer): boolean;
var bit: unsigned;
begin
  write_debug('%get_flag');
  bit := flagtable[flag].value;
  getheader(code);
  freeheader;
  get_flag := uand(bit,uint(header.flags)) > 0;

end;

function x_get_flag { (code: integer; flag: integer): boolean };
begin
    x_get_flag := get_flag(code,flag);
end;


[global]
procedure view_monster(code: integer);
var i: integer;
    pub,dis: atom_t;
    flag_typed: boolean;
    value: string_l;

begin

    flag_typed := false;
    if not lookup_class(pub,'public') then
	writeln('%error #1 in view monster');
    if not lookup_class(dis,'disowned') then
	writeln('%error #2 in view monster');


  getheader(code);
  freeheader;

  writeln ('Monster/Hook statistics:');
  writeln;
  if header.owner = pub  then
    writeln ('Monster/Hook is public')
  else if header.owner = dis then
    writeln ('Monster/Hook is disowned')
  else writeln ('Owner:          ',class_out(header.owner));
  writeln ('Creation time:  ',header.ctime);
  if header.author <> '' then     
     writeln ('Author:         ',class_out(header.author)); 
  if header.wtime <> '' then
     writeln ('Load time:      ',header.wtime);  

  if header.running_id > '' then
    writeln ('Running under:  ',header.running_id);
  if header.runnable then writeln ('Code is runnable')
  else writeln ('Code is blocked');
  if header.priv then 
     writeln ('Monster/Hook is privileged');
    for i := 1 to max_flag do begin
	if uand (uint(header.flags),flagtable[i].value) > 0 then 
	    value := flagtable[i].on
	else value := flagtable[i].off;
	if value > '' then begin
	    if not flag_typed then writeln('Flags: ',value)
	    else                   writeln('       ',value);
	    flag_typed := true;
	end;
    end;

  writeln;                                    
  writeln ('Label             Run num.    Error count   Last run');
  for i := 1 to statmax do if header.stats[i].lab > '' then 
     with header.stats[i] do 
        writeln (substr(lab+'                ',1,17),
                 runcount:4,'        ',
                 errorcount:4,'          ',
                 lastrun);
  writeln
end;


[global]
function run_monster (monster_name: atom_t;
                      code: integer;
                      label_name: atom_t;
                      variable: atom_t;
                      value: string_t;
                      time: atom_t;
		      spell: atom_t := '';
		      summoner: atom_t := '' ): boolean;
label 1;
var o_file: text;
    i,count,lb,temp: integer;
    ok: boolean;
    health,errorcode: integer;
    sys: atom_t;
begin                            
    run_monster := false;   { default value for error situation }
   
    write_debug ('%run_monster.');
    if not lookup_class(sys,'system') then 
	writeln('%error in run_monster');
    if not code_running then begin
	code_running := true;
	getheader(code);
	freeheader;
	health := int_get_health(monster_name); { -1 = not monster }
	if debug then writeln('%run_monster - health: ',health); 
	if header.runnable and (health <> 0) then begin
	    current_buffer := alloc_buffer(code);

	    with pool[current_buffer] do begin  

		{ ladataan monsterin koodi }
		if (current_program <> code) or 
		    (current_version <> header.version) then begin
		    if current_program <> 0 then clear_program (current_buffer);
		    current_program := 0;

		    count := 0;   
		    repeat
			getheader(code);
			if header.interlocker > '' then begin
			    freeheader;
			    write_debug ('%locking in run_monster');
			    count := count +1 ;
			    wait (1); { wait a second }
			    if count > 10 then begin
				if debug then begin
				    writeln ('%deadlock in run_monster.');
				    writeln ('%deadlock will be ignored.');
				end;
				getheader(code);
				header.interlocker := '';
			    end;
			end;
		    until header.interlocker = '';
		    header.interlocker := userid;
		    putheader;
    
		    open(o_file,file_name(code),old,error:=continue,
			RECORD_LENGTH := string_length + 20);
		    errorcode := status(o_file);
		    if errorcode > 0 then begin
			writeln ('%code file read failure in run_monster - possible deadlock.');
			writeln ('% Error code (status): ',errorcode:1);
			writeln ('% Notify monster manager.');
			

			getheader(code);
			header.interlocker := '';
			putheader;

			goto 1
		    end;
		    read_program (o_file,current_buffer);
 		    current_program := code;
              
		    getheader(code);
		    header.interlocker := '';
		    putheader;              
		    current_version := header.version;
		end;
	    end; { with pool }

        ok := false;
        i := 0;
        while not ok and (i < 10) do
          case int_login(monster_name,false) of
              0: begin
                 writeln ('%serious error in run_monster. Notify Monster Manager.');
                 writeln ('% bad monster name');
                 goto 1
              end;
              1: ok := true;
              2,3: begin            { odotetetaan edllisen valmistumista }
                i := i+1;
                 wait(1);
                 checkevents(true)
              end;
              otherwise begin
                 writeln ('%serious error in run_monster. Notify Monster Manager.');
                 writeln ('% bad return from int_login');

                 goto 1
              end;
          end; { case }
         if not ok then 
            case int_login(monster_name,true) of  { k‰ynistet‰‰n pakolla }
               0: begin
                  writeln ('%serious error in run_monster. Notify Monster Manager.');
                  writeln ('% bad monster name');

                  goto 1
               end;
               1: ok := true;
               3: ok := false;                { k‰‰k }
               otherwise begin  
                  writeln ('%serious error in run_monster. Notify Monster Manager.');
                  writeln ('% bad return from int_login');

                  goto 1
               end;
            end; { case }

         if ok then begin

            getheader(code);
            header.running_id := userid;
      
            lb := 0;
            for i := 1 to statmax do if header.stats[i].lab = '' then lb := i;
            for i := 1 to statmax do 
               if header.stats[i].lab = label_name then lb := i;

            if lb = 0 then begin
                        lb := 1;
                        header.stats[lb].lab := label_name;
                        header.stats[lb].errorcount := 0;
                        header.stats[lb].runcount := 1
            end else if header.stats[lb].lab = '' then begin
                        header.stats[lb].lab := label_name;
                        header.stats[lb].errorcount := 0;
                        header.stats[lb].runcount := 1
            end else if header.stats[lb].runcount < MaxInt then
	       header.stats[lb].runcount := header.stats[lb].runcount +1;
	    system_code := header.owner = sys;
            privilegion := header.priv or system_code;
            putheader;
	    
	    spell_mode := get_flag(code,CF_SPELL_MODE);

            error_counter := 0;
	    used_attack   := 0;

	    temp := int_get_experience(monster_name);
	    if temp = -1 then begin
		monster_level := 0;
		attack_limit  := maxint;
	    end else begin 
		monster_level := level(temp);
		attack_limit  := leveltable[monster_level].maxpower;
	    end;
	    if system_code then attack_limit := MaxInt;

	    if debug then begin
		writeln('%run_monster - monster_level ',monster_level:1);
		writeln('%run_monster - attack_limit  ',attack_limit:1);
	    end;
            
            run_monster := exec_program (label_name,monster_name,
		variable,value,current_buffer,spell,summoner);

            getheader(code);
            header.running_id := '';
            if header.stats[lb].errorcount < MaxInt - error_counter then
               header.stats[lb].errorcount := header.stats[lb].errorcount +
                  error_counter
            else header.stats[lb].errorcount := MaxInt;
            header.stats[lb].lastrun := time;
            putheader;
                                                          
           int_logout(monster_name)
        end else run_monster := false;
     end else run_monster := false;   { if not header.runnable }
     code_running := false;
  end else run_monster := false; { re_entrance }
  1:
end; { run monster }

[global]                             
procedure list_program(code: integer;
                       procedure print(l: string_t); len: integer := 80);
label 1;
var o_file: text;
    count,errorcode: integer;
begin 
    write_debug('%list_program.');
    getheader(code);
    freeheader;

    current_buffer := alloc_buffer(code);
    with pool [current_buffer] do begin
	{ ladataan monsterin koodi }
	if (current_program <> code) or 
	    (header.version <> current_version) then begin
	    if current_program <> 0 then clear_program (current_buffer);
	    current_program := 0;

	    count := 0;   
	    repeat
		getheader(code);
		if header.interlocker > '' then begin
		    freeheader;
		    write_debug ('%locking in list_program');
		    count := count +1 ;
		    wait (1); { wait a second }
		    if count > 10 then begin
			if debug then begin
			    writeln ('%deadlock in list_program.');
			    writeln ('%deadlock will be ignored.');
			end;
			getheader(code);
			header.interlocker := '';
		    end;
		end;
	    until header.interlocker = '';
	    header.interlocker := userid;
	    putheader;
   
	    open(o_file,file_name(code),history := READONLY,
		sharing := READONLY,error:=continue, 
		record_length := string_length +20);
	    errorcode := status(o_file);
	    if errorcode > 0 then begin
		writeln ('%code file read failure in list_program.');
		writeln ('%Try later. Error code (status): ',errorcode:1);

		getheader(code);
		header.interlocker := '';
		putheader;

		goto 1
	    end;
	    read_program (o_file,current_buffer);
	    current_program := code;
              
	    getheader(code);
	    header.interlocker := '';
	    putheader;              
	    current_version := header.version;
	end;

	print_program (current_buffer,print,len);
    end; { with }
    1:
end; { list_program }

type medium_t = varying [ 80 ] of char;
                      
[global]
procedure load (code: integer; source: string_l;
                time: atom_t; 
                author: atom_t;
		def : string_l := '.MDL');

label 1;
var o_file,s_file: text;
    count,i,errorcode,s_errorcode: integer;
begin
    write_debug('%load');
	open(s_file,source,old,error := continue,
	    record_length := string_length +20,
	    default := def );
	s_errorcode := status(s_file);
	if s_errorcode <= 0 then begin  
	    count := 0;   
	    repeat 
		getheader(code);
		if header.interlocker > '' then begin
		    freeheader;
		    write_debug ('%locking in load');
		    count := count +1 ;
		    wait (1);
		    if count > 10 then begin
			if debug then begin
			    writeln ('%Deadlock in load. Deadlock will be ignored.');
			end;
			getheader(code);
			header.interlocker := '';
		    end; { count > 10 }
		end;
	    until header.interlocker = '';
	    header.interlocker := author;
	    header.author := author;
	    header.wtime := time;
	    putheader;      
	    if header.priv then writeln('Monster/Hook is no longer privileged.');

	    open(o_file,file_name(code),old,SHARING := NONE,ERROR := CONTINUE,
		record_length := string_length +20);
	    errorcode := status(o_file);
	    if errorcode > 0 then begin
		writeln ('%Can''t open code file. Try later.');
		writeln ('% It''s really deadlocked.');
		writeln ('% Error code (status): ',errorcode:1);

		getheader(code);
		header.interlocker := '';
		putheader;
       
		close(s_file);
		goto 1
	    end;  

	    current_buffer := alloc_buffer(code);
	    parse (s_file,o_file);
                                                       
	    getheader(code);
	    header.version := (header.version +1) mod 100000;
	    header.interlocker := '';
	    header.runnable := TRUE;
	    header.priv := FALSE;
	    for i := 1 to statmax do header.stats[i].lab := '';
	    for i := 1 to statmax do header.stats[i].runcount := 0;
	    for i := 1 to statmax do header.stats[i].errorcount := 0;
	    for i := 1 to statmax do header.stats[i].lastrun := '';
	    putheader;

	1:
	end else case s_errorcode of
	    3: { PAS$K_FILNOTFOU } writeln('Error: File not found.');
	    4: { PAS$K_INVFILSYN } writeln('Error: Illegal file name.');
	    otherwise writeln('Error: (status) ',s_errorcode:1);
	end; { case }
end; { load }

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
          record_length := string_length +20);
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
procedure init_interpreter;
var i: integer;
begin     
    write_debug ('%init_interpreter');
    { alustetaan ohjelma puskuri }
    for i := 1 to max_buffer do with pool[i] do begin
	used := 0;
	current_program := 0;
	current_version := 0;
	time := 0;
    end;

end; { init_interpreter }

[global]         
procedure finish_interpreter;	{ not need yet }
begin
  write_debug('%finish_interpreter');

end; { finish_interpreter }

[global]                
procedure create_program (hdr: integer; owner: atom_t; time: atom_t);
var i: integer;
begin
  write_debug('%create_program');
  delete_program(hdr); { truncate code file }
  getheader(hdr);
  header.interlocker := '';
  header.runnable := FALSE;
  header.owner := owner;
  header.ctime := time;
  header.priv  := false;
  for i := 1 to statmax do header.stats[i].lab := '';
  for i := 1 to statmax do header.stats[i].runcount := 0;
  for i := 1 to statmax do header.stats[i].errorcount := 0;
  for i := 1 to statmax do header.stats[i].lastrun := '';
  header.author := '';
  header.wtime  := '';
  header.running_id := '';
  header.version    := 0;
  header.state      := '';
  header.flags	    := 0;
  putheader;
end; { create_program }
            
{ addheaders moved to module DATABASE }

end. { end of module interpreter }
                                      
