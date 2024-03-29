%define	stdin	        0
%define	stdout	        1

%define sys_exit        1
%define sys_read        3
%define sys_write       4
%define sys_open        5

[section .bss]
getalbuffer:
		resb	11
inbuffer:
        resb    72
ofile:
        resd    1
ifile:
        resd    1

[section .data]
i_offset:
        dd      0
outbuffer:      
        times 70 db     ' ' 
        db      0Ah

vraagzin:       
        db      'graag een getal tussen -2147483648 en 2147483647 : '
vraagzinl:      dd      51
spatieserror:
        db      'u vulde alleen spaties in', 0Ah, 0Dh
spatieserrorl:  dd      27
numeriekerror:
        db      'de invoer is niet numeriek', 0Ah, 0Dh
numeriekerrorl: dd      28
eentekenerror:
        db      'u vulde alleen een teken in', 0Ah, 0Dh
eentekenerrorl: dd      29
meertekenserror:
        db      'u vulde 2 of meer tekens in', 0Ah, 0Dh
meertekenserrorl:dd     29
tegrooterror:
        db      'de absolute waarde is te groot', 0Ah, 0Dh
tegrooterrorl:  dd      32

tien:   dd      10
mineen: dd      -1
isneg:  dd      0
hasteken:dd     0
hasnum: dd      0

[section .text]
align 4
get.kernel.attention:
        int     80h
        ret

%macro  system          1
        mov     eax, %1
        call get.kernel.attention
%endmacro

%macro  sys.exit        0
        system  sys_exit
%endmacro

%macro  sys.write       0
        system  sys_write
%endmacro

%macro  sys.read        0
        system  sys_read
%endmacro

%macro  sys.open        0
        system  sys_open
%endmacro

global tkstbsr
tkstbsr:
        push    ebx
        xor     ebx, ebx
begintkstb:
        dec     ecx
        cmp     ecx, 0
        jl      eindtkstb
        lodsb
        xor     al, 30h
        cmp     al, 9
        jg      begintkstb
        lea     ebx, [ebx*4 + ebx]
        lea     ebx, [ebx*2 + eax]
        jmp     begintkstb
eindtkstb:
        xchg    ebx, eax
        pop     ebx
        ret

global leessr
leessr:
        push    edi
        push    esi
        push    ecx
        
        mov     edi, [esp+16]
        
        push    dword 71
        push    dword inbuffer
        push    dword [ifile]
        sys.read
        add     esp, 12 
        
        mov     ecx, eax
        mov     esi, inbuffer
        rep     movsb
        
        pop     ecx
        pop     edi
        pop     esi
        
        ret

global openisr
openisr:
        push    eax
        push    ebx
        push    esi
        push    edi
        
        lea     ebx, [esp+24]
        mov     esi, [ebx]
        mov     edi, esi
        cld
        add     edi, 1
        lodsb
vindipunt:
        add     edi, 1
        lodsb
        cmp     al, '.'
        jne     vindipunt
        mov     al, 'i'
        stosb
        mov     al, 'n'
        stosb
        mov     al, 0
        stosb
        
        push    dword 420
        push    dword 0
        push    dword [ebx]
        sys.open
        mov     [ifile], eax
        
        add     esp, 12
        
        pop     edi
        pop     esi
        pop     ebx
        pop     eax
        ret

global openusr
openusr:
        push    eax
        push    ebx
        push    esi
        push    edi
        
        lea     ebx, [esp+24]
        mov     esi, [ebx]
        mov     edi, esi
        cld
        add     edi, 1
        lodsb
vindopunt:
        add     edi, 1
        lodsb
        cmp     al, '.'
        jne     vindopunt
        mov     al, 'u'
        stosb
        mov     al, 'i'
        stosb
        mov     al, 't'
        stosb
        mov     al, 0
        stosb
        
        push    dword 420
        push    dword 0200h | 0400h | 01h
        push    dword [ebx]
        sys.open
        mov     [ofile], eax
        
        add     esp, 12
        
        pop     edi
        pop     esi
        pop     ebx
        pop     eax
        ret
  
global schrsr
schrsr:
        push    edi
        push    ecx
        
        mov     edi, [esp+16]
        mov     ecx, [esp+12]
        push    dword ecx
        push    dword edi
        push    dword [ofile]
        sys.write
        add     esp, 12
        
        pop     ecx
        pop     edi
        ret
   
global sluitsr
sluitsr:
        push    dword 0
        sys.exit
        ret

global invsr
invsr:
        push    eax
        push    ebx
        push    ecx
        push    edx
        push    edi
        push    dword esi
        
vraag:  push    dword [vraagzinl]
        push    dword vraagzin
        push    dword stdout
        sys.write  
        add     esp, 12
        
        mov     al, 00h
        mov     ecx, 70
        mov     edi, inbuffer
        rep     stosb
        
        push    dword 70
        push    dword inbuffer
        push    dword stdin
        sys.read
        add     esp, 12
        
