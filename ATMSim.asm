;------------------------------------------------------
; Bank ATM Machine
; Author: Saurabh Tomar
; Written for CPSC355
; Description: This program emulates a bank ATM Machine for
;				for a bank. It displays balance, deposits, 
;				withdraws, and prints bank data.
;------------------------------------------------------

INCLUDE Irvine32.inc

; Initialize the data
.DATA
; ----------------------- BANK DATA ----------------------- 
accountNumbers DWORD 10021331,12322244,44499922,10222334
PINS WORD 2341,3345,1923,3456
balances DWORD 1000,0,80000,4521

; ----------------------- OTHER DATA -----------------------
tries WORD 0			; Tracks the number of tries. MAX 3
logged_in WORD 0		; Tracks whether the user is authenticated
transCount WORD 0		; Tracks the number of SUCCESSFUL transactions commited by user
accpos DWORD 0			; Helps to keep track of the corresponding PIN with its account number
accountBalance DWORD 0	; Tracks the account balance
totalDeposits DWORD 0	; Tracks the total number of deposits
totalWithdrawls DWORD 0	; Tracks the total number of withdrawls
currentAccount DWORD 0	; Tracks the account number of the current session
max_withdraw DWORD 1000	; Maximum withdrawl amount allowed per transaction
max_transactions WORD 3 ; Maximum number of SUCCESSFULL transactions allowed

; ----------------------- GUI MESSAGES ----------------------- 
welcomeMsg BYTE "Welcome to Maze Bank",0dh,0ah,0dh,0ah,0

promptAccountNum BYTE "Please enter your account number: ",0
promptAccountPin BYTE "Please enter your PIN: ",0
promptAccountErr BYTE "No account with that number exits.",0dh,0ah,0dh,0ah,0
promptIncorrectPin BYTE "That is an incorrect pin.",0dh,0ah,0

atmOptions BYTE "1) Display Balance",0dh,0ah
			BYTE "2) Withdraw",0dh,0ah
			BYTE "3) Deposit",0dh,0ah
			BYTE "4) Print Receipt",0dh,0ah
			BYTE "5) Exit",0dh,0ah,0dh,0ah
			BYTE "Please select an option: ",0

depositOptions BYTE "1) Cash",0dh,0ah
				BYTE "2) Cheque",0dh,0ah,0dh,0ah
				BYTE "Please select a deposit option: ",0

promptWithdraw BYTE "Please enter the withdraw amount: ",0
promptDepositCash BYTE "Please enter the cash amount in multiples of $10: ",0
promptDepositCheque BYTE "Please enter the cheque amount: ",0

currentBalanceMsg BYTE "Your current balance is: ",0					

promptWithdawlSuccess BYTE "The Withdrawl was successful.",0dh,0ah
						BYTE "Your new balance is: ",0

promptDepositSuccess BYTE "The Deposit was successful.",0dh,0ah
						BYTE "Your new balance is: ",0

receipt_1 BYTE "Your account number: ",0
receipt_2 BYTE "Your account balance: ",0
receipt_3 BYTE "Your total withdrawls for this session: ",0
receipt_4 BYTE "Your total deposits for this session: ",0

promptInvalidChoice BYTE "That is an invalid selection. Please choose one of the 5 options.",0dh,0ah,0
promptInvalidWithdrawLimit BYTE "You are exceeding your withdrawl limit.",0
promptInvalidWithdrawBalance BYTE "You are exceeding your balance.",0
promptExceeded BYTE "You have exceeded your number",0dh,0ah
				BYTE "of transactions for this session.",0

promptExceedAttempts BYTE "You have exceeded your attempts. Goodbye!",0dh,0ah,0dh,0ah,0

promptEnd BYTE "Thank you for choosing MAZE Bank",0dh,0ah,0dh,0ah,0

divider BYTE "---------------------------------------------",0dh,0ah,0
errorDiv BYTE "------------------ WARNING ------------------",0dh,0ah,0 

.CODE

