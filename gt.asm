%macro   covar 0.nolist
[section .data]
         times 100 dd 0
mvpad:   db './',__FILE__
mvnapad: db 0
%endmacro

%macro   openin   0.nolist         
extern openisr
         push dword mvpad
         push dword mvnapad
         call openisr
%endmacro

%macro   openuit  0.nolist
extern openusr
         push dword mvpad
         push dword mvnapad
         call openusr
%endmacro

%macro   schrijf  0.nolist         
extern schrsr
         push dword outarea
         push dword 71
         call schrsr
%endmacro

%macro   uit 1.nolist
extern uitsr
         push esi
         lea esi,%1
         push  esi
         call uitsr
         pop esi
%endmacro

%macro  inv 1.nolist       
;deze macro leest een getal in van het scherm; 
;het getal staat daarna in binaire vorm in %1
extern invsr
         push esi
         lea esi,%1
         push  esi
         call invsr
         pop esi
%endmacro         

%macro  lees 0.nolist
extern leessr
        push dword inarea
        call leessr
%endmacro         

%macro  inleiding 0.nolist
[section .text]
global start
global main
start: 
main:
%endmacro

%macro   slot 0.nolist
extern sluitsr
         call sluitsr
%endmacro

%macro   tekstbin 0.nolist
;De externe inhoud vanaf adres in ESI wordt omgerekend naar binair. 
;Het aantal bytes moet in ECX staan.
;Het resultaat komt in EAX.

extern tkstbsr
         call tkstbsr
%endmacro         

