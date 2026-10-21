$ErrorActionPreference = 'Stop'
$src='C:\Users\20594\Downloads\tupian'
$out=(Join-Path $PSScriptRoot '..\Art\Artifacts')
New-Item -ItemType Directory -Force -Path $out | Out-Null
Add-Type -AssemblyName System.Drawing
$names=Get-ChildItem -LiteralPath $src -Filter *.png
foreach($file in $names){
  $name=$file.BaseName
  $input=[System.Drawing.Image]::FromFile($file.FullName)
  $side=[Math]::Min($input.Width,$input.Height); $x=[int](($input.Width-$side)/2); $y=[int](($input.Height-$side)/2)
  $square=New-Object System.Drawing.Bitmap($side,$side,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g=[System.Drawing.Graphics]::FromImage($square); $g.DrawImage($input,(New-Object System.Drawing.Rectangle(0,0,$side,$side)),(New-Object System.Drawing.Rectangle($x,$y,$side,$side)),[System.Drawing.GraphicsUnit]::Pixel); $g.Dispose(); $input.Dispose()
  foreach($size in @(256,64,45)){
    $scaled=New-Object System.Drawing.Bitmap($size,$size,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb); $gs=[System.Drawing.Graphics]::FromImage($scaled); $gs.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic; $gs.DrawImage($square,0,0,$size,$size); $gs.Dispose(); $png=Join-Path $out ($name+'_'+$size+'.png'); $scaled.Save($png,[System.Drawing.Imaging.ImageFormat]::Png); $scaled.Dispose()
  }
  $square.Dispose()
}
Write-Host "generated png files:" (Get-ChildItem $out -Filter *.png).Count
$tex=(Join-Path $PSScriptRoot '..\..\_tools\CivNexus6-master\bin\Release\texconv.exe')
foreach($png in Get-ChildItem $out -Filter *.png){ & $tex -y -f BC3_UNORM -o $out $png.FullName; if($LASTEXITCODE -eq 0){ Remove-Item -LiteralPath $png.FullName } }