;------------------------------------------------------
; main
; This procedure is the outer case for all procedures 
; and calls each procedure based on where the user is 
; in the ATM login system. The user is directed based on
; successful login to appropriate procedures in here.
; Receives: nothing
; Returns: nothing
;------------------------------------------------------
main PROC
	
	; Display the ATM Welcome Message
	mov EDX, OFFSET welcomeMsg
	call WriteString
	
	; Validate the user's account number
	call auth_accountnum
	; Check to see if they have not exceeded 
	; their maximum login attempts
	cmp tries, 03h
	jge MAX_ATTEMPTS_FINISH

	; Authenticate the user's corresponding PIN
	call auth_accountpin
	; Check to see if they have not exceeded 
	; their maximum login attempts
	cmp tries, 03h
	jge MAX_ATTEMPTS_FINISH

	
	START_MENU:
	; Check to see if the user has been authenticated
	cmp logged_in, 1
	; if so then send them to the ATM Main menu
	je atm_menu

	; Default Flow towards program exit
	jmp FINISH

	MAX_ATTEMPTS_FINISH:
	call Crlf
	; Display that they have exeeded their login attempts and wait for prompt
	mov EDX, OFFSET promptExceedAttempts
	call WriteString
	call WaitMsg

	FINISH:
	exit

main ENDP

;------------------------------------------------------
; auth_accountnum
; This procedure first checks to see if the user has not
; maxed out their login attempts. Then it checks to see if 
; the user provided account number exists. It also tracks 
; which position of the array the accountNums the user account
; is so that the corresponding PIN can be located in the 
; auth_accountpin procedure.
; Receives: nothing
; Returns: nothing
;------------------------------------------------------
auth_accountnum PROC		
	
	START:
	; Check to make sure the user has 
	; not exceeded their login attempts.
	cmp tries,03h
	; if they have then exit the procedure
	jge EXIT_LOOP
	
	; Prompt the user for their account number
	mov accpos, 0 ; reset array tracking 
	mov EDX, OFFSET promptAccountNum
	call WriteString
	call ReadInt
	mov ECX, LENGTHOF accountNumbers
	mov ESI, OFFSET accountNumbers

	; Step through and find the account number
	L1:
		; Store the account number to display in the receipt
		mov currentAccount,EAX 
		cmp EAX,[ESI]
		je EXIT_LOOP
		; Array tracking
		inc accpos 
		add ESI, TYPE accountNumbers
		loop L1
	; If no account is found throw error and
	; and reprompt the user to enter account number
	mov EDX, OFFSET promptAccountErr
	call WriteString
	inc tries
	jmp START

	EXIT_LOOP:
	ret
auth_accountnum ENDP

;------------------------------------------------------
; auth_accountpin
; This procedure simply authenticates the user based 
; on their correct account PIN number
; Receives: nothing
; Returns: nothing
;------------------------------------------------------
auth_accountpin PROC
	
	; Store the current position of the Account Nums array
	; in EAX and multiply that by the size of pinarray's type
	; to get the correct matching PIN for the account.
	START:
	mov ESI, OFFSET PINS
	mov EAX, accpos
	mov ECX, TYPE PINS
	mul ECX
	add ESI, EAX

	; Check to make sure the user has 
	; not exceeded their login attempts.
	PIN_RETRY:
	cmp tries, 03h
	; if they have then exit the procedure
	jge EXIT_LOOP

	; Prompt/Re-Prompt the user to enter their PIN
	mov EDX, OFFSET promptAccountPin
	call WriteString
	call ReadInt

	; Check to see if it is valid
	cmp AX,[ESI]
	je PIN_VALID

	; Check to see if it is invalid
	cmp AX,[ESI]
	jne PIN_INVALID

	; If PIN is invalid increment login attempts and 
	; if the user has not exceeded login attempts send 
	; them back to the prompt screen.
	PIN_INVALID:
	inc tries
	mov EDX, OFFSET promptIncorrectPin
	call WriteString
	jmp PIN_RETRY

	; If PIN in valid then set the logged in variable to 1
	; and capture the account balance into the accountBalance
	; variable
	PIN_VALID:
	mov logged_in, 1
	mov ESI, OFFSET balances
	mov EAX, TYPE balances
	mul accpos
	add ESI, EAX
	mov EAX, [ESI]
	; Capture account balance
	mov accountBalance, EAX
	jmp EXIT_LOOP

	EXIT_LOOP:
	ret
