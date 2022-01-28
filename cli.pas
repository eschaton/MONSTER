[environment,inherit ('Global','Guts','Database')]
module cli (input, output);

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
	done		: [external] boolean;
	userid		: [external] veryshortstring;
	myname		: [external] shortstring;
	wizard		: [external] boolean;

	output_file	: [global] string := 'SYS$OUTPUT';

function cli$get_value (%descr entity_desc: string; 
			%descr retdesc: string;
			%ref retlength: word_unsigned): cond_value;
	external;

function cli$present (%descr entity_desc: string): cond_value;
	external;

function lowcase (s: string): string;
	external;

[global] procedure monster_version;
begin
	{ Don't take this out please... }
	writeln('Monster, a multiplayer adventure game where the players create the world');
	writeln('and make the rules.');
	writeln;
	writeln('VERSION:     ',VERSION);
	writeln('DISTRIBUTED: ',DISTRIBUTED);
	writeln;
	writeln('Originally written by Rich Skrenta at Northwestern University, 1988.');
        writeln;
	writeln('         modified by Juha Laiho   at University of Helsinki,  1988--89,');
	writeln('                     Antti Leino  at University of Helsinki,  1989,');
        writeln('                     Kari Hurtta  at University of Helsinki,  1989--92.');
        writeln;
	writeln('Monster''s programming language by Kari Hurtta.');
end;




[global] procedure very_prestart; { before procedure init }
var
	qualifier,
	value,
	s,file_name	: string;
	value_length	: word_unsigned;
	status1,
	status2		: cond_value;

	do_fix, do_batch : boolean;
begin

	qualifier := 'OUTPUT';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
	    status2 := cli$get_value (qualifier, value, value_length);
	    if status2 = ss$_normal then output_file := value
	    else begin
		writeln ('Something is wrong with /OUTPUT.');
		done := true;
	    end;
	end else if status1 = cli$_negated then output_file := 'NLA0:';

	{ for /OUTPUT and big terminal lines }
	if output_file > '' then begin
	    close(output);
	    open(output,output_file,new,terminal_line_len+80,DEFAULT := '.LOG');
	    rewrite(output);
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
    
end;

   
[global] procedure prestart;
var
	qualifier,
	value,
	s		: string;
	value_length	: word_unsigned;
	status1,
	status2		: cond_value;

begin

	qualifier := 'VERSION';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then monster_version;

	qualifier := 'REAL_USERID';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
		status2 := cli$get_value (qualifier, value, value_length);
		if status2 = ss$_normal then begin
			if (userid <> lowcase(value)) then begin
		 		if (userid = MM_userid) then begin
					userid := lowcase(value);   { hurtta@finuh }
					wizard := false;
	 			end else begin
					writeln ('You may not pose as another player.');
 					done := true;
				end;
			end else begin
				writeln('Do you find it interesting to pose as yourself?');
			end;
		end else begin
			writeln ('Something is wrong with /REAL_USERID.');
			done := true;
		end;
	end;

	qualifier := 'USERID';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then begin
		status2 := cli$get_value (qualifier, value, value_length);
		if status2 = ss$_normal then begin
			s := lowcase(value);	     { hurtta@finuh }
			if s.length > veryshortlen-4 then begin
				s := substr (s, 1, veryshortlen-4);
				writeln ('Userid truncated to ', s, ', sorry.');
			end;
			userid := '"' + s + '"';
			myname := s;
			if (myname[1] >= 'a') and (myname[1] <= 'z') then begin
			    myname[1] := 
				chr (ord ('A') + 
				ord (myname[1]) - ord ('a'));
			end;
		end else begin
			writeln ('Something is wrong with /USERID.');
			done := true;
		end;
	end;

	qualifier := 'START';
	status1 := cli$present (qualifier);
	if status1 = cli$_present then done := false
	else if status1 = cli$_negated then done := true;

end;


end.
