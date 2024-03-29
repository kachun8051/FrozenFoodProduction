﻿B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=11.8
@EndOfDesignText@
#Region  Service Attributes 
	#StartAtBoot: False
	
#End Region

Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.
	' Which activity or page consume this service
	Private mySender As Object
	Private objConfig As clsConfig
	' BlueTooth Label Printer object
	' After posting the finished product successfully, 
	' bluetooth printer would receive print label command in this service 
	Private btPrinter As clsTSPLPrinter
	Private MacAddr As String
	Private Job As HttpJob
	Private lstOfProduction As List
	Private strErrMsg As String
End Sub

Sub Service_Create
	objConfig.Initialize
	btPrinter.Initialize(Me, "btPrinter")
	lstOfProduction.Initialize
	strErrMsg = ""
End Sub

Sub Service_Start (StartingIntent As Intent)
	Service.StopAutomaticForeground 'Call this when the background task completes (if there is one)
	If StartingIntent.HasExtra("senderid") = False Then
		StopService("")
		Return
	End If
	If StartingIntent.HasExtra("task") = False Then
		StopService("")
		Return
	End If
	Dim SenderId_1 As String = StartingIntent.GetExtra("senderid")
	mySender = B4XPages.GetPage(SenderId_1)
	Dim task_1 As String = StartingIntent.GetExtra("task")
	
	Dim param_1 As String 
			
	If StartingIntent.HasExtra("param") Then
		param_1 = StartingIntent.GetExtra("param")
		LogColor("svcBack4AppFinishedProduct: " & CRLF & param_1, Colors.Blue)
	Else
		param_1 = ""		
	End If
		
	Select task_1
		Case "btconnect"
			' param_1 for btconnect task is mac address
			If param_1 = "" Then
				Return
			End If
			MacAddr = param_1
			If btPrinter.IsInitialized Then
				' would trigger the event handler btPrinter_Connected
				btPrinter.Connect2(param_1)
			End If				
			'CallSubDelayed2(mySender, "btPrinter_Connected", btPrinter.IsBluetoothOn)
		Case "btdisconnect"
			If btPrinter.IsInitialized Then
				btPrinter.DisConnect
			End If
			CallSubDelayed2(mySender, "btPrinter_Disconnected", btPrinter.IsBluetoothOn)
		Case "query"
			' myParam here is date in format yyyyMMdd
			Dim url As String = getUrlFromOneDate(param_1)
			sendBack4AppReq(url)
		Case "delete"
			' myParam here is the objectId
			Dim url_2 As String = "https://parseapi.back4app.com/classes/Production/" & param_1
			sendBack4AppDelete(url_2)	
		Case "printonly"
			' param_1 for postandprint is json string of object clsFinishedProduct
			If param_1 = "" Then
				Return
			End If
			If btPrinter.IsBluetoothOn = False Then
				CallSubDelayed2(mySender, "getFinishedProductPrintedResponse", _
					CreateMap("issuccess": False, "errmsg": "btprinter is NOT connected!"))
				Return
			End If
			Dim objFP As clsFinishedProduct : objFP.Initialize
			objFP.myDeserialize(param_1)			
			Dim isPrinted As Boolean = PrintLabel(objFP.ObjectId, objFP.Product, objFP.WeightInGram)
			If isPrinted = False Then
				CallSubDelayed2(mySender, "getFinishedProductPrintedResponse", _ 
					CreateMap("issuccess": False, "errmsg": "Printer Error!" & CRLF & LastException.Message))
				Return
			End If
			CallSubDelayed2(mySender, "getFinishedProductPrintedResponse", CreateMap("issuccess": True))
		Case "printtest"
			strErrMsg = ""
			If btPrinter.IsBluetoothOn = False Then
				CallSubDelayed2(mySender, "getPrintTestResponse", _
					CreateMap("issuccess": False, "errmsg": "btprinter is NOT connected!"))
				Return
			End If
			Dim isTestPrinted As Boolean = PrintTestLabel
			If isTestPrinted Then
				CallSubDelayed2(mySender, "getPrintTestResponse", _
					CreateMap("issuccess": True))
			Else
				CallSubDelayed2(mySender, "getPrintTestResponse", _
					CreateMap("issuccess": False, "errmsg": strErrMsg))
			End If
		Case "postandprint"
			' param_1 for postandprint is json string of object clsFinishedProduct
			If param_1 = "" Then
				Return
			End If
			If btPrinter.IsBluetoothOn = False Then
				CallSubDelayed2(mySender, "getFinishedProductPostedResponse", _
					CreateMap("issuccess": False, "errmsg": "btprinter is NOT connected!"))
				Return
			End If
			Dim objFP As clsFinishedProduct : objFP.Initialize
			objFP.myDeserialize(param_1)
			Wait For (sendBack4AppPost(objFP.JsonStringForPost)) Complete(mapRes As Map)
			If mapRes.Get("issuccess").As(Boolean) = False Then
				CallSubDelayed2(mySender, "getFinishedProductPostedResponse", _ 
					CreateMap("issuccess": False, "errmsg": "posting error!"))
				Return			
			End If
			Dim objid As String = mapRes.Get("objectid")
			Log("Object Id from response: " & objid)
		 	Dim isPrinted As Boolean = PrintLabel(objid, objFP.Product, objFP.WeightInGram) 
			If isPrinted = False Then
				CallSubDelayed2(mySender, "getFinishedProductPostedResponse", _
					CreateMap("issuccess": False, "errmsg": "printing error!"))
				Return
			End If
			CallSubDelayed2(mySender, "getFinishedProductPostedResponse", _ 
				CreateMap("issuccess": True, "objectid": objid, "itemnum": objFP.Itemnum, "itemname": objFP.Product.Itemname))
		
	End Select
	
