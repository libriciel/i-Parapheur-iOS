/*
 * Copyright 2012-2017, Libriciel SCOP.
 *
 * contact@libriciel.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documents on an authorized iParapheur.
 *
 * This software is governed by the CeCILL license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL license and that you accept its terms.
 */

import XCTest
@testable import iParapheur


class Utils_CryptoUtils_Tests: XCTestCase {


    func testCleanupPublicKey() {

        let pollutedCertificate = """
          Plop -----BEGIN CERTIFICATE-----
          MIIEvDCCA6SgAwIBAgIJAMXb2wwwEe7bMA0GCSqGSIb3DQEBBQUAMIGYMQswCQYD
          VQQGEwJGUjEQMA4GA1UECBMHSGVyYXVsdDEYMBYGA1UEChMPQURVTExBQ1QtUHJv
          aI4sMpE2XfSFX2lfQgT4zJMqLYj21aUDFY5GC/6+y/Q0DvrTnG6Zga2YT+k+ADX2
          zQTAPlHkAUt5Kwtlp9xk7w==
          -----END CERTIFICATE----- Plop
          """

        let cleanCertificate = """
          MIIEvDCCA6SgAwIBAgIJAMXb2wwwEe7bMA0GCSqGSIb3DQEBBQUAMIGYMQswCQYD
          VQQGEwJGUjEQMA4GA1UECBMHSGVyYXVsdDEYMBYGA1UEChMPQURVTExBQ1QtUHJv
          aI4sMpE2XfSFX2lfQgT4zJMqLYj21aUDFY5GC/6+y/Q0DvrTnG6Zga2YT+k+ADX2
          zQTAPlHkAUt5Kwtlp9xk7w==
          """

        var expectedResult = "MIIEvDCCA6SgAwIBAgIJAMXb2wwwEe7bMA0GCSqGSIb3DQEBBQUAMIGYMQswCQYD"
        expectedResult = "\(expectedResult)VQQGEwJGUjEQMA4GA1UECBMHSGVyYXVsdDEYMBYGA1UEChMPQURVTExBQ1QtUHJv"
        expectedResult = "\(expectedResult)aI4sMpE2XfSFX2lfQgT4zJMqLYj21aUDFY5GC/6+y/Q0DvrTnG6Zga2YT+k+ADX2"
        expectedResult = "\(expectedResult)zQTAPlHkAUt5Kwtlp9xk7w=="

        let cleanedPollutedCertificate = CryptoUtils.cleanupPublicKey(publicKey: pollutedCertificate)
        let cleanedCleanCertificate = CryptoUtils.cleanupPublicKey(publicKey: cleanCertificate)

        XCTAssertEqual(cleanedPollutedCertificate, expectedResult)
        XCTAssertEqual(cleanedCleanCertificate, expectedResult)
    }


    func testCleanupSignature() {

        let pollutedSignature = """
          -----BEGIN PKCS7-----
          MIIHLwYJKoZIhvcNAQcCoIIHIDCCBxwCAQExCzAJBgUrDgMCGgUAMAsGCSqGSIb3
          usuukeNvUD3KDmLKdLAs3ws3aIBdaQXHfYyuK/8s/vM450Ug54ktLm5soyBCzfpT
          9YKwLwLgE5kUJ7lOeDsiNMq8LvwKrFl8k0bIsOUYoJWI5Lmi3E+pvRONMMxMtC3p
          OQcOGkY08B0p0deav2xZTgBxwA==
          -----END PKCS7-----
        """

        let cleanSignature = """
          MIIHLwYJKoZIhvcNAQcCoIIHIDCCBxwCAQExCzAJBgUrDgMCGgUAMAsGCSqGSIb3
          usuukeNvUD3KDmLKdLAs3ws3aIBdaQXHfYyuK/8s/vM450Ug54ktLm5soyBCzfpT
          9YKwLwLgE5kUJ7lOeDsiNMq8LvwKrFl8k0bIsOUYoJWI5Lmi3E+pvRONMMxMtC3p
          OQcOGkY08B0p0deav2xZTgBxwA==
          """

        var expectedResult = "MIIHLwYJKoZIhvcNAQcCoIIHIDCCBxwCAQExCzAJBgUrDgMCGgUAMAsGCSqGSIb3"
        expectedResult = "\(expectedResult)usuukeNvUD3KDmLKdLAs3ws3aIBdaQXHfYyuK/8s/vM450Ug54ktLm5soyBCzfpT"
        expectedResult = "\(expectedResult)9YKwLwLgE5kUJ7lOeDsiNMq8LvwKrFl8k0bIsOUYoJWI5Lmi3E+pvRONMMxMtC3p"
        expectedResult = "\(expectedResult)OQcOGkY08B0p0deav2xZTgBxwA=="

        let cleanedPollutedSignature = CryptoUtils.cleanupSignature(string: pollutedSignature)
        let cleanedCleanSignature = CryptoUtils.cleanupSignature(string: cleanSignature)

        XCTAssertEqual(cleanedPollutedSignature, expectedResult)
        XCTAssertEqual(cleanedCleanSignature, expectedResult)
    }


