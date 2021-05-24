#Include "Totvs.Ch"
User Function GERSXDB()
Local aLinha := {}
aTables := {}

OpenSM0()


lCpyLocal := MsgYesNo("Deseja copiar o(s) pacote(s) gerado para [C:\TEMP\QUERY] ?")

aTables := {}

If File("\query\config.txt")
	nHdl := FT_FUse("\query\config.txt")
	FT_FGoTop ()

	Do While !FT_FEof()
		aLinha := WfTokenChar(StrTran(Ft_FReadLn(), Chr(13) + Chr(10)), ";")
		
		For nLinha := 1 To Len(aLinha)
			If Left(aLinha[nLinha], 1) = '{'
				aLinha[nLinha] := &(aLinha[nLinha]) 
			EndIf
		Next
		
		Aadd(aTables, aLinha)

		FT_FSkip ()
	EndDo
	
	FClose(nHdl)
EndIf
					
MsAguarde({|| RunProc() }, "Geração pacote de instalação", "Processando tabelas. Aguarde....", .T.)

Alert("Pacote(s) gerado(s) na pasta [\query] com sucesso !!")

Return

Static Function RunProc

Local cSXB     := cSX5 := cSXG := ""
Local nTables := 0 
Local nPos 	  := 1

For nTables := 1 To Len(aTables)
	__PACOTE := aTables[nTables][1]
	
	__DIR := "\query\" + aTables[nTables][1] + "\"
	if ! ExistDir(__DIR)
		Loop
	EndIf
	
	__TABLES  := aTables[nTables][2]
	__SX1 	  := aTables[nTables][3]
	__X7CAMPO := aTables[nTables][4]
	cSX5 	  := aTables[nTables][5]
	cSXB	  := ""
	cSXG	  := ""
	__X6VAR   := aTables[nTables][6]
	
	Ferase(__DIR + "sx1.dbf")
	Ferase(__DIR + "sx2.dbf")
	Ferase(__DIR + "sx3.dbf")
	Ferase(__DIR + "sx5.dbf")
	Ferase(__DIR + "six.dbf")
	Ferase(__DIR + "sx7.dbf")
	Ferase(__DIR + "sx9.dbf")
	Ferase(__DIR + "sxa.dbf")
	Ferase(__DIR + "sxb.dbf")
	Ferase(__DIR + "sxg.dbf")
	Ferase(__DIR + "sxv.dbf")
	
	MsAguarde({|| GerSX1(@cSXB,@cSX5) }, "Geração pacote de instalação", "Gerando [" + __DIR + "sx1.dbf]. Aguarde....", .T.)
	ProcessMessage()

	MsAguarde({|| GerSX2() }, "Geração pacote de instalação", "Gerando [" + __DIR + "sx2.dbf]. Aguarde....", .T.)
	ProcessMessage()
	
	MsAguarde({|| GerSX3(@cSXB,@cSX5,@cSXG) }, "Geração pacote de instalação", "Gerando [" + __DIR + "sx3.dbf]. Aguarde....", .T.)
	ProcessMessage()

	MsAguarde({|| GerSX5(cSX5) }, "Geração pacote de instalação", "Gerando [" + __DIR + "sx5.dbf]. Aguarde....", .T.)
	ProcessMessage()
	MsAguarde({|| GerSX6() }, "Geração pacote de instalação", "Gerando [" + __DIR + "sx6.dbf]. Aguarde....", .T.)
	ProcessMessage()

	MsAguarde({|| GerSIX() }, "Geração pacote de instalação", "Gerando [" + __DIR + "six.dbf]. Aguarde....", .T.)
	ProcessMessage()

	MsAguarde({|| GerSX7() }, "Geração pacote de instalação", "Gerando [" + __DIR + "sx7.dbf]. Aguarde....", .T.)
	ProcessMessage()

	MsAguarde({|| GerSX9() }, "Geração pacote de instalação", "Gerando [" + __DIR + "sx9.dbf]. Aguarde....", .T.)
	ProcessMessage()

	MsAguarde({|| GerSXA() }, "Geração pacote de instalação", "Gerando [" + __DIR + "sxa.dbf]. Aguarde....", .T.)
	ProcessMessage()

	MsAguarde({|| GerSXB(cSXB) }, "Geração pacote de instalação", "Gerando [" + __DIR + "sxb.dbf]. Aguarde....", .T.)
	ProcessMessage()

	MsAguarde({|| GerSXG(cSXG) }, "Geração pacote de instalação", "Gerando [" + __DIR + "sxg.dbf]. Aguarde....", .T.)
	ProcessMessage()

	MsAguarde({|| GerSXV() }, "Geração pacote de instalação", "Gerando [" + __DIR + "sxv.dbf]. Aguarde....", .T.)
	ProcessMessage()
