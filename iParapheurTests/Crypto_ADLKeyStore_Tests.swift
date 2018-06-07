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


class Crypto_ADLKeyStore_Tests: XCTestCase {

    static private let PUBLIC_KEY = """
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
    
    
    func testX509FromPem() {
        let x509 = ADLKeyStore.x509(fromPem: Crypto_ADLKeyStore_Tests.PUBLIC_KEY)
        XCTAssertNotNil(x509)
    }
    
    
    func testParseX509Values() {
        let x509 = ADLKeyStore.x509(fromPem: Crypto_ADLKeyStore_Tests.PUBLIC_KEY)
        let valuesDict = ADLKeyStore.parseX509Values(x509) as! [String: AnyObject]
        
        XCTAssertNotNil(valuesDict)
        XCTAssertFalse(valuesDict.isEmpty)
        
        XCTAssertEqual(String(describing: valuesDict["notAfter"]!), "2021-01-10T13:49:03+01:00")
        XCTAssertEqual(String(describing: valuesDict["commonName"]!), "")
        XCTAssertEqual(String(describing: valuesDict["serialNumber"]!), "1492312803695880384522100141540144058214476")
        XCTAssertEqual(String(describing: valuesDict["keyUsage"]!), "Non Repudiation")
        XCTAssertEqual(String(describing: valuesDict["notBefore"]!), "2018-01-11T13:49:03+01:00")
    }
    
    
    func testParseX509V3Extensions() {
        let x509 = ADLKeyStore.x509(fromPem: Crypto_ADLKeyStore_Tests.PUBLIC_KEY)
        let valuesDict = ADLKeyStore.parseX509V3Extensions(x509) as! [String: AnyObject]
        
        XCTAssertNotNil(valuesDict)
        XCTAssertFalse(valuesDict.isEmpty)

        XCTAssertEqual(String(describing: valuesDict["X509v3 Key Usage"]!), "Non Repudiation")
        XCTAssertEqual(String(describing: valuesDict["X509v3 Basic Constraints"]!), "CA:FALSE")
        XCTAssertEqual(String(describing: valuesDict["X509v3 Subject Alternative Name"]!), "email:stephane.vast@libriciel.coop")
        
        // There is som weird things here : OpenSSL doesn't always return the same result.
        // Those 2 fields may be differents (or missing) amongst multiple executions.
        
        // XCTAssertTrue(String(describing: valuesDict["X509v3 Subject Key Identifier"]).contains("85:08:2F:BA:1A:DD:67:92:FF:4C:F7:C2:7A:06:57:AF:BB:3A:35:4F"))
        // XCTAssertTrue(String(describing: valuesDict["X509v3 Authority Key Identifier"]).contains("keyid:1A:51:38:A6:9A:63:0E:5C:E4:C8:C7:8E:A1:5E:C5:D0:2E:DC:85:CA"))
    }
    
}
