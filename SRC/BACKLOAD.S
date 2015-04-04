;________________________________________________________________
;[								]
;[	Backward III, chargeur du moteur d'‚mulation		]
;[		½ 1994 Cyrille Dupuydauby.			]
;[			version 1.00				]
;[______________________________________________________________]
;[ Notes:							]
;[ 14/10/94: Nouvelle approche, on n'utilise que 160Ko		]
;[		en mode reboot.					]
;[ 16/10/94: Am‚lioration de la m‚thode pr‚c‚dente. Fonction	]
;[		d'allocation.					]
;[ 02/11/94: Nouvelle m‚thode pour l'allocation.		]
;[ 27/11/94: Chargement de fichier image des ROMs.		]
;[ 30/11/94: Optimisation m‚moire pour les images des ROMs.	]
;[ 05/01/95: Utilisation de softs ROMs y compris pour TOS <>	]
;[ 12/03/95: R‚serve la zone FFFFC000-FFFFE000 pour des appels	]
;[		courts a des sous-routines.			]
;[ 25/03/95: Charge le MiniDesk					]
;[______________________________________________________________]


; Options d'assemblage
	OPT	O+,OW+,V+,W+

; inclusions
	INCDIR	D:\ASM\LIB

	INCLUDE	SYSTEM.SYM
	INCLUDE	ERROR.SYM

	INCLUDE	PMMUCALL.SYM
	INCLUDE	CONFIG.SYM

; d‚calage initial.
ISHIFT =     8
; Niveau A
ABITSZ =     9
APAGENB=    1<<ABITSZ
APAGESZ= 1<<(32-ISHIFT-ABITSZ)
; Niveau B
BBITSZ =     2
BPAGENB=    1<<BBITSZ
BPAGESZ= 1<<(32-ISHIFT-ABITSZ-BBITSZ)
; Niveau C
CBITSZ =      0
CPAGENB=      1<<CBITSZ
CPAGESZ= 1<<(32-ISHIFT-ABITSZ-BBITSZ-CBITSZ)
; Valeur du TC.
TCVALUE=((((((1<<11+32-ABITSZ-BBITSZ-CBITSZ-ISHIFT)<<4+ISHIFT)<<4+ABITSZ)<<4)+BBITSZ)<<4+CBITSZ)<<4

; taille de la page.
PAGESZ= BPAGESZ

	SECTION	TEXT

	MOVEa.l	4(SP),A6
	LEA	(myStack.w,PC),SP
	MOVE.l	#256,D7
	ADD.l	(p_tlen.w,A6),D7
	ADD.l	(p_dlen.w,A6),D7
	ADD.l	(p_blen.w,A6),D7
	MOVE.l	D7,programsize
; Pas de Mshrink pour le moment
	MOVE.l	D7,-(SP)
	MOVE.l	(p_lowtpa.w,A6),-(SP)
	CLR	-(SP)
	MOVE	#$4A,-(SP)
	TRAP	#1
	LEA	(12.w,SP),SP
	MOVE.l	D7,D1

	MOVE.l	#'BCKW',D0
	BSR	Read_Cookie
; Backward d‚j… r‚sident.
	TST.l	D0
	Beq	al_res
	
; Texte d'installation
	PEA	(INSTEXT.w,PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP

; lecture des pr‚f‚rences.
	CLR.l	_prefs
	CLR	-(SP)
	PEA	(PrefName.w,PC)
	MOVE	#$3D,-(Sp)
	TRAP	#1
	ADDq	#8,SP
	TST.l	D0
	Bmi.s	no_prefs
	MOVE	D0,D7
	PEA	(Prefs.w,PC)
	MOVE.l	#SIZEPREF,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	TRAP	#1
	LEA	(12.w,SP),SP
	
	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP

	MOVE.l	#Prefs,_prefs

no_prefs
; Ouverture du fichier.
	CLR	-(SP)
	PEA	(ExeName.w,PC)
	MOVE	#$3D,-(SP)
	TRAP	#1
	ADDq	#8,SP

	TST.l	D0
	Bpl.s	ok
	PEA	(NO_EXE.w,PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP

	MOVE	#7,-(SP)
	TRAP	#1
	ADDq	#2,SP
	Bra.s	end
ok
	MOVE	D0,D7
; On le lit.
	PEA	(Ehancer_Dump.w,PC)
	MOVE.l	#65536,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	TRAP	#1
	LEA	12(SP),SP

	MOVE.l	(2+Ehancer_Dump.w,PC),D0
	ADD.l	(6+Ehancer_Dump.w,PC),D0
	ADD.l	(10+Ehancer_Dump.w,PC),D0
	MOVE.l	D0,Ehancer_Size

; On le ferme.
	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP

; Mode superviseur (et on y reste).
	CLR.l	-(SP)
	MOVE	#$20,-(SP)
	TRAP	#1
	ADDq	#6,SP
	MOVE.l	D0,-(SP)
; Il faut le reloger.
	BSR	Reboot_Mode
; fin de supervieur.
	MOVE	#$20,-(SP)
	TRAP	#1
	ADDq	#6,SP
al_res
end
	CLR	-(SP)
	TRAP	#1

; Gestions des librairies.
; installe une configuration fix‚e en paramŠtres.
Set_Config
	MOVEm.l	A0/D0-D2,-(SP)
	CARGS	#16,CONFIG.l,WHERE.l
	MOVE.l	([CONFIG.w,SP]),D0
	MOVEa.l	(WHERE.w,SP),A0
	MOVEq	#Motor,D1
	AND.l	D0,D1
	Seq	(pClock.w,A0)
	MOVEq	#TosPatch,D1
	AND.l	D0,D1
	Sne	(pTOS.w,A0)
	MOVE.l	#HardD,D1
	AND.l	D0,D1
	Sne	(pHD.w,A0)
	MOVE.l	#Gem,D1
	AND.l	D0,D1
	Sne	(pGEM.w,A0)
	MOVE.l	#InSpeak,D1
	AND.l	D0,D1
	Sne	(pSpeaker.w,A0)
; m‚moire.
	MOVE.l	#Memsize,D1
	AND.l	D0,D1
	CMPi.l	#Mem512,D1
	Bne.s	.not_512
	CLR.b	(memSize.w,A0)
	Bra.s	.mem_end
.not_512
	CMPi.l	#Mem1024,D1
	Bne.s	.not_1024
	MOVE.b	#1,(memSize.w,A0)
	Bra.s	.mem_end
.not_1024
	CMPi.l	#Mem2048,D1
	Bne.s	.not_2048
	MOVE.b	#2,(memSize.w,A0)
	Bra.s	.mem_end
.not_2048
	MOVE.b	#3,(memSize.w,A0)
.mem_end	
; caches
	MOVE.l	#$3111,D2
	MOVEq	#ICache,D1
	AND.l	D0,D1
	Bne.s	.no_icache
	ANDi.l	#$FFFFFF00,D2	
.no_icache
	MOVEq	#DCache,D1
	AND.l	D0,D1
	Bne.s	.no_dcache
	ANDi.l	#$FFFF00FF,D2	
.no_dcache
	MOVE.l	D2,(pCache.w,A0)
; erreurs bus
	CLR.b	(pBusMode.w,A0)
	MOVEq	#Buserr,D1
	AND.l	D0,D1
	CMPi	#CBus,D1
	Bne.s	.not_corrected
	MOVE.b	#0,(pBusMode.w,A0)
	Bra.s	.end_bus
.not_corrected
	CMPi	#SBus,D1
	Bne.s	.not_special
	MOVE.b	#2,(pBusMode.w,A0)
	Bra.s	.end_bus
.not_special
	CMPi	#StBus,D1
	Bne.s	.not_STmode
	MOVE.b	#1,(pBusMode.w,A0)
.not_STmode
.end_bus
; vid‚o.
	MOVE.l	#Video,D1
	AND.l	D0,D1
	CMPi.l	#VLow,D1
	Bne.s	.not_low
	CLR.b	(pVideo.w,A0)
	Bra.s	.video_end
.not_low
	CMPi.l	#VMed,D1
	Bne.s	.not_med
	MOVE.b	#1,(pVideo.w,A0)
	Bra.s	.video_end
.not_med
	CMPi.l	#VHigh,D1
	Bne.s	.not_high
	MOVE.b	#2,(pVideo.w,A0)
	Bra.s	.video_end
.not_high
	MOVE.b	#-1,(pVideo.w,A0)
.video_end	
	MOVEm.l	(SP)+,A0/D0-D2
	RTS

Get_CJar
; r‚cupŠre la cookie-jar
	MOVEM.l	A1-A3/D1-D3,-(SP)
	PEA	(.GET_COOKIE.w,PC)
	MOVE	#$26,-(SP)
	TRAP	#14
	ADDQ	#6,SP
	TST.l	D0
	BNE.s	.JAR_OK
	MOVEQ	#ER_NOJAR,D0
	BRA.s	.END
.JAR_OK
	MOVEA.l	D0,A0
	MOVEQ	#0,D0
.END
	MOVEM.l	(SP)+,A1-A3/D1-D3
	TST.l	D0
	RTS

.GET_COOKIE
	MOVE.l	(cookie_jar).w,D0
	RTS

Read_Cookie
; lit la valeur d'un cookie fix‚ dans D0, retourn‚ en D1.
	MOVEM.l	A0/D2-D3,-(SP)
	MOVE.l	D0,D2
	BSR.s	Get_CJar
	BMI.s	.error
	MOVEQ	#ER_NOCK,D0
.loop
	MOVE.l	(A0),D3
	BEQ.s	.error
	CMP.l	D2,D3
	BEQ.s	.found
	ADDQ.l	#8,A0
	BRA.s	.loop
.found
	MOVE.l	(4.w,A0),D1
	MOVEQ	#0,D0
.error
	MOVEM.l	(SP)+,A0/D2-D3
	TST.l	D0
	RTS


; Installation pour Reboot.
;--------------------------
Reboot_Mode
; En mode Reboot, on le reloge en $ED8000 (logique) quoiqu'il arrive.
; D'abord trouver l'adresse physique.
; IMPORTANT: On suppose que la taille m‚moire s'exprime en Meg entiers.
; chargement de la bibliothŠque.
	CLR	(size)
	MOVE.l	#2000*SIZEDISK,-(SP)
	MOVE	#$48,-(SP)
	TRAP	#1
	ADDq	#6,SP
	TST.l	D0
	Beq	.end

	MOVE.l	D0,_lib
	CLR	-(SP)
	PEA	(LibName.w,PC)
	MOVE	#$3D,-(SP)
	TRAP	#1
	ADDq	#8,SP
	TST.l	D0
	Bmi	.end

	MOVE	D0,D7
	MOVE.l	(_lib.w,PC),-(SP)
	MOVE.l	#2000*SIZEDISK,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	TRAP	#1
	LEA	(12.w,SP),SP

	TST.l 	D0
	Bmi.s	.end
	MOVE.l	D0,_rlib_size
	MOVE.l	D0,D6
	DIVU.l	#SIZEDISK,D0
	MOVE	D0,size

	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP
	MOVE	#$2700,SR	; pas d'interruptions.

; pr‚paration de la Pmmu
	BSR	Init_Pmmu
; on charge le minidesk.
	BSR	LoadMiniDesk
; chargement ‚ventuel d'une image
	BSR	Soft_Roms
; transfert de la biliothŠque.
; calcul sur D6, pour d‚terminer un buffer suffisant.
	MOVE.l	(_rlib_size.w,PC),D6
	ADDi.l	#PAGESZ-1,D6	; on arrondi … la page sup.
	ANDi.l	#-PAGESZ,D6
	MOVE.l	D6,D0
	DIVU.l	#SIZEDISK,D0
	MOVE	D0,maxsize

	MOVE.l	D6,-(SP)
	JSR	PMMURESERVE
	ADDq	#4,SP
	MOVEa.l	(_lib.w,PC),A1
	MOVE.l	D0,A0
	MOVE.l	D0,_lib
.copy_lib
	MOVE.b	(A1)+,(A0)+
	SUBq.l	#1,D6
	Bne.s	.copy_lib
.end
; r‚servation de la m‚moire
	MOVE.l	(Ehancer_Size.w,PC),-(SP)
	JSR	PMMURESERVE
	ADDq	#4,SP
	MOVEa.l	D0,A2
	MOVEa.l	D0,A1
; On recopie l'‚mulateur.
	LEA	(Ehancer_Dump+28.w,PC),A0
	MOVE.l	(Ehancer_Dump+2.w,PC),D0	; taille texte.
	ADD.l	(Ehancer_Dump+6.w,PC),D0	; taille data.
	SUBq.l	#1,D0
	LSR.l	#2,D0
.copy_it
	MOVE.l	(A0)+,(A1)+
	DBF	D0,.copy_it
; On le reloge.
	MOVE.l	A2,D0
	LEA	(Ehancer_Dump+28.w,PC),A0
	ADDa.l	(Ehancer_Dump+2.w,PC),A0	; taille data.
	ADDa.l	(Ehancer_Dump+6.w,PC),A0	; taille data.
	ADDa.l	(Ehancer_Dump+14.w,PC),A0	; taille symboles.
	MOVEa.l	D0,A1
; c'est parti.
	TST.l	(A0)
	Beq.s	.reloc_done
	ADDa.l	(A0)+,A1
	ADD.l	D0,(A1)
	MOVEq	#0,D1
.next_byte
	MOVE.b	(A0)+,D1
	Beq.s	.reloc_done
	CMPi.b	#1,D1
	Beq.s	.great_move
; reloge.
	ADDa	D1,A1
	ADD.l	D0,(A1)
	Bra.s	.next_byte
.great_move
	LEA	(254.w,A1),A1
	Bra.s	.next_byte
.reloc_done
; on lui passe la main.
	MOVE.l	(_prefs.w,PC),-(SP)
	MOVE.l	(_minidesk.w,PC),-(SP)
	MOVE	(maxsize.w,PC),-(SP)
	MOVE	(size.w,PC),-(SP)
	MOVE.l	(_lib.w,PC),-(SP)
	JSR	(A2)
	LEA	(16.w,SP),SP
; on ne doit JAMAIS arriver l… !
	RTS

; Gestion des ROMs en fichiers.
Soft_Roms
; Ouverture du fichier image.
	MOVEm.l	A0-A3/D0-D2,-(SP)
	CLR	-(SP)
	PEA	(ImgName.w,PC)
	MOVE	#$3D,-(SP)
	TRAP	#1
	ADDq	#8,SP

	TST.l	D0
	Bmi	.no_img
	MOVE	D0,D7
; On le lit.
	PEA	(TOS_Dump.w,PC)
	MOVE.l	#512*1024,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	TRAP	#1
	LEA	12(SP),SP
; On le ferme.
	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP
; on le 'recopie en ROM'.
	MOVE	#$2700,SR
	JSR	PMMUVROMON
	LEA	$E80000,A0
	LEA	(TOS_Dump+$80000,PC),A1
.copy_rom
	MOVE.l	-(A1),D0
	CMP.l	-(A0),D0
	Beq.s	.next
	MOVE.l	D0,(A0)
.next
	CMPa.l	#$E00000,A0
	Bne.s	.copy_rom
; maintenant on regarde les modifs n‚cessaires (translations).
; r‚cupŠre le pointeur sur les translations.
	MOVE	$E00002,D0
	MOVE	$FEE00002,D1
	SUBi	#$401,D0
	SUBi	#$401,D1
	MOVE.l	(TTables.w,PC,D0.w*4),A0
	MOVE.l	(TTables.w,PC,D1.w*4),A1
.translate
	TST.l	(A0)
	Beq.s	.installed
	MOVEa.l	(A0)+,A2
	MOVEa.l	(A1)+,A3
	ADDa.l	#$FE000000,A3
	MOVE.l	(A3),D0
; translation de l'adresse.
	CMP.l	(A2),D0
	Beq.s	.translate
	ADDi.l	#$FE000000,D0
	MOVE.l	D0,(A2)
	Bra.s	.translate
.not_404
.installed
	JSR	PMMUVROMOFF
.no_img
	MOVEm.l	(SP)+,D0-D2/A0-A3
	RTS

; Charge le mini bureau.
LoadMiniDesk
	MOVEm.l	A0-A6/D0-D7,-(SP)
	CLR.l	_minidesk
; Ouverture du fichier.
	CLR	-(SP)
	PEA	(MiniName.w,PC)
	MOVE	#$3D,-(SP)
	TRAP	#1
	ADDq	#8,SP

	TST.l	D0
	Bmi	.end
	MOVE	D0,D7
; On le lit.
	PEA	(headBuffer.w,PC)
	MOVE.l	#$1C,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	TRAP	#1
	LEA	(12.w,SP),SP

	MOVE.l	(2+headBuffer.w,PC),D0
	ADD.l	(6+headBuffer.w,PC),D0
	ADD.l	(10+headBuffer.w,PC),D0

	MOVE.l	D0,D5
	MOVE.l	D0,-(SP)
	JSR	PMMURESERVE
	ADDq	#4,SP
; bloc pour charger tout ca.
	MOVE.l	D0,D6
	MOVE.l	D6,-(SP)
	MOVE.l	D5,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	TRAP	#1
	LEA	(12.w,SP),SP
; On le ferme.
	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP
; On le reloge.
	MOVEa.l	D6,A0
	MOVE.l	D6,D0
	ADDa.l	(headBuffer+2.w,PC),A0	; taille data.
	ADDa.l	(headBuffer+6.w,PC),A0	; taille data.
	ADDa.l	(headBuffer+14.w,PC),A0	; taille symboles.
	MOVEa.l	D0,A1
; c'est parti.
	TST.l	(A0)
	Beq.s	.reloc_done
	ADDa.l	(A0)+,A1
	ADD.l	D0,(A1)
	MOVEq	#0,D1
.next_byte
	MOVE.b	(A0)+,D1
	Beq.s	.reloc_done
	CMPi.b	#1,D1
	Beq.s	.great_move
; reloge.
	ADDa	D1,A1
	ADD.l	D0,(A1)
	Bra.s	.next_byte
.great_move
	LEA	(254.w,A1),A1
	Bra.s	.next_byte
.reloc_done
	MOVE.l	D6,_minidesk
.end
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

Init_Pmmu
; Installe la Pmmu.
; en paramŠtre, un pointeur sur une zone qui lui sera r‚serv‚e.
	MOVE	SR,-(SP)
	MOVEm.l	A0-A4/D0,-(SP)
	MOVEa.l	_memtop.w,A0
	SUBa.l	#PAGESZ,A0
	MOVEa.l	A0,A3
	SUBa.l	#PAGESZ,A0
	MOVE.l	A0,_memtop.w
	MOVEa.l	A0,A4
; copie des routines.
	MOVEa.l	A3,A0
	LEA	(PAGE_HANDLING.w,PC),A2
	MOVEa.l	A0,A1
	ADDa.l	#Pmmu_Infos,A1
	SUBa.l	A2,A1
.loop_copy
	MOVE.l	(A2)+,(A0)+
	CMPa.l	#ENDPAGE_HANDLING,A2
	Bcs.s	.loop_copy
; initialisation de la structure.
	MOVEq	#PMMU_STRUCT-1,D0
.clear_loop
	CLR.b	(A0)+
	DBF	D0,.clear_loop
; calcul du d‚but de l'arbre.
	MOVE.l	A0,D0
	ADDq.l	#7,D0
	ADDq.l	#8,D0
	ANDi.b	#$F0,D0
; pr‚paration de la zone de description.
	MOVE.l	D0,(Pmmu_Top.w,A1)
	MOVE.l	D0,(Pmmu_Bottom.w,A1)
	MOVE.l	D0,(Pmmu_LBottom.w,A1)
; fin de la m‚moire libre.
	MOVE.l	_memtop.w,(low_memory.w,A1)
; d‚but de la zone de relocation.
	MOVE.l	#$E80000,(high_memory.w,A1)
	LEA	(Pmmu_Infos.w,PC),A2
	MOVE.l	D0,(Pmmu_Bottom.w,A2)
	MOVE.l	D0,Pmmu_CRP+4
	MOVE.l	D0,-(SP)
	BSR	Init_ALevel
	ADDq	#4,SP
; on protŠge la page.
	MOVE.l	#$E00019,-(SP)
	MOVE.l	D0,-(SP)
	BSR	Translate_Page
	ADDq	#8,SP
; on d‚place notre page.
; translate la page.
	PEA	(A3)
	MOVE.l	#PMMUBASE,-(SP)
	BSR	Translate_Page
	ADDq	#8,SP
; r‚servation d'un espace 'utilisateur'
	PEA	(A4)
	MOVE.l	#FASTROUTS,-(SP)
	BSR	Translate_Page
	ADDq	#8,SP
; en-tˆte.
	MOVE.l	#FASTROUTS+8,(A4)
	MOVE.l	#PAGESZ-8,(4.w,A4)
; on protŠge la page.
	MOVE.l	#$E00019,-(SP)
	PEA	(A4)
	BSR	Translate_Page
	ADDq	#8,SP
; on corrige le d‚but et la fin de l'arbre.
	MOVE.l	(Pmmu_Top.w,A1),D0
	SUB.l	A3,D0
	ADDi.l	#PMMUBASE,D0
	MOVE.l	D0,(Pmmu_Top.w,A1)
	MOVE.l	(Pmmu_Bottom.w,A2),(Pmmu_Bottom.w,A1)
	MOVE.l	(Pmmu_LBottom.w,A2),D0
	SUB.l	A3,D0
	ADDi.l	#PMMUBASE,D0
	MOVE.l	D0,(Pmmu_LBottom.w,A1)
; on pr‚pare la translation.
	PMOVE	CRP,Old_CRP
	PMOVE	TC,Old_TC
	PMOVE	Pmmu_CRP,CRP
	PMOVE	Pmmu_TC,TC
	PMOVE	Pmmu_TT0,TT0
	PMOVE	Pmmu_TT1,TT1
	MOVEm.l	(SP)+,A0-A4/D0
	MOVE	(SP)+,SR
	RTS

; construit le premier niveau.
Init_ALevel
	CARGS	#60,ATree_Add.l
	MOVEm.l	A0-A6/D0-D7,-(SP)
	MOVEa.l	(ATree_Add.w,SP),A0
	LEA	(Pmmu_Infos.w,PC),A6
	MOVE.l	A0,(Pmmu_Top.w,A6)
; g‚n‚ration du niveau.
	MOVE	#APAGENB-1,D1
; les pages sont d‚j… marqu‚es modifi‚es et utilis‚es.
	MOVEq	#$19,D2
.init_level
	MOVE.l	D2,(A0)+
	ADDi.l	#APAGESZ,D2
	MOVE.l	D2,D0
	SWAP	D0
	ANDi	#$F0,D0
	CMPi	#$F0,D0
	Bcs.s	 .not_periph
; zone non cachable.
	ORi.b	#$40,D2
	Bra.s	.go_on
.not_periph
; zone cachable.
	ANDi.b	#$BF,D2
.go_on
	DBF	D1,.init_level
	ADDi.l	#APAGENB*4,(Pmmu_Bottom.w,A6)
	MOVE.l	A0,(Pmmu_LBottom.w,A6)
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

; Gestion des niveaux.
;---------------------
; cette partie doit ˆtre disponible pour l'‚mulateur.
PAGE_HANDLING
	Bra.w	Log2Phys
	Bra.w	Translate_Page
	Bra.w	Reserve
	Bra.w	Activate_VROM
	Bra.w	Stop_VROM
	Bra.w	Copy_Page

; En cas d'accŠs ill‚gal au ROM, translate la page et recommence.
Activate_VROM
	MOVE.l	A1,-(SP)
	LEA	(VRom.w,PC),A1
	MOVE.l	8.w,(-4.w,A1)
	MOVE.l	A1,8.w
	MOVEa.l	(SP)+,A1
	RTS

Stop_VROM
	MOVE.l	(Vold.w,PC),8.w
	RTS

; gestionnaier charg‚ de la gestion de ce cas.
	DC.l	'XBRA'
	DC.l	'VROM'
Vold
	DC.l	0
VRom
	CMPi.b	#$E0,($11.w,SP)	; Bonne addresse ?
	Bcs.s	.not_handled
	CMPi.b	#$E8,(11.w,SP)
	Bcc.s	.not_handled
; il faut translater la page et refaire l'accŠs.
	MOVEm.l	D0/A0-A1,-(SP)
; on v‚rifie l'existence de la page.
	MOVE.l	($1C.w,SP),-(SP)
	BSR	Check_CPage
	ADDq	#4,SP
; on r‚cupŠre son descripteur.
	MOVE.l	($1C.w,SP),-(SP)
	BSR	Convert_LevelC
	ADDq	#4,SP
	MOVE.l	D0,A0
	MOVE.l	(A0),D0
	CLR.b	D0
	MOVE.l	D0,A0
; on copie cette page en RAM.
	BSR.s	Ask_Page
	MOVE.l	D0,A1
; paramŠtre pour la translation
	MOVE.l	A1,-(SP)
	MOVE.l	A0,-(SP)
	MOVE	#(PAGESZ/4)-1,D0
.copy_ROM
	MOVE.l	(A0)+,(A1)+
	DBF	D0,.copy_ROM
	BSR	Translate_Page
	ADDq	#8,SP
	MOVEm.l	(SP)+,D0/A0-A1
; recommencer l'instruction.
	BSET	#0,($A.w,SP)
	RTE
.not_handled
	JMP	([Vold.w,PC])

Ask_Page
; r‚serve une page de m‚moire 'basse'.
	MOVE.l	A0,-(SP)
	LEA	(Pmmu_Infos.w,PC),A0
	SUBi.l	#PAGESZ,(low_memory.w,A0)
	MOVE.l	(low_memory.w,A0),D0
; on fixe le nouveau bas de la m‚moire.
	MOVE.l	D0,_memtop.w
	MOVE.l	D0,phystop.w
	MOVEa.l	(SP)+,A0
	RTS

; R‚serve et rend disponible de la m‚moire 'haute'.
Reserve
	CARGS	#12,RAmount.l
	MOVEm.l	D1-D2/A0,-(SP)
; arrondie la taille … un nombre entier de page.
	MOVE.l	(RAmount.w,SP),D0
	Beq.s	.end
	ADDi.l	#PAGESZ-1,D0
	DIVu	#PAGESZ,D0
; D0 contient le nombre de page … r‚server.
	SUBQ	#1,D0
	MOVE	D0,D2
	LEA	(Pmmu_Infos.w,PC),A0
	MOVE.l	(high_memory.w,A0),D1
.loop
; r‚cupŠre une page.
	BSR.s	Ask_Page
	MOVE.l	D0,-(SP)
	MOVE.l	(high_memory.w,A0),-(SP)
	ADDi.l	#PAGESZ,(high_memory.w,A0)
	BSR.s	Translate_Page
	ADDq	#8,SP
	DBF	D2,.loop
; D1 contient le d‚but de cette m‚moire.
	MOVE.l	D1,D0
.end
	MOVEm.l	(SP)+,D1-D2/A0
	RTS

; Convertion de logique vers physique.
Log2Phys
	CARGS	#8,LogAdd.l
	MOVEm.l	D1/A0,-(SP)
	MOVE.l	(LogAdd.w,SP),D0
	MOVE.l	D0,D1
	MOVE.l	D0,-(SP)
	BSR	Convert_LevelC
	ADDq	#4,SP
	MOVE.l	D0,A0
	MOVE.l	(A0),D0
	CLR.b	D0
	ANDi	#PAGESZ-1,D1
	ADD	D1,D0
	MOVEm.l	(SP)+,D1/A0
	RTS

Translate_Page
; d‚place une page et protŠge l'originale.
	CARGS	#8,TPPhys.l,TPLog.l
	MOVEm.l	D0/A0,-(SP)
; on s'assure de l'existence de la page.
	MOVE.l	(TPPhys.w,SP),-(SP)
	BSR	Check_CPage
	ADDq	#4,SP
; on r‚cupŠre le descripteur.
	MOVE.l	(TPPhys.w,SP),-(SP)
	BSR	Convert_LevelC
	ADDq	#4,SP
; on translate.
	MOVE.l	D0,A0
	MOVE.l	(TPLog.w,SP),D0
	ORi.b	#$19,D0
	MOVE.l	D0,(A0)
; on protŠge la page associ‚e.
; on s'assure de l'existence de la page.
	MOVE.l	(TPLog.w,SP),-(SP)
	BSR	Check_CPage
	ADDq	#4,SP
; on r‚cupŠre le descripteur.
	MOVE.l	(TPLog.w,SP),-(SP)
	BSR	Convert_LevelC
	ADDq	#4,SP
; on translate.
	MOVE.l	D0,A0
	MOVE.l	#$E00019,(A0)
	PFLUSHA
	MOVEm.l	(SP)+,D0/A0
	RTS

Copy_Page
; offre un nouvell accŠs … une page une page.
	MOVEm.l	D0/A0,-(SP)
; on s'assure de l'existence de la page.
	MOVE.l	(TPPhys.w,SP),-(SP)
	BSR	Check_CPage
	ADDq	#4,SP
; on r‚cupŠre le descripteur.
	MOVE.l	(TPPhys.w,SP),-(SP)
	BSR	Convert_LevelC
	ADDq	#4,SP
; on translate.
	MOVE.l	D0,A0
	MOVE.l	(TPLog.w,SP),D0
	ORi.b	#$19,D0
	MOVE.l	D0,(A0)
	PFLUSHA
	MOVEm.l	(SP)+,D0/A0
	RTS


; Retourne un pointeur sur l'entr‚e de niveau A correspondant … l'adresse.
Convert_LevelA
	CARGS	#4,LAAdresse.l
	MOVE.l	A6,-(SP)
	LEA	(Pmmu_Infos.w,PC),A6
	MOVE.l	(LAAdresse.w,SP),D0
; on ignore les premiers bits.
	LSL.l	#ISHIFT,D0
; on amŠne en bas ceux qui nous int‚resse.
; si plus de 8 bits, on fait le d‚cal en deux fois.
	IF	ABITSZ<9
	ROL.l	#ABITSZ,D0
	ELSE
	ROL.l	#8,D0
	ROL.l	#ABITSZ-8,D0
	ENDC
	ANDi.l	#-1>>(32-ABITSZ),D0
	LEA.l	([Pmmu_Top.w,A6],D0.w*4),A6
	MOVE.l	A6,D0
	MOVE.l	(SP)+,A6
	RTS

; Retourne un pointeur sur l'entr‚e de niveau B correspondant … l'adresse.
Convert_LevelB
	CARGS	#8,LBAdresse.l
	MOVEm.l	A1/A6,-(SP)
; on va chercher le niveau A.
	MOVE.l	(LBAdresse.w,SP),-(SP)
	BSR.s	Convert_LevelA
	ADDq	#4,SP
	IF	BBITSZ
	MOVEa.l	D0,A6
	MOVE.l	(A6),D0
	ANDi.b	#3,D0
	CMPi.b	#2,D0
	Bne.s	.no_down
	MOVE.l	(A6),D0
	ANDi.b	#$F0,D0
; on converti en physique !
	LEA	(Pmmu_Infos.w,PC),A1
	SUB.l	(Pmmu_Bottom.w,A1),D0
	ADD.l	(Pmmu_LBottom.w,A1),D0
	MOVE.l	D0,A6
	MOVE.l	(LBAdresse.w,SP),D0
; on ignore les premiers bits.
	LSL.l	#ISHIFT,D0
; on amŠne en bas ceux qui nous int‚resse.
; si plus de 8 bits, on fait le d‚cal en deux fois.
	IF	ABITSZ<9
	LSL.l	#ABITSZ,D0
	ELSE
	LSL.l	#8,D0
	LSL.l	#ABITSZ-8,D0
	ENDC
	ROL.l	#BBITSZ,D0
	ANDi.l	#-1>>(32-BBITSZ),D0
	LEA.l	(A6,D0.w*4),A6
.no_down
	MOVE.l	A6,D0
	ENDC
	MOVEm.l	(SP)+,A1/A6
	RTS

; Retourne un pointeur sur l'entr‚e de niveau C correspondant … l'adresse.
Convert_LevelC
	CARGS	#8,LCAdresse.l
	MOVEm.l	A1/A6,-(SP)
; on va chercher le niveau B.
	MOVE.l	(LCAdresse.w,SP),-(SP)
	BSR.s	Convert_LevelB
	ADDq	#4,SP
; Conditionnel suivant l'existence d'un niveau C.
	IF	CBITSZ
	MOVEa.l	D0,A6
	MOVE.l	(A6),D0
	ANDi.b	#3,D0
	CMPi.b	#2,D0
	Bne.s	.no_down
	MOVE.l	(A6),D0
	ANDi.b	#$F0,D0
; on converti en physique !
	LEA	(Pmmu_Infos.w,PC),A1
	SUB.l	(Pmmu_Bottom.w,A1),D0
	ADD.l	(Pmmu_LBottom.w,A1),D0
	MOVE.l	D0,A6
	MOVE.l	(LCAdresse.w,SP),D0
; on ignore les premiers bits.
	LSL.l	#ISHIFT,D0
; on amŠne en bas ceux qui nous int‚resse.
	ROL.l	#ABITSZ,D0
	ROL.l	#BBITSZ,D0
	ROL.l	#CBITSZ,D0
	ANDi.l	#-1>>(32-CBITSZ),D0
	LEA.l	(A6,D0.w*4),A6
.no_down
	MOVE.l	A6,D0
	ENDIF	; CBITSZ
	MOVEm.l	(SP)+,A1/A6
	RTS

; s'assure qu'une page est disponible dans l'arbre.
; en paramŠtre l'adresse.
Check_BPage
	CARGS	#24,CBAdresse.l
	MOVEm.l	A4-A6/D0-D2,-(SP)
; on v‚rifie qu'il y a une sous-table.
	MOVE.l	(CBAdresse.l),-(SP)
	BSR	Convert_LevelA
	ADDq	#4,SP
	IF	BBITSZ
	MOVE.l	D0,A5
	MOVE.l	(A5),D0
	ANDi.b	#3,D0
	CMPi.b	#2,D0
	Beq.s	.ok
; l'entr‚e ne d‚signe pas une sous-table, il faut en faire une.
	LEA	(Pmmu_Infos.w,PC),A6
; il faut g‚n‚rer un niveau.
	MOVE.l	(Pmmu_LBottom.w,A6),D0
; arrondi.
	ADDq	#7,D0
	ADDq	#8,D0
	ANDi.b	#$F0,D0
	MOVE.l	D0,A4
; pointeur sur la page courante.
	MOVE.l	(Pmmu_Bottom.w,A6),D0
	ADDq	#7,D0
	ADDq	#8,D0
	ANDi.b	#$F0,D0
	ORi.b	#2,D0
; on r‚cupŠre l'adresse logique.
	MOVE.l	(A5),D2
; on fixe l'adresse du niveau.
	MOVE.l	D0,(A5)
; g‚n‚ration du niveau.
	MOVEq	#BPAGENB-1,D1
.init_level
	MOVE.l	D2,(A4)+
	ADDi.l	#BPAGESZ,D2
	DBF	D1,.init_level
	ADDi.l	#4*BPAGENB,(Pmmu_Bottom.w,A6)
	MOVE.l	A4,(Pmmu_LBottom.w,A6)
.ok
	ENDC
	MOVEm.l	(SP)+,A4-A6/D0-D2
	RTS

; s'assure qu'une page est disponible dans l'arbre.
; en paramŠtre l'adresse.
Check_CPage
	CARGS	#24,CCAdresse.l
	MOVEm.l	A4-A6/D0-D2,-(SP)
; on s'assure de la coh‚rence des niveaux sup‚rieurs.
	MOVE.l	(CCAdresse.l),-(SP)
	BSR.s	Check_BPage
	ADDq	#4,SP
; li‚ … l'existence d'un niveau C.
	IF	CBITSZ
; on v‚rifie qu'il y a une sous-table.
	MOVE.l	(CCAdresse.l),-(SP)
	BSR	Convert_LevelB
	ADDq	#4,SP
	MOVE.l	D0,A5
	MOVE.l	(A5),D0
	ANDi.b	#3,D0
	CMPi.b	#2,D0
	Beq.s	.ok
; l'entr‚e ne d‚signe pas une sous-table, il faut en faire une.
	LEA	(Pmmu_Infos.w,PC),A6
; il faut g‚n‚rer un niveau.
	MOVE.l	(Pmmu_LBottom.w,A6),D0
; arrondi
	ADDq	#7,D0
	ADDq	#8,D0
	ANDi.b	#$F0,D0
	MOVE.l	D0,A4
; pointeur sur la page courante.
	MOVE.l	(Pmmu_Bottom.w,A6),D0
	ADDq	#7,D0
	ADDq	#8,D0
	ANDi.b	#$F0,D0
	ORi.b	#2,D0
; on r‚cupŠre l'adresse logique.
	MOVE.l	(A5),D2
; on fixe l'adresse du niveau.
	MOVE.l	D0,(A5)
; g‚n‚ration du niveau.
	MOVEq	#CPAGENB-1,D1
.init_level
	MOVE.l	D2,(A4)+
	ADDi.l	#CPAGESZ,D2
	DBF	D1,.init_level
	ADDi.l	#4*CPAGENB,(Pmmu_Bottom.w,A6)
	MOVE.l	A4,(Pmmu_LBottom.w,A6)
.ok
	ENDIF	; CBITSZ
	MOVEm.l	(SP)+,A4-A6/D0-D2
	RTS

; structure de gestion de la PMMU
	RSRESET
Pmmu_Top	RS.l	1	; d‚but de l'arbre.
Pmmu_Bottom	RS.l	1	; fin de l'arbre.
Pmmu_LBottom	RS.l	1	; fin de l'arbre (adresse logique).
high_memory	RS.l	1	; pointeur sur la zone de relocation logique.
low_memory	RS.l	1	; pointeur sur la fin de la m‚moire libre (physique).
PMMU_STRUCT	RS	0

ENDPAGE_HANDLING
; Structure pour les tests.
Pmmu_Infos	DS.b	PMMU_STRUCT

	SECTION	DATA
;________________________
;[ Donn‚es pour la PMMU ]
;[______________________]

; Registres:
;	TC, Translation Control.
;		Configuration standart.
Pmmu_TC		DC.l	TCVALUE
;		Arrˆt de la Pmmu.
No_Pmmu		DC.l	0

;	CRP, Control Root Pointer.
Pmmu_CRP	DC.l	$7FFF0002	; Table de descripteurs courts.
		DC.l	0		; Adresse de l'arbre.

; 	TTx, registres de translations transparentes.
Pmmu_TT0	DC.l	$FE008507
Pmmu_TT1	DC.l	$00000000

; tableau de pointeurs sur les chaŒnes.
TTables		DC.l	tTOS_401,tTOS_402,0,tTOS_404

; chaines de translations pour les softs ROMs.
;	liste des pointeurs: logo, font 6x6, 8x8, 8x16 (bis), bombes.
tTOS_401	DC.l	$E4799C,$E49198,$E49874,$E093F2,$E4B2D0,$E0129E,0
tTOS_402	DC.l	$E497DC,$E4AFD8,$E4B6B4,$E093FC,$E4D110,$E0129E,0
tTOS_404	DC.l	$E4983C,$E4B038,$E4B714,$E0945C,$E4D170,$E012DC,0

; ChaŒnes
;--------
ExeName	DC.b	'BCKWTSR.EXE',0
ImgName	DC.b	'ROM.IMG',0
LibName	Dc.b	'BACKWARD.DKS',0
PrefName	Dc.b	'BACKWARD.INF',0
INSTEXT	DC.b	27,'pBackward III Loader.    ',27,'q',10,13
	DC.b	'V 1.0 by Cyrille Dupuydauby',10,13,0

NO_EXE	DC.b	"Can't find BACKWARD.EXE!",10,13,0

UPDATE	DC.b	27,'pBackward III Loader.    ',27,'q',10,13
	DC.b	'Updating Set-Up Library.',13,10,0

MiniName
	DC.b	'MINIDESK.PRG'

	SECTION	BSS

; infos sur la bib
_lib		Ds.l	1
size		Ds	1
maxsize		Ds	1
_rlib_size	Ds.l	1

; pointeur sur les pr‚f‚rences.
_prefs		Ds.l	1

; Taille m‚moire disponible pour les diff‚rentes relocations.
Available_Memory
		DS.l	1

; pointeur sur le premier octet occup‚.
Memory_Top	DS.l	1

; Zone m‚moire de la relocation.
Reloc_Zone	DS.l	1

; Nombre de pages libres.
Free_Pages	DS	1

; Taille de l'‚mulateur.
Ehancer_Size	DS.l	1

programsize	DS.l	1

; Ancienne valeur pour Pmmu.
Old_CRP		DS.l	2
Old_TC		DS.l	1

; pointeur sur le d‚but de Minidesk.
_minidesk	DS.l	1

; Pile
	DS.l	256
myStack

; pr‚f‚rences.
Prefs	Ds.b	SIZEPREF

; Zone m‚moire pour stocker l'‚mulateur.
Ehancer_Dump
	DS.b	16384

; Buffer pour l'en tˆte des programmes.
headBuffer
	DS.b	28

; Zone m‚moire pour l'image du TOS.
TOS_Dump
	DS.b	512*1024
