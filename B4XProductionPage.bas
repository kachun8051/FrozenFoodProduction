B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.2
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView 'ignore
	Private xui As XUI 'ignore
	
	#Region Drawer_Menu_Variables
	Private drManager As DrawerManager
	Private clvDrawer As CustomListView
	Private clvIcon As Label
	Private clvMenuLabel As Label
	Private objConfig As clsConfig
	#End Region	
	Private lstProduct As List
	Private lblData As Label
	Private lblReading As Label
	Private currValue As Double
'	Private currValRec As Double
	
	Private ScrollView1 As ScrollView
	Private dybtn As cvDynamicButton
	' BlueTooth Label Printer object
'	Private btPrinter As clsTSPLPrinter
	' BlueTooth Weighting Scale object
	' Private btScale As clsSerialScale
	' Serial for weighting scale
	Private BTA As BluetoothAdmin
	Private mySerial As Serial
	Private lstOfFoundDevices As List
	Type BlueTooth_NameAndMac (Name As String, Mac As String)
End Sub

'You can add more parameters here.
Public Sub Initialize As Object
	objConfig.Initialize
	lstProduct.Initialize
	' btPrinter.Initialize(Me, "btPrinter")
	' btScale.Initialize(Me, "btScale")
	mySerial.Initialize("mySerial")
	currValue = -1	
	Return Me
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1

	BTA.Initialize("BTA")
	lstOfFoundDevices.Initialize
	
	'load the layout to Root
	drManager.Initialize(Me, "Drawer", Root, 200dip)
	drManager.myDrawer.CenterPanel.LoadLayout("ProductionPage.bal")
	drManager.myDrawer.LeftPanel.LoadLayout("sidemenu")
	' Event handler is B4XPage_MenuClick
	B4XPages.GetManager.LogEvents = True	
	B4XPages.AddMenuItem(Me, "Connect Bluetooth")
	B4XPages.AddMenuItem(Me, "Disconnect Bluetooth")
	B4XPages.AddMenuItem(Me, "refresh")
	createMenu
	B4XPages.SetTitle(Me, "Production")
	dybtn.Initialize(Me, "dybtn_click")
	' Please note that dimension of ScrollView is different from
	' dimension of panel of ScrollView
	Dim svHeight As Double = 100%y-70dip 'ScrollView1.Height
	Dim svWidth As Double = 100%x-20dip 'ScrollView1.Width
	LogColor("ScrollView's height: " & svHeight, Colors.Blue)
	LogColor("ScrollView's width: " & svWidth, Colors.Blue)
	dybtn.setPanelHeightWidth(svHeight, svWidth)
	' ScrollView1.Panel.Width = svWidth
	If lstProduct.Size = 0 Then
		' sendBack4AppRequest
		sendProductIntent("query")		
	End If
End Sub

'You can see the list of page related events in the B4XPagesManager object. The event name is B4XPage.
#Region B4XPageEvents
Private Sub B4XPage_Appear
	drManager.B4XPageAppear
	If BTA.IsEnabled = False Then
		If BTA.Enable = False Then
			ToastMessageShow("Bluetooth is off", True)
		Else
			ToastMessageShow("Turn on Bluetooth ...", True)
		End If
	Else
		BTA_StateChanged(BTA.STATE_ON, 0)
	End If
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	Return drManager.B4XPageCloseRequest
End Sub

Private Sub B4XPage_Disappear
	drManager.B4XPageDisappear
	dybtn.resetNumOfRow
'	If IsPaused( svcSerialScale) = False Then
'		StopService(svcSerialScale)
'	End If
'	mySerial.Disconnect
End Sub

' For DrawerMenu
Private Sub B4XPage_Resize (Width As Int, Height As Int)
	drManager.myDrawer.Resize(Width, Height)
End Sub
#End Region


Private Sub B4XPage_MenuClick(Tag As String)
	Log("B4XPage_MenuClick: " & Tag)
	Select Tag
		Case "Connect Bluetooth"
			ConnectBluetoothDevices
		Case "Disconnect Bluetooth"
			DisconnectBluetoothDevices
		Case "refresh"
			' reset the num of row to get new data
			dybtn.resetNumOfRow			
			sendProductIntent("query")
	End Select
End Sub

' Check Draw Menu
Private Sub clvDrawer_ItemClick(Index As Int, Val As Object)
	drManager.mainMenu(Index)
End Sub

Private Sub Button1_Click
	xui.MsgboxAsync("Hello world!", "B4X")
	' B4XPages.ShowPageAndRemovePreviousPages("Production")
End Sub

