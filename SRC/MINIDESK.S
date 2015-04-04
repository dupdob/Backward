;********************************************************
;*							*
;*		MiniDesk, a small program launcher	*
;*			½ 1994 C.Dupuydauby		*
;*				V 1.00			*
;*							*
;********************************************************

MAXENT=40

	SECTION	TEXT
* Code de d‚marrage.
	PEA	1.w
	MOVE	#$20,-(SP)
	TRAP	#1
	ADDq	#6,SP
	TST.l	D0
	Beq.s	user
	CLR	-(SP)
	MOVE	#$20,-(SP)
	TRAP	#1
	ADDq	#6,SP
user
	MOVEA.l	4(SP),A6
	LEA	STACK(PC),SP
	MOVE.l	#256,D0
	ADD.l	12(A6),D0
	ADD.l	20(A6),D0
	ADD.l	28(A6),D0
	MOVE.l	#256,D0		juste basepage.
	MOVE.l	D0,-(SP)
	PEA	(A6)
	CLR	-(SP)
	MOVE	#$4A,-(SP)	Mshrink
	TRAP	#1
	LEA	12(SP),SP

	BSR	MAIN

	CLR	-(SP)
	TRAP	#1

MAIN
	PEA	DTA(PC)
	MOVE	#$1A,-(SP)		mise en place de la DTA.
	TRAP	#1
	ADDq	#6,SP
.rescan
	LEA	SELECT(PC),A0
	CLR	(A0)
	LEA	BUFFER(PC),A6
	MOVEq	#MAXENT,D7			max de fichiers.
	LEA	DTA+30(PC),A1
	CLR.l	(A1)+
	CLR.l	(A1)+
	CLR.l	(A1)+
	MOVE	#$10,-(SP)		directory.
	PEA	ALL(PC)
	MOVE	#$4E,-(SP)
	TRAP	#1
	ADDq	#8,Sp
.loop_dir
	TST.l	D0
	Bmi	.end_dir
	MOVEa.l	A6,A0
	MOVE.b	DTA+21(PC),D0
	CMPi	#$10,D0
	Bne.s	.next_dir
	LEA	DTA+30(PC),A1
	CMPi	#'.'*256,(A1)
	Beq.s	.next_dir
	MOVE.b	#'[',(A0)+
	REPT	12
	MOVE.b	(A1)+,D0
	Beq.s	.end_dirname
	MOVE.b	D0,(A0)+
	ENDR
.end_dirname
	MOVE.b	#']',(A0)+
	CLR	(A0)+
	LEA	16(A6),A6
	SUBq	#1,D7
	Beq	.end_scan
.next_dir
	LEA	DTA+30(PC),A1
	CLR.l	(A1)+
	CLR.l	(A1)+
	CLR.l	(A1)+
	MOVE	#$4F,-(SP)
	TRAP	#1
	ADDq	#2,SP
	Bra	.loop_dir
.end_dir
	LEA	DTA+30(PC),A1
	CLR.l	(A1)+
	CLR.l	(A1)+
	CLR.l	(A1)+
	CLR	-(SP)		fichiers.
	PEA	ALL(PC)
	MOVE	#$4E,-(SP)
	TRAP	#1
	ADDq	#8,Sp
.loop_file
	TST.l	D0
	Bmi	.end_file
	MOVEa.l	A6,A0
	LEA	DTA+30(PC),A1
	MOVEq	#8,D0
.get_period
	CMPi.b	#'.',(A1)+
	DBeq	D0,.get_period
	Bne	.next_file
	MOVE.b	#'.',D0
	REPT	3
	LSL.l	#8,D0
	MOVE.b	(A1)+,D0
	ENDR
	CMPi.l	#'.TOS',D0
	Beq.s	.ok
	CMPi.l	#'.PRG',D0
	Beq.s	.ok
	CMPi.l	#'.APP',D0
	Beq.s	.ok
	CMPi.l	#'.TTP',D0
	Bne.s	.next_file
.ok
	LEA	DTA+30(PC),A1
	REPT	12
	MOVE.b	(A1)+,D0
	Beq.s	.end_filename
	MOVE.b	D0,(A0)+
	ENDR
.end_filename
	CLR	(A0)+
	LEA	16(A6),A6
	SUBq	#1,D7
	Beq.s	.end_scan
.next_file
	LEA	DTA+30(PC),A1
	CLR.l	(A1)+
	CLR.l	(A1)+
	CLR.l	(A1)+
	MOVE	#$4F,-(SP)
	TRAP	#1
	ADDq	#2,SP
	Bra	.loop_file
.end_file
	CLR	(A6)+