Next

Return


Static Function GerSX1(cSXB,cSX5)

Local cFile := __DIR + "sx1.dbf"

If Empty(__SX1)
	Return .T.
EndIf

// Tabelas
DbSelectArea("SX1")
DbSetOrder(1)
dbUseArea(.T.,"CTREECDX","\SX\SX1990.DTC","SX1",.F.)

If At(",", __SX1) > 0
	Set Filter to AllTrim(X1_GRUPO) $ __SX1
Else
	Set Filter to LEFT(X1_GRUPO, Len(__SX1)) = __SX1
EndIf
FileCopy(cFile)

If File(cFile)
	dbUseArea(.T.,"CTREECDX", cFile, "SX1QRY",.F.)
	Set Filter to X1_F3 <> " "
	DbGoTop()
	While ! Eof()
		If At(X1_F3 + ";", cSXB) == 0 .And. SXB->(DbSeek(SX1QRY->X1_F3))
			cSXB += X1_F3 + ";"
		ElseIf At(X1_F3 + ";", cSX5) == 0 .And. SX5->(DbSeek(xFilial() + "00" + SX1QRY->X1_F3))
			cSX5 += X1_F3 + ";"
		EndIF
	
		DbSkip()
	EndDo
	SX1QRY->(DbCloseArea())
EndIf

DbSelectArea("SX1")
Set Filter To
DbGoTop()

Return

Static Function GerSX2()

Local cFile   := __DIR + "sx2.dbf"
Local�cFilter :=�""



DbSetOrder(1)
DbUseArea(.T.,"CTREECDX","\SX\SX2990.DTC","SX2",.F.)


DbUseArea(.T.,"CTREECDX","\SX\SX3990.DTC","SX3",.F.)

 
// Cria o arquivo de indice para a tabela temporaria
      aIndTrb := { "X2_CHAVE" } 
			For nI := 1 to len(aIndTrb)
			 IndRegua("SX2", "SX2" + Str(nI, 1), aIndTrb[nI],,,'...')
			Next nI
		
			dbClearIndex()
		
			For nI := 1 to len(aIndTrb)
			  dbSetIndex("SX2" + Str(nI, 1) + OrdBagExt())
			Next nI


DbSetOrder(1)




Set Filter to X2_CHAVE $ __TABLES .And. X2_PATH = "\data\" 
DbGoTop()



// Copia dos dados da tabela
While ! Eof()
	DbSelectArea("SX2")
	DbSeek(SX2->X2_CHAVE)
	cFL_FILIAL := SX3->X3_CAMPO

	DbSelectArea(SX2->X2_CHAVE)
	cFilter := ""

	If Len(&(cFL_FILIAL)) = 11 .And. SX2->X2_MODO = "E" 	
		cFilter := "LEN(ALLTRIM(" + cFL_FILIAL + ")) = 2"
	EndIf

	MsAguarde({|| 	FileCopy(__DIR + SX2->X2_CHAVE + "dat.dbf", cFilter) }, "Geração pacote de instalação",;
						"Gerando [" + __DIR + SX2->X2_CHAVE + "dat.dbf]. Aguarde....", .T.)
	DbSelectArea("SX2")
	DbSkip()
EndDo

If Empty(__TABLES)
	Set Filter to AllTrim(SX2->X2_PATH) == "\query\" .or. AllTrim(SX2->X2_PATH) == "\custom\" 
	DbGoTop()
ElseIf __PACOTE == "pms"
	Set Filter to
Else
	Set Filter to X2_CHAVE $ __TABLES
Endif
DbGoTop()
FileCopy(cFile)

Return

Static Function GerSX3(cSXB, cSX5, cSXG)

Local cFile := __DIR + "sx3.dbf"

// Campos
DbSelectArea("SX3")
DbSetOrder(1)
dbUseArea(.T.,"CTREECDX","\SX\SX3990.DTC","SX3",.F.)

If __PACOTE == "pms"
	// Set Filter to X3_ARQUIVO $ __TABLES
ElseIf Empty(__TABLES)
	Set Filter to X3_PROPRI $ 'U,L'
Else
	Set Filter to X3_ARQUIVO $ __TABLES .And. X3_PROPRI $ 'U,L'
EndIf
FileCopy(cFile)

