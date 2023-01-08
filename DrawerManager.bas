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
	Private dlgAbout As CustomLayoutDialog
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
	menuIcons.AddAll(Array As String( Chr(0xf2dc), Chr(0xfccc), Chr(0xf008), Chr(0xf1b8), Chr(0xf493), Chr(0xf2fc)))
	menuItems.AddAll(Array As String( "Main", "Production", "Records", "Items", "Diagnosis", "About"))
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
			Log("Main Page")
			B4XPages.ShowPageandRemovePreviousPages("MainPage")
		Case 1
			Log("Page Production")
			B4XPages.ShowPageandRemovePreviousPages("pidProduction")
		Case 2			
			Log("Page Record")
			B4XPages.ShowPageandRemovePreviousPages("pidRecord")
		Case 3
			Log("Page Item")
			B4XPages.ShowPageandRemovePreviousPages("pidItem")
		Case 4
			Log("Page Diagnosis")
			B4XPages.ShowPageandRemovePreviousPages("pidDiagnosis")
		Case 5
			Log("About Dialog")
			' Msgbox2Async("About Me", "About", "OK", "", "", Null, True)
			showAboutMeDialog
	End Select
End Sub

Private Sub showAboutMeDialog()
	Dim sf1 As Object = dlgAbout.ShowAsync("About this App", "OK", "", "", Null, True)
	Wait For (sf1) Dialog_Ready(DialogPanel As Panel)
	dlgAbout.SetSize(70%x, 85%y)
	Dim imageicon As ImageView : imageicon.Initialize("")
	imageicon.Bitmap = LoadBitmapResize(File.DirAssets, "frozenfoodlogo.png", 120dip, 120dip, True)
	imageicon.Gravity = Gravity.CENTER
		
	Dim lblAppName As Label : lblAppName.Initialize("")
	lblAppName.TextColor = Colors.Black
	lblAppName.TextSize = 20
	lblAppName.Text = "App Name: FrozenFoodProduction"
	Dim lblVersion As Label : lblVersion.Initialize("")
	lblVersion.TextColor = Colors.Black
	lblVersion.TextSize = 20
	lblVersion.Text = "Version: " & Application.VersionName
	
	Dim lblSubject As Label : lblSubject.Initialize("")
	lblSubject.TextColor = Colors.Black
	lblSubject.TextSize = 20
	lblSubject.Text = "Subject Name: IT Project"
	Dim lblSubject2 As Label : lblSubject2.Initialize("")
	lblSubject2.TextColor = Colors.Black
	lblSubject2.TextSize = 20
	lblSubject2.Text = "Subject Code: UFCFFC-30-3"
	Dim lblTutor As Label : lblTutor.Initialize("")
	lblTutor.TextColor = Colors.Black
	lblTutor.TextSize = 20
	lblTutor.Text = "Tutor Name: Mr. Jackie Kwong" 
	
	Dim lblAuthor As Label : lblAuthor.Initialize("")
	lblAuthor.TextColor = Colors.Black
	lblAuthor.TextSize = 20
	lblAuthor.Text = "Student Name: Wong Ka Chun"
	Dim lblStudentId As Label : lblStudentId.Initialize("")
	lblStudentId.TextColor = Colors.Black
	lblStudentId.TextSize = 20
	lblStudentId.Text = "Student Id: 217214002"
	Dim lblEmail As Label : lblEmail.Initialize("")
	lblEmail.TextColor = Colors.Black
	lblEmail.TextSize = 20
	lblEmail.SingleLine = False
	lblEmail.Text = "Student Email: "$
	Dim lblEmail_1 As Label : lblEmail_1.Initialize("")
	lblEmail_1.TextColor = Colors.Black
	lblEmail_1.TextSize = 20
	lblEmail_1.Text = "   217214002@stu.vtc.edu.hk"
	Dim lblEmail_2 As Label : lblEmail_2.Initialize("")
	lblEmail_2.TextColor = Colors.Black
	lblEmail_2.TextSize = 20
	lblEmail_2.Text = "   kcwong8051@gmail.com"
	Dim lblDate As Label : lblDate.Initialize("")
	lblDate.TextColor = Colors.Black
	lblDate.TextSize = 20
	lblDate.Text = "Date: 2023/01/08"
	
	DialogPanel.AddView(imageicon, 32%x-(120dip/2), 5dip, 120dip, 120dip)
	DialogPanel.AddView(lblAppName, 10dip, 130dip, 100%x, 30dip)
	DialogPanel.AddView(lblVersion, 10dip, 160dip, 100%x, 30dip) 
	DialogPanel.AddView(lblSubject, 10dip, 190dip, 100%x, 30dip)
	DialogPanel.AddView(lblSubject2, 10dip, 220dip, 100%x, 30dip)
	DialogPanel.AddView(lblTutor, 10dip, 250dip, 100%x, 30dip)
	DialogPanel.AddView(lblAuthor, 10dip, 280dip, 100%x, 30dip)
	DialogPanel.AddView(lblStudentId, 10dip, 310dip, 100%x, 30dip)
	DialogPanel.AddView(lblEmail, 10dip, 340dip, 100%x, 30dip)
	DialogPanel.AddView(lblEmail_1, 10dip, 370dip, 100%x, 30dip)
	DialogPanel.AddView(lblEmail_2, 10dip, 400dip, 100%x, 30dip)
	DialogPanel.AddView(lblDate, 10dip, 430dip, 100%x, 30dip)
	
	Wait For (sf1) Dialog_Result(result1 As Int)
End Sub