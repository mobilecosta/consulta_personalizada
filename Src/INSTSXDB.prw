#Include 'Protheus.ch'

Static aTables  := {}
Static lUpdStru := .T.

//--------------------------------------------------------------------------
/*/{Protheus.doc} INSTSXDB
Rotina para instalação da Consulta Personalizada.
@author unknown programmer (unknown.programmer@unknown.programmer)
@since  03/04/2014
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
User Function INSTSXDB()
	Private Titulo   := "Instalação de Pacote SYNCSXDB"
	Private aSays    := {}
	Private aButtons := {}
	Private oText	 := Nil
	MyOpenSM0() 
	aAdd(aSays," Rotina para instalação de dicionários personalizados.")
	aAdd(aSays,"Empresa: " + SM0->M0_CODIGO + "-" + AllTrim(SM0->M0_NOME))
	aAdd(aSays," ATUALIZAÇÃO DE DICIONÝRIOS E TABELAS")
	aAdd(aSays," Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )")
	aAdd(aSays," além do conteudo destas tabelas")
	aAdd(aButtons,{ 1,.T.,{|o| Processa({|| RunProc(), FechaBatch() },Titulo,,.T.) }})
	aAdd(aButtons,{ 2,.T.,{|o| FechaBatch() }})
	FormBatch(Titulo,aSays,aButtons)
Return Nil
User Function UPDSXDB()
	Private Titulo   := "Criação e atualização tabelas a partir dos SXS"
	Private aSays    := {}
	Private aButtons := {}
	Private oText	 := Nil
	MyOpenSM0()
	
	If ! GetParams()
		Return .F.
	EndIf
	aAdd(aSays," ATUALIZAÇÃO DAS TABELAS")
	aAdd(aSays," Esta rotina tem como função cria todas as tabelas no banco a partir dos SXS.")
	aAdd(aButtons,{ 1,.T.,{|o| MsAguarde({|| AcsTable() },Titulo, "Criando as tabelas ...",.T.) }})
	aAdd(aButtons,{ 2,.T.,{|o| FechaBatch() }})
	FormBatch(Titulo,aSays,aButtons)
Return Nil
//--------------------------------------------------------------------------
/*/{Protheus.doc} RUNPROC
Rotina de processamento para instalação da Consulta Personalizada.
@author unknown programmer (unknown.programmer@unknown.programmer)
@since  03/04/2014
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function RUNPROC()
Local aArea    := GetArea()
Local cArqPath := "\query\"
Local aFil     := Directory(Alltrim(cArqPath + "*.DBF")), aFiles := {}
Local k        := 0
	If ! GetParams()
		Return .F.
	EndIf
	InitLog() 
	If Ascan(aFil, { |x| Upper(x[1]) == "SXG.DBF" }) > 0
		Aadd(aFiles, "SXG.DBF")
	EndIf
	For k := 1 To Len(aFil)
		If aFil[k][1] <> "SXG.DBF"
			Aadd(aFiles, aFil[k][1])
		EndIf
	Next
	//-- Atualiza dicionário
	For k := 1 to Len(aFiles)
		If Upper(aFiles[k]) $ "SIX.DBF,SX1.DBF,SX2.DBF,SX3.DBF,SX5.DBF,SX6.DBF,SX7.DBF,SX9.DBF,SXA.DBF,SXB.DBF,SXG.DBF,SXV.DBF"
			
			If !isBlind()
				MsAguarde({|| Load_SX(cArqPath + aFiles[k], StrTran(aFiles[k], ".DBF", "")) }, Titulo, "Atualizando [" + aFiles[k] + "]. Aguarde....", .T.)
			Else
				Load_SX(cArqPath + aFiles[k], StrTran(aFiles[k], ".DBF", ""))
				Conout("Atualizando [" + aFiles[k] + "]. Aguarde....")
			EndIf
				
		EndIf
	Next k
	If !isBlind()
		MsAguarde({|| UpdStru()}, Titulo, "Atualizando a estrutura das tabelas. Aguarde....", .T.)
	Else
		UpdStru()
	EndIf
	//-- Atualiza conteúdo
	For k := 1 to Len(aFiles)
		If Upper(Right(aFiles[k], 7)) $ "DAT.DBF"
			If !isBlind()
				MsAguarde({|| 	LoadData(StrTran(Left(aFiles[k], 3), cArqPath, ""), cArqPath + aFiles[k]) }, Titulo,;
							"Atualizando [" + aFiles[k] + "]. Aguarde....", .T.)
			Else
				LoadData(StrTran(Left(aFiles[k], 3), cArqPath, ""), cArqPath + aFiles[k])
				Conout("Atualizando [" + aFiles[k] + "]. Aguarde....")
			EndIf		
		EndIf
	Next
	If !isBlind()
		Alert("Instalação finalizada com sucesso !!")
	Else
		Conout("Instalação finalizada com sucesso !!")
	EndIf
	
	RestArea(aArea)
Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} AcsTable
Rotina para acessar a estrutura de todas as tabelas
@author unknown programmer (unknown.programmer@unknown.programmer)
@since  16/02/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function AcsTable()
Local lOk    	:= .T.
Local nRegs	 	:= 0
Local nRecX3 	:= 1
Local nRecX2 	:= 1
Local cFileX2  	:= cFileX3 := cSQL := cError := cX3_ARQUIVO := ""
Local aStruX2  	:= { 	{ "X2_CHAVE", "C", 3, 0 }, { "X2_ARQUIVO", "C", 10, 0 } }
Local aStruX3  	:= { 	{ "X3_ARQUIVO", "C", 3, 0 }, { "X3_CAMPO", "C", 10, 0 }, { "X3_TIPO", "C", 1, 0 }, { "X3_TAMANHO", "N", 3, 0 },;
						{ "X3_DECIMAL", "N", 2, 0 } }
