TITLE Temperature Reader Program     (Proj6_guardadd.asm)

; Author: Daniel Guardado
; Last Modified: 6/7/2026
; OSU email address: guardadd@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 6               Due Date: 6/7/2026
; Description:  This programs asks the user to enter the name of a file that will contain 
;               comma-delimited temperature values. The program will then open the file, 
;               read the temperatures, and print the signed values in reverse order.

INCLUDE Irvine32.inc


; -----------------------------------------------------------------
; Name: mGetString
;
; Displays a prompt and reads a string of characters.
;
; Preconditions: Do not use EDX or ECX as arguments.
;
; Receives:
;   fileNamePromptRef   = address of text prompt to display
;   fileNameRef         = address of byte array to store input in
;   maxChars            = maximum number of characters to read
;   bytesReadRef        = address variable that stores read length
;
; Returns:
;   fileNameRef         = user typed string
;   bytesReadRef        = number of bytes read
; -----------------------------------------------------------------
mGetString MACRO fileNamePromptRef:req, fileNameRef:req, maxChars:req, bytesReadRef:req
	pushad
	
	mov		edx, fileNamePromptRef
	call	WriteString
	mov		edx, fileNameRef
	mov		ecx, maxChars
	call	ReadString
	mov		edx, bytesReadRef
	mov		[edx], eax

	popad
ENDM

; ---------------------------------------------------------------
; Name: mDisplayString
;
; Prints an ASCII-formatted, null-terminated string to console.
;
; Preconditions: stringRef must refer to null-terminated string.
;
; Receives:
;   stringRef   = address of string
; ---------------------------------------------------------------
mDisplayString MACRO stringRef:req
	push	edx

	mov		edx, stringRef
	call	WriteString

	pop		edx
ENDM

; ----------------------------------------------------
; Name: mDisplayChar
;
; Displays a single ASCII character to the console.
;
; Receives:
;   charVal = ASCII character (literal/constant)
; ----------------------------------------------------
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

	introPrompt		BYTE	"Welcome to the Temperature Reader Program. This program will read a comma-delimited file",13,10
					BYTE	"that must be ASCII-formatted. It will retrieve the stored temperature values and reverse",13,10
					BYTE	"the ordering to then print them.",13,10,0
	fileNamePrompt	BYTE	"Enter the name of the file to be read: ",0
	fileErrorMsg	BYTE	"Incorrect file name.",13,10,0
    farewellMsg     BYTE    "Goodbye.",0

	fileName        BYTE    MAX_CHARS       DUP(?)  ; File name buffer for user string input
    bytesRead       DWORD   ?                       ; Length of user string input
    fileBuffer      BYTE    BUFFER_SIZE     DUP(?)  ; Buffer for raw text contents from file
    tempArray       SDWORD  TEMPS_PER_DAY   DUP(?)  ; Array for storing converted signed integers
    fileHandle      DWORD   ?                       ; System handle variable for the opened file

.code
main PROC
; Display introduction
    mDisplayString  OFFSET introPrompt

_promptUser:
    ; Get user filename, attempt to open file.
    mGetString      OFFSET fileNamePrompt, OFFSET fileName, MAX_CHARS, OFFSET bytesRead
    mov             edx, OFFSET fileName
    call            OpenInputFile
    mov             fileHandle, eax

    ; Check file handle. If negative, throw error message and reprompt.
    cmp             eax, INVALID_HANDLE_VALUE
    jne             _fileValid
    mDisplayString  OFFSET fileErrorMsg
    jmp             _promptUser

_fileValid:
    ; Read and store text data stream into fileBuffer. Close file stream after finished.
    mov             eax, fileHandle
    mov             edx, OFFSET fileBuffer
    mov             ecx, BUFFER_SIZE
    call            ReadFromFile
    mov             eax, fileHandle
    call            CloseFile

    ; Convert fileBuffer content into formatted SDWORD values.
    push            OFFSET fileBuffer
    push            OFFSET tempArray
    call            ParseTempsFromString

    ; Print converted signed array items in reverse order.
    push            OFFSET tempArray
    call            WriteTempsReverse

    ; Display farewell message.
    call            CrLf
    mDisplayString  OFFSET farewellMsg

_exit:
    Invoke  ExitProcess,0
main ENDP

; ---------------------------------------------------------------------------------
; Name: ParseTempsFromString
;
; Parses ASCII data string from a text file buffer, extracts numerical 
; digit characters separated by delimiters, and converts them into signed
; integers stored sequentially within destination array.
;
; Preconditions:    fileBuffer must contain valid null-terminated string of data.
;                   tempArray must hold at least TEMPS_PER_DAY elements.
;
; Receives:
;   [ebp + 12] = address of text-contents buffer
;   [ebp + 8]  = address of destination array
;
; Returns:
;   tempArray  = holds converted signed integer values
; ---------------------------------------------------------------------------------
ParseTempsFromString PROC
    LOCAL   charBuffer[8]:BYTE, negativeFlag:DWORD
    pushad

    mov     esi, [ebp + 12]     ; fileBuffer
    mov     edi, [ebp + 8]      ; tempArray
    mov     ecx, TEMPS_PER_DAY  

_collectLoop:
    ; Set pointer to charBuffer. 
    mov     edx, ebp
    sub     edx, 8              ; Point to charBuffer
    push    edi                 ; Preserve tempArray pointer and point EDI to charBuffer
    mov     edi, edx            
    cld                         

_readChar:
    ; Check if comma, carriage return, line-feed, or end of string is reached and properly deal with them.
    lodsb                       
    cmp     al, DELIMITER       ; Check if comma reached
    je      _endOfToken
    cmp     al, 13              ; Check for carriage return
    je      _endOfToken
    cmp     al, 10              ; Check and skip line-feeds
    je      _readChar
    cmp     al, 0               ; Check if end of string
    je      _endOfToken
    stosb                       ; Store AL character in charBuffer
    jmp     _readChar

_endOfToken:
    mov     al, 0
    stosb                       ; Null-terminate substring

    ; Convert substring in charBuffer to integer
    push    esi                 
    mov     esi, edx            ; Point ESI to charBuffer
    
    mov     negativeFlag, 0     ; Reset local sign tracker
    mov     ebx, 0              ; Accumulator

    lodsb                       
    cmp     al, '-'
    jne     _calculateDigit
    mov     negativeFlag, 1     ; Toggle flag if negative number
    lodsb                       ; Get first digit in substring

_calculateDigit:
    sub     al, '0'             ; Convert ASCII character to literal value
    
    ; Perform multi-digit accumulation, total = (total * 10) + current_digit
    push    eax                 
    mov     eax, ebx
    mov     edx, 10
    imul    edx                 
    mov     ebx, eax            
    pop     eax                 

    mov     edx, 0              
    mov     dl, al              ; Move byte to sub-register
    add     ebx, edx            ; Add digit to current total

    lodsb                       
    cmp     al, 0               ; Process until null terminator
    jne     _calculateDigit

    ; Apply negative sign if set flag
    cmp     negativeFlag, 1
    jne     _finishStorage
    neg     ebx

_finishStorage:
    pop     esi                 ; Restore fileBuffer pointer
    pop     edi                 ; Restore tempArray pointer
    
    mov     [edi], ebx          ; Store signed value into array
    add     edi, TYPE tempArray ; Move to next tempArray position
    
    loop    _collectLoop

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

    call    CrLf                ; Drop to a new line at the very end of the line output
    
    popad
    pop     ebp
    ret     4                   ; Clean up the single 4-byte stack parameter
WriteTempsReverse ENDP

END main
