[environment,inherit ('sys$library:starlet','global')]


MODULE guts(input,output);
{+
COMPONENT: Low level interfase to VMS
 
PROGRAM DESCRIPTION:
 
    
 
AUTHORS:
 
    Rich Skrenta
    Antti Leino
    Kari Hurtta
 
CREATION DATE: Unknow
 
DESIGN ISSUES:
 

 
MODIFICATION HISTORY:
 
     Date     |   Name  | Description
--------------+---------+-------------------------------------------------------
    28.5.1992 | Hurtta	| Partially rewritten, new do_dcl and grab_line
    31.5.1992 |		| This header, database poll time in check timer 
              |         | changed from 0 ::2 to 0 ::1 (ie. one second).
    10.6.1992 |         | in grab_line 'terminator not seen' action changed
    14.7.1992 |		| open_terminal, close_terminal, terminal argument to
	      |		| to grab_line
    15.7.1992 |         | ESCape sequence length check
-}

 
const
        SHORT_WAIT = 0.1;
        LONG_WAIT = 0.2;
        maxcycle = 10;          { attempting to fine tune nextkey }

	smg$_eof = 1213442;	{ ei määritelly starlet.pas:issa vaan 
				    smsg$routines.pas }

        base_efn = 32;		{ ensimmäisen EF:n numero tässä EF clusterissa }
	tmr_efn = 33;		{ timer eventflag }
 
type

	$UBYTE = [BYTE] 0..255;
        { $uword is declared in glopal.pas }
	$UQUAD = [QUAD,UNSAFE] RECORD
		L0,L1:UNSIGNED; END;

	terminal_t = $uword;

        ident = packed array[1..12] of char;
                              
        iosb_type = record
                cond: $uword;
                trans: $uword;
                junk: unsigned; {longword}
        end;
 
        il3 = record
             buflen : $uword;
             itm    : $uword;
             baddr  : unsigned;
             laddr  : unsigned;
        end;
 
 
var

        save_dcl_ctrl:  unsigned;
        out_chan,inp_chan: [volatile] $uword;

{       vaxid:          [global] packed array[1..12] of char;
        line:           [global] string; }
        old_prompt: [global] string; 
 

	need_reprint : boolean := false;

        seed: integer;
 
        user_rec,uname:varying[31] of char;
        sts:integer;
        il:array[1..2] of il3;
        key:$uword;
 
        userident: [global] ident;

	Terminal: [ global ] Boolean := false; 
	DecCRT:	  [ global ] Boolean := False; { least vt100 }
	Terminal_line_len: [global] integer := 80; { default = 80 }
	Terminal_page_len: [global] integer := 24; { default = 24 }

	grab_next: [global ] integer := 0;

	cur_position : Integer := 0;	{ 0 is leftmost column	}

	leave_monster : boolean := false;
	eof_counter   : integer := 0;

[asynchronous, external (lib$signal)]     
function lib$signal (
   %ref status : [unsafe] unsigned) : unsigned; external;
 
[asynchronous, external (str$trim)]
function str$trim (
   destination_string : [class_s] packed array [$l1..$u1:integer] of char;
   source_string : [class_s] packed array [$l2..$u2:integer] of char;
   %ref resultant_length : $uword) : unsigned; external;

 
[asynchronous, external (lib$disable_ctrl)]
function lib$disable_ctrl (
    %ref disable_mask : unsigned;
    %ref old_mask : unsigned := %immed 0) : unsigned; external;
 
[asynchronous, external (lib$enable_ctrl)]
function lib$enable_ctrl (
    %ref enable_mask : unsigned;
    %ref old_mask : unsigned := %immed 0) : unsigned; external;
 

[asynchronous] 
procedure syscall( s: [unsafe] unsigned );
 
begin
   if not odd( s ) then begin
      lib$signal( s );
   end;
end;
 
 
[external,asynchronous]
function mth$random(var seed: integer): real;
external;


[global]
procedure quit_monster;
begin
    leave_monster := true;
    eof_counter := 0;
end; { quit_monster }
 
[global]
function random: real;
 
begin
        random := mth$random(seed);
end;
 
[global]
function rnd100: integer;       { random int between 0 & 100, maybe }
 