Local cView		:= "SX3" + cEmpAnt + "0DUP" 						
cFileX2 := "SX2" + cEmpAnt + "0_DF"
cFileX3 := "SX3" + cEmpAnt + "0"
If ! MsgYesNo("Verifica Estrutura ?")
	Return .T.
EndIf
If (! MSFile(cFileX2, , "TOPCONN") .Or. ! MSFile(cFileX3, , "TOPCONN")) .Or.;
	MsgYesNo("Atualizar o SX3 ?")
	//-- Criação SX2
	If MSFile(cFileX2, , "TOPCONN")
	  	If TcSqlExec("DROP TABLE " + cFileX2) <> 0
	 		DisarmTransaction()
		   	
		   	GrLog(TCSQLError())
			Return
	  	EndIf
	EndIf
	
	DbCreate(cFileX2,aStruX2,"TOPCONN")
	
	//-- Criação SX3
	If MSFile(cFileX3, , "TOPCONN")
	  	If TcSqlExec("DROP TABLE " + cFileX3) <> 0
	 		DisarmTransaction()
		   	
		   	GrLog(TCSQLError())
			Return
	  	EndIf
	EndIf
	
	DbCreate(cFileX3,aStruX3,"TOPCONN")
	
	SX3->(DbGoTop())
	SX3->(DbSetOrder(1))	//-- X3_ARQUIVO + X3_ORDEM
	
	While ! SX3->(Eof())
		If ! Empty(SX3->X3_ARQUIVO) .And. SX3->X3_CONTEXT <> "V"
			GrLog("Carregando o campo [" + SX3->X3_CAMPO + "] ...")
			If cX3_ARQUIVO <> SX3->X3_ARQUIVO .And. SX2->(DbSeek(SX3->X3_ARQUIVO))
				cSQL += "INSERT INTO " + cFileX2 + "(X2_CHAVE, X2_ARQUIVO, R_E_C_N_O_) " +;
						"VALUES ('" + SX3->X3_ARQUIVO + "', '" + SX2->X2_ARQUIVO + "', " +;
						 AllTrim(Str(nRecX2)) + ");" 
				nRecX2 ++
			EndIf
	
			If !isBlind()
				MsProcTxt("Lendo campo [" + SX3->X3_CAMPO + "] ...")
				ProcessMessage()
			EndIf
			
			cSQL += "INSERT INTO " + cFileX3 + "(X3_ARQUIVO, X3_CAMPO, X3_TIPO, X3_TAMANHO, X3_DECIMAL, R_E_C_N_O_) " +;
					"VALUES ('" + SX3->X3_ARQUIVO + "', '" + SX3->X3_CAMPO + "', '" + SX3->X3_TIPO + "', " +;
					  AllTrim(Str(SX3->X3_TAMANHO)) + ", " + AllTrim(Str(SX3->X3_DECIMAL)) + ", " +;
					  AllTrim(Str(nRecX3)) + ");" 
		EndIf
		
		cX3_ARQUIVO := SX3->X3_ARQUIVO
		SX3->(DbSkip())
		nRegs ++
		nRecX3 ++
		
		If nRegs > 200 .Or. SX3->(Eof())
			GrLog("Enviando campos para o banco ...")
			TcSqlExec(cSQL)
	
			cError := TcSqlError()
			IF ! Empty(cError)
				GrLog("Atenção. Erro ao importar [" + cFile + "]. Erro: " + cError)
			EndIf
	
			nRegs := 0	
			cSQL := ""
		EndIf 
	EndDo
	
	// DbUseArea(.T.,"TOPCONN",cFile,"SX3TOP",.T.,.F.)
	// Append From (cFile) For X3_CONTEXT <> "V"
EndIf
cFileX2 := "%" + cFileX2 + "%"
cFileX3 := "%" + cFileX3 + "%"
// Verifica arquivos em duplicidade no dicionário
beginsql alias "QRY
	%noparser%
	
	select X2_ARQUIVO from %Exp:cFileX2% GROUP BY X2_ARQUIVO HAVING COUNT(*) > 1
endsql	
nReg := 0
While ! Eof()
	GrLog("Atenção. Arquivo [" + QRY->X2_ARQUIVO + "] duplicado no SX2 !")
	nReg ++
	DbSkip()
