B4A=true
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
End Sub

Sub Service_Create
	objConfig.Initialize
	btPrinter.Initialize(Me, "btPrinter")
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
				btPrinter.Connect2(param_1)
			End If			
			CallSubDelayed2(mySender, "getBtConnectedResponse", btPrinter.IsBluetoothOn)
		Case "btdisconnect"
			If btPrinter.IsInitialized Then
				btPrinter.DisConnect
			End If
			CallSubDelayed2(mySender, "getBtDisconnectedResponse", btPrinter.IsBluetoothOn)
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

'Private Sub jstrToMap(jstr As String) As Map
'	If jstr = "" Then
'		Return CreateMap()
'	End If
'	Dim jParser As JSONParser
'	Try
'		jParser.Initialize(jstr)
'		Dim m As Map = jParser.NextObject
'		Return m
'	Catch
'		Log(LastException)
'		Return CreateMap()
'	End Try
'End Sub