class Certificate {
    static [byte[]] ExportPfx([byte[]] $acmeCertificate, [System.Security.Cryptography.AsymmetricAlgorithm] $algorithm, [securestring] $password) {
        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($acmeCertificate);

        if($algorithm -is [System.Security.Cryptography.RSA]) {
            $certifiate = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::CopyWithPrivateKey($certificate, $algorithm);
        }
        elseif($algorithm -is [System.Security.Cryptography.ECDsa]) {
            $certifiate = [System.Security.Cryptography.X509Certificates.ECDsaCertificateExtensions]::CopyWithPrivateKey($certificate, $algorithm);
        }
        else {
            throw [System.InvalidOperationException]::new("Cannot use $($algorithm.GetType().Name) to export pfx.");
        }

        if($password) {
            return $certifiate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $password);
        } else {
            return $certifiate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx);
        }
    }

    static [byte[]] GenerateCsr([string[]] $dnsNames, [string]$distinguishedName,
        [System.Security.Cryptography.AsymmetricAlgorithm] $algorithm,
        [System.Security.Cryptography.HashAlgorithmName] $hashName)
    {
        if(-not $dnsNames) {
            throw [System.ArgumentException]::new("You need to provide at least one DNSName", "dnsNames");
        }
        if(-not $distinguishedName) {
            thtow [System.ArgumentException]::new("Provide a distinguishedName for the Certificate")
        }

        $sanBuilder = [System.Security.Cryptography.X509Certificates.SubjectAlternativeNameBuilder]::new();
        foreach ($dnsName in $dnsNames) {
            $sanBuilder.AddDnsName($dnsName);
        }

        $certDN = [X500DistinguishedName]::new($distinguishedName);

        [System.Security.Cryptography.X509Certificates.CertificateRequest]$certRequest = $null;

        if($algorithm -is [System.Security.Cryptography.RSA]) {
            $certRequest = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
                    $certDN, $algorithm, $hashName, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1);
        }
        elseif($algorithm -is [System.Security.Cryptography.ECDsa]) {
            $certRequest = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
                $certDN, $algorithm, $hashName);

        }
        else {
            throw [System.InvalidOperationException]::new("Cannot use $($algorithm.GetType().Name) to create CSR.");
        }

        $certRequest.CertificateExtensions.Add($sanBuilder.Build());
        return $certRequest.CreateSigningRequest();
    }
}