begin
        rnd100 := round(mth$random(seed)*100);
end;
 
 
[external] function lib$wait(seconds:[reference] real):integer;
external;
 
[global]
procedure wait(seconds: real);
 
begin
        syscall( lib$wait(seconds) );
end;
 
[external] procedure checkevents(silent: boolean := false);
extern;
 

function check_timer(force: boolean := false): boolean;
var code: unsigned;
    time: $uquad;
begin
    syscall ($readef (base_efn,code));
    if (uand(code,2 ** (tmr_efn-base_efn)) > 0) or force then begin
	syscall($clref (tmr_efn));
	syscall($bintim (database_poltime,time)); { yksi sekuntti laukeamiseen }
	syscall($setimr (tmr_efn,time,,)); (* remove final flags param *)
	check_timer := true;
    end else check_timer := false;
end; { check_timer }
                     
[global]
procedure doawait(time: real);
 
begin
        syscall( lib$wait(time) );
end;
 
 
[global]
function trim(s: string): string;
var
        tmp: [static] string := '';
 
begin
        syscall( str$trim(tmp.body,s,tmp.length) );
        trim := tmp;
end;
 
 
[global]
function get_userid: string;
 
begin
  il:=zero;
  il[1].itm    := jpi$_username;
  il[1].buflen := size(user_rec.body);
  il[1].baddr  := iaddress(user_rec.body);
  il[1].laddr  := iaddress(user_rec.length);
  syscall($getjpiw(,,,il));
  syscall( str$trim(uname.body,user_rec,uname.length) );
  userident := user_rec;
  get_userid := uname;
end;
 
 
[global,asynchronous]
procedure putchars(s: mega_string; channel: integer := -1);
var
        msg: packed array[1..MEGA_LENGTH] of char;
        len: integer;
 
begin
        msg := s;
        len := length(s);
	if channel >= 0 then 
	    syscall($qiow(,channel,
		io$_writevblk+io$m_refresh,,,,msg,len,,,,))
        else 
	    syscall($qiow(,out_chan,io$_writevblk,,,,msg,len,,,,));
end;

[external(LIB$GETDVI)]	{ Uses SYS$GETDVI, but it is too	}
Function GetDvi	(		{ complicated,so I use library routine	}
	%REF	ItemCode:		$uword;          
	%REF	Channel:		$uword		:= %IMMED 0;
	%DESCR	DeviceName:		String		:= %IMMED 0;
	%REF	OutValue:		Unsigned	:= %IMMED 0;
	%DESCR	OutString:		String		:= %IMMED 0
	):	Integer;	Extern;



[global]
procedure reprint_grab;
begin
    if need_reprint then putchars(''(13),inp_chan);
end;


[global]
procedure grab_line(prompt:string; var s:string;echo:boolean := true;
                    erase: boolean := false; edit_mode: boolean := false;
		    procedure eof_handler;
		    channel: integer := -1);
label again,out;
Const	max_line = size(s.body);
	Lines = 100;
	grab_efn = 34;
	max_esc = 10;

	ESC_NONE = 0;
	ESC_RETURN = 1;
	ESC_EOF = 2;
	ESC_F10 = 3;
	ESC_B   = 4;
	ESC_UP1 = 5;
	ESC_UP2 = 6;
	ESC_UP3	= 7;
	ESC_UP4 = 8;
	ESC_DOWN1 = 9;
	ESC_DOWN2 = 10;
	ESC_DOWN3 = 11;
	ESC_DOWN4 = 12;

	ESC_LAST = 12;

type	Line_buffer = Array [ 1 .. Lines ] of string;

        item = record
	    len:   $uword;
	    code:  $uword;
	    addr:  [long] unsigned;
	    rtradr: [long] unsigned;
	end;
