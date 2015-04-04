;********************************************************
;*							*
;*	BackwardIII¿, ‚mulateur ST pour Falcon		*
;*		gestionnaire de bibliothŠque		*
;*			V 1.00				*
;*		par C.Dupuydauby	1993-94-95	*
;*							*
;********************************************************

;	OPT	X+

; d‚clarer SWD pour avoir une version su‚doise.
SWD
; Taille minimale de la fenetre.
WA_MINW	=	128
WA_MINH	=	72

; Type de fichier.
; sp‚cial si suŠde.

	;OUTPUT	.APP
	
	OUTPUT	BACKSWE.APP

	INCLUDE	CONFIG.SYM


CHECKREGISTER	MACRO
; en sortie D0 vaut 0 si non enregistr‚e.
	MOVEm.l	A0-A1/D1-D2,-(SP)
	LEA	(cur_config+UName.w,PC),A0
	LEA	(cur_config+UKey.w,PC),A1
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

; En tete RSC.
	INCLUDE	BCKWUSA.SYM

	SECTION	TEXT
; Code de d‚marrage.
	MOVEa.l	(4.w,SP),A6
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
	Bsr	main

	CLR	-(SP)
	MOVE	#$4C,-(SP)
	TRAP	#1		;Pterm

main
; programme principal.
; ouverture d'une app. AES.
	Bsr	appl_init
	MOVE	D0,appl_id
; graf handle.
	LEA	(char_rec.w,PC),A1
	Bsr	graf_handle
	MOVE	D0,work_handle

; partie sp‚cifique SuŠde
	IFD SWD
	LEA	(SWE_RSC.w,PC),A0	;SuŠde par d‚faut.
	Bsr	rsrc_load	;load rsc file.
	TST.l	D0		;rsc charg‚ ?
	Bne.s	.rsc_loaded
	ENDC

; lecture du cookie du pays.
	MOVE.l	#'_AKP',D0
	BSR	Read_Cookie	;cookie pays ?
	TST.l	D0
	Bne.s	.NOT_FIND	;pas trouv‚.
	ANDi.l	#$F00,D1
	LSR	#8,D1
	MOVE	D1,D0
	MOVE	D0,country_flag
	Bra.s	.country_good

.NOT_FIND
	MOVEq	#0,D0		;par d‚faut USA.
.country_good
	ifd SWD
	LEA	(SWE_RSC.w,PC),A0
	Bsr	rsrc_load
	Bne.s	.file_ok
	endc
	ADD	D0,D0
	ADD	D0,D0
	LEA	(RSC_NAME.w,PC),A0
	TST.l	(A0,D0)		;nom d‚fini ?
	Beq.s	.usafile
	MOVEa.l	(A0,D0),A0	;A0 pointe sur le nom de fichier.
; chargement du RSC.
	Bsr	rsrc_load	;load rsc file.
	Bne.s	.file_ok
.usafile
	MOVEa.l	RSC_NAME(PC),A0	;USA par d‚faut.
	Bsr	rsrc_load	;load rsc file.
.file_ok

	TST.l	D0		;rsc charg‚ ?
	Bne.s	.rsc_loaded
; pas de fichier RSC.
; souris en flŠche.
	MOVEq	#0,D0
	BSR	graf_mouse
	LEA	NO_RSC(PC),A0
	MOVEq	#1,D0
	Bsr	form_alert	;alert 'not found'.
	Bra.s	.end_app

.rsc_loaded
; on ouvre une station.
	LEA	(VDI_WKST.w,PC),A0
	LEA	(work_out.w,PC),A1
	MOVEq	#1,D0
	Bsr	v_opnvwk
	MOVE	D0,vdi_handle
	Bsr	Startapp
; on referme la station.
	MOVE	(vdi_handle.w,PC),D0
	Bsr	v_clsvwk
; lib‚ration du rsc.
	Bsr	rsrc_free
; fin d'application.
.end_app
	Bsr	appl_exit
	RTS

Startapp
; Est-ce un Falcon ?
	Bsr	Test_Falcon
	TST.l	D0
	Beq.s	.falcon_ok
; pas de triche.
	MOVEq	#R_STRING,D0
	MOVEq	#NOT_A_FALCON,D1
	Bsr	rsrc_gaddr
; alerte pas falcon.
	MOVEq	#1,D0
	Bsr	form_alert
	RTS

.falcon_ok
; lecture du cookie Backward
	MOVE.l	#'BCKW',D0
	BSR	Read_Cookie
	MOVE.l	D1,_infos
; initialisations.
	MOVE	#-1,selconf
; on charge la configuration par d‚faut.
	LEA	(cur_config.w,PC),A0
	Bsr	Load_Config
	TST.l	D0
	Beq.s	.load_ok
; on restaure la configuration preset.
	LEA	(DEFAULT_CONFIG.w,PC),A0
	LEA	(cur_config.w,PC),A1
	BSR	Copy_Config
.load_ok
	LEA	(cur_config.w,PC),A0
	LEA	(DEFAULT_CONFIG.w,PC),A1
	BSR	Copy_Config
; On initialise le RSC.
	BSR	Init_Rsc

; On charge la librairie
	BSR	Load_Library
	TST.l	D0
	Beq.s	.lib_ok
; souris en flŠche.
	MOVEq	#0,D0
	Bsr	graf_mouse
	MOVEq	#10,D0
	Bsr	form_error
	RTS

.lib_ok
; on installe le menu.
	MOVEq	#R_TREE,D0
	MOVEq	#MENU,D1
	Bsr	rsrc_gaddr
	MOVE.l	A0,menutree
	Bsr	menu_bar

	St	Flag_Registered
	CHECKREGISTER
	TST.b	D0
	Bne.s	.ok
	Sf	Flag_Registered
	Bsr	PRINT_INFO
.ok
; on crŠe la fenetre pour la librairie.
	LEA	(screen_rec.w,PC),A1
	MOVEq	#0,D0
	MOVEq	#WF_WORKXYWH,D1
	Bsr	wind_get		;taille de l'‚cran.
	MOVE	#%000111111101,D0
	LEA	(screen_rec.w,PC),A1
	Bsr	wind_create		;cr‚ation de la fenetre.
	MOVE	D0,whandle
	LEA	(EMPTY.w,PC),A0
	LEA	(dum_rec.w,PC),A1
	MOVE.l	A0,(A1)
	MOVE	whandle(PC),D0
	MOVEq	#WF_INFO,D1
	Bsr	wind_set		;barre d'infos vide.
	CLR	wconfig
	Bsr	Win_Slider		;calcul du slide.
	Bsr	Win_Title

; on scan le disque.
	Bsr	Read_Disk
	Bsr	Scan_Lib
	MOVE	D0,-(SP)
	LEA	(dum_rec.w,PC),A0
	LEA	(screen_rec.w,PC),A1	;on la r‚duit un peu.
	MOVE	(A1)+,D0
	ADDi	#20,D0
	MOVE	D0,(A0)+
	MOVE	(A1)+,D0
	ADDi	#20,D0
	MOVE	D0,(A0)+
	MOVE	(A1)+,D0
	SUBi	#40,D0
	MOVE	D0,(A0)+
	MOVE	(A1)+,D0
	SUBi	#40,D0
	MOVE	D0,(A0)+
	LEA	dum_rec(PC),A1
	MOVE	whandle(PC),D0
	BSR	wind_open		;ouverture.
	MOVE	(SP)+,D0	
	BSR	New_Selected

.wait_msg
; event multi.
	LEA	msg_buffer(PC),A0
	LEA	screen_rec(PC),A1
	LEA	screen_rec(PC),A2
	MOVEq	#%010011,D0		;attente message+clic+kbd.
	MOVEq	#2,D1			;2 clics max.
	MOVEq	#%01,D2			;bout. gauche.
	MOVEq	#%11,D3			;d‚cl. enfonc‚.
	MOVEq	#0,D4			;dummy. (zone1)
	MOVEq	#0,D5			;dummy. (zone2)
	MOVEq	#1,D5			;timer (1ms).
	BSR	evnt_multi
; Raccourci clavier ?
	LEA	msg_buffer(PC),A6
	MOVE	D0,D7
	BTST	#4,D7
	BNE	.not_kbd		;pas de clavier si message.
	BTST	#0,D7
	BEQ	.not_kbd
.not_return
	CMPi.b	#' ',D5
	BNE.s	.notspace
	MOVE	#M_RESCAN,8(A6)
	BRA	.simulmenu
.notspace
	ANDi	#$FFDF,D5		;Tout majuscule ?
	CMPi.b	#'A',D5
	BCS	.not_alpha
	CMPi.b	#'Z'+1,D5
	BCC	.wait_msg
; L'utilisateur a press‚ une touche alpha.
	MOVEa.l	_libmem(PC),A0
	MOVEq	#0,D0
.search
	CMP.b	Name(A0),D5
	BLS.s	.found
	LEA	SIZEDISK(A0),A0
	CMP	nbconfig(PC),D0
	BCC	.wait_msg
	ADDq	#1,D0
	BRA.s	.search
.found
	MOVE	D0,wconfig
	BSR	Adjust_Win		;on fixe l'affichage.
	BSR	Draw_Window
	BRA	.not_kbd
.not_alpha
	CMPi.b	#$9,D5
	BNE.s	.not_tab
	MOVE	#M_ABOUT,8(A6)
	BRA.s	.simulmenu
.not_tab
	CMPi	#$3B00,D5
	BNE.s	.not_f1
	MOVE	#M_BESTC,8(A6)
	BRA	.simulmenu
.not_f1
	CMPi	#$3C00,D5
	BNE.s	.not_f2
	MOVE	#M_INTERC,8(A6)
	BRA	.simulmenu
