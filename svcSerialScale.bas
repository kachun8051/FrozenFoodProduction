B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=11.8
@EndOfDesignText@
#Region  Service Attributes 
	#StartAtBoot: False
	
#End Region

Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.
	Private AST As AsyncStreamsText
	Private Serial2 As Serial
	Private flagIsConn As Boolean
	Private flagConnError As String
	' Which activity or page consume this service 
	Private mySender As Object
	' Bluetooth mac address of scale
	Private myMac As String
	' current reading text from scale
	Private currTextReading As String
	Private currValueReading As Double
End Sub

Sub Service_Create
	flagIsConn = False
	flagConnError = ""
	mySender = Null
	' myEventHandler = ""
	myMac = ""
	currTextReading = ""
	currValueReading = -1
End Sub

Sub Service_Start (StartingIntent As Intent)
	Service.StopAutomaticForeground 'Call this when the background task completes (if there is one)
	If StartingIntent.HasExtra("senderid") = False Then
		StopService("")
		Return
	End If
	If StartingIntent.HasExtra("mac") = False Then
		StopService("")
		Return
	End If
	Dim SenderId_1 As String = StartingIntent.GetExtra("senderid")
	mySender = B4XPages.GetPage(SenderId_1)
	myMac = StartingIntent.GetExtra("mac")
	Serial2.Initialize("Serial2")
	Connect2(myMac)
	
End Sub

Sub Service_Destroy
	' Release the resources
	DisConnect
End Sub

Public Sub getValue() As Double
	Return currValueReading
End Sub

#Region Bluetooth_fundamental
Public Sub ConnectedErrorMsg As String
	' Returns any error raised by the last attempt to connect a printer
	Return flagConnError
End Sub

Public Sub IsConnected As Boolean
	' Returns whether a printer is connected or not
	Return flagIsConn
End Sub

Public Sub IsBluetoothOn As Boolean
	' Returns whether Bluetooth is on or off
	Return Serial2.IsEnabled
End Sub
' Connect the Scale by MAC address directly
Private Sub Connect2(mac As String)
	Serial2.Connect(mac)
End Sub

'Public Sub Connect As ResumableSub
'	' Ask the user to connect to a printer and return whether tried or not
'	' If True then a subsequent Connected event will indicate success or failure
'	Dim PairedDevices As Map
'	PairedDevices = Serial2.GetPairedDevices
'	Dim l As List
'	l.Initialize
'	For i = 0 To PairedDevices.Size - 1
'		l.Add(PairedDevices.GetKeyAt(i))
'	Next
'	InputListAsync(l, "Choose a Scale", 0, False) 'show list with paired devices
'	Wait For InputList_Result (Index As Int)
'	If Index <> DialogResponse.CANCEL Then
'		Log("Selected place (Scale): " & l.Get(Index))
'		Serial2.Connect(PairedDevices.Get(l.Get(Index))) 'convert the name to mac address
'		Return True
'	End If
'	Return False
'End Sub

Private Sub DisConnect
	' Disconnect the printer
	If Serial2.IsInitialized Then
		Serial2.Disconnect
	End If
	If AST.IsInitialized Then
		AST.Close
	End If
	flagIsConn = False
End Sub

'Public Sub FlushClose
'	If AST.IsInitialized Then
'		AST.Close
'	End If
'	Astream.SendAllAndClose
'End Sub
#End Region

#Region Internal_Serial_Events
Private Sub Serial2_Connected (Success As Boolean)
	' Internal Serial Events
	If Success Then
		If AST.IsInitialized Then AST.Close
		AST.Initialize(Me, "AST", Serial2.InputStream, Serial2.OutputStream)
		flagIsConn = True
		flagConnError = ""
		Serial2.Listen
	Else
		flagIsConn = False
		flagConnError = LastException.Message
	End If
	If SubExists(mySender, "btScale_Connected") Then
		CallSub2(mySender, "btScale_Connected", Success) 'ignore
	End If
End Sub
#End Region

#Region Internal_AsyncStream_Events
' Internal AsyncStream Events
' This event would keep interacting with bluetooth scale (i.e. very busy) until the service is terminated
' Refresh to UI by CallSub2 in consumer activity or page only the receiving text is different from before.
' Thus, asynchronous of I/O interaction is achieved by this service to relieve the bundle of activity
Private Sub AST_NewText (Text As String)
	If currTextReading = Text Then 
		' No change in coming message
		' Most of time sending same message when the scale is in idle
		Return
	End If
	Log("Data " & Text)
	' Update the current reading
	currTextReading = Text
	If Text.Length = 19 Then
		' Log("Message received: " & Text)
		If currValueReading <> NumericReading(Text) Then
			currValueReading = NumericReading(Text)
			LogColor("Weighting Scale Value : " & Round2(currValueReading, 3) & " g", Colors.Magenta)
			' lblReading.Text = currValRec & " gram"
		End If
	End If
	If SubExists(mySender, "btScale_NewText") Then
		CallSub2(mySender, "btScale_NewText", CreateMap("string": currTextReading, "value": currValueReading)) 'ignore
	End If
End Sub

Private Sub AST_Error
	If SubExists(mySender, "btScale_Error") Then
		CallSub(mySender, "btScale_Error") 'ignore
	End If
End Sub

Private Sub AST_Terminated
	flagIsConn = False
	If SubExists(mySender, "btScale_Terminated") Then
		CallSub(mySender, "btScale_Terminated") 'ignore
	End If
End Sub
#End Region

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
