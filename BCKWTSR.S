;________________________________________________________________
;I								I
;I		Backward III, moteur d'‚mulation		I
;I				V 1.00				I
;I		    ½ 1993-95 Cyrille Dupuydauby.		I
;I______________________________________________________________I
;INotes:							I
;I 14 05 94 : D‚but du recodage.				I
;I 17 08 94 : D‚but des tests (premiŠres fonctionnalit‚s	I
;I               impl‚ment‚es).					I
;I 21 08 94 : PremiŠre version (incomplŠte) stable.		I
;I 05 03 95 : Gestion de la bibliothŠque.			I
;I 12/03/95 : - Nouvelle m‚thode corrig‚e, plus rapide.		I
;I              Utilise la page d'appels rapides.		I
;I______________________________________________________________I

	OUTPUT	.EXE

; Place en pile r‚serv‚e.
;------------------------
STACK_ROOM	=	512

VERNUM=$100	; Version.
; Options d'assemblage
	OPT	OW+,W+,O+,V

; inclusions
	INCDIR	D:\ASM\LIB

	INCLUDE	SYSTEM.SYM
	INCLUDE	ERROR.SYM
	INCLUDE	PMMUCALL.SYM
	INCLUDE	CONFIG.SYM

CHECKREGISTER	MACRO
; en sortie D0 vaut 0 si non enregistr‚e.
	MOVEm.l	A0-A1/D1-D2,-(SP)
	LEA	(UName.w,A6),A0
	LEA	(UKey.w,A6),A1
	MOVEq	#0,D0
	MOVE.l	(A0)+,D1
	EOR.l	D1,D0
	MOVE.l	(A0)+,D1
	EOR.l	D1,D0
	MOVE.l	(A0)+,D1
	EOR.l	D1,D0
	MOVE.l	(A0)+,D1
	EOR.l	D1,D0
	MOVE.l	(A0)+,D1
	EOR.l	D1,D0
	MOVE.l	(A0)+,D1
	EOR.l	D1,D0
	MOVE.l	(A0)+,D1
	EOR.l	D1,D0
	MOVE.l	(A0)+,D1
	EOR.l	D1,D0
	EOR.l	#KEY,D0			; cl‚ calcul‚e.
	CLR.l	D2
	MOVE.b	(A1)+,D1
	ANDi	#$F,D1
	OR.b	D1,D2
	LSL.l	#4,D2
	MOVE.b	(A1)+,D1
	ANDi	#$F,D1
	OR.b	D1,D2
	LSL.l	#4,D2
	MOVE.b	(A1)+,D1
	ANDi	#$F,D1
	OR.b	D1,D2
	LSL.l	#4,D2
	MOVE.b	(A1)+,D1
	ANDi	#$F,D1
	OR.b	D1,D2
	LSL.l	#4,D2
	MOVE.b	(A1)+,D1
	ANDi	#$F,D1
	OR.b	D1,D2
	LSL.l	#4,D2
	MOVE.b	(A1)+,D1
	ANDi	#$F,D1
	OR.b	D1,D2
	LSL.l	#4,D2
	MOVE.b	(A1)+,D1
	ANDi	#$F,D1
	OR.b	D1,D2
	LSL.l	#4,D2
	MOVE.b	(A1)+,D1
	ANDi	#$F,D1
	OR.b	D1,D2
	CMP.l	D0,D2
	Seq	D0
	CMP.l	#KEY,D2
	Sne	D1
	AND	D1,D0
	MOVEm.l	(SP)+,A0-A1/D1-D2
	ENDM

	SECTION	TEXT

; Pr‚parations pour l'installation.
	CARGS	_Lib.l,LibSize.w,MaxSize.w,_Shell.l,_Prefs.l
	Sf	fRegister
; r‚cup‚ration des pr‚f‚rences.
	TST.l	(_Prefs.w,SP)
	Beq.s	.no_prefs
	MOVE.l	(_Prefs.w,SP),-(SP)
	Bsr	Set_Prefs
	ADDq	#4,SP
.no_prefs
	MOVE.l	(_Lib.w,SP),curConfig+_library
	MOVE	(LibSize.w,SP),curConfig+_lib_size
	MOVE	(MaxSize.w,SP),curConfig+_lib_max
	MOVE.l	(_Shell.w,SP),curConfig+_shell
; on est en mode BOOT.
	Bsr.s	BootPatches
; il est indispensable de toucher les pages de ROM qu'on veut modifier.
	Bsr.s	TouchROM
; initialisations diverses … faire au chargement.
	Bsr	GeneralInit
; ‚mulation des anciennes ROMS.
	PEA	$E00000
	Jsr	PMMULOG2PHYS
	ADDq	#4,SP
	MOVE.l	D0,-(SP)
	PEA	$FC0000
	Jsr	PMMUCOPY
	ADDq	#8,SP
; Reboot
	JMP	$E00000

; routine charg‚e de faire les modifs globales des ROMs..
TouchROM
	MOVE.l	D0,-(SP)
	MOVE.l	#$3111,-(SP)
	Bsr	setCaches
	ADDq	#4,SP
	Bsr	PatchRoms
	MOVE.l	(SP)+,D0
	RTS

BootPatches
; corrige les roms pour le boot.
; modifs communes.
	JSR	PMMUVROMON
	MOVE	#$4E71,$E00038		; plus de RESET.
	move	#$4E71,$E000A4		; pas de test memval pour RESET.
	MOVE.l	#$42780446,$E0006A	; clr _bootdev
	MOVE.l	#$4EF900E0,$E0006E	;
	MOVE.l	#$00744E71,$E00072	; pas de RESET MMU.
	MOVE.l	#$4E714E71,$E00076	;
	MOVE.l	#$4E714E71,$E0007A	;
	MOVE.l	#$4E714E71,$E0007E	;

	MOVE.l	#$4E714E71,$E002BC	; pas d'init PMMU.
; D‚tournement du boot floopy
	MOVE.l	$E0032C,ContBoot	; Sauvegarde de l'ancien vecteur.
	MOVE.l	#StartUp,$E0032C	; Routine de boot.

	MOVE.b	#$60,$E00136		; pas de test de memval3.
	CLR.l	memval3.w

; patchs sp‚cifiques.
	CMPi	#$401,$E00002		; 4.01 ?
	Beq.s	.401patches
	CMPi	#$402,$E00002		; 4.02 ?
	Bne.s	.not401_2
.401patches
	MOVE	#$4E71,$E006D4		; pas de CRC des ROMs.
	Bra.s	.no_rom_copie
.not401_2
	CMPi	#$404,$E00002		; 4.04 ?
	Bne.s	.no_rom_copie
	MOVE	#$4E71,$E006DE		; pas de CRC des ROMs.
.no_rom_copie
; on ne peut rien faire !	
	JSR	PMMUVROMOFF
	RTS

PatchRoms
; modif pour rect_fl.
	JSR	PMMUVROMON
	CMPi.w	#$401,$E00002		; TOS 4.01 ?
	Bne.s	.not_TOS401
; patch pour v_rectfl
	MOVE	#$50C0,$E128B4
; patch pour vsf_updat
	MOVE.l	#$4E714E71,$E0D06C
	MOVE	#$6610,$E0D048
	MOVE	#$4E71,$E0D062
	Bra.s	.end
.not_TOS401
	CMPi.w	#$402,$E00002		; TOS 4.02 ?
	Bne.s	.not_TOS402
; patch pour v_rectfl
	MOVE	#$50C0,$E12902
; mode non 3D
;	CLR	$E2B428
	Bra.s	.end
.not_TOS402
	CMPi.w	#$404,$E00002		; TOS 4.02 ?
	Bne.s	.not_TOS404
; patch pour v_rectfl
	MOVE	#$50C0,$E12962
.not_TOS404
.end
	BSR	Install_AES_Patch
	JSR	PMMUVROMOFF
	RTS

Install_Backward
; Installation faites … chaque red‚marrage.
	MOVEm.l	A0-A2/D0-D2,-(SP)
; mise … z‚ro des variables.
	Sf	finEsc
	Sf	fInk
	Sf	fPaper
	Sf	STmode
	CLR	BackKey
	CLR	WaitCount
; diverses init
	MOVE.l	#Internal_Stack,_Stack
	DC	$A000		; LineA Init
	MOVE.l	D0,_Line_A
; Installation des vecteurs.
	Bsr	Install_Exceptions
; Installation des gestionnaires divers.
	Bsr	Install_Standard_Handlers
; installation du cookie indiquant la pr‚sence de Backward.
	MOVE.l	#'BCKW',D0
	MOVE.l	#curConfig,D1
	Bsr	Create_Cookie
; fixe certaines variables
	LEA	(curConfig.w,PC),A0
	MOVE	#VERNUM,(Version.w,A0)
	MOVE.l	#Set_Up,(_Config_.w,A0)
	MOVE.l	#Set_Prefs,(_Set_Prefs.w,A0)
; installation du cookie PMMU.
	MOVE.l	#'PMMU',D0
	MOVE.l	#curConfig,D1
	Bsr	Create_Cookie
	MOVEm.l	(SP)+,A0-A2/D0-D2
	RTS

Set_Up
; r‚glages de la configuration
	MOVEm.l	A0-A6/D0-D7,-(SP)
; Installe les patchs systŠmes.
	Bsr	PatchTOS
	LEA	(curConfig.w,PC),A2
	TST.b	(pTOS.w,A2)
	Sne	fSystemPatch
	MOVE.b	(pBusMode.w,A2),D0
	EXT	D0
; Mode correction.
	MOVE	D0,-(SP)
	Bsr	Install_Bus_Mode
	ADDq	#2,SP

; valeurs des caches.
	MOVE.l	(pCache.w,A2),-(SP)
	Bsr	setCaches
	ADDq	#4,SP

; Horloge.
	MOVE.b	(pClock.w,A2),D0
	EXT	D0
	MOVE	D0,-(SP)
	Bsr	Set_Clock
	ADDq	#2,SP

; Haut Parleur.
	MOVE.b	(pSpeaker.w,A2),D0
	EXT	D0
	MOVE	D0,-(SP)
	Bsr	Set_HP
	ADDq	#2,SP

; correction de la matrice
; 8 bit stereo.
	CLR	-(SP)
	MOVE	#$84,-(SP)
	TRAP	#14
	ADDq	#4,SP

; Devconnect pour le DMA.
	MOVE	#1,-(SP)
	CLR.l	-(SP)
	MOVE	#8,-(SP)
	CLR	-(SP)
	MOVE	#$8B,-(SP)
	TRAP	#14
	ADDa	#12,SP
	
; prescale 50Khz.
	MOVE	#3,-(SP)
	MOVE	#6,-(SP)
	MOVE	#$82,-(SP)
	TRAP	#14
	ADDq	#6,SP

; entr‚e ADC : PSG.
	MOVE	#3,-(SP)
	MOVE	#5,-(SP)
	MOVE	#$82,-(SP)
	TRAP	#14
	ADDq	#6,SP

; entr‚e ADDER: PSG+Matrice.
	MOVE	#3,-(SP)
	MOVE	#4,-(SP)
	MOVE	#$82,-(SP)
	TRAP	#14
	ADDq	#6,SP

; interruption Timer A
	CLR	-(SP)
	MOVE	#3,-(SP)
	MOVE	#$87,-(SP)
	TRAP	#14
	ADDq	#6,SP
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

;___________________
;[ Initialisations ]
;[_________________]
; Init … faire … l'installation.
GeneralInit
	MOVE.l	_memtop.w,trueMemtop
	RTS

;___________________________
;[ Configurations diverses ]
;[_________________________]
; installation des vecteurs systŠmes.
PatchTOS
; Patchs Line A.
	PEA	(LineA_Patch.w,PC)
	MOVE	#$A,-(SP)
	Bsr	Install_Patch
	ADDq	#6,SP
