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

MAX_CHARS		= 21
TEMPS_PER_DAY	= 24
DELIMITER		= ','

.data

	introPrompt		BYTE	"Welcome to the intern error-corrector! I'll read a ','-delimited file storing a series of temperature values.",13,10
					BYTE	"The file must be ASCII-formatted. I'll then reverse the ordering and provide the corrected temperature",13,10
					BYTE	"ordering as a printout!",13,10,0

	userInput		BYTE	MAX_CHARS	DUP(?)
	bytesRead		DWORD	?
	fileBuffer		BYTE	TEMPS_PER_DAY	DUP(?)
	tempArray		BYTE	TEMPS_PER_DAY	DUP(?)

.code
main PROC
	mGetString		OFFSET introPrompt, OFFSET userInput, MAX_CHARS, OFFSET bytesRead


	Invoke ExitProcess,0
main ENDP

ParseTempsFromString PROC

ENDP


END main
