B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.8
@EndOfDesignText@
Sub Class_Globals
	Private m_objectid As String	
	Private m_objProduct As clsProduct	
	Private m_weightInGram As Double
	Private m_sellingprice As Double
	Private m_barcode As String
	' m_packingDt is String(in back4app) for display
	Private m_packingDt As String
	' m_packedAt is Date(in back4app) for filtering.
	' m_packedAt would be 8 hours earlier than m_packingDt due to timezone	
	Private m_packedAt As String ' yyyy-MM-ddTHH:mm:ssZ
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize
	
End Sub
' this function serialize the object
Public Sub mySerialize() As String
	If m_objProduct.IsInitialized = False Then
		Return "{}"
	End If	
	Dim m As Map : m.initialize
	m.Put("objectid", m_objectid)
	m.Put("itemnum", m_objProduct.itemnum)
	m.Put("itemname", m_objProduct.Itemname)
	m.Put("itemname2", m_objProduct.Itemname2)
	m.Put("itemuom", m_objProduct.itemuom)
	m.Put("itemuom2", m_objProduct.itemuom2)
	m.Put("itemstandardweight", m_objProduct.Itemstandardweight)	
	m.Put("itemprice", m_objProduct.ItemPrice)
	m.Put("weightingram", m_weightInGram)
	m.Put("sellingprice", m_sellingprice)
	m.Put("barcode", m_barcode)
	m.Put("packingdt", m_packingDt)
	m.Put("packedAt", m_packedAt)
	Dim jGen As JSONGenerator
	Try
		jGen.Initialize(m)
		Return jGen.ToString
	Catch
		Log(LastException)
		Return "{}"
	End Try
End Sub

' this function parse json string and assign values
Public Sub myDeserialize(jstr As String) As Boolean
	If jstr = "" Then
		Return False
	End If
	Dim jParser As JSONParser
	Try
		jParser.Initialize(jstr)
		Dim m As Map = jParser.NextObject
		If m.ContainsKey("objectid") Then
			m_objectid = m.Get("objectid")
		End If
		m_objProduct.Initialize		
		If m.ContainsKey("itemnum") Then
			m_objProduct.itemnum = m.Get("itemnum")
		End If		
		If m.ContainsKey("itemname") Then
			m_objProduct.itemname = m.Get("itemname")
		End If		
		If m.ContainsKey("itemname2") Then
			m_objProduct.itemname2 = m.Get("itemname2")
		End If		
		If m.ContainsKey("itemuom") Then
			m_objProduct.itemuom = m.Get("itemuom")
		End If
		If m.ContainsKey("itemuom2") Then
			m_objProduct.itemuom2 = m.Get("itemuom2")
		End If
		If m.ContainsKey("itemstandardweight") Then
			m_objProduct.itemstandardweight = m.Get("itemstandardweight")
		End If
		If m.ContainsKey("itemprice") Then
			m_objProduct.itemprice = m.Get("itemprice")
		End If
		If m.ContainsKey("weightingram") Then
			m_weightInGram = m.Get("weightingram")
		End If
		If m.ContainsKey("sellingprice") Then
			m_sellingprice = m.Get("sellingprice")
		End If
		If m.ContainsKey("barcode") Then
			m_barcode = m.Get("barcode")
		End If
		If m.ContainsKey("packingdt") Then
			m_packingDt = m.Get("packingdt")
		End If
		If m.ContainsKey("packedAt") Then
			m_packedAt = m.Get("packedAt")
		End If
		Return True
	Catch
		Log(LastException)
		Return True
	End Try
