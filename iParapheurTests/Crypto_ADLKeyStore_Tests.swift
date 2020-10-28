/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
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
        XCTAssertEqual(valuesDict.count, 8)

        XCTAssertEqual(valuesDict["commonName"] as! String, "St\\C3\\A9phane VAST")
        XCTAssertEqual(valuesDict["keyUsage"] as! String, "Non Repudiation")
        XCTAssertEqual(valuesDict["serialNumber"] as! String, "1492312803695880384522100141540144058214476")
        XCTAssertEqual(valuesDict["issuerName"] as! String, "CN=AC Imprimerie Nationale El\\C3\\A9mentaire Personnel,OU=0002 41049449600046,O=Groupe Imprimerie Nationale,C=FR")
        XCTAssertEqual(valuesDict["subject"] as! String, "serialNumber=e67d1488cd9745068f5080f6a0de73c3,CN=St\\C3\\A9phane VAST,OU=0002 12345678200010,O=Prospect Client,C=FR")
        XCTAssertEqual((valuesDict["publicKey"] as! String).count, 1996)
        XCTAssertEqual((valuesDict["notBefore"] as! NSDate).timeIntervalSince1970, 1515674943)
        XCTAssertEqual((valuesDict["notAfter"] as! NSDate).timeIntervalSince1970, 1610282943)
    }


    func testParseX509Values_IN() {

        let dataBase64 = "" +
                "MIIH+DCCBeCgAwIBAgISESFr7O1FVKFYJJvEcQ5Hli4CMA0GCSqGSIb3DQEBCwUAMIGeMQswCQYDVQQGEwJGUjEkMCIGA1UECgwbR3JvdXBlIEltcHJpbWVyaWUgTmF0" +
                "aW9uYWxlMRcwFQYDVQQLDA4wMDAyIDQxMDQ5NDQ5NjEYMBYGA1UEYQwPTlRSRlItNDEwNDk0NDk2MTYwNAYDVQQDDC1BQyBJbXByaW1lcmllIE5hdGlvbmFsZSBTdWJz" +
                "dGFudGllbCBQZXJzb25uZWwwHhcNMTgxMTA2MTAwNDMxWhcNMjExMTA1MTAwNDMxWjCB0DELMAkGA1UEBhMCRlIxHTAbBgNVBAoMFFZpbGxlIGRlIGxhIFJvY2hlbGxl" +
                "MR0wGwYDVQRhDBROVFJGUi0yMTE3MDMwMDQwMDAxMzEcMBoGA1UECwwTMDAwMiAyMTE3MDMwMDQwMDAxMzEpMCcGA1UEBRMgM2MxZDRlMGU3ZjQzMTI1YWZhNzFiNjEy" +
                "ZGEyNzU5OGMxEjAQBgNVBCoMCUd1aWxsYXVtZTENMAsGA1UEBAwEVk9MQTEXMBUGA1UEAwwOR3VpbGxhdW1lIFZPTEEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK" +
                "AoIBAQC/GBzCXsrutrneXWuJgdGDOFQZxOn+kbkvNeRt9Rr4hpOfkQEoCuKekPeTY6kkycHBKm4Usu6JIx/h3ATTMBXayZO7z1Km9OoKgzYKv1iYFTcElhofDW2cEkKs" +
                "9XFHrsRzZEVscfxb1MyI2h11Ed2nnsMrj5vw/fN1rDfzFBKFeBj5fDXbMGHJusTHHCRFu8e6LC4+6yzjrYZ5VVBPZmwgaawSxsXAg1vFbXqFCSUD5T00oXiXlmkl1HQ0" +
                "cyA4LMO6ClhUg9jZfArK/fDpojJk/3Sz+Y+Zt1AdtQLi4qsW/F8XgzSDQq4vKOE8iWNUDMIQzrjJQMeINddPUh/tT0kvAgMBAAGjggL6MIIC9jAJBgNVHRMEAjAAMIHG" +
                "BgNVHSAEgb4wgbswga0GDSqBegGCJwEBCAYBZgEwgZswNAYIKwYBBQUHAgEWKGh0dHA6Ly93d3cuaW1wcmltZXJpZW5hdGlvbmFsZS5mci9HSU4vUEMwYwYIKwYBBQUH" +
                "AgIwVwxVQ2VydGlmaWNhdCBkZSBzaWduYXR1cmUgY29uZm9ybWUgRVRTSSAzMTkgNDExLTIgKFFDUC1OLVFTQ0QpIHBvdXIgcGVyc29ubmVzIHBoeXNpcXVlczAJBgcE" +
                "AIvsQAECMIGFBgNVHR8EfjB8MHqgeKB2hjdodHRwOi8vY3JsLmltcHJpbWVyaWVuYXRpb25hbGUuZnIvR0lOL2NlcnQvQUNGLVNCLVAuY3JshjtodHRwOi8vd3d3Lmlt" +
                "cHJpbWVyaWVuYXRpb25hbGUuZnIvR0lOL0NSTC9jZXJ0L0FDRi1TQi1QLmNybDAOBgNVHQ8BAf8EBAMCBkAwLQYDVR0RBCYwJIEiZ3VpbGxhdW1lLnZvbGFAdmlsbGUt" +
                "bGFyb2NoZWxsZS5mcjCBigYIKwYBBQUHAQEEfjB8MDcGCCsGAQUFBzABhitodHRwOi8vb2NzcC1hY2Ytc2ItcC5pbXByaW1lcmllbmF0aW9uYWxlLmZyMEEGCCsGAQUF" +
                "BzAChjVodHRwOi8vd3d3LmltcHJpbWVyaWVuYXRpb25hbGUuZnIvR0lOL0FDL0FDRi1TQi1QLnA3YjCBiwYIKwYBBQUHAQMEfzB9MAgGBgQAjkYBATAIBgYEAI5GAQQw" +
                "EwYGBACORgEGMAkGBwQAjkYBBgEwUgYGBACORgEFMEgwRhZAaHR0cDovL3d3dy5pbXByaW1lcmllbmF0aW9uYWxlLmZyL0dJTi9QRFMvcGRzX3Bhc3Npbl8yMDE2LWVu" +
                "LnBkZhMCRU4wHQYDVR0OBBYEFArEoIDJ9h3uG5jUnmOFdNeXKPrUMB8GA1UdIwQYMBaAFNXS5UVfQ9oCdDU1n7yYLs2zp+HQMA0GCSqGSIb3DQEBCwUAA4ICAQCoKmDi" +
                "4HiKd/yhqXmEjL35VByR+vXLxSZks5D86S1tPlRsLf60NHI8IVqgyxIAahYInYmqrZi6dH9vIy7CX8cPj+8QcULQmsg2DjDpKSnxHO4fKtREqN0Fuo9ngpCeKf97VMxa" +
                "cigLPNScT01i3bnMiPdpoXuej0NA5OkbtpMcRSHVwqyMuCiSM8qnJsrb+voW4yJtEd2qcLHx2LbhCaCQBp+sivvlTeq28V27Q/t0VTj2bYwILvgS27qNd2xq6XIiVnrS" +
                "GtQV0ll6AYoDdIcnbNhRiJBT50G9wOmCrVgYzseGgJ7sEOSgbLNLBGZQ/DmJq9A+9bDLhaKGg35gPb0ZTfVEdfuY5IdADDZesVu+RvCamQcuy4gGMiub4DuuUKK5Wu7x" +
                "EQ9BhOim2nSHatUHfHAfURsZ8SQK/fZebeRcd689seAFAAjmUyEU5S2tKcpT0jVMAfzB/KixDEYHW675nUJYMDJ60vB6cXIZD+eJ+N9HmQZtCVQliGKtXu9aa5+gAcDG" +
                "WM7G2/Ktq/uhqa+UZ33YFX1aOiZ4qWKwIqk+VZlYGIgg71YneImSiXJb0DGVzNn5xXUegyOJhUt3WMakM+86YUfar+O3drYoS9aNDBY8edzJAVutUS617e8LwZ04XyqB" +
                "vfm1wjy3NQpqqwgUmbSVfMteHD5oEmEilKdeEw=="

        let x509 = ADLKeyStore.x509(fromPem: dataBase64)
        let x509Values = ADLKeyStore.parseX509Values(x509) as! [String: AnyObject]

        XCTAssertTrue(x509Values["commonName"] != nil)
        XCTAssertEqual((x509Values["commonName"] as! String).count, 14)
    }


    func testParseX509Values_Certinomis() {

        let dataBase64 = "" +
                "MIIHNTCCBR2gAwIBAgIUAITR9JEBHAQo0jbK6eI5hYEqVXcwDQYJKoZIhvcNAQELBQAwWjELMAkGA1UEBhMCRlIxEzARBgNVBAoTCkNlcnRpbm9taXMxFzAVBgNVBAsT" +
                "DjAwMDIgNDMzOTk4OTAzMR0wGwYDVQQDExRDZXJ0aW5vbWlzIC0gRWFzeSBDQTAeFw0xNzEyMTQxNDA3MDdaFw0yMDEyMTMxNDA3MDdaMIG6MQswCQYDVQQGEwJGUjEZ" +
                "MBcGA1UEChMQQ09NTVVORSBEIEFOTkVDWTEXMBUGA1UEYRMOMDAwMiAyMDAwNjM0MDIxFzAVBgNVBAsTDjAwMDIgMjAwMDYzNDAyMQ4wDAYDVQQMEwVNYWlyZTEYMBYG" +
                "A1UEAxMPSmVhbi1MdWMgUklHQVVUMQ8wDQYDVQQEEwZSSUdBVVQxETAPBgNVBCoTCEplYW4tTHVjMRAwDgYDVQQFEwcxLTY1Mjc3MIIBIjANBgkqhkiG9w0BAQEFAAOC" +
                "AQ8AMIIBCgKCAQEA9lhp3+vdR9oiWVrCB0GSSfZOHgkbRmO8b7g+165hjuq59+cuzOlih6wU2kwBDH60lTLq88LsNAveO9xHfMISG2uSZS8x8UJRitXoG8qNIf1oIg5c" +
                "EJdiVjoYZd7VxrMFAG4rAG+FFDg5sIjfU4aJoizZ/75/8OsvCtYAVdaJO9BmqB/bNTPg/NWz6nwbKdNn9NKimFczBSE9p2GEyNRKWyV2/MJPux1CGl+zWFCoo+K9fJRC" +
                "Gs71G5hYi7wMXcm7yqvlzxagbiKb6Kq43jFHmeXqofa0LeRcb3m1kCczoUeJPsVUoZ/LbtnATLv8wEtQ2o9B/COvSChTF0E+EiXzGwIDAQABo4ICkDCCAowwDgYDVR0P" +
                "AQH/BAQDAgbAMIHnBggrBgEFBQcBAwSB2jCB1zCBvwYGBACORgEFMIG0MFgWUmh0dHBzOi8vd3d3LmNlcnRpbm9taXMuZnIvZG9jdW1lbnRzLWV0LWxpZW5zL25vcy1j" +
                "b25kaXRpb25zLWdlbmVyYWxlcy1kdXRpbGlzYXRpb24TAmVuMFgWUmh0dHBzOi8vd3d3LmNlcnRpbm9taXMuZnIvZG9jdW1lbnRzLWV0LWxpZW5zL25vcy1jb25kaXRp" +
                "b25zLWdlbmVyYWxlcy1kdXRpbGlzYXRpb24TAmZyMBMGBgQAjkYBBjAJBgcEAI5GAQYBMAkGA1UdEwQCMAAwVQYIKwYBBQUHAQEESTBHMEUGCCsGAQUFBzABhjlodHRw" +
                "Oi8vaWdjLWczLmNlcnRpbm9taXMuY29tL0lOU1RBTkNFX1NIQTIvb2NzcC9PQ1NQX0VBU1kwKgYDVR0RBCMwIYEfamVhbi1sdWMucmlnYXV0QHZpbGxlLWFubmVjeS5m" +
                "cjAdBgNVHQ4EFgQUy15wvarYkk0dZJHS1d99HC8lOdIwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMEMB8GA1UdIwQYMBaAFCzF4yAvqwoR1vc611F49GyPsQBZ" +
                "MBcGA1UdIAQQMA4wDAYKKoF6AVYCAwEKATCBiQYDVR0fBIGBMH8wSqBIoEaGRGh0dHA6Ly9jcmwuaWdjLWczLmNlcnRpbm9taXMuY29tL0lOU1RBTkNFX1NIQTIvY3Js" +
                "L0FDX0VBU1ktY3JsLTEuY3JsMDGgL6AthitodHRwOi8vd3d3LmNlcnRpbm9taXMuY29tL2NybC9hY2czLUVBU1kuY3JsMA0GCSqGSIb3DQEBCwUAA4ICAQALnZH9zUp/" +
                "HkrseQBDj0msZPRGbeaYDO09o2Z7ocG/uKZGdocqSwhI39u9PTV292Gc4qnzEDaQxAA0mLRZWB6EFq8KzN6U8NxrIbYj6imBOnUkt9qv96sEAi08Iao+btXZdkGi6bhO" +
                "jlqZ6Dd+wVwp/KVHe9Vvuh4nLGGmAiJTG0m2JNSELjfP/v9YN9vffN7MYE7wq2AEoiYu3IjC0T1V7vYfQheGUDIrKYnyRqedfdkEAq+GhemHDdipDNcyFqPb9doueKas" +
                "G0s+IgImsqOUD50REShAVdmPRnvp8CKJryfFLfdiWqKIdiDSvTfVsHKdO0MPUeB9uKjYr0VsuIoJDCk6bclfBjPYk/o4jNPMst1KhCjtxGxpz9ATGlWxF9wqrwYTqdvK" +
                "x+9Zmn5gMqW716+88Z8phaWKEMtZUdc59HHMCJz+nvpQ96HI9VN61S323cmaxnQKhekkFSxigo9yOjMrUiuHz6EcMORUUhdYLt0Y5lwcpnATsA6a8Txh612zuFkz6RdY" +
                "FkL3MD7KblXvXH4M7c2FJ69tctXOwP/vPIZi0w6lKy6kaVzcHbF8LGfwPgh4iH5MY3ouvWOmrXmO7prt1U0i7ALmP2YLkmZ2mktxBJaC4Z8OD/tj2NrguaudR94fqJIB" +
                "VKvV9rL0mvXpVVJypgZqHI6zRhUPDi/W7g=="

        let x509 = ADLKeyStore.x509(fromPem: dataBase64)
        let x509Values = ADLKeyStore.parseX509Values(x509) as! [String: AnyObject]

        XCTAssertTrue(x509Values["commonName"] != nil)
        XCTAssertEqual((x509Values["commonName"] as! String).count, 15)
    }


    func testParseX509V3Extensions() {
        let x509 = ADLKeyStore.x509(fromPem: Crypto_ADLKeyStore_Tests.PUBLIC_KEY)
        let valuesDict = ADLKeyStore.parseX509V3Extensions(x509) as! [String: AnyObject]

        XCTAssertNotNil(valuesDict)
        XCTAssertEqual(valuesDict.count, 8)

        XCTAssertEqual(valuesDict["X509v3 Key Usage"] as! String, "Non Repudiation")
        XCTAssertEqual(valuesDict["Authority Information Access"] as! String, "OCSP - URI:http://ocsp-ac-el-p.imprimerienationale.fr\nCA Issuers - URI:http://www.imprimerienationale.fr/GIN/AC/AC-EL-P.p7b\n")
        XCTAssertEqual(valuesDict["X509v3 Authority Key Identifier"] as! String, "keyid:1A:51:38:A6:9A:63:0E:5C:E4:C8:C7:8E:A1:5E:C5:D0:2E:DC:85:CA\n")
        XCTAssertEqual(valuesDict["X509v3 CRL Distribution Points"] as! String, "\nFull Name:\n  URI:http://crl.imprimerienationale.fr/GIN/cert/ACF-EL-P.crl\n  URI:http://www.imprimerienationale.fr/GIN/CRL/cert/ACF-EL-P.crl\n")
        XCTAssertEqual(valuesDict["X509v3 Certificate Policies"] as! String, "Policy: 1.2.250.1.295.1.1.2.1.1.102.1\n  CPS: http://www.imprimerienationale.fr/GIN/PC\n")
        XCTAssertEqual(valuesDict["X509v3 Subject Alternative Name"] as! String, "email:stephane.vast@libriciel.coop")
        XCTAssertEqual(valuesDict["X509v3 Basic Constraints"] as! String, "CA:FALSE")
    }

}
