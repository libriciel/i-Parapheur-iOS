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


class Crypto_XadesSha1EnvHasher_Test: XCTestCase {


    func testCanonicalizeXml() {

        let validC14n = "<xad:SignedProperties xmlns:xad=\"http://uri.etsi.org/01903/v1.1.1#\" Id=\"test_SIG_1_SP\"><xad:SignedSignatureProperties><xad:SigningTime>2018-01-08T14:39:20Z</xad:SigningTime><xad:SigningCertificate><xad:Cert><xad:CertDigest><xad:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"></xad:DigestMethod><xad:DigestValue>fi49F7OjBlkGaYPzSxAB3iBbII4=</xad:DigestValue></xad:CertDigest><xad:IssuerSerial><ds:X509IssuerName xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">1.2.840.113549.1.9.1=#161473797374656d65406164756c6c6163742e6f7267,CN=AC ADULLACT Projet g2,OU=ADULLACT-Projet,O=ADULLACT-Projet,ST=Herault,C=FR</ds:X509IssuerName><ds:X509SerialNumber xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">14257229890764009179</ds:X509SerialNumber></xad:IssuerSerial></xad:Cert></xad:SigningCertificate><xad:SignaturePolicyIdentifier><xad:SignaturePolicyId><xad:SigPolicyId><xad:Identifier>urn:oid:1.2.250.1.131.1.5.18.21.1.4</xad:Identifier><xad:Description>Politique de signature Helios de la DGFiP</xad:Description></xad:SigPolicyId><xad:SigPolicyHash><xad:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"></xad:DigestMethod><xad:DigestValue>Jkdb+aba0Hz6+ZPKmKNhPByzQ+Q=</xad:DigestValue></xad:SigPolicyHash><xad:SigPolicyQualifiers><xad:SigPolicyQualifier><xad:SPURI>https://portail.dgfip.finances.gouv.fr/documents/PS_Helios_DGFiP.pdf</xad:SPURI></xad:SigPolicyQualifier></xad:SigPolicyQualifiers></xad:SignaturePolicyId></xad:SignaturePolicyIdentifier><xad:SignatureProductionPlace><xad:City>Montpellier</xad:City><xad:PostalCode>34000</xad:PostalCode><xad:CountryName>France</xad:CountryName></xad:SignatureProductionPlace><xad:SignerRole><xad:ClaimedRoles><xad:ClaimedRole>Administrateur titre</xad:ClaimedRole></xad:ClaimedRoles></xad:SignerRole></xad:SignedSignatureProperties></xad:SignedProperties>"
        let before = "<xad:SignedProperties xmlns:xad=\"http://uri.etsi.org/01903/v1.1.1#\" Id=\"test_SIG_1_SP\"><xad:SignedSignatureProperties><xad:SigningTime>2018-01-08T14:39:20Z</xad:SigningTime><xad:SigningCertificate><xad:Cert><xad:CertDigest><xad:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"/><xad:DigestValue>fi49F7OjBlkGaYPzSxAB3iBbII4=</xad:DigestValue></xad:CertDigest><xad:IssuerSerial><ds:X509IssuerName xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">1.2.840.113549.1.9.1=#161473797374656d65406164756c6c6163742e6f7267,CN=AC ADULLACT Projet g2,OU=ADULLACT-Projet,O=ADULLACT-Projet,ST=Herault,C=FR</ds:X509IssuerName><ds:X509SerialNumber xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">14257229890764009179</ds:X509SerialNumber></xad:IssuerSerial></xad:Cert></xad:SigningCertificate><xad:SignaturePolicyIdentifier><xad:SignaturePolicyId><xad:SigPolicyId><xad:Identifier>urn:oid:1.2.250.1.131.1.5.18.21.1.4</xad:Identifier><xad:Description>Politique de signature Helios de la DGFiP</xad:Description></xad:SigPolicyId><xad:SigPolicyHash><xad:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"/><xad:DigestValue>Jkdb+aba0Hz6+ZPKmKNhPByzQ+Q=</xad:DigestValue></xad:SigPolicyHash><xad:SigPolicyQualifiers><xad:SigPolicyQualifier><xad:SPURI>https://portail.dgfip.finances.gouv.fr/documents/PS_Helios_DGFiP.pdf</xad:SPURI></xad:SigPolicyQualifier></xad:SigPolicyQualifiers></xad:SignaturePolicyId></xad:SignaturePolicyIdentifier><xad:SignatureProductionPlace><xad:City>Montpellier</xad:City><xad:PostalCode>34000</xad:PostalCode><xad:CountryName>France</xad:CountryName></xad:SignatureProductionPlace><xad:SignerRole><xad:ClaimedRoles><xad:ClaimedRole>Administrateur titre</xad:ClaimedRole></xad:ClaimedRoles></xad:SignerRole></xad:SignedSignatureProperties></xad:SignedProperties>"
        let after = XadesSha1EnvHasher.canonicalizeXml(xmlCompactString: before,
                                                   forceSignPropertiesXmlns: false,
                                                   forceSignedInfoXmlns: false)

        XCTAssertEqual(validC14n, after)
    }


