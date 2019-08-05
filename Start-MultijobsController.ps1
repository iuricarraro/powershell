<#
.Synopsis
    Controla multiplos jobs em Powershell de forma concorrente conforme parâmentros

.DESCRIPTION
   Controla multiplas instâncias de jobs Powershell de forma concorrente

   O módulo recebe o script que será executa multiplas vezes em concorrência para
   consumir volumes de dados grandes com mais eficiência.

   O módulo controla as sessões de Powershell e a massa de dados que deve ser
   processada.

.NOTES

#>
param(
    # Input de dados para o script
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path -Path $_ })]
    [ValidatePattern("\.ps1$")]
    [string] $Script,

    # Input de dados para o script
    [Parameter(Mandatory = $true)]
    [System.Object] $InputData,

    # Número máximo de processos concorrentes
    [Parameter(Mandatory = $false)]
    [int] $MaxParallelSessions = 10,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("server1", "server2", "server3")]
    [String] $ServerAPI,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [int] $PortAPI
)

try
{
    $measure = [Diagnostics.Stopwatch]::StartNew();
    $numTotalFiles = $InputData.Count;
    $arrJobs = @();
    $i = 0;

    foreach ($file in $InputData)
    {
        $arrJobs += Start-Job -ScriptBlock { $Script } -Name "Job_$($file.Name)";

        # controle de quantos novos jobs
        $arrJobsRunning = 0;
        do
        {
            $arrJobsRunning = (Get-Job -State Running);

            $timeElapsed = "{0:00}d {1:00}h {2:00}m {3:00}s" -f $measure.Elapsed.Days, $measure.Elapsed.Hours, $measure.Elapsed.Minutes, $measure.Elapsed.Seconds;
            $percent = (($i / $numTotalFiles) * 100);
            Write-Progress -Id 1 -Activity "Total files to process: $numTotalFiles | Elapsed [$timeElapsed]" -CurrentOperation ("Left {1} file(s) | {0:N2}% complete" -f $percent, ($numTotalFiles - $i)) -Status "$($arrJobsRunning.Count) jobs running" -PercentComplete $percent;

            $JobsStillRunning = $null;
            foreach ($jobRunning in $arrJobsRunning)
            {
                $JobsStillRunning += (" {0};" -f $jobRunning.Name);
            }

            if ($null -ne $jobsStillRunning)
            { Write-Progress -Id 2 -ParentId 1 -Activity 'jobs still running' -Status $jobsStillRunning; }

            Start-Sleep -Milliseconds 500; # tempo entre verificações de status dos jobs
        } While ($arrJobsRunning.Count -eq $MaxParallelSessions)
        Get-Job -State Completed | Receive-Job;
        Get-Job -State Completed | Remove-Job;
        $arrJobs = @();
    }

    # controle para os últimos jobs encerrarem
    # controle de quantos novos jobs
    $arrJobsRunning = 0;
    do
    {
        $arrJobsRunning = (Get-Job -State Running);

        $timeElapsed = "{0:00}d {1:00}h {2:00}m {3:00}s" -f $measure.Elapsed.Days, $measure.Elapsed.Hours, $measure.Elapsed.Minutes, $measure.Elapsed.Seconds;
        $percent = (($i / $numTotalFiles) * 100);
        Write-Progress -Id 1 -Activity "Total files to process: $numTotalFiles | Elapsed [$timeElapsed]" -CurrentOperation ("Left {1} file(s) | {0:N2}% complete" -f $percent, ($numTotalFiles - $i)) -Status "$($arrJobsRunning.Count) jobs running" -PercentComplete $percent;

        $JobsStillRunning = $null;
        foreach ($jobRunning in $arrJobsRunning)
        {
            $JobsStillRunning += (" {0};" -f $jobRunning.Name);
        }

        if ($null -ne $jobsStillRunning)
        { Write-Progress -Id 2 -ParentId 1 -Activity 'jobs still running' -Status $jobsStillRunning; }

        Start-Sleep -Milliseconds 500; # tempo entre verificações de status dos jobs
    } While ($arrJobsRunning.Count -eq $MaxParallelSessions)
    Get-Job -State Completed | Receive-Job;
    Get-Job -State Completed | Remove-Job;
    $arrJobs = @();

    # aguarda todos os jobs iniciados serem concluidos, faz o join das threads
    Get-Job | Wait-Job | Out-Null;
    Get-Job | Receive-Job;
    Get-Job | Remove-Job;

    $measure.Stop();
    ("Finished in {0:00}d {1:00}h {2:00}m {3:00}s" -f $measure.Elapsed.Days, $measure.Elapsed.Hours, $measure.Elapsed.Minutes, $measure.Elapsed.Seconds);
}
catch
{
    $_
}