EndDo	
Qry->(DbCloseArea())    
If nReg > 0
	EndLog()
	Return
EndIf
cSQL := "select X3_ARQUIVO as X2_CHAVE "
cSQL +=   "from ("
cSQL +=           "select sx3.X3_ARQUIVO, sx3.X3_CAMPO, sx3.X3_TIPO, sx3.X3_TAMANHO, sx3.X3_DECIMAL, "
cSQL +=                  "coalesce(case when topfld.FIELD_TYPE = 'P' then 'N' else topfld.FIELD_TYPE end, "
cSQL +=                  "case when typ.name = 'varchar' then 'C' else '' end) as x3_tipo_db, "
cSQL +=                  "coalesce(topfld.FIELD_PREC, fld.max_length, 0) as x3_tamanho_db, "
cSQL +=                  "coalesce(topfld.FIELD_DEC, 0) as x3_decimal_db "
cSQL +=             "from " + StrTran(cFileX2, "%", "") + " sx2 "
cSQL +=             "join " + StrTran(cFileX3, "%", "") + " sx3 on sx3.X3_ARQUIVO = sx2.X2_CHAVE "
cSQL +=             "join sys.tables tab on tab.name = sx2.X2_ARQUIVO " 
cSQL +=        "left join sys.columns fld on fld.object_id = tab.object_id and fld.name = sx3.X3_CAMPO " 
cSQL +=        "left join sys.systypes typ on typ.xtype = fld.system_type_id "
cSQL +=        "left join TOP_FIELD topfld on replace(topfld.FIELD_TABLE, 'dbo.', '') = tab.name "
cSQL +=         "and fld.name = topfld.FIELD_NAME "
cSQL +=       "where sx3.X3_TIPO <> coalesce(case when topfld.FIELD_TYPE = 'P' then 'N' else topfld.FIELD_TYPE end, "
cSQL +=             "case when typ.name = 'varchar' then 'C' else '' end) or "
cSQL +=             "case when sx3.X3_TIPO = 'M' then 10 else sx3.X3_TAMANHO end <> "
cSQL +=                        "coalesce(case when topfld.FIELD_TYPE = 'M' then 10 else topfld.FIELD_PREC end, " 
cSQL +=                        "fld.max_length, 0) or "
cSQL +=                        "sx3.X3_DECIMAL <> coalesce(topfld.FIELD_DEC, 0) "
cSQL +=  "union all "	   
cSQL += "select sx2.X2_CHAVE, fld.name, ' ' as X3_TIPO, 0 as X3_TAMANHO, 0 AS X3_DECIMAL, " 
cSQL +=        "coalesce(case when topfld.FIELD_TYPE = 'P' then 'N' else topfld.FIELD_TYPE end, "
cSQL +=        "case when typ.name = 'varchar' then 'C' else '' end) as x3_tipo_db, "
cSQL +=        "coalesce(topfld.FIELD_PREC, fld.max_length, 0) as x3_tamanho_db, "
cSQL +=        "coalesce(topfld.FIELD_DEC, 0) as x3_decimal_db "
cSQL +=   "from " + StrTran(cFileX2, "%", "") + " sx2 "
cSQL +=   "join sys.tables tab on tab.name = sx2.X2_ARQUIVO " 
cSQL +=   "join sys.columns fld on fld.object_id = tab.object_id and not fld.name in ('R_E_C_N_O_','R_E_C_D_E_L_','D_E_L_E_T_') "  
cSQL +=   "left join sys.systypes typ on typ.xtype = fld.system_type_id "
cSQL +=   "left join TOP_FIELD topfld on replace(topfld.FIELD_TABLE, 'dbo.', '') = tab.name "
cSQL +=    "and fld.name = topfld.FIELD_NAME "
cSQL +=   "left join " + StrTran(cFileX3, "%", "") + " sx3 on sx3.X3_ARQUIVO = sx2.X2_CHAVE and sx3.X3_CAMPO = fld.name "
cSQL +=  "where sx3.X3_CAMPO is null) tab "
cSQL +=  "group by X3_ARQUIVO"
//-- Dropar a tabela
TcSqlExec("DROP VIEW " + cView)
If TcSqlExec("CREATE VIEW " + cView + " AS " + cSQL) <> 0
   	GrLog(TCSQLError())
	Return
EndIf
cView := "%" + cView + "%"
beginsql alias "QRY
	%noparser%
	select X2_CHAVE from %Exp:cView% ORDER BY X2_CHAVE
