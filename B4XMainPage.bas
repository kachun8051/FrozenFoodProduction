B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Region Shared Files
#CustomBuildAction: folders ready, %WINDIR%\System32\Robocopy.exe,"..\..\Shared Files" "..\Files"
'Ctrl + click to sync files: ide://run?file=%WINDIR%\System32\Robocopy.exe&args=..\..\Shared+Files&args=..\Files&FilesSync=True
#End Region
'Ctrl + click to export as zip: ide://run?File=%B4X%\Zipper.jar&Args=Project.zip

Sub Class_Globals
	Private Root As B4XView
	Private xui As XUI
'	Private Label1 As Label		
	' Drawer Menu Variables ''''''''''''
	Private drManager As DrawerManager
	Private clvDrawer As CustomListView
	Private clvIcon As Label
	Private clvMenuLabel As Label
	'''''''''''''''''''''''''''''''''''
	Private pProduction As B4XProductionPage
	Private pRecord As B4XRecordPage
	Private pItem As B4XItemPage
	Private btnExit As Button
	Private ImageView1 As ImageView
	Private btnNext As Button
	Private btnPlay As Button
	Private btnPrev As Button
	Private ImageSlider1 As ImageSlider
	Private lstImage As List
	Private timer1 As Timer
End Sub

Public Sub Initialize
'	B4XPages.GetManager.LogEvents = True
End Sub

'This event will be called once, before the page becomes visible.
Private Sub B4XPage_Created (Root1 As B4XView)
	Root = Root1	
	drManager.Initialize(Me, "Drawer", Root, 220dip)
	drManager.myDrawer.CenterPanel.LoadLayout("MainPage.bal")
	drManager.myDrawer.LeftPanel.LoadLayout("sidemenu.bal")
	createMenu
	' Enable logging B4XPages events
	B4XPages.GetManager.LogEvents = True
	B4XPages.SetTitle(Me, "Main Page")
	pProduction.Initialize
	B4XPages.AddPage("pidProduction", pProduction)
	pRecord.Initialize
	B4XPages.AddPage("pidRecord", pRecord)
	pItem.Initialize
	B4XPages.AddPage("pidItem", pItem)	
'	Label1.Text = "Welcome To" & CRLF & "Frozen Food Production"	
	initMainPage
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
'Check Draw Menu
Private Sub clvDrawer_ItemClick(Index As Int, Val As Object)
	drManager.mainMenu(Index)
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

Private Sub btnExit_Click
	Msgbox2Async("Do you want to leave?","Exit","OK","Cancel","",Null,False)
	Wait For Msgbox_Result (Result As Int)
	If Result = DialogResponse.POSITIVE Then
		ExitApplication
	End If	
End Sub

Private Sub initMainPage()

	timer1.Initialize("timer1", 3000)
	lstImage.Initialize2(Array As String( _
	 	"beefslice", "breamfish", "greenshrimp", "lobster", _
		"porkslice", "portunus", "safflowercrab", "squid", "tenderloin"))
	ImageSlider1.NumberOfImages = lstImage.Size
	btnPlay_Click
End Sub

Private Sub ImageSlider1_GetImage (Index As Int) As ResumableSub
	If File.Exists(File.DirAssets, lstImage.Get(Index) & ".png") Then
		Return xui.LoadBitmapResize(File.DirAssets, lstImage.Get(Index) & ".png", _
        	ImageSlider1.WindowBase.Width, ImageSlider1.WindowBase.Height, True)	
	End If	
	Return Null
End Sub

Private Sub btnPrev_Click
	ImageSlider1.PrevImage
End Sub

Private Sub btnPlay_Click
	timer1.Enabled = Not(timer1.Enabled)
	If timer1.Enabled Then btnPlay.Text = Chr(0xF04D) Else btnPlay.Text = Chr(0xF04B)
End Sub

Private Sub btnNext_Click
	ImageSlider1.NextImage
End Sub

Sub Timer1_Tick
	btnNext_Click
End Sub