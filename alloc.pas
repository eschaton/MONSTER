[ ENVIRONMENT, INHERIT('database', 'guts', 'global' , 'privusers', 'parser')]
MODULE ALLOC (OUTPUT) ;
 
{
PROGRAM DESCRIPTION: 
 
    ALLOC module for CUSTOM module (and MONSTER/REBUILD and /FIX)
 
AUTHORS: 
 
    Kari Hurtta
 
CREATION DATE:	25.6.1992
 
 
	    C H A N G E   L O G
 
     Date     |   Name  | Description
--------------+---------+-------------------------------------------------------
   25.60.1992 | Hurtta  | Allocation routines moved to module ALLOC from 
              |         | module CUSTOM, nc_createroom
}

VAR

	userid: [global] veryshortstring;	{ userid of this player }
 
{ allocation routines ------------------------------------------------------ }

{
First procedure of form alloc_X
Allocates the oneliner resource using the indexrec bitmaps

Return the number of a one liner if one is available
and remove it from the free list
}
[global] FUNCTION alloc_line(var n: integer):boolean;
var
	found: boolean;

begin
	getindex(I_LINE);
	if indx.inuse = indx.top then begin
		freeindex;
		n := 0;
		alloc_line := false;
		writeln('There are no available one line descriptions.');
	end else begin
		n := 1;
		found := false;
		while (not found) and (n <= indx.top) do begin
			if indx.free[n] then
				found := true
			else
				n := n + 1;
		end;
		if found then begin
			indx.free[n] := false;
			alloc_line := true;
			indx.inuse := indx.inuse + 1;
			putindex;
		end else begin
			freeindex;
			writeln('%serious error in alloc_line; notify Monster Manager');
			
			alloc_line := false;
		end;
	end;
end;

{
put the line specified by n back on the free list
zeroes n also, for convenience
}
[global] PROCEDURE delete_line(var n: integer);

begin
	if n = DEFAULT_LINE then
		n := 0
	else if n > 0 then begin
		getindex(I_LINE);
		indx.inuse := indx.inuse - 1;
		indx.free[n] := true;
		putindex;
	end;
	n := 0;
end;



[global] FUNCTION alloc_int(var n: integer):boolean;
var
	found: boolean;

begin
	getindex(I_INT);
	if indx.inuse = indx.top then begin
		freeindex;
		n := 0;
		alloc_int := false;
		writeln('There are no available integer records.');
	end else begin
		n := 1;
		found := false;
		while (not found) and (n <= indx.top) do begin
			if indx.free[n] then
				found := true
			else
				n := n + 1;
		end;
		if found then begin
			indx.free[n] := false;
			alloc_int := true;
			indx.inuse := indx.inuse + 1;
			putindex;
		end else begin
			freeindex;
			writeln('%serious error in alloc_int; notify Monster Manager');
			
			alloc_int := false;
		end;
	end;
end;


[global] PROCEDURE delete_int(var n: integer);

begin
	if n > 0 then begin
		getindex(I_INT);
		indx.inuse := indx.inuse - 1;
		indx.free[n] := true;
		putindex;
	end;
	n := 0;
end;



{
Return the number of a description block if available and
remove it from the free list
}
[global] FUNCTION alloc_block(var n: integer):boolean;
var
	found: boolean;

begin
	if debug then
		writeln('%alloc_block entry');
	getindex(I_BLOCK);
	if indx.inuse = indx.top then begin
		freeindex;
		n := 0;
		alloc_block := false;
		writeln('There are no available description blocks.');
	end else begin
		n := 1;
		found := false;
		while (not found) and (n <= indx.top) do begin
			if indx.free[n] then
				found := true
			else
				n := n + 1;
		end;
		if found then begin
			indx.free[n] := false;
			alloc_block := true;
			indx.inuse := indx.inuse + 1;
			putindex;
			if debug then
				writeln('%alloc_block successful');
		end else begin
			freeindex;
			writeln('%serious error in alloc_block; notify Monster Manager');
			alloc_block := false;
		end;
	end;
end;




{
puts a description block back on the free list
zeroes n for convenience
}
[global] PROCEDURE delete_block(var n: integer);

begin
	if n = DEFAULT_LINE then
		n := 0		{ no line really exists in the file }
	else if n > 0 then begin
		getindex(I_BLOCK);
		indx.inuse := indx.inuse - 1;
		indx.free[n] := true;
		putindex;
		n := 0;
	end else if n < 0 then begin
		n := (- n);
		delete_line(n);
	end;
end;



{
Return the number of a room if one is available
and remove it from the free list
}
[global] FUNCTION alloc_room(var n: integer):boolean;
var
	found: boolean;

begin
	getindex(I_ROOM);
	if indx.inuse = indx.top then begin
		freeindex;
		n := 0;
		alloc_room := false;
		writeln('There are no available free rooms.');
	end else begin
		n := 1;
		found := false;
		while (not found) and (n <= indx.top) do begin
			if indx.free[n] then
				found := true
			else
				n := n + 1;
		end;
		if found then begin
			indx.free[n] := false;
			alloc_room := true;
			indx.inuse := indx.inuse + 1;
			putindex;
		end else begin
			freeindex;
			writeln('%serious error in alloc_room; notify Monster Manager');
			alloc_room := false;
		end;
	end;
end;

{
Called by DEL_ROOM()
put the room specified by n back on the free list
zeroes n also, for convenience
}
[global] PROCEDURE delete_room(var n: integer);