End Sub
' this function is used "eat" the map from back4app and "digest" its key-pair value 
Public Sub myDeserializeByMap(i_map As Map) As Boolean
	If i_map.IsInitialized = False Then
		Return False
	End If
	m_objProduct.Initialize
	If i_map.ContainsKey("objectId") Then m_objectid = i_map.Get("objectId")
	If i_map.ContainsKey("itemnum") Then m_objProduct.Itemnum = i_map.Get("itemnum")
	If i_map.ContainsKey("itemname") Then m_objProduct.Itemname = i_map.Get("itemname")
	If i_map.ContainsKey("itemname2") Then m_objProduct.Itemname2 = i_map.Get("itemname2")
	If i_map.ContainsKey("itemuom") Then m_objProduct.Itemuom = i_map.Get("itemuom")
	If i_map.ContainsKey("itemuom2") Then m_objProduct.Itemuom2 = i_map.Get("itemuom2")
	If i_map.ContainsKey("itemstandardweight") Then m_objProduct.Itemstandardweight = i_map.Get("itemstandardweight")
	If i_map.ContainsKey("itemprice") Then m_objProduct.ItemPrice = i_map.Get("itemprice")
	If i_map.ContainsKey("weightingram") Then m_weightInGram = i_map.Get("weightingram")
	If i_map.ContainsKey("sellingprice") Then m_sellingprice = i_map.Get("sellingprice")
	If i_map.ContainsKey("barcode") Then m_barcode = i_map.Get("barcode")
	If i_map.ContainsKey("packingdt") Then m_packingDt = i_map.Get("packingdt")
	If i_map.ContainsKey("packedAt") Then m_packedAt = i_map.Get("packedAt")
	Return True
End Sub

' this function is used to encapsulate this object for posting the record to cloud database
Public Sub getJsonStringForPost() As String
	Dim mapTmp As Map = mySerializeAsMap
	Dim jGen As JSONGenerator
	Try
		jGen.Initialize(mapTmp)
		Return jGen.ToString
	Catch
		Log(LastException)
		Return "{}"
	End Try
End Sub
' this function is used to serialize this object as map for post propose
Private Sub mySerializeAsMap() As Map
	If m_objProduct.IsInitialized = False Then
		' return empty map
		Return CreateMap()
	End If
	Dim innermap As Map = CreateMap("__type": "Date", "iso": m_packedAt)
	Dim map1 As Map : map1.Initialize
	map1.Put("itemnum", m_objProduct.itemnum)
	map1.Put("itemname", m_objProduct.itemname)
	map1.Put("itemname2", m_objProduct.itemname2)
	map1.Put("itemuom", m_objProduct.itemuom)
	map1.Put("itemuom2", m_objProduct.itemuom2)
	map1.Put("itemstandardweight", m_objProduct.itemstandardweight)
	map1.Put("itemprice", m_objProduct.itemprice)
	map1.Put("weightingram", m_weightInGram)		
	map1.Put("sellingprice", m_sellingprice)
	map1.Put("barcode", m_barcode)
	map1.Put("packingdt", m_packingDt)
	map1.Put("packedAt", innermap)
	Return map1
End Sub
' this function 'eat' Product object and assign its attributes
Public Sub myDeserializeByObject(obj As clsProduct) As Boolean
	If obj.IsInitialized = False Then
		Return False
	End If	
	m_objProduct.Initialize	
	m_objProduct.Itemnum = obj.Itemnum
	m_objProduct.Itemname = obj.Itemname
	m_objProduct.Itemname2 = obj.Itemname2
	m_objProduct.Itemuom = obj.Itemuom
	m_objProduct.Itemuom2 = obj.Itemuom2
	m_objProduct.Itemstandardweight = obj.Itemstandardweight
	m_objProduct.ItemPrice = obj.ItemPrice
	Return True
End Sub

' Change map of finished product from production record to string
Public Sub mapToString(i_map As Map) As String
	
	If i_map.IsInitialized = False Then
		Return ""
	End If
