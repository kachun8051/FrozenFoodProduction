B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.8
@EndOfDesignText@
Sub Class_Globals
	' Private Astream As AsyncStreams
	Private AST As AsyncStreamsText
	Private Serial2 As Serial
	Private flagIsConn As Boolean
	Private flagConnError As String
	Private EventName As String 'ignore
	Private CallBack As Object 'ignore
End Sub

'Initialize the object with the parent and event name
Public Sub Initialize(vCallback As Object, vEventName As String)
	EventName = vEventName
	CallBack = vCallback
	Serial2.Initialize("Serial2")
	flagIsConn = False
	flagConnError = ""
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
Public Sub Connect2(mac As String)
	Serial2.Connect(mac)
End Sub

Public Sub Connect As ResumableSub
	' Ask the user to connect to a printer and return whether tried or not
	' If True then a subsequent Connected event will indicate success or failure
	Dim PairedDevices As Map
	PairedDevices = Serial2.GetPairedDevices
	Dim l As List
	l.Initialize
	For i = 0 To PairedDevices.Size - 1
		l.Add(PairedDevices.GetKeyAt(i))
	Next
	InputListAsync(l, "Choose a Scale", 0, False) 'show list with paired devices
	Wait For InputList_Result (Index As Int)
	If Index <> DialogResponse.CANCEL Then
		Log("Selected place (Scale): " & l.Get(Index))
		Serial2.Connect(PairedDevices.Get(l.Get(Index))) 'convert the name to mac address
		Return True
	End If
	Return False
End Sub

Public Sub DisConnect
	' Disconnect the printer
	If Serial2.IsInitialized Then
		Serial2.Disconnect
	End If	
'	If AST.IsInitialized Then
'		AST.Close
'	End If
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
	If SubExists(CallBack, EventName & "_Connected") Then
		CallSub2(CallBack, EventName & "_Connected", Success)
	End If
End Sub
#End Region

#Region Internal_AsyncStream_Events
' Internal AsyncStream Events
Private Sub AST_NewText (Text As String)
	Log("Data " & Text)
	If SubExists(CallBack, EventName & "_NewText") Then
		CallSub2(CallBack, EventName & "_NewText", Text)
	End If	
End Sub

Private Sub AST_Error
	If SubExists(CallBack, EventName & "_Error") Then
		CallSub(CallBack, EventName & "_Error")
	End If
End Sub

Private Sub AST_Terminated
	flagIsConn = False
	If SubExists(CallBack, EventName & "_Terminated") Then
		CallSub(CallBack, EventName & "_Terminated")
	End If
End Sub
#End Region