; Patchs GemDOS.
	PEA	(Gemdos_Patch.w,PC)
	MOVE	#$21,-(SP)
	Bsr	Install_Patch
	ADDq	#6,SP
; Patchs BIOS.
	PEA	(BIOS_Patch.w,PC)
	MOVE	#$2D,-(SP)
	Bsr	Install_Patch
	ADDq	#6,SP
; Patchs XBIOS.
	PEA	(XBIOS_Patch.w,PC)
	MOVE	#$2E,-(SP)
	Bsr	Install_Patch
	ADDq	#6,SP
; VBL
	PEA	(VBL_Patch.w,PC)
	MOVE	#$1C,-(SP)
	Bsr	Install_Patch
	ADDq	#6,SP
; TimerC
	PEA	(TimerC_Patch.w,PC)
	MOVE	#$45,-(SP)
	Bsr	Install_Patch
	ADDq	#6,SP
	RTS

; configuration des caches.
setCaches
	CARGS	#4,CValue.l
	MOVE.l	D0,-(SP)
	JSR	PMMUVROMON
	MOVE.l	(CValue.w,SP),D0
	MOVE.l	D0,CacheControl		; sauvegarde.
	ORi.l	#$0808,D0		; on rajoute la purge des caches.
	CMPi.w	#$401,$E00002		; TOS 4.01 ?
	Bne.s	.not_401
	MOVE.l	D0,$E23A44
	MOVE.l	D0,$E426A6
	Bra.s	.no_rom_copie
.not_401	
	CMPi.w	#$402,$E00002		; TOS 4.02 ?
	Bne.s	.not_402
	MOVE.l	D0,$E2530C
	MOVE.l	D0,$E444E6
	Bra.s	.no_rom_copie
.not_402
	CMPi.w	#$404,$E00002		; TOS 4.04 ?
	Bne.s	.no_rom_copie
	MOVE.l	D0,$E2536C
	MOVE.l	D0,$E44546
.no_rom_copie
; on ne peut pas patcher les ROMs.
; on se contente de modifier les caches.
	MOVEc.l	D0,CACR
	JSR	PMMUVROMOFF
	MOVE.l	(SP)+,D0
	RTS

; Remet la configuration par d‚faut.
Restore_Default
	MOVEm.l	A0-A1/D0,-(SP)
	MOVEq	#SETUP_SIZE-1,D0
	LEA	(defConfig+__SETUP.w,PC),A0
	LEA	(curConfig+__SETUP.w,PC),A1
.copy_setup
	MOVE.b	(A0)+,(A1)+
	DBF	D0,.copy_setup
	St	curConfig+pHD
	St	curConfig+pGEM
	MOVEm.l	(SP)+,A0-A1/D0
	RTS

; Utilise la config minimale.
Disable_Backward
	MOVEm.l	A0-A1/D0,-(SP)
	MOVEq	#SETUP_SIZE-1,D0
	LEA	(nulConfig+__SETUP.w,PC),A0
	LEA	(curConfig+__SETUP.w,PC),A1
.copy_setup
	MOVE.b	(A0)+,(A1)+
	DBF	D0,.copy_setup
	MOVEm.l	(SP)+,A0-A1/D0
	RTS

	DC.l	'XBRA'
	DC.l	'#STU'
; Adresse du retour aprŠs le boot.
ContBoot	DC.l	0

