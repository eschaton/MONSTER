[inherit ('Global'),environment]
Module Queue;			{ Written by Kari Hurtta, 1989 }

Const
	maxqueue = 100;

Type 
	item = record
               Monster: shortstring;
               code:    integer;
               label_name:   shortstring;
               deltatime: integer;
        end;

Var used : 0 .. maxqueue := 0;
    myname: [external] shortstring;
    debug:  [external] boolean;
    queue : array [ 1 .. maxqueue ] of item;


[external]
function lowcase(s: string): string; external;

[external]
function run_monster (monster_name: shortstring; code: integer;
                      label_name: shortstring; variable: shortstring;
                      value: mega_string;
                      time: shortstring;
		      spell: shortstring := '';
		      summoner: shortstring := ''): boolean; external; 
                                                    { hurtta@finuh }

[external]
function sysdate: string; external;

[external]
function systime: string; external;

[external]
function current_run: integer; external;

[external]
procedure log_event(	send: integer := 0;	{ slot of sender }
			act:integer;		{ what event occurred }
			targ: integer := 0;	{ target of event }
			p: integer := 0;	{ expansion parameter }
			s: string := '';	{ string for messages }
			room: integer := 0	{ room to log event in }
		   );	external;

[external]
function player_room(player: shortstring): integer; external;

[external]
function protected(n: integer := 0): boolean; external;

[global]
procedure reset_queue;
begin
    used := 0;
end;

[global]
procedure add_queue (monster: shortstring; code: integer;
	label_name: shortstring; deltatime: integer);
var place,i : integer;
begin
   if used < maxqueue then begin
      place := used+1;
      for i := used downto 1 do 
         if queue[i].deltatime > deltatime then place := i;
      for i := used downto place do queue[i+1] := queue[i];
      used := used +1;
      queue[place].monster    := monster;
      queue[place].code       := code;
      queue[place].label_name := label_name;
      queue[place].deltatime  := deltatime;
   end;
end;

function run_task(nr : integer): boolean;
var i: integer;
begin
   with queue[nr] do
      run_task := run_monster(monster,code,label_name,'','',sysdate+' '+systime);
   used := used -1;
   for i := nr to used do queue[i] := queue [i+1];
end;

[global]
function time_check: boolean;
var i: integer;
begin
  for i := 1 to used do with queue[i] do
     if deltatime > 0 then deltatime := deltatime -1;
  time_check := false;
  if (used > 0) and not protected then 
     if queue[1].deltatime = 0 then
        if current_run = 0 then time_check := run_task(1);
end;

[global]
function send_submit (monster: shortstring; code: integer;
	label_name: shortstring; deltatime: integer; player: shortstring):
	boolean;
var room: integer;
begin
   room := player_room(player);
   if room > 0 then 
      log_event( act := E_SUBMIT, targ := code, p := deltatime,
		s := monster + ',' + label_name + ',' + player,
		room := room);
   send_submit := room > 0;
end;

[global]
procedure get_submit(targ: integer; s: string; p: integer);
var loc: integer;
    s1,s2,s3,s4: string;
begin
  loc := index(s,',');
  s1 := substr(s,1,loc-1);
  s2 := substr(s,loc+1,length(s)-loc);
  loc := index(s2,',');
  s3 := substr(s2,1,loc-1);
  s4 := substr(s2,loc+1,length(s2)-loc);
  if lowcase(myname) = lowcase(s4) then
     add_queue(s1, targ,s3 ,p);
end; 

end. { End of module Queue }