; nu zit de ingelezen waarde in inbuffer, inclusief de cr/lf
; kijken of alles proper is dan maar.

        cld
        xor     ecx, ecx        ; teller voor input
        mov     [isneg], ecx    ; ervanuitgaan dat het getal positief is
        mov     [hasteken], ecx ; en dus, dat er nog geen teken is meegegeven
        mov     esi, inbuffer
invoersan:
        lodsb
        test    al, al
        je      eoi

        cmp     al, 0Ah
        je      invoersan
        
        cmp     al, 0Dh
        je      invoersan
        
        cmp     al, ' '
        je      invoersan
        
        cmp     ecx, 0
        jg      natekencheck    ; als we reeds een numerieke input hebben, zijn tekens nietnumeriek
        cmp     al, '-'
        je      near negteken
        
        cmp     al, '+'
        je      near posteken

natekencheck:        
        xor     al, 30h
        cmp     al, 10
        jge     near nietnumeriek
        
        inc     ecx
        jmp     invoersan
        
eoi:    cmp     ecx, 0
        je      near geeninput
        
        ; als we hier geraakt zijn, is de input numeriek.
        ; dus, opnieuw erdoor loopen, en alle numerieke input omzetten
        ; in niet-ascii, machten van 10, teken aanpassen, klaar.
        ; maar, kijken of er overflow is, zoja, error
        xor     eax, eax        ; overflow-flag clearen en eax op 0 zetten
        xor     ebx, ebx        ; we houden het resultaat bij in ebx
        xor     edx, edx        ; zodat we overflow ook effectief kunnen checken
        mov     ecx, 10         ; om te vermenigvuldigen
        mov     esi, inbuffer

omzetting:
        lodsb
        test    al, al
        jz      naomzetting
        xor     al, 30h
        cmp     al, 9
        jg      omzetting       ; niet-numeriek, niet-null, dus overslaan
        xchg    eax, ebx
        imul    ecx
        cmp     eax, 0
        jl      tegroot
        cmp     edx, 0
        jne     tegroot
        add     eax, ebx
        jo      tegroot
        xchg    eax, ebx
        jmp     omzetting
naomzetting:
        mov     eax, ebx
        mov     ebx, [isneg]
        cmp     ebx, 0
        je      invnietneg
        mov     ebx, dword -1
        imul    ebx
invnietneg:
        pop     esi
        mov     [esi], eax
        
        pop     edi
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        
        ret

tegroot:
        push    dword [tegrooterrorl]
        push    dword tegrooterror
        push    dword stdout
        sys.write
        add     esp, 12
        jmp vraag
        
negteken:
        mov     ebx, [hasteken]
        cmp     ebx, 0
        jg      near meertekens
        mov     [hasteken], dword 1
        mov     [isneg], dword 1
        jmp     invoersan

posteken:
        mov     ebx, [hasteken]
        cmp     ebx, 0
        jg      meertekens
        mov     [hasteken], dword 1
        mov     [isneg], dword 0
        jmp     invoersan

geeninput:
        mov     ebx, [hasteken]
        cmp     ebx, 1
        je      enkelteken
        push    dword [spatieserrorl]
        push    dword spatieserror
        push    dword stdout
        sys.write
        add     esp, 12
        jmp     vraag

nietnumeriek:
        push    dword [numeriekerrorl]
        push    dword numeriekerror
        push    dword stdout
        sys.write
        add     esp, 12
        jmp     vraag

meertekens:
        push    dword [meertekenserrorl]
        push    dword meertekenserror
        push    dword stdout
        sys.write
        add     esp, 12
        jmp     vraag

enkelteken:
        push    dword [eentekenerrorl]
        push    dword eentekenerror
        push    dword stdout
        sys.write
        add     esp, 12
        jmp     vraag

global uitsr
uitsr:
		push	eax
		push	ebx
		push	ecx
		push	edx
		push	edi
		pushfd

; eerst de outputbuffer legen, en de getalbuffer, ook
		xor		eax, eax
		mov		ecx, 70
		mov		edi, outbuffer
		rep		stosb
		mov		al, 0Ah
		stosb
		xor		eax, eax
		mov		ecx, 11
		mov		edi, getalbuffer
		rep		stosb

		mov		eax, [esi]
		mov		ebx, 10
		cdq								; kortere versie van vermenigvuldiging met 1
		mov		ecx, edx				; om later het teken te bepalen
		xor		eax, edx				; absolute waarde nemen
		sub		eax, edx				; meer absolute waarde sweetness
		std

uitsrlus:
		xor		edx, edx
		idiv	ebx
		xchg	al, dl
		or		al, 30h
		stosb
		xchg	al, dl
		cmp		eax, 0
		je		uitsrnalus
		jmp		uitsrlus

uitsrnalus:
		cld
		mov		esi, edi
		mov		edi, outbuffer
		cmp		ecx, 0
		je		uitsrgroterdannul
		mov		al, "-"
		stosb
uitsrgroterdannul:
		mov		ecx, 10
		rep 	movsb

		push	dword 71
		push	dword outbuffer
		push	dword stdout
		sys.write
		add		esp, 12

		popfd
		pop		edi
		pop		edx
		pop		ecx
		pop		ebx
		pop		eax

		ret		4