    func testSha1Base64() {

        let validC14nString = "<xad:SignedProperties xmlns:xad=\"http://uri.etsi.org/01903/v1.1.1#\" Id=\"test_SIG_1_SP\"><xad:SignedSignatureProperties><xad:SigningTime>2018-01-08T14:39:20Z</xad:SigningTime><xad:SigningCertificate><xad:Cert><xad:CertDigest><xad:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"></xad:DigestMethod><xad:DigestValue>fi49F7OjBlkGaYPzSxAB3iBbII4=</xad:DigestValue></xad:CertDigest><xad:IssuerSerial><ds:X509IssuerName xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">1.2.840.113549.1.9.1=#161473797374656d65406164756c6c6163742e6f7267,CN=AC ADULLACT Projet g2,OU=ADULLACT-Projet,O=ADULLACT-Projet,ST=Herault,C=FR</ds:X509IssuerName><ds:X509SerialNumber xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">14257229890764009179</ds:X509SerialNumber></xad:IssuerSerial></xad:Cert></xad:SigningCertificate><xad:SignaturePolicyIdentifier><xad:SignaturePolicyId><xad:SigPolicyId><xad:Identifier>urn:oid:1.2.250.1.131.1.5.18.21.1.4</xad:Identifier><xad:Description>Politique de signature Helios de la DGFiP</xad:Description></xad:SigPolicyId><xad:SigPolicyHash><xad:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"></xad:DigestMethod><xad:DigestValue>Jkdb+aba0Hz6+ZPKmKNhPByzQ+Q=</xad:DigestValue></xad:SigPolicyHash><xad:SigPolicyQualifiers><xad:SigPolicyQualifier><xad:SPURI>https://portail.dgfip.finances.gouv.fr/documents/PS_Helios_DGFiP.pdf</xad:SPURI></xad:SigPolicyQualifier></xad:SigPolicyQualifiers></xad:SignaturePolicyId></xad:SignaturePolicyIdentifier><xad:SignatureProductionPlace><xad:City>Montpellier</xad:City><xad:PostalCode>34000</xad:PostalCode><xad:CountryName>France</xad:CountryName></xad:SignatureProductionPlace><xad:SignerRole><xad:ClaimedRoles><xad:ClaimedRole>Administrateur titre</xad:ClaimedRole></xad:ClaimedRoles></xad:SignerRole></xad:SignedSignatureProperties></xad:SignedProperties>"
        let sha1Base64fromString = CryptoUtils.sha1Base64(string: validC14nString)

        let validC14nData = validC14nString.data(using: .utf8)
        let sha1Base64fromData = CryptoUtils.sha1Base64(data: validC14nData!)

        XCTAssertEqual(sha1Base64fromString, "tTHoWxazhE1HwGzRsTygY8purRw=")
        XCTAssertEqual(sha1Base64fromData, "tTHoWxazhE1HwGzRsTygY8purRw=")
    }


    func testData() {

        let data = CryptoUtils.data(hex: "5465737431323334")
        let decodedData = String(data: data, encoding: .utf8)

        XCTAssertEqual(decodedData, "Test1234")
    }


    func testHex() {

        let data = "Test1234".data(using: .utf8)
        let string = CryptoUtils.hex(data: data!)

        XCTAssertEqual(string, "5465737431323334")
    }


