/**
 * Utility class for integrating with the Percipia Nexus hospitality platform.
 * Handles HTTP communication with the Nexus endpoint to fetch and cache guest extension parameters,
 * including restrictions for guest-to-guest calling, guest-to-admin messaging, and conversation access.
 *
 * Authored by Maj Kravos <https://www.majkravos.com>
 */

import Foundation
import linphonesw

private class InsecureSSLDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

final class PercipiaNexus {
    private static let TAG = "[Percipia Nexus]"
    
    // Nexus server
    private static let ENDPOINT = "getConnectParams"
    private static let PORT = "8443"
    
    // WARNING: Only enable for lab testing with self-signed certificates, do not use in prod
    private static let SKIP_SSL_VERIFICATION = true
    
    private static let client: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        
        if SKIP_SSL_VERIFICATION {
            Log.warn("\(TAG) SSL certificate verification is DISABLED - only use for testing!")
            let delegate = InsecureSSLDelegate()
            return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        } else {
            return URLSession(configuration: config)
        }
    }()

    private static let paramsCache = NSLock()
    private static var paramsCacheDict = [String: CachedConnectParams]()
    private static let CACHE_EXPIRY_S: TimeInterval = 60 // 1 minute to account for Nexus rate limiting

    // Struct to hold Frequency Connect config parameters fetched from Nexus
    struct ConnectParams {
        let isGuest: Bool
        let isGuestToAdminMessagingEnabled: Bool
        let isGuestToGuestCallingEnabled: Bool
    }

    // Struct to hold cached connect params along with timestamp
    private struct CachedConnectParams {
        let params: ConnectParams
        let timestamp: TimeInterval
    }

    private static func resolveHostname(_ hostname: String) -> String {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        
        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(hostname, nil, &hints, &result) == 0,
            let addrinfo = result else {
            return hostname
        }
        defer { freeaddrinfo(result) }
        
        // Convert first result to IP string
        var current = addrinfo
        while true {
            let addr = current.pointee
            
            if addr.ai_family == AF_INET {
                var ip = sockaddr_in()
                memcpy(&ip, addr.ai_addr, Int(addr.ai_addrlen))
                if let ipString = String(cString: inet_ntoa(ip.sin_addr), encoding: .utf8) {
                    return ipString
                }
            }
            
            guard let next = current.pointee.ai_next else { break }
            current = next
        }
        
        return hostname
    }
    
    private static func getPbxAddress(account: Account) -> String? {
        guard let params = account.params else { return nil }
        
        // serverAddress is an Address object, extract domain from it
        guard let serverAddress = params.serverAddress else { return nil }
        guard let domain = serverAddress.domain else { return nil }
        
        return resolveHostname(domain)
    }
    
    private static func getPbxDomain(account: Account) -> String? {
        guard let params = account.params else {
            return nil
        }
        guard let serverAddress = params.serverAddress else {
            return nil
        }
        guard let domain = serverAddress.domain else {
            return nil
        }
        return domain
    }
    
    private static func getExtensionNumber(account: Account) -> String? {
        return account.params?.identityAddress?.username
    }
    
    private static func getAccountForExtension(extensionNumber: String) -> Account? {
        return CoreContext.shared.mCore.accountList.first {
            $0.params?.identityAddress?.username == extensionNumber
        }
    }
    
    private static func isCacheValid(cachedParams: CachedConnectParams) -> Bool {
        return Date().timeIntervalSince1970 - cachedParams.timestamp < CACHE_EXPIRY_S
    }
    
    private static func getCachedParams(forExtension ext: String) -> ConnectParams? {
        paramsCache.lock()
        defer { paramsCache.unlock() }
        
        if let cached = paramsCacheDict[ext], isCacheValid(cachedParams: cached) {
            return cached.params
        }
        return nil
    }
    
    private static func setCachedParams(_ params: ConnectParams, forExtension ext: String) {
        paramsCache.lock()
        defer { paramsCache.unlock() }
        
        paramsCacheDict[ext] = CachedConnectParams(
            params: params,
            timestamp: Date().timeIntervalSince1970
        )
    }

    private static func getConnectParams(account: Account, forExtension targetExtension: String? = nil) async -> ConnectParams? {
        guard let pbxAddress = getPbxAddress(account: account) else { return nil }
        guard let domain = getPbxDomain(account: account) else { return nil }
        
        // Use provided extension or extract from account
        let extensionNumber: String
        if let targetExtension = targetExtension {
            extensionNumber = targetExtension
        } else {
            guard let ext = getExtensionNumber(account: account) else { return nil }
            extensionNumber = ext
        }
        
        let urlString = "https://\(pbxAddress):\(PORT)/\(ENDPOINT)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let encodedDomain = domain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? domain
        let encodedExtension = extensionNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? extensionNumber
        let formBody = "domain=\(encodedDomain)&extension=\(encodedExtension)"
        request.httpBody = formBody.data(using: .utf8)
        
        do {
            let (data, response) = try await client.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else { return nil }
            guard httpResponse.statusCode == 200 else {
                Log.error("\(TAG) Failed to fetch connect params: \(httpResponse.statusCode)")
                return nil
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                Log.error("\(TAG) Response is not a JSON object for extension [\(extensionNumber)]")
                return nil
            }
            
            return ConnectParams(
                isGuest: json["is_guest_extension"] as? Bool ?? false,
                isGuestToAdminMessagingEnabled: json["is_guest_to_admin_messaging_enabled"] as? Bool ?? false,
                isGuestToGuestCallingEnabled: json["is_guest_to_guest_calling_enabled"] as? Bool ?? false
            )
        } catch {
            Log.error("\(TAG) Failed to fetch connect params: \(error.localizedDescription)")
            return nil
        }
    }
    
    private static func getConnectParamsForExtension(ext: String?) async -> ConnectParams? {
        guard let ext = ext else {
            Log.error("\(TAG) Extension is null")
            return nil
        }
        
        // Check cache first
        if let cached = getCachedParams(forExtension: ext) {
            Log.debug("\(TAG) Using cached connect params for extension [\(ext)]")
            return cached
        }
        
        // Try to get account for this extension
        if let account = getAccountForExtension(extensionNumber: ext) {
            let params = await getConnectParams(account: account)
            
            // Cache the result
            if let params = params {
                setCachedParams(params, forExtension: ext)
            }
            
            return params
        }
        
        // No local account found, try to fetch using any available account's PBX IP
        Log.debug("\(TAG) No local account found for extension [\(ext)], attempting to fetch using default account's PBX IP")
        if let defaultAccount = CoreContext.shared.mCore.defaultAccount {
            let params = await getConnectParams(account: defaultAccount, forExtension: ext)
            
            // Cache the result
            if let params = params {
                setCachedParams(params, forExtension: ext)
            }
            
            return params
        }
        
        Log.error("\(TAG) No account available to fetch params for extension [\(ext)]")
        return nil
    }

    static func chatPageEnabledForExtension(_ ext: String?) async -> Bool {
        let params = await getConnectParamsForExtension(ext: ext)

        if let params = params, params.isGuest && !params.isGuestToAdminMessagingEnabled {
            Log.info("\(TAG) Guest without admin messaging rights - disabling conversations page")
            return false
        }
        return true
    }
    
    static func outgoingChatAllowed(fromExtension: String?, toExtension: String?, isGroupChat: Bool) async -> Bool {
        Log.info("\(TAG) outgoingChatAllowed - fromExtension: \(fromExtension ?? "nil"), toExtension: \(toExtension ?? "nil"), isGroupChat: \(isGroupChat)")
        
        let fromExtensionParams = await getConnectParamsForExtension(ext: fromExtension)
        let toExtensionParams = await getConnectParamsForExtension(ext: toExtension)
        
        Log.info("\(TAG) fromExtensionParams - isGuest: \(fromExtensionParams?.isGuest ?? false), toExtensionParams - isGuest: \(toExtensionParams?.isGuest ?? false)")
        
        if let fromExtensionParams = fromExtensionParams, let toExtensionParams = toExtensionParams {
            if fromExtensionParams.isGuest && toExtensionParams.isGuest {
                Log.warn("\(TAG) Guest extension [\(fromExtension ?? "")] is not allowed to message extension [\(toExtension ?? "")] because it is another guest extension")
                return false
            } else if fromExtensionParams.isGuest && isGroupChat {
                Log.warn("\(TAG) Guest extension [\(fromExtension ?? "")] is not allowed to create group chats")
                return false
            } else if fromExtensionParams.isGuest && !fromExtensionParams.isGuestToAdminMessagingEnabled {
                Log.warn("\(TAG) Guest extension [\(fromExtension ?? "")] is not allowed to message admin extension [\(toExtension ?? "")] because guest-to-admin messaging is disabled")
                return false
            } else {
                return true
            }
        } else {
            Log.warn("\(TAG) fromExtensionParams or toExtensionParams is null, allowing outgoing message by default")
            return true
        }
    }
    
    static func outgoingCallAllowed(fromExtension: String?, toExtension: String?) async -> Bool {
        let fromExtensionParams = await getConnectParamsForExtension(ext: fromExtension)
        let toExtensionParams = await getConnectParamsForExtension(ext: toExtension)
        
        if let fromExtensionParams = fromExtensionParams, let toExtensionParams = toExtensionParams {
            if fromExtensionParams.isGuest && toExtensionParams.isGuest && !fromExtensionParams.isGuestToGuestCallingEnabled {
                Log.warn("\(TAG) Guest extension [\(fromExtension ?? "")] is not allowed to call extension [\(toExtension ?? "")] because guest-to-guest calling is disabled")
                return false
            } else {
                return true
            }
        } else {
            Log.warn("\(TAG) fromExtensionParams or toExtensionParams is null, allowing outgoing call by default")
            return true
        }
    }
    
    static func getHttpClient() -> URLSession {
        return client
    }
}