.not_f2
	CMPi	#$3D00,D5
	BNE.s	.not_f3
	MOVE	#M_MINC,8(A6)
	BRA	.simulmenu
.not_f3
	BRA	.not_kbd
.simulmenu
	BCLR	#0,D7
	BSET	#4,D7
	MOVE	#MN_SELECTED,(A6)
.not_kbd
	BTST	#4,D7
	BEQ	.not_msg
	LEA	msg_buffer(PC),A6
; s‚lection menu ?
	CMPi	#MN_SELECTED,(A6)
	BNE	.not_menu
	MOVEa.l	menutree(PC),A0
	MOVE	(6.w,A6),D0
	MOVEq	#1,D1
	BSR	menu_tnormal	;remise normal du menu
; quitter ?
	CMPi	#M_QUIT,8(A6)
	BEQ	.end_app
	CMPi	#M_ABOUT,8(A6)
	BNE.s	.not_info
	BSR	PRINT_INFO
.not_info
	CMPi	#M_CONFIG,8(A6)
	Bne.s	.not_config
	BSR	Configuration
	Bra	.not_msg
.not_config
	CMPi	#M_SV_DEF,8(A6)
	BNE.s	.not_save
	BSR	SaveDefault
	BRA	.not_msg
.not_save
	CMPi	#M_ADD,8(A6)
	BNE.s	.not_add
	BSR	New_Disk
	BRA	.not_msg
.not_add
	CMPi	#M_REMOVE,8(A6)
	BNE.s	.not_remove
	BSR	Remove_Selected
	BSR	Draw_Window
	BRA	.not_msg
.not_remove
	CMPi	#M_SAVED,8(A6)
	BNE.s	.not_save_dat
	BSR	Save_Library
	BRA	.not_msg
.not_save_dat
	CMPi	#M_RESCAN,8(A6)
	BNE.s	.not_rescan
	BSR	Read_Disk
	BSR	Scan_Lib
	BSR	New_Selected
	BSR	Draw_Window
	BRA	.not_msg
.not_rescan
; Configurations pr‚r‚gl‚es.
	CMPi	#M_BESTC,8(A6)
	Bne.s	.not_bestc
	LEA	BEST_CONFIG(PC),A0
	Bsr	Preset_Config
	BRA	.not_msg
.not_bestc
	CMPi	#M_INTERC,8(A6)
	BNE.s	.not_interc
	LEA	INTER_CONFIG(PC),A0
	Bsr	Preset_Config
	BRA	.not_msg
.not_interc
	CMPi	#M_MINC,8(A6)
	BNE.s	.not_minc
	LEA	MIN_CONFIG(PC),A0
	Bsr	Preset_Config
	BRA	.not_msg
.not_minc
	CMPi	#M_REGISTER,8(A6)
	BNE.s	.not_register
	BSR	Register
	BRA	.not_msg
.not_register
	CMPi	#M_OTHERS,8(A6)
	Bne.s	.not_others
	BSR	OtherOptions
	BRA	.not_msg
.not_others
	BRA	.not_msg

.not_menu
; message pour fenetre.
	CMPi	#WM_REDRAW,(A6)
	BNE	.not_wredr
	MOVE	whandle(PC),D0		;redessin ?
	CMP	6(A6),D0
	BNE	.not_msg
	LEA	8(A6),A6
	BSR	Redraw_Window
	BRA	.not_msg

.not_wredr
	CMPi	#WM_TOPPED,(A6)
	BEQ.s	.topped			;nouvelle top ?
	CMPi	#WM_NEWTOP,(A6)
	BNE.s	.not_topped
.topped
	MOVE	whandle(PC),D0
	CMP	6(A6),D0
	BNE	.not_msg
	MOVEq	#WF_TOP,D1
	BSR	wind_set		;oui.
	BRA	.not_msg
.not_topped
	CMPi	#WM_FULLED,(A6)
	BNE.s	.not_fulled		;boutton full ?
	MOVE	whandle(PC),D0
	CMP	6(A6),D0
	BNE	.not_msg
	LEA	dum_rec(PC),A1
	MOVEq	#WF_CURRXYWH,D1		;coord. actuelles.
	BSR	wind_get
	LEA	screen_rec(PC),A2
	CMPm.l	(A1)+,(A2)+
	BNE.s	.not_full
	CMPm.l	(A1)+,(A2)+		;plein ‚cran ?
	BEQ.s	.full
.not_full
	LEA	screen_rec(PC),A1	;non.
	BRA.s	.ful_cont
.full
	LEA	dum_rec(PC),A1		;oui.
	MOVE	whandle(PC),D0
	MOVEq	#WF_PREVXYWH,D1
	BSR	wind_get		;anciennes coord.
.ful_cont
	MOVE	whandle(PC),D0
	MOVEq	#WF_CURRXYWH,D1
	BSR	wind_set		;on fixe les coord.
	BSR	Adjust_Win		;on fixe l'affichage.
	BSR	Win_Slider		;m.….j. du slider.
	BRA	.not_msg
.not_fulled
	CMPi	#WM_SIZED,(A6)
	BNE.s	.not_sized		;chang. taille ?
	MOVE	whandle(PC),D0
	CMP	6(A6),D0
	BNE	.not_msg		;oui.
	LEA	8(A6),A1		;nouveau rec.
	CMPi	#WA_MINW,4(A1)
	BCC.s	.width_ok
	MOVE	#WA_MINW,4(A1)
.width_ok
	CMPi	#WA_MINH,6(A1)
	BCC.s	.heigh_ok		;au dessus du min ?
	MOVE	#WA_MINH,6(A1)
.heigh_ok
	MOVEq	#WF_CURRXYWH,D1
	BSR	wind_set		;on fixe le nouveau rec.
	BSR	Adjust_Win		;on fixe l'affichage.
	BSR	Win_Slider		;m.….j. du slider.
	BRA	.not_msg
.not_sized
	CMPi	#WM_MOVED,(A6)
	BNE.s	.not_moved
	MOVE	whandle(PC),D0
	CMP	6(A6),D0
	BNE	.not_msg		;oui.
	LEA	8(A6),A1		;nouveau rec.
	MOVEq	#WF_CURRXYWH,D1
	BSR	wind_set		;on fixe le nouveau rec.
	BRA	.not_msg
.not_moved
	CMPi	#WM_ARROWED,(A6)
	BNE	.not_arrowed		;clic flŠches ?
	MOVE	whandle(PC),D0
	CMP	6(A6),D0
	BNE	.not_msg
	MOVE	8(A6),D0
	CMPi	#WA_UPPAGE,D0
	BNE.s	.not_uppage
	BSR	Win_Lines
	MOVE	wconfig(PC),D1
	SUB	D0,D1
	MOVE	D1,wconfig
	BSR	Adjust_Win		;on fixe l'affichage.
	BSR	Draw_Window
	BRA	.not_msg
.not_uppage
	CMPi	#WA_DNPAGE,D0
	BNE.s	.not_dnpage
	BSR	Win_Lines
	MOVE	wconfig(PC),D1
	ADD	D0,D1
	MOVE	D1,wconfig
	BSR	Adjust_Win		;on fixe l'affichage.
	BSR	Draw_Window
	BRA	.not_msg
.not_dnpage
	CMPi	#WA_UPLINE,D0
	BNE.s	.not_upline
	MOVE	wconfig(PC),D1
	SUBq	#1,D1
	MOVE	D1,wconfig
	BSR	Adjust_Win		;on fixe l'affichage.
	BSR	Draw_Window
	BRA	.not_msg
.not_upline
	CMPi	#WA_DNLINE,D0
	BNE.s	.not_dnline
	BSR	Win_Lines
	MOVE	wconfig(PC),D1
	ADDq	#1,D1
	MOVE	D1,wconfig
	BSR	Adjust_Win		;on fixe l'affichage.
	BSR	Draw_Window
	BRA	.not_msg
.not_dnline
.not_arrowed
	CMPi	#WM_VSLID,(A6)
	BNE.s	.not_slide
	MOVE	whandle(PC),D0
	CMP	6(A6),D0
	BNE	.not_msg
	MOVE	8(A6),D7
	MOVE	nbconfig(PC),D1
	BSR	Win_Lines
	SUB	D0,D1
	BLE.s	.not_slide
	MULu	D1,D7
	DIVu	#1000,D7
	MOVE	D7,wconfig
	BSR	Draw_Window
	BRA	.not_msg
.not_slide
	BRA	.not_msg
.not_msg
	BTST	#1,D7
	BEQ	.not_button
; gestion des clics souris.
	MOVE	D1,D0
	MOVE	D2,D1
	MOVE	D1,D5
	BSR	wind_find
	CMP	whandle(PC),D0
	BNE.s	.not_my_window
	LEA	dum_rec(PC),A1
	MOVEq	#WF_WORKXYWH,D1
	BSR	wind_get
	SUB	2(A1),D5
	EXT.l	D5
	DIVu	char_rec+2(PC),D5
	ADD	wconfig(PC),D5
	CMP	nbconfig(PC),D5
	BCS.s	.ok_sel
	MOVEq	#-1,D5
.ok_sel
	MOVE	D5,D0
	BRA.s	.end_clic

.not_my_window
	MOVEq	#-1,D0
.end_clic
	MOVE	D0,D5
	BSR	New_Selected
	BSR	Draw_Window
	CMPi	#-1,D5
	BEQ	.not_button
	CMPi	#2,D6
	Bne.s	.not_button
	Bsr	Configuration
.not_button
	Bra	.wait_msg

.end_app
	MOVEq	#R_STRING,D0
	MOVEq	#AL_QUIT,D1
	BSR	rsrc_gaddr
