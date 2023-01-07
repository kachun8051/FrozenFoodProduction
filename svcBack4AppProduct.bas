B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Service
Version=11.8
@EndOfDesignText@
#Region  Service Attributes 
	#StartAtBoot: False
	
#End Region
' This service is used to do the CRUD with backend i.e. Back4App
Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.
	' Which activity or page consume this service
	Private mySender As Object
	Private objConfig As clsConfig
	Private lstOfProduct As List
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
		Case "query"
			Wait For (sendBack4AppRequest) Complete(isSuccess As Boolean)
			If isSuccess Then
				CallSubDelayed2(mySender, "getProductResponse", _
					CreateMap("issuccess": True, "datalist": lstOfProduct))
			Else
				CallSubDelayed2(mySender, "getProductResponse", _
					CreateMap("issuccess": False))	
			End If
			
	End Select
	
End Sub

Sub Service_Destroy

End Sub

Sub sendBack4AppRequest() As ResumableSub
	Dim isSuccess As Boolean = False
	Dim Job As HttpJob
	Job.initialize("request", Me)
	Job.Download("https://parseapi.back4app.com/classes/Product")
	Job.GetRequest.SetHeader("X-Parse-Application-Id", objConfig.appid)
	Job.GetRequest.SetHeader("X-Parse-Master-Key", objConfig.masterkey)
	Wait For (Job) JobDone(j As HttpJob)
	Log("B4XProductionPage.sendBack4AppRequest: " & j.Success)
	If j.Success Then
		Log(j.GetString)
		Try
			Dim jparser As JSONParser
			jparser.Initialize(j.GetString)
			Dim map1 As Map = jparser.Nextobject
			lstOfProduct = map1.Get("results")
			isSuccess = True
		Catch
			Log(LastException)
			isSuccess = False
		End Try
	Else
		isSuccess = False
	End If
	j.Release
	Return isSuccess
End Sub
' this function to show the json string responsed from Back4App
Sub lstToJsonString(i_lst As List) As String 'ignore
	If i_lst.IsInitialized = False Then 
		Return "[]"
	End If
	Dim jGen As JSONGenerator
	Try
		jGen.Initialize2(i_lst)
		Return jGen.ToPrettyString(4)
	Catch
		Log(LastException)
		Return "[]"
	End Try
End Sub