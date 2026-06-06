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
	tempArray       SDWORD  TEMPS_PER_DAY   DUP(?)
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

    push	OFFSET tempArray
	call	WriteTempsReverse
	
    jmp		_exit

_invalidFile:
	mDisplayString		OFFSET fileErrorMsg

_exit:
	Invoke ExitProcess,0
main ENDP

ParseTempsFromString PROC
    LOCAL   charBuffer[8]:BYTE, negativeFlag:DWORD
    pushad

    mov     esi, [ebp + 12]     ; ESI = pointer to fileBuffer string
    mov     edi, [ebp + 8]      ; EDI = pointer to tempArray destination
    
    mov     ecx, TEMPS_PER_DAY  ; Counter loop for exactly 24 elements

_collectLoop:
    ; Set up destination pointer to our local temporary buffer manually without LEA
    mov     edx, ebp
    sub     edx, 8              ; EDX = pointer to start of charBuffer local variable
    
    push    edi                 ; Save tempArray pointer while we use EDI
    mov     edi, edx            ; EDI now points to our local charBuffer
    cld                         ; Clear direction flag for string operations

_readChar:
    lodsb                       ; Load byte from [ESI] into AL, advances ESI
    cmp     al, DELIMITER       ; Comma reached?
    je      _endOfToken
    cmp     al, 13              ; Carriage Return reached?
    je      _endOfToken
    cmp     al, 10              ; Skip line-feeds
    je      _readChar
    cmp     al, 0               ; End of file string?
    je      _endOfToken

    stosb                       ; Store character from AL into local charBuffer
    jmp     _readChar

_endOfToken:
    mov     al, 0
    stosb                       ; Null-terminate our local substring

    ; --- Convert the string chunk inside charBuffer to an Integer ---
    push    esi                 ; Preserve main file string pointer
    mov     esi, edx            ; ESI points to the start of charBuffer
    
    mov     negativeFlag, 0     ; Reset our local sign tracker
    mov     ebx, 0              ; EBX will act as our accumulating total

    lodsb                       ; Load first character of the number
    cmp     al, '-'
    jne     _calculateDigit
    mov     negativeFlag, 1     ; Number is negative, toggle flag
    lodsb                       ; Fetch the next byte (the actual first digit)

_calculateDigit:
    sub     al, '0'             ; Convert ASCII character to literal value
    
    ; Simple multi-digit accumulation without 3-operand instructions
    ; total = total * 10
    push    eax                 ; Save our current digit
    mov     eax, ebx
    mov     edx, 10
    imul    edx                 ; EAX = EAX * 10
    mov     ebx, eax            ; Put total back into EBX
    pop     eax                 ; Restore our digit

    ; total = total + current_digit
    mov     edx, 0              ; Clear EDX manually
    mov     dl, al              ; Safely move byte to register without movzx
    add     ebx, edx            ; Add digit to running total

    lodsb                       ; Fetch next character
    cmp     al, 0               ; Process until our null terminator
    jne     _calculateDigit

    ; Apply negative sign if flag was set
    cmp     negativeFlag, 1
    jne     _finishStorage
    neg     ebx

_finishStorage:
    pop     esi                 ; Restore fileBuffer source pointer
    pop     edi                 ; Restore tempArray destination pointer
    
    mov     [edi], ebx          ; Store 32-bit SDWORD into array
    add     edi, TYPE tempArray ; Move to next SDWORD position (adds 4)
    
    loop    _collectLoop        ; Loop until all 24 integers are populated

    popad
    ret     8
ParseTempsFromString ENDP

WriteTempsReverse PROC
    push    ebp
    mov     ebp, esp
    pushad

    mov     esi, [ebp + 8]      ; ESI = pointer to start of tempArray
    
    ; Calculate the memory offset for the last element (index 23):
    ; Offset = (TEMPS_PER_DAY - 1) * TYPE tempArray = 23 * 4 = 92 bytes
    mov     eax, TEMPS_PER_DAY
    dec     eax                 ; EAX = 23
    mov     ebx, 4              ; Each SDWORD element is 4 bytes
    mul     ebx                 ; EAX = 23 * 4 = 92
    
    add     esi, eax            ; ESI now points directly to the last element
    mov     ecx, TEMPS_PER_DAY  ; Set loop counter to 24

_reverseLoop:
    ; Register Indirect addressing to fetch and print the signed integer
    mov     eax, [esi]
    call    WriteInt            ; Prints the signed value

    ; Print the delimiter after the number
    mDisplayChar DELIMITER      ; Invokes your required I/O macro

    ; Move pointer backward by 1 SDWORD element (4 bytes)
    sub     esi, 4              
    loop    _reverseLoop        ; Decrement ECX and repeat until 24 elements are done

    call    Crlf                ; Drop to a new line at the very end of the line output
    
    popad
    pop     ebp
    ret     4                   ; Clean up the single 4-byte stack parameter
WriteTempsReverse ENDP

END main
