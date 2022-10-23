B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.2
@EndOfDesignText@
Sub Class_Globals
	Private m_itemnum As String
	' English name of item
	Private m_itemname As String
	' Chinese name of item
	Private m_itemname2 As String
	Private m_itemuom As String
	Private m_itemstandardweight As Int
	Private m_itemprice As Double
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	
End Sub

Public Sub getItemnum() As String
	Return m_itemname
End Sub

Public Sub getItemname() As String
	Return m_itemname
End Sub

Public Sub getItemname2() As String
	Return m_itemname2
End Sub

Public Sub getItemuom() As String
	Return m_itemuom
End Sub

Public Sub getItemstandardweight As Int
	Return m_itemstandardweight
End Sub

Public Sub getItemPrice() As Double
	Return m_itemprice
End Sub

Public Sub getItemPriceX10() As Int
	Dim ret As Int = Round2(m_itemprice, 1) * 10
	Return ret 
End Sub

Public Sub getProductBarcode(weight As Double) As String
	Dim weightx10 As Int = Round2(weight, 1) * 10
	Dim weightPart As String = zeroLeading(weightx10)
	Dim packPrice As Double = (weight * m_itemprice) / m_itemuom
	Dim packPricex10 As Int = Round2(packPrice, 1) * 10
	Dim packPricePart As String = zeroLeading(packPricex10)
	Return calcOddParity("0" & m_itemnum & packPricePart & weightPart)
End Sub

Private Sub zeroLeading(txt As String) As String
	If txt.Length > 5 Then
		Return txt.SubString2(0, 5)
	End If
	Select Case txt.Length
		Case 0
			Return "00000"
		Case 1
			Return "0000" & txt
		Case 2
			Return "000" & txt
		Case 3
			Return "00" & txt
		Case 4
			Return "0" & txt
		Case 5
			Return txt
		Case Else
			Return "00000"
	End Select
End Sub
' This function calculate the checksum by Odd Parity method
' Return the whole barcode with check digit
Private Sub calcOddParity(txt As String) As String
	If IsNumber(txt) = False Then
		Return "000000000000000000"
	End If
	Dim sum As Int = 0
	Dim checksum As Int = 0
	Dim i As Int 
	For i = 0 To txt.Length -1
		If (i Mod 2 = 0) Then
			Dim digit_1a As String = txt.CharAt(i)
			' Type conversion
			Dim digit_1b As Int = digit_1a
			sum = sum + digit_1b
		Else
			Dim digit_2a As String = txt.CharAt(i)
			' Type conversion
			Dim digit_2b As Int = digit_2a
			sum = sum + digit_2b * 3
		End If		
	Next
	If (sum Mod 10 > 0) Then
		checksum = 10 - (sum Mod 10)
	Else
		checksum = 0
	End If
	Return txt & checksum
End Sub