endsql
While ! QRY->(Eof())
	SX2->(DbSeek(QRY->X2_CHAVE))
	GrLog("Acessando tabela [" + QRY->X2_CHAVE + "] ...")
	If ! IsBlind()
		MsProcTxt("Acessando tabela [" + QRY->X2_CHAVE + "] ...")
		ProcessMessage()
				
	EndIf
	lOk := .T.
	//-- Campos não localizados
	If ! SX3->(DbSeek(QRY->X2_CHAVE))
		GrLog("Atenção. A lista de campos no SX3 não foi definida para tabela [" + QRY->X2_CHAVE + "] !")
		
		lOk := .F.
	Else
		While SX3->X3_ARQUIVO == QRY->X2_CHAVE .And. ! SX3->(Eof()) 
      		If ! Empty(SX3->X3_GRPSXG)
      			SX3->(RecLock("SX3", .F.))
      			UpdSx3Sxg()
      			SX3->(MsUnLock())
      		EndIf
      		
      		UpdSx3Aju()
      		
      		SX3->(DbSkip())
      	EndDo
	EndIf
	//-- Indices não localizados
	If ! SIX->(DbSeek(QRY->X2_CHAVE))
		GrLog("Atenção. A lista de indices no SIX não foi definida para tabela [" + QRY->X2_CHAVE + "] !")
		
		lOk := .F.
	EndIf
	If lOk
		GrLog("Atualizando a tabela [" + QRY->X2_CHAVE + "] !")
		X31UPDTABLE(QRY->X2_CHAVE)
		DbSelectArea(QRY->X2_CHAVE)
		DbCloseArea()
	EndIf
	QRY->(DbSkip())
EndDo
QRY->(DbCloseArea())
EndLog()
Return
Static FUNCTION A370VerFor(cForm)
BEGIN SEQUENCE
	
	xResult := &cForm
END SEQUENCE
Return 
Static Function ChecErro(e)
IF e:gencode > 0
	GrLog(e:Description)
Endif
Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} Load_SX
Rotina para atualização dos dicionários de dados
@author unknown programmer (unknown.programmer@unknown.programmer)
@since  05/02/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function Load_SX(cArqDbf, cAlias)
Local bSeek := { || .F. }, nReg := 0
	DbselectArea(cAlias)
	If cAlias == "SX3"
		DbSetOrder(2)	//-- X3_CAMPO
	Else
		DbSetOrder(1)
	EndIf
	If cAlias == "SIX"		//-- Indices
		bSeek := { || ! SIX->(DbSeek(NEW->(INDICE + ORDEM))) }
	ElseIf cAlias == "SX1"	//-- Perguntas
		bSeek := { || ! SX1->(DbSeek(NEW->(X1_GRUPO + X1_ORDEM))) }
	ElseIf cAlias == "SX2"	//-- Tabelas
		bSeek := { || ! SX2->(DbSeek(NEW->X2_CHAVE)) }
	ElseIf cAlias == "SX3"	//-- Campos
		bSeek := { || ! SX3->(DbSeek(NEW->X3_CAMPO)) }
	ElseIf cAlias == "SX5"	//-- Tabelas de Tabelas
		bSeek := { || ! SX5->(DbSeek(NEW->(X5_FILIAL+X5_TABELA+X5_CHAVE) )) }
	ElseIf cAlias == "SX6"	//-- Parametros
		bSeek := { || ! SX6->(DbSeek(NEW->(Left(X6_FIL + Space(Len(SX6->X6_FIL)), Len(SX6->X6_FIL)) + X6_VAR) )) }
	ElseIf cAlias == "SX7"	//-- Gatilhos
		bSeek := { || ! SX7->(DbSeek(NEW->(X7_CAMPO + X7_SEQUENC))) }
	ElseIf cAlias == "SX9"	//-- Relacionamentos
		bSeek := { || ! SX9->(CheckSX9(NEW->X9_DOM, NEW->X9_IDENT)) }
	ElseIf cAlias == "SXA"	//-- Pastas
		bSeek := { || ! SXA->(DbSeek(NEW->(XA_ALIAS + XA_ORDEM))) }
	ElseIf cAlias == "SXB"	//-- Consultas
		bSeek := { || ! SXB->(DbSeek(NEW->(XB_ALIAS + XB_TIPO + XB_SEQ + XB_COLUNA))) }
	ElseIf cAlias == "SXG"	//-- Tamanho dos campos
		bSeek := { || ! SXG->(DbSeek(NEW->(XG_GRUPO))) }
	ElseIf cAlias == "SXV"	//-- Marshup
		bSeek := { || ! SXV->(DbSeek(NEW->(XV_MASHUP+XV_ALIAS))) }
	EndIf
	dbUseArea( .T., "CTREECDX", cArqDbf, "NEW", .T., .F.)
	If Select("NEW") = 0
		GrLog("O arquivo [" + cArqDbf + "] não pode ser aberto !")
		
		Return .F.
	EndIf
	While NEW->(!EOF())
		nReg ++
		
		If !isBlind()
			MsProcTxt("Gravando [" + cAlias + "] - Registro: " + AllTrim(Str(nReg)))
			ProcessMessage()		
		EndIf
		ConOut("Gravando [" + cAlias + "] - Registro: " + AllTrim(Str(nReg)))
		
 		SaveReg(cAlias, "NEW", Eval(bSeek), .F.)
   		If cAlias == "SX2"
	   		SX2->X2_ARQUIVO := AllTrim( NEW->X2_CHAVE ) + AllTrim( SM0->M0_CODIGO ) + "0"
	   		If ! Empty(mv_par01)
	   			SX2->X2_ARQUIVO := AllTrim( NEW->X2_CHAVE ) + mv_par01 + "0"
	   		EndIf
	   	EndIf
      	If cAlias == "SX3"
      		If AScan(aTables, SX3->X3_ARQUIVO) == 0
      			If ! SX2->(DbSeek(SX3->X3_ARQUIVO))
      				GrLog("Atenção. A definição da tabela [" + SX3->X3_ARQUIVO + "] não está no pacote !")
      			Else
      				Aadd(aTables, SX3->X3_ARQUIVO)
      			EndIf
      		EndIf
      		If ! Empty(SX3->X3_GRPSXG)
      			UpdSx3Sxg()
      		EndIf
      		
      		If Empty(SX3->X3_PYME)
      			SX3->X3_PYME := "S"
      		EndIf
      		If Empty(SX3->X3_ORTOGRA)
      			SX3->X3_ORTOGRA := "N"
      		EndIf
      		If Empty(SX3->X3_IDXFLD)
      			SX3->X3_IDXFLD := "N"
      		EndIf
      	ElseIf cAlias == "SX1"
      		If ! Empty(SX1->X1_GRPSXG) .And. X1_GSC <> "R"
      			SXG->(DbSeek(SX1->X1_GRPSXG))
      			SX1->X1_TAMANHO := SXG->XG_SIZE
      		EndIf
      	EndIf
	   	(cAlias)->(MsUnLock())
      	If cAlias == "SX3"
      		UpdSx3Aju()
      	EndIf      		
		NEW->(DbSkip())
	EndDo
	NEW->(DbCloseArea())
Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} UpdSx3Sxg
Atualiza o campo X3_TAMANHO a partir do XG_SIZE
@author Wagner Mobile Costa
@since  05/02/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function UpdSx3Sxg()
If SXG->(DbSeek(SX3->X3_GRPSXG))
	SX3->X3_TAMANHO := SXG->XG_SIZE
