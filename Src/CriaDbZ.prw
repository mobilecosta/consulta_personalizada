#Include "Totvs.ch"

User Function CopiaDBZ

If ! MyOpenSM0()
	Return .F.
EndIf

ConOut("CopiaDBZ: " + cEmpAnt + " - Inicio - Data: " + Dtoc(dDataBase) + "-" + Time())

DbSelectArea("SX3")
DbSetOrder(1)

DbSelectArea("SIX")
DbSetOrder(1)

DbSelectArea("SX2")
DbGoTop()
While ! Eof()
	If File("\DATA\" + AllTrim(SX2->X2_ARQUIVO) + "#.dtc")
		DbSelectArea("SX2")
		DbSkip()
		Loop
	EndIf
	
	DbSelectArea("SX3")
	If ! DbSeek(SX2->X2_CHAVE)
		ConOut("Alias [" + SX2->X2_CHAVE + "] não localizado ")
		DbSelectArea("SX2")
		DbSkip()
		Loop
	EndIf

	DbSelectArea("SIX")
	If ! DbSeek(SX2->X2_CHAVE)
		ConOut("Indice [" + SX2->X2_CHAVE + "] não localizado ")
		DbSelectArea("SX2")
		DbSkip()
		Loop
	EndIf

	cMsg := "Copiando " + AllTrim(SX2->X2_ARQUIVO)
	ConOut(cMsg)
	PtInternal(1,cMsg)
	DbSelectArea(SX2->X2_CHAVE)
	aStru := DbStruct()

	DbCreate("\DATA\" + AllTrim(SX2->X2_ARQUIVO)+ "#",aStru,"CTREECDX")
	DbCloseArea()
	
	DbSelectArea("SX2")
	DbSkip()
EndDo

ConOut("CopiaDBZ" + cEmpAnt + " - Fim - Data: " + Dtoc(dDataBase) + "-" + Time())

Return

User Function GerDBZ

Local aData  := Directory(Alltrim("\DATA\*#.DTC")), nData := 1
Local aFiles := {}, cFiles := ""

If ! MyOpenSM0()
	Return .F.
EndIf

ConOut("GerDBZ - Inicio - Data: " + Dtoc(dDataBase) + "-" + Time())

For nData := 1 To Len(aData)
	cAlias := StrTran(Upper(aData[nData][1]), ".DTC", "")
	If MSFile(cAlias, , "TOPCONN")
		Loop
	EndIf
	
	Aadd(aFiles, cAlias)

	If Len(aFiles) = 5000 .Or. nData = Len(aData)
		cFiles := ""
		For nFiles := 1 To Len(aFiles)
			cFiles += aFiles[nFiles] + ", "
		Next
		ConOut("Executando thread para geração das tabela: " + cFiles + " - Inicio")
		StartJob( "U_GZTABLE" , GetEnvServer(), .F., aFiles)
		ConOut("Executando thread para geração das tabela: " + cFiles + " - Fim")
		aFiles := {}
	EndIf
Next

ConOut("GerDBZ - Fim - Data: " + Dtoc(dDataBase) + "-" + Time())

Return

//------------------------------------------------------------------
/*/{Protheus.doc} CPYGRDTC
JOB para gerar dtc a partir de lista
@type function
@author Mobile
@since 28/06/2018
@version 1.0
@param aFiles, Array, 1. cFile, Caractere, Nome da tabela para copia
/*/
//------------------------------------------------------------------
User Function GZTABLE( aFiles )
Local cAlias := "", aStru := {}
Local nFiles := 1
MyOpenSM0()
For nFiles := 1 To Len(aFiles)
    cAlias := aFiles[nFiles]
	cMsg := "Abrindo Arquivo \data\" + cAlias
	ConOut(cMsg)
	PtInternal(1,cMsg)
	
    dbUseArea(.T.,"CTREECDX", "\data\" + cAlias, cAlias,.T.)
    aStru := DbStruct()
    DbCloseArea()
	cMsg := "Criando Arquivo " + cAlias
	ConOut(cMsg)
	PtInternal(1,cMsg)
	
	DbCreate(cAlias,aStru,"TOPCONN")
Next
Return
User Function DropDBZ
Local aData  := Directory(Alltrim("\DATA\*#.DTC")), nData := 1
Local cAlias := "", aStru := {}
MyOpenSM0()
/*
BEGINSQL ALIAS "QRY"
	SELECT FIELD_TABLE AS ALIAS FROM TOP_FIELD WHERE FIELD_TABLE LIKE '%V25%'
 	GROUP BY FIELD_TABLE
	ORDER BY FIELD_TABLE
EndSQL
While ! QRY->(Eof())
	cAlias := StrTRan(AllTrim(QRY->ALIAS), "PRJUPDT12.", "")
	cMsg := "Deletando Arquivo " + cAlias
	ConOut(cMsg)
	PtInternal(1,cMsg)
	MsErase(cAlias)
	QRY->(DbSkip())
EndDo	
*/
For nData := 1 To Len(aData)
	cAlias := StrTran(Upper(aData[nData][1]), ".DTC", "")
	cMsg := "Deletando Arquivo " + cAlias
	ConOut(cMsg)
	PtInternal(1,cMsg)
	MsErase(cAlias)
Next
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
Static Function MyOpenSM0()
Local aParam    := {}
Local cCadastro := "Selecao da Empresa"
If Select("SM0") > 0
	Return
EndIf
	dbUseArea( .T., , 'SIGAMAT.EMP', 'SM0', .T., .F. )
	dbSetIndex( 'SIGAMAT.IND' )
	Set Delete On
	Set Filter to M0_CODIGO <> ' '
	DbGoTop()
	RpcSetType( 3 )
	RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )
	__cInternet := Nil
	If LastRec() > 1 .And. ! IsBlind()
		Aadd(aParam, {1, "Empresa", Space(2), "@!"	, "", "SM0", "", 002, .F.})
		
		IF ! ParamBox(aParam, "Parametros da rotina",, {|| AllwaysTrue()},,,,,,, .F.)
			Return .F.
		Endif
		SM0->(DbSeek(mv_par01))
		cOEmp := SM0->M0_CODIGO
		cOFil := SM0->M0_CODFIL
		RpcClearEnv()
		RpcSetEnv( cOEmp, cOFil )
	EndIf
Return .t.
