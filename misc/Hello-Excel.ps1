function Hello-Excel {
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $true
        $workbook = $excel.Workbooks.Add()
        $worksheet = $workbook.Worksheets.Item(1)
        $worksheet.Cells.Item(1,1).Value = "Hello Excel!"
    } catch {
        throw $_
    }
}

Hello-Excel
