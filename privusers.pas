[environment,inherit ('sys$library:starlet','global') ]
module privusers(output);

const max_message_lines = 50;

var timestring : string := '';
    default_allow: [global] integer := 0;
    min_room: [global] integer := 0;
    min_accept: [global] integer := 0;

    msg: array [1 .. max_message_lines] of string;
    msg_count: 0 .. max_message_lines := 0;

    alloc_dcl_access: boolean := true;

function image_name: string;
var
    value: string;
    ret: unsigned;
    itmlst: itmlst_type;
    i: integer;
    
begin
    with itmlst do begin
	buffer_length := string_len;
	item_code := jpi$_imagname;
	new (buffer_address);
	new (return_length_address);
	itmlst_end := 0;
    end;
          
    ret := $getjpiw (,,,itmlst,,,);
    
    if odd(ret) then begin
	value := '';
	for i:= 1 to itmlst.return_length_address^ do
	    value := value + itmlst.buffer_address^(.i.);
	image_name := value;
    end else
	image_name := '';

    with itmlst do begin
	dispose(buffer_address);
	dispose(return_length_address);
    end;

end; { image_name }

Function strip_line(line: string): string;
var ok: boolean;
begin
    ok := true;
    while ok do begin
	ok := line > '';
	if ok then ok := chartable[line[1]].kind = ct_space;
	if ok then line := substr(line,2,length(line)-1);
    end;

    ok := true;
    while ok do begin
	ok := line > '';
	if ok then ok := chartable[line[length(line)]].kind = ct_space;
	if ok then line := substr(line,1,length(line)-1);
    end; { ok }
    strip_line := line;
end; { strip_line }

