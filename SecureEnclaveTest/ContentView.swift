//
//  ContentView.swift
//  SecureEnclaveTest
//
//  Created by Georg Wechslberger on 15.11.21.
//

import SwiftUI
import CryptoKit
import CryptoTokenKit
import os.log

struct ContentView: View {
    @State private var createResult = ""
    @State private var errorDescription = ""
    @State private var tkErrorCode = 0
    var body: some View {
        VStack {
            Text("Secure Enclave KeyGen Test")
                .padding()
            Text(createResult)
                .textSelection(EnabledTextSelectability.enabled)
            if tkErrorCode != 0 {
                Text("error code: " + tkErrorCode.formatted())
                    .textSelection(EnabledTextSelectability.enabled)
            }
            if errorDescription != "" {
                Text("error desc: " + errorDescription)
                    .textSelection(EnabledTextSelectability.enabled)
            }
            Button("create key", action: createKey)
                .padding()
        }
    }
    
    func createKey() {
        // Create access control flags for a private key that requires biometric authentication.
        var accessControlFlags = SecAccessControlCreateFlags.init()
        accessControlFlags.insert(SecAccessControlCreateFlags.biometryAny)
        accessControlFlags.insert(SecAccessControlCreateFlags.privateKeyUsage)
        
        // Create access control with the just created flags.
        var error: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            accessControlFlags,
            &error
        ) else {
            createResult = "creating access control failed"
            return
        }
        // Create the key in the secure enclave.
        do {
            try SecureEnclave.P256.Signing.PrivateKey.init(
                compactRepresentable: false, accessControl: access)
            createResult = "key created successfully"
        } catch let error as TKError {
            // Extract the error code and the corresponding description.
            tkErrorCode = error.errorCode
            createResult = error.localizedDescription
            switch error.code {
            case .notImplemented:
                errorDescription = "not implemented"
            case .communicationError:
                errorDescription = "communication error"
            case .corruptedData:
                errorDescription = "corrupted data"
            case .canceledByUser:
                errorDescription = "canceled by user"
            case .authenticationFailed:
                errorDescription = "authentication failed"
            case .objectNotFound:
                errorDescription = "object not found"
            case .tokenNotFound:
                errorDescription = "token not found"
            case .badParameter:
                errorDescription = "bad parameter"
            case .authenticationNeeded:
                errorDescription = "authentication needed"
            @unknown default:
                errorDescription = "unknown"
            }
        } catch {
            createResult = "unexpected error"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