    func testPemToWrappedPem() {
        
        let data = "MIIFlTCCBH2gAwIBAgISESGDX4DHAz5bRvqfOEjtXChMMA0GCSqGSIb3DQEBCwUAMIGKMQswCQYDVQQGEwJGUjEkMCIGA1UECgwbR3JvdXBlIEltcHJpbWVyaWUgTmF0aW9uYWxlMRwwGgYDVQQLDBMwMDAyIDQxMDQ5NDQ5NjAwMDQ2MTcwNQYDVQQDDC5BQyBJbXByaW1lcmllIE5hdGlvbmFsZSBFbMOpbWVudGFpcmUgUGVyc29ubmVsMB4XDTE4MDExMTEzNDkwM1oXDTIxMDExMDEzNDkwM1owgYkxCzAJBgNVBAYTAkZSMRgwFgYDVQQKDA9Qcm9zcGVjdCBDbGllbnQxHDAaBgNVBAsMEzAwMDIgMTIzNDU2NzgyMDAwMTAxFzAVBgNVBAMMDlN0w6lwaGFuZSBWQVNUMSkwJwYDVQQFEyBlNjdkMTQ4OGNkOTc0NTA2OGY1MDgwZjZhMGRlNzNjMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK3yjSfTStG/eJtdimcKSmzB7Kk4lydZbX6ivCFOxRsqLNKxHnnQPUEHPfw5oJUBQUt4St0vtsbDwh21Z19cgOdrOXnwG5jJ0u3ow5fEID/cnfAQpGfZpnB+VRrm460DfYrvcCqcgABZjHakD2AB7YFrrKrrWSZlhQ2kfWUReVgiH3QXYfkOc8pQpfK9nzZ9ZkcJna5OLPCiQjx1kMWkE6Fd/UpAcxWFdw/CvWQDA9EfIGwJEzb22VOzziV/e7eTYJASB70VI51hot0R5zg7O31EXtwS9NHgvgwACmwTQ3Quc6nzeiixZCGEn9wqCfVK7KKakZMDmzqzpNvMh8CbSRkCAwEAAaOCAfIwggHuMAwGA1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgZAMFIGA1UdIARLMEkwRwYNKoF6AYInAQECAQFmATA2MDQGCCsGAQUFBwIBFihodHRwOi8vd3d3LmltcHJpbWVyaWVuYXRpb25hbGUuZnIvR0lOL1BDMIGFBgNVHR8EfjB8MHqgeKB2hjdodHRwOi8vY3JsLmltcHJpbWVyaWVuYXRpb25hbGUuZnIvR0lOL2NlcnQvQUNGLUVMLVAuY3JshjtodHRwOi8vd3d3LmltcHJpbWVyaWVuYXRpb25hbGUuZnIvR0lOL0NSTC9jZXJ0L0FDRi1FTC1QLmNybDCBiAYIKwYBBQUHAQEEfDB6MDYGCCsGAQUFBzABhipodHRwOi8vb2NzcC1hYy1lbC1wLmltcHJpbWVyaWVuYXRpb25hbGUuZnIwQAYIKwYBBQUHMAKGNGh0dHA6Ly93d3cuaW1wcmltZXJpZW5hdGlvbmFsZS5mci9HSU4vQUMvQUMtRUwtUC5wN2IwJwYDVR0RBCAwHoEcc3RlcGhhbmUudmFzdEBsaWJyaWNpZWwuY29vcDAdBgNVHQ4EFgQUhQgvuhrdZ5L/TPfCegZXr7s6NU8wHwYDVR0jBBgwFoAUGlE4pppjDlzkyMeOoV7F0C7chcowDQYJKoZIhvcNAQELBQADggEBAHZOVlD8j+n+/sfD8L+JW6AxGo5FJ3FoiQnHQ44ko5vv6tfS9tBxpA5lLGohsvony8tbMrYTriz7LBxEukdM6N7L3dCLqXw8CExEZGzRD+1mcpr4IxCizdtcxIxWjMeTbBxtAuAN/lgVT5QD528HxUwNRa4L/TMTlPk9SS/ghD1akden74QggZDNhXs7FtLUe6KWJI/LWy8ihwIUNRhnWfGzE8KAZGKWSdzgx1pqBhrXSriYMhv8Z0Id4fUvEZpaMbuHuJVHWfQmErGPqZ80lCSCZdzZCV4zcS99HrqpKEpOIXVamVmyz92hwUXRTCQhAwe6eTSce+gv5BSLGNd8bYE="
        let result = CryptoUtils.wrappedPem(publicKey: data)
        let expectedResult = """
        -----BEGIN CERTIFICATE-----
        MIIFlTCCBH2gAwIBAgISESGDX4DHAz5bRvqfOEjtXChMMA0GCSqGSIb3DQEBCwUA
        MIGKMQswCQYDVQQGEwJGUjEkMCIGA1UECgwbR3JvdXBlIEltcHJpbWVyaWUgTmF0
        aW9uYWxlMRwwGgYDVQQLDBMwMDAyIDQxMDQ5NDQ5NjAwMDQ2MTcwNQYDVQQDDC5B
        QyBJbXByaW1lcmllIE5hdGlvbmFsZSBFbMOpbWVudGFpcmUgUGVyc29ubmVsMB4X
        DTE4MDExMTEzNDkwM1oXDTIxMDExMDEzNDkwM1owgYkxCzAJBgNVBAYTAkZSMRgw
        FgYDVQQKDA9Qcm9zcGVjdCBDbGllbnQxHDAaBgNVBAsMEzAwMDIgMTIzNDU2Nzgy
        MDAwMTAxFzAVBgNVBAMMDlN0w6lwaGFuZSBWQVNUMSkwJwYDVQQFEyBlNjdkMTQ4
        OGNkOTc0NTA2OGY1MDgwZjZhMGRlNzNjMzCCASIwDQYJKoZIhvcNAQEBBQADggEP
        ADCCAQoCggEBAK3yjSfTStG/eJtdimcKSmzB7Kk4lydZbX6ivCFOxRsqLNKxHnnQ
        PUEHPfw5oJUBQUt4St0vtsbDwh21Z19cgOdrOXnwG5jJ0u3ow5fEID/cnfAQpGfZ
        pnB+VRrm460DfYrvcCqcgABZjHakD2AB7YFrrKrrWSZlhQ2kfWUReVgiH3QXYfkO
        c8pQpfK9nzZ9ZkcJna5OLPCiQjx1kMWkE6Fd/UpAcxWFdw/CvWQDA9EfIGwJEzb2
        2VOzziV/e7eTYJASB70VI51hot0R5zg7O31EXtwS9NHgvgwACmwTQ3Quc6nzeiix
        ZCGEn9wqCfVK7KKakZMDmzqzpNvMh8CbSRkCAwEAAaOCAfIwggHuMAwGA1UdEwEB
        /wQCMAAwDgYDVR0PAQH/BAQDAgZAMFIGA1UdIARLMEkwRwYNKoF6AYInAQECAQFm
        ATA2MDQGCCsGAQUFBwIBFihodHRwOi8vd3d3LmltcHJpbWVyaWVuYXRpb25hbGUu
        ZnIvR0lOL1BDMIGFBgNVHR8EfjB8MHqgeKB2hjdodHRwOi8vY3JsLmltcHJpbWVy
        aWVuYXRpb25hbGUuZnIvR0lOL2NlcnQvQUNGLUVMLVAuY3JshjtodHRwOi8vd3d3
        LmltcHJpbWVyaWVuYXRpb25hbGUuZnIvR0lOL0NSTC9jZXJ0L0FDRi1FTC1QLmNy
        bDCBiAYIKwYBBQUHAQEEfDB6MDYGCCsGAQUFBzABhipodHRwOi8vb2NzcC1hYy1l
        bC1wLmltcHJpbWVyaWVuYXRpb25hbGUuZnIwQAYIKwYBBQUHMAKGNGh0dHA6Ly93
        d3cuaW1wcmltZXJpZW5hdGlvbmFsZS5mci9HSU4vQUMvQUMtRUwtUC5wN2IwJwYD
        VR0RBCAwHoEcc3RlcGhhbmUudmFzdEBsaWJyaWNpZWwuY29vcDAdBgNVHQ4EFgQU
        hQgvuhrdZ5L/TPfCegZXr7s6NU8wHwYDVR0jBBgwFoAUGlE4pppjDlzkyMeOoV7F
        0C7chcowDQYJKoZIhvcNAQELBQADggEBAHZOVlD8j+n+/sfD8L+JW6AxGo5FJ3Fo
        iQnHQ44ko5vv6tfS9tBxpA5lLGohsvony8tbMrYTriz7LBxEukdM6N7L3dCLqXw8
        CExEZGzRD+1mcpr4IxCizdtcxIxWjMeTbBxtAuAN/lgVT5QD528HxUwNRa4L/TMT
        lPk9SS/ghD1akden74QggZDNhXs7FtLUe6KWJI/LWy8ihwIUNRhnWfGzE8KAZGKW
        Sdzgx1pqBhrXSriYMhv8Z0Id4fUvEZpaMbuHuJVHWfQmErGPqZ80lCSCZdzZCV4z
        cS99HrqpKEpOIXVamVmyz92hwUXRTCQhAwe6eTSce+gv5BSLGNd8bYE=
        -----END CERTIFICATE-----
        """
        
        XCTAssertEqual(result, expectedResult)
    }
    
