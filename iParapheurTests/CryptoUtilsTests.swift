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


class CryptoUtilsTests: XCTestCase {


    func testBuildXadesEnveloppedSignWrapper() {

        let getSignInfoJsonString = """
            {
                "pesid":"IDF2017-05-17T08-29-45.35",
                "hash":"3a922b5c63bd40021439dcbfe432e87cb4ee9d25",
                "pespolicydesc":"Politique de Signature de l'Agent",
                "pescountryname":"France",
                "pespostalcode":"34000",
                "format":"XADES-env",
                "pesspuri":"http://www.s2low.org/PolitiqueSignature-Agent",
                "pesencoding":"UTF-8",
                "pesclaimedrole":"Pastell",
                "pespolicyid":"urn:oid:1.2.250.1.5.3.1.1.10",
                "pespolicyhash":"G4CqRa9R5c9Yg+dzMH3gbEc4Kqo=",
                "p7s":null,
                "pescity":"Montpellier" 
            }
        """
        let getSignInfoJsonData = getSignInfoJsonString.data(using: .utf8)!
        let jsonDecoder = JSONDecoder()
        let signInfo = try? jsonDecoder.decode(SignInfo.self,
                                               from: getSignInfoJsonData)

        print("")
//        print(CryptoUtils.buildXadesEnveloppedSignWrapper(privateKey: "MIIHGjCCBQKgAwIBAgIUStb/+TKiIUj2TDZgq+uVGtUbRZQwDQYJKoZIhvcNAQELBQAwga8xCzAJ\n" +
//                                                                      "BgNVBAYTAkZSMRAwDgYDVQQIDAdIZXJhdWx0MR0wGwYDVQQKDBRBc3NvY2lhdGlvbiBBRFVMTEFD\n" +
//                                                                      "VDEkMCIGA1UECwwbQUNfQURVTExBQ1RfVXRpbGlzYXRldXJzX0czMSQwIgYDVQQDDBtBQ19BRFVM\n" +
//                                                                      "TEFDVF9VdGlsaXNhdGV1cnNfRzMxIzAhBgkqhkiG9w0BCQEWFHN5c3RlbWVAYWR1bGxhY3Qub3Jn\n" +
//                                                                      "MB4XDTE3MDkxMzA5NDgyM1oXDTE4MDkxMzA5NDgyM1owgasxCzAJBgNVBAYTAkZSMRAwDgYDVQQI\n" +
//                                                                      "DAdIZXJhdWx0MRQwEgYDVQQHDAtNb250cGVsbGllcjEXMBUGA1UECgwOTGlicmljaWVsLVNDT1Ax\n" +
//                                                                      "FjAUBgNVBAsMDURlbW9uc3RyYXRpb24xFjAUBgNVBAMMDUhhbWV1cnlfTHVrYXMxKzApBgkqhkiG\n" +
//                                                                      "9w0BCQEWHGx1a2FzLmhhbWV1cnlAbGlicmljaWVsLmNvb3AwggEiMA0GCSqGSIb3DQEBAQUAA4IB\n" +
//                                                                      "DwAwggEKAoIBAQC379oboJX8hGhZ8XpdAzTm6IDls2fkzQaDvRuz5JVSRYF8JNFt79HWaHDAISC/\n" +
//                                                                      "6C/B8SC8Ue1D3anCnbJJHMm2omgCBTOMGGURxb5nWsy4hPscecuB6wvG8Kh0J/PBnb+KOeSygZHI\n" +
//                                                                      "ag7V2BES5xNvrdcad5DqHJ+l8wbwxYtMsBWrjq8zDfTVmn/RSy4VRlD8II9lOvYEeHKFiBuHMOTG\n" +
//                                                                      "q6QVwCWGSQGBxzZ9GLfyx0enjHF9/9a3X6K7Dn+mRx5iS0b9LVcBh7+hDob06rFylzeGHClJEKIh\n" +
//                                                                      "I7e6tDUtK5JHbj1cLkm2L/IzFSrIRM9M1tSPTjj3vd6c/ehMXWpPAgMBAAGjggIuMIICKjAJBgNV\n" +
//                                                                      "HRMEAjAAMEIGCWCGSAGG+EIBDQQ1FjNDZXJ0aWZpY2F0IGdlbmVyZSBwYXIgbCdBQ19BRFVMTEFD\n" +
//                                                                      "VF9VVElMSVNBVEVVUlNfRzMwHQYDVR0OBBYEFBx9ML+71yRm/ohqLaYvXQJHaMbTMIH1BgNVHSME\n" +
//                                                                      "ge0wgeqAFJm7fwICmEWUBKxgJBPTKvvao19AoYG7pIG4MIG1MQswCQYDVQQGEwJGUjEQMA4GA1UE\n" +
//                                                                      "CAwHSGVyYXVsdDEUMBIGA1UEBwwLTW9udHBlbGxpZXIxHTAbBgNVBAoMFEFzc29jaWF0aW9uIEFE\n" +
//                                                                      "VUxMQUNUMRwwGgYDVQQLDBNBQ19BRFVMTEFDVF9ST09UX0czMRwwGgYDVQQDDBNBQ19BRFVMTEFD\n" +
//                                                                      "VF9ST09UX0czMSMwIQYJKoZIhvcNAQkBFhRzeXN0ZW1lQGFkdWxsYWN0Lm9yZ4IUbyl4BzfA+DWw\n" +
//                                                                      "MPJHFgkdXxI7UGowJwYDVR0RBCAwHoEcbHVrYXMuaGFtZXVyeUBsaWJyaWNpZWwuY29vcDAfBgNV\n" +
//                                                                      "HRIEGDAWgRRzeXN0ZW1lQGFkdWxsYWN0Lm9yZzA6BglghkgBhvhCAQQELRYraHR0cDovL2NybC5h\n" +
//                                                                      "ZHVsbGFjdC5vcmcvQ0FfVVNFUlNfQ1JMX2czLnBlbTA8BgNVHR8ENTAzMDGgL6AthitodHRwOi8v\n" +
//                                                                      "Y3JsLmFkdWxsYWN0Lm9yZy9BQ19VU0VSU19DUkxfZzMucGVtMA0GCSqGSIb3DQEBCwUAA4ICAQBg\n" +
//                                                                      "/5A9B53TFzd9cDqN3UzFdURWv1U3sdP/lsrks9yEcqmcZ22MX3osvIVvVAw4NDAghhcKB2bxKDTP\n" +
//                                                                      "XKKUX6RGneBWUx/dFNqgNc8hg7Su0A7hfUp8jyY2sxL9/NYiqPYD7tWzYxR2cIFO6ACS42SWysmg\n" +
//                                                                      "rr1Hf6Rm5tKvJQyWCVgx/TTe1y/5FgCgFnJcBoX5/7/vWO3+nKdmg1JybX0MNJoDKycb84mIqtBF\n" +
//                                                                      "hfJ4bTMBur4Y9wmoYrCMIP5PFXFVarWRSX9OI0YPTwvr0/G5I9On7WAD7TT93izpZYPvyxGzCPT1\n" +
//                                                                      "HSM2rFflNC6mjhMQex7UONE0Ch6HLFF8MMsBxhaQt8A/cTlhAfxMyY8kvPWjrkZQVfwGtA6fealh\n" +
//                                                                      "MjuxD/NhPEDrLid+ZrK6Nne1KtrZjDFzNokE8tRs78FDQMQlDJpkwrcT4f8x6yzjBY2X73okf5F/\n" +
//                                                                      "CYJTWSDcfSdujnP1DqT1v2szmP80OMW8uAGB0YScIH3a0H1q1gMFCAhki9ksMFMDaHxET570vIch\n" +
//                                                                      "xxo8oJD3uHiW8o+LfJ2HP5ybbyhqioE29UO7uqlE9Kh5mrlORfl2/QosVpimlod0Vz5t5BRpfCFg\n" +
//                                                                      "HBPeZdg3oA0VGljoVC9K2RQzRhKZN54rqGbbV1veJU5MFQEjIVzg2U32gfxZbTd3FejNZzEKIw==",
//                                                          signatureValue: "g/2G409/qXypnc6Gk1SDhDasoJpzUCM0EIilDA+C+/uFoXo8X1tP5NVePNCBVvVpgFPIiWkxmBQw\n" +
//                                                                          "psBMn+IP+lWAwHLkjrUCb9WLBCpnKroDdyYPQcpBfMd/Tc7TekDcznRHsaxfrZ5bEkwu7YlBeghM\n" +
//                                                                          "2IHczXQg8djASpciGD9w5PUQzKdJnx/RwUrQQXpHmlzCX38HSxwqnaiPyOuDNjmKOt0P36jfV2T+\n" +
//                                                                          "OOIxgq7P3aVsvTwfkBYqJU1Rrw847cRj7TtIu+ZAbQckSNgpOF/AMgAu4uxsJ664AuGoQecPs9L6\n" +
//                                                                          "x1d2Hf6n9Wyu2EG7MTRtP8QvJpNwOM1iQa9sCw==",
//                                                          signInfo: signInfo))
        print("")
    }

}
