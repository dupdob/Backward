; taille max
max_disks=2000
	INCLUDE	CONFIG.SYM

; convertisseur de bibliothŠques ancien->nouveau
; Code de d‚marrage.
	MOVEA.l	(4.w,SP),A6
	LEA	(STACK.w,PC),SP
	MOVE.l	#256,D0
	ADD.l	(12.w,A6),D0
	ADD.l	(20.w,A6),D0
	ADD.l	(28.w,A6),D0
	MOVE.l	D0,-(SP)
	PEA	(A6)
	CLR	-(SP)
	MOVE	#$4A,-(SP)	;Mshrink
	TRAP	#1
	LEA	(12.w,SP),SP
	
	PEA	(Welcome_Texte.w,PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP
; chargement de l'ancienne bibliothŠques.
	MOVE.l	#max_disks*100,-(SP)
	MOVE	#$48,-(SP)
	TRAP	#1
	ADDq	#6,SP
	TST.l	D0
	Beq	end
	MOVE.l	D0,Old_Lib

	CLR	-(SP)
	PEA	(Old_Name.w,PC)
	MOVE	#$3D,-(SP)
	TRAP	#1
	ADDq	#8,SP
	TST.l	D0
	Bmi	end

	MOVE	D0,D7
	MOVE.l	(Old_Lib.w,PC),-(SP)
	MOVE.l	#max_disks*100,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	TRAP	#1
	LEA	(12.w,SP),SP

	TST.l 	D0
	Bmi	end
	DIVU.l	#100,D0
	MOVE	D0,size

	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP
; conversions.
	MOVEq	#0,D0
	MOVE	(size.w,PC),D0
	MULU.l	#SIZEDISK,D0
	MOVE.l	D0,-(SP)
	MOVE	#$48,-(SP)
	TRAP	#1
	ADDq	#6,SP
	TST.l	D0
	Beq	end
	MOVE.l	D0,New_Lib
; boucles
	MOVEa.l	(New_Lib.w,PC),A0
	MOVEa.l	(Old_Lib.w,PC),A1
	MOVE	(size.w,PC),D0
	SUBq	#1,D0
loop
	MOVE	#7,D1
.copy_name
	MOVE.l	(A1)+,(A0)+
	DBf	D1,.copy_name
	
	MOVEq	#0,D7
	TST.b	(A1)+
	Beq.s	.not_8mhz
	ADDi.l	#Motor,D7
.not_8mhz
	ADDq	#1,A1
; caches ??
	MOVE.b	(A1)+,D2
	ANDi	#2,D2
	Beq.s	.no_icache
	ADDi.l	#ICache,D7
.no_icache
	ANDi	#1,D2
	Beq.s	.no_dcache
	ADDi.l	#DCache,D7
.no_dcache
	ADDq	#2,A1
; bus
	MOVE.b	(A1)+,D2
	CMPi	#3,D2
	Bne.s	.not_stmode
	ADDi.l	#StBus,D7
	Bra.s	.end_bus
.not_stmode
	CMPi	#2,D2
	Bne.s	.not_spec
	ADDi.l	#SBus,D7
	Bra.s	.end_bus
.not_spec
	CMPi	#1,D2
	Bne.s	.not_cor
	ADDi.l	#CBus,D7
;	Bra.s	.end_bus
.not_cor
.end_bus
; patchs
	TST.b	(A1)+
	Beq.s	.no_patch
	ADDi.l	#TosPatch,D7
.no_patch
	ADDq	#1,A1
; taille m‚moire.
	MOVE.b	(A1)+,D2
	CMPi	#1,D2
	Bne.s	.not_512K
	ADDi.l	#Mem512,D7
	Bra.s	.end_mem
.not_512K
	CMPi	#2,D2
	Bne.s	.not_1meg
	ADDi.l	#Mem1024,D7
	Bra.s	.end_mem
.not_1meg
	CMPi	#4,D2
	Bne.s	.not_2meg
	ADDi.l	#Mem2048,D7
	Bra.s	.end_mem
.not_2meg
	CMPi	#6,D2
	Bne.s	.not_max
	ADDi.l	#MemMax,D7
.not_max
.end_mem
; hp
	TST.b	(A1)+
	Beq.s	.no_hp
	ADDi.l	#InSpeak,D7
.no_hp
; HD
	TST.b	(A1)+
	Beq.s	.no_hd
	ADDi.l	#HardD,D7
.no_hd
; gem
	TST.b	(A1)+
	Beq.s	.no_gem
	ADDi.l	#Gem,D7
.no_gem
; skip
	ADDq	#8,A1
	MOVE.l	D7,(A0)+
; mot r‚serv‚e.
	CLR.l	(A0)+
.copy_keys
	REPT	3
	MOVE.l	(A1)+,(A0)+
	ENDR
	ADDa	#36,A1
	DBf	D0,loop

;sauvegarde.
	CLR	-(SP)
	PEA	(New_Name.w,PC)
	MOVE	#$3C,-(SP)
	TRAP	#1
	ADDq	#8,SP
	TST.l	D0
	Bmi.s	end

	MOVE	D0,D7
	MOVE.l	(New_Lib.w,PC),-(SP)
	MOVEq	#0,D0
	MOVE	(size.w,PC),D0
	MULU.l	#SIZEDISK,D0
	MOVE.l	D0,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$40,-(SP)
	TRAP	#1
	LEA	(12.w,SP),SP

	TST.l 	D0
	Bmi.s	end

	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP
end
	CLR	-(SP)
	TRAP	#1

	SECTION	DATA
Welcome_Texte	Dc.b	'Backward II->Backward III library converter.',0
Old_Name	Dc.b	'BACKWARD.DAT',0
New_Name	Dc.b	'BACKWARD.DKS',0

	SECTION	BSS

size		DS	1
New_Lib		Ds.l	1
Old_Lib		Ds.l	1
	Ds.b	256
STACK