<#
.SYNOPSIS
    Replace de strings em multiplos arquivos

.DESCRIPTION
    Replace de strings em multiplos arquivos

.EXAMPLE
    ReplaceTextIn-File.ps1 -Path e:\temp\arquivo*.xml -Find 'item' -Replace 'itens' -Overwrite -Recurse -Verbose

.INPUTS
    Inputs (if any)

.OUTPUTS
    Output (if any)

.NOTES
    General notes
#>

[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path -Path $_ })]
    [String] $Path,

    # string a ser subtituida
    [Parameter(Mandatory = $true)]
    [String] $Find,

    # string subtituta
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [String] $Replace,

    # sobreescreve o arquivo de saida
    [switch] $Overwrite,

    # pesquisa recursiva
    [Switch] $Recurse
)

# contador de ocorrencias do replace
$countNeedleFinded = 0;

Get-ChildItem -Path $Path -Recurse:$Recurse -File | ForEach-Object {
    $count = (Select-String -Path $_.FullName -Pattern $Find -AllMatches).Matches.Count;

    if ($VerbosePreference -eq "Continue")
    { "$($_.Name): $count ocorrência(s)"; }

    if ($count -gt 0)
    {
        # replace case sensitive
        (Get-Content -LiteralPath $_.FullName | ForEach-Object { $_ -creplace $Find, $Replace; }) | Set-Content -Path "$($_.FullName).temp";

        $FileOut = $_.FullName + @{ $true = '.true'; $false = '.replaced' }[$Overwrite.IsPresent];
        Move-Item -Path "$($_.FullName).temp" -Destination $FileOut -Force -ErrorAction Stop;
    }
    $countNeedleFinded += $count;
}

"-----------------";
"Total de $countNeedleFinded ocorrência(s)";
