B4A=true
Group=Public Access Group
ModulesStructureVersion=1
Type=Class
Version=11.2
@EndOfDesignText@
Sub Class_Globals
	Private m_appid As String
	'Dim appidGiven As String
	Private m_apikey As String
	'Dim apikeyGiven As String
	Private m_masterkey As String
	'Dim masterkeyGiven As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	' Account of kcwong8051@gmail.com
	m_appid = "5vUD5SzypdFDZfa7Sxjya1yLliHMAJ52ML3sqBf6"
	m_apikey = "sgyDDR9YYlvTfkZv1datnUu75nhnnjqejm2yMFNL"
	m_masterkey = "xFPWpeqIXuGXBek7CljLVsRH72TjvQen5Rd9XxiF"
	' Account of zebramc36002@gmail.com
'	m_appid = "6DILeMWIdzEA4jzdj9am5UV5czdUD5rmEIQzbh3A"
'	m_apikey = "AwqvAouTa7RNoktwCTdNc4Wc7DQDF9v41BpfN0v9"
'	m_masterkey = "lxU1bFBupo35PVUUkfAjos44hFUqNhFyHTEgQCCZ"
End Sub

Public Sub getAppId() As String
	Return m_appid
End Sub

Public Sub getApiKey() As String
	Return m_apikey
End Sub

Public Sub getMasterKey() As String
	Return m_masterkey
End Sub