B4A=true
Group=Public Access Group
ModulesStructureVersion=1
Type=StaticCode
Version=11.2
@EndOfDesignText@
'Code module
'Subs in this code module will be accessible from all modules.
Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.
	
	' This is list of product which is accessible for other activities
	' Public listOfProduct As List
	' The key is item number while the value is clsProduct 
	Public mapOfProduct As Map
	Public mapOfTrainedData As Map
End Sub

Public Sub getNowForShown() As String
	Dim df As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyy/MM/dd HH:mm:ss"
	Dim dt As String = DateTime.Date(DateTime.Now)
	Log(dt)
	' restore the original date format
	DateTime.DateFormat = df
	Return dt
End Sub

Public Sub getNowWithTimeZone() As String
	Dim df As String = DateTime.DateFormat
	DateTime.DateFormat = "yyyy-MM-dd HH:mm:ss"
	Dim dt As String = DateTime.Date(DateTime.Now).Replace(" ", "T") & getTimeZoneInString
	Log(dt)
	' restore the original date format
	DateTime.DateFormat = df
	Return dt	 
End Sub

Public Sub getTimeZoneInString() As String
	Dim timezone As Int = getTimeZone
	Dim prefix As String = ""
	If timezone > 0 Then
		prefix = "+"
	Else
		prefix = "-"
	End If
	If Abs(timezone) < 10 Then
		prefix = prefix & "0"
	End If
	Dim tz As String = prefix & Abs(timezone).As(String) & ":00"
	Return tz
End Sub

Public Sub getTimeZone() As Int
	Dim timezone As Long
	Dim df As String = DateTime.DateFormat
	DateTime.DateFormat = "dd/MM/yyyy"
	timezone = -DateTime.DateParse("01/01/1970")
	Dim tz As Int = timezone / DateTime.TicksPerHour
	' restore the date format
	DateTime.DateFormat = df
	Return tz
End Sub

'Public Sub NowInUTC() As String
'	Dim timezone As Int = DateTime.TimeZoneOffset
'	Dim df As String = DateTime.DateFormat
'	DateTime.SetTimeZone(8) 'only need to set it once so the process is now based on UTC timezone.
'	DateTime.DateFormat = "dd/MM/yyyy HH:mm:ss z"
'	Dim utc As String = DateTime.Date(DateTime.Now)
'	' Dim ticks As Long = DateTime.DateParse("03/07/2015 11:11:44" & " EST")
'	Log(utc)
'	DateTime.SetTimeZone(timezone)
'	DateTime.DateFormat = df
'	Return utc
'	
'End Sub