End Sub

Sub Service_Destroy
	If btPrinter.IsInitialized Then
		' Release the resource
		btPrinter.DisConnect
	End If
End Sub

#Region btPrinter_Events

Private Sub btPrinter_Connected(issuccess As Boolean)
	CallSubDelayed2(mySender, "btPrinter_Connected", issuccess)
End Sub



#End Region

Sub sendBack4AppPost(postingdata As String) As ResumableSub
	Dim isSuccess As Boolean = False
	Dim objid As String = ""
	Dim Job As HttpJob
	Job.initialize("post", Me)
	Job.PostString("https://parseapi.back4app.com/classes/Production", postingdata)
	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
	Job.GetRequest.SetHeader("X-Parse-REST-API-Key", objConfig.ApiKey)
	Job.GetRequest.SetContentType("application/json")
	
	Wait For JobDone(j As HttpJob)
	
	If j.Success Then
		Log(j.GetString)
		Try
			Dim jparser As JSONParser
			jparser.Initialize(j.GetString)
			Dim map2 As Map = jparser.NextObject
			objid = map2.Get("objectId")
			' Msgbox2Async($"objectId: ${map2.Get("objectId")}${CRLF}createdAt: ${map2.Get("createdAt")}"$, "Response","Done","","",Null, True)
			ToastMessageShow($"objectId: ${map2.Get("objectId")}${CRLF}createdAt: ${map2.Get("createdAt")}"$, False)
			isSuccess = True
		Catch
			Log(LastException)
			isSuccess = False
		End Try
	End If
	j.Release
	Return CreateMap("issuccess": isSuccess, "objectid": objid)
End Sub

