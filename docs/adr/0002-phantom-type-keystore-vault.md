# 2. One generic Keystore vault with a phantom type

Date: 2026-10-02

## Status

Accepted

## Context

`Keystore` stored software keys. Secure Enclave keys have stricter rules: P-256
only, `ThisDeviceOnly` protections only, `.privateKeyUsage` always set, and no
import of private keys. With one non-generic class, a caller could ask for an
RSA key in the Secure Enclave and find out only at runtime.

## Decision

`Keystore` is a namespace. `Keystore.Vault<B: Keystore.Backing>` holds the
shared code: tag mapping, load and delete. The marker types `Keystore.Standard`
and `Keystore.SecureEnclave` carry no data. Constrained extensions
(`where B == …`) add the initializers and methods that are valid for each kind.
`Keystore.StandardVault` and `Keystore.SecureEnclaveVault` are typealiases.

## Consequences

- Invalid combinations do not compile: a key type or an import on a Secure
  Enclave vault, a protection that is not `ThisDeviceOnly`, a policy that
  disagrees with the access control.
- Swift has no stored static properties in generic types, so the defaults live
  on the namespace: `Keystore.standard` and `Keystore.secureEnclave`.
- Inside `Vault`, the names `AccessControl`, `Protection` and `Error` resolve to
  the inherited `Keychain` members. Code in `Vault` writes `Keystore.…` in full.
- A third kind of key means a new marker and a new constrained extension. The
  shared code does not change.

## Alternatives considered

- **Runtime validation on the existing class.** Smallest diff, but every wrong
  combination is a runtime error.
- **Two sibling classes.** Same compile-time safety, but two public names for
  one concept, and the shared code needs a base class or protocol anyway.
- **A CryptoKit `SecureEnclave.P256` wrapper.** Modern Swift API, but CryptoKit
  has no ECIES, so encryption would need a hand-built ECDH + HKDF + AES-GCM
  format, and the types would differ from the `SecKey` used everywhere else.