Private Sub createMenu
	clvDrawer.clear
	For i = 0 To drManager.menuItems.Size-1
		Dim p As B4XView = xui.CreatePanel("")
		Dim height As Int = 50dip
		Dim width As Int = 160dip
		p.SetLayoutAnimated(0, 0, 0, width, height)
		p.LoadLayout("drawerMenuItems")
		clvIcon.Text = drManager.menuIcons.Get(i)
		clvMenuLabel.Text = drManager.menuItems.Get(i)
		clvDrawer.Add(p, i)
	Next
End Sub

Sub sendScaleIntent(mac As String)
	If IsPaused(svcSerialScale) = False Then
		StopService(svcSerialScale)
	End If
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcserialscale")
	' pidProduction is page id of B4XProductionPage
	inte.PutExtra("senderid", "pidProduction")
	inte.PutExtra("mac", mac)
	StartService(inte)
End Sub

Sub sendFinishedProductIntent(task As String, macaddr As String, fp As clsFinishedProduct)
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcback4appfinishedproduct")
	' pidProduction is page id of B4XProductionPage
	inte.PutExtra("senderid", "pidProduction")
	inte.PutExtra("task", task)
	Select task
		Case "btconnect"
			inte.PutExtra("param", macaddr)
		Case "postandprint"
			inte.PutExtra("param", fp.mySerialize)
	End Select
	StartService(inte)
End Sub

Sub sendProductIntent(task As String)
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcback4appproduct")
	' pidProduction is page id of B4XProductionPage
	inte.PutExtra("senderid", "pidProduction")
	inte.PutExtra("task", task)
	StartService(inte)
End Sub

Sub getProductResponse(mapRes As Map)
	StopService(svcBack4AppProduct)
	Dim isSuccess As Boolean = mapRes.Get("issuccess")
	If isSuccess = False Then
		Msgbox2Async("Product Menu retrieval error!", "Menu Retrieval", "OK", "", "", Null, True)
		Return
	End If
	Dim lstOfProduct As List = mapRes.Get("datalist")
	Dim isFilled As Boolean = fillTheList(lstOfProduct)
	If isFilled Then
		ScrollView1.Panel.RemoveAllViews
		' Cast from double to int
		ScrollView1.Panel.Height = dybtn.InnerPanelHeight
		ScrollView1.Panel.Width = 100%x-20dip
		' CreateButton would trigger the event - AddButtonHandler
		' to add button(s) to existing scrollview
		dybtn.CreateButtons
	End If
End Sub

Sub getFinishedProductPostedResponse(mapRes As Map)
	' StopService(svcBack4AppFinishedProduct)
	ProgressDialogHide
	Dim isSuccess As Boolean = mapRes.Get("issuccess")
	If isSuccess = False Then
		Dim errmsg As String = "Finished Product post error!" & CRLF & mapRes.Get("errmsg").As(String)
		' Msgbox2Async("Error: " & CRLF & mapRes.Get("errmsg").As(String), "Operation Error", "OK", "", "", Null, True)
		Msgbox2Async(errmsg, "Posting Finished Product", "OK", "", "", Null, True)
		Return
	End If
	Dim objId As String = mapRes.Get("objectid")
	Dim itemnum_1 As String = mapRes.Get("itemnum")
	Dim itemname_1 As String = mapRes.Get("itemname")
	Log("Finished Product Posted: " & objId)
	Dim msg As String = $"Item: ${itemname_1} (${itemnum_1}) is posted and printed"$
	ToastMessageShow(msg, True)
End Sub

Sub getBtConnectedResponse(isbtOn As Boolean)
	Log("Connected: " & isbtOn)	
End Sub

Sub getBtDisconnectedResponse(isbtOn As Boolean)
	Log("Disconnected: " & isbtOn)
End Sub

'Sub sendBack4AppPost(fp As clsFinishedProduct) As ResumableSub
'	Dim isSuccess As Boolean = False
'	Dim objid As String = ""
'	Dim Job As HttpJob
'	Job.initialize("post", Me)
'	Job.PostString("https://parseapi.back4app.com/classes/Production", fp.JsonStringForPost)
'	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
'	Job.GetRequest.SetHeader("X-Parse-REST-API-Key", objConfig.ApiKey)
'	Job.GetRequest.SetContentType("application/json")
'	ProgressDialogShow2("Posting...", True)
'	Wait For JobDone(j As HttpJob)
'	ProgressDialogHide
'	If j.Success Then
'		Log(j.GetString)
'		Try
'			Dim jparser As JSONParser
'			jparser.Initialize(j.GetString)
'			Dim map2 As Map = jparser.NextObject
'			objid = map2.Get("objectId")
'			Msgbox2Async($"objectId: ${map2.Get("objectId")}${CRLF}createdAt: ${map2.Get("createdAt")}"$, "Response","Done","","",Null, True)
'			isSuccess = True
'		Catch
'			Log(LastException)
'			isSuccess = False
'		End Try
'	End If
'	j.Release
'	Return CreateMap("issuccess": isSuccess, "objectid": objid)
'End Sub

