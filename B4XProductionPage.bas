B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.2
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView 'ignore
	Private xui As XUI 'ignore
	
	' Drawer Menu Variables ''''''''''''
	Private drManager As DrawerManager
	Private clvDrawer As CustomListView
	Private clvIcon As Label
	Private clvMenuLabel As Label
	Private objConfig As clsConfig
	'''''''''''''''''''''''''''''''''''	
	Private lstProduct As List
	Private lblData As Label
	Private lblReading As Label
	Private currValRec As Double
	
	Private ScrollView1 As ScrollView
	Private dybtn As cvDynamicButton
	Private btPrinter As clsTSPLPrinter
	' Serial for weighting scale
	Private BTA As BluetoothAdmin
	Private serialScale As Serial
	Private flagIsScaleConn As Boolean 'ignore
	Private lstOfFoundDevices As List
	Dim AST As AsyncStreamsText
	Type BlueTooth_NameAndMac (Name As String, Mac As String)
	Dim connectedDevices As BlueTooth_NameAndMac
End Sub

'You can add more parameters here.
Public Sub Initialize As Object
	objConfig.Initialize
	lstProduct.Initialize
	btPrinter.Initialize(Me, "btPrinter")
	currValRec = -1
	Return Me
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1

	
	' Dim mi_1 As B4AMenuItem = B4XPages.AddMenuItem(Me, "test")
	' mi_1.AddToBar = True
	
	flagIsScaleConn = False
	BTA.Initialize("BTA")
	serialScale.Initialize("SERIALSCALE")
	lstOfFoundDevices.Initialize	
	
	'load the layout to Root
	drManager.Initialize(Me, "Drawer", Root, 200dip)
	drManager.myDrawer.CenterPanel.LoadLayout("ProductionPage")
	drManager.myDrawer.LeftPanel.LoadLayout("sidemenu")
	' Event handler is B4XPage_MenuClick
	B4XPages.GetManager.LogEvents = True
	B4XPages.AddMenuItem(Me, "Connect Bluetooth")
	B4XPages.AddMenuItem(Me, "Disconnect Bluetooth")
	
	'drManager.
	
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
		sendBack4AppRequest
		
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
	' If UserClosed Then
		If AST.IsInitialized Then
			AST.Close
		End If
		If serialScale.IsInitialized Then
			serialScale.Disconnect
		End If
		' Activity.Finish
	' End If
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

Sub sendBack4AppRequest()
	Dim Job As HttpJob
	Job.initialize("request", Me)
	Job.Download("https://parseapi.back4app.com/classes/Product")
	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
	Job.GetRequest.SetHeader("X-Parse-Master-Key", objConfig.masterkey)
	Wait For (Job) JobDone(j As HttpJob)
	Log("B4XProductionPage.sendBack4AppRequest: " & j.Success)
	If j.Success Then
		Log(j.GetString)
		Try
			Dim jparser As JSONParser
			jparser.Initialize(j.GetString)
			Dim map1 As Map = jparser.Nextobject
			Dim lst1 As List = map1.Get("results")
			lstToJsonString(lst1)
			' ListView1.Clear
			Dim isFilled As Boolean = fillTheList(lst1)
			If isFilled Then
				ScrollView1.Panel.RemoveAllViews
				' Cast from double to int
				ScrollView1.Panel.Height = dybtn.InnerPanelHeight
				ScrollView1.Panel.Width = 100%x-20dip
				' CreateButton would trigger the event - AddButtonHandler
				' to add button(s) to existing scrollview
				dybtn.CreateButtons
			End If
		Catch
			Log(LastException)
		End Try
	End If
	j.Release
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

Sub BTA_DiscoveryFinished
	ProgressDialogHide
	If lstOfFoundDevices.Size = 0 Then
		ToastMessageShow("Bluetooth devices not found !!!"&CRLF&"Please try again !",True)
	Else
		Dim il As List
		il.Initialize
		For i=0 To lstOfFoundDevices.Size-1
			Dim nm As BlueTooth_NameAndMac
			nm = lstOfFoundDevices.Get(i)
			il.Add(nm.Name)
		Next
		
		InputListAsync(il, "Take from a paired device", 0, False)
		Wait For InputList_Result (Index As Int)
		If Index <> DialogResponse.CANCEL Then
			connectedDevices = lstOfFoundDevices.Get(Index)
			ProgressDialogShow("Connect with : "&CRLF&connectedDevices.Name&CRLF&"Mac Adr("&connectedDevices.Mac)
			serialScale.Connect(connectedDevices.Mac)
		End If
		
	End If
End Sub
#End Region