    func testCanonicalizeXml_forceSignPropertiesXmlns() {

        let validC14n = "<xad:SignedProperties xmlns:xad=\"http://uri.etsi.org/01903/v1.1.1#\" Id=\"test_SIG_1_SP\"><xad:SignedSignatureProperties><xad:SigningTime>2018-01-10T09:20:30Z</xad:SigningTime><xad:SigningCertificate><xad:Cert><xad:CertDigest><xad:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"></xad:DigestMethod><xad:DigestValue>fi49F7OjBlkGaYPzSxAB3iBbII4=</xad:DigestValue></xad:CertDigest><xad:IssuerSerial><ds:X509IssuerName xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">EMAILADDRESS=systeme@adullact.org,CN=AC ADULLACT Projet g2,OU=ADULLACT-Projet,O=ADULLACT-Projet,ST=Herault,C=FR</ds:X509IssuerName><ds:X509SerialNumber xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\">14257229890764009179</ds:X509SerialNumber></xad:IssuerSerial></xad:Cert></xad:SigningCertificate><xad:SignaturePolicyIdentifier><xad:SignaturePolicyId><xad:SigPolicyId><xad:Identifier>urn:oid:1.2.250.1.131.1.5.18.21.1.4</xad:Identifier><xad:Description>Politique de signature Helios de la DGFiP</xad:Description></xad:SigPolicyId><xad:SigPolicyHash><xad:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"></xad:DigestMethod><xad:DigestValue>Jkdb+aba0Hz6+ZPKmKNhPByzQ+Q=</xad:DigestValue></xad:SigPolicyHash><xad:SigPolicyQualifiers><xad:SigPolicyQualifier><xad:SPURI>http://www.s2low.org/PolitiqueSignature-Agent</xad:SPURI></xad:SigPolicyQualifier></xad:SigPolicyQualifiers></xad:SignaturePolicyId></xad:SignaturePolicyIdentifier><xad:SignatureProductionPlace><xad:City>Montpellier</xad:City><xad:PostalCode>34000</xad:PostalCode><xad:CountryName>France</xad:CountryName></xad:SignatureProductionPlace><xad:SignerRole><xad:ClaimedRoles><xad:ClaimedRole>Administrateur titre</xad:ClaimedRole></xad:ClaimedRoles></xad:SignerRole></xad:SignedSignatureProperties></xad:SignedProperties>"
        let before = "<xad:SignedProperties Id=\"test_SIG_1_SP\"><xad:SignedSignatureProperties><xad:SigningTime>2018-01-10T09:20:30Z</xad:SigningTime><xad:SigningCertificate><xad:Cert><xad:CertDigest><xad:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\" /><xad:DigestValue>fi49F7OjBlkGaYPzSxAB3iBbII4=</xad:DigestValue></xad:CertDigest><xad:IssuerSerial><ds:X509IssuerName>EMAILADDRESS=systeme@adullact.org,CN=AC ADULLACT Projet g2,OU=ADULLACT-Projet,O=ADULLACT-Projet,ST=Herault,C=FR</ds:X509IssuerName><ds:X509SerialNumber>14257229890764009179</ds:X509SerialNumber></xad:IssuerSerial></xad:Cert></xad:SigningCertificate><xad:SignaturePolicyIdentifier><xad:SignaturePolicyId><xad:SigPolicyId><xad:Identifier>urn:oid:1.2.250.1.131.1.5.18.21.1.4</xad:Identifier><xad:Description>Politique de signature Helios de la DGFiP</xad:Description></xad:SigPolicyId><xad:SigPolicyHash><xad:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\" /><xad:DigestValue>Jkdb+aba0Hz6+ZPKmKNhPByzQ+Q=</xad:DigestValue></xad:SigPolicyHash><xad:SigPolicyQualifiers><xad:SigPolicyQualifier><xad:SPURI>http://www.s2low.org/PolitiqueSignature-Agent</xad:SPURI></xad:SigPolicyQualifier></xad:SigPolicyQualifiers></xad:SignaturePolicyId></xad:SignaturePolicyIdentifier><xad:SignatureProductionPlace><xad:City>Montpellier</xad:City><xad:PostalCode>34000</xad:PostalCode><xad:CountryName>France</xad:CountryName></xad:SignatureProductionPlace><xad:SignerRole><xad:ClaimedRoles><xad:ClaimedRole>Administrateur titre</xad:ClaimedRole></xad:ClaimedRoles></xad:SignerRole></xad:SignedSignatureProperties></xad:SignedProperties>"
        let after = XadesSha1EnvHasher.canonicalizeXml(xmlCompactString: before,
                                                   forceSignPropertiesXmlns: true,
                                                   forceSignedInfoXmlns: false)

        XCTAssertEqual(validC14n, after)
    }