var
        esc_table : [static] array [ 0 .. ESC_LAST] of shortstring :=
	    ( '',	    { ESC_NONE }
	      ''(13),	    { ESC_RETURN }
	      ''(26),	    { ESC_EOF }
	      ''(27)'[21~', { ESC_F10 }
	      ''(2),	    { ESC_B }
	      ''(27)'[A',   { ESC_UP1 }
	      ''(155)'A',   { ESC_UP2 }
	      ''(27)'OA',   { ESC_UP3 }
	      ''(143)'A',   { ESC_UP4 }
	      ''(27)'[B',   { ESC_DOWN1 }
	      ''(155)'B',   { ESC_DOWN2 }
	      ''(27)'OB',   { ESC_DOWN3 }
	      ''(143)'B');   { ESC_DOWN4 }
	      


        mask:	    unsigned;
	end_grab:   boolean;
	code:	    unsigned;
	start: [volatile] string;
	line:	    string;
	area:	    [volatile] packed array [ 1 .. max_line + max_esc ] of char;
	modifiers:  unsigned;
	iosb:	    [volatile] record
	    status: [volatile] $uword;
	    offtrm: [volatile] $uword;
	    trmchr: [volatile] $ubyte;
	    reserved: [volatile] $ubyte;
	    trmlen: [volatile] $ubyte;
	    crspos: [volatile] $ubyte;
	end;

	buffer	: [static] Line_buffer;	{ saved values		}
	used	: [static] 0 .. Lines := 0;	{ between calls 	}
        current : 1 .. Lines;
	maxlen,i  : integer;
	itemlist : array [ 1 .. 4 ] of item;

        result  : unsigned;
	terminator : shortstring;
	esccode : integer;
	eof_detected : boolean;
	have_deccrt : boolean;

      procedure erase_line;
      begin
	if echo then begin		
	    if have_deccrt Then putchars(chr(13)+chr(27)+'[K',channel)
	    else begin 
		putchars(chr(13),channel);			
		for i := 1 to length (prompt) + length(line) do
		putchars(' ',channel);			
		putchars(chr(13),channel);			
	    end;
	end; 
      end; { erase_line }

    var tmp : terminal_t;
