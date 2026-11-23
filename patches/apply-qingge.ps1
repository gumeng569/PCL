# 新清歌版PCL 构建补丁
# 1) 顶部导航加入「新清歌版PCL」按钮
# 2) 点击按钮打开当前 Minecraft 文件夹下的整合包 versions 目录
$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$XamlPath = Join-Path $RepoRoot 'Plain Craft Launcher 2\FormMain.xaml'
$VbPath = Join-Path $RepoRoot 'Plain Craft Launcher 2\FormMain.xaml.vb'
$Utf8Bom = New-Object System.Text.UTF8Encoding($true)

function Get-NewLine([string]$text) {
    if ($text.Contains("`r`n")) { return "`r`n" } else { return "`n" }
}

# ---------- 1. XAML：顶部导航新增按钮 ----------
$doc = [System.IO.File]::ReadAllText($XamlPath, [System.Text.Encoding]::UTF8)
if ($doc -notmatch 'BtnNewQinggePCL') {
    $anchorIndex = $doc.IndexOf('x:Name="BtnTitleSelect4"')
    if ($anchorIndex -lt 0) { throw '未找到顶部导航「更多」按钮的定位锚点。' }
    $stackEnd = $doc.IndexOf('</StackPanel>', $anchorIndex)
    if ($stackEnd -lt 0) { throw '未找到顶部导航容器的结束标签。' }
    $nl = Get-NewLine $doc
    $lineStart = $doc.LastIndexOf("`n", $stackEnd) + 1
    $indent = $doc.Substring($lineStart, $stackEnd - $lineStart)
    $button = $indent + '    <local:MyButton x:Name="BtnNewQinggePCL" Text="新清歌版PCL" Height="27" MinWidth="98" Margin="14,0,2,0" VerticalAlignment="Center" Padding="9,0" />' + $nl
    $doc = $doc.Substring(0, $lineStart) + $button + $doc.Substring($lineStart)
    [System.IO.File]::WriteAllText($XamlPath, $doc, $Utf8Bom)
    Write-Host '已写入顶部导航按钮。'
}

# ---------- 2. VB：按钮点击后打开 versions 文件夹 ----------
$code = [System.IO.File]::ReadAllText($VbPath, [System.Text.Encoding]::UTF8)
if ($code -notmatch 'BtnNewQinggePCL_Click') {
    $nl = Get-NewLine $code
    $method = @'
    ''' <summary>
    ''' 「新清歌版PCL」：打开当前 Minecraft 文件夹下的整合包 versions 目录。
    ''' </summary>
    Private Sub BtnNewQinggePCL_Click() Handles BtnNewQinggePCL.Click
        Try
            Dim McPath As String = If(McFolderSelected, "").Trim()
            If McPath = "" OrElse Not DirectoryUtils.Exists(McPath) Then
                Hint("还没有选择 Minecraft 文件夹，请先在启动页设置文件夹后再使用整合包目录。", HintType.Red)
                Return
            End If
            Dim VersionFolder As String = PathUtils.AddSlashSuffix(Path.Combine(McPath, "versions"))
            If Not DirectoryUtils.Exists(VersionFolder) Then Directory.CreateDirectory(VersionFolder)
            OpenExplorer(VersionFolder)
            Hint("已打开整合包 versions 文件夹")
        Catch ex As Exception
            Logger.Error(ex, "打开整合包 versions 文件夹失败")
        End Try
    End Sub
'@
    $endIndex = $code.LastIndexOf('End Class')
    if ($endIndex -lt 0) { throw '未找到类结束标记。' }
    $methodText = $method.Replace("`r`n", $nl).Replace("`n", $nl)
    $code = $code.Substring(0, $endIndex) + $methodText + $nl + 'End Class' + $code.Substring($endIndex + 'End Class'.Length)
    [System.IO.File]::WriteAllText($VbPath, $code, $Utf8Bom)
    Write-Host '已写入按钮处理逻辑。'
}