'Sub sendBack4AppRequest()
'	Dim Job As HttpJob
'	Job.initialize("request", Me)
'	Job.Download("https://parseapi.back4app.com/classes/Product")
'	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
'	Job.GetRequest.SetHeader("X-Parse-Master-Key", objConfig.masterkey)
'	Wait For (Job) JobDone(j As HttpJob)
'	Log("B4XProductionPage.sendBack4AppRequest: " & j.Success)
'	If j.Success Then
'		Log(j.GetString)
'		Try
'			Dim jparser As JSONParser
'			jparser.Initialize(j.GetString)
'			Dim map1 As Map = jparser.Nextobject
'			Dim lst1 As List = map1.Get("results")
'			' lstToJsonString(lst1)
'			' ListView1.Clear
'			Dim isFilled As Boolean = fillTheList(lst1)
'			If isFilled Then
'				ScrollView1.Panel.RemoveAllViews
'				' Cast from double to int
'				ScrollView1.Panel.Height = dybtn.InnerPanelHeight
'				ScrollView1.Panel.Width = 100%x-20dip
'				' CreateButton would trigger the event - AddButtonHandler
'				' to add button(s) to existing scrollview
'				dybtn.CreateButtons
'			End If
'		Catch
'			Log(LastException)
'		End Try
'	End If
'	j.Release
'End Sub

Sub fillTheList(i_lst As List) As Boolean
	If i_lst.IsInitialized = False Then
		Return False
	End If
	If modCommon.mapOfProduct.IsInitialized Then
		modCommon.mapOfProduct.Clear
	Else
		modCommon.mapOfProduct.Initialize
	End If
	' Clone the responsed list to public product list
	For Each entry As Map In i_lst
		Dim obj As clsProduct
		obj.Initialize
		Dim isDeSer As Boolean = obj.myDeserialize(entry)
		If isDeSer Then
			If modCommon.mapOfProduct.ContainsKey(obj.Itemnum) = False Then
				modCommon.mapOfProduct.Put(obj.Itemnum, obj)
			End If			
		End If
	Next
	Return True
End Sub

' Menu Event Handler
Sub Connect_Click
	ConnectBluetoothDevices
End Sub
' Menu Event Handler
Sub Disconnect_Click
	DisconnectBluetoothDevices
End Sub

#Region Bluetooth_Event
Sub BTA_StateChanged (NewState As Int, OldState As Int)
	
End Sub
'
'Sub BTA_DiscoveryFinished
'	ProgressDialogHide
'	If lstOfFoundDevices.Size = 0 Then
'		ToastMessageShow("Bluetooth devices not found !!!"&CRLF&"Please try again !",True)
'	Else
'		Dim il As List
'		il.Initialize
'		For i=0 To lstOfFoundDevices.Size-1
'			Dim nm As BlueTooth_NameAndMac
'			nm = lstOfFoundDevices.Get(i)
'			il.Add(nm.Name)
'		Next
'		
'		InputListAsync(il, "Take from a paired device", 0, False)
'		Wait For InputList_Result (Index As Int)
'		If Index <> DialogResponse.CANCEL Then
'			connectedDevices = lstOfFoundDevices.Get(Index)
'			ProgressDialogShow("Connect with : "&CRLF&connectedDevices.Name&CRLF&"Mac Adr("&connectedDevices.Mac)
'			serialScale.Connect(connectedDevices.Mac)
'		End If
'		
'	End If
'End Sub
#End Region

#Region AsyncStream_Event

' Try parsing and extract numeric value from electronic scale
'Sub NumericReading(i_reading As String) As Double
'	Dim matcher1 As Matcher
'	matcher1 = Regex.Matcher("[\d\s]+\.[\d\s]+", i_reading)
'	Do While matcher1.Find = True
'		Dim tmp As String = matcher1.Match.Trim
'		If IsNumber(tmp) Then
'			Return tmp.As(Double)
'		End If
'	Loop
'	Return 0
'End Sub
#End Region

' Event handler 
Sub AddButtonHandler(mapRes As Map)
	Dim btn As Button = mapRes.Get("button")
	Dim x As Int = mapRes.Get("x")
	Dim y As Int = mapRes.Get("y")
	Dim w As Int = mapRes.Get("w")
	Dim h As Int = mapRes.Get("h")
	Dim row As Int = mapRes.Get("r")
	Dim col As Int = mapRes.Get("c")
	ScrollView1.Panel.AddView(btn, x, y, w, h)
	Log("Button added: " & $"(${row}, ${col})"$)
