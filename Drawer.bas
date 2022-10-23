B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.2
@EndOfDesignText@
Sub Class_Globals
	Private Root As B4XView 'ignore
	Private xui As XUI

	Private Drawer As B4XDrawer
	Public HamburgerIcon As B4XBitmap
	Public LeftOpen As Boolean 
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	Drawer.Initialize(Me, "Drawer", Root, 200dip)
End Sub

Public Sub createDrawer(page As String)
	Drawer.CenterPanel.LoadLayout(page)
	Drawer.LeftPanel.LoadLayout("sidemenu.bal")
	
	HamburgerIcon = xui.LoadBitmapResize(File.DirAssets, "hamburger.png", 32dip, 32dip, True)
	
End Sub


Public Sub Resize(Width As Int, Height As Int )
	Drawer.Resize(Width, Height)
End Sub


'To menu της εφαρμογής
Public Sub menuItem_Click
	Dim p As Panel = Sender
	Select p.Tag
		Case "page1"
			Log("page1 clicked")
			B4XPages.ShowPage("Page 1")
		Case "page2"
			Log("page2 clicked")
			B4XPages.ShowPage("Page 2")
		Case "page3"
			Log("page3 clicked")
			B4XPages.ShowPage("Page 3")
	End Select
End Sub


