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

	; Add Proc calls

	
    jmp		_exit

_invalidFile:
	mDisplayString		OFFSET fileErrorMsg

_exit:
	Invoke ExitProcess,0
main ENDP

ParseTempsFromString PROC
	
ENDP

WriteTempsReverse PROC

ENDP

END main
