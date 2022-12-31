B4A=true
Group=Custom View Group
ModulesStructureVersion=1
Type=Class
Version=11.2
@EndOfDesignText@
'Custom View class 
#Event: ButtonClick (itemnum As String)
#Event: LayoutLoaded
#DesignerProperty: Key: BooleanExample, DisplayName: Boolean Example, FieldType: Boolean, DefaultValue: True, Description: Example of a boolean property.
#DesignerProperty: Key: IntExample, DisplayName: Int Example, FieldType: Int, DefaultValue: 10, MinRange: 0, MaxRange: 100, Description: Note that MinRange and MaxRange are optional.
#DesignerProperty: Key: StringWithListExample, DisplayName: String With List, FieldType: String, DefaultValue: Sunday, List: Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday
#DesignerProperty: Key: StringExample, DisplayName: String Example, FieldType: String, DefaultValue: Text
#DesignerProperty: Key: ColorExample, DisplayName: Color Example, FieldType: Color, DefaultValue: 0xFFCFDCDC, Description: You can use the built-in color picker to find the color values.
#DesignerProperty: Key: DefaultColorExample, DisplayName: Default Color Example, FieldType: Color, DefaultValue: Null, Description: Setting the default value to Null means that a nullable field will be displayed.
Sub Class_Globals
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Private mBase As Panel
	Public Const DefaultColorConstant As Int = -984833 'ignore
	Private Const m_NumOfCol As Int = 3
	Private m_NumOfRow As Int
	Private m_BtnWidth As Int
	Private m_BtnHeight As Int
	Private m_PanelWidth As Int
	Private m_PanelHeight As Int
	Type Pos(x As Int,y As Int)
	Private svDynamicButton As ScrollView
End Sub

Public Sub Initialize (Callback As Object, EventName As String)
	mEventName = EventName
	mCallBack = Callback
	m_NumOfRow = -1
End Sub

Public Sub DesignerCreateView (Base As Panel, Lbl As Label, Props As Map)
	mBase = Base
	' The solution is to use CallSubDelayed.
	' Reference: https://www.b4x.com/android/forum/threads/how-load-layout-in-a-customview-class.67125/
	CallSubDelayed(Me, "AfterLoadLayout")
End Sub

Private Sub AfterLoadLayout()
	Log("custom view - cvDynamicButton layout is loaded.")
	mBase.LoadLayout("dynamicbutton.bal")	
	svDynamicButton.Height = m_PanelHeight
	svDynamicButton.Width = m_PanelWidth
	If SubExists(mCallBack, mEventName & "_LayoutLoaded") Then
		CallSubDelayed(mCallBack, mEventName & "_LayoutLoaded")
	End If	
End Sub

Public Sub GetBase As Panel
	Return mBase
End Sub

Public Sub getNumOfCol() As Int
	Return m_NumOfCol
End Sub

Public Sub resetNumOfRow()
	m_NumOfRow = -1
End Sub

' Note: Number of Row is dependent of number of product fetched from cloud
Public Sub getNumOfRow() As Int
	If m_NumOfRow = -1 Then		
		If modCommon.mapOfProduct.IsInitialized = False Then
			Return 100%y - 70dip
		Else
			m_NumOfRow = Ceil(modCommon.mapOfProduct.Size / m_NumOfCol)
		End If
	End If
	Return m_NumOfRow
End Sub

Public Sub getBtnHeight() As Int
	Return m_BtnHeight
End Sub

Public Sub setPanelHeightWidth(h As Int, w As Int)
	m_PanelHeight = h
	m_PanelWidth = w
	m_BtnWidth = m_PanelWidth / m_NumOfCol
	m_BtnHeight = m_PanelHeight / 5
	Log("Panel's Height: " & m_PanelHeight)
	Log("Panel's Width: " & m_PanelWidth)
	Log("Button's Height: " & m_BtnHeight)
	Log("Button's Width: " & m_BtnWidth)
End Sub

Private Sub getInnerPanelHeight() As Int
	If m_NumOfRow = -1 Then
		m_NumOfRow = getNumOfRow
	End If	
	Return m_NumOfRow * m_BtnHeight
End Sub

Public Sub FillTheData() As Boolean
	' the inner panel height is dependent on the number of rows * height of each button
	svDynamicButton.Panel.Height = getInnerPanelHeight
	If svDynamicButton.IsInitialized Then
		svDynamicButton.Panel.RemoveAllViews
		Dim isCreated As Boolean = CreateButtons
		Return isCreated
	End If
	Return False
End Sub

Private Sub CreateButtons() As Boolean
    ' Note: CreateButton would access listOfProduct in modCommon
	'If modCommon.listOfProduct.IsInitialized = False Then
	'	Return False
	'End If
	If modCommon.mapOfProduct.IsInitialized = False Then
		Return False
	End If
	If svDynamicButton.IsInitialized = False Then
		Return False
	End If
	Dim NumOfProduct As Int = modCommon.mapOfProduct.Size ' modCommon.listOfProduct.Size
	m_NumOfRow = getNumOfRow
	LogColor("NumOfRow: " & m_NumOfRow, Colors.Blue) 
	For c = 0 To m_NumOfCol-1
		For r = 0 To m_NumOfRow-1
			Dim idx As Int = r * m_NumOfCol + c
			If idx >= NumOfProduct Then
				Exit
			End If
			Dim obj As clsProduct = modCommon.mapOfProduct.GetValueAt(idx) 'modCommon.listOfProduct.Get(idx)
			Dim ButtonX As Button
			Dim PosX As Pos
			PosX.x = c
			PosX.y = r
			ButtonX.Initialize("ButtonX")
			ButtonX.Tag = obj.Itemnum
			ButtonX.Text = obj.Itemname
			ButtonX.TextSize = 16
			svDynamicButton.Panel.AddView(ButtonX,c*m_BtnWidth,r*m_BtnHeight,m_BtnWidth,m_BtnHeight)
			Log("Button added: " & $"(${r}, ${c})"$)
		Next
	Next
    Return True
End Sub

Sub ButtonX_Click
	Dim Button1 As Button
	Button1 = Sender
	' Log(Button1.Left & " " & Button1.Top)
	Dim Item_1 As String = Button1.Tag
	' Dim Coordinate As String = $"(${Pos_1.x}, ${Pos_1.y})"$
	ToastMessageShow("Item# " & Item_1 & " is Clicked", False)
	If SubExists(mCallBack, mEventName & "_ButtonClick") Then
		CallSub2(mCallBack, mEventName & "_ButtonClick", Item_1)
	End If	
End Sub

Private Sub svDynamicButton_ScrollChanged(Position As Int)
	
End Sub