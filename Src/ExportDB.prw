#Include "Totvs.ch"
#include "tryexception.ch"

Static cFileIDB := "DTCTODB"
Static cFileLOG := "DTCLOG"
Static aStruLog := { 	{ "TABELA", "C", 10, 0 }, { "DATA_", "D", 8, 0 }, { "HORA_", "C", 8, 0 },;
		 				{ "TIPO", "C", 1, 0 }, { "LOG", "C", 255, 0 }, { "ERROR", "M", 10, 0 } }


// 1. Dele��o da pasta \CPY\
User Function DelCpy

Local aData := Directory(Alltrim("\CPY\*.DTC")), aFiles := {}
Local nData := 1
Local cMsg  := ""

For nData := 1 To Len(aData)
	cMsg := "Deletando Arquivo " + aData[nData][1]
	ConOut(cMsg)
	PtInternal(1,cMsg)
	Ferase("\CPY\" + aData[nData][1])
Next

Return

// 2. Gera��o da pasta \CPY\ a partir do SX2
User Function DbToDtc

Local aFiles  := {}
Local lPula   := .F.
Local cTabela := cTabSQL := ""
Local nFiles  := 1 

If ! MyOpenSM0()
	Return
EndIf

If ! MSFile(cFileLOG, , "TOPCONN")
	DbCreate(cFileLOG,aStruLog,"TOPCONN")
ElseIf MsgYesNo("Limpar o conteudo da tabela [" + cFileLog + "] ?")
	TcSqlExec("DELETE FROM " + cFileLOG )
EndIF

//   %noparser%    
UpdLog("", "Inicio", "")

DbSelectArea("SX2")
DbGoTop()

While ! SX2->(Eof())
    cTabela := AllTrim(SX2->X2_ARQUIVO)
    cTabSQL := "%" + cTabela + "%"
    cArq := "\cpy\"+cTabela + ".dtc"
    UpdLog(cTabela, "Verificando Tabela: " + cTabela, "")
    lPula := .T.

	If MsFile(cTabela)
		BeginSQL Alias "QRY"
			Select COUNT(*) AS REGDB
			  FROM %Exp:cTabSQL% 
			 WHERE D_E_L_E_T_ = ' '
		EndSQL
		lPula := QRY->REGDB == 0
		QRY->(DbCloseArea())
	EndIf

    If File(cArq) .Or. lPula
       DbSelectArea("SX2")
       DbSkip()
       Loop
    EndIf

	Aadd(aFiles, cTabela)
    UpdLog(cTabela, "Copiando Tabela: " + cTabela, "")

	SX2->(DbSkip())
	If Len(aFiles) = 10 .Or. SX2->(Eof())
		cFiles := ""
		For nFiles := 1 To Len(aFiles)
			cFiles += aFiles[nFiles] + ", "
		Next
		UpdLog("", "Executando thread para gera��o das tabela: " + cFiles + " - Inicio", "")
		StartJob( "U_CPYGRDTC()" , GetEnvServer(), .F., aFiles)
		UpdLog("", "Executando thread para gera��o das tabela: " + cFiles + " - Fim", "")
		aFiles := {}
	EndIf
EndDo

UpdLog("", "Fim", "")

Return

User Function CountDB

Local cTabela := cTabSQL := cLog := ""
Local oExcel  := FWMSEXCEL():New()

If ! MyOpenSM0()
	Return
EndIf

cLog := 'REGDB_'+cEmpAnt + '_' + dtos(date()) + strtran(time(),':','')+'.XML'

DbSelectArea("SX2")
DbGoTop()

//	Criando as planilhas no pasta
oExcel:AddworkSheet("Tabelas")

//	Criando os nomes das tabelas
oExcel:AddTable ("Tabelas","Registros")

// Criando as colunas
oExcel:AddColumn("Tabelas","Registros","Prefixo", 1, 1)
oExcel:AddColumn("Tabelas","Registros","Arquivo", 1, 1)
oExcel:AddColumn("Tabelas","Registros","Descrição", 1, 1)
oExcel:AddColumn("Tabelas","Registros","Registros", 1, 1)

While ! SX2->(Eof())
    cTabela := AllTrim(SX2->X2_ARQUIVO)
    cTabSQL := "%" + cTabela + "%"
    UpdLog(cTabela, "Verificando Tabela: " + cTabela, "")

	If MsFile(cTabela)
		BeginSQL Alias "QRY"
			Select COUNT(*) AS REGDB
			  FROM %Exp:cTabSQL% 
			 WHERE D_E_L_E_T_ = ' '
		EndSQL
		If QRY->REGDB > 0
			oExcel:AddRow(	"Tabelas","Registros",;
						{	SX2->X2_CHAVE,;
							cTabela,;
							SX2->X2_NOME,;
							AllTrim(Str(QRY->REGDB)) })
		EndIF
		QRY->(DbCloseArea())
	EndIf

	SX2->(DbSkip())
EndDo

oExcel:Activate()
oExcel:GetXMLFile("\TEMP\"+cLog)
__Copyfile("\TEMP\"+cLog, "c:\TEMP\"+cLog)
Alert("Resultado copiado em C:\TEMP\"+cLog)	
UpdLog("", "Fim", "")

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
User Function CPYGRDTC( aFiles )
Local cTabela := ""
Local cArq    := "" 
Local nFiles  := 1
If ! MyOpenSM0()
	RETURN
EndIf
For nFiles := 1 To Len(aFiles)
    cTabela := aFiles[nFiles]
    cArq := "\cpy\"+cTabela + ".dtc"
    UpdLog(cTabela, "Abrindo Tabela: " + cTabela, "")
    If Select(cTabela) > 0
      	DbSelectArea(cTabela)
      	DbCloseArea()
    EndIf
    dbUseArea(.T.,"TOPCONN", cTabela, cTabela,.T.)
    If Select(cTabela) > 0
    	UpdLog(cTabela, "Copiando a Tabela: " + cTabela, "")
      	COPY TO &cArq VIA "CTREECDX"
      	DbCloseArea()
    Else
    	UpdLog(cTabela, "A tabela n�o pode ser aberta", "")
    EndIf
Next
Return
User Function CpSxsCli
Local aData := {}
Local nData := 1
Local cTime := Time()
Local cDir  := AllTrim(cGetFile("*.*","Selecione o diret�rio",,"c:\temp\sxs\",.F.,GETF_NETWORKDRIVE+GETF_LOCALFLOPPY+GETF_LOCALHARD+GETF_RETDIRECTORY))
Local cFile := ""
Local cMsg  := ""
If ! MyOpenSM0()
	RETURN
EndIf
cFile := "\SYSTEM\S??" + cEmpAnt + "0.DTC"
aData := Directory(Alltrim(cFile))
ConOut(cFile + ": Files " + AllTrim(Str(Len(aData))))
For nData := 1 To Len(aData)
	cFile := UPPER(aData[nData][1])
	cMsg := "Copiando " + cFile
	ConOut(cMsg)
	PtInternal(1, cMsg)
	__CopyFile("\SYSTEM\" + cFile, cDir + cFile)
Next
Alert("CpSxsCli: Inicio em " + cTime + " - Final em " + Time())
Return
User Function CpDtcCli
Local aData := Directory(Alltrim("\CPY\*.DTC")), aFiles := {}
Local nData := 1
Local cTime := Time()
Local cDir  := AllTrim(cGetFile("*.*","Selecione o diret�rio",,"c:\temp\cpy\",.F.,GETF_NETWORKDRIVE+GETF_LOCALFLOPPY+GETF_LOCALHARD+GETF_RETDIRECTORY))
Local cFile := ""
For nData := 1 To Len(aData)
	cFile := UPPER(aData[nData][1])
	__CopyFile("\CPY\" + cFile, cDir + cFile)
Next
Alert("CpDtcCli: Inicio em " + cTime + " - Final em " + Time())
Return
User Function CpDatSrv
Local cDir := AllTrim(cGetFile("*.*","Selecione o diret�rio",,"c:\temp\cpy\",.F.,GETF_NETWORKDRIVE+GETF_LOCALFLOPPY+GETF_LOCALHARD+GETF_RETDIRECTORY))
If Empty(cDir)
	Alert("� obrigat�rio a sele��o do diret�rio")
EndIf
CpFilSrv(cDir, "\cpy\", .f., .t.)
Return
User Function CpSxsSrv
Local cDir := AllTrim(cGetFile("*.*","Selecione o diret�rio",,"c:\temp\sxs\",.F.,GETF_NETWORKDRIVE+GETF_LOCALFLOPPY+GETF_LOCALHARD+GETF_RETDIRECTORY))
If Empty(cDir)
	Alert("� obrigat�rio a sele��o do diret�rio")
EndIf
CpFilSrv(cDir, "\system\", .t., .f.)
Return
User Function CpCfgSrv
Local cDir := AllTrim(cGetFile("*.*","Selecione o diret�rio",,"c:\temp\sxs\",.F.,GETF_NETWORKDRIVE+GETF_LOCALFLOPPY+GETF_LOCALHARD+GETF_RETDIRECTORY))
If Empty(cDir)
	Alert("� obrigat�rio a sele��o do diret�rio")
EndIf
CpFilSrv(cDir, "\system\", .f., .f.)
Return
Static Function CpFilSrv(cArqPath, cPatDest, lDelCdx, lUpDb)
Local aData    := Directory(Alltrim(cArqPath + "*.*")), aFiles := {}
Local nData    := 1
Local cFile    := ""
Local aStruIDB := { { "TABELA", "C", 10, 0 }, { "LOCAL", "N", 6, 0 }, { "REGDB", "N", 6, 0 } }
	If lUpDb
		If ! MyOpenSM0()
			RETURN
		EndIf
		
		RDDSetDefault("CTREECDX")
		If ! MSFile(cFileIDB, , "TOPCONN")
			DbCreate(cFileIDB,aStruIDB,"TOPCONN")
		Else
			TcSqlExec("DELETE FROM " + cFileIDB + " WHERE REGDB = 0" )
		EndIF
	EndIf
	
	nHdl := FCreate("\cpy\cpytodbf.log")
	For nData := 1 To Len(aData)
		Aadd(aFiles, UPPER(aData[nData][1]))
	Next
	For nData := 1 To Len(aFiles)
		cFile := StrTran(aFiles[nData], ".DTC", "")
		If lUpDb
			BeginSQL Alias "QRY"
				Select REGDB
				  FROM DTCTODB
				 WHERE TABELA = %Exp:cFile% AND D_E_L_E_T_ = ' '
			EndSQL
			IF QRY->REGDB > 0
				QRY->(DbCloseArea())
				Loop
			EndIf
			QRY->(DbCloseArea())
		EndIf
		If ! lUpDb
			cFile := cPatDest + StrTran(aFiles[nData], "DTC", "CDX")
			PtInternal(1,"Deletando Arquivo " + cFile)
			FWrite(nHdl, Dtoc(Date()) + "-" + Time() + " - Deletando Arquivo " + cFile + Chr(13) + Chr(10))
			Ferase(cFile)
		EndIf
		
		cFile := cArqPath + aFiles[nData]
		PtInternal(1,"Copiando Arquivo " + cFile)
		FWrite(nHdl, Dtoc(Date()) + "-" + Time() + " - Copiando Arquivo " + cFile + Chr(13) + Chr(10))
		//If ! File(cPatDest + aFiles[nData])
			__CopyFile(cFile, cPatDest + aFiles[nData])
		//EndIf
		
		If lUpDb
			PtInternal(1,"Abrindo Arquivo " + cPatDest + aFiles[nData] + " e contando registros ...")
			dbUseArea(.T.,"CTREECDX", cPatDest + aFiles[nData], "TAB", .T.)
			FWrite(nHdl, Dtoc(Date()) + "-" + Time() + " - Tabela: " + cPatDest + aFiles[nData] + ": " + AllTrim(Str(TAB->(LastRec()))) + Chr(13) + Chr(10))
			
			TcSqlExec("INSERT INTO " + cFileIDB + "(TABELA, LOCAL, R_E_C_N_O_) " +;
						   "VALUES('" + StrTran(aFiles[nData], ".DTC", "") + "', " + AllTrim(Str(TAB->(LastRec()))) + ", " +;
						   "COALESCE((SELECT MAX(R_E_C_N_O_) + 1 FROM " + cFileIDB + "), 1))")
			TAB->(DbCloseArea())
		EndIf
	Next
	FClose(nHdl)
	__CopyFile("\cpy\cpytodbf.log", "c:\temp\cpy\log\cpytodbf.log")
Return
//------------------------------------------------------------------
/*/{Protheus.doc} CPYAPDTD
JOB para appendar uma tabela no banco dropando a tabela existente
@type function
@author Mobile
@since 14/06/2018
@version 1.0
@param aFiles, Array, 1. cFile, Caractere, Alias do dicion�rio referente a X2_CHAVE
                      2. Nome da tabela para o banco de dados 
                      3. Diret�rio e nome do arquivo a ser importado do servidor
/*/
//------------------------------------------------------------------
User Function CPYAPDTD( aFiles )
Local aStru  := {}
Local nHdl 	 := 0
Local cFile  := cTabDb := cTabImp := ""
Local nFiles := 1 
If ! MyOpenSM0()
	RETURN
EndIf
For nFiles := 1 To Len(aFiles)
TRY EXCEPTION
	cFile   := aFiles[nFiles][1] 
	cTabDB  := aFiles[nFiles][2] 
	cTabImp := aFiles[nFiles][3] 
	UpdLog(cTabDB, "Importa��o: " + cFile + " - Inicio", "")
	
	If Select(Left(cFile, 3)) == 0 
		UpdLog(cTabDB, "Abrindo Arquivo " + cTabImp, "")
		dbUseArea(.T.,"CTREECDX", cTabImp, cFile, .T.)
		UpdLog(cTabDB, "Arquivo Origem " + cTabImp + "-" + AllTrim(Str(LastRec())), "")
		
		PtInternal(1,"Apagando Arquivo " + cFile)
		If MsFile(cTabDb)
			MsErase(cTabDB)
		EndIf
		aStru := DbStruct()
		DbCloseArea()
		UpdLog(cTabDB, "Criando Arquivo TOPCONN: " + cFile, "")
		MsCreate(cTabDb, aStru, 'TOPCONN' )
	EndIf
	
	UpdLog(cTabDB, "Contando Registros Arquivo TOPCONN: " + cTabDb, "")
	dbUseArea(.T.,"TOPCONN",cTabDb,"QRY",.T.)
	UpdLog(cTabDB, "Antes - Arquivo " + cTabDb + "-" + AllTrim(Str(LastRec())), "")
	QRY->(DbCloseArea())
	
	// DbSelectArea(Left(cFile, 3))
	UpdLog(cTabDB, "Apagando Arquivo " + cTabDB, "")
	TcSqlExec( "DELETE FROM " + cTabDB)
	TCRefresh(cTabDB)
	
	UpdLog(cTabDB, "Appendando Arquivo TOPCONN: " + cFile, "")
	dbUseArea(.T.,"TOPCONN", cTabDB, cTabDB, .T., .F.)
	Append From (cTabImp)
	UpdLog(cTabDB, "Antes - Arquivo " + cTabDb + "-" + AllTrim(Str(LastRec())), "")
	DbCloseArea()
	UpdLog(cTabDB, "Contando Registros TOPCONN: " + cTabDb, "")
	dbUseArea(.T.,"TOPCONN",cTabDb,"QRY",.T.)
	TcSqlExec("UPDATE " + cFileIDB + " SET REGDB = " + AllTrim(Str(QRY->(LastRec()))) + " WHERE TABELA = '" + cTabDB + "'")
	UpdLog(cTabDB, "Depois - Arquivo " + cTabDb + "-" + AllTrim(Str(QRY->(LastRec()))), "")
	QRY->(DbCloseArea())
	
	UpdLog(cTabDB, "Importa��o: " + cFile + " - Fim", "")
CATCH EXCEPTION USING oError
	UpdLog(cTabDB, "Arquivo " + cFile, "Erro: " + oError:Description)
END TRY
Next
Return	
User Function IDtcToDb
Local cPath  := "\CPY\"
Local nHdl   := FCreate("\cpy\idtctodb.log")
Local nFiles := 1
Local aFiles := {}
Local cFiles := ""
Local cSQL	 := ""
If ! MyOpenSM0()
	RETURN
EndIf
UpdLog("", "Inicio", "")
If ! MSFile(cFileLOG, , "TOPCONN")
	DbCreate(cFileLOG,aStruLog,"TOPCONN")
Else
	TcSqlExec("DELETE FROM " + cFileLOG )
EndIF
BeginSQL Alias "QRYDB"
	Select TABELA
	  FROM DTCTODB
	 WHERE LOCAL <> REGDB AND D_E_L_E_T_ = ' '
	 ORDER BY TABELA
EndSQL
While ! QRYDB->(Eof())
	PtInternal(1,"Copiando Arquivo " + QRYDB->TABELA)
	Aadd(aFiles, {LEFT(QRYDB->TABELA, 3), AllTrim(QRYDB->TABELA), cPath + AllTrim(QRYDB->TABELA) + ".dtc"})
	QRYDB->(DbSkip())
	If Len(aFiles) = 10 .Or. QRYDB->(Eof())
		cFiles := ""
		For nFiles := 1 To Len(aFiles)
			If ! Empty(cFiles)
				cFiles += ","
			EndIf
			cFiles += aFiles[nFiles][2]
		Next
		UpdLog("", "Executando thread para importa��o das tabela: " + cFiles + " - Inicio", "")
		//StartJob( "U_CPYAPDTD()" , GetEnvServer(), .F., aFiles)
		U_CPYAPDTD(aFiles)
		UpdLog("", "Executando thread para importa��o das tabela: " + cFiles + " - Fim", "")
		aFiles := {}
	EndIf
EndDo
UpdLog("", "Fim", "")
__cInternet := Nil
MostraErro("", "IDtcToDb.Log")
Return
Static Function UpdLog(cTabela, cLog, cError)
Local nHdl   := nHdlTmp := 0
Local nFiles := 0
Local aFiles := {}
Local cLinha := ""
Local aArea  := GetArea()
Local cErrorS:= ""
PtInternal(1,Dtoc(Date()) + "-" + Time() + " - " + cLog)
ProcessMessage()
If Select(cFileLog) = 0
	If ! MSFile(cFileLOG, , "TOPCONN")
		DbCreate(cFileLOG,aStruLog,"TOPCONN")
	EndIf
	dbUseArea(.T.,"TOPCONN", cFileLog, cFileLog, .T., .F.)
EndIf
cLog := Left(cLog, 255)
RecLock(cFileLog, .T.)
(cFileLog)->TABELA := cTabela
(cFileLog)->DATA_ := Date()
(cFileLog)->HORA_ := Time()
(cFileLog)->TIPO := If(cError <> "", "2", "1")
(cFileLog)->LOG := cLog
(cFileLog)->ERROR := cError
RestArea(aArea)
If ! Empty(cError)
	cError := " - " + cError
EndIf 
cLog := Dtoc(Date()) + "-" + Time() + ": " + cLog + cError + cErrorS + Chr(13) + Chr(10)
ConOut(cLog)
AutoGrLog(cLog)
Return
Static WaitLog
While File("\cpy\upd.log")
	nFiles ++
	PtInternal(1,"Aguardando libera��o do arquivo \cpy\upd.log [" + AllTrim(Str(nFiles)) + "]")
EndDo
nHdlTmp	:= FCreate("\cpy\upd.log")
FClose(nHdlTmp)
nHdl := FT_FUse("\cpy\idtctodb.log")
FT_FGoTop ()
cLinha := FT_FREADLN()
Do While !FT_FEof()
	If ! Empty(cLinha)
		aAdd (aFiles, AllTrim(cLinha))
	EndIf
	FT_FSkip ()
	cLinha := FT_FREADLN()
EndDo
FClose(nHdl)
nHdl := FCreate("\cpy\idtctodb.log")
For nFiles := 1 To Len(aFiles)
	FWrite(nHdl, aFiles[nFiles] + Chr(13) + Chr(10))
Next
FWrite(nHdl, cLog + Chr(13) + Chr(10))
FClose(nHdl)
__CopyFile("\cpy\idtctodb.log", "c:\temp\cpy\log\idtctodb.log")
Ferase("\cpy\upd.log")
Return
User Function CriaSix
Local aData := Directory(Alltrim("\CPY\*.DTC")), aFiles := {}
Local nData := 1
If ! MyOpenSM0()
	RETURN
EndIf
Alert("CriaSX: Inicio em " + Time())
For nData := 1 To Len(aData)
	Aadd(aFiles, UPPER(aData[nData][1]))
Next
For nData := 1 To Len(aFiles)
	cFiles := Left(aFiles[nData], 3)
	If AliasInDic(cFiles)
		PtInternal(1,"Criando indices da tabela " + cFiles)
		DbSelectArea(cFiles)
	EndIf
Next
Alert("CriaSX: Final em " + Time())
Return
	
//--------------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Abertura do arquivo SIGAMAT.EMP quando necess�rio
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
	Return .T.
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
	
	__cInternet := Nil
	
Return .T.
