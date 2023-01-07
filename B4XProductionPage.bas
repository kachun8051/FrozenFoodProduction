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
	'Private objConfig As clsConfig
	#End Region	
	Private lstProduct As List
	' Private rp As RuntimePermissions
	Private lblData As Label
	Private lblReading As Label
	Private currValue As Double
	
	' Private ScrollView1 As ScrollView
	' Private dybtn As cvDynamicButton
	Private BTA As BluetoothAdmin
	Private mySerial As Serial
	Private lstOfFoundDevices As List
	Type BlueTooth_NameAndMac (Name As String, Mac As String)
	Private cvDynamicButton1 As cvDynamicButton
End Sub

'You can add more parameters here.
Public Sub Initialize As Object
	'objConfig.Initialize
	lstProduct.Initialize	
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
	drManager.Initialize(Me, "Drawer", Root, 220dip)
	drManager.myDrawer.CenterPanel.LoadLayout("ProductionPage.bal")
	drManager.myDrawer.LeftPanel.LoadLayout("sidemenu")
	' Event handler is B4XPage_MenuClick
	B4XPages.GetManager.LogEvents = True	
	B4XPages.AddMenuItem(Me, "Connect Bluetooth")
	B4XPages.AddMenuItem(Me, "Disconnect Bluetooth")
	B4XPages.AddMenuItem(Me, "refresh")
	createMenu
	B4XPages.SetTitle(Me, "Production")
	'dybtn.Initialize(Me, "dybtn_click")
	' Please note that dimension of ScrollView is different from
	' dimension of panel of ScrollView
	Dim svHeight As Double = 100%y-70dip 'ScrollView1.Height
	Dim svWidth As Double = 100%x-20dip 'ScrollView1.Width
	LogColor("ScrollView's height: " & svHeight, Colors.Blue)
	LogColor("ScrollView's width: " & svWidth, Colors.Blue)
	cvDynamicButton1.setPanelHeightWidth(svHeight, svWidth)
	lblData.Text = ""
	lblReading.Text = ""
	' ScrollView1.Panel.Width = svWidth	
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
	cvDynamicButton1.resetNumOfRow
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
			cvDynamicButton1.resetNumOfRow
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

Sub sendHuskylensIntent(macaddr As String)
	If IsPaused(svcSerialHuskylens) = False Then
		StopService(svcSerialHuskylens)
	End If
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcserialhuskylens")
	' pidProduction is page id of B4XProductionPage
	inte.PutExtra("senderid", "pidProduction")
	inte.PutExtra("mac", macaddr)
	StartService(inte)
End Sub

Sub sendScaleIntent(macaddr As String)
	If IsPaused(svcSerialScale) = False Then
		StopService(svcSerialScale)
	End If
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcserialscale")
	' pidProduction is page id of B4XProductionPage
	inte.PutExtra("senderid", "pidProduction")
	inte.PutExtra("mac", macaddr)
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

' this event hander - LayoutLoaded would be triggered if
' custom view has loaded the layout file
Private Sub cvDynamicButton1_LayoutLoaded
	If lstProduct.Size = 0 Then
		' sendBack4AppRequest
		sendProductIntent("query")
	End If
End Sub
' this event hander - Refresh would be triggered if
' custom view pull to refresh in scrollview
Private Sub cvDynamicButton1_Refresh
	Log("Pull to refresh")
	' reset the num of row to get new data
	cvDynamicButton1.resetNumOfRow
	sendProductIntent("query")
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
		cvDynamicButton1.FillTheData
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
		Dim obj As clsProduct : obj.Initialize
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

