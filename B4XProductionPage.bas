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
End Sub

'You can add more parameters here.
Public Sub Initialize As Object
	objConfig.Initialize
	lstProduct.Initialize
	Return Me
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1
	'load the layout to Root
	drManager.Initialize(Me, "Drawer", Root, 200dip)
	drManager.myDrawer.CenterPanel.LoadLayout("ProductionPage")
	drManager.myDrawer.LeftPanel.LoadLayout("sidemenu")
	createMenu
	B4XPages.SetTitle(Me, "Production")
	If lstProduct.Size = 0 Then
		sendBack4AppRequest
		
	End If
End Sub

'You can see the list of page related events in the B4XPagesManager object. The event name is B4XPage.
#Region B4XPageEvents
Private Sub B4XPage_Appear
	drManager.B4XPageAppear
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
			' fillTheList(lst1)
		Catch
			Log(LastException)
		End Try
	End If
	j.Release
End Sub

Sub fillTheList(i_lst As List)
	If i_lst.IsInitialized = False Then
		Return
	End If
	
End Sub

Sub createButtonArray()
	
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