Else
	
	GrLog("O grupo de campos [" + SX3->X3_GRPSXG + "] do campo [" + AllTrim(SX3->X3_CAMPO) + "] não existe !")
EndIf
Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} UpdSx3Aju
Atualiza o campo X3_TAMANHO dos campos Memos e Reais.
@author Alexandre Florentino
@since  21/09/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function UpdSx3Aju()
If ((SX3->X3_CONTEXT <> "V") .AND. (SX3->X3_TIPO == "M"))
	SX3->(RecLock("SX3", .F.))
    SX3->X3_TAMANHO := 10  			
	SX3->(MsUnLock())	
EndIf
Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} LoadData
Rotina para atualização dos dados da tabela
@author unknown programmer (unknown.programmer@unknown.programmer)
@since  05/02/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function LoadData(cTab, cFile)
Local nReg   := 0
Local cUnico := ""
	DbSelectArea(cTab)
  	If mv_par03 == 1
	  	If TcSqlExec("DELETE FROM " + RetSqlName(cTab)) <> 0
		   	GrLog(TCSQLError())
			Return
	  	EndIf
	  	
	  	ImpData(cTab, cFile)
	
		SX2->(DbSeek(cTab))
		If .F. // SX2->X2_MODO = "E"
			SX3->(DbSetOrder(1))
			SX3->(DbSeek(cTab))
	  		If TcSqlExec("UPDATE " + RetSqlName(cTab) + " SET " + SX3->X3_CAMPO + " = '01'") <> 0
		   		GrLog(TCSQLError())
			
				Return
	  		EndIf
	  	EndIf
		
		Return
	Else
		DbSelectArea(cTab)
	
		dbUseArea( .T., "CTREECDX", cFile, "NEW", .F., .F.)
		If Select("NEW") = 0
			GrLog("Atenção. O arquivo [" + cFile + "] não pode ser aberto !")
			(cTab)->(DbCloseArea())
			Return
		EndIf
		SX2->(DbSeek(cTab))
		cUnico := AllTrim(SX2->X2_UNICO)
		
		If Empty(cUnico)
			NEW->(DbCloseArea())
			GrLog("Atenção. A chave unica da tabela [" + cTab + "] não foi definida !")
		
			Return
		EndIf
		
		While NEW->(!EOF())
			nReg ++
			
			If !IsBlind()
				MsProcTxt("Gravando [" + cTab + "] - Registro: " + AllTrim(Str(nReg)))
				ProcessMessage()
			EndIf
			cChave := NEW->(&cUnico)
	
	 		SaveReg(cTab, "NEW", ! (cTab)->(DbSeek(cChave)))
	 		If Select("NEW") = 0
	 			Alert("Alias [NEW] não aberto ! Tabela [" + cTab + "] !")
	 			Return	
	 		EndIf
	
			NEW->(DbSkip())
		EndDo
		NEW->(DbCloseArea())
		(cTab)->(DbCloseArea())
	EndIf
	TcRefresh(RetSqlName(cTab))