; alerte quitter ?
	MOVEq	#1,D0
	BSR	form_alert
	CMPI	#1,D0
	BNE	.wait_msg
	MOVE	whandle(PC),D0
	BSR	wind_close
	MOVE	whandle(PC),D0
	BSR	wind_delete
; lib‚ration de la m‚moire.
	MOVE.l	_libmem,-(SP)
	MOVE	#$49,-(SP)
	TRAP	#1
	ADDq	#6,SP
	RTS

PRINT_INFO
; Affiche la boite d'info.
	MOVEq	#INFO,D0
	MOVEq	#-1,D1
	BSR	form_use
	RTS

Register
; Enregistre l'utilisateur.
	MOVEm.l	A0-A6/D0-D7,-(SP)
	MOVEq	#REGISTER,D0
	MOVEq	#RE_NAME,D1
	BSR	form_use
	MOVeq	#REGISTER,D1
	MOVEq	#R_TREE,D0
	BSR	rsrc_gaddr
	MOVEa.l	A0,A6
	LEA	RE_NAME*size_OBJECT(A6),A0	;adresse du nom.
	MOVEa.l	ob_spec(A0),A0
	MOVEa.l	te_ptext(A0),A0
	MOVEa.l	A0,A2
	MOVEq	#31,D0
.loop2
	TST.b	(A2)+
	DBEQ	D0,.loop2
	TST	D0
	BMI.s	.end_string
.clear
	CLR.b	(A2)+
	DBF	D0,.clear
.end_string
	MOVEq	#0,D0
	REPT	8
	MOVE.l	(A0)+,D1
	EOR.l	D1,D0
	ENDR
	BEQ	.wrong_code
	EOR.l	#KEY,D0				;cl‚ calcul‚e.
	LEA	RE_CODE*size_OBJECT(A6),A0	;adresse du nom.
	MOVEa.l	ob_spec(A0),A0
	MOVEa.l	te_ptext(A0),A0
	MOVEq	#0,D2
	REPT	7
	MOVE.b	(A0)+,D1
	ANDi	#$F,D1
	OR.b	D1,D2
	LSL.l	#4,D2
	ENDR					;cl‚ entr‚e.
	MOVE.b	(A0)+,D1
	ANDi	#$F,D1
	OR.b	D1,D2
	CMP.l	D0,D2
	BNE	.wrong_code
; On installe le nom et le code
	LEA	RE_NAME*size_OBJECT(A6),A0	;adresse du nom.
	MOVEa.l	ob_spec(A0),A0
	MOVEa.l	te_ptext(A0),A0
	LEA	(cur_config+UName.w,PC),A1
	REPT	32
	MOVE.b	(A0)+,(A1)+
	ENDR
	CLR.b	(A1)+
	LEA	RE_CODE*size_OBJECT(A6),A0	;adresse du nom.
	MOVEa.l	ob_spec(A0),A0
	MOVEa.l	te_ptext(A0),A0
	LEA	(cur_config+UKey.w,PC),A1
	REPT	8
	MOVE.b	(A0)+,(A1)+
	ENDR
	CLR.b	(A1)+
; Sauver l'enregistrement.
	LEA	(cur_config.w,PC),A0
	BSR	Save_Config
	MOVEq	#ARROW,D0
	BSR	graf_mouse
	MOVEq	#R_STRING,D0
	MOVEq	#AL_REGISTERED,D1
	BSR	rsrc_gaddr
	MOVEq	#1,D0
	BSR	form_alert
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

.wrong_code
	MOVEq	#AL_WRONGCODE,D1
	MOVEq	#R_STRING,D0
	BSR	rsrc_gaddr
	MOVEq	#1,D0
	BSR	form_alert
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

Init_Rsc
; Initialisations diverses du RSC.
	MOVEm.l	A0-A6/D0-D7,-(SP)
; Mise en place du num‚ro de version.
	MOVEq	#INFO,D1
	MOVEq	#R_TREE,D0
	BSR	rsrc_gaddr
	LEA	IN_VERSION*size_OBJECT(A0),A0
	LEA	TEXTVERSION(PC),A1
	MOVE.l	A1,ob_spec(A0)
	CHECKREGISTER
	TST.b	D0
	Bne.s	.registered
; Version non enregistr‚e.
	MOVEq	#INFO,D1
	MOVEq	#R_TREE,D0
	BSR	rsrc_gaddr
	LEA	IN_REGISTER*size_OBJECT(A0),A0
	LEA	DEMOVERSION(PC),A1	;texte d‚mo.
	MOVE.l	A1,ob_spec(A0)
	MOVE	#20,MaxConf		;20 configs.
; options d‚sactiv‚es.
;	MOVEq	#GENERAL,D1
;	MOVEq	#R_TREE,D0
;	BSR	rsrc_gaddr
; 68030 … 16Mhz.
;	LEA	MF_16*size_OBJECT(A0),A1
;	ORi	#8,ob_state(A1)	
; pas de caches.
;	LEA	MCBO*size_OBJECT(A0),A1
;	ORi	#8,ob_state(A1)	
;	LEA	MCIN*size_OBJECT(A0),A1
;	ORi	#8,ob_state(A1)	
;	LEA	MCDA*size_OBJECT(A0),A1
;	ORi	#8,ob_state(A1)	
	BRA.s	.end

.registered
; Version enregistr‚e.
	MOVEq	#INFO,D1
	MOVEq	#R_TREE,D0
	BSR	rsrc_gaddr
	LEA	IN_USERNAME*size_OBJECT(A0),A0
	LEA	(cur_config+UName.w,PC),A1
	MOVEa.l	ob_spec(A0),A0
	MOVE.l	A1,te_ptext(A0)
.end
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

INTERSECT
; Calcul l'intersection entre un rectangle en A1 (rec AES)
; et un rectangle en A2 (rec VDI). R‚sultat en A1 (rec VDI).
	MOVEm.l	A1-A2/D1-D2,-(SP)
	MOVE	(A1),D0
	SUBq	#1,D0
	ADD	D0,4(A1)
	MOVE	2(A1),D0
	SUBq	#1,D0
	ADD	D0,6(A1)
	CMPm	(A1)+,(A2)+
	BLT.s	.OK_X1
	MOVE	-2(A2),-2(A1)
.OK_X1
	CMPm	(A1)+,(A2)+
	BLT.s	.OK_Y1
	MOVE	-2(A2),-2(A1)
.OK_Y1
	CMPm	(A1)+,(A2)+
	BGE.s	.OK_X2
	MOVE	-2(A2),-2(A1)
.OK_X2
	CMPm	(A1)+,(A2)+
	BGE.s	.OK_Y2
	MOVE	-2(A2),-2(A1)
.OK_Y2
	LEA	-8(A1),A1
	MOVE	(A1),D2
	CMP	4(A1),D2
	SLE	D0
	MOVE	2(A1),D2
	CMP	6(A1),D2
	SLE	D1
	AND.b	D1,D0
	MOVEm.l	(SP)+,A1-A2/D1-D2
	RTS

Win_Title
; Fixe le titre de la fenetre.
	MOVEm.l	A0-A6/D0-D7,-(SP)
	TST.b	Libflag
	BNE.s	.modified
	MOVEq	#R_STRING,D0
	MOVEq	#ST_WTITLE,D1
	BSR	rsrc_gaddr
	BRA.s	.ok
.modified
	MOVEq	#R_STRING,D0
	MOVEq	#ST_WMODIF,D1
	BSR	rsrc_gaddr
.ok
	LEA	dum_rec(PC),A1
	MOVE.l	A0,(A1)
	MOVE	whandle(PC),D0
	MOVEq	#WF_NAME,D1
	BSR	wind_set		;titre.
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

Draw_Window
; Raffraichit la fenetre.
	LEA	screen_rec(PC),A6
	BSR	Redraw_Window
	RTS

Redraw_Window
; Retrace la fenetre avec un clipping en A0.
	MOVEq	#BEG_UPDATE,D0
	BSR	wind_update		;demande redessin.
	LEA	rdrw_rec(PC),A0
	MOVE	(A6),D0
	MOVE	D0,(A0)+
	SUBq	#1,D0
	MOVE	2(A6),D1
	MOVE	D1,(A0)+
	SUBq	#1,D1
	ADD	4(A6),D0
	MOVE	D0,(A0)+
	ADD	6(A6),D1
	MOVE	D1,(A0)			;calcul du rectangle (AES->VDI).
	MOVE	#M_OFF,D0
	BSR	graf_mouse		;plus de souris.
	MOVEq	#0,D0
	BSR	vsf_interior		;remplissage blanc.
	LEA	dum_rec(PC),A1
	MOVE	whandle(PC),D0
	MOVEq	#WF_FIRSTXYWH,D1
	BSR	wind_get		;premier rectangle.
	TST.l	4(A1)
	BEQ.s	.no_redraw		;pas de dessin ?
.redraw_loop
	LEA	rdrw_rec(PC),A2
	BSR	INTERSECT		;intersection.
	TST.b	D0
	BEQ.s	.no_inter		;reelle ?
	LEA	dum_rec(PC),A1
	MOVEq	#1,D0
	BSR	vs_clip			;clipping on.
	LEA	dum_rec(PC),A1
	BSR	v_recfl
	LEA	dum_rec(PC),A1
	BSR	Lib_Print
.no_inter
	LEA	dum_rec(PC),A1
	MOVE	whandle(PC),D0
	MOVEq	#WF_NEXTXYWH,D1
	BSR	wind_get		;premier rectangle.
	TST.l	4(A1)
	BNE.s	.redraw_loop
