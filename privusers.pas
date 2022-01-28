[environment,inherit ('sys$library:starlet','global') ]
module privusers(output);

var timestring : string := '';
    default_allow: [global] integer := 0;
    min_room: [global] integer := 0;
    min_accept: [global] integer := 0;

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
    while index(line,' ') = 1 do
	line := substr(line,2,length(line)-1);

    ok := true;
    while ok do begin
	ok := line > '';
	if ok then ok := line[length(line)] = ' ';
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

    function get_line: string;
    var line: string;
	pos: integer;
	ok: boolean;
    begin
	ok := false;
	repeat
	    if eof(init) then begin
		get_line := '';
		ok := true;
	    end else begin
		readln(init,line);
		counter := counter +1;
		current_line := line;
		pos := index(line,'!');
		if pos > 0 then line := substr(line,1,pos-1);

		line := strip_line(line);

		get_line := line;
		ok := line > '';
	    end;
	until ok;
    end;    { get_line }

    procedure message(s: string);
    begin
	writeln('%Error in ',path);
	writeln('%at line ',counter:1);
	writeln('%',current_line);
	writeln('%',s);
	writeln('%Notify Monster Manager.');
	halt;
    end; { message }

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

    close (init);

end;	{ Get_Environment }


[ global ]
procedure write_message;
var ch: char;
    fyle : text;
begin
   open(fyle,
        root+'ILMOITUS.TXT',
        access_method:=sequential,
        history:= readonly,
        sharing:=readonly,
	error:=continue);
   if status(fyle) <> 0 then
	writeln('%Can''t type ILMOITUS.TXT. Notify Monster Manager.')
   else begin
       reset(fyle);
       while not eof(fyle) do begin
	  while not eoln(fyle) do begin
	     read(fyle,ch);
	     write(ch)
	  end;
	  readln(fyle);
	  writeln
       end;
       close(fyle);
   end;
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
