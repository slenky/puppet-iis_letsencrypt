function Check-StoredPfx {
param (
[String]$CertRootStore = "LocalMachine",
[String]$CertStore = "My",
[String]$Thumbprint = $null,
[String]$CertSubject
)
    $store = new-object System.Security.Cryptography.X509Certificates.X509Store($CertStore,$CertRootStore)
    $store.open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
    if (($CertSubject -ne $null) -and ($CertSubject -ne "")) {
        $cert = ($store.Certificates | ? {$_.subject -match $CertSubject})
        }
    else {
        $cert = $store.Certificates
        }
    $store.Close()
    return $cert
    }
$csv2 = Check-StoredPfx -CertStore "My" |
 foreach {
   new-object psobject -Property @{ Domain = ($_.Subject.Replace("CN=","") + " " + $_.Thumbprint); }}
$csv2 | fl