    func testCanonicalizeXml_forceSignedInfoXmlns() {

        let validC14n = "<ds:SignedInfo xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\"><ds:CanonicalizationMethod Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"></ds:CanonicalizationMethod><ds:SignatureMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#rsa-sha1\"></ds:SignatureMethod><ds:Reference URI=\"#test\"><ds:Transforms><ds:Transform Algorithm=\"http://www.w3.org/2000/09/xmldsig#enveloped-signature\"></ds:Transform><ds:Transform Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"></ds:Transform></ds:Transforms><ds:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"></ds:DigestMethod><ds:DigestValue>OpIrXGO9QAIUOdy/5DLofLTunSU=</ds:DigestValue></ds:Reference><ds:Reference Type=\"http://uri.etsi.org/01903/v1.1.1#SignedProperties\" URI=\"#test_SIG_1_SP\"><ds:Transforms><ds:Transform Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"></ds:Transform></ds:Transforms><ds:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\"></ds:DigestMethod><ds:DigestValue>Drt6Vcz5dJtXvJ7xQghZEhpiHD8=</ds:DigestValue></ds:Reference></ds:SignedInfo>"
        let before = "<ds:SignedInfo><ds:CanonicalizationMethod Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\" /><ds:SignatureMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#rsa-sha1\" /><ds:Reference URI=\"#test\"><ds:Transforms><ds:Transform Algorithm=\"http://www.w3.org/2000/09/xmldsig#enveloped-signature\" /><ds:Transform Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\" /></ds:Transforms><ds:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\" /><ds:DigestValue>OpIrXGO9QAIUOdy/5DLofLTunSU=</ds:DigestValue></ds:Reference><ds:Reference Type=\"http://uri.etsi.org/01903/v1.1.1#SignedProperties\" URI=\"#test_SIG_1_SP\"><ds:Transforms><ds:Transform Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\" /></ds:Transforms><ds:DigestMethod Algorithm=\"http://www.w3.org/2000/09/xmldsig#sha1\" /><ds:DigestValue>Drt6Vcz5dJtXvJ7xQghZEhpiHD8=</ds:DigestValue></ds:Reference></ds:SignedInfo>"
        let after = XadesSha1EnvHasher.canonicalizeXml(xmlCompactString: before,
                                                   forceSignPropertiesXmlns: false,
                                                   forceSignedInfoXmlns: true)

        XCTAssertEqual(validC14n, after)
    }

}