begin
	if n <> 0 then begin
		getindex(I_ROOM);
		indx.inuse := indx.inuse - 1;
		indx.free[n] := true;
		putindex;
		n := 0;
	end;
end;



[global] FUNCTION alloc_log(var n: integer):boolean;
var
	found: boolean;

begin
	getindex(I_PLAYER);
	if indx.inuse = indx.top then begin
		freeindex;
		n := 0;
		alloc_log := false;
		writeln('There are too many monster players, you can''t find a space.');
	end else begin
		n := 1;
		found := false;
		while (not found) and (n <= indx.top) do begin
			if indx.free[n] then
				found := true
			else
				n := n + 1;
		end;
		if found then begin
			indx.free[n] := false;
			alloc_log := true;
			indx.inuse := indx.inuse + 1;
			putindex;
		end else begin
			freeindex;
			writeln('%serious error in alloc_log; notify Monster Manager');
			alloc_log := false;
		end;
	end;
end;

[global] PROCEDURE delete_log(var n: integer);

begin
	if n <> 0 then begin
		getindex(I_PLAYER);
		indx.inuse := indx.inuse - 1;
		indx.free[n] := true;
		putindex;
		n := 0;
	end;
end;


[global] FUNCTION alloc_obj(var n: integer):boolean;
var
	found: boolean;

begin
	getindex(I_OBJECT);
	if indx.inuse = indx.top then begin
		freeindex;
		n := 0;
		alloc_obj := false;
		writeln('All of the possible objects have been made.');
	end else begin
		n := 1;
		found := false;
		while (not found) and (n <= indx.top) do begin
			if indx.free[n] then
				found := true
			else
				n := n + 1;
		end;
		if found then begin
			indx.free[n] := false;
			alloc_obj := true;
			indx.inuse := indx.inuse + 1;
			putindex;
		end else begin
			freeindex;
			writeln('%serious error in alloc_obj; notify Monster Manager');
			alloc_obj := false;
		end;
	end;
end;


[global] PROCEDURE delete_obj(var n: integer);

begin
	if n <> 0 then begin
		getindex(I_OBJECT);
		indx.inuse := indx.inuse - 1;
		indx.free[n] := true;
		putindex;
		n := 0;
	end;
end;


[GLOBAL] function alloc_detail(var n: integer;s: string): boolean;
var
	found: boolean;

begin
	n := 1;
	found := false;
	while (n <= maxdetail) and (not found) do begin
		if here.detaildesc[n] = 0 then
			found := true
		else
			n := n + 1;
	end;
	alloc_detail := found;
	if not(found) then
		n := 0
	else begin
		getroom;
		here.detail[n] := lowcase(s);
		putroom;
	end;
end;

{---------------------------------------------------------------------------- }

[global]
function nc_createroom(s: string):boolean; { create a room with name s }
var
	roomno: integer;
	dummy: integer;
	i:integer;
	rand_accept: integer;

begin
	if alloc_room(roomno) then begin

		getnam;
		nam.idents[roomno] := lowcase(s);	{ assign room name }
		putnam;					{ case insensitivity }

		getown;
		own.idents[roomno] := userid;	{ assign room owner }
		putown;

		getroom(roomno);

		here.primary := 0;
		here.secondary := 0;
		here.which := 0;	{ print primary desc only by default }
		here.magicobj := 0;

		here.owner := userid;	{ owner and name are stored here too }
		here.nicename := s;
		here.nameprint := 1;	{ You're in ... }
		here.objdrop := 0;	{ objects dropped stay here }
		here.objdesc := 0;	{ nothing printed when they drop }
		here.magicobj := 0;	{ no magic object default }
		here.trapto := 0;	{ no trapdoor }
		here.trapchance := 0;	{ no chance }
		here.rndmsg := DEFAULT_LINE;	{ bland noises message }
		here.pile := 0;
		here.grploc1 := 0;
		here.grploc2 := 0;
		here.grpnam1 := '';
		here.grpnam2 := '';

		here.effects := 0;
		here.parm := 0;

		here.xmsg2 := 0;
		here.hook := 0;

		here.exp3 := 0;
		here.exp4 := 0;
		here.exitfail := DEFAULT_LINE;
		here.ofail := DEFAULT_LINE;

		for i := 1 to maxpeople do
			here.people[i].kind := 0;

		for i := 1 to maxpeople do
			here.people[i].name := '';

		for i := 1 to maxobjs do
			here.objs[i] := 0;

		for i := 1 to maxdetail do
			here.detail[i] := '';
		for i := 1 to maxdetail do
			here.detaildesc[i] := 0;

		for i := 1 to maxobjs do
			here.objhide[i] := 0;

		for i := 1 to maxexit do
			with here.exits[i] do begin
				toloc := 0;
				kind := 0;
				slot := 0;
				exitdesc := DEFAULT_LINE;
				fail := DEFAULT_LINE;
				success := 0;	{ no success desc by default }
				goin := DEFAULT_LINE;
				comeout := DEFAULT_LINE;
				closed := DEFAULT_LINE;

				objreq := 0;
				hidden := 0;
				alias := '';

				reqverb := false;
				reqalias := false;
				autolook := true;
			end;
		
{		here.exits := zero;	}

				{ random accept for this room }
		rand_accept := 1 + (rnd100 mod maxexit);
		here.exits[rand_accept].kind := 5;

		putroom;

		change_owner(0,mylog);
		nc_createroom := true;      { succeed }
	end else nc_createroom := false;    { failed }
end; { createroom }

END.
