[inherit ('global') ]
module keys(input,output);

{
    This file contains the keys used in encrypting the player
    passwords. The file should be kept well protected.
}

const maxkeys = 10;
type 
     keyarray = array[1..maxkeys] of shortstring;

var     mylog : [external] integer;

	keys: keyarray := (

'Kaupungin keskustaan',
'meneva juna saapuu e',
'dellään aalto kostea',
'ilmaa ja ontto humin',
'a. Se on tuskin puol',
'illaan, koska kello ',
'on yli kuusi illalla',
'ka liikenne on vilkk', 
'aampi lähiöiden suun',
'taan. Moni vaunussa '

);

[global]
procedure encrypt (var s: shortstring; code: integer := -1);
var i, l : integer;
begin
	if code = -1 then code := mylog;

	l := (code mod maxkeys) + 1;
	for i := 1 to s.length do
		s[i] := chr ((ord (s[i]) + ord (keys[l][i])) mod 256);
end;

end. { end of module keys }
