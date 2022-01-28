$! Install Monster 
$ SET NOON
$ SET ON
$ ON WARNING THEN CALL FATAL "ERROR !!"
$ df = F$ENVIRONMENT("DEFAULT")
$
$! Questions
$ CALL PATHNAME bn 'F$ENVIRONMENT("PROCEDURE")
$ source_directory == ""
$ CALL QUERY_DIR source_directory "Give source (distribution) directory" 'bn
$ work_directory == ""
$ CALL ASK_DIR work_directory "Give work directory for compilation" 'df
$ option == 0
$ CALL ASK_OPTION
$ database_directory == ""
$ image_directory == ""
$ IF option .eq. 4 
$    THEN
$    CALL QUERY_DIR image_directory "Give directory for (current) installed MON.EXE"
$    CALL CHECK_FILE 'image_directory'MONSTER.INIT
$    CALL QUERY_DIR database_directory "Give existed database directory" ""
$    CALL CHECK_FILE 'database_directory'DB.DIR
$    CALL CHECK_FILE 'database_directory'C.DIR
$    ELSE
$    CALL ASK_DIR image_directory "Give directory for installed MON.EXE"
$    CALL ASK_DIR database_directory "Give directory for Monster database"
$ ENDIF
$ old_database == ""
$ IF option .eq. 2 
$    THEN
$    CALL QUERY_DIR old_database "Give old monster database" 'database_directory
$    CALL CHECK_FILE 'old_database'DESC.MON
$    CALL CHECK_FILE 'old_database'EVENTS.MON
$    CALL CHECK_FILE 'old_database'INDEX.MON
$    CALL CHECK_FILE 'old_database'INTFILE.MON
$    CALL CHECK_FILE 'old_database'LINE.MON
$    CALL CHECK_FILE 'old_database'NAMS.MON
$    CALL CHECK_FILE 'old_database'OBJECTS.MON
$    CALL CHECK_FILE 'old_database'ROOMS.MON
$ ENDIF
$ IF option .eq. 3 THEN CHECK_FILE 'source_directory'CASTLE.DMP
$
$
$! Actions
$ SET DEFAULT 'work_directory'
$ CALL CHECK_FILE 'source_directory'MONSTER.HELP
$ CALL CHECK_FILE 'source_directory'COMMANDS.PAPER
$ IF option .ne. 4 THEN CALL CHECK_FILE 'source_directory'ILMOITUS.TXT
$ CALL CHECK_FILE 'source_directory'CLD.PROTO
$ IF option .ne. 4 THEN CALL CHECK_FILE 'source_directory'INIT.PROTO
$ CALL CHECK_FILE 'source_directory'CONVERT.BATCH
$ CALL CHECK_FILE 'source_directory'FIX.BATCH
$
$ CALL MAKE_HELP | Produce MONSTER_E.HLB
$ CALL MAKE_DUMP ! Produce MONSTER_DUMP.EXE
$ CALL MAKE_REBUILD ! Produce MONSTER_REBUILD.EXE
$ CALL MAKE_WHO  ! Produce MONSTER_WHO.EXE
$ CALL MAKE_MON  ! Produce MON.EXE
$
$ CALL CHECK_FILE MON.EXE
$ CALL CHECK_FILE MONSTER_DUMP.EXE
$ CALL CHECK_FILE MONSTER_REBUILD.EXE
$ CALL CHECK_FILE MONSTER_WHO.EXE
$
$ CALL CREATE_SUBDIR 'database_directory' DB DBDIR
$ CALL CREATE_SUBDIR 'database_directory' C  CODEDIR
$ COPY/LOG MON.EXE,MONSTER_DUMP.EXE,MONSTER_WHO.EXE,MONSTER_E.HLB,MONSTER_REBUILD.EXE 'image_directory
$ IF .not. $SEVERITY THEN CALL FATAL "Copy failed"
$ COPY/LOG 'source_directory'CONVERT.BATCH,FIX.BATCH 'image_directory
$ IF .not. $SEVERITY THEN CALL FATAL "Copy failed"
$ SET FILE/PROTECTION=(W:E)/LOG 'image_directory'MON.EXE,MONSTER_DUMP.EXE,MONSTER_WHO.EXE
$ IF .not. $SEVERITY THEN CALL FATAL "Set file/protection failed"
$ COPY/LOG 'source_directory'CONVERT.BATCH,FIX.BATCH 'image_directory
$ IF .not. $SEVERITY THEN CALL FATAL "Copy failed"
$ COPY/LOG 'source_directory'MONSTER.HELP 'DBDIR'
$ IF .not. $SEVERITY THEN CALL FATAL "Copy failed"
$ IF option .ne. 4 
$   THEN
$   COPY/LOG 'source_directory'ILMOITUS.TXT 'DBDIR'
$   IF .not. $SEVERITY THEN CALL FATAL "Copy failed"
$ ENDIF
$ SET FILE/PROTECTION=(W:R)/LOG 'DBDIR'MONSTER.HELP,ILMOITUS.TXT
$ IF .not. $SEVERITY THEN CALL FATAL "Set file/protection failed"
$ COPY/LOG 'source_directory'COMMANDS.PAPER 'DBDIR'
$ IF .not. $SEVERITY THEN CALL FATAL "Copy failed"
$ SET FILE/PROTECTION=(W:R)/LOG 'DBDIR'COMMANDS.PAPER
$ IF .not. $SEVERITY THEN CALL FATAL "Set file/protection failed"
$ SB_IMAGE_DIR = image_directory
$ CALL MAKE_FILE 'source_directory'CLD.PROTO 'image_directory'MONSTER.CLD
$ SB_MANAGER = F$EDIT(F$GETJPI("","USERNAME"),"LOWERCASE")
$ SB_DB1 = DBDIR
$ SB_DB2 = CODEDIR
$ IF option .ne. 4 THEN CALL MAKE_FILE 'source_directory'INIT.PROTO 'image_directory'MONSTER.INIT
$
$ CALL DEFINE_MONSTER
$
$ IF option .eq. 1 THEN CALL BUILD_DATABASE
$ IF option .eq. 2 THEN CALL CONVERT_DATABASE
$ IF option .eq. 3 THEN CALL BUILD_CASTLE
$
$ WRITE SYS$OUTPUT ""
$ WRITE SYS$OUTPUT "Add to your LOGIN.COM command:"
$ WRITE SYS$OUTPUT "$ SET COMMAND ''image_directory'MONSTER.CLD"
$ WRITE SYS$OUTPUT ""
$ SET DEFAULT 'df'
$ EXIT
$!
$ CHECK_FILE: SUBROUTINE
$ file = F$PARSE(P1)
$ IF file .eqs. "" THEN CALL FATAL "File ''P1' not found - bad path?"
$ if F$SEARCH(file) .eqs. "" THEN CALL FATAL "File ''file' not found."
$ EXIT
$ ENDSUBROUTINE 
$!
$ FATAL: SUBROUTINE
$ WRITE SYS$ERROR "Install failed: ", p1
$ SET NOON
$ IF F$TYPE(df) .eqs. "STRING" THEN SET DEFAULT 'df'
$ IF F$TRNLMN("FROM") .nes. "" THEN CLOSE FROM
$ IF F$TRNLMN("TO") .nes. "" THEN CLOSE TO
$ SET ON
$ STOP
$ ENDSUBROUTINE
$!
$ ASK_DIR: SUBROUTINE
$again1:
$ write SYS$OUTPUT P2
$ IF P3 .nes. "" THEN WRITE SYS$OUTPUT "Default: ",P3
$ INQUIRE dir "Directory"
$ IF dir .eqs. "" .and. P3 .nes. "" THEN dir = P3
$ full = F$PARSE(dir,,,,"SYNTAX_ONLY") - ".;"
$ IF full .eqs. "" 
$   THEN
$   WRITE SYS$ERROR "Bad directory specification: ''dir'"
$   GOTO again1
$ ENDIF
$ WRITE SYS$OUTPUT "''full' - OK?"
$ INQUIRE OK "Ok (Y/N)"
$ IF OK .nes. "Y" THEN GOTO again1
$ IF F$PARSE(full) .eqs. ""
$   THEN
$   WRITE SYS$ERROR "Directory ''full' not exist - create it?"
$   INQUIRE OK "Create (Y/N)"
$   IF OK .nes. "Y" THEN GOTO again1
$   CREATE/DIRECTORY/LOG/PROTECTION=(S:RWE,O:RWE,G:E,W:E) 'full
$   IF .not. $SEVERITY 
$     THEN
$       WRITE SYS$ERROR "Creating of ''full' failed"
$       GOTO again1
$   ENDIF
$ ENDIF
$ CALL DIRNAME 'full' dirname
$ SET FILE/ACL=(IDENTIFIER='F$USER(),access=r+w+e+d+c)/LOG 'dirname
$ IF .not. $SEVERITY THEN CALL FATAL "Set file/acl failed"
$ SET FILE/ACL=(IDENTIFIER='F$USER(),OPTIONS=DEFAULT,access=r+w+e+d+c)/LOG 'dirname
$ IF .not. $SEVERITY THEN CALL FATAL "Set file/acl failed"
$ SET FILE/ACL=(DEFAULT_PROTECTION,SYSTEM:RWED,OWNER:RWED,GROUP,WORLD:R)/LOG 'dirname
$ IF .not. $SEVERITY THEN CALL FATAL "Set file/acl failed"
$ 'p1 == full
$ EXIT
$ ENDSUBROUTINE
$!
$ CREATE_SUBDIR: SUBROUTINE
$ base = p1 - ">" - "]"        ! This can fail
$ tail = p1 - base
$ dir = base + "." + p2 + tail
$ IF F$PARSE(dir,,,,"SYNTAX_ONLY") .eqs. "" THEN CALL FATAL "Internal error - bad path: ''dir'"
$ if F$PARSE(dir) .eqs. "" THEN CREATE/DIRECTORY/LOG/PROTECTION=(S:RWE,O:RWE,G:E,W:E) 'dir
$ CALL DIRNAME 'dir' dirname
$ SET FILE/ACL=(IDENTIFIER='F$USER(),access=r+w+e+d+c)/LOG 'dirname
$ IF .not. $SEVERITY THEN CALL FATAL "Set file/acl failed"
$ SET FILE/ACL=(IDENTIFIER='F$USER(),OPTIONS=DEFAULT,access=r+w+e+d+c)/LOG 'dirname
$ IF .not. $SEVERITY THEN CALL FATAL "Set file/acl failed"
$ SET FILE/ACL=(DEFAULT_PROTECTION,SYSTEM:RWED,OWNER:RWED,GROUP,WORLD:RW)/LOG 'dirname
$ IF .not. $SEVERITY THEN CALL FATAL "Set file/acl failed"
$ 'p3 == dir
$ EXIT
$ ENDSUBROUTINE
$!
$ DIRNAME: SUBROUTINE
$ disk = F$PARSE(p1,,,"DEVICE","SYNTAX_ONLY")
$ path = F$PARSE(p1,,,"DIRECTORY","SYNTAX_ONLY")
$ IF disk .eqs. "" .or. path .eqs. "" THEN CALL FATAL "Internal error - bad path ''p1'"
$ last = ""
$ build = ""
$ i = 0
$again2:
$ e = F$ELEMENT(i,".",path)
$ IF e .nes. "." 
$   THEN
$   IF build .nes. "" THEN build = build + "."
$   build = build + last
$   last = e
$   i = i + 1
$   GOTO again2
$ ENDIF
$ name = last - ">" - "]" - "<" - "["      ! if not . in name
$ tail = last - name 
$ IF build .nes. "" 
$ THEN
$    dirname = disk + build + tail + name + ".DIR"
$ ELSE
$    dirname = disk + "<000000>" + name + ".DIR"
$ ENDIF
$ IF F$PARSE(dirname) .eqs. "" THEN CALL FATAL "Internal error - bad pathname ''dirname'"
$ IF F$SEARCH(dirname) .eqs. "" THEN CALL FATAL "Internal error - not found ''dirname'"
$ 'p2 == dirname
$ EXIT
$ ENDSUBROUTINE
$!
$ MAKE_FILE: SUBROUTINE
$ OPEN/ERROR=error1 from 'p1
$ WRITE SYS$OUTPUT "Creating file: ''p2'"
$ OPEN/WRITE/ERROR=error2 to 'p2
$again4:
$ READ/END_OF_FILE=out from line
$ pos = F$LOCATE("%",line)
$ IF pos .eq. F$LENGTH(line) THEN GOTO done
$ start = F$EXTRACT(0,pos,line)
$ rest = F$EXTRACT(pos+1,F$LENGTH(line)-pos,line)
$ itm = F$LOCATE("%",rest)
$ IF itm .eq. F$LENGTH(line) THEN GOTO done
$ symbol = F$EXTRACT(0,itm,rest)
$ tail = F$EXTRACT(itm+1,F$LENGTH(rest)-itm,rest)
$ x = "SB_" + symbol
$ line = start + 'x' + tail
$done:
$ WRITE to line
$ GOTO again4
$out:
$ CLOSE to
$ CLOSE from
$ SET FILE/PROTECTION=(W:R)/LOG 'p2
$ EXIT
$error1:
$ CALL FATAL "Opening of ''p1' failed"
$ EXIT
$error2:
$ CLOSE from
$ CALL FATAL "Creating of ''p2' failed"
$ EXIT
$ ENDSUBROUTINE
$
$ QUERY_DIR: SUBROUTINE
$again5:
$ WRITE SYS$OUTPUT P2
$ WRITE SYS$OUTPUT "Default: ",P3
$ INQUIRE dir "Directory"
$ IF dir .eqs. "" THEN dir = P3
$ path = F$PARSE(dir) - ".;"
$ IF path .eqs. "" 
$   THEN
$   WRITE SYS$ERROR "Directory ",dir," not exist."
$   GOTO again5
$ ENDIF
$ 'P1 == path
$ EXIT
$ ENDSUBROUTINE
$ 
$ PATHNAME: SUBROUTINE
$ node = F$PARSE(P2,,,"NODE","SYNTAX_ONLY")
$ device = F$PARSE(P2,,,"DEVICE","SYNTAX_ONLY")
$ directory = F$PARSE(P2,,,"DIRECTORY","SYNTAX_ONLY")
$ IF node + device + directory .eqs. "" THEN CALL FATAL "Bad filename: ''P2'"
$ 'P1 == node  + device + directory
$ EXIT
$ ENDSUBROUTINE
$
$ COMPILE: SUBROUTINE
$ source = F$PARSE(".PAS",source_directory + P1)
$ result = F$PARSE(".OBJ",work_directory + P1)
$ IF source .eqs. "" THEN CALL FATAL "Internal_error: Bad filename: ''P1'"
$ IF result .eqs. "" THEN CALL FATAL "Internal error: Bad filename: ''P1'"
$ IF F$SEARCH(result) .nes. "" THEN EXIT
$ CALL CHECK_FILE 'source'
$ PASCAL/CHECK=ALL/OBJECT='result'/TERMINAL=FILE_NAME 'source'
$ IF .not. $SEVERITY THEN CALL FATAL "Compilation of ''source' failed"
$ IF F$SEARCH(result) .eqs. "" THEN CALL FATAL "Compile failed: ''result' not found"
$ EXIT
$ ENDSUBROUTINE
$
$ MAKE_MON: SUBROUTINE
$ IF F$SEARCH("MON.EXE") .nes. "" THEN EXIT
$ CALL COMPILE GLOBAL
$ CALL COMPILE VERSION
$ CALL COMPILE GUTS
$ CALL COMPILE KEYS
$ CALL COMPILE PRIVUSERS
$ CALL COMPILE DATABASE
$ CALL COMPILE PARSER
$ CALL COMPILE INTERPRETER
$ CALL COMPILE QUEUE
$ CALL COMPILE CLI
$ CALL COMPILE ALLOC
$ CALL COMPILE CUSTOM
$ CALL COMPILE MON
$ LINK MON,GLOBAL,GUTS,KEYS,PRIVUSERS,DATABASE,PARSER,INTERPRETER,QUEUE,CLI,CUSTOM,ALLOC,VERSION
$ IF .not. $SEVERITY THEN CALL FATAL "Linking of MON.EXE failed"
$ IF F$SEARCH("MON.EXE") .eqs. "" THEN CALL FATAL "Link failed: MON.EXE not found"
$ EXIT
$ ENDSUBROUTINE
$
$ MAKE_WHO: SUBROUTINE
$ IF F$SEARCH("MONSTER_WHO.EXE") .nes. "" THEN EXIT
$ CALL COMPILE GLOBAL
$ CALL COMPILE GUTS 
$ CALL COMPILE PRIVUSERS
$ CALL COMPILE DATABASE
$ CALL COMPILE PARSER
$ CALL COMPILE MONSTER_WHO
$ LINK MONSTER_WHO,GLOBAL,GUTS,PRIVUSERS,DATABASE,PARSER
$ IF .not. $SEVERITY THEN CALL FATAL "Linking of MONSTER_WHO.EXE failed"
$ IF F$SEARCH("MONSTER_WHO.EXE") .eqs. "" THEN CALL FATAL "Link failed: MONSTER_WHO.EXE not found"
$ EXIT
$ ENDSUBROUTINE
$
$ MAKE_DUMP: SUBROUTINE
$ IF F$SEARCH("MONSTER_DUMP.EXE") .nes. "" THEN EXIT
$ CALL COMPILE GLOBAL
$ CALL COMPILE VERSION
$ CALL COMPILE GUTS 
$ CALL COMPILE PRIVUSERS
$ CALL COMPILE DATABASE
$ CALL COMPILE PARSER
$ CALL COMPILE MONSTER_DUMP
$ LINK MONSTER_DUMP,GLOBAL,GUTS,PRIVUSERS,DATABASE,PARSER,VERSION
$ IF .not. $SEVERITY THEN CALL FATAL "Linking of MONSTER_DUMP.EXE failed"
$ IF F$SEARCH("MONSTER_DUMP.EXE") .eqs. "" THEN CALL FATAL "Link failed: MONSTER_DUMP.EXE not found"
$ EXIT
$ ENDSUBROUTINE
$ 
$ MAKE_REBUILD: SUBROUTINE
$ IF F$SEARCH("MONSTER_REBUILD.EXE") .nes. "" THEN EXIT
$ CALL COMPILE GLOBAL
$ CALL COMPILE VERSION
$ CALL COMPILE GUTS 
$ CALL COMPILE PRIVUSERS
$ CALL COMPILE DATABASE
$ CALL COMPILE PARSER
$ CALL COMPILE ALLOC
$ CALL COMPILE KEYS
$ CALL COMPILE MONSTER_REBUILD
$ LINK MONSTER_REBUILD,GLOBAL,GUTS,PRIVUSERS,DATABASE,PARSER,VERSION,ALLOC,KEYS
$ IF .not. $SEVERITY THEN CALL FATAL "Linking of MONSTER_REBUILD.EXE failed"
$ IF F$SEARCH("MONSTER_REBUILD.EXE") .eqs. "" THEN CALL FATAL "Link failed: MONSTER_REBUILD.EXE not found"
$ EXIT
$ ENDSUBROUTINE
$
$ MAKE_HELP: SUBROUTINE
$ IF F$SEARCH("MONSTER_E.HLB") .nes. "" THEN EXIT
$ CALL CHECK_FILE 'source_directory'MONSTER_E.HLP
$ LIBRARY/HELP/LOG/CREATE MONSTER_E.HLB 'source_directory'MONSTER_E.HLP
$ IF .not. $SEVERITY THEN CALL FATAL "Creating of MONSTER_E.HLB failed"
$ IF F$SEARCH("MONSTER_E.HLB") .eqs. "" THEN CALL FATAL "Creating failed: MONSTER_E.HLB not found"
$ EXIT
$ ENDSUBROUTINE
$
$ DEFINE_MONSTER: SUBROUTINE
$ IF F$TYPE(monster) .nes. ""
$    THEN
$    WRITE SYS$OUTPUT "Deleting symbol MONSTER"
$    DELETE/SYMBOL/GLOBAL monster
$ ENDIF
$ SET COMMAND 'image_directory'MONSTER.CLD
$ IF .not. $SEVERITY THEN CALL FATAL "Defining of command MONSTER failed"
$ WRITE SYS$OUTPUT "Command MONSTER defined"
$ WRITE SYS$OUTPUT "(To define this in future add to your LOGIN.COM command:"
$ WRITE SYS$OUTPUT " $ SET COMMAND ''image_directory'MONSTER.CLD"
$ WRITE SYS$OUTPUT ")"
$ EXIT
$ ENDSUBROUTINE
$
$ BUILD_DATABASE: SUBROUTINE
$ WRITE SYS$OUTPUT "Building monster database"
$ MONSTER/REBUILD/NOSTART
yes
$ EXIT
$ ENDSUBROUTINE
$
$ ASK_OPTION: SUBROUTINE
$again7:
$ WRITE SYS$OUTPUT "You can: "
$ WRITE SYS$OUTPUT "  1 =  Build new empty monster database"
$ WRITE SYS$OUTPUT "  2 =  Convert old (Skrenta's Monster V1) database"
$ WRITE SYS$OUTPUT "  3 =  Build new empire database with the starter's CASTLE"
$ WRITE SYS$OUTPUT "  4 =  Only install NEW Monster image (database exist)"
$ INQUIRE i "Select 1, 2, 3 or 4"
$ option == f$integer(i)
$ IF option .lt. 1 .or. option .gt. 4 THEN GOTO again7
$ EXIT
$ ENDSUBROUTINE
$
$ CONVERT_DATABASE: SUBROUTINE
$ COPY/LOG 'old_database'DESC.MON,EVENTS.MON,INDEX.MON,INTFILE.MON,LINE.MON,NAMS.MON,OBJECTS.MON,ROOMS.MON 'dbdir'
$ MONSTER/NOSTART/BATCH='source_directory'CONVERT.BATCH
$ EXIT
$ ENDSUBROUTINE
$
$ BUILD_CASTLE: SUBROUTINE
$ MONSTER/BUILD 'source_directory'CASTLE.DMP
yes
$ EXIT
$ ENDSUBROUTINE
