# SecureNotes

## Welcome to SecureNotes. 

SecureNotes lets the user store text notes securely. All notes are encrypted with **AES-GCM** 256 before being stored in the database.

The key to decrypt notes is formed by the user's password; therefore, only the user can decrypt the saved notes.

### Demo
Click on image below for the product video demo.

[![SecureNotes Demo](http://img.youtube.com/vi/v5ToKgt-rOU/0.jpg)](http://www.youtube.com/watch?v=v5ToKgt-rOU)

### Supported platforms & Set up

* iOS 13 and later.
* Xcode 12 and later.

### Set up
The [Cocoapods dependency manager](https://cocoapods.org/) is required to set up the project dependencies.

If Cocoapods is already available, then download the SecureNotes project from Github and run the below command.

```
cd SecureNotes
pod install
```

## Features & Cryptography

### Cryptography Used

* AES-GCM
* AES-CBC
* SHA256
* SHA512
* eciesEncryptionCofactorVariableIVX963SHA256AESGCM


### Register, Key forming
```
salt = random(32 bytes) // To be encrypted by ecies and stored in db
data = Data(salt+username+pin)
iv = random(32 bytes) // To be encrypted by ecies and stored in db
key = data.sha256()
aes = AES-GCM(key, iv)

hash = data.sha512() // To be encrypted by ecies and stored in db
```
> For demonstration purposes, sha256 is used to derive the key. However, PBKDF2 should be used to protect against brute force.

After successful login/registering, the **AES-GCM key**  will be formed and stay **encrypted** in the memory during the active session by Secure Enclave **eciesEncryptionCofactorVariableIVX963SHA256AESGCM** (EC*). It acts as a caching algorithm to be re-used multiple times without additional login from the user. If the application is transitioned to background or is terminated, the encrypted **EC(AES-GCM key, IV)** will be wiped out from memory.

```
SecureEnclave.generateKeyPair()
// Caching keys in memory
encrypted = SecureEnclave.encrypt(key)
encrypted = SecureEncalve.encrypt(IV)
```

### Login with username + pin

```
encryptedSalt = datbase(encryptedSalt)
salt = SecureEnclave.decrypt(encryptedSalt)

encryptedHash = datbase(encryptedHash)
hash = SecureEnclave.decrypt(encryptedHash)

data = Data(salt+username+pin)
loginHash = data.sha512()

if loginHash == hash {
    key = data.sha256()
    encryptedKey = SecureEnclave.encrypt(key)
    encryptedIV = Database(encryptedIV)
} else {
    //Wrong Username or Password
}

```

### Enable Biometric

The biometric authentication mode is not activated by default.

The **EC(AES-GCM key)** will need to be securely stored in the database if the user wants to use the '*login with the Biometric*' feature

First, the system generates a new random **AES-CBC** symmetric key.

Once the new **AES-CBC** key is created, the **EC(AES-GCM key)** will be encrypted with **AES-CBC** key

The final **AES-CBC(EC(AES-GCM key))** will be stored in the database for later access.

The new **AES-CBC** symmetric key to decrypt the **AES-CBC(EC(AES-GCM key))** will be locked inside Keychain and only be accessible with the user's presence (Biometrics authentication)

```
bioIV = random(16 bytes) // To be encrypted by ecies and stored in db
bioKey = random(16 bytes)
bioServiceId = random(32 bytes) // To be encrypted by ecies and stored in db

// Store AES-CBC key to the keychain that requires user's presence
KeyChainBiometric.add(bioKey, serviceId: bioServiceId)

aes = AES-CBC(bioIV, bioKey)
encryptedMasterKey = aes.encrypt(encryptedKey) // To store in db
```

### Login with Biometric

```
encryptedBioServiceId = Database(encryptedBioServiceId)
bioServiceId = SecureEnclave.decrypt(encryptedBioServiceId)

encryptedBioIV = Database(encryptedBioIV)
bioIV = SecureEnclave.decrypt(encryptedBioIV)

// This key requires the user's presence to read
bioKey = KeyChainBiometric.read(bioServiceId)

aes = AES-CBC(bioIV, bioKey)
encryptedMasterKey = Database(encryptedMasterKey)

// Caching keys in memory
encryptedKey = aes.decrypt(encryptedMasterKey)
encryptedIV = Database(encryptedIV)
```

## Security Discussion:
The application has been enforced by some security protections in the RELEASE build:
* Show warning to jailbreak devices
* Anti-debug for some important functions
* Anti-hook for some important functions

Below methods can be implemented for the application's further protection:
* Hide hardcoded strings, add more control flows and rename sensitive functions/variables to hide attack points during static analysis.
* Add a secure keypad to protect the pin against the keyboard logger.
* Add anti-tampering.
* Use MEDL and Zcrambler to implement RASP.

## Testing
Because of the time constraints, automatic tests are not included.