.no_redraw
	LEA	dum_rec(PC),A1
	MOVEq	#0,D0
	BSR	vs_clip			;clipping off.
	MOVEq	#END_UPDATE,D0
	BSR	wind_update		;fin m.….j.
	MOVE	#M_ON,D0		;mouse on.
	BSR	graf_mouse
	BSR	Win_Slider		;m.….j. des sliders.
	RTS

Adjust_Win
; R‚ajuste la portion de liste affich‚e.
	MOVEm.l	D0-D1,-(SP)
	BSR	Win_Lines
	MOVE	D0,D1
	ADD	wconfig(PC),D0
	CMP	nbconfig(PC),D0		;trop loin ?
	BCS.s	.ok
	MOVE	nbconfig(PC),D0
.ok
	SUB	D1,D0
	BPL.s	.ok2			;trop prŠs ?
	MOVEq	#0,D0
.ok2
	MOVE	D0,wconfig
	MOVEm.l	(SP)+,D0-D1
	RTS

Win_Lines
; retourne le nombre de lignes dans la fenetre.
	MOVEm.l	A0-A2/D1-D2,-(SP)
	LEA	dum_rec(PC),A1
	MOVE	whandle(PC),D0
	MOVEq	#WF_WORKXYWH,D1
	BSR	wind_get
	MOVE	6(A1),D0
	EXT.l	D0
	MOVE	char_rec+2(PC),D1
	DIVu	D1,D0
	MOVEm.l	(SP)+,A0-A2/D1-D2
	RTS

Win_Slider
; calcul et fixe la taille et la position du slider.
	MOVEm.l	A0-A2/D0-D2,-(SP)
	MOVE	#1000,D0
	MOVE	nbconfig(PC),D1
	BEQ.s	.full_slide
	BSR	Win_Lines
	TST	D0
	BNE.s	.windowgood
	MOVE	D1,D0
	BRA.s	.ok
.windowgood
	CMP	D1,D0
	BCS.s	.ok
	MOVE	D0,D1
.ok
	MULu	#1000,D0
	DIVu	D1,D0
.full_slide
	LEA	dum_rec(PC),A1
	MOVE	D0,(A1)
	MOVE	whandle(PC),D0
	MOVEq	#WF_VSLSIZE,D1
	BSR	wind_set		;taille.
	MOVE	(A1),D2
	MOVEq	#1,D0
	CMPi	#1000,D2
	BEQ.s	.top
	TST	wconfig
	BEQ.s	.top
	MOVE	nbconfig(PC),D1
	BSR	Win_Lines
	SUB	D0,D1
	BPL.s	.ok2
	MOVEq	#1,D0
	BRA.s	.top
.ok2
	MOVE	wconfig(PC),D0
	MULu	#1000,D0
	Divu	D1,D0
	ADDq	#1,D0
.top
	LEA	dum_rec(PC),A1
	MOVE	D0,(A1)
	MOVE	whandle(PC),D0
	MOVEq	#WF_VSLIDE,D1
	BSR	wind_set		;position.
	MOVEm.l	(SP)+,A0-A2/D0-D2
	RTS

*********************************
*	Librairie de config.	*
*********************************
Preset_Config
; fixe une entr‚e … une valeur par d‚faut.
	MOVEm.l	A0-A6/D0-D7,-(SP)
	MOVE	(selconf.w,PC),D0
	CMPi	#-1,D0
	Beq.s	.def_config
	MULu	#SIZEDISK,D0
	MOVEa.l	(_libmem.w,PC),A1
	LEA	(Config.w,A1,D0.l),A1
	Bra.s	.ok
.def_config
	LEA	(cur_config.w,PC),A1
.ok
	BSR	Copy_Config
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

Remove_Selected
	MOVEm.l	A0-A6/D0-D7,-(SP)
	TST	selconf
	BMI.s	.no_delete
	MOVE	selconf(PC),D0
	MULu	#SIZEDISK,D0
	MOVEa.l	_libmem(PC),A6
	LEA	(A6,D0),A0
	BSR	Delete_Disk
	MOVE	#-1,selconf
	MOVEq	#-1,D0
	BSR	New_Selected
	ST	Libflag
	BSR	Win_Title
.no_delete
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

New_Selected
; Change le disque s‚lectionn‚ pour D0.
	MOVEm.l	A0-A6/D0-D7,-(SP)
	MOVE	D0,D7
	CMPi	#-1,D7
	BEQ.s	.none_selected
	CMPi	#-2,D7
	BEQ.s	.no_select_no_default
	MOVE	D7,D0
	MULu	#SIZEDISK,D0
	MOVEa.l	_libmem(PC),A0
	LEA	Name(A0,D0.l),A0
	BRA.s	.ok			;nom du disque.
.none_selected
.no_select_no_default
	MOVEq	#-1,D7
	MOVEq	#R_STRING,D0
	MOVEq	#ST_WINFO,D1
	BSR	rsrc_gaddr		;pas de disque.
.ok
	LEA	dum_rec(PC),A1
	MOVE.l	A0,(A1)
	MOVE	whandle(PC),D0
	MOVEq	#WF_INFO,D1
	BSR	wind_set		;nouvelles infos.
	MOVE	D7,selconf
	CMPi	#-1,D7
	BEQ.s	.not_move
; on positionne la fenetre si n‚cessaire.
	BSR	Win_Lines
	CMP	wconfig(PC),D7
	BCS	.winout
	ADD	wconfig(PC),D0
	CMP	D7,D0
	BCC	.not_move
.winout
	MOVE	D7,wconfig
	BSR	Adjust_Win		;on fixe l'affichage.
.not_move
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

Lib_Print
; Affiche la librairie dans la fenŠtre.
; A1 rectangle de redessin.
	MOVEm.l	A0-A6/D0-D7,-(SP)
	MOVE	2(A1),miny
	MOVE	6(A1),maxy
	MOVE	wconfig(PC),D0
	MOVE	D0,D3
	MULu	#SIZEDISK,D0
	MOVEa.l	_libmem(PC),A6
	LEA	(A6,D0.l),A6		;d‚but … afficher.
	BSR	Win_Lines
	ADDq	#1,D0
	MOVE	D0,D7			;nb lignes.
	MOVEq	#0,D0
	MOVEq	#3,D1
	BSR	vst_alignment
	LEA	work_rec(PC),A1
	MOVE	whandle(PC),D0
	MOVEq	#WF_WORKXYWH,D1
	BSR	wind_get		;coord. int‚rieures.
	MOVE	(A1),D5			;X.
	ADD	char_rec(PC),D5
	ADD	char_rec(PC),D5		;2 car. du bord.
	MOVE	2(A1),D4		;Y.
	MOVE	2+char_rec(PC),D6	;hauteur de char.
	SUBq	#1,D4
.loop
	CMP	nbconfig(PC),D3
	BEQ	.end
	CMP	maxy(PC),D4
	BGT	.not_selected
	ADD	D6,D4
	MOVE	D5,D0
	MOVE	D4,D1
	MOVE.l	A6,A1
	CMP	miny(PC),D4
	BLT	.not_selected
	BSR	v_gtext			;on affiche le texte.
	CMP	selconf(PC),D3
	BNE.s	.not_selected
	MOVEq	#3,D0
	BSR	vswr_mode		;mode XOR.
	MOVEq	#1,D0
	BSR	vsf_interior		;remplissage avec fond.
	MOVEq	#15,D0
	BSR	vsf_color		;couleur 15.
	LEA	dum_rec(PC),A1
	LEA	work_rec(PC),A2
	MOVE.l	(A2),(A1)
	MOVE.l	4(A2),4(A1)
	MOVE	D4,D0
	MOVE	D0,6(A1)
	SUB	D6,D0
	ADDq	#1,D0
	MOVE	D0,2(A1)
	MOVE	(A1),D0
	SUBq	#1,D0
	ADD	D0,4(A1)
	BSR	v_recfl
	MOVEq	#1,D0
	BSR	vswr_mode		;mode Replace.
	MOVEq	#0,D0
	BSR	vsf_interior		;remplissage avec fond.
	MOVEq	#0,D0
	BSR	vsf_color		;couleur 0.
.not_selected
	ADDq	#1,D3
	LEA	SIZEDISK(A6),A6
	SUBq	#1,D7
	BNE	.loop
.end

	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

Scan_Lib
; Cherche un disque de cheksum D1,D2,D3.
; Retourne -1 si pas trouv‚, index sinon.
	MOVE.l	A0,-(SP)
	MOVEa.l	_libmem(PC),A0
	MOVE.l	D1,D0
	OR.l	D2,D0
	OR.l	D3,D0
	Beq.s	.end
	MOVEq	#0,D0
.loop
	CMP	(nbconfig.w,PC),D0
	Beq.s	.end
	CMP.l	(Chk1.w,A0),D1
	Bne.s	.no
	CMP.l	(Chk2.w,A0),D2
	Bne.s	.no
	CMP.l	(Chk3.w,A0),D3
	Bne.s	.no
	MOVEa.l	(SP)+,A0
	RTS
.no
	LEA	(SIZEDISK.w,A0),A0
	ADDq	#1,D0
	BRA.s	.loop

.end
	MOVEq	#-1,D0
	MOVEa.l	(SP)+,A0
	RTS

New_Disk
; Ajout d'un disque dans la base.
; Reste-t-il de la place ?
	MOVEm.l	A0-A6/D0-D7,-(SP)
	MOVE	nbconfig(PC),D0
	CMP	MaxConf(PC),D0
	Bne.s	.not_full
; Librairie pleine.
	MOVEq	#R_STRING,D0
	MOVEq	#AL_FULL,D1
	BSR	rsrc_gaddr
	MOVEQ	#1,D0
	BSR	form_alert
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