Return Nil
Static Function SaveReg(cAlias, cAliasCp, lInsert, lMsUnLock)
/*/f/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
<Descricao> : Função para inserção de um registro em um alias a partir de outro
<Data> : 02/08/2013
<Parametros> : Nenhum
<Retorno> : Nenhum
<Processo> : Consultas Personalizadas
<Tipo> (Menu,Trigger,Validacao,Ponto de Entrada,Genericas,Especificas ) : E
<Obs> :
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
*/
Local nField := 0, cField := ""
RecLock(cAlias, lInsert)
For nField := 1 To (cAliasCP)->(FCount())
    cField := (cAliasCP)->(FieldName(nField))
    
    //-- Não altero o compartilhamento das tabelas existentes
    If ! lInsert .And. AllTrim(FieldName(nField)) $ "X2_MODO,X2_MODOUN,X2_MODOEMP"
    	Loop
    EndIf
    
    If (cAlias)->(FieldPos(cField)) > 0 .And. (cAliasCP)->(FieldPos(cField)) > 0 .And. ValType(&(cAliasCp + "->" + cField)) <> "M"
       &(cAlias + "->" + cField) := &(cAliasCp + "->" + cField)
    EndIf
Next
If lMsUnLock
	(cAlias)->(MsUnlock())
EndIf
Return
Static Function RumTxt(cRetornoXML)
/*/f/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
<Descricao> : Função para retirar caracteres especiais de uma string
<Data> : 02/08/2013
<Parametros> : Nenhum
<Retorno> : Nenhum
<Processo> : Consultas Personalizadas
<Tipo> (Menu,Trigger,Validacao,Ponto de Entrada,Genericas,Especificas ) : E
<Obs> :
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
*/
cRetornoXML:=StrTran(cRetornoXML,"á","a")
cRetornoXML:=StrTran(cRetornoXML,"Ý","A")
cRetornoXML:=StrTran(cRetornoXML,"à","a")
cRetornoXML:=StrTran(cRetornoXML,"À","A")
cRetornoXML:=StrTran(cRetornoXML,"ã","a")
cRetornoXML:=StrTran(cRetornoXML,"Ã","A")
cRetornoXML:=StrTran(cRetornoXML,"â","a")
cRetornoXML:=StrTran(cRetornoXML,"Â","A")
cRetornoXML:=StrTran(cRetornoXML,"ä","a")
cRetornoXML:=StrTran(cRetornoXML,"Ä","A")
cRetornoXML:=StrTran(cRetornoXML,"é","e")
cRetornoXML:=StrTran(cRetornoXML,"É","E")
cRetornoXML:=StrTran(cRetornoXML,"ë","e")
cRetornoXML:=StrTran(cRetornoXML,"Ë","E")
cRetornoXML:=StrTran(cRetornoXML,"ê","e")
cRetornoXML:=StrTran(cRetornoXML,"Ê","E")
cRetornoXML:=StrTran(cRetornoXML,"í","i")
cRetornoXML:=StrTran(cRetornoXML,"Ý","I")
cRetornoXML:=StrTran(cRetornoXML,"ï","i")
cRetornoXML:=StrTran(cRetornoXML,"Ý","I")
cRetornoXML:=StrTran(cRetornoXML,"î","i")
cRetornoXML:=StrTran(cRetornoXML,"Î","I")
cRetornoXML:=StrTran(cRetornoXML,"ý","y")
cRetornoXML:=StrTran(cRetornoXML,"Ý","y")
cRetornoXML:=StrTran(cRetornoXML,"ÿ","y")
cRetornoXML:=StrTran(cRetornoXML,"ó","o")
cRetornoXML:=StrTran(cRetornoXML,"Ó","O")
cRetornoXML:=StrTran(cRetornoXML,"õ","o")
cRetornoXML:=StrTran(cRetornoXML,"Õ","O")
cRetornoXML:=StrTran(cRetornoXML,"ö","o")
cRetornoXML:=StrTran(cRetornoXML,"Ö","O")
cRetornoXML:=StrTran(cRetornoXML,"ô","o")
cRetornoXML:=StrTran(cRetornoXML,"Ô","O")
cRetornoXML:=StrTran(cRetornoXML,"ò","o")
cRetornoXML:=StrTran(cRetornoXML,"Ò","O")
cRetornoXML:=StrTran(cRetornoXML,"ú","u")
cRetornoXML:=StrTran(cRetornoXML,"Ú","U")
cRetornoXML:=StrTran(cRetornoXML,"ù","u")
cRetornoXML:=StrTran(cRetornoXML,"Ù","U")
cRetornoXML:=StrTran(cRetornoXML,"ü","u")
cRetornoXML:=StrTran(cRetornoXML,"Ü","U")
cRetornoXML:=StrTran(cRetornoXML,"ç","c")
cRetornoXML:=StrTran(cRetornoXML,"Ç","C")
cRetornoXML:=StrTran(cRetornoXML,"º","o")
cRetornoXML:=StrTran(cRetornoXML,"°","o")
cRetornoXML:=StrTran(cRetornoXML,"ª","a")
cRetornoXML:=StrTran(cRetornoXML,"ñ","n")
cRetornoXML:=StrTran(cRetornoXML,"Ñ","N")
cRetornoXML:=StrTran(cRetornoXML,"²","2")
cRetornoXML:=StrTran(cRetornoXML,"³","3")
cRetornoXML:=StrTran(cRetornoXML,"","'")
cRetornoXML:=StrTran(cRetornoXML,"§","S")
cRetornoXML:=StrTran(cRetornoXML,"±","+")
cRetornoXML:=StrTran(cRetornoXML,"­","-")
cRetornoXML:=StrTran(cRetornoXML,"´","'")
cRetornoXML:=StrTran(cRetornoXML,"o","o")
cRetornoXML:=StrTran(cRetornoXML,"µ","u")
cRetornoXML:=StrTran(cRetornoXML,"¼","1/4")
cRetornoXML:=StrTran(cRetornoXML,"½","1/2")
cRetornoXML:=StrTran(cRetornoXML,"¾","3/4")
cRetornoXML:=StrTran(cRetornoXML,"&","e") 
Return cRetornoXML
//--------------------------------------------------------------------------
/*/{Protheus.doc} UpdStru
Rotina para atualização da estrutura das tabelas
@author unknown programmer (unknown.programmer@unknown.programmer)
@since  04/02/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function UpdStru
Local nTables := 0, aStru  := {}, aSX3 := {}, aSQL := {}
Local lUpd := .F., cInsert := cInstru := cTable := "", xValue := Nil
SX3->(DbSetOrder(1))
For nTables := 1 To Len(aTables)
   	cTable := aTables[nTables]
	DbSelectArea(cTable)
   	lUpd := .F.
	If Select(aTables[nTables]) > 0
		DbSelectArea(aTables[nTables])
		DbCloseArea()
	EndIf
	SX2->(DbSeek(aTables[nTables]))
	If MSFile(AllTrim(SX2->X2_ARQUIVO), , "TOPCONN")
	    dbUseArea( .T., "TOPCONN", AllTrim(SX2->X2_ARQUIVO), aTables[nTables], .F., .F.)
      	    aStru := DbStruct()
      	    lUpd := .T.
   	EndIf
   	aSX3 := LoadSX3(aTables[nTables])
   	lUpd := CompStru(aStru, aSx3)
   	If ! lUpd
    	    lUpd := CompStru(aSx3, aStru)
  	EndIf
   	aSQL := {}
	If ! lUpdStru
		If lUpd
			GrLog("Tabela: " + AllTrim(SX2->X2_ARQUIVO) + " com diferença entre SX3/Banco")
		EndIf
	ElseIf lUpd
		If Select(aTables[nTables]) > 0
			(aTables[nTables])->(DbCloseArea())
		EndIf
		/*
		dbUseArea( .T., "TOPCONN", AllTrim(SX2->X2_ARQUIVO), aTables[nTables], .F., .F.)
		If Select(aTables[nTables]) == 0
			GrLog("Não é possível abrir o arquivo [" + AllTrim(SX2->X2_ARQUIVO) + "] em modo exclusivo para alteração da estrutura !")
		   	Loop
		EndIf
		*/
		X31UPDTABLE(cTable)
		If __GetX31Error()
			GrLog("Tabela: " + cTable + " Erro: " + __GetX31Trace())
		Else
			GrLog("Tabela: " + cTable + " atualizada estrutura com sucesso !")
		EndIf
   EndIf
