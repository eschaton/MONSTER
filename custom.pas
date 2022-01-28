[ ENVIRONMENT, inherit ('Global','Guts','Database','Cli','Privusers','Parser',
			'Interpreter','Queue', 'Alloc') ]
MODULE Custom ( Input, Output );
 
{+
COMPONENT: Modulin MON custom komennot on siiretty t‰nne.
 
PROGRAM DESCRIPTION:
 
    Peli MONSTER 
 
AUTHORS:
 
    Kari Hurtta
 
CREATION DATE: 29.9.1990
 
DESIGN ISSUES:
 
    Tarkoitus on pienent‰‰ tiedoston MON.PAS kokoa.
 
 
MODIFICATION HISTORY:
 
     Date     |   Name  | Description
--------------+---------+-------------------------------------------------------
    5.10.1990 | Hurtta  | Spells
    7.11.1990 |         | Global descbibtions
   24.01.1991 |         | Look more exact value of status -funktion
    6.05.1992 |         | O_TRAP was leaven out from prog_kind
   25.06.1992 |         | Moved to module ALLOC
   25.06.1992 | Hurtta  | Allocation routines moved to module ALLOC from 
              |         | module CUSTOM
}

var system_id,disowned_id,public_id: [global] shortstring;

	hiding : [global] boolean := FALSE;	  { is player hiding? }
	logged_act : [global] boolean := FALSE;	  { flag to indicate that a log_action
					  has been called, and the next call
					  to clear_command needs to clear the
					  action parms in the here roomrec }


	{ userid moved to module ALLOC }

	myslot: [global] integer := 1;	{ here.people[myslot]... is this player }

	myname: [global] shortstring;	
				{ personal name this player chose (setname) }
	myexperience: [global] integer;	{ how experienced I am }
	mydisguise: [global] integer;	{ what disguise I'm wearing }

 
[external]
function put_token(room: integer;var aslot:integer;hidelev:integer := 0):boolean;
external;

procedure do_program(object_name: string); forward;

procedure do_y_altmsg;
forward;

procedure do_group1;
forward;

procedure do_group2;
forward;

procedure custom_monster(name: string); forward;

[global] PROCEDURE custom_hook(var code: integer;
			owner: shortstring;
			default: string := '.MDL'); forward;

[global] FUNCTION  spell_owner(sid: integer): string;
var tmp: intrec;
    code: integer;
begin
    tmp := anint;
    getint(N_SPELL);
    freeint;
    code := anint.int[sid];
    anint := tmp;
    if code = 0 then begin
	writeln('%Error in spell_owner. Notify Monster Manager.');
	spell_owner := ''
    end else spell_owner := monster_owner(code);
end; { spell_owner }

[global] FUNCTION is_spell_owner(sid: integer;
    public_ok: boolean := false): boolean;
var owner: shortstring;
begin
    owner := spell_owner(sid);
    if owner = userid then is_spell_owner := true
    else if owner_priv and not (owner = system_id) then is_spell_owner := true
    else if manager_priv then is_spell_owner := true
    else if public_ok and (owner = public_id) then is_spell_owner := true
    else is_spell_owner := false;
end; { is_spell_owner }


function trim_filename(name: shortstring): string;
var i: integer;
    def: string;
begin
    def := '';
    for i := 1 to length(name) do 
	if ('a' <= name[i]) and ('z' >= name[i]) then
	    def := def + chr(ord(name[i]) - ord('a') + ord('A'))
	else if ('A' <= name[i]) and ('Z' >= name[i]) then
	    def := def + name[i]
	else if (name[i] = ' ') or (name[i] = '_') then
	    def := def + '_';
     def := def + '.MDL';
     trim_filename := def;
end; { trim_filename }

[global]
function sysdate:string;
var
	thedate: packed array[1..11] of char;
begin
	date(thedate);
	sysdate := thedate;
end;


[global]
procedure gethere(n: integer := 0);
begin
	if (n = 0) or (n = location) then begin
		if not(inmem) then begin
			getroom;	{ getroom(n) okay here also }
			freeroom;
			inmem := true;
		end else if debug then
			writeln('%gethere - here already in memory');
	end else begin
		getroom(n);
		freeroom;
	end;
end;


{ -------------------------------------------------------------------------- }


{
Returns TRUE if player is owner of room n
If no n is given default will be this room (location)
}
[global] FUNCTION is_owner(n: integer := 0;surpress:boolean := false): boolean;
begin
	gethere(n);
	if (here.owner = userid) or 
	    (owner_priv and (here.owner <> system_id)) or 
	    manager_priv then  { minor change by leino@finuha }
				{ and hurtta@finuh }
		is_owner := true
	else begin
		is_owner := false;
		if not(surpress) then begin
		    if here.owner = system_id then
			writeln('System is the owner of this room.')
		    else
			writeln('You are not the owner of this room.');
		end;
	end;
end;

[global] FUNCTION room_owner(n: integer): string;
begin
	if n <> 0 then begin
		gethere(n);
		room_owner := here.owner;
		gethere;	{ restore old state! }
	end else
		room_owner := 'no room';
end;

{
Returns TRUE if player is allowed to alter the exit
TRUE if either this room or if target room is owned by player
}
[global] FUNCTION can_alter(dir: integer;room: integer := 0): boolean;
begin
	gethere;
	if (here.owner = userid) or 
	    (owner_priv and (here.owner <> system_id)) or
	    manager_priv then begin  { minor change by leino@finuha }
		can_alter := true
	end else begin
		if here.exits[dir].toloc > 0 then begin
			if room_owner(here.exits[dir].toloc) = userid then
				can_alter := true
			else can_alter := false;
		end else can_alter := false;
	end;
end;
[global] FUNCTION can_make(dir: integer;room: integer := 0): boolean;
begin

	gethere(room);	{ 5 is accept door }
	if (here.exits[dir].toloc <> 0) then begin
		writeln('There is already an exit there.  Use UNLINK or RELINK.');
		can_make := false;
	end else begin
		if (here.owner = userid) or		{ I'm the owner }
		   (here.exits[dir].kind = 5) or	{ there's an accept }
		   (owner_priv and (here.owner <> system_id)) or	
		   manager_priv or { Monster Manager } 
		   { minor change by leino@finuha and hurtta@finuh }
		   (here.owner = disowned_id)	       { disowned room }
							 then
			can_make := true
		else begin
			can_make := false;
			writeln('You are not allowed to create an exit there.');
		end;
	end;
end;

[global] PROCEDURE niceprint(var len: integer; s: string);
begin
	if len + length(s) > terminal_line_len -2 then begin
		len := length(s);
		writeln;
	end else begin
		len := len + length(s);
	end;
	write(s);
end;
[global] PROCEDURE print_short(s: string; cr: boolean; var len: integer);
var i,j: integer;
begin
    i := 1;
    for j := 1 to length(s) do begin
	if s[j] = ' ' then begin
	    niceprint(len,substr(s,i,j-i+1));
	    i := j+1;
	end;
    end;
    if i <= length(s) then
	niceprint(len,substr(s,i,length(s)-i+1));
    if cr then begin
	writeln;    
	len := 0;
    end;
end; 

{
print a one liner
}
[global] PROCEDURE print_line(n: integer);
var len: integer;
begin
	len := 0;
	if n = DEFAULT_LINE then
		writeln('<default line>')
	else if n > 0 then begin
		getline(n);
		freeline;
		if terminal_line_len < 80 then 
		    print_short(oneliner.theline,true,len)
		else
		    writeln(oneliner.theline);
	end;
end;

[global] PROCEDURE print_desc(dsc: integer;default:string := '<no default supplied>');
var
	i: integer;
	len: integer;
begin
	if dsc = DEFAULT_LINE then begin
		writeln(default);
	end else if dsc > 0 then begin
		getblock(dsc);
		freeblock;
		i := 1;
		len := 0;
		while i <= block.desclen do begin
		    if terminal_line_len < 80 then
			print_short(block.lines[i],i = block.desclen,len)
		    else
			writeln(block.lines[i]);
		    i := i + 1;
		end;
	end else if dsc < 0 then begin
		print_line(abs(dsc));
	end;
end;

[global] procedure print_global(flag: integer; noti: boolean := true;
			force_read: boolean := false);
var code: integer;
begin
    if Gf_Types [ flag] <> G_text then begin
	writeln('%Error in print_global:');
        writeln('%Global value #',flag:1,' isn''t global desciption');
	writeln('%Notify Monster Manager.');
	code := 0;
    end else begin
	if read_global or force_read then begin
	    getglobal;
	    freeglobal;
	    read_global := false;
	end;
	code := global.int[flag];
    end;

    if code = 0 then begin
	if noti then writeln('No (global) desciption.');
    end  else print_desc(code);

end; { print_global }
  
[global] PROCEDURE make_line(var n: integer;prompt : string := '';limit:integer := 79);
label exit_label;
var
	s: string;
	ok: boolean;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;
	
begin
    if (n <> DEFAULT_LINE) and (n <> 0) then
	begin
	    getline(n);
	    freeline;
	    s := oneliner.theline;
	end
    else s := '';

	writeln('Type ** to leave line unchanged, * to make [no line]');
	repeat 
	    grab_line(prompt,s,edit_mode := true, eof_handler := leave);
	until (grab_next = 0) or (grab_next = 1);

	if s = '**' then begin
		writeln('No changes.');
	end else if s = '***' then begin
		n := DEFAULT_LINE;
	end else if s = '*' then begin
		if debug then
			writeln('%deleting line ',n:1);
		delete_line(n);
	end else if s = '' then begin
		if debug then
			writeln('%deleting line ',n:1);
		delete_line(n);
	end else if length(s) > limit then begin
		writeln('Please limit your string to ',limit:1,' characters.');
	end else begin
		if (n = 0) or (n = DEFAULT_LINE) then begin
			if debug then
				writeln('%make_line: allocating line');
			ok := alloc_line(n);
		end else
			ok := true;

		if ok then begin
			if debug then
				writeln('%ok in make_line');
			getline(n);
			oneliner.theline := s;
			putline;

			if debug then
				writeln('%completed putline in make_line');
		end;
	end;
    exit_label:
end;

[global] FUNCTION isnum(s: string): boolean;
var
	i: integer;

begin
    if s = '' then isnum := false
    else begin
	readv(s,i,error := continue);
	if statusv <> 0 then isnum := false
	else if i < 0 then isnum := false
	else isnum := true;
    end; { isnum }
end;

[global] FUNCTION number(s: string): integer;
var
	i: integer;
begin
	if (length(s) < 1) or not(s[1] in ['0'..'9']) then
		number := 0
	else begin
		readv(s,i,error := continue);
		if statusv <> 0 then number := 0
		else number := i;
	end;
end;

[global] FUNCTION log_name: string;	{ myname or 'Someone' if use disguise }
				{ hurtta@finuh }
begin
	if mydisguise = 0 then log_name := myname
	else log_name := 'Someone';
end;

[global] PROCEDURE log_action(theaction,thetarget: integer);
begin
	if debug then
		writeln('%log_action(',theaction:1,',',thetarget:1,')');
	getroom;
	here.people[myslot].act := theaction;
	here.people[myslot].targ := thetarget;
	putroom;

	logged_act := true;
	log_event(myslot,E_ACTION,thetarget,theaction,log_name);
end;

[global]
function systime:string;
var
	hourstring: string;
	hours: integer;
	thetime: packed array[1..11] of char;
	dayornite: string;

begin
	time(thetime);
	if thetime[1] = ' ' then
		hours := ord(thetime[2]) - ord('0')
	else
		hours := (ord(thetime[1]) - ord('0'))*10 +
			  (ord(thetime[2]) - ord('0'));

	if hours < 12 then
		dayornite := 'am'
	else
		dayornite := 'pm';
	if hours >= 13 then
		hours := hours - 12;
	if hours = 0 then
		hours := 12;

	writev(hourstring,hours:2);

	systime := hourstring + ':' + thetime[4] + thetime[5] + dayornite;
end;

[global] FUNCTION custom_privileges(var privs: integer;
		authorized: unsigned): boolean;
label exit_label;
var s: string;
    update: boolean;
    upriv,mask : unsigned;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	update := false;
	goto exit_label;
    end;

begin
   upriv := uint(privs);
   update := false;
   repeat
      grab_line('Custom privileges> ',s,eof_handler := leave);
      s := lowcase(s);
      if s > '' then case s[1] of
         'v': begin
                write('Current set: ');
                list_privileges(upriv);
              end;
         'h','?': begin
		    command_help('*privilege help*');
                 end;
	 'l'    : begin
		    write('Possible privilege set: ');
		    list_privileges(authorized);
		  end;
         '-'   : begin
	           if length(s) < 3 then writeln('Type ? for help.')
		   else if lookup_priv(mask,slead(substr(s,3,length(s)-2))) then
		   begin
			if uand(mask,upriv) > 0 then begin
			    upriv := uand(upriv,unot(mask));
			    write('Removed: '); list_privileges(mask);
			end else writeln('Isn''t in current set.');
		    end else writeln('Type L for list.');
		end;
         '+'   : begin
	           if length(s) < 3 then writeln('Type ? for help.')
		   else if lookup_priv(mask,slead(substr(s,3,length(s)-2))) then
		   begin
			if uand(mask,authorized) <> mask then 
			    writeln('Not authorized.')
			else if uand(mask,upriv) = 0 then begin
			    upriv := uor(upriv,mask);
			    write('Added: '); list_privileges(mask);
			end else writeln('Is already in current set.');
		    end else writeln('Type L for list.');
		end;
         'q'   : update := false;
         'e'   : update := true;
         otherwise writeln ('Type ? for list.');
      end; { case }
   until (s = 'q') or (s = 'e');
   exit_label:
   if update then privs := int(upriv);
   custom_privileges := update;
end; { custom_privileges }

          
[global] FUNCTION desc_allowed: boolean;
begin
	if (here.owner = userid) or
	   (owner_priv) then { minor change by leino@finuha }
		desc_allowed := true
	else begin
		writeln('Sorry, you are not allowed to alter the descriptions in this room.');
		desc_allowed := false;
	end;
end;

{ count the number of people in this room; assumes a gethere has been done }

[global] function find_numpeople: integer;
var
	sum,i: integer;
begin
	sum := 0;
	for i := 1 to maxpeople do
		if here.people[i].kind > 0 then
{		if here.people[i].username <> '' then	}
			sum := sum + 1;
	find_numpeople := sum;
end;



{ don't give them away, but make noise--maybe
  percent is percentage chance that they WON'T make any noise }
procedure noisehide(percent: integer);
begin
	{ assumed gethere;  }
	if (hiding) and (find_numpeople > 1) then begin
		if rnd100 > percent then
			log_event(myslot,E_REALNOISE,rnd100,0);
			{ myslot: don't tell them they made noise }
	end;
end;


[global] function checkhide: boolean;
begin
	if (hiding) then begin
		checkhide := false;
		noisehide(50);
		writeln('You can''t do that while you''re hiding.');
	end else
		checkhide := true;
end;

{ edit DESCRIBTION --------------------------------------------------------- }

procedure edit_replace(n: integer);
label exit_label;
var
	prompt: string;
	s: string;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


begin
	if (n > heredsc.desclen) or (n < 1) then
		writeln('-- Bad line number')
	else begin
		writev(prompt,n:2,': ');
		s := heredsc.lines[n];
		grab_line(prompt,s,edit_mode := True,eof_handler := leave);
		if s <> '**' then
			heredsc.lines[n] := s;
	end;
    exit_label:
end;

procedure edit_insert(n: integer);
var
	i: integer;

begin
	if heredsc.desclen = descmax then
		writeln('You have already used all ',descmax:1,' lines of text.')
	else if (n < 1) or (n > heredsc.desclen+1) then begin
		writeln('Invalid line #; valid lines are between 1 and ',heredsc.desclen+1:1);
		writeln('Use A (add) to add text to the end of your description.');
	end else begin
		for i := heredsc.desclen+1 downto n + 1 do
			heredsc.lines[i] := heredsc.lines[i-1];
		heredsc.desclen := heredsc.desclen + 1;
		heredsc.lines[n] := '';
	end;
end;

procedure edit_doinsert(n: integer);
label exit_label;
var
	s: string;
	prompt: string;             
	i: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


begin
	if heredsc.desclen = descmax then
		writeln('You have already used all ',descmax:1,' lines of text.')
	else if (n < 1) or (n > heredsc.desclen+1) then begin
		writeln('Invalid line #; valid lines are between 1 and ',heredsc.desclen:1);
		writeln('Use A (add) to add text to the end of your description.');
	end else begin
		edit_insert(n); 
		repeat    
			writev(prompt,n:2,': '); 
			s := heredsc.lines[n];
			grab_line(prompt,s,edit_mode := true,eof_handler := leave);
			if s <> '**' then begin
				heredsc.lines[n] := s;	{ copy this line onto it }
	   			if (grab_next < 0) and (n > 1) then
					n := n -1
				else if (grab_next >0) and 
					(n < heredsc.desclen) then
					n := n +1
				else if (grab_next = 0) and 
					(n < descmax)then begin
					n := n +1;
					edit_insert(n);
		       		end
			end else begin
		   		for i := n+1 to heredsc.desclen do
					heredsc.lines[i-1] := heredsc.lines[i];
				heredsc.desclen := heredsc.desclen -1
			end;
		until (heredsc.desclen = descmax) or (s = '**');
	end;
	exit_label:
end;
                                          
procedure edit_show;
var
	i: integer;

begin
	writeln;
	if heredsc.desclen = 0 then
		writeln('[no text]')
	else begin
		i := 1;
		while i <= heredsc.desclen do begin
			writeln(i:2,': ',heredsc.lines[i]);
			i := i + 1;
		end;
	end;
end;

procedure edit_append; 		{ changed by hurtta@finuh }
var
	prompt,s: string;
	stilladding: boolean; 
	ln: integer;

    procedure leave;
    begin
	writeln('EXIT');
	stilladding := false;
	grab_next := 0;
    end;


begin
	stilladding := true;
	writeln('Enter text.  Terminate with ** at the beginning of a line.');
	writeln('You have ',descmax:1,' lines maximum.');
	writeln; 
	ln := heredsc.desclen+1;
	if ln > descmax then ln := descmax;
	while stilladding do begin   
		if ln > heredsc.desclen then heredsc.lines[ln] := '';
		s := heredsc.lines[ln];
		writev(prompt,ln:2,': ');
		grab_line(prompt,s, edit_mode := true,eof_handler := leave);
		if s = '**' then begin
			stilladding := false;
			heredsc.desclen := ln -1
		end else begin
			if heredsc.desclen < ln then heredsc.desclen := ln;
			heredsc.lines[ln] := s;      
			if grab_next = 0 then begin
				if ln < descmax then ln := ln+1
				else stilladding := false
			end else if grab_next > 0 then begin               
				if ln < heredsc.desclen then ln := ln+1
			end else begin
				if ln > 1 then ln := ln -1
			end;
		end;     
	end;
end;    { edit_append }

procedure edit_delete(n: integer);
var
	i: integer;

begin
	if heredsc.desclen = 0 then
		writeln('-- No lines to delete')
	else if (n > heredsc.desclen) or (n < 1) then
		writeln('-- Bad line number')
	else if (n = 1) and (heredsc.desclen = 1) then
		heredsc.desclen := 0
	else begin
		for i := n to heredsc.desclen-1 do
			heredsc.lines[i] := heredsc.lines[i + 1];
		heredsc.desclen := heredsc.desclen - 1;
	end;
end;

procedure check_subst;
var i: integer;
begin
	if heredsc.desclen > 0 then begin
		for i := 1 to heredsc.desclen do
			if (index(heredsc.lines[i],'#') > 0) and
			   (length(heredsc.lines[i]) > 59) then
				writeln('Warning: line ',i:1,' is too long for correct parameter substitution.');
	end;
end;


[global] function edit_desc(var dsc: integer):boolean;
var
	cmd: char;
	s: string;
	done: boolean;
	n: integer;

    procedure leave;
    begin
	writeln('EXIT');
	s := 'e';
    end;

begin
	if dsc = DEFAULT_LINE then begin
		heredsc.desclen := 0;
	end else if dsc > 0 then begin
		getblock(dsc);
		freeblock;
		heredsc := block;
	end else if dsc < 0 then begin
		n := (- dsc);
		getline(n);
		freeline;
		heredsc.lines[1] := oneliner.theline;
		heredsc.desclen := 1;
	end else begin
		heredsc.desclen := 0;
	end;

	edit_desc := true;
	done := false;
        edit_append;
	repeat
		writeln;
		repeat
			grab_line('* ',s,eof_handler := leave);
			s := slead(s);
		until length(s) > 0;
		s := lowcase(s);
		cmd := s[1];

		if length(s)>1 then begin
			n := number(slead(substr(s,2,length(s)-1)))
		end else
			n := 0;

		case cmd of
			'h','?': command_help('*edit help*');
			'a': edit_append;
			'z': heredsc.desclen := 0;
			'c': check_subst;
			'p','l','t': edit_show;
			'd': edit_delete(n);
			'e': begin
				check_subst;
				if debug then
					writeln('edit_desc: dsc is ',dsc:1);


{ what I do here may require some explanation:

	dsc is a pointer to some text structure:
		dsc = 0 :  no text
		dsc > 0 :  dsc refers to a description block (descmax lines)
		dsc < 0 :  dsc refers to a description "one liner".  abs(dsc)
			   is the actual pointer

	If there are no lines of text to be written out (heredsc.desclen = 0)
	then we deallocate whatever dsc is when edit_desc was invoked, if
	it was pointing to something;

	if there is one line of text to be written out, allocate a one liner
	record, assign the string to it, and return dsc as negative;

	if there is mmore than one line of text, allocate a description block,
	store the lines in it, and return dsc as positive.

	In all cases if there was already a record allocated to dsc then
	use it and don't reallocate a new record.
}

{ kill the default }		if (heredsc.desclen > 0) and
{ if we're gonna put real }		(dsc = DEFAULT_LINE) then
{ texty in here }				dsc := 0;

{ no lines, delete existing }	if heredsc.desclen = 0 then
{ desc, if any }			delete_block(dsc)
				else if heredsc.desclen = 1 then begin
					if (dsc = 0) then begin
						if alloc_line(dsc) then;
						dsc := (- dsc);
					end else if dsc > 0 then begin
						delete_block(dsc);
						if alloc_line(dsc) then;
						dsc := (- dsc);
					end;

					if dsc < 0 then begin
						getline( abs(dsc) );
						oneliner.theline := heredsc.lines[1];
						putline;
					end;
{ more than 1 lines }		end else begin
					if dsc = 0 then begin
						if alloc_block(dsc) then;
					end else if dsc < 0 then begin
						dsc := (- dsc);
						delete_line(dsc);
						if alloc_block(dsc) then;
					end;

					if dsc > 0 then begin
						getblock(dsc);
						block := heredsc;
{ This is a fudge }				block.descrinum := dsc;
						putblock;
					end;
				end;
				done := true;
			     end;
			'r': edit_replace(n);
			'@': begin
				delete_block(dsc);
				dsc := DEFAULT_LINE;
				done := true;
			     end;
			'i': edit_doinsert(n);
			'q': begin
				grab_line('Throw away changes, are you sure? ',
				    s,eof_handler := leave);
				s := lowcase(s);
				if (s = 'y') or (s = 'yes') then begin
					done := true;
					edit_desc := false; { signal caller not to save }
				end;
			     end;
			otherwise writeln('-- Invalid command, type ? for a list.');
		end;
	until done;
end;

{ -------------------------------------------------------------------------- }

[global] procedure custom_global_desc(code: integer);
var val,lcv: integer;
begin
    if GF_Types[code] <> G_text then begin
	writeln('%Error in custom_global_desc:');
	writeln('%Global item #',code:1,' isn''t global desciption.');
	writeln('%Notify Monster Manager.');
    end else if not global_priv then begin
	writeln('You haven''t power for this.');
    end else begin
	case code of
	    GF_NEWPLAYER: writeln('Edit new player welcome text.');
	    GF_STARTGAME: Writeln('Edit welcome text.');
	    otherwise writeln('Edit global descibtion #',code:1,' (unknown).');
	end; { case }
	getglobal; freeglobal;
	val := global.int[code];
	if edit_desc(val) then begin
	    getglobal;
	    global.int[code] := val;
	    putglobal;
	    read_global := false;
	    writeln('Database is updated.');
	    for lcv :=1 to numevnts do
		log_event(0,E_GLOBAL_CHANGE,0,0,'',lcv);
	end else writeln('No changes.');
    end;
end; { custom_global_desc }


{ -------------------------------------------------------------------------- }

[global] function lookup_detail(var n: integer;s:string): boolean;
var
	i,poss,maybe,num: integer;
begin
	n := 0;
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxdetail do begin
		if s = here.detail[i] then
			num := i
		else if index(here.detail[i],s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;
	end;
	if num <> 0 then begin
		n := num;
		lookup_detail := true;
	end else if maybe = 1 then begin
		n := poss;
		lookup_detail := true;
	end else if maybe > 1 then begin
		lookup_detail := false;
	end else begin
		lookup_detail := false;
	end;
end;

{
User describe procedure.  If no s then describe the room

Known problem: if two people edit the description to the same room one of their
	description blocks could be lost.
This is unlikely to happen unless the Monster Manager tries to edit a
description while the room's owner is also editing it.
}
[global] PROCEDURE do_describe(s: string);
var
	i: integer;
	newdsc: integer;

begin
	gethere;
	if checkhide then begin
	if s = '' then begin { describe this room }
		if desc_allowed then begin
			log_action(desc,0);
			writeln('[ Editing the primary room description ]');
			newdsc := here.primary;
			if edit_desc(newdsc) then begin
				getroom;
				here.primary := newdsc;
				putroom;
			end;
			log_event(myslot,E_EDITDONE,0,0);
		end;
	end else begin{ describe a detail of this room }
		if length(s) > veryshortlen then
			writeln('Your detail keyword can only be ',veryshortlen:1,' characters.')
		else if desc_allowed then begin
			if not(lookup_detail(i,s)) then
			if not(alloc_detail(i,s)) then begin
				writeln('You have used all ',maxdetail:1,' details.');
				writeln('To delete a detail, DESCRIBE <the detail> and delete all the text.');
			end;
			if i <> 0 then begin
				log_action(e_detail,0);
				writeln('[ Editing detail "',here.detail[i],'" of this room ]');
				newdsc := here.detaildesc[i];
				if edit_desc(newdsc) then begin
					getroom;
					here.detaildesc[i] := newdsc;
					putroom;
				end;
				log_event(myslot,E_DONEDET,0,0);
			end;
		end;
	end;
{	clear_command;	}
	end;
end;

{ return TRUE if the player is allowed to program the object n
  if checkpub is true then obj_owner will return true if the object in
  question is public }

[global] function obj_owner(n: integer;checkpub: boolean := FALSE):boolean;
begin
	getobjown;
	freeobjown;
	if (objown.idents[n] = userid) or 
	    (owner_priv and (objown.idents[n] <> system_id)) or
	    manager_priv then begin { minor change by leino@finuha }
				    { and hurtta@finuh }
		obj_owner := true;
	end else if (objown.idents[n] = public_id) and (checkpub) then begin
		obj_owner := true;
	end else begin
		obj_owner := false;
	end;
end;

[global] function parse_pers(var pnum: integer;s: string): boolean;
var
	persnum: integer;
	i,poss,maybe,num: integer;
	pname: string;

begin
	gethere;
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to maxpeople do begin
{		if here.people[i].username <> '' then begin	}

		if here.people[i].kind > 0 then begin
			pname := lowcase(here.people[i].name);

			if s = pname then
				num := i
			else if index(pname,s) = 1 then begin
				maybe := maybe + 1;
				poss := i;
			end;
		end;
	end;
	if num <> 0 then begin
		persnum := num;
		parse_pers := true;
	end else if maybe = 1 then begin
		persnum := poss;
		parse_pers := true;
	end else if maybe > 1 then begin
		persnum := 0;
		parse_pers := false;
	end else begin
		persnum := 0;
		parse_pers := false;
	end;
	if persnum > 0 then begin
		if here.people[persnum].hiding > 0 then
			parse_pers := false
		else begin
			parse_pers := true;
			pnum := persnum;
		end;
	end;
end;

[global] function lookup_level(var n: integer;s:string): boolean;
var
	i,poss,maybe,num: integer;
begin
	n := 0;
	s := lowcase(s);
	i := 1;
	maybe := 0;
	num := 0;
	for i := 1 to levels do begin
		if s = lowcase (leveltable[i].name) then
			num := i
		else if index(lowcase (leveltable[i].name),s) = 1 then begin
			maybe := maybe + 1;
			poss := i;
		end;
	end;
	if num <> 0 then begin
		n := num;
		lookup_level := true;
	end else if maybe = 1 then begin
		n := poss;
		lookup_level := true;
	end else if maybe > 1 then begin
		lookup_level := false;
	end else begin
		lookup_level := false;
	end;
end; { lookup_level }


{ custom ROOM --------------------------------------------------------------- }


function room_nameinuse(num: integer; newname: string): boolean;
var
	dummy: integer;

begin
	if exact_room(dummy,newname) then begin
		if dummy = num then
			room_nameinuse := false
		else
			room_nameinuse := true;
	end else
		room_nameinuse := false;
end;



procedure do_rename(param: string);
label exit_label;
var
	dummy: integer;
	newname: string;
	s: string;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	gethere;
	if param > '' then newname := param
	else begin
		writeln('This room is named ',here.nicename);
		writeln;
		grab_line('New name? ',newname,eof_handler := leave);
	end;
	if (newname = '') or (newname = '**') then
		writeln('No changes.')
	else if length(newname) > shortlen then
		writeln('Please limit your room name to ',shortlen:1,' characters.')
	else if room_nameinuse(location,newname) then
		writeln(newname,' is not a unique room name.')
	else begin
		getroom;
		here.nicename := newname;
		putroom;

		getnam;
		nam.idents[location] := lowcase(newname);
		putnam;
		writeln('Room name updated.');
	end;
    exit_label:
end;


function obj_nameinuse(objnum: integer; newname: string): boolean;
var
	dummy: integer;

begin
	if exact_obj(dummy,newname) then begin
		if dummy = objnum then
			obj_nameinuse := false
		else
			obj_nameinuse := true;
	end else
		obj_nameinuse := false;
end;


procedure do_objrename(objnum: integer; param: string);
label exit_label;
var
	newname: string;
	s: string;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	getobj(objnum);
	freeobj;

	if param > '' then newname := param
	else begin
		writeln('This object is named ',obj.oname);
		writeln;
		grab_line('New name? ',newname,eof_handler := leave);
	end;
	if (newname = '') or (newname = '**') then
		writeln('No changes.')
	else if length(newname) > shortlen then
		writeln('Please limit your object name to ',shortlen:1,' characters.')
	else if obj_nameinuse(objnum,newname) then
		writeln(newname,' is not a unique object name.')
	else begin
		getobj(objnum);
		obj.oname := newname;
		putobj;

		getobjnam;
		objnam.idents[objnum] := lowcase(newname);
		putobjnam;
		writeln('Object name updated.');
	end;
    exit_label:
end;



procedure view_room;
var
	s: string;
	i: integer;

begin
	writeln;
	getnam;
	freenam;
	getobjnam;
	freeobjnam;

	with here do begin
		writeln('Room:        ',nicename);
		case nameprint of
			0: writeln('Room name not printed');
			1: writeln('"You''re in" precedes room name');
			2: writeln('"You''re at" precedes room name');
			3: writeln('"You''re in the" precedes room name');
			4: writeln('"You''re at the" precedes room name');
			5: writeln('"You''re in a" precedes room name');
			6: writeln('"You''re at a" precedes room name');
			7: writeln('"You''re in an" precedes room name');
			8: writeln('"You''re at an" precedes room name');
			otherwise writeln('Room name printing is damaged.');
		end;

		writeln('Room owner:    ',class_out(owner));

		if primary = 0 then
			writeln('There is no primary description')
		else
			writeln('There is a primary description');

		if secondary = 0 then
			writeln('There is no secondary description')
		else
			writeln('There is a secondary description');

		case which of
			0: writeln('Only the primary description will print');
			1: writeln('Only the secondary description will print');
			2: writeln('Both the primary and secondary descriptions will print');
			3: begin
				writeln('The primary description will print, followed by the seconary description');
				writeln('if the player is holding the magic object');
			   end;
			4: begin
				writeln('If the player is holding the magic object, the secondary description will print');
				writeln('Otherwise, the primary description will print');
			   end;
			otherwise writeln('The way the room description prints is damaged');
		end;

		writeln;
		if magicobj = 0 then
			writeln('There is no magic object for this room')
		else
			writeln('The magic object for this room is the ',objnam.idents[magicobj],'.');

		if objdrop = 0 then
			writeln('Dropped objects remain here')
		else begin
			writeln('Dropped objects go to ',nam.idents[objdrop],'.');
			if objdesc = 0 then
				writeln('Dropped.')
			else
				print_line(objdesc);
			if objdest = 0 then
				writeln('Nothing is printed when object "bounces in" to target room')
			else
				print_line(objdest);
		end;
		writeln;
		if trapto = 0 then
			writeln('There is no trapdoor set')
		else
			writeln('The trapdoor sends players ',direct[trapto],
				' with a chance factor of ',trapchance:1,'%');

		if hook > 0 then writeln ('There is a hook in this room.');
		for i := 1 to maxdetail do begin
			if length(detail[i]) > 0 then begin
				write('Detail "',detail[i],'" ');
				if detaildesc[i] > 0 then
					writeln('has a description')
				else
					writeln('has no description');
			end;
		end;
		writeln;
	end;
end;


[global] procedure custom_room;
label exit_label;
var
	done: boolean;
	prompt,param: string;
	n: integer;
	s: string;
	newdsc: integer;
	bool: boolean;
	prevloc: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


begin
	log_action(e_custroom,0);
	writeln;
	writeln('Customizing this room');
	writeln('If you would rather be customizing an exit, type CUSTOM <direction of exit>');
	writeln('If you would rather be customizing an object, type CUSTOM <object name>');
	writeln;
	done := false;
	prompt := 'Custom> ';

	repeat
		repeat
			grab_line(prompt,s,eof_handler := leave);
			param := slead(s);
			s := bite(param);
		until length(s) > 0;		
		s := lowcase(s);		
		case s[1] of
			'c': begin
				gethere;
				n := here.hook;
				prevloc := location;
				custom_hook(n,here.owner,
				    trim_filename(here.nicename));
				if (prevloc <> location) then begin
					writeln('You can no longer customize this room.');
                                        done := true;
				end else begin
                   			getroom;
					here.hook := n;
					putroom
				end;
			     end;
			'e','q': done := true;
			'?','h': command_help('*room help*');
			'r': do_rename (param);
			'v': view_room;
{dir trapdoor goes}	't': begin
				if param > '' then s := param
				else grab_line('What direction does the trapdoor exit through? ',
				    s,eof_handler := leave);
				if length(s) > 0 then begin
					if lookup_dir(n,s) then begin
						getroom;
						here.trapto := n;
						putroom;
						writeln('Room updated.');
					end else
						writeln('No such direction.');
				end else
					writeln('No changes.');
			     end;
{chance}		'f': begin
				if param > '' then s := param
				else begin
					writeln('Enter the chance that in any given minute the player will fall through');
					writeln('the trapdoor (0-100) :');
					writeln;
					grab_line('? ',s,eof_handler := leave);
				end;
				if isnum(s) then begin
					n := number(s);
					if n in [0..100] then begin
						getroom;
						here.trapchance := n;
						putroom;
					end else
						writeln('Out of range.');
				end else
					writeln('No changes.');
			     end;
			's': begin
				newdsc := here.secondary;
				writeln('[ Editing the secondary room description ]');
				if edit_desc(newdsc) then begin
					getroom;
					here.secondary := newdsc;
					putroom;
				end;
			     end;
			'i': begin
				newdsc := here.exitfail;
				writeln('[ Editing th default exit failure  description ]');
				if edit_desc(newdsc) then begin
					getroom;
					here.exitfail := newdsc;
					putroom;
				end;
			     end;
		 	'p': begin
{ same as desc }		newdsc := here.primary;
				writeln('[ Editing the primary room description ]');
				if edit_desc(newdsc) then begin
					getroom;
					here.primary := newdsc;
					putroom;
				end;
			     end;
			'o': begin
				writeln('Enter the line that will be printed when someone drops an object here:');
				writeln('If dropped objects do not stay here, you may use a # for the object name.');
				writeln('Right now it says:');
				if here.objdesc = 0 then
					writeln('Dropped. [default]')
				else
					print_line(here.objdesc);

				n := here.objdesc;
				make_line(n);
				getroom;
				here.objdesc := n;
				putroom;
			     end;
	  		'x': begin
				writeln('Enter a line that will be randomly shown.');
				writeln('Right now it says:');
				if here.rndmsg = 0 then
					writeln('[none defined]')
				else
					print_line(here.rndmsg);

				n := here.rndmsg;
				make_line(n);
				getroom;
				here.rndmsg := n;
				putroom;
			     end;
{alternate mystery msg}	'a': do_y_altmsg; 
{bounced in desc}	'b': begin
				writeln('Enter the line that will be displayed in the room where an object really');
				writeln('goes when an object dropped here "bounces" there:');
				writeln('Place a # where the object name should go.');
				writeln;
				writeln('Right now it says:');
				if here.objdest = 0 then
					writeln('Something has bounced into the room.')
				else
					print_line(here.objdest);

				n := here.objdest;
				make_line(n);
				getroom;
				here.objdest := n;
				putroom;
			     end;
{visual links}		'1': do_group1;
			'2': do_group2;
			'm': begin
				getobjnam;
				freeobjnam;
				if param > '' then s := param
				else begin
					if here.magicobj = 0 then
						writeln('There is currently no magic object for this room.')
					else
						writeln(objnam.idents[here.magicobj],
							' is currently the magic object for this room.');
					writeln;
					grab_line('New magic object? ',s,
					    eof_handler := leave);
				end;
				if s = '' then
					writeln('No changes.')
				else if lookup_obj(n,s) then begin
					getroom;
					here.magicobj := n;
					putroom;
					writeln('Room updated.');
				end else
					writeln('No such object found.');
			     end;
			'g': begin
				getnam;
				freenam;
				if param > '' then s := param
				else begin
					if here.objdrop = 0 then
						writeln('Objects dropped fall here.')
					else
						writeln('Objects dropped fall in ',nam.idents[here.objdrop],'.');
					writeln;
					writeln('Enter * for [this room]:');
					grab_line('Room dropped objects go to? ',
					    s,eof_handler := leave);
				end;
				if s = '' then
					writeln('No changes.')
				else if s = '*' then begin
					getroom;
					here.objdrop := 0;
					putroom;
					writeln('Room updated.');
				end else if lookup_room(n,s) then begin
					getroom;
					here.objdrop := n;
					putroom;
					writeln('Room updated.');
				end else
					writeln('No such room found.');
			     end;
			'd': begin
				writeln('Print room descriptions how?');
				writeln;
				writeln('0)  Print primary (main) description only [default]');
				writeln('1)  Print only secondary description.');
				writeln('2)  Print both primary and secondary descriptions together.');
				writeln('3)  Print primary description first; then print secondary description only if');
				writeln('    the player is holding the magic object for this room.');
				writeln('4)  Print secondary if holding the magic obj; print primary otherwise');
				writeln;
				grab_line('? ',s,eof_handler := leave);
				if isnum(s) then begin
					n := number(s);
					if n in [0..4] then begin
						getroom;
						here.which := n;
						putroom;
						writeln('Room updated.');
					end else
						writeln('Out of range.');
				end else
					writeln('No changes.');

			     end;
			'n': begin
				writeln('How would you like the room name to print?');
				writeln;
				writeln('0) No room name is shown');
				writeln('1) "You''re in ..."');
				writeln('2) "You''re at ..."');
				writeln('3) "You''re in the ..."');
				writeln('4) "You''re at the ..."');
				writeln('5) "You''re in a ..."');
				writeln('6) "You''re at a ..."');
				writeln('7) "You''re in an ..."');
				writeln('8) "You''re at an ..."');
				writeln;
				grab_line('? ',s,eof_handler := leave);
				if isnum(s) then begin
					n := number(s);
					if n in [0..8] then begin
						getroom;
						here.nameprint := n;
						putroom;
					end else
						writeln('Out of range.');
				end else
					writeln('No changes.');
			     end;
			otherwise writeln('Bad command, type ? for a list');
		end;
	until done;
	exit_label:
	log_event(myslot,E_ROOMDONE,0,0);
end;

{ custom EXIT -------------------------------------------------------------- }

[global] procedure exit_default(dir, kind: integer);
begin
	case kind of
	1: writeln('There is a passage leading ',direct[dir],'.');
	2: writeln('There is a locked door leading ',direct[dir],'.');
	5:	case dir of
			north,south,east,west:
				writeln('A note on the ',direct[dir],' wall says "Your exit here."');
			up: writeln('A note on the ceiling says "Your exit here."');
			down: writeln('A note on the floor says "Your exit here."');
		end;
	otherwise writeln('There is an exit: ',direct[dir]);
	end;
end;

procedure analyze_exit(dir: integer);
var
	s: string;

begin
	writeln;
	getnam;
	freenam;
	getobjnam;
	freeobjnam;
	with here.exits[dir] do begin
		s := alias;
		if s = '' then
			s := '(no alias)'
		else
			s := '(alias ' + s + ')';
		if here.exits[dir].reqalias then
			s := s + ' (required)'
		else
			s := s + ' (not required)';

		if toloc <> 0 then
			writeln('The ',direct[dir],' exit ',s,' goes to ',nam.idents[toloc])
		else
			writeln('The ',direct[dir],' exit goes nowhere.');
		if hidden <> 0 then
			writeln('Concealed.');
		write('Exit type: ');
		case kind of
			0: writeln('no exit.');
			1: writeln('Open passage.');
			2: writeln('Door, object required to pass.');
			3: writeln('No passage if holding object.');
			4: writeln('Randomly fails');
			5: writeln('Potential exit.');
			6: writeln('Only exists while holding the required object.');
			7: writeln('Timed exit');
		end;
		if objreq = 0 then
			writeln('No required object.')
		else
			writeln('Required object is: ',objnam.idents[objreq]);

		writeln;
		if exitdesc = DEFAULT_LINE then
			exit_default(dir,kind)
		else
			print_line(exitdesc);

		if success = 0 then
			writeln('(no success message)')
		else
			print_desc(success);

		if fail = DEFAULT_LINE then begin
			if kind = 5 then
				writeln('There isn'' an exit there yet.')
			else
				writeln('You can''t that.');
		end else
			print_desc(fail);

		if comeout = DEFAULT_LINE then
			writeln('# has come into the room from ',direct[dir])
		else
			print_desc(comeout);
		if goin = DEFAULT_LINE then
			writeln('# has gone ',direct[dir])
		else
			print_desc(goin);

		writeln;
		if autolook then
			writeln('LOOK automatically done after exit used')
		else
			writeln('LOOK supressed on exit use');
		if reqverb then
			writeln('The alias is required to be a verb for exit use')
		else
			writeln('The exit can be used with GO or as a verb');
	end;
	writeln;
end;


procedure get_key(dir: integer; param: string := '');
label exit_label;
var
	s: string;
	n: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;


begin
	getobjnam;
	freeobjnam;
	if param > '' then s := param
	else begin
		if here.exits[dir].objreq = 0 then
			writeln('Currently there is no key set for this exit.')
		else
			writeln(objnam.idents[here.exits[dir].objreq],' is the current key for this exit.');
		writeln('Enter * for [no key]');
		writeln;
	
		grab_line('What object is the door key? ',s,
		    eof_handler := leave);
	end;
	if length(s) > 0 then begin
		if s = '*' then begin
			getroom;
			here.exits[dir].objreq := 0;
			putroom;
			writeln('Exit updated.');
		end else if lookup_obj(n,s) then begin
			getroom;
			here.exits[dir].objreq := n;
			putroom;
			writeln('Exit updated.');
		end else
			writeln('There is no object by that name.');
	end else
		writeln('No changes.');
    exit_label:
end;

procedure custom_exit(dirnam: string);
label exit_label;
var
	prompt: string;
	done : boolean;
	s,param: string;
	dir,n: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	log_event(myslot,E_CUSTDONE,0,0);
	goto exit_label;
    end;

begin
	if lookup_dir(dir,dirnam) then begin
	   if can_alter(dir) then begin

		log_action(c_custom,0);

		writeln('Customizing ',direct[dir],' exit');
		writeln('If you would rather be customizing this room, type CUSTOM with no arguments');
		writeln('If you would rather be customizing an object, type CUSTOM <object name>');
		writeln('If you would rather be customizing a monster, type CUSTOM <monster name>');
		writeln;
		writeln('Type ** for any line to leave it unchanged.');
		writeln('Type return for any line to select the default.');
		writeln;
		writev(prompt,'Custom ',direct[dir],'> ');
		done := false;
		repeat
			repeat
				grab_line(prompt,s,eof_handler := leave);
				param := slead(s);
				s := bite(param);
			until length(s) > 0;
			s := lowcase(s);
			case s[1] of
				'?','h': command_help('*custom help*');
				'q','e': done := true;
				'k': get_key(dir,param);
				'c': begin
					writeln('Type the description that a player will see when the exit is found.');
					writeln('Make no text for description to unconceal the exit.');
					writeln;
					writeln('[ Editing the "hidden exit found" description ]');
	  				n := here.exits[dir].hidden;
					if edit_desc(n) then begin
						getroom;
						here.exits[dir].hidden := n;
						putroom;
					end;
				     end;
{req alias}			'r': begin
					getroom;
					here.exits[dir].reqalias :=
						not(here.exits[dir].reqalias);
					putroom;

					if here.exits[dir].reqalias then
						writeln('The alias for this exit will be required to reference it.')
					else
						writeln('The alias will not be required to reference this exit.');
				     end;
{req verb}			'x': begin
					getroom;
					here.exits[dir].reqverb :=
						not(here.exits[dir].reqverb);
					putroom;

					if here.exits[dir].reqverb then
						writeln('The exit name will be required to be used as a verb to use the exit')
					else
						writeln('The exit name may be used with GO or as a verb to use the exit');
				     end;
{autolook}			'l': begin
					getroom;
					here.exits[dir].autolook :=
						not(here.exits[dir].autolook);
					putroom;

					if here.exits[dir].autolook then
						writeln('A LOOK will be done after the player travels through this exit.')
					else
						writeln('The automatic LOOK will not be done when a player uses this exit.');
				     end;
				'a': begin
					if param > '' then s := param
	  				else grab_line('Alternate name for the exit? ',
					    s,eof_handler := leave);
					if length(s) > veryshortlen then
						writeln('Your alias must be less than ',veryshortlen:1,' characters.')
					else begin
						getroom;
						here.exits[dir].alias := lowcase(s);
						putroom;
					end;
				     end;
				'v': analyze_exit(dir);
				't': begin
					writeln;
					writeln('Select the type of your exit:');
					writeln;
					writeln('0) No exit');
					writeln('1) Open passage');
					writeln('2) Door (object required to pass)');
					writeln('3) No passage if holding key');
					if special_priv then { minor change by leino@finuha }
						writeln('4) exit randomly fails');
					writeln('6) Exit exists only when holding object');
					if special_priv then { minor change by leino@finuha }
						writeln('7) exit opens/closes invisibly every minute');
					writeln;
					grab_line('Which type? ',s,
					    eof_handler := leave);
					if isnum(s) then begin
						n := number(s);
						if ((n in [4,7]) and special_priv)
						or (n in [0..3,6]) then begin { minor hack by jlaiho@finuha }
							getroom;
							here.exits[dir].kind := n;
							putroom;
							writeln('Exit type updated.');
							writeln;
							if n in [2,6] then
								get_key(dir);
						end else
							writeln('Bad exit type.');
					end else
						writeln('Exit type not changed.');
				     end;
				'f': begin
					writeln('The failure description will print if the player attempts to go through the');
					writeln('the exit but cannot for any reason.');
					writeln;
	  				writeln('[ Editing the exit failure description ]');

					n := here.exits[dir].fail;
					if edit_desc(n) then begin
						getroom;
						here.exits[dir].fail := n;
						putroom;
					end;
				     end;
				'i': begin
					writeln('Edit the description that other players see when someone goes into');
					writeln('the exit.  Place a # where the player''s name should appear.');
					writeln;
					writeln('[ Editing the exit "go in" description ]');
					n := here.exits[dir].goin;
					if edit_desc(n) then begin
						getroom;
						here.exits[dir].goin := n;
						putroom;
					end;
				     end;
				'o': begin
					writeln('Edit the description that other players see when someone comes out of');
					writeln('the exit.  Place a # where the player''s name should appear.');
					writeln;
					writeln('[ Editing the exit "come out of" description ]');
					n := here.exits[dir].comeout;
					if edit_desc(n) then begin
						getroom;
						here.exits[dir].comeout := n;
						putroom;
					end;
				     end;
{ main exit desc }		'd': begin
					writeln('Enter a one line description of the exit.');
					writeln;
					n := here.exits[dir].exitdesc;
					make_line(n);
					getroom;
					here.exits[dir].exitdesc := n;
					putroom;
				     end;
				's': begin
					writeln('The success description will print when the player goes through the exit.');
					writeln;
					writeln('[ Editing the exit success description ]');

					n := here.exits[dir].success;
					if edit_desc(n) then begin
						getroom;
						here.exits[dir].success := n;
						putroom;
					end;
				     end;
				otherwise writeln('-- Bad command, type ? for a list');
			end;
		until done;
	   end else
		writeln('You are not allowed to alter that exit.');

		log_event(myslot,E_CUSTDONE,0,0);
	end else writeln('Unknown direction.');
    exit_label:

end;

[global] PROCEDURE do_custom(dirnam: string);
var	n: integer;
	t: o_type;
	fi,ta: string; { first and tail }
begin
    gethere;
    if checkhide then begin
	ta := dirnam;
	fi := bite(ta);

	if length(dirnam) = 0 then begin
	    if is_owner(location,TRUE) then
		custom_room
	    else begin
		writeln('You are not the owner of this room; you cannot customize it.');
		writeln('However, you may be able to customize some of the exits.  To customize an');
		writeln('exit, type CUSTOM <direction of exit>');
	    end;
	end else if lookup_dir(n,dirnam) then 
	    custom_exit(dirnam)
	else if lookup_type(t,fi,pl := FALSE) then begin
	    case t of 
		t_none: writeln('%Error in DO_CUSTOM. Notify Monster Manager.');
		t_room: begin
		    if ta > '' then writeln('You can only custom this room.')
		    else if is_owner(location,TRUE) then custom_room
		    else writeln('You are not the owner of this room; you cannot customize it.');
		end;
		t_object: do_program(ta);
		t_spell:  writeln('Use SET SPELL <spell name> to customize spell.');
		t_monster: custom_monster(ta);
		t_player: begin
		    if manager_priv then writeln('Use SYSTEM to customize player.')
		    else writeln('You can''t customize player.');
		end;
	    end; { case }
	end else if lookup_obj(n,dirnam) then
{ if lookup_obj returns TRUE then dirnam is name of object to customize }
	    do_program(dirnam)	{ customize the object }
        else if lookup_pers(n,dirnam) then
	    custom_monster(dirnam)
	else begin
	    writeln('To customize this room, type CUSTOM');
	    writeln('To customize an exits, type CUSTOM <direction>');
	    writeln('To customize an object, type CUSTOM <object name>');
	    writeln('To customize a monster, type CUSTOM <monster name>');
	end;
{	clear_command;	}
	end;
end;

{ custom OBJECT ------------------------------------------------------------- }


{ support for do_program (customize an object)
  Give the player a list of kinds of object he's allowed to make his object
  and update it }

procedure prog_kind(objnum: integer);
label exit_label;
var
	n: integer;
	s: string;
	p: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
	writeln('Select the type of your object:');
	writeln;
	writeln(O_BLAND:3,	'    Ordinary object (good for door keys)');
	writeln(O_WEAPON:3,	'    Weapon');
	writeln(O_ARMOR:3,	'    Armor');
{	writeln(O_THRUSTER:3,	'    Exit thruster');	}
	writeln(O_DISGUISE:3,	'    Disguise');
	writeln(O_BOOK:3,       '    Magic book.');
              
	writeln(O_TRAP:3,	'    Trap (bites if player fails to get it)'); { O_TRAP }
	if special_priv then begin { minor change by leino@finuha }
		writeln;
{		writeln(O_BAG:3,	'    Bag');	}
		writeln(O_CRYSTAL:3,	'    Crystal Ball');
{		writeln(O_WAND:3,	'    Wand of Power');	}
{		writeln(O_HAND:3,	'    Hand of Glory');	}
		writeln(O_TELEPORT_RING:3,'    Teleport Ring');
		writeln(O_HEALTH_RING:3,'    Health Ring');
	end;
	writeln;
	if wizard and special_priv then begin
		writeln(O_MAGIC_RING:3,	'    Magic Ring');
		writeln;
	end;

	grab_line('Which kind? ',s,eof_handler := leave);

	if isnum(s) then begin
		n := number(s);
		if (n >= 100) and (not special_priv) 
			or (n >= 200) and (not wizard) then
			writeln('Out of range.')
		else if n in [O_BLAND,O_WEAPON,O_ARMOR,
			O_DISGUISE,O_CRYSTAL,O_MAGIC_RING,
			O_TELEPORT_RING,O_HEALTH_RING,
			O_BOOK, O_TRAP] then begin
			getobj(objnum);
			{ clear parms }
			for p := 1 to maxparm do obj.parms[p] := 0;
                        obj.kind := n;
			putobj;         
          
                        writeln('Object updated.');
		end else
			writeln('Out of range.');
	end;
    exit_label:
end;
      

{ support for do_program (customize an object)
  Based on the kind it is allow the
  user to set the various parameters for the effects associated with that
  kind }

Procedure program_weapon (objnum: integer);
label exit_label;
Var attack_power: Integer;
    required_experience: Integer;
    n,top,lev: integer;
    s: string;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
{ getobj (objnum);
   freeobj;  }   { prog_obj do this already }

   writeln ('Use 3 to edit failure attack message');
   writeln ('Use 4 to edit attack success message');
   writeln ('Use x to edit attack success message, what victim sees.');
   writeln ('Use 5 to edit attack success message, what others see.');
   writeln;

   attack_power := obj.ap;
   required_experience := obj.exreq;
   lev := level(myexperience);
   top := leveltable[lev].maxpower;

   writeln ('Select attack power of this weapon: 0 - ',top:1);
   writeln ('Current attack power is ',attack_power:1);
   grab_line ('Power? ',s,eof_handler := leave);
   if isnum (s) then begin
     n := number (s);
     if (n >= 0) and (n <=top) then 
       begin
         attack_power := n; 
         getobj (objnum);
         obj.ap := attack_power;
         putobj;
         writeln ('Updated.');

       end
     else writeln ('Out of range.');  
   end else writeln('No such power.');
   writeln;

   writeln ('Select required experience to use this weapon: 0 - ',
      maxexperience:1);
   writeln ('Current required experience is ',required_experience:1);
   grab_line ('Experience? ',s,eof_handler := leave);
   if isnum (s) then begin
     n := number (s);
     if (n >=0) and (n <= maxexperience) then
       begin
         required_experience := n;
         getobj (objnum);
         obj.exreq := required_experience;
         putobj;
         writeln ('Updated.');
       end else writeln ('Out of range.');
   end else writeln ('No such experience.');
   writeln;

    exit_label:

end;                                 

Procedure program_book (objnum: integer);
label exit_label;
Var spell: Integer;
    required_experience: Integer;
    n: integer;
    s: string;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
{ getobj (objnum);
   freeobj;  }   { prog_obj do this already }

   spell := obj.parms[OP_SPELL];
   required_experience := obj.exreq;
   getspell_name;
   freespell_name;


   writeln ('Select spell for this magic book.');

   if spell > 0 then 
      writeln ('Current spell is ',spell_name.idents[spell])
   else writeln('Current spell is <none>');
   grab_line ('Spell? ',s,eof_handler := leave);
   if lookup_spell(n,s) then begin
       if is_spell_owner(n,public_ok := true) then
       begin
         spell := n; 
         getobj (objnum);
         obj.parms[OP_SPELL] := spell;
         putobj;
         writeln ('Updated.');
       end
     else writeln ('You aren''t owner of this spell.');  
   end else writeln('No such spell.');
   writeln;

   writeln ('Select required experience to use this magic book: 0 - ',
      maxexperience:1);
   writeln ('Current required experience is ',required_experience:1);
   grab_line ('Experience? ',s,eof_handler := leave);
   if isnum (s) then begin
     n := number (s);
     if (n >=0) and (n <= maxexperience) then
       begin
         required_experience := n;
         getobj (objnum);
         obj.exreq := required_experience;
         putobj;
         writeln ('Updated.');
       end else writeln ('Out of range.');
   end else writeln ('No such experience.');
   writeln;

   exit_label:
end;                                 

procedure program_trap (objnum: integer);
label exit_label;
var attack_power: integer;
    n,top,lev: integer;
    s: string;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
{ getobj (objnum);
   freeobj;  }   { prog_obj do this already }
   
   writeln ('Use f to edit what victim sees when (s)he tries to get trap.');
   writeln ('Use x to edit what others see when someone fails to get trap');

   writeln;
   writeln ('Attack power that the trap uses when it bites someone');
   attack_power := obj.ap;
   lev := level(myexperience);
   top := leveltable[lev].maxpower;

   writeln ('Select attack power, range is 0 - ',top:1);
   writeln ('Current attack power is ',attack_power:1);
   grab_line ('Power? ',s,eof_handler := leave);
   if isnum (s) then begin
     n := number (s);
     if (n >= 0) and (n <=top) then 
       begin
         attack_power := n;            
         getobj (objnum);
         obj.ap := attack_power;
         putobj;
         writeln ('Updated.');

       end
     else writeln ('Out of range.');  
   end else writeln('No such power.');
   exit_label:
end;               

procedure program_armor(objnum: integer);
label exit_label;
var attack_power: integer;
    n,top,lev: integer;
    s: string;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	goto exit_label;
    end;

begin
{ getobj (objnum);
   freeobj;  }   { prog_obj do this already }
   writeln ('Protection rate of armor');
   attack_power := obj.ap;
   lev := level(myexperience);
   top := leveltable[lev].maxpower;

   writeln ('Select protection rate, range is 0 - ',top:1);
   writeln ('Current protection rate is ',attack_power:1);
   grab_line ('Power? ',s,eof_handler := leave);
   if isnum (s) then begin
     n := number (s);
     if (n >= 0) and (n <=top) then 
       begin
         attack_power := n;            
         getobj (objnum);
         obj.ap := attack_power;
         putobj;
         writeln ('updated.');

       end
     else Writeln ('Out of range.');  
   end else writeln('No such power.');
   exit_label:
end;               

procedure prog_obj(objnum: integer);
var object_type: integer;
begin             
  getobj (objnum);
  freeobj;
 
  object_type := obj.kind;
  case object_type of
	O_BLAND : WriteLn ('You can''t program ordinary object.');            
	O_WEAPON: program_weapon (objnum);       
	O_TRAP: program_trap(objnum);
	O_ARMOR: program_armor(objnum);
	O_DISGUISE: Writeln ('You can''t program disguise.');
	O_BOOK: program_book(objnum);
    otherwise  WriteLn ('This kind of object is not supported here.')
  end; { case }
end;


[global] PROCEDURE show_kind(p: integer; cr: boolean := true);
var s: string;
begin
	case p of
		O_BLAND:    s := 'Ordinary object';
		O_WEAPON:   s := 'Weapon';
		O_ARMOR:    s := 'Armor';
       		O_TRAP:     s := 'Trap';
		O_DISGUISE: s := 'Disguise';
		O_BOOK:	    s := 'Magic book';
		O_BAG:      s := 'Bag';
		O_CRYSTAL:  s := 'Crystal Ball';
		O_WAND:     s := 'Wand of Power';
		O_HAND:     s := 'Hand of Glory';
		O_TELEPORT_RING:  s := 'Teleport Ring';
		O_HEALTH_RING:    s := 'Health Ring';
		O_MAGIC_RING:     s := 'Magic Ring';
		otherwise   s := 'Bad object type';
	end;
	if cr then writeln(s)
	else write(lowcase(s));
end;

procedure obj_view(objnum: integer);
begin
	writeln;
	getobj(objnum);
	freeobj;
	getobjown;
	freeobjown;
	writeln('Object name:    ',obj.oname);
	if objown.idents[objnum] = public_id then writeln('Public')
	else if objown.idents[objnum] = disowned_id then writeln('Disowned')
	else writeln('Owner:          ',class_out(objown.idents[objnum]));
	writeln;
	show_kind(obj.kind);
	writeln;

	if obj.linedesc = 0 then
		writeln('There is a(n) # here')
	else
		print_line(obj.linedesc);

	if obj.examine = 0 then
		writeln('No inspection description set')
	else
		print_desc(obj.examine);

{	writeln('Worth (in points) of this object: ',obj.worth:1);	}
	if obj.home > 0 then begin
	    getnam;
	    freenam;
	    writeln('Home of this object is ',nam.idents[obj.home]);
	end;
	if obj.kind in [O_WEAPON,O_ARMOR,O_TRAP] then 
		writeln ('Power of this object: ',obj.ap:1);
	if obj.kind in [O_WEAPON,O_BOOK] then
		writeln ('Required experience to use this object: ',obj.exreq:1);
        if obj.kind = O_BOOK then begin
		getspell_name; freespell_name;
		if obj.parms[OP_SPELL] > 0 then
		    writeln('Spell name of this object: ',
			spell_name.idents[obj.parms[OP_SPELL]])
		else writeln('Spell name of this object: <none>');
	end;
	if obj.actindx > 0 then
		writeln ('In this object is a hook.')
	else writeln ('No hook in this object.');
	writeln('Number in existence: ',obj.numexist:1);
	writeln;
end;




PROCEDURE do_program;	{ (object_name: string);  declared forward }
label exit_label;
var
	prompt: string;
	done : boolean;
	s,param: string;
	objnum: integer;
	n: integer;
	newdsc: integer;

    procedure leave;
    begin
	writeln('EXIT - no changes.');
	log_event(myslot,E_OBJDONE,objnum,0);
	goto exit_label;
    end;


begin
    gethere;
    if checkhide then begin
	if object_name = '' then writeln('To customize an object, type CUSTOM OBJECT <object name>.')
	else if lookup_obj(objnum,object_name) then begin
	    if not is_owner(location,TRUE) then begin
		writeln('You may only work on your objects when you are in one of your own rooms.');
	    end else if obj_owner(objnum) then begin
		log_action(e_program,0);
		writeln;
		writeln('Customizing object');
		writeln('If you would rather be customizing an EXIT, type CUSTOM <direction of exit>');
		writeln('If you would rather be customizing this room, type CUSTOM');
		writeln;
		getobj(objnum);
		freeobj;
		if (obj.kind = O_MAGIC_RING) and not wizard then begin
			writeln ('That kind of object may be customized only by Monster Manager.');
			done := true;
		end else done := false;
		prompt := 'Custom object> ';
		while not done do begin
			repeat
				grab_line(prompt,s,eof_handler := leave);
				param := slead(s);
				s := bite(param)
			until length(s) > 0;
			s := lowcase(s);
			case s[1] of
				'?','h': command_help('*program help*');
				'q','e': done := true;
				'v': obj_view(objnum);
				'r': do_objrename(objnum,param);
				'c': begin
					getobj(objnum);
					freeobj;
					n := obj.actindx;
					{ obj_owner is made getobjown }
					{ lookup_obj is made getobjnam }
					custom_hook(n,objown.idents[objnum],
					    trim_filename(
						objnam.idents[objnum])
					    );
					getobj(objnum);
					obj.actindx := n;
					putobj;
				     end;
				'g': begin
					if param > '' then s := param
					else begin
						writeln('Enter * for no object');
						grab_line('Object required for GET? ',
						    s,eof_handler := leave);
					end;
					if s = '*' then begin
						getobj(objnum);
						obj.getobjreq := 0;
						putobj;
					end else if lookup_obj(n,s) then begin
						getobj(objnum);
						obj.getobjreq := n;
						putobj;
						writeln('Object modified.');
					end else
						writeln('No such object.');
				     end;
				'7': begin
					if param > '' then s := param
					else begin
						writeln('Enter * for no home.');
						writeln('Set home of object. ');
						grab_line('Home? ',s,
						    eof_handler := leave);
					end;
					if s = '*' then begin
						getobj(objnum);
						obj.home := 0;
						putobj;
						writeln('Object modified.');
					end else if lookup_room(n,s) then begin
					    gethere(n);
					    if (here.owner <> userid) and 
						    (not owner_priv) then
						    writeln('Can''t set home to others room')
					    else begin
						getobj(objnum);
						obj.home := n;
						putobj;
						writeln('Object modified.');
					    end;
					end else writeln('No such room.');
				     end;
				'u': begin
					if param > '' then s := param
					else begin
						writeln('Enter * for no object');
						grab_line('Object required for USE? ',
						    s,eof_handler := leave);
					end;
					if s = '*' then begin
						getobj(objnum);
						obj.useobjreq := 0;
						putobj;
					end else if lookup_obj(n,s) then begin
						getobj(objnum);
						obj.useobjreq := n;
						putobj;
						writeln('Object modified.');
					end else
						writeln('No such object.');
				     end;
				'2': begin
					if param > '' then s := param
					else begin
						writeln('Enter * for no special place');
						grab_line('Place required for USE? ',
						    s,eof_handler := leave);
					end;
					if s = '*' then begin
						getobj(objnum);
						obj.uselocreq := 0;
						putobj;
					end else if lookup_room(n,s) then begin
						getobj(objnum);
						obj.uselocreq := n;
						putobj;
						writeln('Object modified.');
					end else
						writeln('No such object.');
				     end;
				's': begin
					getobj(objnum);
					obj.sticky := not(obj.sticky);
					putobj;
					if obj.sticky then
						writeln('The object will not be takeable.')
					else
						writeln('The object will be takeable.');
				     end;
				'a': begin
					writeln;
	  				writeln('Select the article for your object:');
					writeln;
					writeln('0)	None                ex: " You have taken Excalibur "');
					writeln('1)	"a"                 ex: " You have taken a small box "');
					writeln('2)	"an"                ex: " You have taken an empty bottle "');
					writeln('3)	"some"              ex: " You have picked up some jelly beans "');
					writeln('4)     "the"               ex: " You have picked up the Scepter of Power"');
					writeln;
					grab_line('? ',s,eof_handler := leave);
					if isnum(s) then begin
						n := number(s);
						if n in [0..4] then begin
							getobj(objnum);
							obj.particle := n;
							putobj;
						end else
							writeln('Out of range.');
					end else
						writeln('No changes.');
				     end;
				'k': begin
					prog_kind(objnum);
				     end;
				'p': begin
					prog_obj(objnum);
				     end;
				'd': begin
					newdsc := obj.examine;
					writeln('[ Editing the description of the object ]');
					if edit_desc(newdsc) then begin
						getobj(objnum);
						obj.examine := newdsc;
						putobj;
					end;
				     end;
				'x': begin
					newdsc := obj.d1;
					writeln('[ Editing extra description #1 ]');
					if obj.kind = O_WEAPON then 
                                          WriteLn ('Victim sees this. ',
						'# attacks you.')
					else if obj.kind = O_TRAP then
		    			  writeln ('Others see this. ',
						'# tries to get a trap.');
                                        if edit_desc(newdsc) then begin
						getobj(objnum);
						obj.d1 := newdsc;
						putobj;
					end;
				     end;
				'5': begin
					newdsc := obj.d2;
					writeln('[ Editing extra description #2 ]');
					if obj.kind = O_WEAPON then
                                          WriteLn ('Others see this. ',
						'# is attacker.');
                                        if edit_desc(newdsc) then begin
						getobj(objnum);
						obj.d2 := newdsc;
						putobj;
					end;
				     end;
				'f': begin
					newdsc := obj.getfail;
					writeln('[ Editing the get failure description ]');
					if edit_desc(newdsc) then begin
						getobj(objnum);
						obj.getfail := newdsc;
						putobj;
					end;
				     end;
				'1': begin
					newdsc := obj.getsuccess;
					writeln('[ Editing the get success description ]');
					if edit_desc(newdsc) then begin
						getobj(objnum);
						obj.getsuccess := newdsc;
						putobj;
					end;
				     end;
				'3': begin
					newdsc := obj.usefail;
					writeln('[ Editing the use failure description ]');
					if edit_desc(newdsc) then begin
						getobj(objnum);
						obj.usefail := newdsc;
						putobj;
					end;
				     end;
				'6': begin
					newdsc := obj.homedesc;
					writeln('[ Editing the home description ]');
					if edit_desc(newdsc) then begin
						getobj(objnum);
						obj.homedesc := newdsc;
						putobj;
					end;
				     end;
				'4': begin
					newdsc := obj.usesuccess;
					writeln('[ Editing the use success description ]');
					if obj.kind = O_WEAPON then
						writeln ('# is victim.');
					if edit_desc(newdsc) then begin
						getobj(objnum);
						obj.usesuccess := newdsc;
						putobj;
					end;
				     end;
				'l': begin
					writeln('Enter a one line description of what the object will look like in any room.');
					writeln('Example: "There is an as yet unknown object here."');
					writeln;
					getobj(objnum);
					freeobj;
					n := obj.linedesc;
					make_line(n);
					getobj(objnum);
					obj.linedesc := n;
					putobj;
				     end;
				otherwise writeln('-- Bad command, type ? for a list');
			end;
		end;
		log_event(myslot,E_OBJDONE,objnum,0);

	end else
		writeln('You are not allowed to program that object.');
	end else
		writeln('There is no object by that name.');
	end;
	exit_label:
end;

{ --------------------------------------------------------------------------- }
[global] PROCEDURE type_paper;
var c_file: text;
    count,errorcode: integer;
    line: string;
    continue: boolean;

    procedure leave;
    begin
	writeln('EXIT');
	line  := '-';
    end;

begin
   open(c_file,root+'COMMANDS.PAPER',HISTORY := READONLY,
      sharing := READONLY ,error := continue);
   errorcode := status(c_file);
   if errorcode > 0 then begin
      case errorcode of
	3: { PAS$K_FILNOTFOU } writeln('%File COMMANDS.PAPER not found.');
	otherwise writeln('%Can''t open file COMMANDS.PAPER, error code (status): ',
	    errorcode:1);
      end; { case }
      writeln('% Notify Monster Manager.');
   end else begin
      reset(c_file);
      count := 0;
      continue := true;
      while not eof(c_file) and continue do begin
         readln(c_file,line);
         writeln(line);
         count := count +1;
         if count > terminal_page_len -2 then begin
            grab_line('-more-',line,,true,eof_handler := leave);
            continue := line = '';
            count := 0;
         end;
      end;
      close(c_file);
   end;
end; { type_paper }

procedure do_y_altmsg;
var
	newdsc: integer;

begin
	if is_owner then begin
		gethere;
		newdsc := here.xmsg2;
		writeln('[ Editing the alternate mystery message for this room ]');
		if edit_desc(newdsc) then begin
			getroom;
			here.xmsg2 := newdsc;
			putroom;
		end;
	end;
end;


procedure do_group1;
label exit_label;
var
	grpnam: string;
	loc: integer;
	tmp: string;

    procedure leave;
    begin
	writeln('EXIT - No changes.');
	goto exit_label;
    end;

	
begin
	if is_owner then begin
		gethere;
		if here.grploc1 = 0 then
			writeln('No primary group location set')
		else begin
			getnam;
			freenam;
			writeln('The primary group location is ',nam.idents[here.grploc1],'.');
			writeln('Descriptor string: [',here.grpnam1,']');
		end;
		writeln;
		writeln('Type * to turn off the primary group location');
		grab_line('Room name of primary group? ',grpnam,
		    eof_handler := leave);
		if length(grpnam) = 0 then
			writeln('No changes.')
		else if grpnam = '*' then begin
			getroom;
			here.grploc1 := 0;
			putroom;
		end else if lookup_room(loc,grpnam) then begin
			writeln('Enter the descriptive string.  It will be placed after player names.');
			writeln('Example:  Monster Manager is [descriptive string, instead of "here."]');
			writeln;
			grab_line('Enter string? ',tmp,
			    eof_handler := leave);
			if length(tmp) > shortlen then begin
				writeln('Your string was truncated to ',shortlen:1,' characters.');
				tmp := substr(tmp,1,shortlen);
			end;
			getroom;
			here.grploc1 := loc;
			here.grpnam1 := tmp;
			putroom;
		end else
			writeln('No such room.');
	end;
    exit_label:
end;

procedure do_group2;
label exit_label;
var
	grpnam: string;
	loc: integer;
	tmp: string;

    procedure leave;
    begin
	writeln('EXIT - No changes.');
	goto exit_label;
    end;

begin
	if is_owner then begin
		gethere;
		if here.grploc2 = 0 then
			writeln('No secondary group location set')
		else begin
			getnam;
			freenam;
			writeln('The secondary group location is ',nam.idents[here.grploc2],'.');
			writeln('Descriptor string: [',here.grpnam2,']');
		end;
		writeln;
		writeln('Type * to turn off the secondary group location');
		grab_line('Room name of secondary group? ',grpnam,
		    eof_handler := leave);
		if length(grpnam) = 0 then
			writeln('No changes.')
		else if grpnam = '*' then begin
			getroom;
			here.grploc2 := 0;
			putroom;
		end else if lookup_room(loc,grpnam) then begin
			writeln('Enter the descriptive string.  It will be placed after player names.');
			writeln('Example:  Monster Manager is [descriptive string, instead of "here."]');
			writeln;
			grab_line('Enter string? ',tmp,
			    eof_handler := leave);
			if length(tmp) > shortlen then begin
				writeln('Your string was truncated to ',shortlen:1,' characters.');
				tmp := substr(tmp,1,shortlen);
			end;
			getroom;
			here.grploc2 := loc;
			here.grpnam2 := tmp;
			putroom;
		end else
			writeln('No such room.');
	end;
    exit_label:
end;

{ custom MONSTER ------------------------------------------------------------ }

procedure view2_monster(mid: integer);
begin
    getpers;
    freepers;
    writeln('Monster     : ',pers.idents[mid]);
    getint(N_EXPERIENCE);
    freeint;
    writeln(' experience : ',anint.int[mid]:1);
    writeln(' level      : ',leveltable[level(anint.int[mid])].name);
    getint(N_HEALTH);
    freeint;
    writeln(' health     : ',anint.int[mid]:1);
    getint(N_PRIVILEGES);
    freeint;
    write  (' privileges : '); list_privileges(uint(anint.int[mid]));
    writeln;
    getint(N_SELF);
    freeint;
    if (anint.int[mid] = 0) or (anint.int[mid] = DEFAULT_LINE) then
	writeln('Monster haven''t the self-description.')
    else print_desc(anint.int[mid]);
end; { view2_monster }

procedure lister(code: integer);
label 0; { out }
var count: integer;

    procedure leave;
    begin
	writeln('EXIT');
	goto 0;
    end;


    procedure print(l: mega_string);
    var s: string;
    begin
	writeln(l);
	count := count +1;
	if count > terminal_page_len -2 then begin
	    grab_line('-more-',s,erase := true,eof_handler := leave);
	    if s > '' then goto 0;
	    count := 0;
	end;
    end; { print }

begin
    count := 0;
    list_program(code,print,terminal_line_len);
    0:
end; { lister }

procedure lister_2(code: integer; param: string);
label exit_label;
var list_file: text;
    name: string;
    counter,errorcode: integer;
    s: string;

    procedure print(l: mega_string);
    begin
	counter := counter + 1;
	if (counter mod 50) = 0 then checkevents(TRUE);
	writeln(list_file,l);
    end; { print }

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;

begin
    counter := 0;
    if param = '' then begin
	writeln('File name for listing ?');
	writeln('Default: MDL.LIS');
	grab_line('File name? ',s,eof_handler := leave);
    end else s := param;
    open(list_file,s,new,default := 'MDL.LIS',error := continue);
    errorcode := status(list_file);
    if errorcode > 0 then case errorcode of
	4: { PAS$K_INVFILSYN } writeln('Illegal file name.');
	otherwise writeln('Can''t open file for writing, error code (status): ',
	    errorcode:1)
    end {case }
    else begin
	rewrite(list_file);
	list_program(code,print,terminal_line_len);
	close(list_file);
    end;
    exit_label:
end; { lister_2 }
               
PROCEDURE custom_monster; { (name: string); forward; }
label exit_label;
var s,param,def: string;
    done,ok: boolean;
    mid,mslot,code,self,oldloc,old: integer;
    mname: shortstring;     
    notice: shortstring;
    lev,max,value,health,exp,i: integer;
    prevloc: integer;

    procedure leave;
    begin
	writeln('EXIT');
        log_event (myslot,E_MONSTERDONE,0,0,'');
	goto exit_label;
    end;


begin
  oldloc := location;
  if not is_owner(location,TRUE) then { is_owner make gethere }
     writeln('You must be in one of your own rooms to customize a monster.')
  else if name = '' then writeln('To customize a monster, type CUSTOM MONSTER <monster name>.')
  else if parse_pers(mslot,name) then begin

     mname := here.people[mslot].name;
     def := trim_filename(mname);

     if exact_pers(mid,mname) then begin    
        if here.people[mslot].kind = P_MONSTER then begin
           code := here.people[mslot].parm;
           if (monster_owner(code) = userid) or owner_priv then begin
              log_action (e_custommonster,0);
              done := false;
              repeat
		prevloc := location;
                grab_line ('Custom monster> ',s,eof_handler := leave);
                param := lowcase(s);
		s := bite(param);
                getint(N_LOCATION);
                freeint;
		if prevloc <> location then begin
		   writeln('You can no longer customize this monster.');
                   done := true;
                end else if anint.int[mid] <> location then begin
                   writeln ('Monster is no longer here.');
                   done := true
                end else if s > '' then case s[1] of
                  'h','?': command_help('*monster help*');
                  'a'    : begin 
                             lev := level(myexperience);
			     if lev = levels then max := maxexperience
			     else if leveltable[lev+1].exp > maxexperience then
				 max := maxexperience
			     else max := leveltable[lev+1].exp -1;
                             if param > '' then s := param
                             else begin
                                write('Give monster''s level ');
                                write(leveltable[1].name,' - ');
				writeln(leveltable[lev].name);
				writeln('or experience 0 - ',max:1,'.');
                                grab_line('Level or experience? ',s,
				    eof_handler := leave);
                             end;
			     value := -1;
                             if lookup_level(value,s) then begin
				 value := leveltable[value].exp;
			     end else if isnum(s) then begin
				 value := number(s);
				 if (value < 0) or (value > max) then begin
				     writeln('Out of range.');
				     value := -1;
				 end;
			     end else begin
				 writeln('Not such level or experience.');
				 value := -1
			     end;
			     if userid <> MM_userid then begin
				if leveltable[level(value)].hidden and 
				    (level(value) <> lev) then begin
				    writeln('You can give only your own hidden level.');
				    value := -1;
				end else if level(value) > lev then begin
				    writeln('Not allowed.');
				    value := -1;
				end;
			    end;
			    if value >= 0 then begin
				exp := value; 
                                lev := level(value);
                                health := leveltable[lev].health * goodhealth 
                                   div 10;
          
                                getroom;
                                here.people[mslot].health := health;
                                here.people[mslot].experience := exp;
                                putroom;
                                getint(N_HEALTH);
                                anint.int[mid] := health;
                                putint;
                                getint(N_EXPERIENCE);
                                anint.int[mid] := exp;
                                putint;
                                writeln('Monster''s experience is now ',exp:1);
                                writeln('and health is ',health:1);
                             end;
                           end;
		  'i'    : begin
			     getint(N_EXPERIENCE);
			     freeint;
			     lev := level(anint.int[mid]);
			     max := leveltable[lev].health;
			     if param > '' then s := param
			     else begin
				writeln('Give monster''s health 0 - ',max:1);
				grab_line('Health? ',s,eof_handler := leave);
			    end;
			    if not isnum(s) then
				writeln('Not such value.')
			    else if (number(s) < 0) or (number(s) > max) then
				writeln('Out of range.')
			    else begin
				health := number(s);
                                getroom;
                                here.people[mslot].health := health;
                                putroom;
                                getint(N_HEALTH);
                                anint.int[mid] := health;
                                putint;
				writeln('Database updated.');
			    end;
			end;
                  'b'    : set_runnable(code,false);
                  'c'    : type_paper;
                  'd'    : begin
                             getint(N_PRIVILEGES);
                             freeint;
                             value := anint.int[mid];
                             if custom_privileges(value,
				read_cur_priv) then begin
                                getint(N_PRIVILEGES);
                                anint.int[mid] := value;
                                putint;
                                writeln('Database updated.');
                             end else writeln('Database not updated.');
                           end;
                  'p'    : if monster_priv then monsterpriv(code)
                           else writeln ('This command is for Monster Manager.');
                  'f'    : set_runnable(code,true);
                  'v'    : begin
			       view2_monster(mid);
			       grab_line('-more-',s,erase := true,
				    eof_handler := leave);
			       if s = '' then view_monster(code);
			   end;
                  'm'    : begin
                             if param > '' then s := param
                             else grab_line('Label? ',s,eof_handler := leave);
                             if s > '' then begin
                                if length(s) > shortlen then
                                  s := substr(s,1,shortlen);
                                if not run_monster(mname,code,s,'','',
                                   sysdate+' '+systime)
                                   then writeln ('Label not found or monster is dead.');
                                if oldloc <> location then begin
                                   writeln('You are no longer customizing monster.');
                                   done := true;
                                end;
                             end;
                           end;
                  'g'    : begin
                             if param > '' then s := param
                             else begin
				writeln('Default: ',def);
				grab_line('File name? ',s,eof_handler := leave);
			     end;
			     load(code,s,sysdate+' '+systime,userid,def);
			     getint(N_PRIVILEGES);
			     value := anint.int[mid];
			     anint.int[mid] := 0;
			     putint;
			     if value <> 0 then writeln('Monster''s privilege set is now empty.');
                           end;
		  'j'    : begin
			     if get_flag(code,CF_NO_CONTROL) then begin
				set_flag(code,CF_NO_CONTROL,false);
				getint(N_PRIVILEGES);
				value := anint.int[mid];
				anint.int[mid] := 0;
				putint;
				if value <> 0 then writeln('Monster''s pprivilege set is now empty.');
			     end else set_flag(code,CF_NO_CONTROL,TRUE);
			     writeln('Databse updated.');
			   end;
                  's'    : begin
                             writeln ('Edit monster self description');
                             getint(N_SELF);
                             freeint;
                             self := anint.int[mid];
                             if edit_desc(self) then begin
                                getroom;
                                here.people[mslot].self := self;
                                putroom;
                                getint(N_SELF);
                                anint.int[mid] := self;
                                putint;
                             end;
                           end;
                  'l'    : lister (code);
		  'o'	 : lister_2 (code,param);
                  'n'    : begin
                              if param > '' then s := param
                              else grab_line ('New name? ',s,eof_handler := leave);
                              if s = '' then writeln ('No changes')
                              else if length(s) > shortlen then
                                 writeln('Limit new name to ',shortlen:1,' characters.')
                              else if lowcase(s) = 'monster manager' then
                                 writeln ('That name is reserved for the Monster Manager.')
                              else begin
                                 if exact_pers(old,s) then
                                    if old = mid then ok := true
                                    else begin
                                       ok := false;
                                       writeln ('Someone already has that name.');
                                    end
                                 else ok := true;
                                 if ok then begin
                                    getroom;
                                    notice := here.people[mslot].name;
                                    here.people[mslot].name := s;
                                    putroom;
                                    getpers;
                                    pers.idents[mid] := s;
                                    putpers;
                                    mname := s;
                                    log_event(0,E_SETNAM,0,0,notice+' is now known as ' + s);
                                 end
                              end;
                           end;
                  'e','q': done := true;
                   otherwise writeln ('Enter ? for help.');
                end; { case }
              until done;                
              log_event (myslot,E_MONSTERDONE,0,0,'');
           end else writeln ('You are not the owner of this monster.');
        end else writeln ('You can only customize monsters.');
     end else writeln ('%serius error in custom_monster. Notify monster manager.');
  end else writeln ('That monster isn''t here.');
   exit_label:

end;	{ custom_monster }

{ custom HOOK --------------------------------------------------------------- }

PROCEDURE custom_hook {(var code: integer; owner: shortstring;
			default: string := '.MDL')};
label exit_label;
var done: boolean;
    s,param: string;

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;


begin
  if code = 0 then begin { alloc code }
     if alloc_general(I_HEADER,code) then begin
        create_program (code,owner,sysdate+' '+systime);
        writeln ('New hook created.');
     end else begin
        writeln ('There is no place for any more hooks in this universe.');
        code := 0
     end;
  end;
  if code > 0 then begin
     done := false;
     repeat
        grab_line ('Custom hook> ',s,eof_handler := leave);
        param := lowcase(s);
	s := bite(param);
        if s > '' then case s[1] of
           'h','?': command_help('*hook help*');
           'b'    : set_runnable(code,false);
           'c'    : type_paper;
           'p'    : if monster_priv then monsterpriv(code)
                    else writeln ('This command is for Monster Manager.');
           'f'    : set_runnable(code,true);
           'v'    : view_monster(code);
           'm'    : begin
                       if param > '' then s := param
                       else grab_line('Label? ',s,eof_handler := leave);
                       if s > '' then begin
                          if length(s) > shortlen then
                             s := substr(s,1,shortlen);
                          if not run_monster('',code,s,'','',
                             sysdate+' '+systime)
                             then writeln ('Label not found.');
                       end;
                    end;
           'g'    : begin
                       if param > '' then s := param
                       else begin
			    writeln('Default: ',default);
			    grab_line('File name? ',s,eof_handler := leave);
		       end;
		       load(code,s,sysdate+' '+systime,userid,default);
                    end;                       
           'l'    : lister (code);
	   'o'	  : lister_2 (code,param);
           'e','q': done := true;
           'd'    : begin
                       delete_program(code);
                       delete_general(I_HEADER,code);
                       done := true;
                       code := 0;
                       writeln ('Hook deleted.');
                    end;
           otherwise writeln ('Enter ? for help.');
       end; { case }
     until done;
  end;
  exit_label:
end;

{ custom SPELL --------------------------------------------------------------- }

[global] PROCEDURE custom_spell(s: string);
label exit_label;

var done: boolean;
    param: string;
    code: integer; owner: shortstring;
    default: string;

    procedure leave;
    begin
	writeln('EXIT');
	log_event(myslot,E_SPELLDONE,0,0,'');
	goto exit_label;
    end;

    var new: boolean;
	sid,player: integer;
begin
  if (s = '') or (s = '?') then 
    writeln('Use SET SPELL <spell name> to customize spell.')
  else begin
    new := not lookup_spell(sid,s);
  
    if new then begin
	code := 0;
	if alloc_general(I_SPELL,sid) then begin
	    getspell_name;
	    spell_name.idents[sid] := s;
	    putspell_name;

	    if alloc_general(I_HEADER,code) then begin
		create_program (code,userid,sysdate+' '+systime);
		getint(N_SPELL);
		anint.int[sid] := code;
		putint;

		getindex(I_PLAYER);
		freeindex;
		for player := 1 to indx.top do if not indx.free[player] then
		    begin
			getspell(player);
			spell.level[sid] := 0;
			putspell;
		    end;
		writeln ('New spell created.');
		       		
	    end else begin
		writeln ('There is no place for any more spell codes in this universe.');
		code := 0;
		getspell_name;
		spell_name.idents[sid] := '';
		putspell_name;
		delete_general(I_SPELL,sid);
	    end;
	end else writeln('There is no place for any more spells in this universe.');

    end else begin
	getint(N_SPELL);
	freeint;
	code := anint.int[sid];

	if not is_spell_owner(sid) then
	    begin
		writeln('You haven''t owner of this spell.');
		code := 0;
	    end;
    end;

    if code > 0 then begin
       getspell_name;
       freespell_name;
       default := trim_filename(spell_name.idents[sid]);
       log_action(e_customspell,0);

       done := false;
       repeat
        grab_line ('Custom spell> ',s,eof_handler := leave);
        param := lowcase(s);
	s := bite(param);
        if s > '' then case s[1] of
           'h','?': command_help('*spell help*');
           'b'    : set_runnable(code,false);
           'c'    : type_paper;
           'p'    : if monster_priv then monsterpriv(code)
                    else writeln ('This command is for Monster Manager.');
           'f'    : set_runnable(code,true);
           'v'    : view_monster(code);
           'm'    : begin
                       if param > '' then s := param
                       else grab_line('Label? ',s,eof_handler := leave);
                       if s > '' then begin
                          if length(s) > shortlen then
                             s := substr(s,1,shortlen);
                          if not run_monster('',code,s,'','',
                             sysdate+' '+systime)
                             then writeln ('Label not found.');
                       end;
                    end;
           'g'    : begin
                       if param > '' then s := param
                       else begin
			    writeln('Default: ',default);
			    grab_line('File name? ',s,eof_handler := leave);
		       end;
		       if get_flag(code, CF_SPELL_MODE) then 
			    set_flag(code, CF_SPELL_MODE,FALSE);
		       load(code,s,sysdate+' '+systime,userid,default);
                    end;                       
           'l'    : lister (code);
	   'o'	  : lister_2 (code,param);
           'e','q': done := true;
           'd'    : begin
                       delete_program(code);
                       delete_general(I_HEADER,code);

		       getspell_name;
		       spell_name.idents[sid] := '';
		       putspell_name;
		       getint(N_SPELL);
		       anint.int[sid] := 0;
		       putint;

		       delete_general(I_SPELL,sid);
                       done := true;
                       code := 0;
                       writeln ('Spell deleted.');
                    end;
		'i': begin
                       if param > '' then s := param
                       else begin
			    writeln('Seting your level of this spell.');
			    grab_line('Level? ',s,eof_handler := leave);
		       end;
			
		       if isnum(s) then begin
			  if number(s) < 0 then writeln('Must be positive or zero.')
			  else begin
			    getspell(mylog);
			    spell.level[sid] := number(s);
			    putspell;
			    writeln('Database modified');
			end;
		       end else writeln('Invalid number.');
			 
		     end;
           'a'	  : if get_flag(code, CF_SPELL_MODE) then 
			set_flag(code, CF_SPELL_MODE,FALSE)
		    else if not spell_priv then 
			writeln('You haven''t power for this.')
		    else set_flag(code, CF_SPELL_MODE,TRUE);
           otherwise writeln ('Enter ? for help.');
       end; { case }
       until done;
       log_event (myslot,E_SPELLDONE,0,0,'');
     end;
  end;
  exit_label:
end;

{ Global Code --------------------------------------------------------------- }

[global] procedure exec_global(flag: integer; label_name: shortstring; 
	force_read: boolean := false; variable: shortstring := '';
	value: mega_string := '');
var code: integer;
begin
    if Gf_Types [ flag] <> G_code then begin
	writeln('%Error in exec_global:');
        writeln('%Global value #',flag:1,' isn''t global MDL code');
	writeln('%Notify Monster Manager.');
	code := 0;
    end else begin
	if read_global or force_read then begin
	    getglobal;
	    freeglobal;
	    read_global := false;
	end;
	code := global.int[flag];
    end;

    if code <> 0 then 
	run_monster(monster_name := '',
		    code := code,
		    label_name := label_name,
		    variable := variable,
		    value := value,
		    time := sysdate + ' ' + systime);

end; { exec_global }

PROCEDURE custom_g_code(var code: integer);
label exit_label;

var done: boolean;
    param: string;
    default,s: string;

    procedure leave;
    begin
	writeln('EXIT');
	goto exit_label;
    end;

begin
    if code = 0 then begin
	if alloc_general(I_HEADER,code) then begin
	    create_program (code,system_id,sysdate+' '+systime);

	    writeln ('New global MDL code created.');
		       		
	end else begin
	    writeln ('There is no place for any more codes in this universe.');
	    code := 0;
	end;
    end;

    if code > 0 then begin
       default := 'GLOBAL_CODE';

       done := false;
       repeat
        grab_line ('Custom global code> ',s,eof_handler := leave);
        param := lowcase(s);
	s := bite(param);
        if s > '' then case s[1] of
           'h','?': command_help('*global c help*');
           'b'    : set_runnable(code,false);
           'c'    : type_paper;
           'f'    : set_runnable(code,true);
           'v'    : view_monster(code);
           'm'    : begin
                       if param > '' then s := param
                       else grab_line('Label? ',s,eof_handler := leave);
                       if s > '' then begin
                          if length(s) > shortlen then
                             s := substr(s,1,shortlen);
                          if not run_monster('',code,s,'','',
                             sysdate+' '+systime)
                             then writeln ('Label not found.');
                       end;
                    end;
           'g'    : begin
                       if param > '' then s := param
                       else begin
			    writeln('Default: ',default);
			    grab_line('File name? ',s,eof_handler := leave);
		       end;
		       load(code,s,sysdate+' '+systime,userid,default);
                    end;                       
           'l'    : lister (code);
	   'o'	  : lister_2 (code,param);
           'e','q': done := true;
           'd'    : begin
                       delete_program(code);
                       delete_general(I_HEADER,code);

                       code := 0;
                       writeln ('Code deleted.');
		       done := true;
                    end;
           otherwise writeln ('Enter ? for help.');
       end; { case }
       until done;
     end;
   exit_label:
end;

[global] procedure custom_global_code(code: integer);
var val,lcv: integer;
begin
    if GF_Types[code] <> G_code then begin
	writeln('%Error in custom_global_code:');
	writeln('%Global item #',code:1,' isn''t global MDL code.');
	writeln('%Notify Monster Manager.');
    end else begin
	case code of
	    GF_CODE: writeln('Customize global hook.');
	    otherwise writeln('Edit global code #',code:1,' (unknown).');
	end; { case }
	getglobal; freeglobal;
	val := global.int[code];
	custom_g_code(val);
	getglobal;
	global.int[code] := val;
	putglobal;
	read_global := false;
        writeln('Database is updated.');
	for lcv :=1 to numevnts do log_event(0,E_GLOBAL_CHANGE,0,0,'',lcv);
    end;
end; { custom_global_code }


{ --------------------------------------------------------------------------- }

{ TO BEGIN DO ; }
 
{ TO END DO ; }

END.
