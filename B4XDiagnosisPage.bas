B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.8
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView 'ignore
	Private xui As XUI 'ignore
	Type BlueTooth_NameAndMac (Name As String, mac As String)
	Private mySerial As Serial
	Private currValue As Double
	
	Private selectedBluetoothDeviceName As String
	Private selectedMacAddress As String
	
	Private timer1 As Timer
	' Drawer Menu Variables ''''''''''''
	Private drManager As DrawerManager
	Private clvDrawer As CustomListView
	Private clvIcon As Label
	Private clvMenuLabel As Label
	' UI
	Private ckbHuskylens As CheckBox
	Private ckbPrinter As CheckBox
	Private ckbScale As CheckBox
	Private edtHuskylens As EditText
	Private edtScale As EditText
	Private edtScanner As EditText
	Private btnClear As Button	
	Private btnPrint As Button
End Sub

'You can add more parameters here.
Public Sub Initialize As Object
	mySerial.Initialize("mySerial")
	currValue = -1
	selectedBluetoothDeviceName = ""
	selectedMacAddress = ""
	' The timer is used to delay auto-connection to bluetooth devices
	timer1.Initialize("timer1", 200)
	Return Me
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	'load the layout to Root
	'load the layout to Root
	drManager.Initialize(Me, "Drawer", Root, 220dip)
	drManager.myDrawer.CenterPanel.LoadLayout("DiagnosisPage.bal")
	drManager.myDrawer.LeftPanel.LoadLayout("sidemenu")
	' Event handler is B4XPage_MenuClick
	B4XPages.AddMenuItem(Me, "Connect Bluetooth")
	B4XPages.AddMenuItem(Me, "Disconnect Bluetooth")
	B4XPages.AddMenuItem(Me, "Refresh")
	createMenu
	B4XPages.SetTitle(Me, "Diagnosis")
	timer1.Enabled = True
End Sub

'You can see the list of page related events in the B4XPagesManager object. The event name is B4XPage.

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

#Region B4XPageEvents
Private Sub B4XPage_Appear
	drManager.B4XPageAppear
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	Return drManager.B4XPageCloseRequest
End Sub

Private Sub B4XPage_Disappear
	drManager.B4XPageDisappear
	DisconnectBluetoothDevices
End Sub

' For DrawerMenu
Private Sub B4XPage_Resize (Width As Int, Height As Int)
	drManager.myDrawer.Resize(Width, Height)
End Sub
#End Region
'Check Draw Menu
Private Sub clvDrawer_ItemClick(Index As Int, Val As Object)
	drManager.mainMenu(Index)
End Sub

Private Sub B4XPage_MenuClick(Tag As String)
	Log("B4XPage_MenuClick: " & Tag)
	Select Tag
		Case "Connect Bluetooth"
			ConnectBluetoothDevices
		Case "Disconnect Bluetooth"
			DisconnectBluetoothDevices
		Case "Refresh"
			' reset the status of connected devices and ui
			resetConnection
			resetUI			
	End Select
End Sub

Private Sub timer1_Tick
	timer1.Enabled = False
	resetConnection
	resetUI
End Sub

Private Sub resetConnection()
	If IsPaused(svcSerialScale) = False Then
		StopService(svcSerialScale)
	End If
	If IsPaused(svcBack4AppFinishedProduct) = False Then
		StopService(svcBack4AppFinishedProduct)
	End If
	If IsPaused(svcSerialHuskylens) = False Then
		StopService(svcSerialHuskylens)
	End If
End Sub

Private Sub resetUI()
	edtScale.Text = ""	
	edtHuskylens.Text = ""
	edtScanner.Text = ""
	ckbScale.Checked = False
	ckbPrinter.Checked = False
	ckbHuskylens.Checked = False
End Sub

Private Sub DisconnectBluetoothDevices()	
	Wait For (sendFinishedProductIntent("btdisconnect", "")) Complete(mapRes As Map)
	
	If IsPaused(svcSerialScale) = False Then
		StopService(svcSerialScale)
	End If
	If IsPaused(svcSerialHuskylens) = False Then
		StopService(svcSerialHuskylens)
	End If
End Sub

' Function used to ask user to connect the bluetooth device
Private Sub ConnectBluetoothDevices()
	Dim pairedDevices As Map = mySerial.GetPairedDevices
	Dim il As List : il.Initialize
	For i=0 To pairedDevices.Size - 1
		il.Add(pairedDevices.GetKeyAt(i))
	Next
	selectedBluetoothDeviceName = ""
	selectedMacAddress = ""
	InputListAsync(il, "Select a device", 0, False)
	Wait For InputList_Result (Index As Int)
	If Index <> DialogResponse.CANCEL Then
		Dim btOption As String = il.Get(Index) ' ["irxon", "XP-365B", "HC-06"]
		Dim btMac As String = pairedDevices.Get(btOption)
		Select Case btOption
			Case "irxon" ' bluetooth adaptor of scale
				selectedBluetoothDeviceName = "irxon"
				selectedMacAddress = btMac
				sendScaleIntent(btMac)				
			Case "XP-365B" ' Xprinter
				selectedBluetoothDeviceName = "XP-365B"
				selectedMacAddress = btMac
				sendFinishedProductIntent("btconnect", btMac)
			Case "HC-06" ' Huskylens
				selectedBluetoothDeviceName = "HC-06"
				selectedMacAddress = btMac
				sendHuskylensIntent(btMac)
			Case Else
				Return
		End Select
	End If
End Sub

Sub sendHuskylensIntent(macaddr As String)
	If IsPaused(svcSerialHuskylens) = False Then
		StopService(svcSerialHuskylens)
	End If
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcserialhuskylens")
	' pidProduction is page id of B4XProductionPage
	inte.PutExtra("senderid", "pidDiagnosis")
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
	inte.PutExtra("senderid", "pidDiagnosis")
	If macaddr <> "" Then
		inte.PutExtra("mac", macaddr)
	End If	
	StartService(inte)
End Sub

Sub sendFinishedProductIntent(task As String, macaddr As String)
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcback4appfinishedproduct")
	' pidProduction is page id of B4XProductionPage
	inte.PutExtra("senderid", "pidDiagnosis")
	inte.PutExtra("task", task)
	If task = "btconnect" Then
		inte.PutExtra("param", macaddr)
	End If
	StartService(inte)
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
	Log("is BT Printer Connected: " & isbtOn)
	ToastMessageShow("is BT Printer Connected: " & isbtOn, True)
	ckbPrinter.Checked = isbtOn
	updateBluetoothMacAddress(selectedBluetoothDeviceName, selectedMacAddress)
End Sub

Private Sub btPrinter_Disconnected(isbtOn As Boolean)
	Log("BT Printer Disconnected: " & isbtOn)
	If ckbPrinter.IsInitialized Then
		ckbPrinter.Checked = isbtOn
	End If	
End Sub
#End Region

#Region btScale_EventHandlers
Private Sub btScale_Connected(issuccess As Boolean)
	Log("is btScale connected: " & issuccess)
	ToastMessageShow("is btScale connected: " & issuccess, True)
	ckbScale.Checked = issuccess
	updateBluetoothMacAddress(selectedBluetoothDeviceName, selectedMacAddress)
End Sub

Private Sub btScale_Disconnected()
	Log("btScale disconnected.")
	ckbScale.Checked = False
End Sub

Private Sub btScale_NewText(mapRes As Map)
	If mapRes.IsInitialized = False Then
		Return
	End If
	If mapRes.ContainsKey("value") Then
		currValue = mapRes.Get("value")
		' lblReading.Text = currValue & " gram"
		edtScale.Text = currValue & " gram"
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
	ckbHuskylens.Checked = True
	Log("Is btHuskylens connected: " & issuccess)	
	ToastMessageShow("Is btHuskylens connected: " & issuccess, True)
	updateBluetoothMacAddress(selectedBluetoothDeviceName, selectedMacAddress)
End Sub

Private Sub btHuskylens_Disconnected()
	ckbHuskylens.Checked = False
	Log("btHuskylens disconnected.")
End Sub

Sub btHuskylens_NewText(id As Int)
	If modCommon.mapOfTrainedData.IsInitialized = False Then
		' lblData.Text = id
		edtHuskylens.Text = id
		Return
	End If
	' Type conversion
	Dim id_1 As String = id
	If modCommon.mapOfTrainedData.ContainsKey(id_1) Then
		Dim innermap As Map = modCommon.mapOfTrainedData.Get(id_1)
		Dim name_1 As String = innermap.Get("name")
		' lblData.Text = $"Identified Object: ${name_1}"$
		edtHuskylens.Text = $"Identified Object: ${name_1}"$
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

Private Sub btnClear_Click
	If edtScanner.IsInitialized Then
		edtScanner.Text = ""
	End If
	edtScanner.RequestFocus
End Sub

Private Sub btnPrint_Click
	sendFinishedProductIntent("printtest", "")
End Sub

Private Sub getPrintTestResponse(mapRes As Map)
	If mapRes.IsInitialized = False Then
		Return
	End If
	If mapRes.Get("issuccess").As(Boolean) = True Then
		Msgbox2Async("Test is printed", "Test Print", "OK", "", "", Null, True)
		Return
	End If
	Msgbox2Async("Test is NOT printed" & CRLF & mapRes.Get("errmsg"), "Test Print", "OK", "", "", Null, True)
End Sub

Private Sub updateBluetoothMacAddress(name_1 As String, mac_1 As String) As Boolean
	If modCommon.mapOfMacAddress.IsInitialized = False Then
		modCommon.mapOfMacAddress.Initialize
	End If
	If modCommon.mapOfMacAddress.ContainsKey(name_1) Then
		modCommon.mapOfMacAddress.Remove(name_1)		
	End If
	modCommon.mapOfMacAddress.Put(name_1, mac_1)
	Dim JGen As JSONGenerator
	Try
		JGen.Initialize(modCommon.mapOfMacAddress)
		File.WriteString(File.DirDefaultExternal, "config/bluetoothmacaddress.json", JGen.ToPrettyString(4))
		Return True
	Catch
		Log(LastException)
		Return False
	End Try
End Sub