' Event handler of custom view i.e. cyDynamicButton1
Private Sub cvDynamicButton1_ButtonClick (itemnum_1 As String)
	If IsPaused(svcSerialScale) Then
		Msgbox2Async("Scale Bluetooth is NOT connected. Please connect the scale bluetooth first.", _
			"Scale bluetooth not found", "OK", "Cancel", "", Null, True)
		Return
	End If	
	If currValue = 0 Or currValue = -1 Then
		Msgbox2Async("The reading is zero! Please place product on scale.", "Invalid", "OK", "", "", Null, True)
		Return
	End If	
	ToastMessageShow(itemnum_1, False)
	If modCommon.mapOfProduct.ContainsKey(itemnum_1) Then
		Dim obj As clsProduct = modCommon.mapOfProduct.Get(itemnum_1)
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
				sendScaleIntent(btMac)
			Case "XP-365B" ' Xprinter
				sendFinishedProductIntent("btconnect", btMac, Null)
			Case "HC-06" ' Huskylens
				sendHuskylensIntent(btMac)
			Case Else
				Return
		End Select
	End If
End Sub
#Region btPrinter_EventHandlers
Private Sub btPrinter_NewData (Buffer() As Byte)
	' Normally, bluetooth printer would not send data back to android 
End Sub

Private Sub btPrinter_Error
	'ToastMessageShow(LastException.Message, True)
	LogColor("btPrinter Error: " & LastException.Message, Colors.Red)
End Sub
Private Sub btPrinter_Terminated
	ToastMessageShow("Connection (Printer) is terminated.", True)
	LogColor("btPrinter Terminated.", Colors.Blue)
End Sub

Private Sub btPrinter_Connected(isbtOn As Boolean)
	Log("BT Printer Connected: " & isbtOn)
End Sub

Private Sub btPrinter_Disconnected(isbtOn As Boolean)
	Log("BT Printer Disconnected: " & isbtOn)
End Sub
#End Region

#Region btScale_EventHandlers
Private Sub btScale_Connected(issuccess As Boolean)
	Log("is btScale connected: " & issuccess)
End Sub

Private Sub btScale_Disconnected()
	Log("btScale disconnected.")
End Sub

Private Sub btScale_NewText(mapRes As Map)	
	If mapRes.IsInitialized = False Then
		Return
	End If
	If mapRes.ContainsKey("value") Then
		currValue = mapRes.Get("value")
		lblReading.Text = currValue & " gram"
	End If
	If mapRes.ContainsKey("string") Then
		' lblData.Text = mapRes.Get("string")
		LogColor("Data coming from scale: " & CRLF & mapRes.Get("string"), Colors.Blue)
	End If
		
End Sub

Private Sub btScale_Error
	LogColor("btScale Error: " & LastException.Message, Colors.Red)
End Sub

Private Sub btScale_Terminated
	ToastMessageShow("Connection (Scale) is terminated.", True)
	LogColor("btScale Terminated.", Colors.Blue)
End Sub
#End Region

#Region btHuskylens_EventHandlers
Private Sub btHuskylens_Connected(issuccess As Boolean)
	Log("Is btHuskylens connected: " & issuccess)
End Sub

Private Sub btHuskylens_Disconnected()
	Log("btHuskylens disconnected.")
End Sub

Sub btHuskylens_NewText(id As Int)
	If modCommon.mapOfTrainedData.IsInitialized = False Then
		lblData.Text = id
		Return
	End If
	' Type conversion
	Dim id_1 As String = id
	If modCommon.mapOfTrainedData.ContainsKey(id_1) Then
		Dim innermap As Map = modCommon.mapOfTrainedData.Get(id_1)
		Dim name_1 As String = innermap.Get("name")
		lblData.Text = $"Identified Object: ${name_1}"$
	End If
End Sub

Sub btHuskylens_Error
	ToastMessageShow("Network Error(Huskylens): " & LastException.Message, True)
	LogColor("btHuskylens Error: " & LastException.Message, Colors.Red)
End Sub

Sub btHuskylens_Terminated
	ToastMessageShow("Broken Connection(Huskylens) !!!",True)
	LogColor("btHuskylens Terminated.", Colors.Blue)
End Sub
#End Region

Private Sub DisconnectBluetoothDevices()	
	
	Wait For (sendFinishedProductIntent("btdisconnect", "", Null)) Complete(mapRes As Map)
	
	If IsPaused(svcSerialScale) = False Then
		StopService(svcSerialScale)
	End If
	If IsPaused(svcSerialHuskylens) = False Then
		StopService(svcSerialHuskylens)
	End If
End Sub