.end_scan
	MOVE	#$19,-(SP)
	TRAP	#1
	ADDq	#2,Sp
	ADD.b	#'A',D0
	LEA	DRIVE(PC),A0
	MOVE.b	D0,(A0)
	PEA	TEXT(PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP
.refresh
	MOVEq	#36,D7
	MOVEq	#0,D6
	LEA	BUFFER(PC),A6
	LEA	POS(PC),A5
.display_loop
	TST	(A6)
	Beq	.end_display
	MOVE.b	D7,2(A5)
	MOVE.b	#32,3(A5)
	PEA	(A5)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP
	CMP	SELECT(PC),D6
	Bne.s	.not_inverse
	PEA	REV(PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,Sp
.not_inverse
	PEA	(A6)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,Sp
	PEA	NORM(PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,Sp
	ADDq	#1,D6
	LEA	16(A6),A6

	TST	(A6)
	Beq.s	.end_display
	MOVE.b	D7,2(A5)
	MOVE.b	#52,3(A5)
	PEA	(A5)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP
	CMP	SELECT(PC),D6
	Bne.s	.not_reverse
	PEA	REV(PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,Sp
.not_reverse
	PEA	(A6)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,Sp
	PEA	NORM(PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,Sp
	ADDq	#1,D6
	ADDq	#1,D7
	LEA	16(A6),A6
	CMPi	#MAXENT,D6
	BCs	.display_loop
.end_display
	LEA	BUFFER(PC),A6
	LEA	SELECT(PC),A5
	MOVE	(A5),D6
	MOVE	#7,-(SP)
	TRAP	#1
	ADDq	#2,SP
	CMPi.b	#$1B,D0
	Beq	.end_prg
	CMPi.b	#13,D0
	Beq	.run
	SWAP	D0
	CMPi.b	#$4B,D0
	Bne.s	.not_left
	BTST	#0,D6
	Beq.s	.end_display
	SUBq	#1,D6
	MOVE	D6,(A5)
	BRA	.refresh
.not_left
	CMPi.b	#$4D,D0
	Bne.s	.not_right
	BTST	#0,D6
	Bne.s	.end_display
	ADDq	#1,D6
	MOVE	D6,D0
	MULU	#16,D0
	TST	(A6,D0)
	Beq.s	.end_display
	MOVE	D6,(A5)
	BRA	.refresh
.not_right
	CMPi.b	#$48,D0
	Bne.s	.not_up
	CMPi	#2,D6
	Bcs.s	.end_display
	SUBq	#2,D6
	MOVE	D6,(A5)
	BRA	.refresh
.not_up
	CMPi.b	#$50,D0
	Bne.s	.not_down
	ADDq	#2,D6
	MOVE	D6,D0
	MULU	#16,D0
	TST	(A6,D0)
	Beq.s	.end_display
	MOVE	D6,(A5)
	BRA	.refresh
.not_down
	SWAP	D0
	ANDi	#$DF,D0
	CMPi.b	#'A',D0
	Bcs	.end_display
	CMPi.b	#'Z'+1,D0
	Bcc	.end_display
	SUB.b	#'A',D0
	EXT.w	D0
	MOVE	D0,-(SP)
	MOVE	#$E,-(SP)
	TRAP	#1
	ADDq	#4,Sp
	BRA	.rescan
.run
	MULU	#16,D6
	CMPi.b	#'[',(A6,D6)
	Bne.s	.not_directory
	LEA	(A6,D6),A0
.search_end
	CMPi.b	#']',(A0)
	Beq.s	.right_bracket
	ADDq	#1,A0
	BRA.s	.search_end
.right_bracket
	CLR.b	(A0)
	PEA	1(A6,D6)
	MOVE	#$3B,-(SP)
	TRAP	#1
	ADDq	#6,SP
	BRA	.rescan
.not_directory
	PEA	CLEAR(PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP
	PEA	NULL(PC)
	PEA	NULL(PC)
	PEA	(A6,D6)
	CLR	-(SP)
	MOVE	#$4B,-(SP)
	TRAP	#1
	LEA	16(SP),SP
	BRA	MAIN
.end_prg
	CLR	-(SP)
	TRAP	#1


	SECTION	DATA

TEXT	DC.b	27,'E',27,'f Minidesk 1.00 ½ 1994 Cyrille Dupuydauby.',10,13,10,13,'Drive '
DRIVE	DC.b	'A:',0
POS	DC.b	27,'Y',32,32,0
REV	DC.b	27,'p',0
NORM	DC.b	27,'q',0
ALL	DC.b	'*.*',0
NULL	DC.b	0
CLEAR	DC.b	27,'E',0

	SECTION	BSS

SELECT	DS	1

DTA	DS.b	44

BUFFER	DS.b	MAXENT*16

	DS.b	4096
STACK
	DS.b	8