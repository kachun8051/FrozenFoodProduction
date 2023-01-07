B4J=true
Group=Custom Class Group
ModulesStructureVersion=1
Type=Class
Version=6
@EndOfDesignText@
'ImageSlider v1.00
#DesignerProperty: Key: AnimationDuration, DisplayName: Animation Duration (ms), FieldType: Int, DefaultValue: 500
#DesignerProperty: Key: CacheSize, DisplayName: Image Cache Size, FieldType: Int, DefaultValue: 5
#DesignerProperty: Key: AnimationType, DisplayName: Animation Type, FieldType: String, DefaultValue: Horizontal, List: Vertical|Horizontal|Fade
#Event: GetImage (Index As Int) As ResumableSub
Sub Class_Globals
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Private mBase As B4XView
	Private xui As XUI
	Private CurrentPanel, NextPanel As B4XView
	Private panels As List
	Private CurrentIndex As Int
	Private CachedImages As List
	Private AnimationDuration As Int
	Private CacheSize As Int
	Type ImageSliderImage (bmp As B4XBitmap, index As Int)
	Private TaskIndex As Int
	Public NumberOfImages As Int
	Private AnimationType As String
	Public WindowBase As B4XView
	Private MousePressedX As Float
End Sub

Public Sub Initialize (Callback As Object, EventName As String)
	mEventName = EventName
	mCallBack = Callback
	CachedImages.Initialize
End Sub

Public Sub DesignerCreateView (Base As Object, Lbl As Label, Props As Map)
	mBase = Base
	WindowBase = xui.CreatePanel("WindowBase")
	mBase.AddView(WindowBase, 0, 0, 0, 0)
	AnimationDuration = Props.Get("AnimationDuration")
	CacheSize = Props.Get("CacheSize")
	AnimationType = Props.Get("AnimationType")
  	CurrentPanel = xui.CreatePanel("pnl")
	NextPanel = xui.CreatePanel("pnl")
	panels = Array(CurrentPanel, NextPanel)
	WindowBase.AddView(CurrentPanel, 0, 0, 0, 0)
	WindowBase.AddView(NextPanel, 0, 0, 0, 0)
	Dim iv1, iv2 As ImageView
	iv1.Initialize("")
	iv2.Initialize("")
	CurrentPanel.AddView(iv1, 0, 0, 0, 0)
	NextPanel.AddView(iv2, 0, 0, 0, 0)
	Base_Resize(mBase.Width, mBase.Height)
End Sub

Private Sub Base_Resize (Width As Double, Height As Double)
	WindowBase.SetLayoutAnimated(0, 0, 0, Width, Height)
	For Each p As B4XView In panels
		p.SetLayoutAnimated(0, 0, 0, Width, Height)
		p.GetView(0).SetLayoutAnimated(0, 0, 0, Width, Height)
	Next
	CachedImages.Clear 'clear the images cache as the sizes are no longer correct
End Sub

Private Sub ShowImage (bmp As B4XBitmap, MovingToNext As Boolean)
	If bmp = Null Then ' skip the null image
		Return
	End If
	NextPanel.GetView(0).SetBitmap(bmp)
	NextPanel.GetView(0).SetLayoutAnimated(0, WindowBase.Width / 2 - bmp.Width / 2, _
		WindowBase.Height / 2 - bmp.Height / 2, bmp.Width, bmp.Height)
	NextPanel.Visible = True
	Select AnimationType
		Case "Vertical"
			Dim top As Int
			If MovingToNext Then top = -NextPanel.Height Else top = NextPanel.Height
			NextPanel.SetLayoutAnimated(0, 0, top, NextPanel.Width, NextPanel.Height)
			NextPanel.SetLayoutAnimated(AnimationDuration, 0, 0, NextPanel.Width, NextPanel.Height)
			CurrentPanel.SetLayoutAnimated(AnimationDuration, 0, -top, CurrentPanel.Width, CurrentPanel.Height)
		Case "Horizontal"
			Dim left As Int
			If MovingToNext Then left = NextPanel.Width Else left = -NextPanel.Width
			NextPanel.SetLayoutAnimated(0, left, 0, NextPanel.Width, NextPanel.Height)
			NextPanel.SetLayoutAnimated(AnimationDuration, 0, 0, NextPanel.Width, NextPanel.Height)
			CurrentPanel.SetLayoutAnimated(AnimationDuration, -left, 0, CurrentPanel.Width, CurrentPanel.Height)
		Case "Fade"
			NextPanel.Visible = False
			NextPanel.SetLayoutAnimated(0, left, 0, NextPanel.Width, NextPanel.Height)
			NextPanel.SetVisibleAnimated(AnimationDuration, True)
			CurrentPanel.SetVisibleAnimated(AnimationDuration, False)			
	End Select
	Dim p As B4XView = CurrentPanel
	CurrentPanel = NextPanel
	NextPanel = p
End Sub

Public Sub NextImage
	TaskIndex = TaskIndex + 1
	Dim MyTask As Int = TaskIndex
	CurrentIndex = (CurrentIndex + 1) Mod NumberOfImages
	Wait For (GetImage(CurrentIndex)) Complete (Result As ImageSliderImage)
	If MyTask <> TaskIndex Then Return
	ShowImage(Result.bmp, True)
	Sleep(0)
	If CurrentIndex < NumberOfImages -1 Then GetImage(CurrentIndex + 1)
End Sub

Public Sub PrevImage
	TaskIndex = TaskIndex + 1
	Dim MyTask As Int = TaskIndex
	CurrentIndex = (CurrentIndex - 1 + NumberOfImages) Mod NumberOfImages
	Wait For (GetImage(CurrentIndex)) Complete (Result As ImageSliderImage)
	If MyTask <> TaskIndex Then Return
	ShowImage(Result.bmp, False)
	Sleep(0)
	If CurrentIndex > 0 Then GetImage(CurrentIndex - 1)
End Sub

Private Sub GetImage(index As Int) As ResumableSub
	For Each ii As ImageSliderImage In CachedImages
		If ii.index = index Then
			CachedImages.RemoveAt(CachedImages.IndexOf(ii))
			CachedImages.Add(ii)
			Return ii
		End If
	Next
	Dim rs As ResumableSub = CallSub2(mCallBack, mEventName & "_GetImage", index)
	Wait For (rs) Complete (bmp As B4XBitmap)
	Dim ii As ImageSliderImage
	ii.Initialize
	ii.bmp = bmp
	ii.index = index
	CachedImages.Add(ii)
	Do While CachedImages.Size > CacheSize
		CachedImages.RemoveAt(0)
	Loop
	Return ii
End Sub

Private Sub CheckTouchGesture(EndX As Float)
	If EndX > MousePressedX + 50dip Then
		PrevImage
	Else if EndX < MousePressedX - 50dip Then
		NextImage
	End If
End Sub

#if B4J
Private Sub WindowBase_MousePressed (EventData As MouseEvent)
	MousePressedX = EventData.X
End Sub

Private Sub WindowBase_MouseReleased (EventData As MouseEvent)
	CheckTouchGesture(EventData.X)
End Sub
#else
Private Sub WindowBase_Touch (Action As Int, X As Float, Y As Float)
	Dim p As Panel = WindowBase
	If Action = p.ACTION_DOWN Then
		MousePressedX = X
	Else If Action = p.ACTION_UP Then
		CheckTouchGesture(X)
	End If
End Sub
#End If



