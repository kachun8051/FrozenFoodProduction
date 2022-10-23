B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.2
@EndOfDesignText@
Sub Class_Globals
	Public myDrawer As B4XDrawer
	Private mRoot As B4XView
	
	Private DrawerBasePanel As B4XView
	Private HamburgerIcon As B4XBitmap
	Private xui As XUI
	
	Public menuItems As List
	Public menuIcons As List
	
End Sub

Public Sub Initialize (Callback As Object, EventName As String, Root As B4XView, Width As Int)
	myDrawer.Initialize(Callback, EventName, Root, Width)
	mRoot = Root
	DrawerBasePanel = mRoot.GetView(0)
	HamburgerIcon = xui.LoadBitmapResize(File.DirAssets, "hamburger.png", 32dip, 32dip, True)
	
	menuItems.Initialize
	menuIcons.Initialize
	'Icons taken from materialdesignicons-webfont.ttf please use the bellow tool
	' https://www.b4x.com/android/forum/threads/b4x-materialicons-web-font-chooser.103985/
	menuIcons.AddAll(Array As String( Chr(0xfccc), Chr(0xf008), Chr(0xf1ad) ))
	menuItems.AddAll(Array As String( "Production", "Records", "Items"))
End Sub


Public Sub B4XPageAppear
	If DrawerBasePanel.Parent.IsInitialized = False Then
		mRoot.AddView(DrawerBasePanel, 0, 0, mRoot.Width, mRoot.Height)
	End If
	#if B4A
	Sleep(0)
	B4XPages.GetManager.ActionBar.RunMethod("setDisplayHomeAsUpEnabled", Array(True))
	Dim bd As BitmapDrawable
	bd.Initialize(HamburgerIcon)
	B4XPages.GetManager.ActionBar.RunMethod("setHomeAsUpIndicator", Array(bd))
	#End If
End Sub


Public Sub B4XPageDisappear
	myDrawer.LeftOpen = Not(myDrawer.LeftOpen)
	DrawerBasePanel.RemoveViewFromParent
	#if B4A
	B4XPages.GetManager.ActionBar.RunMethod("setHomeAsUpIndicator", Array(0))
	#end if
End Sub

Public Sub B4XPageCloseRequest As Boolean
	#if B4A
	'home button
	If Main.ActionBarHomeClicked Then
		myDrawer.LeftOpen = Not(myDrawer.LeftOpen)
		Return False
	End If
	'back key
	If myDrawer.LeftOpen Then
		myDrawer.LeftOpen = False
		Return False
	End If
	#end if
	Return True
End Sub


Public Sub mainMenu(value As Int)
	LogColor("drawer mainMenu selection: " & value, Colors.Magenta)
	Select value
		Case 0
			Log("Page Production")
			B4XPages.ShowPageandRemovePreviousPages("pidProduction")
		Case 1
			Log("Page Record")
			B4XPages.ShowPageandRemovePreviousPages("pidRecord")
		Case 2
			Log("Page Item")
			B4XPages.ShowPageandRemovePreviousPages("pidItem")
	End Select
End Sub