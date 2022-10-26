B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.8
@EndOfDesignText@
Sub Class_Globals
	' API functions according TSPL
	' Reference: https://hackernoon.com/how-to-print-labels-with-tspl-and-javascript
	' Reference: https://www.dobus.ru/pdf/programming-manual-for-ht300.pdf
	' Reference: http://www.bar-tech.com.tw/eng/download/12790046025_TSPL_TSPL2_Programming_2009_06_24.pdf
	Private Astream As AsyncStreams
	Private Serial1 As Serial
	Private flagIsConn As Boolean
	Private flagConnError As String
	Private EventName As String 'ignore
	Private CallBack As Object 'ignore
	Private Const vbCrLf As String=Chr(13) & Chr(10) '\r\n
End Sub

'Initialize the object with the parent and event name
Public Sub Initialize(vCallback As Object, vEventName As String)
	EventName = vEventName
	CallBack = vCallback
	Serial1.Initialize("Serial1")
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
	Return Serial1.IsEnabled
End Sub

Public Sub Connect2(mac As String)
	Serial1.Connect(mac)
End Sub

Public Sub Connect As ResumableSub
	' Ask the user to connect to a printer and return whether tried or not
	' If True then a subsequent Connected event will indicate success or failure
	Dim PairedDevices As Map
	PairedDevices = Serial1.GetPairedDevices
	Dim l As List
	l.Initialize
	For i = 0 To PairedDevices.Size - 1
		l.Add(PairedDevices.GetKeyAt(i))
	Next
	InputListAsync(l, "Choose a printer", 0, False) 'show list with paired devices
	Wait For InputList_Result (Index As Int)
	If Index <> DialogResponse.CANCEL Then
		Log("Selected place: " & l.Get(Index))
		Serial1.Connect(PairedDevices.Get(l.Get(Index))) 'convert the name to mac address
		Return True
	End If
	Return False
End Sub

Public Sub DisConnect
	' Disconnect the printer
	Serial1.Disconnect
	flagIsConn = False
End Sub

Public Sub FlushClose
	Astream.SendAllAndClose
End Sub
#End Region

#Region Common_API_1
Public Sub Size(Width As Double,Height As Double)
	' Label's size configure
	' TSPL command: SIZE 40 mm,30 mm\n
	' We can also set it in a metric system (mm):
	' SIZE 50 mm,25 mm
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("SIZE ")
	sb.Append(Width).Append(" mm,")
	sb.Append(Height).Append(" mm").Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub GAP(Interval As Double,Deviation As Double)
	' Vertial distance between two labels
	' TSPL command: GAP 1.5 mm,0 mm\n
	' GAP 3 mm,0 mm
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("GAP ")
	sb.Append(Interval).Append(" mm,")
	sb.Append(Deviation).Append(" mm").Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub DENSITY2(Concentration As Int)
	' Printer's density i.e. darker if higher
	' TSPL command: DENSITY 7\n
	' Note: Default DENSITY setting is 8.
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("DENSITY ").Append(Concentration).Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub DIRECTION(mType As Int)
	' Print direction
	' TSPL command: DIRECTION 1\n
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("DIRECTION ").Append(mType).Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub REFERENCE(X As Int,Y As Int)
	' Set Origin
	' REFERENCE 10,10
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("REFERENCE ")
	sb.Append(X).Append(",")
	sb.Append(Y).Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub
#End Region