#Region Serial_Event
Sub SERIALSCALE_Connected (Success As Boolean)
	ProgressDialogHide
	
	If Success Then
		ToastMessageShow("Connect successfully",True)
		flagIsScaleConn = True
		If AST.IsInitialized Then AST.Close
		AST.Initialize(Me, "AST", serialScale.InputStream, serialScale.OutputStream)
		' Timer1.Enabled = True
	Else
		flagIsScaleConn = False
		ToastMessageShow("Troubled connecting ...!",True)
	End If
End Sub
#End Region

#Region AsyncStream_Event
Sub AST_Error
	ToastMessageShow("Network Error: " & LastException.Message, True)
End Sub

Sub AST_Terminated
	ToastMessageShow("Broken Connection !!!",True)
End Sub

Sub AST_NewText( Text As String)
	If lblData.Text = Text Then
		Return
	End If
	lblData.Text = Text
	If Text.Length = 19 Then
		' Log("Message received: " & Text)
		If currValRec <> NumericReading(Text) Then
			currValRec = NumericReading(Text)
			LogColor("Weighting Scale Value : " & Round2(currValRec, 3) & " g", Colors.Magenta)
			lblReading.Text = currValRec & " gram"
		End If
	End If
End Sub
' Try parsing and extract numeric value from electronic scale
Sub NumericReading(i_reading As String) As Double
	Dim matcher1 As Matcher
	matcher1 = Regex.Matcher("[\d\s]+\.[\d\s]+", i_reading)
	Do While matcher1.Find = True
		Dim tmp As String = matcher1.Match.Trim
		If IsNumber(tmp) Then
			Return tmp.As(Double)
		End If
	Loop
	Return 0
End Sub
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
	If currValRec = -1 Or currValRec = 0 Then
		Return
	End If
	ToastMessageShow(res, False)
	If modCommon.mapOfProduct.ContainsKey(res) Then
		Dim obj As clsProduct = modCommon.mapOfProduct.Get(res)
		Log(obj.ProductInfo)
		btPrinter.Size(50, 38)
		btPrinter.GAP(1.5,0)
		btPrinter.DENSITY2(7)
		btPrinter.DIRECTION(0)
		btPrinter.REFERENCE(0,0)
		'Printer2.HOME
		'Printer2.BACKUP(320)
		btPrinter.CLS
		Dim a As String
		a="Test" & DateTime.Date(DateTime.Now) & " " &  DateTime.Time(DateTime.Now)
		btPrinter.TEXT(20, 10, "TSS24.BF2", 0, 1.2, 1.2, obj.Itemname2)
		btPrinter.TEXT(20, 60, "TSS24.BF2", 0, 0.8, 0.8, obj.Itemname)
		btPrinter.TEXT(20, 100, "TSS24.BF2", 0, 1, 1, "Per 100g:")
		btPrinter.TEXT(150, 100, "TSS24.BF2", 0, 1, 1, "HK$" & NumberFormat(obj.ItemPrice, 0, 1))
		btPrinter.TEXT(20, 140, "TSS24.BF2", 0, 1, 1, "Weight:")
		btPrinter.TEXT(150, 140, "TSS24.BF2", 0, 1, 1, NumberFormat(currValRec, 0, 1) & " gram")
		btPrinter.TEXT(20, 170, "TSS24.BF2", 0, 1, 1, "Price:")		
		btPrinter.TEXT(150, 170, "TSS24.BF2", 0, 1, 1, "HK$" & NumberFormat(obj.calcPriceByWeight(currValRec), 0, 1))
		btPrinter.BARCODE(20, 210, "128",70,False,0,2,4, obj.getProductBarcode(currValRec))
		' btPrinter.QRCODE(20, 150,"L",3,"A",0,a)
		'only print bmp
		' btPrinter.PUTBMP(100,140,File.DirAssets,"umbellar2.bmp")
		' btPrinter.BITMAP(200,140,0,LoadBitmap(File.DirAssets,"umbellar.jpg"))
		btPrinter.PRINT(1,0)
		btPrinter.EOP
	End If
End Sub

' Function used to ask user to connect the bluetooth device
Private Sub ConnectBluetoothDevices()
	Dim pairedDevices As Map
	pairedDevices = serialScale.GetPairedDevices
	Dim il As List
	il.Initialize
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
				serialScale.Connect(btMac)
			Case "XP-365B" ' Xprinter
				btPrinter.Connect2(btMac)
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
	ToastMessageShow("Connection is terminated.", True)
	LogColor("btPrinter Terminated.", Colors.Blue)
End Sub

Private Sub DisconnectBluetoothDevices()
	AST.Close
	serialScale.Disconnect
	btPrinter.DisConnect
	flagIsScaleConn = False
End Sub

Sub lstToJsonString(i_lst As List) As String
	If i_lst.IsInitialized = False Then
		Return "[]"		
	End If
	Dim jGen As JSONGenerator
	Try
		jGen.Initialize2(i_lst)
		Return jGen.ToPrettyString(4)		
	Catch
		Log(LastException)
		Return "[]"
	End Try
End Sub