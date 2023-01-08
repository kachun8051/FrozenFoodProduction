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
	'''''''''''''''''''''''''''''''''''	
	Private lstOfProduct As List
	Private btnSearch As Button
	Private edtSearch As EditText
	Private btnClear As Button
	' Page UI
	Private CLV2 As CustomListView
	Private Swipe As CLVSwipe
	Private ProgressBar1 As B4XView 'ignore
	Private lblPullToRefresh As B4XView 'ignore
	' row layout in CLV2
	Private lblItemNo As Label
	Private lblName As Label
	Private lblName2 As Label
	Private lblPrice As Label
	Private lblStdWeight As Label
	Private timer As Timer
	' found index when edtSearch is filled by barcode and enter is pressed
	Dim foundIdx As Int
End Sub

'You can add more parameters here.
Public Sub Initialize As Object
	timer.Initialize("timer1", 100)
	foundIdx = -1
	Return Me
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	'load the layout to Root
	drManager.Initialize(Me, "Drawer", Root, 220dip)
	drManager.myDrawer.CenterPanel.LoadLayout("ItemPage.bal")
	drManager.myDrawer.LeftPanel.LoadLayout("sidemenu")
	createMenu
	B4XPages.SetTitle(Me, "Item")
	Swipe.Initialize(CLV2, Me, "Swipe")
	Swipe.ActionColors = CreateMap("Info": xui.Color_Green)
	Dim PullToRefreshPanel As B4XView = xui.CreatePanel("")
	PullToRefreshPanel.SetLayoutAnimated(0, 0, 0, 100%x, 70dip)
	PullToRefreshPanel.LoadLayout("PullToRefresh.bal")
	Swipe.PullToRefreshPanel = PullToRefreshPanel	
	edtSearch.RequestFocus
End Sub

'You can see the list of page related events in the B4XPagesManager object. The event name is B4XPage.
#Region B4XPageEvents
Private Sub B4XPage_Appear
	drManager.B4XPageAppear
	If CLV2.IsInitialized = False Then
		Return
	End If
	edtSearch.Text = ""
	If CLV2.Size = 0 Then
		If lstOfProduct.IsInitialized = False Then
			' when page initialize
			ProgressDialogShow2("Product data loading...", True)
			sendProductIntent("query")
			Return
		End If
		FillTheList
	End If
End Sub

Private Sub B4XPage_CloseRequest As ResumableSub
	Return drManager.B4XPageCloseRequest
End Sub

Private Sub B4XPage_Disappear
	drManager.B4XPageDisappear
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

'Private Sub Button1_Click
'	xui.MsgboxAsync("Hello world!", "B4X")
'	' B4XPages.ShowPageAndRemovePreviousPages("Production")
'End Sub

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

Private Sub btnClear_Click
	edtSearch.Text = ""
End Sub

Private Sub edtSearch_EnterPressed
	searchByBarcode
End Sub

Private Sub btnSearch_Click
	searchByBarcode
End Sub

Private Sub searchByBarcode()
	timer.Enabled = True
	wait for timer1_Tick
	timer.Enabled = False
	edtSearch.RequestFocus
	edtSearch.SelectAll
	If edtSearch.Text.Length <> 18 Then
		ToastMessageShow("Please input barcode of finished product!", True)
		Return
	End If
	Dim itemnum_1 As String = edtSearch.Text.SubString2(1, 7)
	Dim itemname_1 As String = ""
	foundIdx = -1
	Dim idx As Int = 0
	For Each innermap As Map In lstOfProduct
		If innermap.Get("itemnum").As(String) = itemnum_1 Then
			foundIdx = idx
			itemname_1 = innermap.Get("itemname")
			Exit
		End If
		idx = idx + 1
	Next
	If foundIdx = -1 Then
		Msgbox2Async("Item #" & itemnum_1 & " is NOT found!", "Not found", "OK", "Cancel", "", Null, True)
		Return
	End If
	Try
		'CLV2.JumpToItem(foundIdx)
		CLV2.ScrollToItem(foundIdx)		
		ToastMessageShow(itemname_1 & " (#" & itemnum_1 & ") is found.", True)
	Catch
		Log(LastException)
	End Try
End Sub

Sub sendProductIntent(task As String)
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcback4appproduct")
	' pidItem is page id of B4XItemPage
	inte.PutExtra("senderid", "pidItem")
	inte.PutExtra("task", task)
	StartService(inte)
End Sub

Sub getProductResponse(mapRes As Map)
	StopService(svcBack4AppProduct)
	ProgressDialogHide
	Swipe.RefreshCompleted ' <-- call to exit refresh mode
	lblPullToRefresh.Text = "Pull to refresh"
	ProgressBar1.Visible = False
	Dim isSuccess As Boolean = mapRes.Get("issuccess")
	If isSuccess = False Then
		Msgbox2Async("Product retrieval error!", "Retrieval", "OK", "", "", Null, True)
		Return
	End If
	Dim lstOfProduct As List = mapRes.Get("datalist")
	FillTheList
End Sub

Private Sub FillTheList() As Boolean
	If lstOfProduct.IsInitialized = False Then
		Return False
	End If
	For Each mapEntry As Map In lstOfProduct
		Dim p As B4XView = xui.CreatePanel("")
		p.SetLayoutAnimated(0, 0, 0, CLV2.AsView.Width, 170dip)
		' Dim swipeitem As SwipeItem = Swipe.CreateItemValue(mapEntry, Array("Info"))
		' No swipe item 
		Dim swipeitem As SwipeItem = Swipe.CreateItemValue(mapEntry, Array())
		CLV2.Add(p, swipeitem)
	Next
	Return True
End Sub

Private Sub CLV2_VisibleRangeChanged (FirstIndex As Int, LastIndex As Int)
	Dim ExtraSize As Int = 20
	For i = Max(0, FirstIndex - ExtraSize) To Min(LastIndex + ExtraSize, CLV2.Size - 1)
		Dim p As B4XView = CLV2.GetPanel(i)
		If p.NumberOfViews = 0 Then
			Dim swipeitem_1 As SwipeItem = CLV2.GetValue(i)
			Dim map_1 As Map = swipeitem_1.Value
			'**************** this code is similar to the code in CreateItem from the original example			
			p.LoadLayout("ItemLayout.bal")			
			lblItemNo.Text = "#" & map_1.Get("itemnum")
			lblName.Text = map_1.Get("itemname")
			lblName2.Text = map_1.Get("itemname2")
			lblPrice.Text = "HK$" & map_1.Get("itemprice") & CRLF & "per " & map_1.Get("itemuom")
			lblStdWeight.Text = "Std Weight: " & map_1.Get("itemstandardweight") & " gram"
'			If foundIdx > -1 And i = foundIdx Then
'				' high light found row by yellow color
'				p.Color = Colors.Yellow
'				timer2.Enabled = True
'			End If
		End If
	Next
End Sub

Sub Swipe_RefreshRequested
		lblPullToRefresh.Text = "Loading..."
		ProgressBar1.Visible = True
		CLV2.Clear
		lstOfProduct.Clear
		sendProductIntent("query")
End Sub