.not_full
; gŠre la configuration
; fait une copie temporaire.
	LEA	(cur_config.w,PC),A0
	LEA	(cur_disk.w,PC),A6
	LEA	(Config.w,A6),A1
	Bsr	Copy_Config
	CLR.b	(Name.w,A6)
; InsŠre en d‚but.
	MOVEa.l	(_libmem.w,PC),A0
	LEA	(cur_disk.w,PC),A1
	BSR	Insert_Disk
	CLR	selconf
	BSR	Configuration
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

Insert_Disk
; InsŠre un disk dans la librairie.
; A0 contient la position.A1 le disk.
	MOVEm.l	A0-A3/D0,-(SP)
	MOVEa.l	A1,A3
	MOVEa.l	(_libmem.w,PC),A1	;A0 pointe sur la position.
	ADDi	#1,nbconfig
	MOVE	(nbconfig.w,PC),D0
	MULu	#SIZEDISK,D0
	LEA	(SIZEDISK.w,A1,D0.l),A1
	LEA	(SIZEDISK.w,A1),A2
.movetable
	MOVE	-(A1),-(A2)
	CMPa.l	A1,A0
	Bne.s	.movetable
	MOVEa.l	A3,A0
	BSR	Copy_Disk
	MOVEm.l	(SP)+,A0-A3/D0
	RTS

Delete_Disk
; D‚truit le disk en A0.
	MOVEm.l	A0-A2,-(SP)
	MOVEa.l	_libmem(PC),A1
	MOVE	nbconfig(PC),D0
	MULu	#SIZEDISK,D0
	LEA	(A1,D0.l),A1
	LEA	SIZEDISK(A0),A2
.movelibrary
	MOVE	(A2)+,(A0)+
	CMPa.l	A1,A2
	BCS.s	.movelibrary
	SUBi	#1,nbconfig
	MOVEm.l	(SP)+,A0-A2
	RTS

Load_Library
; R‚servation m‚moire et chargement de la configuration.
	MOVE	MaxConf(PC),D0
	MULu	#SIZEDISK,D0
	MOVE.l	D0,-(SP)
	MOVE	#$48,-(SP)
	TRAP	#1			;r‚servation m‚moire
	ADDq	#6,SP
	TST.l	D0
	BEQ.s	.not_enough
	CLR	nbconfig		;pas de config par d‚faut.
	MOVEa.l	D0,A0
	MOVE.l	A0,_libmem
	CLR	-(SP)
	PEA	LIBNAME(PC)
	MOVE	#$3D,-(SP)
	TRAP	#1			;ouverture du fichier.
	ADDq	#8,SP
	TST.l	D0
	BMI.s	.no_lib_file
	MOVE	D0,D7
	MOVE.l	_libmem,-(SP)
	MOVE	MaxConf(PC),D0
	MULu	#SIZEDISK,D0
	MOVE.l	D0,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	TRAP	#1			;lecture.
	LEA	12(SP),SP
	TST.l	D0
	BMI.s	.no_lib_file
	DIVU	#SIZEDISK,D0
	MOVE	D0,nbconfig		;nombre de config existantes.
	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1			;fermeture du fichier.
	ADDq	#4,SP
.no_lib_file
	SF	Libflag
	MOVEq	#0,D0			;pas d'erreur.
	RTS

.not_enough
	MOVEq	#-1,D0			;pas de m‚moire.
	RTS

Save_Library
; sauve la librairie de configurations.
	MOVEm.l	A0-A6/D1-D7,-(SP)
	MOVE	nbconfig(PC),D0
	BEQ	.no_saving
	TST.b	Libflag
	BEQ	.no_saving
; on force la m.….j.
	MOVE	selconf(PC),D0
	BSR	New_Selected
	MOVEq	#HOURGLASS,D0
	BSR	graf_mouse
; on cr‚e le fichier
	CLR	-(SP)
	PEA	LIBNAME(PC)
	MOVE	#$3C,-(SP)
	TRAP	#1
	ADDq	#8,SP
	MOVE	D0,D7
	Bmi.s	.error

; on ‚crit la librairie.
	MOVE.l	_libmem(PC),-(SP)
	MOVE	nbconfig(PC),D0
	MULu	#SIZEDISK,D0
	MOVE.l	D0,-(SP)
	MOVE.l	D0,D6
	MOVE	D7,-(SP)
	MOVE	#$40,-(SP)
	TRAP	#1
	LEA	12(SP),SP
	CMP.l	D6,D0
	Sne	D6
; on referme le fichier.
	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP

	TST.l	D0
	Bmi.s	.error

	MOVEq	#-1,D0
	TST.b	D6
	Bmi.s	.error
; ok.
	MOVEq	#0,D0
	SF	Libflag
	BSR	Win_Title
.error
	MOVE.l	D0,-(SP)
	MOVEq	#ARROW,D0
	BSR	graf_mouse
	MOVE.l	(SP)+,D0
	BSR	Update_Library
.no_saving
	MOVEm.l	(SP)+,A0-A6/D1-D7
	RTS

Comp_Disks
; Compare les noms de deux disques (A0 et A1).
; Retour : 0 si ‚gaux, 1 si A1>A0 et -1 si A1<A0
	MOVEm.l	A0-A1,-(SP)
.loop
	MOVE.b	(A1)+,D0
	CMP.b	(A0)+,D0
	BNE.s	.end
	TST.b	D0
	BNE.s	.loop
	MOVEq	#0,D0		;‚gaux.
	BRA.s	.real_end
.end
	BCS.s	.less
	MOVEq	#1,D0
	BRA.s	.real_end
.less
	MOVEq	#-1,D0
.real_end
	MOVEm.l	(SP)+,A0-A1
	RTS

Read_Disk
; Lit la disquette et en d‚duit les checksums (D1-D3).
	MOVEm.l	A0-A2,-(SP)
	MOVEq	#HOURGLASS,D0
	BSR	graf_mouse
	MOVE	#1,-(SP)
	CLR.l	-(SP)
	MOVE	#1,-(SP)
	CLR	-(SP)
	CLR.l	-(SP)
	PEA	STARTBLOCK(PC)
	MOVE	#8,-(SP)
	TRAP	#14		;lecture boot.
	LEA	20(SP),SP
	TST.l	D0
	BMI.s	.error
; checksum1.
	LEA	STARTBLOCK(PC),A0
	MOVEq	#63,D0
	MOVEq	#0,D1
.loop1
	ADD.l	(A0)+,D1
	DBF	D0,.loop1
; checksum2.
	LEA	STARTBLOCK(PC),A0
	MOVEq	#63,D0
	MOVEq	#0,D2
.loop2
	MOVE.l	(A0)+,D3
	EOR.l	D3,D2
	DBF	D0,.loop2
; checksum3
	LEA	STARTBLOCK(PC),A0
	MOVEq	#63,D0
	MOVEq	#0,D3
.loop3
	ROL.l	D0,D3
	ADD.l	(A0)+,D3
	DBF	D0,.loop3
	MOVEq	#0,D0
.error
	MOVE.l	D0,-(SP)
	MOVEq	#ARROW,D0
	BSR	graf_mouse
	MOVE.l	(SP)+,D0
	MOVEm.l	(SP)+,A0-A2
	RTS

Copy_Disk
; recopie une entr‚e de librairie de A0 sur A1.
	MOVEm.l	A0-A1/D0,-(SP)
	MOVEq	#SIZEDISK-1,D0
.COPY
	MOVE.b	(A0)+,(A1)+
	DBF	D0,.COPY
	MOVEm.l	(SP)+,A0-A1/D0
	RTS

Configuration
	MOVEm.l	A0-A6/D0-D7,-(SP)
; gŠre la configuration
	MOVE	(selconf.w,PC),D0
	CMPi	#-1,D0
	Beq.s	.def_config
	MULu	#SIZEDISK,D0
	MOVEa.l	(_libmem.w,PC),A0
	LEA	(A0,D0.l),A6
; fait une copie temporaire.
	LEA	(cur_disk+Name.w,PC),A1
	MOVEa.l	A6,A0
	Bsr	Copy_Disk
	LEA	(cur_disk.w,PC),A6
	MOVEq	#R_TREE,D0
	MOVEq	#GENERAL,D1
	BSR	rsrc_gaddr
	MOVE.l	#size_OBJECT*IDS_TITLE,D0
	MOVEa.l	(ob_spec.w,A0,D0.l),A1
	LEA	(Name.w,A6),A0
	MOVE.l	A0,(te_ptext.w,A1)	;chaine pour le nom du disque.
	LEA	(Config.w,A6),A0
	Bra.s	.edit
.def_config
	MOVEq	#R_TREE,D0
	MOVEq	#GENERAL,D1
	Bsr	rsrc_gaddr
	MOVE.l	#size_OBJECT*IDS_TITLE,D0
	MOVEa.l	(ob_spec.w,A0,D0.l),A1
	LEA	(DefTitle.w,PC),A0
	MOVE.l	A0,(te_ptext.w,A1)	;chaine pour le nom du disque.
	LEA	(cur_config.w,PC),A0
.edit
	MOVEa.l	A0,A6
	Bsr	Get_Config
.re_edit
	MOVEq	#GENERAL,D0
	MOVEq	#-1,D1
	Bsr	form_use
	CMPi	#B_CANCEL,D0	
	Beq	.cancel
	CMPi.b	#IDB_LINK,D0
	Bne	.ok_choosen
; l'utilisateur … d‚cider de le linker.
; ok.
; pas de link pour la con par d‚faut.
	CMPi	#-1,selconf
	Beq.s	.re_edit

