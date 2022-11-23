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
End Sub

Public Sub NowInUTC() As String
	Dim timezone As Int = DateTime.TimeZoneOffset
	Dim df As String = DateTime.DateFormat
	DateTime.SetTimeZone(8) 'only need to set it once so the process is now based on UTC timezone.
	DateTime.DateFormat = "dd/MM/yyyy HH:mm:ss z"
	Dim utc As String = DateTime.Date(DateTime.Now)
	' Dim ticks As Long = DateTime.DateParse("03/07/2015 11:11:44" & " EST")
	Log(utc)
	DateTime.SetTimeZone(timezone)
	DateTime.DateFormat = df
	Return utc
	
End Sub