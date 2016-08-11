Function Initialize-Call {
    <#
        .SYNOPSIS
        The Initialize-Call function is used to initialize a call between two parties on Asterisk PBX.
        .DESCRIPTION
        Initialize-Call will initiate a call from a local extension to either another local extension or an outside number. It can also be used to call multiple
        parties from the same source extension. 
        
        .PARAMETER ami_ip 
        The IP address of your Asterisk PBX.
        .PARAMETER ami_port
        The Port used to connect to the AMI on your Asterisk PBX. Defaults to 5038.
        .PARAMETER ami_user
        The username to authenticate with the AMI.
        .PARAMETER ami_pass
        The password to authenticate with the AMI.
        .PARAMETER src_ext
        The local extension you wish to initiate a call from.
        .PARAMETER context
        The context to reference when dialing. Defaults to 'from-internal'.
        .PARAMETER dst_Ext
        The extenision you wish to call. Can be a local or external number.
        .PARAMETER caller_id
        The outbound caller id you wish to present. Some carriers require a specific outbound caller id in order to process calls.        
        .EXAMPLE
        Initialize-Call -ami_ip 192.168.1.1 -ami_user admin -ami_pass admin -src_ext 100 -dst_ext 200

        This is the most basic example. It will initiate a call from local extension '100' to local extension '200'.
        .EXAMPLE
        Initialize-Call -ami_ip 192.168.1.1 -ami_user admin -ami_pass admin -src_ext 100 -dst_ext 18005555555 -caller_id 18005551234

        This will will initiate a call from local extenision '100' to the number '1(800) 555-5555, using an outbound caller id of '1(800) 555-1234'. 
        .NOTES 

        .LINK
        https://github.com/areynolds77/AMI_Scripts
    #>
    [CmdletBinding(
        DefaultParameterSetName = 'None'
    )]
    # Parameter help description
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true,
            HelpMessage = "IP address of the Asterisk PBX you wish to target. FQDNs or hostnames are not supported."
        )]
        [ValidateScript({$_ -match [IPAddress]$_})]
        [string]$ami_ip,
        [Parameter(
            Position = 1,
            HelpMessage = "Port the Asterisk Management Interface is utilizing. Defaults to '5038'"
        )]
        [string]$ami_port = 5038,
        [Parameter(
            Position = 2,
            Mandatory = $true,
            HelpMessage = "Username to connect to the AMI."
        )]
        [string]$ami_user,
        [Parameter(
            Position = 3,
            Mandatory = $true,
            HelpMessage = "Password to connect to the AMI"
        )]
        [string]$ami_pass,
        [Parameter(
            Position = 4,
            Mandatory = $true,
            HelpMessage = "The extension you wish to initiate a call from."
        )]
        [string]$src_ext,
        [Parameter(
            Position = 5,
            Mandatory = $true,
            HelpMessage = "The context for the destination extension. Defaults to from-internal"
        )]
        [string]$context = "from-internal",
        [Parameter(
            Position = 6,
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "The extenision you wish to call."
        )]
        [string]$dst_ext,
        [Parameter(
            Position = 7,
            HelpMessage = "The outbound caller ID you wish to use."
        )]
        [string]$caller_id
    )
    Begin {
        $FunctionTime = [System.Diagnostics.Stopwatch]::StartNew()
        #region Misc. settings + parameter cleanup
            #Set debug preference
            if ($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent) {
                $DebugPreference = "Continue"
                Write-Debug -Message "Debug output active"
            } else {
                $DebugPreference = "SilentlyContinue"
            }

        #endregion
        #region Debug Input Values
            Write-Debug -Message "Provided Input values:"
            Write-Debug -Message "Provided Asterisk IP Address: $ami_ip"
            Write-Debug -Message "AMI Port: $ami_port"
        #endregion
        #region Define Actions
            $Act_Login = "ACTION: login`r`nusername: $ami_user`r`nsecret: $ami_pass`r`n"
            $Act_Logoff = "ACTION: Logoff`r`n"
        #endregion
        #region Create Socket & Connect to AMI
            $Socket = New-Object System.Net.Sockets.TcpClient($ami_ip, $ami_port)
            If ($Socket) {
                $Stream = $Socket.GetStream()
                $Writer = New-Object System.IO.StreamWriter($Stream)
                $Buffer = New-Object System.Byte[] 1024 
                $Encoding = New-Object System.Text.AsciiEncoding
                #Login
                $Writer.WriteLine($Act_Login) 
                $Writer.Flush()
                Start-Sleep -Seconds 2
            } Else {
                Write-Error "Unable to connect to host: $ami_ip`:$ami_port"
                Break
            }
        #endregion
    }
    Process {
        $Act_Call = "Action: Originate`r`nChannel: sip/$src_ext`r`nContext: $context`r`nExten: $dst_ext`r`nPriority: 1`r`nCallerid: $caller_id`r`n"
        $Writer.Flush()
        Start-Sleep -Seconds 2
        Write-Debug -Message "Calling from: $src_ext using context: $context to $dst_ext as $caller_id."
        $Act_Call | Write-Debug
        $Writer.WriteLine($Act_Call)
        $Writer.Flush()
        Start-Sleep -Seconds 2
    }
    End {
        #Logoff
        $Writer.WriteLine($Act_Logoff)
        $Writer.Flush()
        Start-Sleep -Seconds 2
        #Output Data
        $Output = ""
        While ($Stream.DataAvailable) {
            $Read = $Stream.Read($Buffer, 0 ,1024)
            $Output += ($Encoding.GetString($Buffer, 0, $Read))
        }
        "Call initiated in " + $FunctionTime.elapsed | Write-Debug
        $Output
    }
}
