.386 
.model flat, stdcall
.stack 1024

GetStdHandle proto a1:DWORD
WriteConsoleA proto a1:DWORD, a2:PTR BYTE, a3:DWORD, a4:DWORD, a5:PTR DWORD
ReadConsoleA proto a1:DWORD, a2:PTR BYTE, a3:DWORD, a4:PTR DWORD, a5:PTR DWORD
SetConsoleCursorPosition PROTO,a1:DWORD, a2:DWORD
GetTickCount PROTO
ExitProcess proto, ExitCode: dword
.data 
elements byte 100 dup("-") 
space byte 32,0
mines dword 10 dup(?)
columngrid byte 0ah,"  1 2 3 4 5 6 7 8 9 10",0ah,0
rowgrid byte "0123456789",0
nextrow byte 0ah
message1 byte "LETS PLAY MINESWEEPER!!",0
message2 byte 0ah,0ah,0ah,"The player must enter the grid element to be uncovered in the following format: r c (where r is row, c is column) :",0ah,0
message3 byte 0ah,"INVALID INPUT!! You must follow the appropiate format",0
message4 byte 0ah, "You have discovered a bomb, You LOSE!!"
message5 byte 0ah, "You lasted only "
buffer byte 10 dup(?)
closeIndex dword 8 dup(?)
timeArray byte 10 dup(?)
indexnumber dword ?
inhandle dword ? 
outhandle dword ? 
x dword ?
row dword ?
column dword ? 
seed dword 10
time dword ?
.code 
showGrid proc
invoke GetStdHandle,-11
mov outhandle, eax
invoke SetConsoleCursorPosition, outhandle, 00010023h
invoke WriteConsoleA, outhandle, offset message1, lengthof message1-1, offset x, 0 
invoke WriteConsoleA,outhandle,offset columngrid, lengthof columngrid-1, offset x, 0
mov ebp, offset rowgrid 
mov ecx, 10 
mov ebx, offset elements
l2:
push ecx
invoke WriteConsoleA, outhandle, offset nextrow, lengthof nextrow, offset x, 0
invoke WriteConsoleA,outhandle,ebp, 1, offset x,0
inc ebp
mov ecx, 10

l1:
push ecx
invoke WriteConsoleA, outhandle,offset space,lengthof space-1, offset x, 0
invoke WriteConsoleA, outhandle,ebx, 1, offset x, 0
inc ebx
pop ecx
Loop l1
pop ecx
loop l2
ret
showGrid endp

getInput proc
invoke WriteConsoleA, outhandle, offset message2, lengthof message2-1, offset x, 0
invoke GetStdHandle,-10
mov inhandle, eax
start:
invoke ReadConsoleA, inhandle,offset buffer, lengthof buffer-1, offset x, 0
mov ebp, x
mov buffer[ebp-2],0
cmp ebp, 5
jb invalidInput
movzx edx, buffer[0]
sub edx, 48
mov row, edx           ;row number
mov esi, offset buffer ;column number
add esi, 2
call ToDecimal
mov column, eax
jmp theend
invalidInput:
invoke WriteConsoleA, outhandle, offset message3, lengthof message3-1, offset x, 0
jmp start
theend:
ret
getInput endp

; Receives address of a null terminated character array in ESI
; Returns corresponding SIGNED number in EAX
ToDecimal PROC
    push esi
    cmp byte ptr [esi], '-'
    jne itspostive
    inc esi
    itspostive:
    mov ebx, 0            ; x = 0
    L1:
        mov cl, [esi]    ; Get a character
        cmp cl, 0        ; check if its a null character
        je endL1
        mov edi, 10
        mov eax, ebx
        mul edi            ; 10*x
        sub cl, 48        ; (s[i]-'0') 
                        ; the character has been converted to its corrsponding number
        movzx ecx, cl
        add eax, ecx    ; x*10 + (s[i]-48) 
        mov ebx, eax    ; x = x*10 + (s[i]-48)  
        inc esi
    jmp L1
    endL1:
    mov eax, ebx
    pop esi
    cmp byte ptr[esi], '-'
    jne itwaspositive
    neg eax
    itwaspositive:
ret
ToDecimal ENDP

