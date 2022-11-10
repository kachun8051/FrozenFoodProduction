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
	' Which activity or page consume this service
	Private mySender As Object
	Private objConfig As clsConfig
End Sub

Sub Service_Create
	mySender = Null
	objConfig.Initialize
End Sub

Sub Service_Start (StartingIntent As Intent)
	Service.StopAutomaticForeground 'Call this when the background task completes (if there is one)
	If StartingIntent.HasExtra("senderid") = False Then
		StopService("")
		Return
	End If
	If StartingIntent.HasExtra("task") = False Then
		StopService("")
		Return
	End If
	Dim SenderId_1 As String = StartingIntent.GetExtra("senderid")
	mySender = B4XPages.GetPage(SenderId_1)
	Dim task_1 As String = StartingIntent.GetExtra("task")
	
	Select task_1
		Case ""
	End Select
	
End Sub

Sub Service_Destroy

End Sub

Sub sendBack4AppPost(fp As clsFinishedProduct) As ResumableSub
	Dim isSuccess As Boolean = False
	Dim objid As String = ""
	Dim Job As HttpJob
	Job.initialize("post", Me)
	Job.PostString("https://parseapi.back4app.com/classes/Production", fp.JsonStringForPost)
	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
	Job.GetRequest.SetHeader("X-Parse-REST-API-Key", objConfig.ApiKey)
	Job.GetRequest.SetContentType("application/json")
	ProgressDialogShow2("Posting...", True)
	Wait For JobDone(j As HttpJob)
	ProgressDialogHide
	If j.Success Then
		Log(j.GetString)
		Try
			Dim jparser As JSONParser
			jparser.Initialize(j.GetString)
			Dim map2 As Map = jparser.NextObject
			objid = map2.Get("objectId")
			Msgbox2Async($"objectId: ${map2.Get("objectId")}${CRLF}createdAt: ${map2.Get("createdAt")}"$, "Response","Done","","",Null, True)
			isSuccess = True
		Catch
			Log(LastException)
			isSuccess = False
		End Try
	End If
	j.Release
	Return CreateMap("issuccess": isSuccess, "objectid": objid)
End Sub