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
	' Page UI
	Private CLV1 As CustomListView
	Private Swipe As CLVSwipe
	Private ProgressBar1 As B4XView 'ignore
	Private lblPullToRefresh As B4XView 'ignore
	#Region RowCardUI
	Private lblItemNo As Label
	Private lblName As Label
	Private lblName2 As Label
	Private lblSellingPrice As Label
	Private lblWeight As Label
	Private lblDt As Label
	#End Region
	Private btnDate As Button
	Private lblDate As Label
	'''''''''''''''''''''''''''''''''''
	Private strDate As String
	Private lstOfProduction As List
	' the selected item's index would record here
	Private SelectedIndex As Int
	
End Sub

'You can add more parameters here.
Public Sub Initialize As Object
	Return Me
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	'load the layout to Root
	drManager.Initialize(Me, "Drawer", Root, 200dip)
	drManager.myDrawer.CenterPanel.LoadLayout("RecordPage.bal")
	drManager.myDrawer.LeftPanel.LoadLayout("sidemenu")
	createMenu
	B4XPages.SetTitle(Me, "Record")
	Swipe.Initialize(CLV1, Me, "Swipe")
	Swipe.ActionColors = CreateMap("Delete": xui.Color_Red, "Info": xui.Color_Green, "Print": xui.Color_Yellow)
	Dim PullToRefreshPanel As B4XView = xui.CreatePanel("")
	PullToRefreshPanel.SetLayoutAnimated(0, 0, 0, 100%x, 70dip)
	PullToRefreshPanel.LoadLayout("PullToRefresh.bal")
	Swipe.PullToRefreshPanel = PullToRefreshPanel
	SelectedIndex = -1
End Sub

'You can see the list of page related events in the B4XPagesManager object. The event name is B4XPage.
#Region B4XPageEvents
Private Sub B4XPage_Appear
	drManager.B4XPageAppear
	If lblDate.Text = "" Then
		If strDate = "" Then
			' when page initialize
			strDate = getNow
		End If
		lblDate.Text = strDate
	End If
	If CLV1.IsInitialized = False Then
		Return
	End If
	If CLV1.Size = 0 Then
		If lstOfProduction.IsInitialized = False Then
			' when page initialize
			ProgressDialogShow2("Production data loading...", True)
			sendQueryIntent(strDate.Replace("/", ""))
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

'Χρειάζεται για το DrawerMenu
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

Private Sub getDeletedResponse(issuccess As Boolean)
	ProgressDialogHide
	If issuccess Then
		If SelectedIndex <> -1 Then
			lstOfProduction.RemoveAt(SelectedIndex)
			CLV1.RemoveAt(SelectedIndex)
			CLV1.Refresh
		End If
	End If
End Sub

Private Sub getQueryResponse(mapRes As Map)
	ProgressDialogHide
	Swipe.RefreshCompleted ' <-- call to exit refresh mode
	lblPullToRefresh.Text = "Pull to refresh"
	ProgressBar1.Visible = False
	If mapRes.IsInitialized = False Then
		Return
	End If
	If mapRes.Get("issuccess").As(Boolean) = False Then
		Msgbox2Async(mapRes.Get("errmsg"), "Query Error", "OK", "", "", Null, True)
		Return
	End If
	lstOfProduction = mapRes.Get("datalist").As(List)
	FillTheList
End Sub

Private Sub getFinishedProductPrintedResponse(mapRes As Map)
	If mapRes.Get("issuccess").As(Boolean) = False Then
		MsgboxAsync(mapRes.Get("errmsg"), "Print Error")
		Return
	End If
	ToastMessageShow("Label Printed by selection.", True)
End Sub

Private Sub FillTheList() As Boolean
	If lstOfProduction.IsInitialized = False Then
		Return False
	End If
	For Each mapEntry As Map In lstOfProduction
		Dim p As B4XView = xui.CreatePanel("")
		p.SetLayoutAnimated(0, 0, 0, CLV1.AsView.Width, 180dip)
		Dim swipeitem As SwipeItem = Swipe.CreateItemValue(mapEntry, Array("Delete", "Print", "Info"))
		CLV1.Add(p, swipeitem)
	Next
	Return True
End Sub

Sub CLV1_VisibleRangeChanged (FirstIndex As Int, LastIndex As Int)
	Dim ExtraSize As Int = 20
	For i = Max(0, FirstIndex - ExtraSize) To Min(LastIndex + ExtraSize, CLV1.Size - 1)
		Dim p As B4XView = CLV1.GetPanel(i)
		If p.NumberOfViews = 0 Then
			Dim swipeitem_1 As SwipeItem = CLV1.GetValue(i)
			Dim map_1 As Map = swipeitem_1.Value
			'**************** this code is similar to the code in CreateItem from the original example
			p.LoadLayout("RowLayout.bal")
			lblItemNo.Text = map_1.Get("itemnum")
			lblName.Text = map_1.Get("itemname")
			lblName2.Text = map_1.Get("itemname2")
			lblSellingPrice.Text = "HK$" & map_1.Get("sellingprice")
			lblWeight.Text = map_1.Get("weightingram") & " gram"
			lblDt.Text = map_1.Get("packingdt").As(String).SubString2(0, 19)
		End If
	Next
End Sub

Sub Swipe_ActionClicked (Index As Int, ActionText As String)
	Log($"Action clicked: ${Index}, ${ActionText}"$)
	SelectedIndex = Index
	Select Case ActionText
		Case "Delete"
			Msgbox2Async("Are you sure to delete this record?", "Delete Record", "Yes", "Cancel", "No", Null, False)
			Wait For MsgBox_Result (Result As Int)
			If Result = DialogResponse.POSITIVE Then
				Dim swipeitem_2A As SwipeItem = CLV1.GetValue(Index)
				Dim map_2A As Map = swipeitem_2A.Value
				ProgressDialogShow2("Deleting...", True)
				sendDeleteIntent(map_2A.Get("objectId"), Index)
			End If
		Case "Info"
			Dim swipeitem_2B As SwipeItem = CLV1.GetValue(Index)
			Dim map_2B As Map = swipeitem_2B.Value
			Dim objFP As clsFinishedProduct
			objFP.Initialize
			Msgbox2Async(objFP.mapToString(map_2B), "Info", "OK", "", "", Null, True)
		Case "Print"
			Dim swipeitem_2C As SwipeItem = CLV1.GetValue(Index)
			Dim map_2C As Map = swipeitem_2C.Value
			Dim objFP_1 As clsFinishedProduct
			objFP_1.initialize
			objFP_1.myDeserializeByMap(map_2C)
			sendPrintIntent(objFP_1)			
		Case Else
			Log("Swipe Action (Else) Clicked: " & ActionText)
	End Select
End Sub

Sub Swipe_RefreshRequested
	If strDate <> "" Then
		lblPullToRefresh.Text = "Loading..."
		ProgressBar1.Visible = True
		CLV1.Clear
		lstOfProduction.Clear
		sendQueryIntent(strDate.Replace("/", ""))
	End If
End Sub

Private Sub sendQueryIntent(datecode As String)
	If datecode = "" Then
		datecode = getNowDateCode
	End If
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcback4appfinishedproduct")
	inte.PutExtra("senderid", "pidRecord")
	inte.PutExtra("task", "query")
	inte.PutExtra("param", datecode)
	StartService(inte)
End Sub

Private Sub sendDeleteIntent(objectId As String, Idx As Int)
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcback4appfinishedproduct")
	inte.PutExtra("senderid", "pidRecord")
	inte.PutExtra("task", "delete")
	inte.PutExtra("param", objectId)
	StartService(inte)
End Sub

Private Sub sendPrintIntent(objFP As clsFinishedProduct)
	Dim inte As Intent
	inte.Initialize("", "")
	inte.SetComponent(Application.PackageName & "/.svcback4appfinishedproduct")
	inte.PutExtra("senderid", "pidRecord")
	inte.PutExtra("task", "printonly")
	inte.PutExtra("param", objFP.mySerialize)
	StartService(inte)
End Sub

Private Sub getNowDateCode() As String
	Dim dtNow As Long = DateTime.Now
	' original date format
	Dim df As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyyMMdd"
	Dim daycode As String
	Try
		daycode = DateTime.Date(dtNow)
	Catch
		Log(LastException)
		daycode = ""
	End Try
	' Restore original date format
	DateTime.DateFormat = df
	Return daycode
End Sub

Private Sub btnDate_Click
	Dim dd As DateDialog
	dd.DateTicks = DateTime.Now
	Dim sf As Object = dd.ShowAsync("Choose Production date", "Which date?", "OK", "Cancel", "", Null, False)
	Wait For (sf) Dialog_Result(Result As Int)
	If Result = DialogResponse.POSITIVE Then
		Dim df As String = DateTime.DateFormat
		DateTime.DateFormat = "yyyy/MM/dd"
		strDate = DateTime.Date(dd.DateTicks)
		lblDate.Text = strDate
		Log(DateTime.Date(dd.DateTicks))
		DateTime.DateFormat = df
		CLV1.Clear
		lstOfProduction.Clear
		ProgressDialogShow2("Production data loading...", True)
		sendQueryIntent(strDate.Replace("/", ""))
	End If
End Sub

Private Sub getNow() As String
	Dim dtNow As String = ""
	Dim df As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyy/MM/dd"
	dtNow = DateTime.Date(DateTime.Now)
	DateTime.DateFormat = df
	Return dtNow
End Sub