Sub PrintTestLabel() As Boolean
	Try
		btPrinter.Size(50, 38)
		btPrinter.GAP(1.5,0)
		btPrinter.DENSITY2(7)
		btPrinter.DIRECTION(0)
		btPrinter.REFERENCE(0,0)
		'Printer2.HOME
		'Printer2.BACKUP(320)
		btPrinter.CLS
		' Dim a As String = DateTime.Date(DateTime.Now) & " " &  DateTime.Time(DateTime.Now) 'ignore
		btPrinter.TEXT(20, 15, "TSS24.BF2", 0, 1, 2, getDateTime)
		btPrinter.TEXT(20, 70, "TSS24.BF2", 0, 5, 10, "TEST")
		btPrinter.PRINT(1,0)
		btPrinter.EOP
		Return True
	Catch
		LogColor("svcBack4AppFinishedProduct.PrintTestLabel: " & CRLF & LastException.Message, Colors.Red)
		strErrMsg = LastException.Message
		Return False
	End Try
End Sub

Private Sub getDateTime() As String
	Dim df As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyy/MM/dd HH:mm:ss"
	Dim dtNow As Long = DateTime.Now
	Dim dt As String = ""
	Try
		dt = DateTime.Date(dtNow)
	Catch
		Log(LastException)		
	End Try
	DateTime.DateFormat = df
	Return dt
End Sub

Sub PrintLabel(objid As String, obj As clsProduct, weight As Double) As Boolean
	
	If obj.IsInitialized = False Then
		Return False
	End If
	Try
		btPrinter.Size(50, 38)
		btPrinter.GAP(1.5,0)
		btPrinter.DENSITY2(7)
		btPrinter.DIRECTION(0)
		btPrinter.REFERENCE(0,0)
		'Printer2.HOME
		'Printer2.BACKUP(320)
		btPrinter.CLS
		Dim a As String = "Test" & DateTime.Date(DateTime.Now) & " " &  DateTime.Time(DateTime.Now) 'ignore
		btPrinter.TEXT(20, 10, "TSS24.BF2", 0, 1, 2, obj.itemname2)
		btPrinter.TEXT(20, 60, "TSS24.BF2", 0, 1, 1, obj.Itemname)
		btPrinter.TEXT(20, 100, "TSS24.BF2", 0, 1, 1, "Per 100g:")
		btPrinter.TEXT(150, 100, "TSS24.BF2", 0, 1, 1, "HK$" & NumberFormat(obj.ItemPrice, 0, 1))
		btPrinter.TEXT(20, 140, "TSS24.BF2", 0, 1, 1, "Weight:")
		btPrinter.TEXT(150, 140, "TSS24.BF2", 0, 1, 1, NumberFormat(weight, 0, 1) & " gram")
		btPrinter.TEXT(20, 170, "TSS24.BF2", 0, 1, 1, "Price:")
		btPrinter.TEXT(150, 170, "TSS24.BF2", 0, 1, 1, "HK$" & NumberFormat(obj.calcPriceByWeight(weight), 0, 1))
		btPrinter.BARCODE(20, 210, "128",70,False,0,2,4, obj.getProductBarcode(weight))
		btPrinter.QRCODE(310, 210, "L", 3, "A", 0, objid)
		'only print bmp
		' btPrinter.PUTBMP(100,140,File.DirAssets,"umbellar2.bmp")
		' btPrinter.BITMAP(200,140,0,LoadBitmap(File.DirAssets,"umbellar.jpg"))
		btPrinter.PRINT(1,0)
		btPrinter.EOP
		Return True
	Catch
		Log(LastException)
		Return False
	End Try
	
End Sub

Private Sub sendBack4AppReq(url As String)
	Job.initialize("query", Me)
	Job.Download(url)
	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
	Job.GetRequest.SetHeader("X-Parse-REST-API-Key", objConfig.apikey)
	Job.GetRequest.SetHeader("X-Parse-Master-Key", objConfig.masterkey)
End Sub

Private Sub sendBack4AppDelete(url As String)
	Job.Initialize("delete", Me)
	Job.Delete(url)
	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
	Job.GetRequest.SetHeader("X-Parse-REST-API-Key", objConfig.apikey)
End Sub

Private Sub JobDone(j As HttpJob)
	If j.JobName = "delete" Then
		jobdoneForDelete(j)
	End If
	If j.JobName = "query" Then
		jobdoneForQuery(j)
	End If
	j.Release