begin
   mask := 2 ** (grab_efn-base_efn) + 2 ** (tmr_efn-base_efn);
   end_grab := false;
   modifiers := 0;
   eof_detected := false;
   have_deccrt := false;

   if channel < 0 then channel := inp_chan;
   tmp := channel;

   syscall(GetDvi(DVI$_TRM,tmp,,result));
   if not odd(result) then begin
	if channel <> inp_chan then begin
	    writeln('%Error on grab_line. Notify Monster manager.');
	    writeln('%Given terminal argument don''t point to terminal.');
	end else writeln('SYS$INPUT must point to terminal !!!');
	HALT;
   end;
   syscall(GetDvi(DVI$_TT_DECCRT,tmp,,result));
   have_deccrt := odd(result);

   putchars(''(13)''(10),channel);

   line := ''; start := '';

   if not edit_mode then begin                  
      if used < lines then begin 
         used := used +1;
         current := used;                          
         buffer [current] := ''
      end else begin				
         current := lines;
         for i := 1 to lines - 1 do buffer [i] := buffer [i+1];
         buffer [current] := '';
      end;              
   end else start := s;

  again:

  modifiers := uor(uor(TRM$M_TM_ESCAPE,TRM$M_TM_TRMNOECHO),TRM$M_TM_NORECALL); 
  if not echo then modifiers := uor(modifiers,TRM$M_TM_NOECHO);

  itemlist[1].len := 0;
  itemlist[1].code := TRM$_ESCTRMOVR;
  itemlist[1].addr := MAX_ESC;
  itemlist[1].rtradr := 0;    { escape koodin koko }
  itemlist[2].len := prompt.length;
  itemlist[2].code := TRM$_PROMPT;
  itemlist[2].addr := IADDRESS(prompt.body);
  itemlist[2].rtradr := 0;
  itemlist[3].len := start.length;
  itemlist[3].code := TRM$_INISTRNG;
  itemlist[3].addr := IADDRESS(start.body);
  itemlist[3].rtradr := 0;
  itemlist[4].len := 0;
  itemlist[4].code := TRM$_MODIFIERS;
  itemlist[4].addr := modifiers;
  itemlist[4].rtradr :=  0;

  iosb := zero;

  need_reprint := true;
  area := ' ';

  syscall($clref(grab_efn));
  syscall($qio( efn  := grab_efn,
		chan := channel,
	        func := IO$_READVBLK+IO$M_EXTEND,
		iosb := iosb,
		p1   := area,
		p2   := size(area),
		p5   := iaddress(itemlist),
		p6   := size(itemlist)));

  end_grab := false;
  while not end_grab do  { odotetaan loppumista }
    begin
      
      syscall($wflor(base_efn,mask));   { odotetaan että timerin tai IO:n
				      EF laukeaa }

      if (check_timer) then checkevents; 
			{ check_timer myöskin laittaa timeri uudestaan }
			{ käyntiin. alunperin se on käynistetty }
			{ setup_guts:issa }

    if leave_monster then begin
	syscall($cancel(channel));
	if eof_counter > 10 then begin
	    putchars(chr(10)+chr(13)+
		'%quit monster failed. Notify Monster Manager.'+chr(13),
		channel);
	    leave_monster := false;
	    goto again;
	end else begin
	    eof_counter  := eof_counter +1;
	    eof_detected := true;
	    goto out;
	end;
    end;

      syscall ($readef (base_efn,code));
      end_grab := uand(code,2 ** (grab_efn-base_efn)) > 0; { Onko IO päättynyt }
    end;

  syscall(iosb.status); { if failed .. > out }
  line := '';
  for i := 1 to iosb.offtrm do line := line + area[i];
  if iosb.trmlen > max_esc then begin
	putchars(''(10)''(13),channel);
	writeln('Too long ESCape sequence.');
	start := line;
	goto again;
  end;

  terminator := '';
  for i := 1 to iosb.trmlen do terminator := terminator + area[iosb.offtrm+i];

  esccode := -1;
  for i := 0 to ESC_LAST do if esc_table[i] = terminator then esccode := i;

  case esccode of
     -1: begin	    
	    putchars(''(10)''(13),channel);
	    writeln('Unknown function key.');
	    start := line;
	    goto again;
	end;
     ESC_NONE: begin
	    putchars(''(10)''(13),channel);
	    writeln('Terminator not seen.');
	    if length(line) >= max_line then
		line := substr(line,1,max_line-1);
	    start := line;
	    goto again;
	end;
     ESC_RETURN: begin
	    grab_next := 0;
	    ;
	end;
     ESC_EOF, ESC_F10: begin
	    eof_detected := true;
	    grab_next := 0;
	end;
     ESC_B, ESC_UP1, ESC_UP2, ESC_UP3, ESC_UP4: begin
	    if edit_mode then grab_next := -1
	    else begin 
		if current > 1 then current := current -1;    
		putchars(''(13)''(0),channel);
		erase_line;
		start := buffer[current];
		goto again;
	    end;
	end;
     ESC_DOWN1, ESC_DOWN2, ESC_DOWN3, ESC_DOWN4: begin
	    if edit_mode then grab_next := 1
	    else begin 
		if current < used then current := current +1;    
		putchars(''(13)''(0),channel);
		erase_line;
		start := buffer[current];
		goto again;
	    end;
	end;
    otherwise halt;
  end; { case }

  need_reprint := false;

  out:

 if erase then erase_line
 else putchars(''(13)''(0),channel);			
 if not edit_mode then begin			
    if echo then buffer [used] := line	
    else buffer [used] := ''			
    end;

    old_prompt := prompt;
    s := line;					
    if eof_detected then eof_handler;

end; { grab_line }       			{ end of grab line	}


[external(LIB$SPAWN)] 
   Function SPAWN      ( %DESCR command_string:     string := %IMMED 0; 
                         %DESCR input_file:         string := %IMMED 0;
                         %DESCR output_file:        string := %IMMED 0;
                         %REF   flags:              unsigned := %IMMED 0;
                         %DESCR process_name:       STRING := %IMMED 0;         
                         %REF   process_id:         unsigned := %IMMED 0;
                         %REF   completion_status:  integer := %IMMED 0;
			 %REF   completion_efn:     integer := %IMMED 0;
                         %REF   AST:  [unsafe]      integer := %IMMED 0;
                                ASTarg: [unsafe]    integer := %IMMED 0;
                         %DESCR prompt:             STRING  := %IMMED 0;
                         %DESCR cli:                STRING  := %IMMED 0
                       ): unsigned; EXTERNAL;