If File(cFile)
	
	dbUseArea(.T.,"CTREECDX", cFile, "SX3QRY",.F.)
	 
	DbGoTop()
	While ! Eof()
		//Verificao se o campo x3_F3  está preenchido 
		if ! Empty(X3_F3) 
			If  At(X3_F3 + ";", cSXB) == 0 .And. SXB->(DbSeek(SX3QRY->X3_F3))
				cSXB += X3_F3 + ";"
			ElseIf At(X3_F3 + ";", cSX5) == 0 .And. SX5->(DbSeek(xFilial() + "00" + SX3QRY->X3_F3))
				cSX5 += X3_F3 + ";"
			EndIF
		EndIF
	
		If  ! Empty(X3_GRPSXG) .And.(X3_GRPSXG + ";", cSXG) == 0 .And. X3_PROPRI = "U"
			cSXG += X3_GRPSXG + ";"
		endif
		cX3_RESERV:=""
		cX3_OBRIGAT:= ""
		cX3_USADO:=  "x       x       x       x       x       x       x       x       x"+;
						"       x       x       x       x       x       x       "
        If ! "_FILIAL" $ Upper(SX3->X3_CAMPO)
			cX3_RESERV:= "     xx "
			cX3_OBRIGAT:=" "
			cX3_USADO:= "x       x       x       x       x       x       x       x"+;
			      		" x       x       x       x       x       x       x xx     "	
		EndIf

		SX3-> (RecLock("SX3", .F.))
		SX3->x3_reserv:= cX3_RESERV 
		SX3->X3_obrigat:= cX3_OBRIGAT
		SX3->X3_usado:= cX3_USADO
		MsUnlock ()
	
		DbSkip()
	EndDo
	
	SX3QRY->(DbCloseArea())
	
endif
Return

Static Function GerSX5(cF3)

Local cFile := __DIR + "sx5.dbf"

If Empty(cF3)
	Return
EndIf

// Consultas
DbSelectArea("SX5")
DbSetOrder(1)
Set Filter To (X5_TABELA = "00" .AND. X5_CHAVE + ";" $ cF3) .Or. X5_TABELA + Space(4) + ";" $ cF3
FileCopy(cFile)

Return

Static Function GerSIX()

Local cFile := __DIR + "six.dbf"

// Indices
DbSelectArea("SIX")
DbSetOrder(1)

dbUseArea(.T.,"CTREECDX","\SX\SIX9901.DTC","SIX",.F.)


If __PACOTE == "pms"
	// Set Filter to INDICE $ __TABLES
ElseIf Empty(__TABLES)
	Set Filter to PROPRI = 'U'
Else
	Set Filter to INDICE $ __TABLES .And. PROPRI = 'U'
EndIf
FileCopy(cFile)

Return

Static Function GerSX6()

Local cFile := __DIR + "sx6.dbf"

// Gatilhos
DbSelectArea("SX6")
DbSetOrder(1)


dbUseArea(.T.,"CTREECDX","\SX\SX6990.DTC","SX6",.F.)

If __PACOTE == "pms"
eLSEIf Empty(__TABLES)
	Set Filter to X6_PROPRI = 'U'
Else
	Set Filter to FilterSX6(X6_VAR) .And. X6_PROPRI = 'U'
Endif 
FileCopy(cFile)

Return

Static Function FilterSX6(cX6_VAR)

Local lRet := .F.
Local nSX6 := 0
 
For nSX6 := 1 To Len(__X6VAR)
	If __X6VAR[nSX6] $ cX6_VAR
		lRet :=  .T.
	EndIf
Next

Return lRet

Static Function GerSX7()

Local cFile := __DIR + "sx7.dbf"

// Gatilhos
DbSelectArea("SX7")
DbSetOrder(1)
dbUseArea(.T.,"CTREECDX","\SX\SX7990.DTC","SX7",.F.)

If __PACOTE == "pms"
	//Set Filter to FilterSX7(X7_CAMPO)
ElseIf Empty(__TABLES)
	Set Filter to X7_PROPRI = 'U'
Else
	Set Filter to FilterSX7() .And. X7_PROPRI = 'U'
EndIf 
FileCopy(cFile)

Return

Static Function FilterSX7()

Local lRet := .F.
Local nSX7 := 0
 
For nSX7 := 1 To Len(__X7CAMPO)
	If __X7CAMPO[nSX7] $ SX7->X7_CAMPO
		lRet :=  .T.
	EndIf
Next

Return lRet

Static Function GerSX9()

Local cFile := __DIR + "sx9.dbf"

// Relacionamento
DbSelectArea("SX9")
DbSetOrder(1)
dbUseArea(.T.,"CTREECDX","\SX\SX9990.DTC","SX9",.F.)

