import Intents
import UIKit
import Foundation
import PassKit
import LocalAuthentication
import Security
import CryptoKit
import CommonCrypto
import os

let BASE_URL = "https://extapigw-uat.bh.kfh.com"
let encryptionKey = "77889900112277889900112277889900"
let certPassword = "P@ssw0rd"
let ivString = "PGKEYENCDECIVSPC"
let appGroupID: String = "group.com.aub.mobilebanking.uat.bh"
let entity = AUBEntity.AUBBH

class IntentHandler: PKIssuerProvisioningExtensionHandler {
    
    let passLibrary = PKPassLibrary()
    
    // MARK: - Required Methods
    func authorize(completion: @escaping (PKIssuerProvisioningExtensionAuthorizationResult) -> Void) {
        completion(.authorized)
    }
    
    override func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
        
        WalletAuthManager.shared.clearToken()
        WalletAuthManager.shared.clearSessionToken()
        
        let status = PKIssuerProvisioningExtensionStatus()

        status.requiresAuthentication = true
        status.passEntriesAvailable = true
        status.remotePassEntriesAvailable = true
        
        completion(status)
    }
    
    override func passEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        
        os_log("callWalletCardsDetailsAPI here")
        
        callWalletCardsDetailsAPI { result in

            switch result {

            case .success(let cards):
                os_log("Cards: \(cards)")
                
                Task {
                    var passEntries: [PKIssuerProvisioningExtensionPassEntry] = []
                    for card in cards {
                        if let entry = await self.getPaymentPassEntry(card: card, baseURL: BASE_URL) {
                            passEntries.append(entry)
                        }
                    }
                    os_log("Cards passEntries : \(passEntries)")
                    completion(passEntries)
                }

            case .failure(let error):
                os_log("Error callWalletCardsDetailsAPI call: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    override func remotePassEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        
        callWalletCardsDetailsAPI { result in

            switch result {

            case .success(let cards):
                
                Task {
                    var passEntries: [PKIssuerProvisioningExtensionPassEntry] = []
                    for card in cards {
                        if let entry = await self.getPaymentPassEntry(card: card, baseURL: BASE_URL) {
                            passEntries.append(entry)
                        }
                    }
                    completion(passEntries)
                }

            case .failure(_):
                completion([])
            }
        }
    }
    
    override func generateAddPaymentPassRequestForPassEntryWithIdentifier(
        _ identifier: String,
        configuration: PKAddPaymentPassRequestConfiguration,
        certificateChain certificates: [Data],
        nonce: Data,
        nonceSignature: Data,
        completionHandler completion: @escaping (PKAddPaymentPassRequest?) -> Void
    ) {
        guard !certificates.isEmpty else {
            completion(nil)
            return
        }
        
        callWalletActivationAPI(certificates: certificates[0].base64EncodedString(), nonce: nonce.base64EncodedString(), nonceSignature: nonceSignature.base64EncodedString(), cardSuffix: configuration.primaryAccountSuffix ?? "") { result in
            
            switch result {

            case .success(let response):
                
                
                guard
                    let encryptedPassData = response.encryptedPassData,
                    let activationData = response.activationData,
                    let ephemeralPublicKey = response.ephemeralPublicKey
                else {
                    os_log("Activation response contains nil values")
                    completion(nil)
                    return
                }
                
                guard
                    let activationData = Data(base64Encoded: activationData),
                    let encryptedData = Data(base64Encoded: encryptedPassData),
                    let ephemeralKey = Data(base64Encoded: ephemeralPublicKey)
                else {
                    os_log("no data converiosn of all strings to data")
                    completion(nil)
                    return
                }
                
                let request = PKAddPaymentPassRequest()
                
                request.activationData = activationData
                request.encryptedPassData = encryptedData
                request.ephemeralPublicKey = ephemeralKey
                
                completion(request)
                
                // call card status update API
                self.callWalletStatusUpdateAPI(suffix: configuration.primaryAccountSuffix ?? "") { result in
                    
                    switch result {
                        
                    case .success(let response):
                        os_log("Code: \(response.code ?? "")")
                        os_log("Description: \(response.desc ?? "")")
                        
                    case .failure(let error):
                        os_log("Error: \(error.localizedDescription)")
                    }
                }

            case .failure(let error):
                os_log("error = \(error)")
                completion(nil)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getPaymentPassEntry(card: Card, baseURL: String) async -> PKIssuerProvisioningExtensionPaymentPassEntry? {
        guard let requestConfig = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2) else {
            return nil
        }
        
        let url = "\(baseURL)\(card.artUrl ?? "")"
        
        requestConfig.primaryAccountIdentifier = card.cardId
        requestConfig.paymentNetwork = .masterCard // Update based on cardType if needed
        requestConfig.cardholderName = card.holderName
        requestConfig.localizedDescription = card.cardTitle
        requestConfig.primaryAccountSuffix = String(card.maskedCardNumber.suffix(4))
        requestConfig.style = .payment
        
        do {
            let cgImage = try await cgImage(from: url)
            return PKIssuerProvisioningExtensionPaymentPassEntry(
                identifier: card.cardId,
                title: card.cardTitle,
                art: cgImage,
                addRequestConfiguration: requestConfig
            )
        } catch {
            return PKIssuerProvisioningExtensionPaymentPassEntry(
                identifier: card.cardId,
                title: card.cardTitle,
                art: defaultCGImage()!,
                addRequestConfiguration: requestConfig
            )
        }
    }
}

// functions for image url to CgImge conversion
extension IntentHandler {
    
    func defaultCGImage(
        width: Int = 100,
        height: Int = 100,
        color: UIColor = .lightGray
    ) -> CGImage? {
 
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
 
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
 
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: width, height: height))
 
        return context?.makeImage()
    }
    
    func cgImage(from urlString: String) async throws -> CGImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image"])
        }
        
        return cgImage
    }
}