Next
Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} LoadSX3
Rotina para leitura do SX3 de uma tabela
@author unknown programmer (unknown.programmer@unknown.programmer)
@since  16/02/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
User Function LoadSX3(cAlias)
Return LoadSX3(cAlias)
Static Function LoadSX3(cAlias)
Local aSX3 := {}
DbSelectArea("SX3")
DbSeek(cAlias)
While X3_ARQUIVO == cAlias .And. ! Eof()
	If SX3->X3_CONTEXT <> "V"
   		Aadd(aSX3, { AllTrim(SX3->X3_CAMPO), SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL })
    EndIf
	DbSkip()
EndDo
Return aSX3
//--------------------------------------------------------------------------
/*/{Protheus.doc} ImpData
Rotina para importação de arquivo .DBF para tabela
@author unknown programmer (unknown.programmer@unknown.programmer)
@since  16/02/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function ImpData(cSX3, cFile)
Local cRDD := RDDSetDefault()
If ! File(cFile)
	Return .T.
EndIf
RDDSetDefault("CTREECDX")
Append From (cFile)
RDDSetDefault(cRdd)
Return .T.
//--------------------------------------------------------------------------
/*/{Protheus.doc} CompStru
Rotina para comparação da estrutura x dicionário SX3 para definir atualização
@author unknown programmer (unknown.programmer@unknown.programmer)
@since  04/02/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function CompStru(aCpos1, aCpos2)
Local nPos 		:= 0
Local nCampos 	:= 0
Local lUpd 		:= .F.
Local cNomArq   := ""
//-- Leitura dos campos
For nCampos := 1 To Len(aCpos1)
   //-- Campo da Estrutura não localizado no SX3
      
   If (nPos := Ascan(aCpos2, { |x| x[1] == AllTrim(aCpos1[nCampos][1]) })) == 0
      lUpd := .T.
   EndIf
   //-- Campo Localizado
   If nPos > 0
      //-- Tipo Diferente
      If aCpos1[nCampos][2] <> aCpos2[nPos][2]
         lUpd := .T.
      EndIf
      //-- Tamanho Diferente
      If aCpos1[nCampos][3] <> aCpos2[nPos][3]
         lUpd := .T.
      EndIf
      //-- Decimais Diferentes
      If aCpos1[nCampos][4] <> aCpos2[nPos][4]
         lUpd := .T.
      EndIf
   EndIf