StartUp
; Code ‚x‚cut‚ au boot.
; il est appel‚ lors du boot disquette.
; effectue un boot floppy tout de suite.
; texte affich‚ au d‚marrage.
	MOVEm.l	A0-A6/D0-D7,-(SP)
	PEA	(Welcome.w,PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP
	TST.b	fRegister
	Bne.s	.registered
; message si non enregistr‚
	PEA	(Shareware.w,PC)
	MOVE	#$9,-(SP)
	TRAP	#1
	ADDq	#6,SP
	Bra.s	.go_on
.registered
	PEA	(Registered.w,PC)
	MOVE	#$9,-(SP)
	TRAP	#1
	ADDq	#6,SP
	PEA	(UserName.w,PC)
	MOVE	#$9,-(SP)
	TRAP	#1
	ADDq	#6,SP
	PEA	(NL.w,PC)
	MOVE	#$9,-(SP)
	TRAP	#1
	ADDq	#6,SP		
.go_on
	MOVEm.l	(SP)+,A0-A6/D0-D7
	JSR	([ContBoot.w,PC])
; boot sur A si pas de disque dur.
; au retour D0=
;	-0 disk bootable.
;	-1 pas de lecteur.
;	-2 pas de disk.
;	-4 secteur non bootable
	MOVE	D0,fbResult
; init par d‚faut.
	MOVE	#1,recResult
	Bsr	Restore_Default
	MOVEm.l	A0-A2/D0-D7,-(SP)
; test si shift.
; pour d‚sactivation.
	MOVE	#-1,-(SP)
	MOVE	#$B,-(SP)
	TRAP	#13
	ADDq	#4,SP
	ANDi	#$3,D0
	Beq.s	.not_shifted
; demander.
	PEA	(Disable_Text.w,PC)
	MOVE	#$9,-(SP)
	TRAP	#1
	ADDq	#6,SP
	MOVE	#7,-(SP)
	TRAP	#1
	ADDq	#2,SP
	CMPi.b	#'Y',D0
	Beq.s	.disable
	CMPi.b	#'y',D0
	Bne.s	.not_shifted
; d‚sactiver.
.disable
; installe la conf mini.
	Bsr	Disable_Backward
	Bra.s	.disabled
.not_shifted
; test sur la disquette.
	CMPi	#4,fbResult
	Beq.s	.disk_present
	TST	fbResult
	Bne.s	.no_floppy
.disk_present
; si non enregistr‚e, message bloquant.
	TST.b	fRegister
	Bne.s	.no_wait_key
	PEA	(Wait_Text.w,PC)
	MOVE	#$9,-(SP)
	TRAP	#1
	ADDq	#6,SP
	MOVE	#7,-(SP)
	TRAP	#1
	ADDq	#2,SP
.no_wait_key
; on a une disquette=> tentative de recon.
	Bsr	Recon_Disk
	MOVE	D0,recResult
.no_floppy
.disabled
	TST.b	curConfig+pHD
	Bne.s	.with_HD
; Saute le boot HD.
	ADDq.l	#4,4+44(SP)
.with_HD
; Init pour la zone de patch.
	MOVE.l	#FASTROUTS+8,FASTROUTS.w
	MOVE.l	#8184,FASTROUTS+4.w
; r‚init les pr‚f‚rences.
	Bsr	Do_Prefs
; R‚init de la m‚moire.
	Bsr.s	Install_Memory
; Initialisation
	Bsr	Install_Backward
; R‚glages
	Bsr	Set_Up
; mode video au boot (ST).
	MOVE.b	(curConfig+pVideo.w,PC),D0
	EXT	D0
	MOVE	D0,-(SP)
	Bsr	BootVideo
	ADDq	#2,SP
	TST	recResult
	Bne.s	.no_disk
; affiche le d‚but.
	PEA	(Found_Text.w,PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP

	PEA	(pathBuffer.w,PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP

	PEA	(NL.w,PC)
	MOVE	#9,-(SP)
	TRAP	#1
	ADDq	#6,SP

.no_disk
	MOVEm.l	(SP)+,A0-A2/D0-D7
	MOVE	fbResult,D0
	RTS

;__________________________________
;[         Gestion m‚moire.       ]
;[________________________________]
Install_Memory
	MOVEm.l	A0-A6/D0-D7,-(SP)
	TST.b	curConfig+memSize
	Bne.s	.not_512
	MOVE.l	#$80000,_memtop.w
	MOVE.b	#4,memctrl.w
	Bra.s	.memset
.not_512
	CMPi.b	#1,curConfig+memSize
	Bne.s	.not_1024
	MOVE.l	#$100000,_memtop.w
	MOVE.b	#5,memctrl.w
	Bra.s	.memset
.not_1024
	CMPi.b	#2,curConfig+memSize
	Bne.s	.not_2048
	MOVE.l	#$200000,_memtop.w
	MOVE.b	#8,memctrl.w
	Bra.s	.memset
.not_2048
	MOVE.l	(trueMemtop.w,PC),_memtop.w
.memset
; v‚rifie que'on a assez de m‚moire.
	MOVE.l	(trueMemtop.w,PC),D0
	CMP.l	_memtop.w,D0
	Bcc.s	.enought_mem
; pas assez de m‚more.
	MOVE.l	D0,_memtop.w
.enought_mem
	MOVE.b	memctrl.w,$FFFF8001.w
	MOVE.l	_memtop.w,phystop.w
; init mem.
; libŠre le bloc video.
	TST.b	(curConfig+pGEM.w,PC)
	Bne.s	.with_gem
	MOVE.l	(curConfig+_shell.w,PC),exec_os.w
	MOVE.l	$E0000C,end_os.w
	MOVE.l	$E0000C,_membot.w
.with_gem
	CLR.l	$56AA.w
	CLR.l	$56AE.w
	CMPi	#$401,$E00002
	Bne.s	.not_401
	JSR	$E1B4E4
	Bra.s	.end_init
.not_401
	CMPi	#$402,$E00002
	Bne.s	.not_402
	JSR	$E1C538
	Bra.s	.end_init
.not_402
	CMPi	#$404,$E00002
	Bne.s	.not_404
	JSR	$E1C598
.not_404
.end_init
; r‚init la mem vid‚o.
; r‚cup du mode.
	MOVE	#-1,-(SP)
	MOVE	#$58,-(SP)
	TRAP	#14
	ADDq	#4,SP
; taille m‚moire n‚cessaire.
	MOVE	D0,-(SP)
	MOVE	#$5B,-(SP)
	TRAP	#14
	ADDq	#4,SP
; nouvelle alloc.
	MOVE.l	D0,-(SP)
	MOVE	#$15,-(SP)
	TRAP	#1
	ADDq	#6,SP
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

;____________________________________
;[         Gestion du mode Video    ]
;[__________________________________]
BootVideo
; change le mode video au BOOT.
; paramŠtre, mode video ST, <0 rien.
	MOVEm.l	A0-A2/D0-D2,-(SP)
	CARGS	#24,VMODE.w
	MOVE	(VMODE.w,SP),D0
	Bmi.s	.no_change 
	MOVE	D0,-(SP)
; R‚installation de l'‚cran.
	MOVE.l	#$7D00,-(SP)
	MOVE	#$15,-(SP)
	TRAP	#1
	ADDq	#6,SP
; Passage en mode ST basse.
	MOVE.l	D0,-(SP)
	MOVE.l	D0,-(SP)
	MOVE	#5,-(SP)
	TRAP	#14
	LEA	(12.w,SP),SP
.no_change
	MOVEm.l	(SP)+,A0-A2/D0-D2
	RTS
;____________________________________
;[             Gestion du HP.       ]
;[__________________________________]
Set_HP
	MOVE	D0,-(SP)
	CARGS	#2,FHP.w
	TST	(FHP.w,SP)
	Bne.s	.with_hp
	MOVE.b	#$E,$FFFF8800.w
	MOVE.b	$FFFF8800.w,D0
	ANDi.b	#$BF,D0
	MOVE.b	D0,$FFFF8802.w
	Bra.s	.end
.with_hp
	MOVE.b	#$E,$FFFF8800.w
	MOVE.b	$FFFF8800.w,D0
	ORi.b	#$40,D0
	MOVE.b	D0,$FFFF8802.w
.end
	MOVE	(SP)+,D0
	RTS

;____________________________________
;[ R‚glage de la fr‚quence du 68030 ]
;[__________________________________]
Set_Clock
; en paramŠtre : - 0 8Mhz.
;		 - 1 16Mhz.
	CARGS	CSPEED.w
	TST	(CSPEED.w,SP)
	Bne.s	.not_8
	ANDi	#$FFFE,$FFFF8006.w
	Bra.s	.end
.not_8
	ORi	#1,$FFFF8006.w
.end
	RTS

;______________________________
;[ Gestionnaires d'exceptions ]
;[____________________________]
Install_Exceptions
; pr‚pare tout pour la table d'exception.
	MOVEm.l	A0-A1/D0,-(SP)
	LEA	(Exc_Table+3.w,PC),A0
	MOVE.l	A0,D0
	ANDi.l	#$FFFFFFFC,D0
	LEA	(_Exc_Table.w,PC),A0
	MOVE.l	D0,(A0)			; adresse de la table (arrondi au long).
	MOVEa.l	D0,A0
	LEA	(Exceptions_Handlers.w,PC),A1
	MOVEq	#NB_EXC-1,D0
.fill_table
; on rempli la table.
	MOVE.l	A1,(A0)+
	ADDq	#6,A1
	DBF	D0,.fill_table
; on change le VBR.
	MOVE.l	(_Exc_Table.w,PC),A0
	MOVEc	A0,VBR
	MOVEm.l	(SP)+,A0-A1/D0
	RTS

; Gestionnaires par d‚faut.
ADDRESS	SET	0
Exceptions_Handlers
	REPT	NB_EXC
	JMP	([(ADDRESS).w])
ADDRESS	SET	ADDRESS+4
	ENDR


; Installe les diff‚rents gestionnaire par d‚faut.
;-------------------------------------------------
Install_Standard_Handlers
	MOVEm.l	A0-A2/D0-D2,-(SP)
; Installe la gestion des erreurs BUS.
	PEA	(Ym_Correction.w,PC)
	MOVE	#2,-(SP)
	BSR	Install_Handler
	ADDq	#6,SP
; Installe la gestion des erreurs de privilŠge.
	PEA	(Privilege_Handler.w,PC)
	MOVE	#8,-(SP)
	BSR	Install_Handler
	ADDq	#6,SP
; Installe la gestion de la LineA (macros).
	PEA	(LineA_Handler.w,PC)
	MOVE	#$A,-(SP)
	BSR	Install_Handler
	ADDq	#6,SP
; Installe la gestion de la VBL.
	PEA	(VBL_Handler.w,PC)
	MOVE	#$1C,-(SP)
	BSR	Install_Handler
	ADDq	#6,SP
; Installe la gestion du clavier.
	PEA	(Kbd_Handler.w,PC)
	MOVE	#$46,-(SP)
	BSR	Install_Handler
	ADDq	#6,SP
	MOVEm.l	(SP)+,A0-A2/D0-D2
	RTS

Install_Bus_Mode
; Installe la correction des erreurs BUS.
; un mot de mode :	0 - mode correction.
;			1 - mode ST.
;			2 - mode correction du code.
	MOVEm.l	D0,-(SP)
	CARGS	#4,BMODE.w
; on d‚sinstalle les vecteurs qu'on aurait pu installer.
; vecteur BUS.
	PEA	(Bus_Correcting.w,PC)
	MOVE	#2,-(SP)
	BSR	Remove_Handler
	ADDq	#6,SP

	TST	(BMODE.w,SP)
	Beq.s	.end		; mode correction ?
	CMPi	#1,(BMODE.w,SP)	; mode ST.
	Bne.s	.not_ST
; bus mode ST.
	MOVE	$FFFF8006.w,D0
	ANDi	#$FFDF,D0
	MOVE	D0,$FFFF8006.w
	Bra.s	.end
.not_ST
	CMPi	#2,(BMODE.w,SP)	; mode correction du code.
	Bne.s	.end
	BSR	Install_Bus_Correcting
.end
	MOVEm.l	(SP)+,D0
	RTS

; Macros de contexte.
;--------------------

; structure du contexte.
	RSRESET
; derniers champs oblig.
creg	RS	0
cD0	RS.l	1	; registres du contexte appelant.
cD1	RS.l	1
cD2	RS.l	1
cD3	RS.l	1
cD4	RS.l	1
cD5	RS.l	1
cD6	RS.l	1
cD7	RS.l	1
cA0	RS.l	1
cA1	RS.l	1
cA2	RS.l	1
cA3	RS.l	1
cA4	RS.l	1
cA5	RS.l	1
cA6	RS.l	1
cA7	RS.l	1
context.size	RS	0

SAVE_CONTEXT	MACRO
;; sauvegarde le contexte processeur actuel.
;; … la fin : 	- SP d‚signe la pile interne.
;;		- A6 d‚signe la zone de sauvegarde du contexte.
;;		- A1 d‚signe l'ancienne pile.
	MOVE	SR,-(SP)
	ORi	#$700,SR		; pas d'interruptions (zone critique).
	MOVE.l	A7,([_Stack],-4.w)	; sauvegarde de SP.
	ADDq.l	#2,([_Stack],-4.w)	; d‚pilage fictif.
	MOVE.l	A6,([_Stack],-8.w)	; sauvegarde de A6.
	LEA	([_Stack.w,PC],-8.w),A6	; zone de sauvegarde du contexte.
	SUBi.l	#STACK_ROOM,_Stack	; r‚servation d'un bout de pile.
	MOVEm.l	A0-A5/D0-D7,-(A6)	; derniers registres.
	MOVE	(SP)+,SR		; fin de zone critique.
	MOVEa.l	SP,A1			; transmission des infos.
	MOVEa.l	A6,SP
	ENDM

RESTORE_CONTEXT	MACRO
;; Op‚ration inverse de la pr‚c‚dente.
	MOVEm.l	(creg.w,A6),A0-A7/D0-D7
	ADDi.l	#STACK_ROOM,_Stack
	ENDM

READ_CONTEXT	MACRO
;; r‚cupŠre les registres sans toucher … la pile.
	MOVEm.l	(creg.w,A6),A0-A6/D0-D7
	ENDM

WRITE_CONTEXT	MACRO
;; refixe le contexte.
	MOVE.l	A6,-(SP)
	LEA	([_Stack.w,PC],(STACK_ROOM-context.size).w),A6
	MOVEm.l	A0-A5/D0-D7,(creg.w,A6)	;; sauvegarde des premiers registres.
	MOVE.l	(SP)+,(cA6.w,A6)	;; sauvegarde de A6.
	ENDM

UPDATE_CONTEXT	MACRO
;; sauve uniquement D0.
	LEA	([_Stack.w,PC],(STACK_ROOM-context.size).w),A6
	MOVE.l	D0,(cD0.w,A6)
	ENDM

; Gestionnaires des erreurs BUS.
;-------------------------------
	DC.l	'XBRA'
	DC.l	'#BYM'
After_YM
	DC.l	0			; gestionnaire suivant.

Ym_Correction
; Refait l'accŠs 'manuellement'.
	CMPi	#$4000,($11.w,SP)
	Bcc.s	.upper_mem
; erreur d'accŠs sous les 4 premiers meg.
	BCLR	#0,($A,SP)
	RTE

.upper_mem
	CMPi	#$FF88,($11.w,SP)	; Bonne addresse ?
	Beq.s	.redo_access
	JMP	([After_YM.w,PC])

.redo_access
	BCLR	#0,($A.w,SP)
	BTST	#1,($13.w,SP)
	Bne.s	.ffff8802_access
	BTST	#6,($B.w,SP)
	Bne.s	.read00
	BTST	#4,($B.w,SP)
	Bne.s	.wbyte00
	BTST	#5,($B.w,SP)
	Beq.s	.wlong00
; ‚criture mot en 00.
	MOVE	($1A.w,SP),$FFFF8800.w
	RTE

.wlong00
; ‚criture mot long en 00.
	MOVE.l	($18.w,SP),$FFFF8800.w
	RTE

.wbyte00
; ‚criture d'un octet en 00.
	MOVE.b	($1B.w,SP),$FFFF8800.w
	RTE

.read00
; accŠs en lecture.
	BTST	#4,($B.w,SP)
	Bne.s	.rbyte00
	BTST	#5,($B.w,SP)
	Beq.s	.rlong00
; lecture d'un mot.
	MOVE	$FFFF8800.w,($2E.w,SP)
	RTE

.rlong00
; lecture d'un mot long.
	MOVE.l	$FFFF8800.w,($2C.w,SP)
	RTE

.rbyte00
; lecture d'un octet.
	MOVE.b	$FFFF8800.w,($2F.w,SP)
	RTE


.ffff8802_access
; mˆme chose en ffff8802.
	BTST	#6,($B.w,SP)
	Bne.s	.read02
	BTST	#4,($B.w,SP)
	Bne.s	.wbyte02
	BTST	#5,($B.w,SP)
	Beq.s	.wlong02
; ‚criture mot en 02.
	MOVE	($1A.w,SP),$FFFF8802.w
	RTE

.wlong02
; ‚criture mot long en 02.
	MOVE	($18.w,SP),$FFFF8802.w
	MOVE	($1A.w,SP),$FFFF8800.w
	RTE

.wbyte02
; ‚criture d'un octet en 00.
	MOVE.b	($1B.w,SP),$FFFF8802.w
	RTE

.read02
; accŠs en lecture.
	BTST	#4,($B.w,SP)
	Bne.s	.rbyte02
	BTST	#5,($B.w,SP)
	Beq.s	.rlong02
; lecture d'un mot.
	MOVE	$FFFF8802.w,($2E.w,SP)
	RTE

.rlong02
; lecture d'un mot long.
	MOVE	$FFFF8802.w,($2C.w,SP)
	MOVE	$FFFF8800.w,($2E.w,SP)
	RTE

.rbyte02
; lecture d'un octet.
	MOVE.b	$FFFF8802.w,($2F.w,SP)
	RTE

Install_Bus_Correcting
; Fait les installations n‚cessaires.
	PEA	(Bus_Correcting.w,PC)
	MOVE	#2,-(SP)
	BSR	Install_Handler
	ADDq	#6,SP
	RTS

; vecteur de correction.
	DC.l	'XBRA'
	DC.l	'#BSP'
After_BusCorr
	DC.l	0			; Gestionnaire suivant.

; On analyse le code qui a plant‚ et on essaye d'y rem‚dier.
;-----------------------------------------------------------

Bus_Correcting
; Tente de corriger le programme qui plante.
	CMPi	#$FF88,($11.w,SP)	; Bonne addresse ?
	Beq.s	.try_correction
	JMP	([After_BusCorr.w,PC])

.try_correction
	ORi	#$700,SR		; par s‚curit‚.
	MOVEm.l	A0/D0,-(SP)
	MOVE	([10.w,SP]),D0		; instruction qui a caus‚ l'erreur.
	ANDi	#$F1C8,D0
	CMPi	#$01C8,D0		; MOVEp.l
	Bne.s	.not_movep
	BCLR	#0,($12.w,SP)
; Ok, on peut patcher.
; On invalide l'entr‚e du cache.
	MOVEc	CACR,D0
	ORi	#8,D0
	MOVEc	D0,CACR
; On r‚‚crit une sous-routine.
	MOVEa.l	FASTROUTS.w,A0
	MOVE	([10.w,SP]),D0
	ANDi	#$0FBF,D0	; transformation de .l en .w
	MOVE	D0,(A0)+
	MOVE	([10.w,SP],2.w),(A0)+
; on met swap.
	MOVE	([10.w,SP]),D0
	LSr	#8,D0
	LSr	#1,D0
	ANDi	#$7,D0
	ADDi	#$4840,D0
	MOVE	D0,(A0)+
; copie le deuxiŠme MOVEP.
	MOVE	([10.w,SP]),D0
	ANDi	#$FFBF,D0	; transformation de .l en .w
	MOVE	D0,(A0)+
	MOVE	([10.w,SP],2.w),(A0)+
; enfin, JMP
	MOVE	#$4EF9,(A0)+
	MOVE.l	(10.w,SP),(A0)
	ADDq.l	#4,(A0)+
	MOVE	#$4EF8,([10.w,SP])	; Jmp xx.w
	MOVE	FASTROUTS+2.w,([10.w,SP],2.w)	; xxxx
	MOVE.l	A0,FASTROUTS.w
	MOVEm.l	(SP)+,A0/D0
	RTE

.not_movep
	MOVEm.l	(SP)+,A0/D0
	JMP	([After_BusCorr.w,PC])

; Gestion des erreurs de privilŠge.
;----------------------------------
	DC.l	'XBRA'
	DC.l	'#PRI'
After_Privi_Handler
	DC.l	0

Privilege_Handler
	MOVE	D0,-(SP)
	MOVE	([4.w,SP]),D0
	ANDi	#$FFC0,D0
	CMPi	#$40C0,D0
	Bne	.not_movesr		; MOVE SR,xx ?
	MOVE.l	A0,-(SP)
	MOVE	#2,-(SP)		; d‚placement initial.
	LEA	(.SubRout.w,PC),A0
	MOVE.l	#$30174E71,(A0)		; Pr‚paration du code.
	MOVE.l	#$4E714E73,(4.w,A0)
	MOVE	([10.w,SP]),D0
	ANDi	#7,D0
	LSL	#8,D0
	ADD	D0,D0
	OR	D0,(A0)			; Num‚ro de registre.
	MOVE	([10.w,SP]),D0
	ANDi	#$38,D0
	LSL	#3,D0
	Beq.s	.todreg			; Vers registre de donn‚es.
	OR	D0,(A0)
	CMPi	#$1C0,D0
	Beq.s	.spec			; Dest est indirect.
	CMPi	#$140,D0
	Beq.s	.one_word		; MOVE SR,d(An) ?
	CMPi	#$180,D0
	Bne.s	.no_word		; MOVE SR,d(An,Xi) ?
.one_word
	MOVE	([10.w,SP],2.w),(2.w,A0)	; il y a un mot … rajouter.
	ADDq	#2,(SP)			; Un peu plus … sauter.
.no_word
	MOVE	([10.w,SP]),D0
	ANDi	#7,D0
	CMPi	#7,D0			; A7 est concern‚ ?
	Bne.s	.todreg			; non (ouf!)
	MOVE	#$4E71,(6.w,A0)		; on ex‚cute la suite du code.
	ANDi	#$F1FF,(A0)		; on remplace A7 par A0.
	MOVE	(SP)+,A0	; d‚placement.
	ADDa.l	(8.w,SP),A0
	MOVE.l	A0,(8.w,SP)
	MOVEa.l	(SP)+,A0
	MOVE	(SP)+,D0
	MOVE.l	A0,-(SP)
	MOVE.l	USP,A0
	Bra.s	.SubRout

.spec
; la destination est indirecte.
	MOVE	([10.w,SP]),D0
	ANDi	#7,D0
	Beq.s	.short_address
	MOVE	([10.w,SP],4.w),(4.w,A0)
	ADDq	#2,(SP)			; Un peu plus … sauter.
.short_address
	MOVE	([10.w,SP],2.w),(2.w,A0)
	ADDq	#2,(SP)			; Un peu plus … sauter.
	
.todreg
; la destination est un registre de donn‚e.
; c'est prˆt.
	MOVE	(SP)+,A0	; d‚placement.
	ADDa.l	(8.w,SP),A0
	MOVE.l	A0,(8.w,SP)
	MOVEa.l	(SP)+,A0
	MOVE	(SP)+,D0

.SubRout
; Routine d'‚mulation, fait MOVE (SP),xx.
	NOP
	NOP
	NOP
	RTE

; cas o— la destination concerne la pile.
	MOVE.l	A0,USP
	MOVEa.l	(SP)+,A0
	RTE

.not_movesr
; on n'a pas pu traiter l'erreur.
	MOVE	(SP)+,D0
	JMP	([After_Privi_Handler.w,PC])


; Gestionnaire Line A. Gestion des macros de patch.
;--------------------------------------------------
	DC.l	'XBRA'
	DC.l	'#PTC'
After_LineA_Handler
	DC.l	0

LineA_Handler
; Installe des patches.
	CMPi	#$ABCD,([2.w,SP])
	Bne.s	.not_rte
; ‚mule le RTE 68000.
	ADDq	#6,SP
	MOVE	(2.w,SP),(SP)
	MOVE.l	(4.w,SP),(2.w,SP)
	CLR	(6.w,SP)
	RTE

.not_rte
	CMPi	#$ABCE,([2.w,SP])
	Bne.s	.not_ccontext
; cr‚e un contexte en pile.
	MOVE	(SP),(6.w,SP)		; sauvegarde de SR.
	MOVE.l	(2.w,SP),(SP)		; adresse de retour.
	MOVE	(6.w,SP),(4.w,SP)	; ramŠne le SR.
	MOVE.l	(8.w,SP),(6.w,SP)	; ramŠne le PC.
	CLR	(10.w,SP)		; faux format.
	ADDq.l	#2,(SP)
	RTS

.not_ccontext
	CMPi	#$ABCF,([2.w,SP])
	Bne.s	.not_tcontext
; jette un contexte.
	MOVE	(SP),(6.w,SP)
	ADDq	#6,SP			; vide la pile.
	RTE

.not_tcontext
	CMPi	#$ABD0,([2.w,SP])
	Bne.s	.not_forceformat
; RTE avec format forc‚.
	ADDq	#8,SP
	CLR	(6.w,SP)
	RTE

.not_forceformat
	JMP	([After_LineA_Handler.w,PC])

; Gestionnaire Line A.
;---------------------
; - patch Bitblt

	Dc.l	'XBRA'
	Dc.l	'#LIA'
After_LineA_Patch
	Dc.l	0

LineA_Patch
	TST.b	fSystemPatch
	Beq.s	.no_patch
	CMPi	#$A007,([2.w,SP])
	Beq.s	.bit_blt
.no_patch
	JMP	([After_LineA_Patch.w,PC])

.bit_blt
	MOVE.l	A6,-(SP)
	MOVE	D0,-(SP)
	LEA	(bitblt_data.w,PC),A0
	REPT	19
	MOVE.l	(A6)+,(A0)+
	ENDR
; correction des variables.
	LEA	(bitblt_data.w,PC),A0
	TST	(28.w,A0)
	Bpl.s	.dest_x_ok
	MOVE	(28.w,A0),D0
	CLR	(28.w,A0)
	SUB	D0,(14.w,D0)
	ADD	D0,(A0)
.dest_x_ok
	TST	(30.w,A0)
	Bpl.s	.dest_y_ok
	MOVE	(30.w,A0),D0
	CLR	(30.w,A0)
	SUB	D0,(16.w,D0)
	ADD	D0,(2.w,A0)
.dest_y_ok
	MOVE	(SP)+,D0
	MOVEa.l	A0,A6
; appel LineA
	MOVE	#$28,-(SP)
	PEA	(.suite_bitblt.w,PC)
	MOVE	SR,-(SP)
	JMP	([After_LineA_Patch.w,PC])
.suite_bitblt
	Dc	$A007
	MOVE.l	(SP)+,A6
	ADDq.l	#2,(2.w,SP)
	RTE
	

; Gestionnaire Line F.
;---------------------
	DC.l	'XBRA'
	DC.l	'#LIF'
After_LineF_Patch
	DC.l	0

LineF_Patch
; ‚mule les LineF MOVEm/Unlk.
	ORi	#$700,SR
	MOVE	(SP)+,D2
	MOVEa.l	(SP)+,A0
	MOVE.l	(A0)+,D1
	BTST	#0,D1
	Bne.s	.ok
; on ne sait pas le traiter.
	PEA	(A0)
	MOVE	D2,-(SP)
	JMP	([After_LineF_Patch.w,PC])
.ok
	ANDi	#$FFE,D1
	Beq.s	.unlk

	LSL	#2,D1
	LEA	(MASK.w,PC),A0
	MOVE	D1,(A0)			; fixer le movem.
	ADDq	#6,SP			; corriger la pile.

	MOVEC	CACR,D1
	ORi	#8,D1
	MOVEC	D1,CACR
MASK	EQU	*+2
	MOVEm.l	(SP)+,A2
.unlk
	MOVE	D2,SR
	UNLK	A6
	RTS


;____________________________________
;[ Patches pour les appels systŠme. ]
;[__________________________________]

; Patchs GemDos.
;---------------
Call_Dos	MACRO	; macro appelant le gemdos.
	READ_CONTEXT
	MOVE	#$84,-(SP)
	PEA	(.\@.w,PC)
	MOVE	SR,-(SP)
	JMP	([After_Gemdos_Patch.w,PC])
.\@
	UPDATE_CONTEXT
	ENDM

	DC.l	'XBRA'
	DC.l	'#DOS'
After_Gemdos_Patch
	DC.l	0

Gemdos_Patch
; Correction du DOS.
; Srealloc : modification pour les modes ST + modif de _memtop
; Ddelete : autorisation du '\' en fin de chemin.
; Fopen : gestion des jokers.
; Frename : ''.
; Fattrib : ''.
; Fwrite : Fwrite(-3) marche.
; Malloc : Malloc(0) autoris‚.
; Mfree : r‚pare les conneries du bureau.
; Pexec : gestion des jokers.

; patchs autoris‚s ?
	TST.b	fSystemPatch
	Bne.s	.go_on
	JMP	([After_Gemdos_Patch.w,PC])
.go_on
	SAVE_CONTEXT
	BTST	#5,(A1)		; en mode Super ?
	Bne.s	.super
	MOVEa.l	USP,A1
	BRA.s	.stack_ok
.super
	ADDq	#8,A1
.stack_ok
; on commence les tests.
	CMPi	#$15,(A1)		; Srealloc ?
	Bne.s	.not_srealloc
; Srealloc.
	CMPi.l	#$7D00,(2.w,A1)		; 32000 octets ?
	Bne.s	.alter_memtop
	ADDi.l	#$200,(2.w,A1)		; alors 32512.
.alter_memtop
	MOVE.l	(2.w,A1),-(SP)
	MOVE	#$15,-(SP)
	Call_Dos
	ADDq	#6,SP
	MOVE.l	D0,_memtop.w
	Bra	.end_handler
.not_srealloc
	CMPi	#$3A,(A1)
	Bne.s	.not_Ddelete
; Ddelete.
	LEA	(pathBuffer.w,PC),A0
	MOVE.l	(2.w,A1),A2
.copy_path
	MOVE.b	(A2)+,(A0)+
	Bne.s	.copy_path
	CMPi.b	#'\',(-2.w,A0)
	Bne	.not_handled
	CLR.b	(-2.w,A0)
	MOVE.l	#pathBuffer,(2.w,A1)
	Bra	.not_handled
.not_Ddelete
	CMPi	#$43,(A1)
	Beq.s	.fAttrib
	CMPi	#$3D,(A1)
	Bne.s	.not_Fopen
; Fopen et Fattrib
.fAttrib
; ouverture de fichier.
	MOVE.l	(2.w,A1),-(SP)
	BSR	Get_Filename
	ADDq	#4,SP
	Bmi	.not_handled
	MOVE.l	D0,(2.w,A1)		; on donne le nouveau nom.
	Bra	.not_handled
.not_Fopen
	CMPi	#$40,(A1)
	Bne.s	.not_Fwrite
; Fwrite.
	CMPi	#-3,(2.w,A1)
	Bne	.not_handled
	MOVE	#3,(2.w,A1)
	Bra	.not_handled
.not_Fwrite

	CMPi	#$48,(A1)		; Malloc ?
	Bne.s	.not_malloc
; Malloc(0) ?
	TST.l	(2.w,A1)
	Bne	.not_handled
; pointeur sur m‚moire ill‚gale.
	MOVE.l	#$10000,(cD0.w,A6)
	Bra	.end_handler
.not_malloc

	CMPi	#$49,(A1)
	Bne.s	.not_Mfree
; Mfree
; est-ce que ‡a concerne le bureau ?
	CMPi	#$401,$E00002
	Bne.s	.not_401
	MOVE.l	#$B968,A0	; valeur TOS 4.01
	Bra.s	.point_ok
.not_401
	MOVE.l	#$B96E,A0	; valeur TOS 4.02 et 4.04.
.point_ok
	MOVEq	#7,D0
.check_A5
	CMPa.l	(cA5.w,A6),A0
	Beq.s	.desktop
	ADDa	#$8E,A0
	DBF	D0,.check_A5
	Bra	.not_handled
.desktop
; on doit faire le Mfree qu'il oublie de faire.
	CMPi	#-1,([cA5.w,A6],4.w)
	Bne	.not_handled
; on ferme vraiment la fenˆtre.
	MOVE.l	([cA5.w,A6],$60.w),-(SP)
	MOVE	#$49,-(SP)
	Call_Dos
	ADDq	#6,SP
	Bra	.not_handled
.not_Mfree
	CMPi	#$4B,(A1)		; Pexec.
	Bne	.not_Pexec
	TST	(2.w,A1)		; mode ?
	Beq.s	.good_mode
	CMPi	#3,(2.w,A1)
	Bne	.not_handled
.good_mode
; on cherche le fichier.
	MOVE.l	(4.w,A1),-(SP)
	BSR	Get_Filename
	ADDq	#4,SP
	Bmi.s	.no_name_change
	MOVE.l	D0,(4.w,A1)		; on donne le nouveau nom.
.no_name_change
; charge le d‚but pour voir.
	MOVE.l	A1,-(SP)
	CLR	-(SP)
	MOVE.l	(4.w,A1),-(SP)
	MOVE	#$3D,-(SP)
	Call_Dos
	ADDq	#8,SP
	TST	D0
	Bmi.s	.not_found
	MOVE	D0,D7
	MOVE.l	_dskbufp.w,-(SP)
	MOVE.l	#512,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	Call_Dos
	LEA	(12.w,SP),SP
	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	Call_Dos
	ADDq	#4,SP
	MOVEa.l	(SP)+,A1
	Bsr.s	Check_Prg
	Bra.s	.end_handler
.not_found
	MOVEa.l	(SP)+,A1
	Bra.s	.not_handled

.not_Pexec
	CMPi	#$56,(A1)
	Bne.s	.not_Frename
; Frename
	MOVE.l	(4.w,A1),-(SP)
	Bsr	Get_Filename
	ADDq	#4,SP
	Bmi.s	.not_handled
	MOVE.l	D0,(4.w,A1)
.not_Frename	
.not_handled
;  on remet tout ‡a normal.
	RESTORE_CONTEXT
; on donne la main au systŠme.
	JMP	([After_Gemdos_Patch.w,PC])

.end_handler
; fin, on remet tout ‡a normal.
	RESTORE_CONTEXT
	RTE

; Sous-routines.
;---------------
Check_Prg
; s'occupe de r‚gler les paramŠtres pour le programme a ‚x‚cuter.
; A1 pointe sur la pile de l'appelant.
	BSR	Recon_Disk
	TST	D0
	Bne	.unknown
; disque reconnu
; on fixe son set-up
	BSR	Set_Up
; r‚glage vid‚o.
	MOVE.l	A1,A5
	MOVE	#-1,-(SP)
	MOVE	#$58,-(SP)
	TRAP	#14
	ADDq	#4,SP
	MOVE	D0,-(SP)

	MOVE.b	(curConfig+pVideo.w,PC),D0
	EXT	D0
	MOVE	D0,-(SP)
	Bsr	BootVideo
	ADDq	#2,SP
	
	MOVE.l	(12.w,A5),-(SP)
	MOVE.l	(8.w,A5),-(SP)
	MOVE.l	(4.w,A5),-(SP)
	MOVE	(2.w,A5),-(SP)
	MOVE	(A5),-(SP)
	Call_Dos
	LEA	(16.w,SP),SP
; restaure le mode video.
	MOVE	#3,-(SP)
	CLR.l	-(SP)
	CLR.l	-(SP)
	MOVE	#$5,-(SP)
	TRAP	#14
	LEA	(14.w,SP),SP
; rebascule en mode par d‚faut.
	BSR	Restore_Default
	BSR	Set_Up
	RTS
.unknown
	RESTORE_CONTEXT
	JMP	([After_Gemdos_Patch.w,PC])

Test_Joker
; retourne 0 si une chaŒne contient des jokers.
	CARGS	#4,STRING.l
	MOVE.l	A0,-(SP)
	MOVEa.l	(STRING.w,SP),A0
	MOVEq	#0,D0
.loop
	CMPi.b	#'*',(A0)
	Beq.s	.end
	CMPi.b	#'?',(A0)
	Beq.s	.end
	TST.b	(A0)+
	Bne.s	.loop
	MOVEq	#-1,D0
.end
	MOVEa.l	(SP)+,A0
	TST.l	D0
	RTS

Get_Filename
; r‚cupŠre le nom d'un fichier r‚pondant au filtre propos‚.
; retourne un pointeur sur le fichier ou <0 si pas trouv‚.
	MOVEm.l	A0-A2/A5/D1-D2/D6,-(SP)
	CARGS	#28,STRING2.l
	MOVE.l	(STRING2.w,SP),-(SP)
	BSR.s	Test_Joker
	ADDq	#4,SP
	Bne	.end_call		; pas de joker ?
	MOVE	#$2F,-(SP)
	Call_Dos			; Fgetdta.
	ADDq	#2,SP
	MOVE.l	D0,-(SP)
	PEA	(myDTA.w,PC)
	MOVE	#$1A,-(SP)		; Fsetdta.
	Call_Dos
	ADDq	#6,SP
	MOVE.l	(STRING2+4.w,SP),D0
	CLR	-(SP)
	MOVE.l	D0,-(SP)
	MOVE	#$4E,-(SP)
	Call_Dos			; Fsfirst.
	ADDq	#8,SP
	TST.l	D0
	BMI.s	.end			; pas de fichier ?
	MOVEa.l	(STRING2+4.w,SP),A5
	LEA	(myDTA+30.w,PC),A0
	LEA	(pathBuffer.w,PC),A1
	MOVEa.l	A1,A2			; d‚but du nom du fichier.
; on va fabriquer le nouveau nom.
.copy_path
	MOVE.b	(A5)+,D0
	MOVE.b	D0,(A1)+
	Beq.s	.end_copy_path
	CMPi.b	#'\',D0			; '\' ?
	Bne.s	.copy_path
	MOVE.l	A1,A2			; nouvelle position du nom.
	Bra.s	.copy_path
.end_copy_path
; on copie le nom.
	MOVE.b	(A0)+,(A2)+
	Bne.s	.end_copy_path
	LEA	(pathBuffer.w,PC),A0
	MOVE.l	A0,D0
.end	
	MOVE.l	(SP)+,D5		; ancienne DTA.
	MOVE.l	D0,-(SP)		; pointeur sur le nom.
	MOVE.l	D5,-(SP)
	MOVE	#$1A,-(SP)		; Fsetdta.
	Call_Dos
	ADDq	#6,SP
	MOVE.l	(SP)+,D0
.end_call
	MOVEm.l	(SP)+,A0-A2/A5/D1-D2/D6
	RTS

; Patchs AES.
;---------------
Install_AES_Patch
; installation (d‚licate) du patch AES/VDI.
	CMPi	#$401,$E00002
	Bne.s	.not_401
	MOVE.l	$E32600,After_AES_Patch
	MOVE.l	#AES_Patch,$E32600
	MOVE.l	#AES_Patch,$E3260A
	Bra.s	.end_patch
.not_401
	CMPi	#$402,$E00002
	Bne.s	.not_402
	MOVE.l	$E343D4,After_AES_Patch
	MOVE.l	#AES_Patch,$E343D4
	MOVE.l	#AES_Patch,$E343DE
	Bra.s	.end_patch
.not_402
	CMPi	#$404,$E00002
	Bne.s	.not_404
	MOVE.l	$E34434,After_AES_Patch
	MOVE.l	#AES_Patch,$E34434
	MOVE.l	#AES_Patch,$E3443E
.not_404
.end_patch
	RTS

Call_AES	MACRO	; macro appelant l'AES/VDI.
	READ_CONTEXT
	MOVE	#$88,-(SP)
	PEA	(.\@.w,PC)
	MOVE	SR,-(SP)
	JMP	([After_AES_Patch.w,PC])
.\@
	UPDATE_CONTEXT
	ENDM

	DC.l	'XBRA'
	DC.l	'#AES'
After_AES_Patch
	DC.l	0

AES_Patch
; patchs autoris‚s ?
	TST.b	fSystemPatch
	Bne.s	.go_on
	JMP	([After_AES_Patch.w,PC])
.go_on
	CMPi	#200,D0
	Beq.s	.AES_Call
	JMP	([After_AES_Patch.w,PC])

.AES_Call
	SAVE_CONTEXT
	MOVE.l	D1,A0
	CMPi	#$51,([A0])
	Beq.s	.Form_Dial
	RESTORE_CONTEXT
	JMP	([After_AES_Patch.w,PC])

.Form_Dial
; Patchs Form Dial (s‚curit‚).
	MOVE.l	A0,-(SP)
	Call_AES
	MOVEa.l	(SP)+,A0	; params.
	MOVEa.l	(8.w,A0),A1	; int_in
	CMPi	#3,(A1)		; form_finish ?
	bne	.end_fd		; on ne fait rien.
; reconstruction des paramŠtres.
	LEA	(AESparams.w,PC),A1
	MOVE.l	#AEScontrol,(A1)
	MOVE.l	(4.w,A0),(4.w,A1)	; recopie de global.
	MOVE.l	#AESintin,(8.w,A1)
	MOVE.l	#AESintout,(12.w,A1)
	MOVE.l	#AESaddrin,(16.w,A1)
	MOVE.l	#AESaddrout,(20.w,A1)
; on remplit les tables.
	LEA	(AEScontrol.w,PC),A0
	MOVE	#24,(A0)		; evt_timer.
	MOVE	#4,(2.w,A0)
	MOVE	#1,(4.w,A0)
	MOVE	#2,(6.w,A0)
	MOVE	#1,(8.w,A0)
	LEA	(AESintin.w,PC),A0
	MOVE	#10,(A0)
	CLR	(2.w,A0)
	MOVE.l	A1,D1
	MOVE.l	#200,D0
	Call_AES
.end_fd
	RESTORE_CONTEXT
	RTE


; Macros pour le Timer C.
;------------------------
CHECK_TIMERC	MACRO
;; Tests
	MOVE.b	$FFFFFA1D.w,-(SP)
	ANDi.b	#$F0,(SP)
	Bne.s	.\@
	ORi.b	#$50,$FFFFFA1D.w
	MOVE.b	#$C0,$FFFFFA23.w
.\@
	ENDM
;; Sauve l'‚tat et restaure le timerC.
	
RESET_TIMERC	MACRO
;; Remet le timer C.
	TST.b	(SP)+
	Bne.s	.\@
	ANDi.b	#$F,$FFFFFA1D.w
	CLR.b	$FFFFFA23.w
.\@
	ENDM


; Patchs BIOS.
;-------------
Call_BIOS	MACRO		; macro appelant le bios.
	READ_CONTEXT
	MOVE	#$B4,-(SP)
	PEA	(.\@.w,PC)
	MOVE	SR,-(SP)
	JMP	([After_BIOS_Patch.w,PC])
.\@
	UPDATE_CONTEXT
	ENDM

	DC.l	'XBRA'
	DC.l	'#BIO'
After_BIOS_Patch
	DC.l	0

BIOS_Patch
; Correction du BIOS.
; gestion des codes escapes couleurs pour la console.
; r‚installation du timer C pour :
; rwabs, bconout sur ikbdsys et getbpb.

; patchs autoris‚s ?
	TST.b	fSystemPatch
	Bne.s	.go_on
	JMP	([After_BIOS_Patch.w,PC])
.go_on
	SAVE_CONTEXT		; passe en contexte Backward.
	BTST	#5,(A1)		; en mode Super ?
	Bne.s	.super
	MOVEa.l	USP,A1
	BRA.s	.stack_ok
.super
	ADDq	#8,A1
.stack_ok
	CMPi.l	#$30002,(A1)	; Bconout console ?
	Bne.s	.not_wcons
	MOVE	(4.w,A1),D0
	TST.b	fInk
	Beq.s	.no_change_ink
; changement de l'encre.
	Sf	fInk
	ANDi	#$F,D0
	MOVE	D0,([_Line_A],-36.w)
	Bra	.not_handled
.no_change_ink
	TST.b	fPaper
	Beq.s	.no_change_paper
; changement du fond.
	Sf	fPaper
	ANDi	#$F,D0
	MOVE	D0,([_Line_A],-38.w)
	Bra	.not_handled

.no_change_paper
	TST.b	finEsc
	Beq.s	.not_inEscape
	Sf	finEsc
; est-ce un code escape qui nous concerne ?
	CMPi.b	#'b',D0
	Seq	fInk
	CMPi.b	#'c',D0
	Seq	fPaper
	Bra	.not_handled
.not_inEscape
	CMPi.b	#$1B,D0
	Seq	finEsc
	Bra	.not_handled
.not_wcons
	CMPi.l	#$30004,(A1)	; Bconout ikbsys ?
	Beq.s	.check_timerc
	CMPi	#7,(A1)		; Getbpb ?
	Beq.s	.check_timerc
	CMPi	#4,(A1)		; Rwabs ?
	Bne	.not_handled
.check_timerc
; on active le timer c s'il est arrˆt‚.
	CHECK_TIMERC
	MOVE.l	A1,-(SP)
	MOVE.l	(16.w,A1),-(SP)
	MOVE.l	(12.w,A1),-(SP)
	MOVE.l	(8.w,A1),-(SP)
	MOVE.l	(4.w,A1),-(SP)
	MOVE.l	(A1),-(SP)
	Call_BIOS
	LEA	(20.w,SP),SP
; Erreur g‚n‚rale ?
	CMPi.l	#-1,D0
	Bne.s	.no_error
; Encore une fois.
	MOVEa.l	(SP),A1
	MOVE.l	(16.w,A1),-(SP)
	MOVE.l	(12.w,A1),-(SP)
	MOVE.l	(8.w,A1),-(SP)
	MOVE.l	(4.w,A1),-(SP)
	MOVE.l	(A1),-(SP)
	Call_BIOS
	LEA	(20.w,SP),SP
	
.no_error
	MOVEa.l	(SP)+,A1
; on d‚sactive le timer.
	RESET_TIMERC
; fin, on remet tout ‡a normal.
	RESTORE_CONTEXT			; retour en contexte normal.
	RTE

.not_handled
;  on remet tout ‡a normal.
	RESTORE_CONTEXT			; retour en contexte normal.
; on donne la main au systŠme.
	JMP	([After_BIOS_Patch.w,PC])


; Patchs XBIOS.
;-------------
Call_XBIOS	MACRO			; macro appelant le xbios.
	READ_CONTEXT
	MOVE	#$B8,-(SP)
	PEA	(.\@.w,PC)
	MOVE	SR,-(SP)
	JMP	([After_XBIOS_Patch.w,PC])
.\@
	UPDATE_CONTEXT
	ENDM

	DC.l	'XBRA'
	DC.l	'#XBI'
After_XBIOS_Patch
	DC.l	0

XBIOS_Patch
; Correction du XBIOS.
; corrections setscr.
; r‚installation du timer C pour ikbws, flopread et flopwrt.
; sauvegarde de la palette pour blitmode.
; correction de Getrez.

; patchs autoris‚s ?
	TST.b	fSystemPatch
	Bne.s	.go_on
	JMP	([After_XBIOS_Patch.w,PC])
.go_on
	SAVE_CONTEXT
	BTST	#5,(A1)		; en mode Super ?
	Bne.s	.super
	MOVEa.l	USP,A1
	Bra.s	.stack_ok
.super
	ADDq	#8,A1
.stack_ok
	CMPi	#4,(A1)
	bne.s	.not_getrez
; demande de r‚solution.
	MOVE.l	A1,-(SP)
	MOVE	#-1,-(SP)
	MOVE	#$58,-(SP)
	Call_XBIOS
	ADDq	#4,SP
	MOVE.l	(SP)+,A1
	BTST	#7,D0
	Beq	.not_handled
	ANDi	#$F,D0
	Beq	.not_handled
; mode 4 ou 16 couleurs, on lit le registre ST.
	MOVEq	#0,D0
	MOVE.b	$FFFF8260.w,D0
	MOVE.l	D0,(cD0.w,A6)
	Bra	.end_handler
	
; mode compatible ST, test.
	
.not_getrez
	CMPi	#6,(A1)		; setpalette ?
	Beq.s	.do_setscr	; on force D0 et D1 … 0.
	CMPi	#5,(A1)		; setscr ?
	Bne	.not_setscr
; corrections setscr.
	CMPi	#-1,(10.w,A1)
	Beq.s	.do_setscr
	LEA	(STmode.w,PC),A0
	CMPi	#3,(10.w,A1)	; mode falcon ?
	Bne.s	.st_mode
	MOVE	(12.w,A1),D0
	CMPi	#$FFFF,D0
	Beq.s	.do_setscr	; simple demande.
; est-ce un mode ST ?
	BTST	#7,D0
	Sne	(A0)		; mode ST.
	ANDi	#$7,D0
	Bne.s	.low_ok		; pas mono.
	Sf	(A0)
; interdiction 40 col et mono.
	MOVE	(12.w,A1),D0
	ANDi	#$F,D0
	Bne.s	.low_ok
	ORi	#2,D0
.low_ok
	MOVE	(12.w,A1),D0
	BTST	#5,D0
	Beq.s	.do_setscr	; vga ?
	ANDi	#$FFBF,(12.w,A1)	; pas d'overscan.
	Bra.s	.do_setscr
.st_mode
	CMPi	#2,(10.w,A1)	; mode mono ?
	Sne	(A0)
.do_setscr
; effectue l'appel.
	MOVE.b	$FFFF820A.w,-(SP)
	MOVE.l	(16.w,A1),-(SP)
	MOVE.l	(12.w,A1),-(SP)
	MOVE.l	(8.w,A1),-(SP)
	MOVE.l	(4.w,A1),-(SP)
	MOVE.l	(A1),-(SP)
	Call_XBIOS
	LEA	(20.w,SP),SP
	MOVE.b	(SP)+,$FFFF820A.w
; on fixe D0 et D1 … 0.
	CLR.l	(cD0.w,A6)
	CLR.l	(cD1.w,A6)
	Bra	.end_handler

.not_setscr
	CMPi	#8,(A1)		; floprd ?
	Beq.s	.check_timerc
	CMPi	#9,(A1)		; flopwrt ?
	Beq.s	.check_timerc
	CMPi	#$19,(A1)	; ikbdws ?
	Bne	.no_timerc
.check_timerc
; on active le timer c s'il est arrˆt‚.
	CHECK_TIMERC
	MOVE.l	A1,-(SP)
	MOVE.l	(16.w,A1),-(SP)
	MOVE.l	(12.w,A1),-(SP)
	MOVE.l	(8.w,A1),-(SP)
	MOVE.l	(4.w,A1),-(SP)
	MOVE.l	(A1),-(SP)
	Call_XBIOS
	LEA	(20.w,SP),SP
	CMPi.l	#-6,D0
	Bne.s	.no_error
; on r‚essaye.
	MOVE.l	(SP),A1
	MOVE.l	(16.w,A1),-(SP)
	MOVE.l	(12.w,A1),-(SP)
	MOVE.l	(8.w,A1),-(SP)
	MOVE.l	(4.w,A1),-(SP)
	MOVE.l	(A1),-(SP)
	Call_XBIOS
	LEA	(20.w,SP),SP
.no_error
	MOVEa.l	(SP)+,A1
; on d‚sactive le timer.
	RESET_TIMERC
	Bra.s	.end_handler

.no_timerc
	CMPi	#$40,(A1)	; blitmode ?
	Bne.s	.not_handled
	LEA	$FFFF8240.w,A0
	REPT	8
	MOVE.l	(A0)+,-(SP)	; sauvegarde de la palette.
	ENDR
	MOVE	(2.w,A1),-(SP)
	MOVE	#$40,-(SP)
	Call_XBIOS
	ADDq	#4,SP
	CLR.l	$45A.w
	LEA	$FFFF8260.w,A0
	REPT	8
	MOVE.l	(SP)+,-(A0)	; restauration de la palette.
	ENDR

.end_handler
; fin, on remet tout ‡a normal.
	RESTORE_CONTEXT
	RTE

.not_handled
; effectue l'appel manuellement.
	MOVE.l	(20.w,A1),-(SP)
	MOVE.l	(16.w,A1),-(SP)
	MOVE.l	(12.w,A1),-(SP)
	MOVE.l	(8.w,A1),-(SP)
	MOVE.l	(4.w,A1),-(SP)
	MOVE.l	(A1),-(SP)
	Call_XBIOS
	LEA	(24.w,SP),SP
;  on remet tout ‡a normal.
	RESTORE_CONTEXT
; on donne la main au systŠme.
	RTE

;________________________________
;[ Gestionnaire d'interruptions ]
;[______________________________]
; Gestionnaires VBL :
;--------------------
	DC.l	'XBRA'
	DC.l	'#VBL'
After_VBL_Handler
	DC.l	0

VBL_Handler
; gŠre le 50/60Hz.
	TST.b	STmode		; mode ST ?
	Beq	.no_change
	CMPi.b	#2,$FFFF8260.w
	Beq	.no_change	; rien pour la haute.
	MOVE.l	A0,-(SP)
	MOVE.l	D0,-(SP)
	MOVE.b	$FFFF8006.w,D0	; monniteur ?
	LSR.b	#6,D0
	ANDi.b	#3,D0
	BTST	#0,D0
	Beq.s	.not_rgb	; RGB (ou TV) ?
; on regarde s'il faut changer.
	BTST	#1,$FFFF820A.w
	Beq.s	.NTSC_RGB
	CMPi	#$20D,$FFFF82A2.w
	Bne.s	.nothing	; pas normal ?
; passage … 50 Hz.
	LEA	(RGB_50.w,PC),A0
	Bra.s	.set_up
.NTSC_RGB
	CMPi	#$271,$FFFF82A2.w
	Bne.s	.nothing
; passage … 60 Hz.
	LEA	(RGB_60.w,PC),A0
	Bra.s	.set_up
.not_rgb
	CMPi.b	#2,D0
	Bne.s	.nothing	; moniteur vga ?
	TST.b	pScreen+curConfig
	Beq.s	.nothing	; multiscan ?
	BTST	#1,$FFFF820A.w
	Beq.s	.NTSC_VGA	; Ntsc ?
	CMPi	#$419,$FFFF82A2.w
	Bne.s	.nothing	; normal ?
; passage … 50Hz.
	LEA	(VGA_50.w,PC),A0
	Bra.s	.set_up
.NTSC_VGA
	CMPi	#$4E1,$FFFF82A2.w
	Bne.s	.nothing
	LEA	(VGA_60.w,PC),A0
.set_up
; copie des registres
	MOVE.l	(A0)+,$FFFF82A2.w
	MOVE.l	(A0)+,$FFFF82A6.w
	MOVE.l	(A0)+,$FFFF82AA.w
.nothing
	MOVE.l	(SP)+,D0
	MOVEa.l	(SP)+,A0
.no_change
	JMP	([After_VBL_Handler.w,PC])

; Patch systŠme.
	DC.l	'XBRA'
	DC.l	'#VBL'
After_VBL_Patch
	DC.l	0

VBL_Patch
; correction (restauration du timer).
; nouveau mode: corrections effectu‚es si !flock.
	TST	flock.w
	Bne.s	.go_on
	MOVE	D0,-(SP)
; le timer C est d‚sactiv‚, on va le r‚activer
	CHECK_TIMERC
.call_vbl
	MOVE	#$70,-(SP)
	PEA	(.suite_vbl.w,PC)
	MOVE	SR,-(SP)
.go_on
	JMP	([After_VBL_Patch.w,PC])
.suite_vbl
	RESET_TIMERC
	MOVE	(SP)+,D0
	RTE

	DC.l	'XBRA'
	DC.l	'#TIC'
After_TimerC_Patch
	DC.l	0

TimerC_Patch
; EmpŠche l'appel de evt_timer si n‚cessaire.
; m‚thode temporaire.
	TST.l	$400.w
	Beq.s	.dont_go
	JMP	([After_TimerC_Patch.w,PC])
.dont_go
	ADDq.l	#1,_hz_200.w
	RTE

; Gestionnaire clavier.
;----------------------
	DC.l	'XBRA'
	DC.l	'#KBD'
After_KBD_Handler
	DC.l	0

Kbd_Handler
	MOVE.b	$FFFFFC00.w,-(SP)
	CLR	-(SP)
	PEA	(.suite.w,PC)
	MOVE	SR,-(SP)
	JMP	([After_KBD_Handler.w,PC])
.suite
	BTST	#7,(SP)+
	Bne.s	.kbd
; interruption MIDI.
	RTE

.kbd
	MOVE.b	$FFFFFC02.w,-(SP)	; octet clavier re‡u.
	TST	WaitCount
	Beq.s	.no_pending_bytes
; il reste des octets … ignorer.
	SUBq	#1,WaitCount
	ADDq	#2,SP
	RTE

.no_pending_bytes
; on doit interpr‚ter l'octet.
; s'agit-il d'un octet de contr“le.
	CMPi.b	#$F6,(SP)
	Bcs.s	.not_control_code
; on va lire dans la table les octets … sauter.
	MOVE.l	D0,-(SP)
	MOVEq	#0,D0
	MOVE.b	(4.w,SP),D0	; code d'en tˆte.
	SUBi	#$F6,D0
	MOVE	(WaitTable.w,PC,D0*2),WaitCount
	MOVE.l	(SP)+,D0
	ADDq	#2,SP
	RTE

.not_control_code
; touche enfonc‚e ou relach‚e.
	TST.b	(SP)
	BMi	.key_released
; touche enfonc‚e.
	CMPi.b	#$1D,(SP)
	Bne.s	.not_control
; contr“le.
	ORi	#1,BackKey
	ADDq	#2,SP
	RTE
.not_control
	CMPi.b	#$38,(SP)
	Bne.s	.not_alternate
; alternate
	ORi	#2,BackKey
	ADDq	#2,SP
	RTE
.not_alternate
	CMPi	#3,BackKey
	Beq.s	.may_configure
	ADDq	#2,SP
	RTE

.may_configure
; premier test pour ‚carter la plupart des touches.
	CMPi.b	#$45,(SP)
	Bcc.s	.may_be_good_key
	ADDq	#2,SP
	RTE

.may_be_good_key
; touches de configuration temps r‚Šl.
	CMPi.b	#$63,(SP)
	Bne.s	.not_16M
; passage du 68030 … 16 Mhz.
	MOVE	#1,-(SP)
	Bsr	Set_Clock
	ADDq	#4,SP
	RTE
.not_16M
	CMPi.b	#$64,(SP)
	Bne.s	.not_8M
; passage … 8Mhz.
	CLR	-(SP)
	Bsr	Set_Clock
	ADDq	#4,SP
	RTE
.not_8M
	CMPi.b	#$67,(SP)
	Bne.s	.not_7
; cache instruction on.
	MOVE.l	CacheControl,-(SP)
	ORi.l	#$9,(SP)
	Bsr	setCaches
	ADDq	#6,SP
	RTE
.not_7
	CMPi.b	#$68,(SP)
	Bne.s	.not_8
; cache instruction off.
	MOVE.l	CacheControl,-(SP)
	ANDi.l	#$FFFFFFFE,(SP)
	Bsr	setCaches
	ADDq	#6,SP
	RTE
.not_8
	CMPi.b	#$6A,(SP)
	Bne.s	.not_4
; cache donn‚e on.
	MOVE.l	CacheControl,-(SP)
	ORi.l	#$900,(SP)
	Bsr	setCaches
	ADDq	#6,SP
	RTE
.not_4
	CMPi.b	#$6B,(SP)
	Bne.s	.not_5
; cache donn‚e off.
	MOVE.l	CacheControl,-(SP)
	ANDi.l	#$FFFFFEFF,(SP)
	Bsr	setCaches
	ADDq	#6,SP
	RTE
.not_5
	CMPi.b	#$65,(SP)
	Bne.s	.not_slash
; sp‚cial, g‚nŠre une crash page.
	ADDq	#2,SP
	MOVE.l	#$12345678,$380.w
	MOVEm.l	A0-A7/D0-D7,$384.w
	MOVE.b	#1,$3C4.w
	MOVE.l	A0,-(SP)
	MOVE.l	USP,A0
	MOVE.l	A0,$3C8.w
	MOVE.l	(SP)+,A0
	MOVE.l	(SP),$3CC.w
	MOVE.l	(4.w,SP),$3D0.w
	MOVE.l	(8.w,SP),$3D4.w
	MOVE.l	(12.w,SP),$3D8.w
	MOVE.l	(16.w,SP),$3DC.w
	MOVE.l	(20.w,SP),$3E0.w
	MOVE.l	(24.w,SP),$3E4.w
	MOVE.l	(28.w,SP),$3E8.w
	RTE
.not_slash
	CMPi.b	#$66,(SP)
	Bne.s	.not_star
; toggle 60/50Hz.
	MOVE	D0,-(SP)
	MOVE.b	$FFFF820A.w,D0
	EORi.b	#2,D0
	MOVE.b	D0,$FFFF820A.w
	MOVE	(SP)+,D0
	ADDq	#2,SP
	RTE
.not_star
	CMPi.b	#$53,(SP)
	Bne.s	.not_del
; reset.
	MOVE	#$2700,SR
	JMP	([4.W])
.not_del
; gestion du volume.
	CMPi.b	#$4A,(SP)
	Bne.s	.not_minus
	CMPi	#$0FF0,$FFFF893A.w
	Beq.s	.no_down
	ADDi	#$0110,$FFFF893A.w
.no_down
	ADDq	#2,SP
	RTE
.not_minus
; gestion du volume.
	CMPi.b	#$4E,(SP)
	Bne.s	.not_plus
	TST	$FFFF893A.w
	Beq.s	.no_up
	SUBi	#$0110,$FFFF893A.w
.no_up
.not_plus
	ADDq	#2,SP
	RTE

.key_released
; touche relach‚e.
	CMPi.b	#$9D,(SP)
	Bne.s	.not_rcontrol
; contr“le lach‚e.
	ANDi	#$FFFE,BackKey
	ADDq	#2,SP
	RTE
.not_rcontrol
	CMPi.b	#$B8,(SP)
	Bne.s	.not_ralternate
; alternate lach‚e.
	ANDi	#$FFFD,BackKey
	ADDq	#2,SP
	RTE
.not_ralternate
; on ignore les autres touches.
	ADDq	#2,SP
	RTE

;__________________________
;[ Sous-routines diverses ]
;[________________________]

Install_Handler
; installe un gestionnaire sp‚cial.
; en paramŠtre nø vecteur, exception.
	MOVEm.l	A0-A1/D0-D1,-(SP)
	CARGS	#16,NOVEC1.w,VECT1.l
	MOVE	(NOVEC1.w,SP),D0
	MOVEa.l	([_Exc_Table.w,PC],D0.w*4),A1
; on v‚rifie qu'il n'est pas d‚ja l….
	MOVE.l	([VECT1.w,SP],-8.w),D1
.search_xbra	
	CMPi.l	#'XBRA',(-12.w,A1)	; XBRA ?
	Bne.s	.end_search
	CMP.l	(-8.w,A1),D1		; meme ID ?
	Beq.s	.found
	TST.l	(-4.w,A1)
	Beq.s	.end_search		; vecteur null suivant ?
	MOVEa.l	(-4.w,A1),A1
	Bra.s	.search_xbra
.end_search
	MOVEa.l	(VECT1.w,SP),A1	
	MOVEa.l	(_Exc_Table.w,PC),A0
	MOVE.l	(A0,D0.w*4),(-4.w,A1)	; on copie l'ancien vecteur.
	MOVE.l	A1,(A0,D0.w*4)		; on met le nouveau.
.found
	MOVEm.l	(SP)+,A0-A1/D0-D1
	RTS

Install_Patch
; installe un patch systŠme, le mˆme qu'avant sauf
; qu'on utilise la table 68000.
; en paramŠtre nø vecteur, exception.
	MOVEm.l	A1/D0-D1,-(SP)
	CARGS	#12,NOVEC2.w,VECT2.l
	MOVE	(NOVEC2.w,SP),D0
; on v‚rifie qu'il n'est pas d‚ja l….
	MOVEa.l	(ZA0,D0.w*4),A1
	MOVE.l	([VECT2.w,SP],-8.w),D1
.search_xbra
	CMPi.l	#'XBRA',(-12.w,A1)	; XBRA ?
	Bne.s	.end_search
	CMP.l	(-8.w,A1),D1		; meme ID ?
	Beq.s	.found
	TST.l	(-4.w,A1)
	Beq.s	.end_search		; vecteur null suivant ?
	MOVEa.l	(-4.w,A1),A1
	Bra.s	.search_xbra
.end_search
	MOVEa.l	(VECT2.w,SP),A0
	MOVE.l	(ZA0,D0.w*4),(-4.w,A0)	; on copie l'ancien vecteur.
	MOVE.l	A0,(ZA0,D0.w*4)		; on met le nouveau.
.found
	MOVEm.l	(SP)+,A1/D0-D1
	RTS

Remove_Handler
; enlŠve un gestionnaire d'exception.
; en paramŠtre nø vect, exception.
	MOVEm.l	A1-A2/D0-D1,-(SP)
	CARGS	#16,NOVEC3.w,VECT3.l
	MOVE	(NOVEC3.w,SP),D0
	LEa.l	([_Exc_Table.w,PC],D0.w*4),A2	; o— se trouve le vect.
	MOVE.l	([VECT3.w,SP],-8.w),D0	; identifieur.
	MOVEA.l	(A2),A1
; on v‚rifie qu'il est d‚ja l….
.search_xbra
	CMPi.l	#'XBRA',(-12.w,A1)	; XBRA ?
	Bne.s	.end_search
	CMP.l	(-8.w,A1),D0		; meme ID ?
	Beq.s	.found
	TST.l	(-4.w,A1)
	Beq.s	.end_search		; vecteur null suivant ?
	LEa	(-4.w,A1),A2		; position ant‚rieure.
	MOVEa.l	(A2),A1
	Bra.s	.search_xbra
.found
; on l'enlŠve de la chaŒne.
	MOVE.l	(-4.w,A1),(A2)	
	CLR.l	(-4.w,A1)		; marqu‚ comme libre.
.end_search
; pas trouv‚ ?
	MOVEm.l	(SP)+,A1-A2/D0-D1
	RTS

Remove_Patch
; enlŠve un gestionnaire d'exception.
; en paramŠtre nø vect, exception.
	MOVEm.l	A1-A2/D0-D1,-(SP)
	CARGS	#16,NOVEC4.w,VECT4.l
	MOVE	(NOVEC4.w,SP),D0
	LSL	#2,D0			; num *4 (offset).
	MOVEa	D0,A2			; o— se trouve le vect.
	MOVEA.l	(A2),A1
	MOVE.l	([VECT3.w,SP],-8.w),D0	; identifieur.
; on v‚rifie qu'il est d‚ja l….
.search_xbra
	CMPi.l	#'XBRA',(-12.w,A1)	; XBRA ?
	Bne.s	.end_search
	CMP.l	(-8.w,A1),D0		; meme ID ?
	Beq.s	.found
	TST.l	(-4.w,A1)
	Beq.s	.end_search		; vecteur null suivant ?
	LEa	(-4.w,A1),A2		; position ant‚rieure.
	MOVEa.l	(A2),A1
	Bra.s	.search_xbra
.found
; on l'enlŠve de la chaŒne.
	MOVE.l	(-4.w,A1),(A2)	
	CLR.l	(-4.w,A1)		; marqu‚ comme libre.
.end_search
; pas trouv‚ ?
	MOVEm.l	(SP)+,A1-A2/D0-D1
	RTS

Get_CJar
; r‚cupŠre la cookie-jar
	MOVEM.l	A1-A3/D1-D3,-(SP)
	PEA	.GET_COOKIE(PC)
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
	MOVE.l	4(A0),D1
	MOVEQ	#0,D0
.error
	MOVEM.l	(SP)+,A0/D2-D3
	TST.l	D0
	RTS

Write_Cookie
; crit le Cookie D0,D1.
; Retourne l'ancienne valeur en D1.
	MOVEm.l	A0/D2-D3,-(SP)
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
	MOVE.l	4(A0),D0
	MOVE.l	D1,4(A0)
	MOVE.l	D0,D1
	MOVEQ	#0,D0
.error
	MOVEm.l	(SP)+,A0/D2-D3
	TST.l	D0
	RTS

Create_Cookie
; CrŠe un Cookie D0,D1.
	MOVEm.l	A0/D2-D3,-(SP)
	MOVE.l	D0,D2
	MOVE.l	D1,D3
	BSR.s	Write_Cookie
	BPL.s	.error
	MOVE.l	D3,D1
	BSR	Get_CJar
	BMI.s	.error
	MOVEq	#1,D0
.next_cookie
	TST.l	(A0)
	BEQ.s	.end
	ADDq	#1,D0
	ADDq	#8,A0
	BRA.s	.next_cookie
.end
	CMP.l	4(A0),D0
	BCC.s	.full
	MOVE.l	D2,(A0)+
	MOVE.l	(A0),D0
	MOVE.l	D1,(A0)+
	CLR.l	(A0)+
	MOVE.l	D0,(A0)
	MOVEq	#0,D0
	BRA.s	.error
.full
	MOVEq	#ER_JARFUL,D0
.error
	MOVEm.l	(SP)+,A0/D2-D3
	TST.l	D0
	RTS

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

; installe les pr‚f‚rences.
Do_Prefs
	MOVEm.l	A0-A1,-(SP)
; IDE on/off et logo on/off
	JSR	PMMUVROMON
; logo on/off.
	CMPi	#$401,$E00002
	Beq.s	.tos_401
	CMPi	#$402,$E00002
	Bne.s	.not_tos_402
.tos_401
	LEA	$E00638,A0
	LEA	$E00AE4,A1
	Bra.s	.address_ok
.not_tos_402
	CMPi	#$404,$E00002
	Bne.s	.end_roms
	LEA	$E00642,A0
	LEA	$E00B22,A1
.address_ok
	MOVE	#$41F8,(A0)
	TST.b	curConfig+pLogo
	Beq.s	.with_logo
	MOVE	#$605E,(A0)
.with_logo
	MOVE.l	#$42790000,(A1)
	TST.b	curConfig+pIDE
	Beq.s	.with_IDE
	MOVE.l	#$31FC0001,(A1)
.with_IDE
.end_roms
	JSR	PMMUVROMOFF
	MOVEm.l	(SP)+,A0-A1
	RTS

; fixe les pr‚f‚rences.
Set_Prefs
	MOVEm.l	A0-A6/D0-D7,-(SP)
	CARGS	#60,PREFS.l
	MOVEa.l	(PREFS.w,SP),A6
	MOVE.b	(Logo.w,A6),defConfig+pLogo
	MOVE.b	(IDE.w,A6),defConfig+pIDE
; type d'‚cran.
	MOVE.b	(Multiscan.w,A6),defConfig+pScreen
; recopie en courante.
	MOVE.b	(defConfig+pLogo.w,PC),curConfig+pLogo
	MOVE.b	(defConfig+pIDE.w,PC),curConfig+pIDE
	MOVE.b	(defConfig+pScreen.w,PC),curConfig+pScreen
	Bsr	Do_Prefs
	PEA	(defConfig.w,PC)
	PEA	(A6)
	Bsr	Set_Config
	ADDq	#8,SP
	CHECKREGISTER
	Sne	fRegister
; Copie le nom.
	LEA	(UName.w,A6),A0
	LEA	(UserName.w,PC),A1
	MOVEq	#33,D0
.copy_string
	MOVE.b	(A0)+,(A1)+
	DBf	D0,.copy_string
	CLR.b	(A1)+
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

; tente de reconnaŒtre le disque.
Recon_Disk
	MOVEm.l	A0-A6/D1-D7,-(SP)
; checksum1.
	MOVEa.l	_dskbufp.w,A0
	MOVEq	#63,D0
	MOVEq	#0,D1
.loop1
	ADD.l	(A0)+,D1
	DBF	D0,.loop1
; checksum2.
	MOVEa.l	_dskbufp.w,A0
	MOVEq	#63,D0
	MOVEq	#0,D2
.loop2
	MOVE.l	(A0)+,D3
	EOR.l	D3,D2
	DBF	D0,.loop2
; checksum3
	MOVEa.l	_dskbufp.w,A0
	MOVEq	#63,D0
	MOVEq	#0,D3
.loop3
	ROL.l	D0,D3
	ADD.l	(A0)+,D3
	DBF	D0,.loop3
; Ok, on a les trois cl‚ dans D1,d2,d3
	MOVE	(curConfig+_lib_size.w,PC),D0
	SUBq	#1,D0
	MOVEa.l	(curConfig+_library.w,PC),A0
.search_disk
	CMP.l	(Chk1.w,A0),D1
	Bne.s	.not_good
	CMP.l	(Chk2.w,A0),D2
	Bne.s	.not_good
	CMP.l	(Chk3.w,A0),D3
	Bne.s	.not_good
; trouv‚.
	PEA	(curConfig.w,PC)
	PEA	(Config.w,A0)
	Bsr	Set_Config
	ADDq	#8,SP
; affiche le nom.
	LEA	(pathBuffer.w,PC),A1
	LEA	(Name.w,A0),A2
	REPT	8
	MOVE.l	(A2)+,(A1)+
	ENDR
	CLR.b	(A1)
	MOVEq	#0,D0
	Bra.s	.found
.not_good
	ADDa	#SIZEDISK,A0
	DBf	D0,.search_disk
	MOVEq	#1,D0
.found
	MOVEm.l	(SP)+,A0-A6/D1-D7
	RTS

	SECTION	DATA
; Zone de configuration par d‚faut puis courante.
curConfig
	DS.b	CONFIG_SIZE
	EVEN

defConfig
	DC	VERNUM
	DC.l	0		; Pointeur Config.
	DC.l	0		; installation.
	DC.l	0		; bibliothŠque.
	DC	0		; taille bib.
	DC	0		; taille max.
	DC.l	0		; programme shell.
	DS.l	3		; rŠs.
	DC.l	$3111		; caches.
	DC.b	3		; taille mem.
	DC.b	-1		; patch TOS.
	DC.b	2		; bus mode.
	DC.b	-1		; fr‚qu.
	DC.b	-1		; video boot.
	DC.b	0		; type d'‚cran.
	DC.b	-1		; disque dur.
	DC.b	-1		; GEM
	DC.b	0		; HP.
	DC.b	0		; Logo
	DC.b	0		; IDE
	Ds.b	10
	EVEN

nulConfig
	DC	VERNUM
	DC.l	0		; Pointeur Config.
	DC.l	0		; installation.
	DC.l	0		; bibliothŠque.
	DC	0		; taille bib.
	DC	0		; taille max.
	DC.l	0		; programme shell.
	DS.l	3		; rŠs.
	DC.l	$3111		; caches.
	DC.b	3		; taille mem.
	DC.b	0		; patch TOS.
	DC.b	0		; bus mode.
	DC.b	-1		; fr‚qu.
	DC.b	-1		; video boot.
	DC.b	0		; type d'‚cran.
	DC.b	-1		; disque dur.
	DC.b	-1		; GEM
	DC.b	-1		; HP.
	DC.b	0		; Logo
	DC.b	0		; IDE
	Ds.b	10
	EVEN
;________________________
;[ Donn‚es pour l'‚cran ]
;[______________________]
; taille d'image en 50Hz (RGB/TV).
RGB_50	DC	$271,$265,$2F,$7F,$20F,$26B
RGB_60	DC	$20D,$201,$16,$4D,$1DD,$207
VGA_50	DC	$4E1,$3AF,$8F,$8F,$3AF,$471
VGA_60	DC	$419,$3AF,$8F,$8F,$3AF,$415

;___________________________
;[ Donn‚es pour le clavier ]
;[_________________________]
; nb d'octets … ignorer.
WaitTable
	Dc	7,5,2,2,2,2,6,0,1,1

Welcome	Dc.b	27,'pBackward III (V1.00) resident.',27,'q',10,13
	Dc.b	'½ 1993-95 Cyrille Dupuydauby.',10,13,10,13,0

Shareware
	Dc.b	27,'pPlease Remember that Backward III.',10,13
	Dc.b	    '          is Shareware.           ',27,'q',13,10,0
Wait_Text
	Dc.b	'Press a key to continue.',10,13,0

Registered
	DC.b	'Registered to:',0

Found_Text
	Dc.b	'Disk found :',0

Disable_Text
	Dc.b	10,13,'Disable emulator (y/n) ?',10,13,0

NL	DC.b	10,13,0

	EVEN
	SECTION	BSS

; Drapeaux divers
; flags pour la console.
finEsc	Ds.b	1
fInk	Ds.b	1
fPaper	Ds.b	1

; type d'affichage.
STmode	Ds.b	1

; flag patchs systŠmes on/off
fSystemPatch
	Ds.b	1
; flag enregistr‚ ou non.
fRegister
	Ds.b	1
; nom de l'utilisateur.
UserName
	Ds.b	35

	EVEN
; v‚ritable taille de la m‚moire.
trueMemtop	DS.l	1

;______________________
;[ Variables Internes ]
;[____________________]

; r‚sultat de la lecture de la disquette.
fbResult	Ds	1
recResult	Ds	1

; donn‚es temporaires pour Bitblt
bitblt_data	DS.b	76

; donn‚es temporaires pour l'AES.
AESparams	Ds.l	6
AEScontrol	Ds	5
AESintin	Ds	4
AESaddrin	Ds.l	2
AESaddrout	Ds.l	1
AESintout	Ds	1

; Pile interne.
_Stack		Ds.l	1
		Ds.b	8192		; 8Ko de pile doivent ˆtre suffisant.
Internal_Stack

; Adresse des variables LineA.
_Line_A		Ds.l	1

; ‚tat des caches
CacheControl	Ds.l	1

; Exceptions
;-----------
; Adresse de la table d'exceptions
_Exc_Table	Ds.l	1

Exc_Table	Ds.l	NB_EXC+1

; Variables pour les fonctions de fichiers.
;------------------------------------------
; tampon pour les calculs de cl‚.
prgBuffer	Ds.b	512
; Chemin
pathBuffer	Ds.b	256
;DTA
myDTA		DTA

; Variables pour le gestionnaire de clavier
;------------------------------------------
; Octets … sauter.
WaitCount	Ds	1
; Etats des touches ALT et CTRL
BackKey		Ds	1