enum AUBEntity: String {
    case AUBBH
    case AUBUK
}

struct AUBCredentials {
    let entity: String
    let clientID: String
    let clientSecret: String
    let signedRequestToken: String
    let username: String
    let password: String
}

struct TokenResponse: Codable {
    let token: String
    let expires_in: String
    let token_type: String
}

struct Card {
    var cardId: String = ""
    var maskedCardNumber: String = ""
    var artUrl: String?
    var cardTitle: String = ""
    var holderName: String = ""
}

struct WalletActivationResponse {
    let encryptedPassData: String?
    let activationData: String?
    let ephemeralPublicKey: String?
}

// for getting entity type like BHARRIN or UK
extension IntentHandler {
    
    func getEntityDetails() -> AUBCredentials {
        let credentials = getCredentials(for: entity)
        return credentials
    }

    func getCredentials(for entity: AUBEntity) -> AUBCredentials {
        
        switch entity {
            
        case .AUBBH:
            return AUBCredentials(
                entity: "AUBBH",
                clientID: "9ad769f1dabad84ba943f561616c0faf",
                clientSecret: "702e32b2b2962fd081c97e9f1a801550",
                signedRequestToken: "S2lxSElGZ3VVdnFWSmFqRG9yT2RYbzNzSXRvdXNJMEM",
                username: "Testuser1",
                password: "Passw0rd"
            )
            
        case .AUBUK:
            return AUBCredentials(
                entity: "AUBUK",
                clientID: "f6a7e302b3448a7104d7e2f758dd8760",
                clientSecret: "726fbd8dcad97a53e5bcd4ae0ea60064",
                signedRequestToken: "a0FpbUxWMkhOTnRBenFMakozdXNjRjh0V1BGR1p4TEk",
                username: "ukadventtest112",
                password: "Passw0rd"
            )
        }
    }
}

// call all token related APIs
extension IntentHandler {

