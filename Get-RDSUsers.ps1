function Global:Get-RDSUsers {
<#
.NOTES
    Author: Robert D. Biddle (email: robertdbiddle+powershell@gmail.com )
.DESCRIPTION
    PowerShell function to determine the current number of active Windows Remote Desktop (i.e. RDP / RDS) sessions on a server
.EXAMPLE 
    Get-RDSUsers 
        - This will output information about all local Remote Desktop Session
    
    Get-RDSUsers -ComputerName abc.xyz.com -Credential (Get-Credential)
        - This will output information about all Remote Desktop Sessions on computer abc.xyz.com and explicitly prompt for Credentials
    
    Get-RDSUsers -ComputerName abc.xyz.com -Credential $cred
        - This will output information about all Remote Desktop Sessions on computer abc.xyz.com using a PSCredential object saved as variable $cred

    Get-RDSUsers -ComputerName abc.xyz.com -Credential $cred -ActiveUsersOnly
        - This will output information about Active (i.e. disconnected sessions are not included in output) Remote Desktop Sessions on computer abc.xyz.com using a PSCredential object saved as variable $cred
#>
    [CmdletBinding(DefaultParameterSetName="localhost")]
    Param(
        [parameter(ParameterSetName="remote",Mandatory=$False,Position=0,ValueFromPipeline=$True)]
        [string[]]$ComputerName,

        [parameter(ParameterSetName="remote",Mandatory=$False,Position=1)]
        [PSCredential]
        $Credential,

        [parameter(Mandatory=$False)]
        [switch]$ActiveUsersOnly
        )
    Begin {}
    Process 
    {       
        switch ($psCmdlet.ParameterSetName)
        {
        "localhost"
            {
	            $RdsUsers = qwinsta | foreach { ($_.trim() -replace "\s+" , ",") } | ConvertFrom-Csv
	            if($ActiveUsersOnly)
                {
                    $ActiveRdsUsers = ($RdsUsers | Where-Object State -like Active)
	                $ActiveRdsUsers
                }Else
                {
                    $RdsUsers
                }               
            }
        "remote"
            {
                foreach($c in $ComputerName)
                # Foreach block is not necessary for pipeline input because the Process block does this implicitly,
                # however it is still neeeded to support passing an array directly into the -ComputerName parameter.
                {
	                $ScriptBlock = {qwinsta | foreach { ($_.trim() -replace "\s+" , ",") } | ConvertFrom-Csv}
                    $PSSession = New-PSSession -ComputerName $c -Credential $Credential
                    $RdsUsers = (Invoke-Command -Session $PSSession -ScriptBlock $ScriptBlock)	                
                    if($ActiveUsersOnly)
                    {
                        $ActiveRdsUsers = ($RdsUsers | Where-Object State -like Active)
	                    $ActiveRdsUsers
                    }Else
                    {
                        $RdsUsers
                    }      
                    Remove-PSSession $PSSession
                }
            }
        }
    }
    End{}
}