    func testGetX509Values() {

        let publicKey = "MIIFlTCCBH2gAwIBAgISESGDX4DHAz5bRvqfOEjtXChMMA0GCSqGSIb3DQEBCwUAMIGKMQswCQYDVQQGEwJGUjEkMCIGA1UECgwbR3JvdXBlIEltcHJpbWVyaWUgTmF0aW9uYWxlMRwwGgYDVQQLDBMwMDAyIDQxMDQ5NDQ5NjAwMDQ2MTcwNQYDVQQDDC5BQyBJbXByaW1lcmllIE5hdGlvbmFsZSBFbMOpbWVudGFpcmUgUGVyc29ubmVsMB4XDTE4MDExMTEzNDkwM1oXDTIxMDExMDEzNDkwM1owgYkxCzAJBgNVBAYTAkZSMRgwFgYDVQQKDA9Qcm9zcGVjdCBDbGllbnQxHDAaBgNVBAsMEzAwMDIgMTIzNDU2NzgyMDAwMTAxFzAVBgNVBAMMDlN0w6lwaGFuZSBWQVNUMSkwJwYDVQQFEyBlNjdkMTQ4OGNkOTc0NTA2OGY1MDgwZjZhMGRlNzNjMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK3yjSfTStG/eJtdimcKSmzB7Kk4lydZbX6ivCFOxRsqLNKxHnnQPUEHPfw5oJUBQUt4St0vtsbDwh21Z19cgOdrOXnwG5jJ0u3ow5fEID/cnfAQpGfZpnB+VRrm460DfYrvcCqcgABZjHakD2AB7YFrrKrrWSZlhQ2kfWUReVgiH3QXYfkOc8pQpfK9nzZ9ZkcJna5OLPCiQjx1kMWkE6Fd/UpAcxWFdw/CvWQDA9EfIGwJEzb22VOzziV/e7eTYJASB70VI51hot0R5zg7O31EXtwS9NHgvgwACmwTQ3Quc6nzeiixZCGEn9wqCfVK7KKakZMDmzqzpNvMh8CbSRkCAwEAAaOCAfIwggHuMAwGA1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgZAMFIGA1UdIARLMEkwRwYNKoF6AYInAQECAQFmATA2MDQGCCsGAQUFBwIBFihodHRwOi8vd3d3LmltcHJpbWVyaWVuYXRpb25hbGUuZnIvR0lOL1BDMIGFBgNVHR8EfjB8MHqgeKB2hjdodHRwOi8vY3JsLmltcHJpbWVyaWVuYXRpb25hbGUuZnIvR0lOL2NlcnQvQUNGLUVMLVAuY3JshjtodHRwOi8vd3d3LmltcHJpbWVyaWVuYXRpb25hbGUuZnIvR0lOL0NSTC9jZXJ0L0FDRi1FTC1QLmNybDCBiAYIKwYBBQUHAQEEfDB6MDYGCCsGAQUFBzABhipodHRwOi8vb2NzcC1hYy1lbC1wLmltcHJpbWVyaWVuYXRpb25hbGUuZnIwQAYIKwYBBQUHMAKGNGh0dHA6Ly93d3cuaW1wcmltZXJpZW5hdGlvbmFsZS5mci9HSU4vQUMvQUMtRUwtUC5wN2IwJwYDVR0RBCAwHoEcc3RlcGhhbmUudmFzdEBsaWJyaWNpZWwuY29vcDAdBgNVHQ4EFgQUhQgvuhrdZ5L/TPfCegZXr7s6NU8wHwYDVR0jBBgwFoAUGlE4pppjDlzkyMeOoV7F0C7chcowDQYJKoZIhvcNAQELBQADggEBAHZOVlD8j+n+/sfD8L+JW6AxGo5FJ3FoiQnHQ44ko5vv6tfS9tBxpA5lLGohsvony8tbMrYTriz7LBxEukdM6N7L3dCLqXw8CExEZGzRD+1mcpr4IxCizdtcxIxWjMeTbBxtAuAN/lgVT5QD528HxUwNRa4L/TMTlPk9SS/ghD1akden74QggZDNhXs7FtLUe6KWJI/LWy8ihwIUNRhnWfGzE8KAZGKWSdzgx1pqBhrXSriYMhv8Z0Id4fUvEZpaMbuHuJVHWfQmErGPqZ80lCSCZdzZCV4zcS99HrqpKEpOIXVamVmyz92hwUXRTCQhAwe6eTSce+gv5BSLGNd8bYE="

        ADLKeyStore.getX509Values(publicKey)
    }
}