'	{
'		"objectId": "n0yBVvsvNx",
'		"itemnum": "120016",
'		"itemname": "Japan Wagyu Dice",
'		"itemname2": "日本和牛粒",
'		"itemuom": "100g",
'		"itemuom2": 100,
'		"itemstandardweight": 200,
'		"itemprice": 38,
'		"weightingram": 102.2,
'		"sellingprice": 38.8,
'		"barcode": "012001600388010224",
'		"packingdt": "21/11/2022 07:55:24 GMT+08:00",
'		"packedAt": "2022-11-20T23:55:24.000Z", 
'		"createdAt": "2022-11-20T23:55:24.506Z",
'		"updatedAt": "2022-11-20T23:55:24.506Z"
'	}
	Dim objSb As StringBuilder
	objSb.Initialize
	If i_map.ContainsKey("objectId") Then objSb.Append("Object Id: ").Append(i_map.Get("objectId")).Append(CRLF)
	If i_map.ContainsKey("itemnum") Then objSb.Append("Item No: ").Append(i_map.Get("itemnum")).Append(CRLF)
	If i_map.ContainsKey("itemname") Then objSb.Append("Item Name: ").Append(i_map.Get("itemname")).Append(CRLF)
	If i_map.ContainsKey("itemname2") Then objSb.Append("Item Name2: ").Append(i_map.Get("itemname2")).Append(CRLF)
	If i_map.ContainsKey("itemuom") Then objSb.Append("Item Unit: ").Append(i_map.Get("itemuom")).Append(CRLF)
	If i_map.ContainsKey("itemstandardweight") Then objSb.Append("Std Weight: ").Append(i_map.Get("itemstandardweight")).Append("g").Append(CRLF)
	If i_map.ContainsKey("itemprice") Then objSb.Append("Price per ").Append("itemnum").Append(": $").Append(i_map.Get("itemprice")).Append(CRLF)
	If i_map.ContainsKey("weightingram") Then objSb.Append("Weight: ").Append(i_map.Get("weightingram")).Append("g").Append(CRLF)
	If i_map.ContainsKey("sellingprice") Then objSb.Append("Selling Price: $").Append(i_map.Get("sellingprice")).Append(CRLF)
	If i_map.ContainsKey("barcode") Then objSb.Append("Barcode: ").Append(i_map.Get("barcode")).Append(CRLF)
	If i_map.ContainsKey("packingdt") Then objSb.Append("Packing Date: ").Append(i_map.Get("packingdt").As(String).SubString2(0, 19))
	Return objSb.ToString
End Sub

#Region Getter

Public Sub getProduct() As clsProduct
	Return m_objProduct
End Sub

Public Sub getObjectId() As String
	Return m_objectid
End Sub

Public Sub getItemnum() As String
	If m_objProduct.IsInitialized = False Then
		Return ""
	End If
	Return m_objProduct.itemnum
End Sub

Public Sub getItemuom() As String
	If m_objProduct.IsInitialized = False Then
		Return ""
	End If
	Return m_objProduct.itemuom
End Sub

Public Sub getItemuom2() As Double
	If m_objProduct.IsInitialized = False Then
		Return ""
	End If
	Return m_objProduct.itemuom2
End Sub

Public Sub getWeightInGram() As Double
	Return m_weightInGram
End Sub

Public Sub getItemPrice() As Double
	If m_objProduct.IsInitialized = False Then
		Return ""
	End If
	Return m_objProduct.itemprice
End Sub

Public Sub getSellingPrice() As Double
	Return m_sellingprice
End Sub

Public Sub getBarcode() As String
	Return m_barcode
End Sub

Public Sub getPackingDt() As String
	Return m_packingDt
End Sub

Public Sub getPackedAt() As String
	Return m_packedAt
End Sub

#End Region
Public Sub setItemnum(value As String)
	If m_objProduct.IsInitialized = False Then
		m_objProduct.Initialize
	End If
	m_objProduct.itemnum = value
End Sub

Public Sub setItemuom(value As String)
	If m_objProduct.IsInitialized = False Then
		m_objProduct.Initialize
	End If
	m_objProduct.itemuom = value
End Sub

Public Sub setItemuom2(value As Double)
	If m_objProduct.IsInitialized = False Then
		m_objProduct.Initialize
	End If
	m_objProduct.itemuom2 = value
End Sub

Public Sub setWeightInGram(value As Double)
	m_weightInGram = value
End Sub

Public Sub setItemPrice(value As Double)
	If m_objProduct.IsInitialized = False Then
		m_objProduct.Initialize
	End If
	m_objProduct.itemprice = value
End Sub

Public Sub setSellingPrice(value As Double)
	m_sellingprice = value
End Sub

Public Sub setBarcode(value As String)
	m_barcode = value
End Sub

Public Sub setPackingDt(value As String)
	m_packingDt = value
End Sub

Public Sub setPackedAt(value As String)
	m_packedAt = value
End Sub