ToString PROC
	push eax
	mov edi, 10
	mov ecx, 0				; Ecx will have the digit count in the end
	findnumofdigits:
		cmp eax, 0
		je exitfinddigits
		mov edx, 0
		div edi
		inc ecx
	jmp findnumofdigits
	exitfinddigits:
	pop eax
	push ecx
	mov byte ptr [esi+ecx] , 0 ; null terminate the string
	savecharacters:
		mov edx, 0
		div edi
		add dl, 48
		mov [esi+ecx-1], dl
	loop savecharacters
	pop eax
ret
ToString ENDP



calIndex proc
mov eax, row 
mov ebx, 10
mul ebx 
mov esi, column 
add eax, esi  

mov indexnumber, eax
ret
calIndex endp

generaterandom proc uses ebx edx
mov eax, 99
mov ebx, eax ; maximum value
mov eax, 343FDh
imul seed
add eax, 269EC3h
mov seed, eax ; save the seed for the next call
ror eax,8 ; rotate out the lowest digit
mov edx,0
div ebx ; divide by max value
mov eax, edx ; return the remainder
ret
generaterandom endp

minesInGrid proc
mov ecx, lengthof mines
mov edx, 0
L1:
mov eax, 99
call generaterandom
mov mines[edx*4], eax 
inc edx
loop L1
ret
minesInGrid endp

searchedIndex proc 
mov edx ,0
mov eax, indexnumber
mov ebx, 10
div ebx
cmp edx, 0
je leftmost 
cmp edx, 1
je rightmost
mov ebx, 0 
mov ebx, indexnumber
cmp ebx, 10
je lefttop
cmp ebx, 99
je leftbottom
cmp ebx, 0
je righttop
cmp ebx, 91
je rightbottom

cmp row,0
je highest
cmp row, 9   
je lowest 

middlevalues:
mov ebp, indexnumber 
inc ebp
mov closeIndex[0], ebp
mov ebp, indexnumber 
add ebp, 10
mov closeIndex[4], ebp
mov ebp, indexnumber 
sub ebp, 9
mov closeIndex[8], ebp
mov ebp, indexnumber 
add ebp, 9
mov closeIndex[12], ebp
mov ebp, indexnumber 
sub ebp, 11
mov closeIndex[16], ebp
mov ebp, indexnumber 
add ebp, 11 
mov closeIndex[20], ebp
mov ebp, indexnumber 
inc ebp
mov closeIndex[24], ebp
mov ebp, indexnumber 
dec ebp
mov closeIndex[28], ebp
jmp endmethod

highest:
mov ebp, indexnumber 
add ebp, 1
mov closeIndex[0], ebp 
mov ebp, indexnumber 
add ebp, 10
mov closeIndex[4], ebp 
mov ebp, indexnumber 
add ebp , 9
mov closeIndex[8], ebp
mov ebp, indexnumber 
add ebp, 11
mov closeIndex[12], ebp
mov ebp, indexnumber 
dec ebp
mov closeIndex[16], ebp
jmp endmethod

lowest:
mov ebp, indexnumber 
add ebp, 1
mov closeIndex[0], ebp
mov ebp, indexnumber 
sub ebp, 9
mov closeIndex[4], ebp
mov ebp, indexnumber 
sub ebp, 11
mov closeIndex[8], ebp
mov ebp, indexnumber 
sub ebp, 10
mov closeIndex[12], ebp
mov ebp, indexnumber 
sub ebp, 1
mov closeIndex[16], ebp
jmp endmethod


rightmost: 
cmp row, 0
je righttop
cmp row, 9 
je rightbottom

righttop:
mov ebp, indexnumber 
add ebp, 1
mov closeIndex[0], ebp 
mov ebp, indexnumber 
add ebp, 10
mov closeIndex[4], ebp 
mov ebp, indexnumber 
add ebp, 11
mov closeIndex[8], ebp
jmp endmethod

rightbottom:
mov ebp, indexnumber 
add ebp, 1
mov closeIndex[0], ebp 
mov ebp, indexnumber
sub ebp, 10
mov closeIndex[4], ebp 
mov ebp, indexnumber 
sub ebp, 9
mov closeIndex[8], ebp
jmp endmethod