auth_accountpin ENDP

;------------------------------------------------------
; atm_menu
; This procedure directs the user to the appropriate ATM 
; menu selections they make and validates their menu 
; selection input.
; Receives: nothing
; Returns: nothing
;------------------------------------------------------
atm_menu PROC
	
	; Display/Re-Display the ATM Menu Options
	START:
	call Crlf
	mov EDX, OFFSET atmOptions
	call WriteString
	call ReadInt

	; If the input is less than equal to 0 
	; then throw error
	cmp AL,00h
	jle INVALID_SELECTION

	; If the input is greater than 5 
	; then throw error
	cmp AL,05h
	jg INVALID_SELECTION

	; 1) Display Balance
	cmp AL,01h
	je displayBal

	; 2) Withdrawl
	cmp AL,02h
	je withdrawBal

	; 3) Deposit
	cmp AL,03h
	je depositBal

	; 4) Print Receipt
	cmp AL,04h
	je receiptBal

	; 5) Exit program
	cmp AL,05h
	je EXIT_LOOP

	; No selection entered. Default back to the ATM Menu
	jmp START

	; Redirect the user to proper Procedures based
	; on their menu choices.
	displayBal:
		call displayBalance
		jmp START

	withdrawBal:
		call withdraw
		jmp START

	depositBal:
		call deposit
		jmp START
	
	receiptBal:
		call printReceipt
		jmp START

	; end of redirects	

	; Deal with invalid user choice
	INVALID_SELECTION:
	call Crlf
	mov EDX, OFFSET promptInvalidChoice
	call WriteString
	jmp START

	EXIT_LOOP:
	ret
atm_menu ENDP

;------------------------------------------------------
; displayBalance
; This procedure displays the user's current balance.
; Receives: nothing
; Returns: nothing
;------------------------------------------------------
displayBalance PROC
	pushad
	call printDivider
	; Display the current balance to the user
	mov EDX, OFFSET currentBalanceMsg
	call WriteString
	mov EAX, accountBalance
	call WriteInt
	call printDivider
	popad
	ret
displayBalance ENDP

;------------------------------------------------------
; withdraw
; This procedure withdraws money from the user account.
; It also check for max transaction attempts and checks to
; make sure the withdrawl is not more than the account balance
; Receives: nothing
; Returns: nothing
;------------------------------------------------------
withdraw PROC
	pushad
	
	; Check to see if the user has not exceeded
	; their max transactions for the session
	mov AX, transCount
	cmp AX, max_transactions
	jge EXCEEDED

	; Ask user how they wish to withdraw
	mov edx, OFFSET promptWithdraw
	call WriteString
	call ReadInt

	; Check if the withdrawl amount is not greater
	; than the max amount per transaction
	cmp EAX,max_withdraw
	jg INVAL_WITHDRAW

	; Check if the withdrawl amount is not less than
	; their current account balance
	cmp EAX,accountBalance
	jg INVAL_BALANCE

	; If all is well then withdraw the amount and display
	; the new balance. 
	sub accountBalance,EAX
	sub totalWithdrawls,EAX
	inc transCount
	mov EDX, OFFSET promptWithdawlSuccess
	call printDivider
	call WriteString
	mov EAX, accountBalance
	call WriteInt
	call printDivider
	call Crlf
	jmp EXIT_LOOP

	; Prompt user that they have exceeded their maximum
	; amount per transaction amount
	INVAL_WITHDRAW:
	call printErrorDiv
	mov EDX, OFFSET promptInvalidWithdrawLimit
	call WriteString
	call printDivider
	jmp EXIT_LOOP

	; Prompt user that they have exceeded their 
	; current account balance
	INVAL_BALANCE:
	call printErrorDiv
	mov EDX, OFFSET promptInvalidWithdrawBalance
	call WriteString
	call printDivider
	jmp EXIT_LOOP

	; Prompt user that they have exceeded their 
	; max number of transaction attempts for this session
	EXCEEDED:
	call printErrorDiv
	mov EDX, OFFSET promptExceeded
	call WriteString
	call printDivider
	jmp EXIT_LOOP

	EXIT_LOOP:
	popad
	ret