    func callWalletLoginAPI(
        username: String,
        password: String,
        completion: @escaping (Result<String, Error>) -> Void) {

        getValidToken { token in

            guard let token = token else {
                os_log("No valid token available")
                completion(.failure(NSError(domain: "TokenError", code: 0)))
                return
            }

            let encryptedPassword = self.encryptAES(
                tranData: password,
                key: encryptionKey
            )
                
            let txnRef = self.generateTxnRef()
            
            let xmlString = """
                <AUB_MESSAGE>
                    <REQUEST_MESSAGE>
                        <RequestHeader>
                            <MsgType>Request</MsgType>
                            <ReqID>MB_WALLET</ReqID>
                            <ChSysID>MB_WALLET_EXT</ChSysID>
                            <FuncID>WALLET_LOGIN_AUTH</FuncID>
                            <UserID/>
                            <TxnRef>\(txnRef)</TxnRef>
                            <CorrTxnRef />
                            <TxnDate>\(self.getTxnDate())</TxnDate>
                            <CustGrpID/>
                            <CustNIN></CustNIN>
                            <EntID>\(self.getEntityDetails().entity)</EntID>
                            <SysID/>
                            <CustID/>
                            <ProcessEntID/>
                            <OrigEntID>\(self.getEntityDetails().entity)</OrigEntID>
                            <TxnStatus>Y</TxnStatus>
                            <SessLang>E</SessLang>
                            <VerNo>0001</VerNo>
                            <SessToken>123456789</SessToken>
                            <BypassOds>Y</BypassOds>
                        </RequestHeader>
                        <RequestBody>
                            <WALLET_LOGIN_AUTH_RQ>
                                <entityId>\(self.getEntityDetails().entity)</entityId>
                                <deviceId>\(self.getDeviceId())</deviceId>
                                <ipAddress>\(self.getIPAddress())</ipAddress>
                                <userName>\(username)</userName>
                                <password>\(encryptedPassword ?? "")</password>
                            </WALLET_LOGIN_AUTH_RQ>
                        </RequestBody>
                    </REQUEST_MESSAGE>
                </AUB_MESSAGE>
                """
                
            let signedRequest = SignedRequestGenerator.createSignedRequest(
                xmlRequest: xmlString,
                token: self.getEntityDetails().signedRequestToken
            )
                
            let postData = """
                <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
                    <SOAP-ENV:Header/>
                    <s:Body xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                        <getResponse xmlns="http://middleware.webservice.aub.com">
                            <request>
                                <![CDATA[\(signedRequest ?? "")]]>
                            </request>
                        </getResponse>
                    </s:Body>
                </s:Envelope>
                """
                
            os_log("callWalletLoginAPI post data = \(postData)")
                
            let consumer = HTTPSConsumer()
                
            consumer.consumePOST(
                url: "\(BASE_URL)/kfh/uat/eiphandlerservice/invoke/wallet_login_auth",
                postData: postData,
                headers: [
                    "Authorization": token,
                    "TxnRef": txnRef,
                    "X-IBM-Client-Id": self.getEntityDetails().clientID
                ],
                contentType: "application/xml"
            ) { result in

                switch result {
                case .success(let response):
                    os_log("callWalletLoginAPI API Success: \(response)")
                        
                    if let sessionToken = self.extractSessionToken(from: response) {
                        WalletAuthManager.shared.saveSessionToken(sessionToken)
                        completion(.success(sessionToken))
                    } else {
                        completion(.failure(NSError(domain: "SessionTokenMissing", code: 0)))
                    }

                case .failure(let error):
                    os_log("callWalletLoginAPI API Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func callWalletCardsDetailsAPI(completion: @escaping (Result<[Card], Error>) -> Void) {

        getValidToken { token in

            guard let token = token else {
                os_log("No valid token available")
                completion(.failure(NSError(domain: "TokenError", code: 0)))
                return
            }

            guard let loginSessionToken = WalletAuthManager.shared.getSessionToken() else {
                os_log("No valid session token available")
                completion(.failure(NSError(domain: "SessionTokenError", code: 0)))
                return
            }
                
            let txnRef = self.generateTxnRef()
                
            let xmlString = """
                <AUB_MESSAGE>
                    <REQUEST_MESSAGE>
                        <RequestHeader>
                            <MsgType>Request</MsgType>
                            <ReqID>MB_WALLET</ReqID>
                            <ChSysID>MB_WALLET_EXT</ChSysID>
                            <FuncID>WALLET_CARD_DETAIL</FuncID>
                            <UserID/>
                            <TxnRef>\(txnRef)</TxnRef>
                            <CorrTxnRef />
                            <TxnDate>\(self.getTxnDate())</TxnDate>
                            <CustGrpID/>
                            <CustNIN></CustNIN>
                            <EntID>\(self.getEntityDetails().entity)</EntID>
                            <SysID/>
                            <CustID/>
                            <ProcessEntID/>
                            <OrigEntID>\(self.getEntityDetails().entity)</OrigEntID>
                            <TxnStatus>Y</TxnStatus>
                            <SessLang>E</SessLang>
                            <VerNo>0001</VerNo>
                            <SessToken>123456789</SessToken>
                            <BypassOds>Y</BypassOds>
                        </RequestHeader>
                        <RequestBody>
                            <WALLET_CARD_DETAIL_RQ>
                                <entityId>\(self.getEntityDetails().entity)</entityId>
                                <deviceId>\(self.getDeviceId())</deviceId>
                                <deviceModel>\(self.getDeviceModelIdentifier())</deviceModel>
                                <ipAddress>\(self.getIPAddress())</ipAddress>
                                <type>\(self.getOSType())</type>
                                <sessionToken>\(loginSessionToken)</sessionToken>
                            </WALLET_CARD_DETAIL_RQ>
                        </RequestBody>
                    </REQUEST_MESSAGE>
                </AUB_MESSAGE>
                """
                
            let signedRequest = SignedRequestGenerator.createSignedRequest(
                xmlRequest: xmlString,
                token: self.getEntityDetails().signedRequestToken
            )
                
            let postData = """
                <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
                    <SOAP-ENV:Header/>
                    <s:Body xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                        <getResponse xmlns="http://middleware.webservice.aub.com">
                            <request>
                                <![CDATA[\(signedRequest ?? "")]]>
                            </request>
                        </getResponse>
                    </s:Body>
                </s:Envelope>
                """
                
            os_log("callWalletCardsDetailsAPI postData = \(postData)")
                
            let consumer = HTTPSConsumer()
                
            consumer.consumePOST(
                url: "\(BASE_URL)/kfh/uat/eiphandlerservice/invoke/wallet_card_detail",
                postData: postData,
                headers: [
                    "Authorization": token,
                    "TxnRef": txnRef,
                    "X-IBM-Client-Id": self.getEntityDetails().clientID
                ],
                contentType: "application/xml"
            ) { result in

                switch result {
                case .success(let response):
                    os_log("callWalletCardsDetailsAPI API Success: \(response)")
                        
                    guard let innerData = self.extractInnerXML(from: response) else {
                        os_log("CDATA extraction failed")
                        completion(.failure(NSError(domain: "CDATAError", code: 0)))
                        return
                    }

                    do {
                        let parser = CardXMLParser()
                        let cards = try parser.parse(data: innerData)
                            
                        os_log("cards = \(cards)")
                            
                        completion(.success(cards))

                    } catch {
                        os_log("Parsing error: \(error.localizedDescription)")
                        completion(.failure(error))
                    }

                case .failure(let error):
                    os_log("callWalletCardsDetailsAPI API Error: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func callWalletActivationAPI(
        certificates: String,
        nonce: String,
        nonceSignature: String,
        cardSuffix: String,
        completion: @escaping (Result<WalletActivationResponse, Error>) -> Void) {

        getValidToken { token in

            guard let token = token else {
                os_log("No valid token available")
                completion(.failure(NSError(domain: "TokenError", code: 0)))
                return
            }

            guard let loginSessionToken = WalletAuthManager.shared.getSessionToken() else {
                os_log("No valid session token available")
                completion(.failure(NSError(domain: "SessionTokenError", code: 0)))
                return
            }
                
            let encryptedPem = self.encryptAES(
                tranData: certificates,
                key: encryptionKey
            )
                
            let txnRef = self.generateTxnRef()
                
            let xmlString = """
                <AUB_MESSAGE>
                    <REQUEST_MESSAGE>
                        <RequestHeader>
                            <MsgType>Request</MsgType>
                            <ReqID>MB_WALLET</ReqID>
                            <ChSysID>MB_WALLET_EXT</ChSysID>
                            <FuncID>WALLET_ACTIVATION</FuncID>
                            <UserID/>
                            <TxnRef>\(txnRef)</TxnRef>
                            <CorrTxnRef />
                            <TxnDate>\(self.getTxnDate())</TxnDate>
                            <CustGrpID/>
                            <CustNIN></CustNIN>
                            <EntID>\(self.getEntityDetails().entity)</EntID>
                            <SysID/>
                            <CustID/>
                            <ProcessEntID/>
                            <OrigEntID>\(self.getEntityDetails().entity)</OrigEntID>
                            <TxnStatus>Y</TxnStatus>
                            <SessLang>E</SessLang>
                            <VerNo>0001</VerNo>
                            <SessToken>123456789</SessToken>
                            <BypassOds>Y</BypassOds>
                        </RequestHeader>
                        <RequestBody>
                            <WALLET_ACTIVATION_RQ>
                                <entityId>\(self.getEntityDetails().entity)</entityId>
                                <deviceId>\(self.getDeviceId())</deviceId>
                                <deviceModel>\(self.getDeviceModelIdentifier())</deviceModel>
                                <ipAddress>\(self.getIPAddress())</ipAddress>
                                <type>\(self.getOSType())</type>
                                <certificatePem>\(encryptedPem ?? "")</certificatePem>
                                <nonce>\(nonce)</nonce>
                                <nonceSignature>\(nonceSignature)</nonceSignature>
                                <cardSuffix>\(cardSuffix)</cardSuffix>
                                <sessionToken>\(loginSessionToken)</sessionToken>
                            </WALLET_ACTIVATION_RQ>
                        </RequestBody>
                    </REQUEST_MESSAGE>
                </AUB_MESSAGE>
                """
                
            let signedRequest = SignedRequestGenerator.createSignedRequest(
                xmlRequest: xmlString,
                token: self.getEntityDetails().signedRequestToken
            )
                
            let postData = """
                <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
                    <SOAP-ENV:Header/>
                    <s:Body xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                        <getResponse xmlns="http://middleware.webservice.aub.com">
                            <request>
                                <![CDATA[\(signedRequest ?? "")]]>
                            </request>
                        </getResponse>
                    </s:Body>
                </s:Envelope>
                """
            
            os_log("postData = \(postData)")
                
            let consumer = HTTPSConsumer()
                
            consumer.consumePOST(
                url: "\(BASE_URL)/kfh/uat/eiphandlerservice/invoke/wallet_activation",
                postData: postData,
                headers: [
                    "Authorization": token,
                    "TxnRef": txnRef,
                    "X-IBM-Client-Id": self.getEntityDetails().clientID,
                    "Content-Type": "application/xml"
                ],
                contentType: "application/xml"
            ) { result in

                switch result {
                case .success(let response):
                    os_log("callWalletActivationAPI API Success: \(response)")
                        
                    let result = self.getWalletActivationData(from: response)

                    let activationResponse = WalletActivationResponse(
                                            encryptedPassData: result.encryptedPassData,
                                            activationData: result.activationData,
                                            ephemeralPublicKey: result.ephemeralPublicKey
                                        )

                    completion(.success(activationResponse))
                        
                case .failure(let error):
                    os_log("callWalletActivationAPI API Error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func callWalletStatusUpdateAPI(suffix: String, completion: @escaping (Result<(code: String?, desc: String?), Error>) -> Void) {

        getValidToken { token in

            guard let token = token else {
                os_log("No valid token available")
                completion(.failure(NSError(domain: "TokenError", code: 0)))
                return
            }

            guard let loginSessionToken = WalletAuthManager.shared.getSessionToken() else {
                os_log("No valid session token available")
                completion(.failure(NSError(domain: "SessionTokenError", code: 0)))
                return
            }
                
            let txnRef = self.generateTxnRef()
                
            let xmlString = """
                <AUB_MESSAGE>
                    <REQUEST_MESSAGE>
                        <RequestHeader>
                            <MsgType>Request</MsgType>
                            <ReqID>MB_WALLET</ReqID>
                            <ChSysID>MB_WALLET_EXT</ChSysID>
                            <FuncID>WALLET_UPDATE_STATUS</FuncID>
                            <UserID/>
                            <TxnRef>\(txnRef)</TxnRef>
                            <CorrTxnRef />
                            <TxnDate>\(self.getTxnDate())</TxnDate>
                            <CustGrpID/>
                            <CustNIN></CustNIN>
                            <EntID>\(self.getEntityDetails().entity)</EntID>
                            <SysID/>
                            <CustID/>
                            <ProcessEntID/>
                            <OrigEntID>\(self.getEntityDetails().entity)</OrigEntID>
                            <TxnStatus>Y</TxnStatus>
                            <SessLang>E</SessLang>
                            <VerNo>0001</VerNo>
                            <SessToken>123456789</SessToken>
                            <BypassOds>Y</BypassOds>
                        </RequestHeader>
                        <RequestBody>
                            <WALLET_UPDATE_STATUS_RQ>
                                <entityId>\(self.getEntityDetails().entity)</entityId>
                                <deviceId>\(self.getDeviceId())</deviceId>
                                <deviceModel>\(self.getDeviceModelIdentifier())</deviceModel>
                                <ipAddress>\(self.getIPAddress())</ipAddress>
                                <primarySuffix>\(suffix)</primarySuffix>
                                <type>\(self.getOSType())</type>
                                <sessionToken>\(loginSessionToken)</sessionToken>
                            </WALLET_UPDATE_STATUS_RQ>
                        </RequestBody>
                    </REQUEST_MESSAGE>
                </AUB_MESSAGE>
                """
                
            let signedRequest = SignedRequestGenerator.createSignedRequest(
                xmlRequest: xmlString,
                token: self.getEntityDetails().signedRequestToken
            )
                
            let postData = """
                <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
                    <SOAP-ENV:Header/>
                    <s:Body xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                        <getResponse xmlns="http://middleware.webservice.aub.com">
                            <request>
                                <![CDATA[\(signedRequest ?? "")]]>
                            </request>
                        </getResponse>
                    </s:Body>
                </s:Envelope>
                """
                
            let consumer = HTTPSConsumer()
                
            consumer.consumePOST(
                url: "\(BASE_URL)/kfh/uat/eiphandlerservice/invoke/wallet_update_status",
                postData: postData,
                headers: [
                    "Authorization": token,
                    "TxnRef": txnRef,
                    "X-IBM-Client-Id": self.getEntityDetails().clientID
                ],
                contentType: "application/xml"
            ) { result in

                switch result {
                case .success(let response):
                    os_log("callWalletStatusUpdateAPI API Success: \(response)")
                        
                    guard let innerXML = self.extractInnerXMLString(from: response) else {
                        os_log("CDATA not found")
                        completion(.failure(NSError(domain: "CDATAError", code: 0)))
                        return
                    }

                    let code = self.extractTagValue("Code", from: innerXML)
                    let desc = self.extractTagValue("Desc", from: innerXML)

                    os_log("Code: \(code ?? "")")
                    os_log("Desc: \(desc ?? "")")
                        
                    completion(.success((code: code, desc: desc)))

                case .failure(let error):
                    os_log("callWalletStatusUpdateAPI API Error: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
}

// all common functions
extension IntentHandler {
    
    func generateTxnRef() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Set Bahrain Timezone
        formatter.timeZone = TimeZone(identifier: "Asia/Bahrain")
        
        let dateTime = formatter.string(from: Date())
        
        // Generate 4 random digits
        let randomNumber = String(format: "%04d", Int.random(in: 0...9999))

        return "RI\(dateTime)\(randomNumber)"
    }

    func getTxnDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Set Bahrain timezone (UTC+3)
        formatter.timeZone = TimeZone(identifier: "Asia/Bahrain")
        
        return formatter.string(from: Date())
    }

    func getDeviceId() -> String {
        let deviceid = UIDevice.current.identifierForVendor?.uuidString ?? "UNKNOWN_DEVICE_ID"
        return deviceid
    }

    func getDeviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }

    func getOSType() -> String {
        var osType = "Mobile"
        #if os(watchOS)
            osType = "Watch"
        #else
            osType = "Mobile"
        #endif
        return osType
    }

    func getIPAddress() -> String {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                let interface = ptr!.pointee

                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                    let name = String(cString: interface.ifa_name)

                    // Wi-Fi: en0 | Cellular: pdp_ip0
                    if name == "en0" || name == "pdp_ip0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(
                            interface.ifa_addr,
                            socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            0,
                            NI_NUMERICHOST
                        )
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address ?? "0.0.0.0"
    }
    
    func encryptAES(tranData: String, key: String) -> String? {
        
        guard let data = tranData.data(using: .utf8),
              let keyData = key.data(using: .utf8),
              let ivData = ivString.data(using: .utf8) else {
            return nil
        }
     
        let outputLength = data.count + kCCBlockSizeAES128
        var outputData = Data(count: outputLength)
     
        var bytesEncrypted = 0
     
        let status = outputData.withUnsafeMutableBytes { outputBytes in
            data.withUnsafeBytes { dataBytes in
                keyData.withUnsafeBytes { keyBytes in
                    ivData.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress,
                            keyData.count, // 16=AES128, 32=AES256
                            ivBytes.baseAddress,
                            dataBytes.baseAddress,
                            data.count,
                            outputBytes.baseAddress,
                            outputLength,
                            &bytesEncrypted
                        )
                    }
                }
            }
        }
     
        guard status == kCCSuccess else {
            os_log("Encryption failed")
            return nil
        }
     
        outputData.removeSubrange(bytesEncrypted..<outputData.count)
     
        // Swift AES output → Base64
        let base64String = outputData.base64EncodedString()
     
        // Convert Base64 → Hex (same as CryptoJS flow)
        guard let base64Data = Data(base64Encoded: base64String) else { return nil }
     
        let hexString = base64Data.map { String(format: "%02X", $0) }.joined()
        return hexString
    }
}

// token API and check valid token
extension IntentHandler {

    func getValidToken(completion: @escaping (String?) -> Void) {

        // If valid stored token exists → use it
        if let token = WalletAuthManager.shared.getStoredValidToken() {
            os_log("token saved = \(token)")
            completion(token)
            return
        }

        // Otherwise fetch new token
        getTokenAPI { newToken in
            os_log("new toen refresh = \(newToken ?? "no new token")")
            completion(newToken)
        }
    }
    
    func getTokenAPI(completion: @escaping (String?) -> Void) {

        let consumer = HTTPSConsumer()

        consumer.consumeGET(
            url: "\(BASE_URL)/kfh/uat/auth/token",
            headers: [
                "X-IBM-Client-Id": getEntityDetails().clientID,
                "X-IBM-Client-Secret": getEntityDetails().clientSecret,
                "TxnRef": generateTxnRef()
            ]
        ) { result in

            switch result {

            case .success(let responseString):

                guard let data = responseString.data(using: .utf8) else {
                    completion(nil)
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
                    WalletAuthManager.shared.saveToken(decoded)

                    completion(decoded.token)

                } catch {
                    os_log("Decoding Error: \(error.localizedDescription)")
                    completion(nil)
                }

            case .failure(let error):
                os_log("Token API Error: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}

// for getting data from all XML API responses
extension IntentHandler {
    
    func extractSessionToken(from soapResponse: String) -> String? {
        
        // 1️⃣ Extract CDATA
        guard let cdataStart = soapResponse.range(of: "<![CDATA["),
              let cdataEnd = soapResponse.range(of: "]]>") else {
            return nil
        }
        
        let innerXML = String(soapResponse[cdataStart.upperBound..<cdataEnd.lowerBound])
        
        // 2️⃣ Extract <sessionToken> using simple range search (fast & clean)
        guard let start = innerXML.range(of: "<sessionToken>"),
              let end = innerXML.range(of: "</sessionToken>") else {
            return nil
        }
        
        let token = innerXML[start.upperBound..<end.lowerBound]
        return String(token)
    }
    
    func getWalletActivationData(from soap: String) -> (encryptedPassData: String?, activationData: String?, ephemeralPublicKey: String?) {
        
        // Step 1: Extract CDATA
        guard let cdataStart = soap.range(of: "<![CDATA["),
              let cdataEnd = soap.range(of: "]]>") else {
            return (nil, nil, nil)
        }
        
        let innerXML = String(soap[cdataStart.upperBound..<cdataEnd.lowerBound])
        
        // Step 2: Generic tag extractor
        func extract(_ tag: String) -> String? {
            let pattern = "<\(tag)>(.*?)</\(tag)>"
            
            guard let regex = try? NSRegularExpression(
                pattern: pattern,
                options: [.dotMatchesLineSeparators]
            ) else { return nil }
            
            let range = NSRange(innerXML.startIndex..., in: innerXML)
            
            if let match = regex.firstMatch(in: innerXML, options: [], range: range),
               let valueRange = Range(match.range(at: 1), in: innerXML) {
                return String(innerXML[valueRange])
            }
            return nil
        }
        
        // Step 3: Extract required values
        return (
            encryptedPassData: extract("encryptedPassData"),
            activationData: extract("activationData"),
            ephemeralPublicKey: extract("ephemeralPublicKey")
        )
    }
    
    func extractInnerXML(from soapString: String) -> Data? {

        guard let start = soapString.range(of: "<![CDATA[")?.upperBound,
              let end = soapString.range(of: "]]>")?.lowerBound else {
            return nil
        }

        let innerXML = String(soapString[start..<end])
        return innerXML.data(using: .utf8)
    }

    func extractInnerXMLString(from soapString: String) -> String? {
        guard let start = soapString.range(of: "<![CDATA[")?.upperBound,
              let end = soapString.range(of: "]]>")?.lowerBound else {
            return nil
        }
        return String(soapString[start..<end])
    }

    func extractTagValue(_ tag: String, from xml: String) -> String? {
        guard let start = xml.range(of: "<\(tag)>")?.upperBound,
              let end = xml.range(of: "</\(tag)>")?.lowerBound else {
            return nil
        }
        return String(xml[start..<end])
    }
}

class CardXMLParser: NSObject, XMLParserDelegate {

    private var currentElement = ""
    private var currentCard: Card?
    private var currentValue = ""

    private(set) var cards: [Card] = []
    private var txnStatus = ""
    private var returnCode = ""
    private var returnDesc = ""

    // MARK: - Parser

    func parse(data: Data) throws -> [Card] {

        let parser = XMLParser(data: data)
        parser.delegate = self

        if parser.parse() {

            guard txnStatus == "Y", returnCode == "00000" else {
                throw NSError(domain: returnDesc, code: 0)
            }

            return cards
        } else {
            throw parser.parserError ?? NSError(domain: "XML Parse Error", code: 0)
        }
    }

    // MARK: - XML Delegates

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {

        currentElement = elementName
        currentValue = ""

        if elementName == "Card" {
            currentCard = Card()
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {

        switch elementName {

        case "TxnStatus":
            txnStatus = currentValue

        case "Code":
            returnCode = currentValue

        case "Desc":
            returnDesc = currentValue

        case "cardId":
            currentCard?.cardId = currentValue

        case "maskedCardNumber":
            currentCard?.maskedCardNumber = currentValue

        case "artUrl":
            currentCard?.artUrl = currentValue

        case "cardTitle":
            currentCard?.cardTitle = currentValue

        case "holderName":
            currentCard?.holderName = currentValue

        case "Card":
            if let card = currentCard {
                cards.append(card)
            }

        default:
            break
        }
    }
}

final class SignedRequestGenerator {

    /// Equivalent to MssCreate_SignedRequest
    static func createSignedRequest(
        xmlRequest: String,
        token: String
    ) -> String? {
        
        // 1️⃣ Normalize XML (remove formatting / line breaks)
        guard let oneLineXML = normalizeXML(xmlRequest) else {
            return nil
        }

        // 2️⃣ Clear SessToken value
        let clearedXML = oneLineXML.replacingOccurrences(
            of: "<SessToken.*?>.*?</SessToken>",
            with: "<SessToken></SessToken>",
            options: .regularExpression
        )

        // 3️⃣ Generate signature
        guard let signedToken = generateHash(
            maskedToken: token,
            request: clearedXML
        ) else {
            return nil
        }

        // 4️⃣ Inject signature back into XML
        let signedRequest = clearedXML.replacingOccurrences(
            of: "<SessToken></SessToken>",
            with: "<SessToken>\(signedToken)</SessToken>"
        )

        return signedRequest
    }
    
    private static func normalizeXML(_ xml: String) -> String? {
        let xmlData = xml.data(using: .utf8)
        let parser = XMLParser(data: xmlData ?? Data())
        parser.shouldProcessNamespaces = false
        parser.shouldResolveExternalEntities = false
        parser.shouldReportNamespacePrefixes = false

        // Simply remove newlines & extra spaces
        return xml
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: "  ", with: "")
    }

    /// Equivalent to GenerateHash
    private static func generateHash(
        maskedToken: String,
        request: String
    ) -> String? {
        
        guard let keyData = decodeBase64(maskedToken),
              let messageData = request.data(using: .utf8) else {
            return nil
        }

        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(
            for: messageData,
            using: key
        )

        return Data(signature).base64EncodedString()
    }
    
    private static func decodeBase64(_ base64: String) -> Data? {
        var padded = base64
        let remainder = base64.count % 4
        if remainder > 0 {
            padded += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: padded)
    }
}

final class HTTPSessionDelegate: NSObject, URLSessionDelegate {

    private let identity: SecIdentity?

    init(identity: SecIdentity?) {
        self.identity = identity
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate,
           let identity = identity {

            let credential = URLCredential(
                identity: identity,
                certificates: nil,
                persistence: .forSession
            )

            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

final class HTTPSConsumer {

    private func createSession(identity: SecIdentity?) -> URLSession {

            let config = URLSessionConfiguration.default

            // iOS / macOS allow TLS 1.2+ only
            if #available(iOS 13.0, macOS 10.15, *) {
                config.tlsMinimumSupportedProtocolVersion = .TLSv12
            }

            let delegate = HTTPSessionDelegate(identity: identity)
            return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        }

        func consumeGET(
            url: String,
            headers: [String: String] = [:],
            contentType: String = "application/x-www-form-urlencoded",
            completion: @escaping (Result<String, Error>) -> Void
        ) {

            guard let identity = getIdentityFromData() else {
                completion(.failure(NSError(domain: "IdentityNotFound", code: -1)))
                return
            }

            guard let requestURL = URL(string: url) else {
                completion(.failure(NSError(domain: "InvalidURL", code: -1)))
                return
            }

            var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")

            headers.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)
            }

            let session = createSession(identity: identity)

            session.dataTask(with: request) { data, _, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let response = String(decoding: data ?? Data(), as: UTF8.self)
                    completion(.success(response))
                }
            }.resume()
        }

        func consumePOST(
            url: String,
            postData: String,
            headers: [String: String] = [:],
            contentType: String = "application/x-www-form-urlencoded",
            completion: @escaping (Result<String, Error>) -> Void
        ) {
            
            guard let identity = getIdentityFromData() else {
                completion(.failure(NSError(domain: "IdentityNotFound", code: -1)))
                return
            }

            guard let requestURL = URL(string: url) else {
                completion(.failure(NSError(domain: "InvalidURL", code: -1)))
                return
            }

            var request = URLRequest(url: requestURL)
            request.httpMethod = "POST"
            request.httpBody = postData.data(using: .utf8)
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")

            headers.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)
            }

            let session = createSession(identity: identity)

            session.dataTask(with: request) { data, _, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let response = String(decoding: data ?? Data(), as: UTF8.self)
                    completion(.success(response))
                }
            }.resume()
        }
        
        func getIdentityFromData() -> SecIdentity? {
            
            guard let content = WalletAuthManager.shared.getIdentityContent() else {
                os_log("no content from keychain")
                return nil
            }
            
            os_log("identity data from keychain= \(content.count)")
            
            // ✅ Base64 → Data
            guard let pfxData = Data(base64Encoded: content) else {
                print("❌ Invalid Base64")
                return nil
            }
            
            let options: [String: Any] = [
                kSecImportExportPassphrase as String: certPassword
            ]

            var items: CFArray?

            let status = SecPKCS12Import(pfxData as CFData, options as CFDictionary, &items)

            guard status == errSecSuccess else {
                print("❌ PKCS12 import failed:", status)
                return nil
            }

            guard let array = items as? [[String: Any]],
                let first = array.first,
                let identity = first[kSecImportItemIdentity as String] else {
                
                print("❌ Identity extraction failed")
                return nil
            }
            
            print("identity extracted = ", identity)

            return (identity as! SecIdentity)
        }
}

// for auth token save and clear user defaults related to auth token
class WalletAuthManager {

    static let shared = WalletAuthManager()

    private var tokenKey: String { "AUTH_TOKEN" }
    private var expiryKey: String { "AUTH_TOKEN_EXPIRY" }
    private var sessionTokenKey: String { "SESSION_TOKEN" }
    private var identityContentKey: String { "IDENTITY_CONTENT_TOKEN" }

    func saveToken(_ response: TokenResponse) {

        let expiresIn = TimeInterval(response.expires_in) ?? 3600

        let expiryDate = Date().addingTimeInterval(expiresIn - 300)

        KeychainHelper.save(key: tokenKey, value: response.token)
        KeychainHelper.save(key: expiryKey, value: "\(expiryDate.timeIntervalSince1970)")
    }

    func getStoredValidToken() -> String? {

        guard let token = KeychainHelper.read(key: tokenKey),
              let expiryString = KeychainHelper.read(key: expiryKey),
              let expiryTime = Double(expiryString) else {
            return nil
        }

        if Date().timeIntervalSince1970 < expiryTime {
            return token
        } else {
            clearToken()
            return nil
        }
    }

    func clearToken() {
        KeychainHelper.delete(key: tokenKey)
        KeychainHelper.delete(key: expiryKey)
    }

    func saveSessionToken(_ token: String) {
        KeychainHelper.save(key: sessionTokenKey, value: token)
    }

    func getSessionToken() -> String? {
        return KeychainHelper.read(key: sessionTokenKey)
    }

    func clearSessionToken() {
        KeychainHelper.delete(key: sessionTokenKey)
    }
        
    func getIdentityContent() -> String? {
        return KeychainHelper.read(key: identityContentKey)
    }
}

class KeychainHelper {

    static func save(key: String, value: String) {
        let data = value.data(using: .utf8)!

        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: appGroupID
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            os_log("Keychain save error: \(status)")
        }
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: appGroupID
        ]

        var dataTypeRef: AnyObject?

        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }

        os_log("Keychain read error: \(status)")
        return nil
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: appGroupID
        ]

        SecItemDelete(query as CFDictionary)
    }
}