; type de lien.
	MOVEq	#R_STRING,D0
	MOVEq	#AL_LINKTYPE,D1
	BSR	rsrc_gaddr
	MOVEq	#1,D0
	BSR	form_alert
	CMPi	#1,D0
	Beq	.floppy_link
	LEA	(tempbuffer.w,PC),A0
	MOVE.l	#'.???',D0
	MOVEM.l	A0-A3/D1-D2,-(SP)
	MOVEA.l	A0,A2
	MOVE.l	D0,D1
	BSR	Dgetdrv
	ADD	#'A',D0
	MOVE.b	D0,(A0)+
	MOVE.b	#':',(A0)+
	MOVEQ	#0,D0
	BSR	Dgetpath
.search_end
	TST.b	(A0)
	Beq.s	.end_found
	ADDq	#1,A0
	Bra.s	.search_end
.end_found
	MOVE.b	#'\',(A0)+
	MOVE.b	#'*',(A0)+
	MOVE.b	#'.',(A0)+
.search_suffix
	ROL.l	#8,D1
	TST.b	D1
	BEQ.s	.search_suffix
	CMPI.b	#'.',D1
	BNE.s	.NO_DOT
	ROL.l	#8,D1
.NO_DOT
	MOVE.b	D1,(A0)+
	ROL.l	#8,D1
	MOVE.b	D1,(A0)+
	ROL.l	#8,D1
	MOVE.b	D1,(A0)+
	CLR.b	(A0)+
	MOVEA.l	A2,A0
	LEA	(prgname.w,PC),A1
	BSR	fsel_input
	AND	D1,D0
; cr‚e le chemin d'accŠs complet.
	LEA	(tempbuffer.w,PC),A0
.search_back
	MOVE.b	(A0)+,D2
	Beq.s	.end_string
	CMPi.b	#'\',D2
	Bne.s	.search_back
	MOVEa.l	A0,A3
	Bra.s	.search_back
.end_string
	LEA	(prgname.w,PC),A1
; copie le nom de fichier … la suite.
.add_name
	MOVE.b	(A1)+,(A3)+
	Bne.s	.add_name
	MOVEM.l	(SP)+,A0-A3/D1-D2
	TST	D0
	Beq	.re_edit
; OK, on charge les premiers 512 octets du fichier
	CLR	-(SP)
	PEA	(tempbuffer.w,PC)
	MOVE	#$3D,-(SP)
	TRAP	#1
	ADDq	#8,SP
	TST	D0
	Bmi	.re_edit
	MOVE	D0,D7
; efface STARTBLOCK par s‚curit‚.
	LEA	(STARTBLOCK.w,PC),A0
	MOVEq	#127,D0
.clear_block
	CLR.l	(A0)+
	DBf	D0,.clear_block
	PEA	(STARTBLOCK.w,PC)
	MOVE.l	#512,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	TRAP	#1
	LEA	(12.w,SP),SP
; ferme le fichier
	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP	
; calcule les cl‚s
; checksum1.
	LEA	STARTBLOCK(PC),A0
	MOVEq	#63,D0
	MOVEq	#0,D1
.loop1
	ADD.l	(A0)+,D1
	DBF	D0,.loop1
; checksum2.
	LEA	STARTBLOCK(PC),A0
	MOVEq	#63,D0
	MOVEq	#0,D2
.loop2
	MOVE.l	(A0)+,D3
	EOR.l	D3,D2
	DBF	D0,.loop2
; checksum3
	LEA	STARTBLOCK(PC),A0
	MOVEq	#63,D0
	MOVEq	#0,D3
.loop3
	ROL.l	D0,D3
	ADD.l	(A0)+,D3
	DBF	D0,.loop3
	Bra	.read_ok

.floppy_link
.re_read
	BSR	Read_Disk
	TST.l	D0
	Beq.s	.read_ok
; problŠme de lecture.
	MOVEq	#R_STRING,D0
	MOVEq	#AL_DISK,D1
	BSR	rsrc_gaddr
; alerte disk.
	MOVEq	#1,D0
	BSR	form_alert
	CMPi	#1,D0
	Beq.s	.re_read
	MOVEq	#0,D1
	MOVEq	#0,D2
	MOVEq	#0,D3
	CMPi	#3,D0			;ignorer ?
	Bne	.re_edit
.read_ok
; ok on continue.
	LEA	(cur_disk.w,PC),A6
	BSR	Scan_Lib
	CMPi	#-1,D0
	Beq.s	.not_found
	CMP	(selconf.w,PC),D0
	Beq.s	.not_found
; On a d‚j… un disque avec ces chks.
	MOVEq	#R_STRING,D0
	MOVEq	#AL_SAME,D1
	BSR	rsrc_gaddr
; alerte d‚j….
	MOVEq	#1,D0
	BSR	form_alert
	LEA	(cur_disk+Config.w,PC),A6
	Bra	.re_edit
.not_found
	LEA	(cur_disk.w,PC),A6
	MOVE.l	D1,(Chk1.w,A6)		;)
	MOVE.l	D2,(Chk2.w,A6)		;) on fixe les chks.
 	MOVE.l	D3,(Chk3.w,A6)		;)
	LEA	(cur_disk+Config.w,PC),A6
	Bra	.re_edit

.ok_choosen
	MOVEa.l	A6,A0
	Bsr	Set_Config
	TST	selconf
	Bmi	.no_change
; modif de la bibliothŠques.
; v‚rifie que le nom n'est pas deja pr‚sent.
	MOVEa.l	(_libmem.w,PC),A0
	LEA	(cur_disk.w,PC),A6
	LEA	(Name.w,A6),A1
	MOVEq	#0,D6			;Compteur de position.
	MOVE	(nbconfig.w,PC),D7
	BRA.s	.start1
.loopx
	LEA	(SIZEDISK.w,A0),A0
	ADDq	#1,D6
.start1
	SUBq	#1,D7
	Bmi.s	.end_test
	CMP	(selconf.w,PC),D6
	Beq.s	.loopx			;on ignore la pos d'origine.
	BSR	Comp_Disks		;on cherche
	TST.l	D0			;sa position.
	Beq.s	.present
	Bpl.s	.loopx
	Bra.s	.end_test
.present
; disque d‚j… dans la base.
; Le disk existe d‚j….
	BSR	Draw_Window
	MOVEq	#R_STRING,D0
	MOVEq	#AL_PRESENT,D1
	BSR	rsrc_gaddr
; alerte d‚j… pr‚sent.
	MOVEq	#1,D0
	BSR	form_alert
	LEA	(cur_disk+Config.w,PC),A6
	Bra	.re_edit
	
.end_test
; Ok
; d‚truit l'ancienne entr‚e
	MOVE	(selconf.w,PC),D0
	MULu	#SIZEDISK,D0
	MOVEa.l	(_libmem.w,PC),A0
	LEA	(A0,D0.l),A0
	BSR	Delete_Disk
; recherche ou placer la nouvelle.
	MOVEa.l	(_libmem.w,PC),A0
	LEA	(cur_disk.w,PC),A6
	LEA	(Name.w,A6),A1
	MOVEq	#0,D6			;Compteur de position.
	MOVE	(nbconfig.w,PC),D7
	BRA.s	.start
.loop
	LEA	(SIZEDISK.w,A0),A0
	ADDq	#1,D6
.start
	SUBq	#1,D7
	Bmi.s	.end
	BSR	Comp_Disks		;on cherche
	Bpl.s	.loop
.end
	LEA	(cur_disk.w,PC),A1
	BSR	Insert_Disk
	MOVE	D6,D0
	BSR	New_Selected
	BSR	Draw_Window
	ST	Libflag			;flag librairie dirty
	BSR	Win_Title
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

.no_change
.cancel
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

OtherOptions
; autres r‚glages.
; copie de la config.
	MOVEq	#R_TREE,D0
	MOVEq	#CONFIG,D1
	BSR	rsrc_gaddr	;adresse du formulaire.
	MOVE.b	(cur_config+Multiscan.w,PC),D1
	MOVEq	#OG_MULTI,D0
	BSR	Set_Object
	MOVE.b	(cur_config+Logo.w,PC),D1
	MOVEq	#OG_LOGO,D0
	BSR	Set_Object
	MOVE.b	(cur_config+IDE.w,PC),D1
	MOVEq	#OG_IDE,D0
	BSR	Set_Object
; affichage de la boŒte.
	MOVEq	#CONFIG,D0
	MOVEq	#-1,D1
	BSR	form_use
	CMPi	#OG_CANCEL,D0
	Beq.s	.cancel
; on_r‚cupŠre la nouvelle config.
	MOVEq	#R_TREE,D0
	MOVEq	#CONFIG,D1
	BSR	rsrc_gaddr	;adresse du formulaire.
; ‚cran multisynch ?
	MOVEq	#OG_MULTI,D0
	BSR	Test_Object
	MOVE.b	D0,cur_config+Multiscan
; logo ATARI ?
	MOVEq	#OG_LOGO,D0
	BSR	Test_Object
	MOVE.b	D0,cur_config+Logo
; disques IDE ?
	MOVEq	#OG_IDE,D0
	BSR	Test_Object
	MOVE.b	D0,cur_config+IDE
.cancel
	RTS

SaveDefault
; sauvegarde de la configuration courante comme
; configuration par d‚faut.
	LEA	(cur_config.w,PC),A0
; sauvegarde des options g‚n‚rales.
	BSR	Save_Config
	RTS

Test_Falcon
; test si on utilise un Falcon
	MOVE.l	#'_MCH',D0
	BSR	Read_Cookie
	TST.l	D0
	BNE.s	.failure
	CMPi.l	#$30000,D1
	BNE.s	.failure
	MOVEq	#0,D0		;succŠs.
	BRA.s	.success
.failure
	MOVEq	#1,D0
.success
	RTS

