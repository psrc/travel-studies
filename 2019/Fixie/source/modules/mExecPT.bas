Option Compare Database
Option Explicit

     Public Sub ExecutePassThrough(lngParam As Long)
       Dim strTSQL As String
       Dim strQueryName As String

       strQueryName = "qsptDeleteRecord"
       strTSQL = "EXECUTE delete_record" & lngParam

       Call BuildPassThrough(strQueryName, strTSQL)

       DoCmd.OpenQuery strQueryName
     End Sub


     Public Sub BuildPassThrough( _
       ByVal strQName As String, _
       ByVal strSQL As String)

       Dim cat As ADOX.Catalog
       Dim cmd As ADODB.Command

       Set cat = New ADOX.Catalog
       Set cat.ActiveConnection = CurrentProject.Connection

       Set cmd = cat.Procedures(strQName).Command

       ' Verify query is a pass-through query
       cmd.Properties( _
          "Jet OLEDB:ODBC Pass-Through Statement") = True

       cmd.CommandText = strSQL

       Set cat.Procedures(strQName).Command = cmd

       Set cmd = Nothing
       Set cat = Nothing

     End Sub