withdraw ENDP

;------------------------------------------------------
; deposit
; This procedure deposits cash or cheques into the user account.
; It also check for max transaction attempts.
; Receives: nothing
; Returns: nothing
;------------------------------------------------------
deposit PROC
	pushad

	; Check to see if the user has not exceeded
	; their max transactions for the session
	mov AX, transCount
	cmp AX, max_transactions
	jge EXCEEDED

	; Prompt/Re-prompt for deposit options
	DEPOSIT_OPTS:
	call Crlf
	mov EDX, OFFSET depositOptions
	call WriteString
	call ReadInt

	; Check if user wants to deposit cash
	cmp AL,01h
	je CASH

	; Check if user wants to deposit cheque
	cmp AL,02h
	je CHEQUE
	
	; Validate user input. Anyother option 
	; will cause a reprompt of the deposit menu
	; Check if user entered less than or equal to 0
	cmp AL,00h
	jle DEPOSIT_OPTS
	; Check if user entered greater than or equal to 3
	cmp AL,003h
	jge DEPOSIT_OPTS

	; Prompt user for cash deposit
	CASH:
	mov edx, OFFSET promptDepositCash
	call WriteString
	call ReadInt
	jmp START

	; Prompt user for cheque deposit
	CHEQUE:
	mov edx, OFFSET promptDepositCheque
	call WriteString
	call ReadInt

	; Deposit the cheque or cash, update the balance, 
	; and display the new balance
	START:
	add accountBalance,EAX
	add totalDeposits,EAX
	inc transCount
	mov EDX, OFFSET promptDepositSuccess
	call printDivider
	call WriteString
	mov EAX, accountBalance
	call WriteInt
	call printDivider
	call Crlf
	jmp EXIT_LOOP

	; Prompt user that they have exceeded their 
	; max number of transaction attempts for this session
	EXCEEDED:
	call printErrorDiv
	mov EDX, OFFSET promptExceeded
	call WriteString
	call printDivider
	jmp EXIT_LOOP

	EXIT_LOOP:
	popad
	ret
deposit ENDP

;------------------------------------------------------
; printReceipt
; This procedure displays a neat overview of the user's
; account data and their current session stats of total 
; deposits and total withdrawls. 
; Receives: nothing
; Returns: nothing
;------------------------------------------------------
printReceipt PROC
	pushad
	call printDivider

	; Display the Account Number
	mov EDX, OFFSET receipt_1
	call WriteString
	mov EAX, currentAccount
	call WriteInt
	call Crlf

	; Display the Account Balance
	mov EDX, OFFSET receipt_2
	call WriteString
	mov EAX, accountBalance
	call WriteInt
	call Crlf

	; Display the total of all withdrawls
	mov EDX, OFFSET receipt_3
	call WriteString
	mov EAX, totalWithdrawls
	call WriteInt
	call Crlf

	; Display the total of all deposits
	mov EDX, OFFSET receipt_4
	call WriteString
	mov EAX, totalDeposits
	call WriteInt

	call printDivider
	popad
	ret
printReceipt ENDP

;------------------------------------------------------
; printDivider
; Displays a horizontal divider. For GUI purposes.
; Receives: nothing
; Returns: nothing
;------------------------------------------------------
printDivider PROC
	pushad
	call Crlf
	mov EDX, OFFSET divider
	call WriteString
	popad
	ret
printDivider ENDP

;------------------------------------------------------
; printErrorDiv
; Displays a horizontal divider for errors. For GUI purposes.
; Receives: nothing
; Returns: nothing
;------------------------------------------------------
printErrorDiv PROC
	pushad
	call Crlf
	mov EDX, OFFSET errorDiv
	call WriteString
	popad
	ret
printErrorDiv ENDP

END main 