Save_Config
; sauve la configuration du programme.
	MOVEm.l	A0-A6/D1-D7,-(SP)
	MOVEa.l	A0,A6
	MOVEq	#HOURGLASS,D0
	BSR	graf_mouse
; on ouvre le fichier.
	MOVE	#2,-(SP)
	PEA	INFNAME(PC)
	MOVE	#$3D,-(SP)
	TRAP	#1
	ADDq	#8,SP
	MOVE	D0,D7
	BPL.s	.ok
; on cr‚e le fichier
	CLR	-(SP)
	PEA	INFNAME(PC)
	MOVE	#$3C,-(SP)
	TRAP	#1
	ADDq	#8,SP
	MOVE	D0,D7
	BMI.s	.error
.ok
; on ‚crit la configuration.
	PEA	(A6)
	MOVE.l	#SIZEPREF,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$40,-(SP)
	TRAP	#1
	LEA	12(SP),SP
	CMPi.l	#SIZEPREF,D0
	SNE	D6
; on referme le fichier.
	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP

	TST.l	D0
	BMI.s	.error

	MOVEQ	#-1,D0
	TST.b	D6
	BMI.s	.error
; ok.
	MOVEq	#0,D0
.error
	MOVEq	#ARROW,D0
	BSR	graf_mouse
	BSR	Update_Pref
	MOVEm.l	(SP)+,A0-A6/D1-D7
	RTS

Load_Config
; charge la configuration du programme.
	MOVEm.l	A0-A6/D1-D7,-(SP)
	MOVEa.l	A0,A6
	CLR.l	cur_config+UName
	CLR.l	cur_config+UKey
; on ouvre le fichier.
	CLR	-(SP)
	PEA	INFNAME(PC)
	MOVE	#$3D,-(SP)
	TRAP	#1
	ADDq	#8,SP
	MOVE	D0,D7
	BMI.s	.error
; on lit la configuration.
	PEA	(A6)
	MOVE.l	#SIZEPREF,-(SP)
	MOVE	D7,-(SP)
	MOVE	#$3F,-(SP)
	TRAP	#1
	LEA	12(SP),SP
	CMPi.l	#SIZEPREF,D0
	SNE	D6

; on referme le fichier.
	MOVE	D7,-(SP)
	MOVE	#$3E,-(SP)
	TRAP	#1
	ADDq	#4,SP

	TST.l	D0
	BMI.s	.error

	MOVEQ	#-1,D0
	TST.b	D6
	BMI.s	.error
; ok.
	MOVEq	#0,D0
.error
	MOVEm.l	(SP)+,A0-A6/D1-D7
	RTS

Set_Config
; convertit l'‚tat du formulaire de configuration
; en structure de config (en A0).
	MOVEm.l	A0-A1/D0-D1,-(SP)
	MOVEa.l	A0,A1
	MOVEq	#R_TREE,D0
	MOVEq	#GENERAL,D1
	BSR	rsrc_gaddr	;adresse du formulaire.
; tout … 0.
	CLR.l	(Data.w,A1)
; fr‚quence 68030
	MOVEq	#MF_8,D0
	BSR	Test_Object
	ANDi.l	#Motor,D0
	MOVE.l	D0,(Data.w,A1)
;	TST.b	Flag_Registered
;	Bne.s	.ok_16
;	ORi.l	#Motor,(Data.w,A1)
;.ok_16
; ‚tat des caches
	MOVEq	#MCBO,D0
	BSR	Test_Object
; test enregistr‚.
;	TST.b	Flag_Registered
;	Beq.s	.cache_good
; les deux ?
	TST.b	D0
	Beq.s	.not_both
	ORi.l	#Caches,(Data.w,A1)
	BRA.s	.cache_good
.not_both
	MOVEq	#MCDA,D0
	BSR	Test_Object
; cache donn‚es ?
	TST.b	D0
	Beq.s	.not_data
	ORi.l	#DCache,(Data.w,A1)
	BRA.s	.cache_good
.not_data
	MOVEq	#MCIN,D0
	BSR	Test_Object
; cache instructions ?
	TST.b	D0
	Beq.s	.cache_good
	ORi.l	#ICache,(Data.w,A1)
.cache_good
; Erreur bus ?
	MOVEq	#HBCOR,D0
	BSR	Test_Object
	TST.b	D0
	Beq.s	.not_corrected
; corrig‚es.
	ORi.l	#CBus,(Data.w,A1)
	BRA.s	.bus_good
.not_corrected
	MOVEq	#HBSPEC,D0
	BSR	Test_Object
	TST.b	D0
	BEQ.s	.not_special
; sp‚cial.
	ORi.l	#SBus,(Data.w,A1)
	BRA.s	.bus_good
.not_special
	MOVEq	#HBST,D0
	BSR	Test_Object
	TST.b	D0
	BEQ.s	.bus_good
	ORi.l	#StBus,(Data.w,A1)
.bus_good
; taille m‚moire
	MOVEq	#HM1000,D0
	BSR	Test_Object
	TST.b	D0
	BEQ.s	.not_mega
; a mega.
	ORi.l	#Mem1024,(Data.w,A1)
	BRA.s	.mem_good
.not_mega
	MOVEq	#HM2000,D0
	BSR	Test_Object
	TST.b	D0
	BEQ.s	.not_two
; two megs.
	ORi.l	#Mem2048,(Data.w,A1)
	BRA.s	.mem_good
.not_two
	MOVEq	#HM3000,D0
	BSR	Test_Object
	TST.b	D0
	BEQ.s	.mem_good
; three megs.
	ORi.l	#MemMax,(Data.w,A1)
.mem_good
; Patch Tos
	MOVEq	#DSBON,D0
	BSR	Test_Object
	ANDi.l	#TosPatch,D0
	OR.l	D0,(Data.w,A1)
; HP interne ?
	MOVEq	#DISON,D0
	BSR	Test_Object
	ANDi.l	#InSpeak,D0
	OR.l	D0,(Data.w,A1)
; Disque Dur ?
	MOVEq	#HDON,D0
	BSR	Test_Object
	ANDi.l	#HardD,D0
	OR.l	D0,(Data.w,A1)
; Gem ?
	MOVEq	#GEMON,D0
	BSR	Test_Object
	ANDi.l	#Gem,D0
	OR.l	D0,(Data.w,A1)
; Mode Video
	MOVEq	#IDR_STMED,D0
	BSR	Test_Object
	TST.b	D0
	Beq.s	.not_med
	ORi.l	#VMed,(Data.w,A1)
	BRA.s	.video_good
.not_med
	MOVEq	#IDR_STHIGH,D0
	BSR	Test_Object
	TST.b	D0
	Beq.s	.not_high
	ORi.l	#VHigh,(Data.w,A1)
	BRA.s	.video_good
.not_high
	MOVEq	#IDR_VDEF,D0
	BSR	Test_Object
	TST.b	D0
	Beq.s	.video_good
; three megs.
	ORi.l	#VDef,(Data.w,A1)
.video_good
	CLR.l	(Res.w,A1)
	MOVEm.l	(SP)+,A0-A1/D0-D1
	RTS

Get_Config
; convertit une structure de config
; en une boite de dialogue
	MOVEm.l	A0-A1/D0-D2,-(SP)
	MOVEa.l	A0,A1
	MOVEq	#R_TREE,D0
	MOVEq	#GENERAL,D1
	BSR	rsrc_gaddr
; fr‚quence 68O3O.
	MOVE.l	(Data.w,A1),D1
	ANDi.l	#Motor,D1
	Sne	D1
; enregistr‚e ?
;	TST.b	Flag_Registered
;	Bne.s	.mot_ok
;	St	D1
.mot_ok
	MOVEq	#MF_8,D0
	BSR	Set_Object
	NOT.b	D1
	MOVEq	#MF_16,D0
	BSR	Set_Object
; configuration des caches.
	MOVE.l	(Data.w,A1),D2
	ANDi.l	#Caches,D2
; enregistr‚e ?
;	TST.b	Flag_Registered
;	Bne.s	.caches_ok
;	CLR.l	D2
.caches_ok
; pas de cache ?
	TST.l	D2
	SEQ	D1
	MOVEq	#MCNO,D0
	BSR	Set_Object
; cache donn‚es.
	CMPi.l	#DCache,D2
	SEQ	D1
	MOVEq	#MCDA,D0
	BSR	Set_Object
; cache instructions.
	CMPi.l	#ICache,D2
	SEQ	D1
	MOVEq	#MCIN,D0
	BSR	Set_Object
; 2 caches.
	CMPi.l	#Caches,D2
	SEQ	D1
	MOVEq	#MCBO,D0
	BSR	Set_Object
; erreur bus.
	MOVE.l	(Data.w,A1),D2
	ANDi.l	#Buserr,D2
; pas de traitement ?
	TST.l	D2
	SEQ	D1
	MOVEq	#HBLEFT,D0
	BSR	Set_Object
; correction ?
	CMPi.l	#CBus,D2
	Seq	D1
	MOVEq	#HBCOR,D0
	Bsr	Set_Object
; sp‚cial ?
	CMPi.l	#SBus,D2
	Seq	D1
	MOVEq	#HBSPEC,D0
	Bsr	Set_Object
; mode ST.
	CMPi.l	#StBus,D2
	Seq	D1
	MOVEq	#HBST,D0
	Bsr	Set_Object
; m‚moire.
	MOVE.l	(Data.w,A1),D2
	ANDi.l	#Memsize,D2
; 512 K.
	CMPi.l	#Mem512,D2
	Seq	D1
	MOVEq	#HM512,D0
	Bsr	Set_Object
; 1 Mega.
	CMPi.l	#Mem1024,D2
	Seq	D1
	MOVEq	#HM1000,D0
	Bsr	Set_Object
