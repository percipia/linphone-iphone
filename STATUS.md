# Frequency Connect iPhone — Project Status

## Current branch

- Repository: `percipia/linphone-iphone`
- Branch: `fix/account-contract-restoration`
- Baseline: pre-June upstream stabilization plus the account-contract and
  explicit-proxy fixes in builds 12–13. QR provisioning is prepared as version
  `6.2.0` build `14`.

## QR provisioning — accepted 2026-08-24

- Live registration evidence showed QR-provisioned extension `107` reaching
  Kamailio as `107@sip.percipia.net`; the served tenant identity is
  `107@sheboyg.percipia.net`, so digest authentication could not complete.
- Fusion's stored device fields were correct, but the former Linphone template
  conflated `server_address` (the Kamailio edge) with the tenant identity and
  digest domain. The corrected server package is deployed and documented under
  `/Users/ghost/Projects/sip-proxy/poc/fusionpbx-linphone-qr/`.
- Restored the applicable source changes from upstream commit `6f012274` (`Fix
  qr code scanner`): preserve the assistant while scanning, listen for the
  actual provisioning completion state, and show success only after Linphone
  reports configuration success.
- Verification: `git diff --check` passes and a Debug generic iOS Simulator
  build of scheme `Linphone` succeeds. Existing unrelated compiler/build-setting
  warnings remain.
- App commit `b2273fc0` is pushed to `origin/fix/account-contract-restoration`
  as Frequency Connect `6.2.0` build `14`. Merl removed the failed account,
  scanned the live Fusion QR, and confirmed immediate provisioning success;
  Kamailio challenged `107@sheboyg.percipia.net` and stored its push token.

## Next release step

1. Complete the normal archive/TestFlight workflow for build 14.
2. Perform a TestFlight QR scan regression after installation.
3. Package the Fusion template and the broader Frequency server delta into the
   durable Frequency deployment repository.

## Table Mountain private-CA trust — staged 2026-09-01

- Extracted and verified the public `TMC-CERT-CA` root from Table Mountain's
  returned PKCS#7 package. Its SHA-256 fingerprint is
  `BD:22:86:F7:C1:E5:68:4D:C8:BD:3C:2C:79:6B:76:AE:7A:0C:FD:41:95:5C:B3:65:AA:86:10:BD:68:45:66:EE`.
- Bundled that public root as `TMC-CERT-CA.pem`. `CoreContext` now combines it
  with Liblinphone's existing public root set through `Core.rootCaData` before
  starting the core. Certificate and hostname verification remain enabled.
- A Debug generic iOS Simulator build succeeds, and the built app contains
  both the SDK `rootca.pem` and the exact TMC root resource.
- The replacement server leaf is valid for
  `frequency-connect.tmcasino.local` and verifies directly against the TMC
  root. Its public key differs from the earlier wrong-name leaf, so Percipia05
  required a matching replacement private key. Douglas restored the matching
  August 27 key on Percipia05, started Kamailio successfully, and verified that
  the live `:5061` listener presents the expected replacement fingerprint
  beginning `EA:16:AF:B7`.
- The app trust change is included on branch
  `fix/account-contract-restoration` for Frequency Connect `6.2.0` build `14`.
  Archive/TestFlight installation and a real Table Mountain TLS registration
  test remain pending.