End Sub

' Event handler
Sub dybtn_click(res As String)
	If IsPaused(svcSerialScale) Then
		Return
	End If
	
	If currValue = 0 Or currValue = -1 Then
		Msgbox2Async("The reading is zero! Please place product on scale.", "Invalid", "OK", "", "", Null, True)
		Return
	End If
	
	ToastMessageShow(res, False)
	If modCommon.mapOfProduct.ContainsKey(res) Then
		Dim obj As clsProduct = modCommon.mapOfProduct.Get(res)
		Log(obj.ProductInfo)
		
		Dim objFP As clsFinishedProduct
		objFP.Initialize
		objFP.myDeserializeByObject(obj)		
		objFP.WeightInGram = currValue
		objFP.Barcode = obj.getProductBarcode(currValue)
		objFP.SellingPrice = obj.calcPriceByWeight(currValue)
		objFP.PackingDt = modCommon.getNowForShown
		objFP.PackedAt = modCommon.getNowWithTimeZone
		ProgressDialogShow2("Posting...", True)
		sendFinishedProductIntent("postandprint", "", objFP)
		'Wait For (sendFinishedProductIntent("postandprint", "", objFP)) Complete(mapRes As Map)
'		ProgressDialogHide
'		If mapRes.Get("issuccess").As(Boolean) = False Then
'			Msgbox2Async("Error: " & CRLF & mapRes.Get("errmsg").As(String), "Operation Error", "OK", "", "", Null, True)
'			Return 
'		End If
'		ToastMessageShow("Item: " & objFP.Product.Itemname2 & " is done.", False)
		
		
	End If
End Sub

' Function used to ask user to connect the bluetooth device
Private Sub ConnectBluetoothDevices()
	Dim pairedDevices As Map = mySerial.GetPairedDevices
	Dim il As List : il.Initialize
	For i=0 To pairedDevices.Size - 1
		il.Add(pairedDevices.GetKeyAt(i))
	Next
	
	InputListAsync(il, "Select a device", 0, False)
	Wait For InputList_Result (Index As Int)
	If Index <> DialogResponse.CANCEL Then
		Dim btOption As String = il.Get(Index) ' ["irxon", "XP-365B", "HC-06"]
		Dim btMac As String = pairedDevices.Get(btOption)
		Select Case btOption 
			Case "irxon" ' bluetooth adaptor of scale
				' serialScale.Connect(btMac)
				' btScale.Connect2(btMac)
				sendScaleIntent(btMac)
			Case "XP-365B" ' Xprinter
				'btPrinter.Connect2(btMac)
				sendFinishedProductIntent("btconnect", btMac, Null)
			Case Else
				Return
		End Select
		
		
	End If
End Sub

Private Sub btPrinter_NewData (Buffer() As Byte)
	
End Sub

Private Sub btPrinter_Error
	'ToastMessageShow(LastException.Message, True)
	LogColor("btPrinter Error: " & LastException.Message, Colors.Red)
End Sub
Private Sub btPrinter_Terminated
	ToastMessageShow("Connection (Printer) is terminated.", True)
	LogColor("btPrinter Terminated.", Colors.Blue)
End Sub

Private Sub btScale_Connected(issuccess As Boolean)
	Log("is btScale connected: " & issuccess)
End Sub

Private Sub btScale_NewText(mapRes As Map)	
	If mapRes.IsInitialized = False Then
		Return
	End If		
	currValue = mapRes.Get("value")
	lblData.Text = mapRes.Get("string")
	lblReading.Text = mapRes.Get("value") & " gram"	
End Sub

Private Sub btScale_Error
	LogColor("btScale Error: " & LastException.Message, Colors.Red)
End Sub

Private Sub btScale_Terminated
	ToastMessageShow("Connection (Scale) is terminated.", True)
	LogColor("btScale Terminated.", Colors.Blue)
End Sub

Private Sub DisconnectBluetoothDevices()
	
	'btPrinter.DisConnect
	Wait For (sendFinishedProductIntent("btdisconnect", "", Null)) Complete(mapRes As Map)
	
	If IsPaused(svcSerialScale) = False Then
		StopService(svcSerialScale)
	End If
End Sub

'Sub lstToJsonString(i_lst As List) As String
'	If i_lst.IsInitialized = False Then
'		Return "[]"		
'	End If
'	Dim jGen As JSONGenerator
'	Try
'		jGen.Initialize2(i_lst)
'		Return jGen.ToPrettyString(4)		
'	Catch
'		Log(LastException)
'		Return "[]"
'	End Try
'End Sub