Next
If Len(aCpos1) == 0 .Or. Len(aCpos2) == 0
	lUpd := .F.
EndIf
Return lUpd
//--------------------------------------------------------------------------
/*/{Protheus.doc} CheckSX9
Verifica a existencia do registro na tabela SX9
@author unknown programmer (unknown.programmer@unknown.programmer)
@since  04/02/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function CheckSX9(cX9_DOM, cX9_IDENT)
Local lFound := .F., nRecSX9 := 0
DbSelectArea("SX9")
Set Filter to X9_DOM == cX9_DOM .And. X9_IDENT == cX9_IDENT
DbGoTop()
If ! Eof()
	lFound := .T.
EndIf
nRecSX9 := Recno()
Set Filter To
DbSelectArea("SX9")
DbGoto(nRecSX9)
Return lFound
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
Local aParam := {}
If Select("SM0") > 0
	Return
EndIf
	Set Dele On
	RpcSetType( 3 )
	RpcSetEnv( "99" )
	
	If LastRec() > 1
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
	
Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} InitLog
Inicialização do log de procedimentos de manutenção de base de dados
@author Wagner Mobile Costa
@since  13/09/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function InitLog()
	AutoGrLog("COMPATIBILIZADOR DA BASE DE DADOS")
	AutoGrLog("---------------------------------")
	AutoGrLog("DATA INICIO - "+Dtoc(MsDate()))
	AutoGrLog("HORA - "+Time())
	AutoGrLog("ENVIRONMENT - "+GetEnvServer())
	AutoGrLog("PATCH - "+GetSrvProfString("Startpath",""))
	AutoGrLog("ROOT - "+GetSrvProfString("SourcePath",""))
	AutoGrLog("VERSÃO - "+GetVersao())
	AutoGrLog("MÓDULO - "+"SIGA"+cModulo)
	AutoGrLog("EMPRESA / FILIAL - "+SM0->M0_CODIGO+"/"+SM0->M0_CODFIL)
	AutoGrLog("NOME EMPRESA - "+Capital(Trim(SM0->M0_NOME)))
	AutoGrLog("NOME FILIAL - "+Capital(Trim(SM0->M0_FILIAL)))
	AutoGrLog("USUÝRIO - "+SubStr(cUsuario,7,15))
	AutoGrLog("")
Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} InitLog
Apresentação do log de inconsistencias na manutenção de base de dados
@author Wagner Mobile Costa
@since  13/09/2015
@param  Nil
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function EndLog()
AutoGrLog("DATA FINAL - "+Dtoc(MsDate()))
AutoGrLog("HORA - "+Time())
If !IsBlind()
   MostraErro("", "INSTSXDB")
EndIf
Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} InitLog
Geração do texto de log com hora de execução
@author Wagner Mobile Costa
@since  13/09/2015
@param  cLog = Texto para chamada da função AutoGrLog
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function GrLog(cLog)
AutoGrLog(Time() + "-" + cLog)
ConOut(Time() + "-" + cLog)
Return
//--------------------------------------------------------------------------
/*/{Protheus.doc} GetParams
Solicita os parametros para execução da rotina
@author Wagner Mobile Costa
@since  29/09/2015
@return Nil
/*/
//-------------------------------------------------------------------------
Static Function GetParams
Local _aParam 	:= {}
Local cEmpresa	:= Space(2)
Local cX2_CHAVE 	:= Space(3)
Local nDelDAT		:= 1
	Aadd(_aParam, {1, "Empresa [X2_ARQUIVO] ?", cEmpresa, "@!"	, ""	, ""	, "", 002, .F.})
	aAdd(_aParam ,{1, "Tabela Inicial",cX2_CHAVE,"@",'.T.','','',3,.F.})
	aAdd(_aParam ,{3, "Deleta conteúdo .DAT",nDelDat,{ "Sim", "Não" },70,,.F.})
	
	IF ! ParamBox(_aParam, "Parametros da rotina",, {|| AllwaysTrue()},,,,,,, .F.)
		Return .F.
	Endif
    SX2->(DbGoTop())
    If ! Empty(mv_par02)
    	SX2->(DbSeek(mv_par02))
    EndIf
Return .T.
