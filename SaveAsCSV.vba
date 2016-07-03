' Does a directory exist?
Public Function DirExists(dir As String) As Boolean
  On Error Resume Next
  DirExists = (GetAttr(dir) And vbDirectory) = vbDirectory
  On Error GoTo 0
End Function

' Make a directory if it doesn't exist already
' TODO: Upgrade this so it creates an entire directory tree.
Public Sub MkDirIdempotent(dir As String)
  If Not (DirExists(dir)) Then MkDir dir
End Sub

' Suspend application interactivity to improve speed.
' Typically call this at the beginning of a subroutine.
Public Sub SubStart()
  Application.ScreenUpdating = False
  Application.EnableEvents = False
  Application.DisplayAlerts = False
  Application.Calculation = xlCalculationManual
End Sub

' Resume application interactivity as usual.
' Typically call this at the end of a subroutine.
Public Sub SubStop()
  Application.ScreenUpdating = True
  Application.DisplayAlerts = True
  Application.EnableEvents = True
  Application.Calculation = xlCalculationAutomatic
End Sub

' Save each worksheet as a CSV file.
' This iterates on each worksheet.
Public Sub SaveAsCSV()
  SubStart
  On Error GoTo OnError

  ' Get the current workbook, which is the source of our data,
  ' and create a temporary workbook, which is the destination.
  Set Book = Application.ActiveWorkbook
  Set Book2 = Application.Workbooks.Add
  
  ' Note: some examples on the net have code that does `Sheet.Copy`.
  ' However, this does not work smoothly when the sheet contains
  ' calculations, macros, or other features incompatible with CSV.
  ' TODO: Diagnose why the Sheet.Copy code does not work smoothly.
  '
  Dim Sheet As Worksheet

  ' Where do you want to save the files?
  '
  ' Note: on macOS and Excel 2016, typical file paths do not work.
  '
  ' For example these macOS directories do not work:
  '
  '     OuputDirectory = "~/"
  '     OutputDirectory = "/tmp/"
  '     OutputDirectory = "/Users/alice/"
  '
  ' This is because of Apple permission restrictions,
  ' and Excel 2016 has permission issues during the save.
  ' For a details see http://www.rondebruin.nl/mac/mac034.htm
  '
  ' For example, we sometimes see this dialog box:
  '
  '     Grant File Access
  '     Additional permissions are required to access the following files.
  '     Microsoft Excel needs access to the folder named 'foo'.
  '     Select this folder to grant access.
  '
  ' To work around these permission issues, we use a specific Mac folder
  ' that is pre-approved by Apple that allows Excel to read and write:
  '
  '     /Users/alice/Library/Containers/com.microsoft.Excel/Data/
  '
  ' To get this directory in VBA:
  '
  '     Debug.Print Environ("HOME")
  '
  ' To see the output CSV files:
  '
  '     ls ~/Library/Containers/com.microsoft.Excel/Data/*.csv
  '
  Dim OutputSep As String: OutputSep = "/"
  Dim OutputExt As String: OutputExt = ".csv"
  Dim OutputDirectory As String
  Dim OutputFileName As String
  
  ' Initialize the output directory
  OutputDirectory = Environ("HOME") & OutputSep & Replace(Book.Name, ".xlsx", "")
  MkDirIdempotent OutputDirectory

  ' Iterate on each sheet, and save it to a CSV file.
  For Each Sheet In Book.Worksheets
    ' Copy
    Dim R As String: R = "A1:Z99"
    Sheet.Range(R).Copy
    Book2.Sheets(1).Range(R).PasteSpecial xlPasteValues
    ' Save
    OutputFileName = OutputDirectory & OutputSep & Sheet.Name & OutputExt
    Book2.SaveAs Filename:=OutputFileName, FileFormat:=xlCSV, CreateBackup:=False
  Next
  Book2.Close False

Finally:
  SubStop
  Exit Sub

OnError:
  MsgBox "Couldn't save all sheets to CSV." & vbCrLf & _
         "Source: " & Err.Source & " " & vbCrLf & _
         "Number: " & Err.Number & " " & vbCrLf & _
         "Description: " & Err.Description & " " & vbCrLf
  GoTo Finally

End Sub
