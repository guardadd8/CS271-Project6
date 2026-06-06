TITLE Thermometer Readings Program     (Proj6_guardadd.asm)

; Author: Daniel Guardado
; Last Modified: 6/7/2026
; OSU email address: guardadd@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6               Due Date: 6/7/2026
; Description: ***This file is provided as a template from which you may work
;              when developing assembly projects in CS271.***

INCLUDE Irvine32.inc

mGetString MACRO introPromptRef:req, userInputRef:req, maxChars:req, bytesReadRef:req
	pushad
	
	mov		edx, introPromptRef
	call	WriteString
	mov		edx, userInputRef
	mov		ecx, maxChars
	call	ReadString
	mov		edx, bytesReadRef
	mov		[edx], eax

	popad
ENDM

mDisplayString MACRO stringRef:req
	push	edx

	mov		edx, stringRef
	call	WriteString

	pop		edx
ENDM

mDisplayChar MACRO charVal:req
    push	eax

    mov		al, charVal
    call	WriteChar

    pop		eax
ENDM

BUFFER_SIZE		= 4096
MAX_CHARS		= 32
TEMPS_PER_DAY	= 24
DELIMITER		= ','

.data

	introPrompt		BYTE	"Welcome to the Temperature Value Program. This program will read a comma-delimited file",13,10
					BYTE	"that must be ASCII-formatted. It will retrieve the stored temperature values and reverse",13,10
					BYTE	"the ordering in order to print them.",13,10,0
	fileNamePrompt	BYTE	"Enter the name of the file to be read: ",0
	fileErrorMsg	BYTE	"Incorrect file name.",13,10,0

	fileName		BYTE	MAX_CHARS		DUP(?)
	bytesRead		DWORD	?
	fileBuffer		BYTE	BUFFER_SIZE		DUP(?)
	tempArray		SBYTE	TEMPS_PER_DAY	DUP(?)
	fileHandle		DWORD	?

.code
main PROC
	mDisplayString	OFFSET introPrompt
	mGetString		OFFSET fileNamePrompt, OFFSET fileName, MAX_CHARS, OFFSET bytesRead

	mov		edx, OFFSET fileName
	call	OpenInputFile
	mov		fileHandle, eax

	cmp		eax, INVALID_HANDLE_VALUE
	je		_invalidFile
	
	mov		eax, fileHandle
    mov		edx, OFFSET fileBuffer
    mov		ecx, BUFFER_SIZE
    call	ReadFromFile
	mov		eax, fileHandle
    call	CloseFile

    push    OFFSET fileBuffer
    push    OFFSET tempArray
    call    ParseTempsFromString
	; Add Proc calls

    ; **************** TEMPCODE
    mov esi, OFFSET tempArray            ; ESI points to the start of the array
    mov ecx, LENGTHOF tempArray; ECX holds the loop counter (number of elements)

print_loop:
    movsx eax, BYTE PTR [esi]            ; Sign-extend the 1-byte SBYTE into the 32-bit EAX register
    call  WriteInt                       ; Print the correctly formatted signed integer
    call  Crlf                            

    add   esi, TYPE tempArray            ; Successfully moves forward by 1 byte
    loop  print_loop  
    ; **************** TEMPCODE
	
    jmp		_exit

_invalidFile:
	mDisplayString		OFFSET fileErrorMsg

_exit:
	Invoke ExitProcess,0
main ENDP

ParseTempsFromString PROC
    push    ebp
    mov     ebp, esp
    pushad

    mov     esi, [ebp + 12]     ; esi = pointer to fileBuffer string
    mov     edi, [ebp + 8]      ; edi = pointer to tempArray destination
    
    mov     ecx, 0              ; ecx will act as our running integer total
    mov     bl, 0               ; bl will track negative flag (0 = positive, 1 = negative)
    mov     bh, 0               ; bh will track if we processed any digits for this number (0 = no, 1 = yes)

_parseLoop:
    mov     al, [esi]           ; Grab current character
    inc     esi                 ; Move pointer forward for next round
    
    cmp     al, 0               ; Check for null terminator (end of file string)
    je      _saveFinal
    cmp     al, DELIMITER       ; Check for comma
    je      _saveValue
    cmp     al, 13              ; Check for Carriage Return (end of line)
    je      _saveValue
    cmp     al, 10              ; Check for Line Feed
    je      _parseLoop          ; Skip line feed, move to next character

    cmp     al, '+'             ; Is it an explicit plus sign?
    je      _parseLoop          ; Just skip it and move to the numbers
    
    cmp     al, '-'             ; Is it a negative sign?
    jne     _isDigit
    mov     bl, 1               ; Set negative flag to true
    jmp     _parseLoop

_isDigit:
    sub     al, '0'             ; Convert ASCII character to literal integer value
    movzx   eax, al
    
    mov     bh, 1               ; Explicitly flag that we have processed a valid digit
    ; Multi-digit math: total = (total * 10) + new_digit
    imul    ecx, ecx, 10
    add     ecx, eax
    jmp     _parseLoop

_saveValue:
    ; If we haven't seen any actual digits yet, don't save anything
    cmp     bh, 0
    je      _resetFlags

    ; Check if negative flag was set
    cmp     bl, 1
    jne     _store
    neg     ecx                 ; Negate the value if it was marked negative

_store:
    mov     [edi], cl           ; Store the lower byte into tempArray
    inc     edi                 ; Move to next byte slot in array

_resetFlags:
    mov     ecx, 0              ; Reset total accumulator
    mov     bl, 0               ; Reset negative flag
    mov     bh, 0               ; Reset digit validation tracker
    jmp     _parseLoop

_saveFinal:
    ; Catch any trailing numbers that didn't end with a delimiter
    cmp     bh, 0
    je      _done
    cmp     bl, 1
    jne     _storeFinal
    neg     ecx
_storeFinal:
    mov     [edi], cl

_done:
    popad
    pop     ebp
    ret     8
ParseTempsFromString ENDP

END main