; 2 Megas.
	CMPi.l	#Mem2048,D2
	Seq	D1
	MOVEq	#HM2000,D0
	Bsr	Set_Object
; 3 Megas.
	CMPi.l	#MemMax,D2
	Seq	D1
	MOVEq	#HM3000,D0
	Bsr	Set_Object
; Base ‚cran.
	MOVE.l	(Data.w,A1),D1
	ANDi.l	#TosPatch,D1
	Sne	D1
	MOVEq	#DSBON,D0
	BSR	Set_Object
	NOT.b	D1
	MOVEq	#DSBOFF,D0
	BSR	Set_Object
; HP interne.
	MOVE.l	(Data.w,A1),D1
	ANDi.l	#InSpeak,D1
	Sne	D1
	MOVEq	#DISON,D0
	BSR	Set_Object
	NOT.b	D1
	MOVEq	#DISOFF,D0
	BSR	Set_Object
; Disque dur.
	MOVE.l	(Data.w,A1),D1
	ANDi.l	#HardD,D1
	Sne	D1
	MOVEq	#HDON,D0
	BSR	Set_Object
	NOT.b	D1
	MOVEq	#HDOFF,D0
	BSR	Set_Object
; GEM.
	MOVE.l	(Data.w,A1),D1
	ANDi.l	#Gem,D1
	Sne	D1
	MOVEq	#GEMON,D0
	BSR	Set_Object
	NOT.b	D1
	MOVEq	#GEMOFF,D0
	BSR	Set_Object
; vid‚o.
	MOVE.l	(Data.w,A1),D2
	ANDi.l	#Video,D2
; basse.
	CMPi.l	#VLow,D2
	Seq	D1
	MOVEq	#IDR_STLOW,D0
	Bsr	Set_Object
; moyenne.
	CMPi.l	#VMed,D2
	Seq	D1
	MOVEq	#IDR_STMED,D0
	Bsr	Set_Object
; haute.
	CMPi.l	#VHigh,D2
	Seq	D1
	MOVEq	#IDR_STHIGH,D0
	Bsr	Set_Object
; d‚faut.
	CMPi.l	#VDef,D2
	Seq	D1
	MOVEq	#IDR_VDEF,D0
	Bsr	Set_Object
	MOVEm.l	(SP)+,A0-A1/D0-D2
	RTS

Copy_Config
; recopie une configuration de A0 sur A1
	MOVEm.l	A0-A1/D0,-(SP)
	MOVEq	#SIZECONFIG-1,D0
.COPY
	MOVE.b	(A0)+,(A1)+
	DBF	D0,.COPY
	MOVEm.l	(SP)+,A0-A1/D0
	RTS

Test_Object
; retourne l'‚tat (s‚lectionn‚ ou non) de l'objet en D0
; de l'arbre point‚ en A0
	MULu	#size_OBJECT,D0
	MOVE	ob_state(A0,D0),D0
	ANDi.l	#1,D0
	Beq.s	.ok
	MOVEq	#-1,D0
.ok
	RTS

Select_Object
; s‚lectionne l'objet D0 de l'arbre point‚ en A0
	MULU	#size_OBJECT,D0
	ORi	#1,ob_state(A0,D0)
	RTS

Unselect_Object
; s‚lectionne l'objet D0 de l'arbre point‚ en A0
	MULU	#size_OBJECT,D0
	ANDi	#$FFFE,ob_state(A0,D0)
	RTS

Set_Object
; fixe l'objet D0 en fonction de D1
	TST.b	D1
	BEQ.s	Unselect_Object
	BRA.s	Select_Object

Copy_String
; Copie une chaine de A0 en A1 (D0 char au max).
; Retour : longueur de chaine.
	MOVEm.l	A0-A1,-(SP)
	SUBq	#1,D0
.loop
	MOVE.b	(A0)+,(A1)+
	DBEQ	D0,.loop
	SUBi	#32,D0
	NEG	D0
	MOVEm.l	(SP)+,A0-A1
	RTS

; recharge les pr‚f‚rences.
Update_Pref
	MOVEm.l	A0-A6/D0-D7,-(SP)
	TST.l	_infos
	Beq.s	.end
	MOVEa.l	([_infos.w,PC],_Set_Prefs.w),A0
	PEA	(cur_config.w,PC)
	JSR	(A0)
	ADDq	#4,SP
.end
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

; recharge la bibliothŠque.
Update_Library
	MOVEm.l	A0-A6/D0-D7,-(SP)
	TST.l	_infos
	Beq.s	.end
	MOVEa.l	([_infos.w,PC],_library.w),A0
	MOVEa.l	(_libmem.w,PC),A1
	MOVE	(nbconfig.w,PC),D0
	CMP	([_infos.w,PC],_lib_max.w),D0
	Bcs.s	.ok
	MOVE	([_infos.w,PC],_lib_max.w),D0
.ok
	MOVE	D0,([_infos],_lib_size.w)
	SUBq	#1,D0
	Bmi.s	.end
.copy_setups
	MOVEq	#SIZEDISK-1,D1
.copy_one
	MOVE.b	(A1)+,(A0)+
	DBf	D1,.copy_one
	DBf	D0,.copy_setups
.end
	MOVEm.l	(SP)+,A0-A6/D0-D7
	RTS

Read_Cookie
; lit la valeur d'un cookie fix‚ dans D0, retourn‚ en D1.
	MOVEM.l	A0/D2-D3,-(SP)
	MOVEq	#0,D1
	MOVE.l	D0,D2
	Bsr.s	Get_CJar
	Bmi.s	.error
	MOVEQ	#ER_NOCK,D0
.loop
	MOVE.l	(A0),D3
	Beq.s	.error
	CMP.l	D2,D3
	Beq.s	.found
	ADDQ.l	#8,A0
	Bra.s	.loop
.found
	MOVE.l	(4.w,A0),D1
	MOVEq	#0,D0
.error
	MOVEM.l	(SP)+,A0/D2-D3
	TST.l	D0
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
	MOVE.l	$5A0.w,D0
	RTS

; librairie GEM.
	INCLUDE	D:\ASM\INCLUDE\GEM.INC

	SECTION	DATA
; configuration par d‚faut
DEFAULT_CONFIG
	DC.l	Motor+StBus+TosPatch

BEST_CONFIG
	DC.l	Motor+StBus+TosPatch

INTER_CONFIG
	DC.l	SBus+DCache+TosPatch+Mem1024+Gem

MIN_CONFIG
	DC.l	TosPatch+SBus+ICache+DCache+MemMax+Gem+HardD
	EVEN

VDI_WKST
	DC	1,1,1,1,1,1,1,1,1,1,2

; Nombre Maximal de configurations
MaxConf	DC	2000
; nom des RSC (0->fichier USA)
RSC_NAME
	DC.l	USA_RSC		;USA
	DC.l	GER_RSC		;FRG
	DC.l	FRA_RSC		;FRA
	DC.l	0		;UK
	DC.l	0		;SPA
 	DC.l	0		;ITA
	DC.l	0		;SWF
	DC.l	0		;SWG

NULL	DC.l	0

USA_RSC	DC.b	"BCKWUSA.RSC",0
FRA_RSC	DC.b	"BCKWFRA.RSC",0
SWE_RSC	DC.b	"BCKWSWE.RSC",0
GER_RSC	DC.b	"BCKWGER.RSC",0

; nom du fichier de configuration.
INFNAME	DC.b	"BACKWARD.INF",0

; nom du fichier librairie.
LIBNAME	DC.b	"BACKWARD.DKS",0

; textes divers
TEXTVERSION	DC.b	'V 1.00'
	IFD BETA
		DC.b	'ž'
	ENDC
		DC.b	0
DEMOVERSION	DC.b	'Demo Demo Demo Demo',0

DefTitle	Dc.b	'Default Set Up',0
		Ds.b	32
; texte des alertes !
NO_RSC	DC.b	"[1][|No RSC file !][ Sorry !]",0,0

; ligne vide.
EMPTY	DC.b	"  ",0,0

	EVEN

	SECTION	BSS
; Min et Max fenetre.
miny	DS	1
maxy	DS	1

; configuration courante.
cur_config
	DS.b	SIZEPREF

; disk courant.
cur_disk
	DS.b	SIZEDISK

; flag librairie modifi‚
Libflag	DS.b	1

; Petite zone tampon
tempbuffer	DS.b	128
prgname		Ds.b	13

; version enregistr‚e.
Flag_Registered	Ds.b	1

	EVEN
; tampon pour les boot secteurs.
STARTBLOCK
	Ds.b	512


; Descripteur de station.
work_out
	DS	57

; identificateur de l'application.
appl_id	DS	1

; taille m‚moire.
mem_size
	DS.l	1

; handle de la station AES.
work_handle
	DS	1

; taille des caractŠres.
char_rec
	DS.b	rec_size

; buffer pour les messages GEM.
msg_buffer
	DS.b	16

; arbre du menu.
menutree
	DS.l	1

; pays
country_flag	Ds	1

; adresse du fichier des configurations.
_libmem
	DS.l	1

; nombre de configuration.
nbconfig
	DS	1

; accŠs aux donn‚es r‚sidentes.
_infos	Ds.l	1

; position courante.
wconfig	DS	1

; configuration s‚lectionn‚e.
selconf	DS	1

; rectangle de l'‚cran.
screen_rec
	DS.b	rec_size

; handle de la fenetre.
whandle	DS	1

; Rectangle a redessiner.
rdrw_rec
	DS.b	rec_size

; Rectangles tampon.
dum_rec	DS.b	rec_size
work_rec
	DS.b	rec_size

; pile.
	DS.b	8192
STACK
	DS.b	8