If __PACOTE == "pms"
eLSEIf Empty(__TABLES)
	Set Filter to X9_PROPRI = 'U'
Else
	Set Filter to X9_DOM $ __TABLES .And. X9_PROPRI = 'U'
EndIf 
FileCopy(cFile)

Return

Static Function GerSXA()

Local cFile := __DIR + "sxa.dbf"

// Pastas
DbSelectArea("SXA")
DbSetOrder(1)
dbUseArea(.T.,"CTREECDX","\SX\SXA990.DTC","SXA",.F.)

If __PACOTE == "pms"
	// Set Filter to XA_ALIAS $ __TABLES 
ElseIf Empty(__TABLES)
	Set Filter to XA_PROPRI = 'U' 
Else
	Set Filter to XA_ALIAS $ __TABLES .And. XA_PROPRI = 'U' 
Endif
FileCopy(cFile)

Return

Static Function GerSXB(cF3)

Local cFile := __DIR + "sxb.dbf"

// Consultas
DbSelectArea("SXB")
DbSetOrder(1)

dbUseArea(.T.,"CTREECDX","\SX\SXB990.DTC","SXB",.F.)

Set Filter To XB_ALIAS $ cF3
FileCopy(cFile)

Return

Static Function GerSXG(cSXG)

Local cFile := __DIR + "sxg.dbf"

// Consultas
DbSelectArea("SXG")
DbSetOrder(1)

dbUseArea(.T.,"CTREECDX","\SX\SXG990.DTC","SXG",.F.)

Set Filter To XG_GRUPO $ cSXG .And. XG_GRUPO > "089"
FileCopy(cFile)

Return

Static Function GerSXV()

Local cFile := __DIR + "sxv.dbf"

// Marshup
DbSelectArea("SXV")
DbSetOrder(1)
dbUseArea(.T.,"CTREECDX","\SX\SXV9901.DTC","SXV",.F.)

Set Filter To XV_ALIAS $ __TABLES
FileCopy(cFile)

Return

Static Function FileCopy(cFile, cFilter)

Local cRDD := RDDSetDefault()

DbGoTop()
If Eof()
	Set Filter To
	DbGoTop()
	Return .T.
EndIf

RDDSetDefault("CTREECDX")

If ! Empty(cFilter)
	Copy To &(cFile) For &(cFilter)
Else
	Copy To &(cFile)
EndIf

If lCpyLocal
	cFileCpy := StrTran(Left(cFile, 6), "\query", "c:\temp\query") + Subs(cFile, 7)
	__CopyFile(cFile, cFileCpy)
	If File(StrTran(cFile, ".dbf", ".fpt"))
		__CopyFile(StrTran(cFile, ".dbf", ".fpt"), StrTran(cFileCpy, ".dbf", ".fpt"))
	EndIf
EndIf 

RDDSetDefault(cRdd)
Set Filter To
DbGoTop()

GerCsv(cFile,lCpyLocal)

Return

Static Function GerCSV(cFile,lCpyLocal)

Local nHdl   := FCreate(StrTran(cFile, ".dbf", ".txt"))
Local nField := 0
Local cCampo := cFileCpy := ""

If ! File(cFile)
	Return .T.
EndIf

use &(cFile) new alias "CSV" via "CTREECDX"
While ! Eof()
	cCampo := ""
	For nField := 1 To FCount()
	   cField := FieldName(nField)

		xValue := &("CSV->" + cField)

    	If ! Empty(cCampo)
      		cCampo += ";"
    	EndIf

		If ValType(xValue) = "C" .Or. ValType(xValue) = "M"
  			cCampo += AllTrim(xValue)
		ElseIf ValType(xValue) = "N"
	   		cCampo += AllTrim(Str(xValue))
  		ElseIf ValType(xValue) = "D"
   			cCampo += Dtos(xValue)
  		ElseIf ValType(xValue) = "L"
	   		cCampo += If(xValue, ".T.", ".F.")
    	EndIf
	Next
	
	FWrite(nHdl, cCampo + Chr(13) + Chr(10))
	DbSkip()
EndDo
FClose(nHdl)
If lCpyLocal
	cFileCpy := StrTran(Left(cFile, 6), "\query", "c:\temp\query") + Subs(cFile, 7)
	__CopyFile(StrTran(cFile, ".dbf", ".txt"), StrTran(cFileCpy, ".dbf", ".txt"))
EndIf

Return

//--------------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Abertura do arquivo SIGAMAT.EMP quando necessário
@author Wagner Mobile Costa
@since  29/06/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------