[global]
Procedure Get_Environment;
var path: string;
    pos,i: integer;
    init: text;
    counter: integer;
    current_line: string;

    procedure message(s: string);
    begin
	writeln('%Error in ',path);
	writeln('%at line ',counter:1);
	writeln('%',current_line);
	writeln('%',s);
	writeln('%Notify Monster Manager.');
	halt;
    end; { message }

    function get_line (exact: boolean := false): string;
    var line: string;
	pos,i: integer;
	ok,quoted: boolean;
    begin
	ok := false;
	repeat
	    if eof(init) then begin
		get_line := '';
		ok := true;
		counter := counter +1;
		current_line := '';
	    end else begin
		readln(init,line);
		counter := counter +1;
		current_line := line;
		
		if not exact then begin
		    quoted := false;
		    pos := 0;
		    for i := 1 to length(line) do
			if line[i] = '"' then quoted := not quoted
			else if (line[i] = '!') and not quoted 
			    and (pos = 0) then 
				pos := i;

		    if quoted then message('Bailing out quote !');
		    if pos > 0 then line := substr(line,1,pos-1);

		    line := strip_line(line);
		end; { exact }

		get_line := line;
		ok := (line > '') or exact;
	    end;
	until ok;
    end;    { get_line }

    function item_value(item: string): string;
    var line: string;
	pos: integer;
    begin
	line := get_line;
	if (line  = '') and  eof(init) then message('EOF detected.');
	pos := index(line,':');
	if pos = 0 then message (': must be in line');
	if item <> substr(line,1,pos-1) then message(item+': expected');
	if pos = length(line) then message('value must be in line');
	line := substr(line,pos+1,length(line)-pos);
	line := strip_line(line);
	if line = '' then message('value can''t be only space');
	item_value := line;
    end;    { item_value }

    function item_number(item: string): integer;
    var val: string;
	num: integer;
    begin
	val := item_value(item);
	readv(val,num,error := continue);
	if statusv > 0 then message('value '+val+' must be integer');
	if num < 0 then message('value '+val+' must be positive or zero');
	item_number := num;
    end; { item_number }

    procedure set_level(var level: levelrec; line: string);

	function cut_field(var line: string): string;
	var pos: integer;
	begin
	    pos := index(line,',');
	    if pos = 0 then begin
		cut_field := strip_line(line);
		line := ''
	    end else begin
		cut_field := strip_line(substr(line,1,pos-1));
		line := substr(line,pos+1,length(line)-pos);
		line := strip_line(line);
	    end;
	end; { cut_field }

	function cut_number(var line: string): integer;
	var val: string;
	    num: integer;
	begin
	    val := cut_field(line);
	    if val = '' then message('field can''t be empty');
	    readv(val,num,error := continue);
	    if statusv > 0 then message('value '+val+' must be integer');
	    if num < 0 then message('value '+val+' must be positive or zero');
	    cut_number := num;
	end; { cut_number }
	    
    begin
	with level do begin
	    name :=     cut_field  (line);
	    exp  :=     cut_number (line);
	    priv :=     cut_number (line);
	    health   := cut_number (line);
	    factor   := cut_number (line);
	    maxpower := cut_number (line);
	    hidden   := cut_field  (line) = 'hidden';
	end;	
    end;    { set_level }
	
    procedure read_leveltable;
    var line: string;
	i: integer;
    begin
	levels := 0;
	if get_line <> 'LEVELTABLE:' then message('LEVELTABLE: expected');
	line := get_line;
	while (line <> 'END OF LEVELTABLE') and (line <> '') do begin
	    levels := levels+1;
	    set_level(leveltable[levels],line);
	    line := get_line;
	end;
	if line <> 'END OF LEVELTABLE' then 
	    message('END OF LEVELTABLE expected');
	levels := levels +1;
	with leveltable[levels] do begin
	    name :=   'Archwizard';
	    exp  :=   MaxInt;
	    priv :=     item_number('Archpriv');
	    health   := item_number('Archhealth');
	    factor   := item_number('Archfactor');
	    maxpower := item_number('Archpower');
	    hidden   := false;
	end; { with }
	for i := levels+1 to maxlevels do with leveltable[i] do begin
	    name :=   '';
	    exp  :=   MaxInt;
	    priv :=     0;
	    health   := 0;
	    factor   := 0;
	    maxpower := 0;
	    hidden   := true;
	end;	    
    end; { read_leveltable }


    procedure read_chartable;
    var	new_charset: string;
	
	procedure set_chartable(line: string);

	    function cut_word(var line: string): string;
	    var result: string;
		quoted,ready: boolean;
		i: integer;
	    begin
		quoted := false;
		ready  := false;
		result := '';
		i := 1;
		ready := i > length(line);
		while not ready do begin
		    if line[i] = '"' then quoted := not quoted;
		    if (chartable[line[i]].kind <> ct_space) or quoted then 
			result := result + line[i]
		    else if (chartable[line[i]].kind = ct_space) and not quoted
			and (result > '') then ready := true;
		    i := i + 1;
		    if i > length(line) then ready := true;
		end;
		if quoted then message ('Bailing out quote: ' + result);
	    
		if i  > length(line) then line := ''
		else line := substr(line,i,length(line)-i+1);

		cut_word := result;
	    end; { cut_word }

	    function parse_char(word: string): char;
	    var code: integer;
	    begin
		if word = '' then message ('Character specification expected.');
		if word[1] = '"' then begin
		    if length(word) <> 3 then 
			message('Bad character specification: ' + word);
		    if word[3] <> '"' then 
			message('Bad character specification: ' + word);
		    parse_char := word[2];
		end else begin
		    readv(word,code,error := continue);
		    if statusv <> 0 then 
			message('Bad value of character spefication: ' + word);
		    if (code < 0) or (code > 255) then
			message ('Character code out of range: ' + word);
		    parse_char := chr(code);
		end;		
	    end; { parse char }

	    var word: string;
	    ch: char;
	    T: charrec;
	begin
	    word := cut_word(line);
	    if word = 'char' then begin
		chartable_charset := '';
		word := cut_word(line); ch := parse_char(word);
		with T do begin
		    kind := ct_none;
		    lcase := ch;
		    ucase := ch;
		    word := cut_word(line);
		    while word > '' do begin
			if word = 'none' then kind := ct_none
			else if word = 'letter' then kind := ct_letter
			else if word = 'special' then kind := ct_special
			else if word = 'space' then kind := ct_space
			else if word = 'upper' then begin
			    word := cut_word(line);
			    ucase := parse_char(word);
			end else if word = 'lower' then begin
			    word := cut_word(line);
			    lcase := parse_char(word);
			end else message('Bad argument: '+word);
			word := cut_word(line);
		    end; { while }
		end; { with }
		chartable[ch] := T;
	    end else if word = 'charset' then begin
		if new_charset <> 'UNKNOWN' then 
		    message('Charset defined twice');
		word := cut_word(line);
		if (word = '') then message ('Charset name expected.');
		if word[1] = '"' then begin
		    if word[length(word)] <> '"' then
			message ('Bad charset specification: ' + word);
		    word := substr(word,2,length(word)-2);
		end;
		new_charset := word;
		word := cut_word(line);
		if (word > '') then 
		    message ('Too many arguments: ' + word);
	    end else message ('"char" or "charset" expected: ' + word);
	end; { set_chartable }

    var line : string;
    begin
	new_charset := 'UNKNOWN';

	if get_line <> 'CHARTABLE:' then message('CHARTABLE: expected');
	line := get_line;
	while (line <> 'END OF CHARTABLE') and (line <> '') do begin
	    set_chartable(line);
	    line := get_line;
	end;
	if chartable_charset = '' then chartable_charset := new_charset;
	if line <> 'END OF CHARTABLE' then message('END OF CHARTABLE expected.');
    end; { read_chartable }

    procedure read_message;
    var line : string;
    begin
	if get_line <> 'CLOSED MESSAGE:' then 
	    message('CLOSED MESSAGE: expected');
	line := get_line(true);			{ don't uncomment }
	while (strip_line(line) <> 'END OF MESSAGE') and not eof(init) do begin
	    if msg_count >= max_message_lines then
		message('Too many lines in CLOSED MESSAGE');
	    msg_count := msg_count + 1;
	    msg[msg_count] := line;
	    line := get_line(true);		{ don't uncomment }
	end;
	if strip_line(line) <> 'END OF MESSAGE' then 
	    message('END OF MESSAGE expected.');

    end;
	
begin
    counter := 0;
    current_line := '';

    path := image_name;
    if path = '' then begin
	writeln('%Can''t get IMAGNAME. Notify Monster Manager.');
	halt;
    end;
    pos := 0;
    for i := 1 to length(path) do begin
	if path[i] = '>' then pos := i;
	if path[i] = ']' then pos := i;
    end;
    if pos = 0 then begin
	writeln('%Odd IMAGNAME. Notify Monster manager.');
	writeln('%IMAGNAME: ',path);
	halt;
    end;
    
    path := substr(path,1,pos) + 'MONSTER.INIT';

    open (init,path,history := READONLY, error := CONTINUE);

    if status (init) > 0 then begin
	writeln('%Can''t open ',path);
	writeln('%Notify Monster Manager.');
	halt;
    end else if status(init) < 0 then begin
	writeln('%',path,' is empty');
	writeln('%Notify Monster Manager.');
	halt;
    end;

    reset(init);

    MM_userid  := item_value('MM_userid');
    gen_debug  := item_value('gen_debug') = 'true';
    rebuild_ok := item_value('REBUILD_OK') = 'true';
    root       := item_value('root');
    coderoot   := item_value('coderoot');
    read_leveltable;
    maxexperience := item_number('maxexperience');
    protect_exp   := item_number('protect_exp');
    timestring    := item_value('Playtime');
    default_allow := item_number('default_allow');
    min_room      := item_number('min_room');
    min_accept     := item_number('min_accept');

    read_chartable;

    database_poltime := item_value('database_poltime');

    read_message;

    max_mdl_buffer  := item_number('mdl_buffers');
    alloc_dcl_access := item_value('allow_dcl_access') = 'true';

    close (init);
end;	{ Get_Environment }

[ global ]
procedure write_message;
var i: integer;
begin
    for i := 1 to msg_count do writeln(msg[i]);
end;	{ write_message }

[global]
function work_time: boolean;
type
    hournums= 0..23;
    timeset= set of hournums;
var
    hours: timeset;
    allright: boolean;     { This will be set to false on any error. }
    root: [external] varying [80] of char;


    function wkdayp: boolean;
    type
	string = varying[string_len] of char;

    var
	value: string;
	fake: boolean;


	function sys_trnlnm (
	    tabnam : [class_s] packed array [$l2..$u2:integer] of char;
	    lognam : [class_s] packed array [$l3..$u3:integer] of char
	    ): string;

	(*
    
	    Takes as parameters a logical name table and a logical  name.
	    Returns  the  equivalence string, or if the name is undefined
	    the logical  name  itself.  The  parameters  must  be  string
	    constants, not variables.
    
	    leino@finuh 20 Mar 1989
    
	    *)
	        
    
	var
	    value: string;
	    ret: unsigned;
	    itmlst: itmlst_type;
	    i: integer;
    
	begin
	    with itmlst do begin
		buffer_length := string_len;
		item_code := lnm$_string;
		new (buffer_address);
		new (return_length_address);
		itmlst_end := 0;
	    end;
          
	    ret := $trnlnm (lnm$m_case_blind, tabnam, 
			    lognam, psl$c_user, itmlst);
    
	    if odd(ret) then begin
		value := '';
		for i:= 1 to itmlst.return_length_address^ do
		    value := value + itmlst.buffer_address^(.i.);
		sys_trnlnm := value;
	    end else
		sys_trnlnm := lognam;

	    with itmlst do begin
		dispose(buffer_address);
		dispose(return_length_address);
	    end;

	end; (* of sys_trnlnm *)

    begin
	fake := false;
	value := sys_trnlnm ('lnm$process_directory', 'lnm$directories');
	if value <> 'lnm$directories' then fake := true;
	value := sys_trnlnm ('lnm$process_directory', 'lnm$system_table');
	if value <> 'lnm$system_table' then fake := true;
	value := sys_trnlnm ('lnm$system_table', '$daystatus');
	if value = 'WEEKDAY' then
	    wkdayp := true
	else
	    wkdayp := false;
	if fake then begin
	    writeln ('%MONSTER-F-CRACK, cracking attempt suspected');
	    wkdayp := true;
	    halt;
	end;
    end;

    procedure getlegal(var time: timeset);
    var i: integer;
    begin
	time := [];
	if length(timestring) <> 24 then allright := false
	else for i:=0 to 23 do begin
	        if timestring[i+1] = '+' then time:=time+[i];
	    end;
    end;

    function gethour: integer;
    var systime: packed array[1..11] of char;
    begin
	time(systime);
	if systime[1]=' '
	then gethour:=ord(systime[2])-ord('0')
	else gethour:=10*(ord(systime[1])-ord('0'))+ord(systime[2])-ord('0')
    end; { gethour }

begin
   allright:=true;     { Let's suppose ev'rything goes fine. }
   work_time:=false;
   if wkdayp
   then begin
      hours:=[];
      getlegal(hours);    { At this moment the 'allright' may change in }
      if allright then begin  { procedure getlegal() only }
         if not (gethour in hours)
         then begin
            work_time:=true    { Someone tries to play at noon. }
         end
      end else
         work_time:=true  { Something odd is going on. Let's prevent playing. }
   end
end;

end. { of module privusers }