mov ebp, indexnumber 
add ebp, 1
mov closeIndex[0], ebp
mov ebp, indexnumber 
add ebp, 10
mov closeIndex[4], ebp
mov ebp, indexnumber 
sub ebp, 10
mov closeIndex[8], ebp
mov ebp, indexnumber 
sub ebp, 9
mov closeIndex[12], ebp
mov ebp, indexnumber
add ebp, 11
mov closeIndex[16], ebp
jmp endmethod

leftmost:
cmp row, 0 
je lefttop
cmp row, 9
je leftbottom 
jmp midcase
lefttop:
mov ebp, indexnumber 
sub ebp , 1
mov closeIndex[0], ebp 
mov ebp, indexnumber 
add ebp, 10
mov closeIndex[4], ebp 
mov ebp, indexnumber 
add ebp, 9
mov closeIndex[8], ebp
jmp endmethod
midcase:
mov ebp, indexnumber 
inc ebp
mov closeIndex[0], ebp
mov ebp, indexnumber 
add ebp, 10
mov closeIndex[4], ebp
mov ebp, indexnumber 
sub ebp, 10
mov closeIndex[8], ebp
mov ebp, indexnumber 
sub ebp, 9
mov closeIndex[12], ebp
mov ebp, indexnumber 
add ebp, 11
mov closeIndex[16], ebp
jmp endmethod

leftbottom:
mov ebp, indexnumber
dec ebp
mov closeIndex[0], ebp 
mov ebp, indexnumber 
sub ebp, 10
mov closeIndex[4], ebp 
mov ebp, indexnumber 
sub ebp, 9
mov closeIndex[8], ebp
jmp endmethod
mov ebp, indexnumber 
sub ebp, 10
jmp endmethod
endmethod:
ret 
searchedIndex endp

showmine proc
mov ecx, 10
mov  esi, 0
l1:
mov eax, mines[esi*4]
mov elements[eax], "M"
inc esi
loop l1
invoke SetConsoleCursorPosition, outhandle , 00050000h
mov ebp, offset rowgrid 
mov ecx, 10 
mov ebx, offset elements
l4:
push ecx
invoke WriteConsoleA, outhandle, offset nextrow, lengthof nextrow, offset x, 0
invoke WriteConsoleA,outhandle,ebp, 1, offset x,0
inc ebp
mov ecx, 10

l5:
push ecx
invoke WriteConsoleA, outhandle,offset space,lengthof space-1, offset x, 0
invoke WriteConsoleA, outhandle,ebx, 1, offset x, 0
inc ebx
pop ecx
Loop l5
pop ecx
loop l4
invoke GetTickCount 
sub time, eax
mov eax, time
mov ebx, 1000
div ebx
mov esi,offset timeArray
call ToString
invoke WriteConsoleA, outhandle,offset message4 , lengthof message4 -1, offset x,0 
invoke WriteConsoleA, outhandle,offset message5, lengthof message5 -1, offset x, 0 
invoke WriteConsoleA, outhandle,offset timeArray, lengthof timeArray , offset x, 0
invoke ExitProcess, 0
ret
showmine endp

checkmine proc
mov esi,0
mov ecx , lengthof mines+1
l1:
mov eax, mines[esi*4]
cmp indexnumber, eax
je bomb
inc esi 
loop l1
jmp eend
bomb:
call showmine
eend:
ret 
checkmine endp

cleararray proc 
mov ecx, lengthof closeIndex
mov esi, 0
looop:
mov closeIndex[esi], 0
inc esi 
loop looop
ret 
cleararray endp

minelocator proc
call checkmine
mov ecx, lengthof closeIndex
mov esi, 0
mov ebp, 0
mov bl, 0
L1:
mov edx, closeIndex[esi*4]
push ecx
mov ecx, lengthof mines
L2:
mov eax, mines[ebp*4]
cmp eax, edx 
je increment
inc ebp
jmp endloop
increment:
inc ebp
inc bl
endloop:
loop L2
mov ebp ,0
pop ecx
inc esi
loop L1
mov eax, indexnumber
add bl , 48
mov elements[eax], bl
ret
minelocator endp

main proc
call minesInGrid
update:
call showGrid
invoke GetTickCount
;mov seed, eax
mov time, eax
call getInput
call calIndex
call searchedIndex
call minelocator
call cleararray
jmp update
endd:
main endp
end main