#Region Common_API_2
Public Sub HOME
	' This command will feed label until the internal sensor has determined the origin.
	' Size and gap of the label
	' should be defined before using this command.
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("HOME").Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub BACKUP(n As Int)
	' BACKUP n (TSPL printers only)
	' BACKFEED n (TSPL2 printers only)
	' This command feeds the label in reverse. The length is specified by dot.
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("BACKUP ").Append(n).Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub FORMFEED
	' This command feeds label to the beginning of next label.
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("FORMFEED").Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub CLS
	' This command clears the image buffer.
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("CLS").Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub TEXT(X As Int, Y As Int, FontName As String, Rotation As Int, _
	xMultiplication As Double, yMultiplication As Double, mText As String)
	' This command prints text on label
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("TEXT ")
	sb.Append(X).Append(",")
	sb.Append(Y).Append(",")
	sb.Append("""").Append(FontName).Append(""",")
	sb.Append(Rotation).Append(",")
	sb.Append(xMultiplication).Append(",")
	sb.Append(yMultiplication).Append(",")
	sb.Append("""").Append(mText).Append("""").Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("GBK"))
End Sub

Public Sub BARCODE(X As Int, Y As Int, CodeType As String, Height As Int, _
	ShowTxt As Boolean, rotation As Int, narrow As Int, wide As Int, CodeText As String)
	' This command prints 1D barcodes.
	' X, Y, barcode type, height, show text?, rotation angle, narrow bar width,
	' wide bar width, barcode text
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("BARCODE ")
	sb.Append(X).Append(",")
	sb.Append(Y).Append(",")
	sb.Append("""").Append(CodeType).Append(""",")
	sb.Append(Height).Append(",")
	If ShowTxt=True Then
		sb.Append("1").Append(",")
	Else
		sb.Append("0").Append(",")
	End If
	sb.Append(rotation).Append(",")
	sb.Append(narrow).Append(",")
	sb.Append(wide).Append(",")
	sb.Append("""").Append(CodeText).Append("""").Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub QRCODE(X As Int,Y As Int,EccLevel As String,CellWidth As Int,mode As String,rotation As Int,CodeText As String)
	' This command prints QR code
	' X, Y, Error correction recovery level (L/N/Q/H), Code Width, <A for auto, M for manual>,
	' rotation angle, code text
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("QRCODE ")
	sb.Append(X).Append(",")
	sb.Append(Y).Append(",")
	sb.Append(EccLevel).Append(",")
	sb.Append(CellWidth).Append(",")
	sb.Append(mode).Append(",")
	sb.Append(rotation).Append(",")
	sb.Append("""").Append(CodeText).Append("""").Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("utf8"))
End Sub

Public Sub PRINT(m As Int,n As Int)
	' This command prints the label format currently stored in the image buffer
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("PRINT ")
	If n>0 Then
		sb.Append(m).Append(",").Append(n).Append(vbCrLf)
	Else
		sb.Append(m).Append(vbCrLf)
	End If
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub EOP()
	' End of program. To declare the start and end of BASIC language commands
	' used in a program, DOWNLOAD “FILENAME.BAS” must be added in the
	' first line of the program, And “EOP” statement at the last line of program.
	Dim sb As StringBuilder
	sb.Initialize
	sb.Append("EOP").Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ASCII"))
End Sub

Public Sub PUTBMP(X As Int,Y As Int,FilePath As String,FileName As String)
	' This command prints BMP format images.
	Dim sb As StringBuilder
	Dim d() As Byte=Bit.InputStreamToBytes(File.OpenInput(FilePath, FileName))
	Dim Bconv As ByteConverter
	sb.Initialize
	' download the image file to printer
	sb.Append("DOWNLOAD ")
	sb.Append("""PrintImg.BMP""")
	sb.Append(",").Append(d.Length)
	sb.Append(",").Append(Bconv.StringFromBytes(d,"ISO-8859-1")).Append(vbCrLf)
	' print image
	sb.Append("PUTBMP ")
	sb.Append(X).Append(",")
	sb.Append(Y).Append(",")
	sb.Append("""PrintImg.BMP""").Append(vbCrLf)
	Astream.Write(sb.ToString.GetBytes("ISO-8859-1"))
End Sub

Public Sub BITMAP(X As Int,Y As Int,mode As Int,Img As Bitmap)
	' This command draws bitmap images (as opposed to BMP graphic files)
	Dim a As String
	Dim sb As StringBuilder
	' width must be in byte i.e. divisible by 8
	Dim w As Int=Img.Width
	If (w Mod 8)=0 Then
		w=w/8
	Else
		w=w/8+1
	End If
	' image processing
	a=ImageToStr(Img)
	sb.Initialize
	sb.Append("BITMAP ")
	sb.Append(X).Append(",")
	sb.Append(Y).Append(",")
	sb.Append(w).Append(",")
	sb.Append(Img.Height).Append(",")
	sb.Append(mode).Append(",")
	sb.Append(a).Append(vbCrLf)
	
	Astream.Write(sb.ToString.GetBytes("ISO-8859-1"))
End Sub

Public Sub ImageToBWIMage(BMP As Bitmap) As Boolean()
	' Convert image to array
	Dim BC As BitmapCreator 'ignore
	Dim W As Int = BMP.Width
	Dim H As Int = BMP.Height
	Dim pixels(W * H) As Boolean
	Dim s As Int
	'Dim r As Double,g As Short,b As Short
	
	For y = 0 To H - 1
		s=y*W
		For x = 0 To W - 1
			Dim j As Int = BMP.GetPixel(x, y)
			' convert color to approximate luminance value
			Dim col As ARGBColor
			BC.ColorToARGB(j, col)
			Dim lum As Int = col.r * 0.11 + col.g*0.59 + col.b*0.3
			'r=Bit.And(j,0xFF)
			'g=Bit.And((j / 0x100),0xFF)
			'b=Bit.And((j / 0x10000),0xFF)
			' change to greyscale
			'Dim lum As Int = r * 0.11 + g*0.59 + b*0.3
			If lum> 255 Then lum = 255
			' save the pixel luminance
			pixels(s + x) = lum<127
		Next
	Next
	Return pixels
End Sub

Private Sub ImageToStr(BMP As Bitmap) As String
	' Convert Byte to String
	Dim b() As Boolean
	Dim W As Int,H As Int
	Dim x As Int,y As Int
	
	b=ImageToBWIMage(BMP)
	W=BMP.Width
	H=BMP.Height

	Dim masks(8) As Short
	masks(0) = 0x80
	masks(1) = 0x40
	masks(2) = 0x20
	masks(3) = 0x10
	masks(4) = 0x08
	masks(5) = 0x04
	masks(6) = 0x02
	masks(7) = 0x01
	Dim sb As StringBuilder
	sb.Initialize
	Dim t As Int,s As Int
	For y=0 To H-1
		s=y*W
		For x=0 To W-1 Step 8
			t=255
			If x+7>W Then
				For j=0 To W-x-1
					If b(s+x+j) Then
						t=t-masks(j)
					End If
				Next
			Else
				For j=0 To 7
					If b(s+x+j) Then
						t=t-masks(j)
					End If
				Next
			End If
			sb.Append(Chr(t))
		Next
	Next
	Return sb.ToString
End Sub
#End Region

#Region Internal_Serial_Events
Private Sub Serial1_Connected (Success As Boolean)
	' Internal Serial Events
	If Success Then
		Astream.Initialize(Serial1.InputStream, Serial1.OutputStream, "astream")
		flagIsConn = True
		flagConnError = ""
		Serial1.Listen
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
Private Sub AStream_NewData (Buffer() As Byte)
	If SubExists(CallBack, EventName & "_NewData") Then
		CallSub2(CallBack, EventName & "_NewData", Buffer)
	End If
	Log("Data " & Buffer(0))
End Sub

Private Sub AStream_Error
	If SubExists(CallBack, EventName & "_Error") Then
		CallSub(CallBack, EventName & "_Error")
	End If
End Sub

Private Sub AStream_Terminated
	flagIsConn = False
	If SubExists(CallBack, EventName & "_Terminated") Then
		CallSub(CallBack, EventName & "_Terminated")
	End If
End Sub
#End Region