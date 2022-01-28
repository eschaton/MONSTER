[ INHERIT('database', 'guts', 'global' , 'privusers', 'parser')]
PROGRAM MONSTER_WHO ( INPUT, OUTPUT) ;
 
{
PROGRAM DESCRIPTION: 
 
    Image for MONSTER/WHO -command
 
AUTHORS: 
 
    Kari Hurtta
 
CREATION DATE:	30.4.1990
 
 
	    C H A N G E   L O G
 
     Date     |   Name  | Description
--------------+---------+-------------------------------------------------------
 11.6.1990    | Hurtta  |  read_global_flag
 12.8.1992    |         |  Dummy player_here removed (now defined in module 
              |         |      PARSER
--------------+---------+-------------------------------------------------------
%[change_entry]%
}
 

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

var play,exist: indexrec;
    userid: [global] veryshortstring;	{ userid of this player }

    public_id, disowned_id, system_id: shortstring;

procedure do_who ;
var
	i,j: integer;
	ok: boolean;
	metaok: boolean;
	roomown: veryshortstring;
        code: integer;
	c: char;
	s: shortstring;
	write_this: boolean;
	count: integer;
	s1: string;

var short_line : boolean;
begin

    short_line := terminal_line_len < 50;


	{ we need just about everything to print this list:
		player alloc index, userids, personal names,
		room names, room owners, and the log record	}

	getpers;
	freepers;
	getnam;
	freenam;
	getown;
	freeown;
	getint(N_LOCATION);	{ get where they are }
	freeint;
	if not short_line then write('              ');
	writeln('     Monster Status');
	writeln;
	if not short_line then write('Username        ');
	writeln('Game Name                 Where');

	if userid = MM_userid then metaok := true
	else metaok := false;

	for i := 1 to exist.top do begin
		if not(exist.free[i]) then begin

			write_this := not play.free[i];
                        if user.idents[i] = '' then begin
                           if write_this and not short_line then 
			    write('<unknown>       ')
                        end else if user.idents[i][1] <> ':' then begin
			   if write_this and not short_line then begin
				write(user.idents[i]);
				for j := length(user.idents[i]) to 15 do
				    write(' ');
			   end;
                        end else write_this := false;
                        
                        if write_this then begin
			   write(pers.idents[i]);
			   j := length(pers.idents[i]);
			   while j <= 25 do begin
			      write(' ');
			      j := j + 1;
			   end;
                                                    
			   if not(metaok) then begin
			      roomown := own.idents[anint.int[i]];

{ if a person is in a public or disowned room, or
  if they are in the domain of the WHOer, then the player should know
  where they are  }

			      if (roomown = public_id) or
				    (roomown = disowned_id) or
				    (roomown = userid) then
					ok := true
			      else
					ok := false;

			   end;

			   if ok or metaok then begin
				writeln(nam.idents[anint.int[i]]);
			   end else
				writeln('n/a');
                       end; { write_this }
		end;
	end;
end; { do who }

var count,I: integer;
 
BEGIN
    Get_Environment;

    if not lookup_class(system_id,'system') then
	writeln('%error in main program: system');
    if not lookup_class(public_id,'public') then
	writeln('%error in main program: public');
    if not lookup_class(disowned_id,'disowned') then
	writeln('%error in main program: disowned');

    Setup_Guts;
    if open_database then begin
	if read_global_flag(GF_VALID) then begin

	    getindex(I_PLAYER);
	    freeindex;
	    exist := indx;

	    getindex(I_ASLEEP);	{ Get index of people who are playing now }
	    freeindex;
	    play := indx;

	    getuser;
	    freeuser;

	    count := 0;
	    for i := 1 to exist.top do 
		if not(exist.free[i]) then 
		    if not (play.free[i]) then 
			if (user.idents[i] <> '') then
			    if user.idents[i][1] <> ':' then
				count := count +1;

	    if count > 0 then begin
		    do_who;

		    writeln;
		    writeln('Number of players: ',count:1);
	    end;
	end;
    end;
    Finish_Guts;
END.