End Sub

Private Sub jobdoneForDelete(j As HttpJob)
	If j.Success Then
		Dim jResponse As String = j.GetString
		Log(jResponse)
		Try
			CallSubDelayed2(mySender, "getDeletedResponse", True)
		Catch
			Log(LastException)
			CallSubDelayed2(mySender, "getDeletedResponse", False)
		End Try
	Else
		CallSubDelayed2(mySender, "getDeletedResponse", False)
	End If
End Sub

Private Sub jobdoneForQuery(j As HttpJob)
	If j.Success Then
		Dim jResponse As String = j.GetString
		Log(jResponse)
		Try
			Dim jparser As JSONParser
			jparser.Initialize(jResponse)
			Dim map1 As Map = jparser.Nextobject
			lstOfProduction = map1.Get("results")
			CallSubDelayed2(mySender, "getQueryResponse", CreateMap("issuccess": True, "datalist": lstOfProduction))
		Catch
			Log(LastException)
			CallSubDelayed2(mySender, "getQueryResponse", CreateMap("issuccess": False, "errmsg": LastException.Message))
		End Try
	Else
		CallSubDelayed2(mySender, "getQueryResponse", CreateMap("issuccess": False, "errmsg": "Network access error"))
	End If
End Sub

' datecode must be in format yyyyMMdd
Private Sub getUrlFromOneDate(datecode As String) As String	
	If IsNumber(datecode) = False Or datecode.Length <> 8 Then
		Return ""
	End If
	' Reference: https://docs.parseplatform.org/rest/guide/
	' negative means desc
	Dim url As String = "https://parseapi.back4app.com/classes/Production?" & _
		"where=" & getDateParam(datecode) & "&order=-packedAt"
	LogColor("getUrlFromOneDate: " & url, Colors.Blue)
	Return url
End Sub

Private Sub getDateParam(datecode As String) As String
	' yyyy-MM-ddT00:00:00+08:00
	Dim dt1 As String = getThisDay(datecode)
	Dim dt2 As String = getAddOneDay(datecode)
	Dim map As Map : map.Initialize	
	map.Put("$gte", CreateMap("__type": "Date", "iso": dt1))
	map.Put("$lt", CreateMap("__type": "Date", "iso": dt2))
	Dim jGen As JSONGenerator
	Try
		jGen.Initialize(CreateMap("packedAt": map))
		Return jGen.ToString
	Catch
		Log(LastException)
		Return "{}"
	End Try
End Sub

Private Sub getThisDay(datecode As String) As String
	If IsNumber(datecode) = False Or datecode.Length <> 8 Then
		Return ""
	End If
	Dim df As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyyMMdd"
	Dim dt As Long = DateTime.DateParse(datecode)
	dt = dt - DateTime.TicksPerHour * modCommon.getTimeZone
	DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
	Dim dt2 As String = DateTime.Date(dt).As(String).Replace(" ", "T") & "Z"
	Log(dt2)
	' Restore the original date format
	DateTime.DateFormat = df	
	Return dt2
End Sub

' datecode must be in format yyyyMMdd
Private Sub getAddOneDay(datecode As String) As String
	If IsNumber(datecode) = False Or datecode.Length <> 8 Then
		Return ""
	End If
	Dim OneDayAdded As String = ""
	' original date format
	Dim df As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyyMMdd"
	Try
		Dim dt1 As Long = DateTime.DateParse(datecode)
		Dim dt2 As Long = DateTime.Add(dt1, 0, 0, 1)
		dt2 = dt2 - DateTime.TicksPerHour * modCommon.getTimeZone
		DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
		OneDayAdded = DateTime.Date(dt2).Replace(" ", "T") & "Z"
		Log(OneDayAdded)
	Catch
		Log(LastException)
		OneDayAdded = ""
	End Try
	' Restore the original date format
	DateTime.DateFormat = df
	Return OneDayAdded	
End Sub