[global]
function open_terminal(name: string; var trm: terminal_t): boolean;
var result: unsigned;
begin
	result := $assign(name,trm);
	if not odd (result) then open_terminal := false
	else begin
	    syscall(GetDvi(DVI$_TRM,trm,,result));
	    if not odd (result) then begin
		syscall($dassgn(trm));
		open_terminal := false;
	    end else open_terminal := true;
	end;
end; { open_terminal }

[global]
procedure close_terminal(trm: terminal_t);
begin
    syscall($dassgn(trm));
end; { close_terminal }

Procedure ReadTerminalType;     { By Kari Hurtta }
Var result: Unsigned;
Begin
  if not odd (GetDvi (DVI$_TRM,,'SYS$OUTPUT',result)) then
	terminal := false		{ Some bad failure (?) }
  Else 	Terminal := Odd (Result);       { Is this terminal 	}
  
  If terminal then begin
	if not odd (GetDvi (DVI$_TT_DECCRT,,'SYS$OUTPUT',result)) then
		DecCrt := false		{ some bad failure (?)	}
	else	DecCrt := Odd (result)
  End;

    if not odd (GetDvi(DVI$_DEVBUFSIZ,,'SYS$OUTPUT',result)) then
	terminal_line_len := 80		{ some wrong so default }
    else terminal_line_len := int(result);

    if not odd (GetDvi(DVI$_TT_PAGE,,'SYS$OUTPUT',result)) then
	terminal_page_len := 24		{ some wrong so default }
    else terminal_page_len := int(result);

end; { ReadTerminalType }
                                         
[ global]
procedure setup_guts;
var
        border: unsigned;
        rows,cols: integer;
        mask: unsigned;
 
begin
        seed := clock;
        old_prompt := '';
      
	ReadTerminalType;
 
    syscall($assign('SYS$OUTPUT',out_chan));
    syscall($assign('SYS$INPUT',inp_chan));

    syscall($clref(tmr_efn));		{ timer not yet launced }
    check_timer(force := true);		{ activate timer }


   mask := %X'02000000';        { CTRL/Y  Just for DCL }
{ mask := ...21... for ctrl-t too }
   syscall( lib$disable_ctrl( mask, save_dcl_ctrl )); 
 
end;
 
[global]
procedure finish_guts;
 
begin
	
       syscall( lib$enable_ctrl(save_dcl_ctrl));       { re-enable dcl ctrls }
end;


[global]            
Procedure do_dcl (command: string := '');

Const dcl_efn = 32;		{ EF:n numero }
                     
Var end_dcl: boolean;           { True kun aliohjelma suoritettu loppuun }
    code:    unsigned;           { Tapahtumalipun tila }
    succeed: boolean;           { onnistuiko käsky }
    Id:      unsigned;          { prosessin pid }
    name:    string;            { prosessin nimi }
    mask:    unsigned;
Begin     
  mask := 2 ** (dcl_efn-base_efn) + 2 ** (tmr_efn-base_efn);
  
  name := Substr ('_'+userident,1,10); 
  
  WriteLn ('Control switch to child-process: ',name); 
  if command = '' Then WriteLn ('Use LOG to return Monster.');
                                         
  succeed := odd (SPawn ( command, '' , '' , 1 ,
                            name , Id , 0, dcl_efn,,,'Dcl> '));
  If not succeed Then WriteLn ('Oops ! Can''t start child process ..');
  
  end_dcl := not succeed;
  while not end_dcl do  { odotetaan loppumista }
    begin
      
      syscall($wflor(base_efn,mask));   { odotetaan että timerin tai aliprosessin
				      EF laukeaa }

      if (check_timer) then checkevents (true); 
			{ check_timer myöskin laittaa timeri uudestaan }
			{ käyntiin. alunperin se on käynistetty }
			{ setup_guts:issa }

      syscall ($readef (base_efn,code));
      end_dcl := uand(code,2 ** (dcl_efn-base_efn)) > 0; { onko lapsi kuollut }
    end;

 WriteLn ('Control return to Monster');

End; { do_dcl }

 
end.
