# Frequency Connect iPhone — Project Status

## Current branch

- Repository: `percipia/linphone-iphone`
- Branch: `fix/account-contract-restoration`
- Baseline: pre-June upstream stabilization plus the account-contract and
  explicit-proxy fixes in builds 12–13. QR provisioning is prepared as version
  `6.2.0` build `14`.

## QR provisioning — in progress 2026-08-23

- Live registration evidence showed QR-provisioned extension `107` reaching
  Kamailio as `107@sip.percipia.net`; the served tenant identity is
  `107@sheboyg.percipia.net`, so digest authentication could not complete.
- Fusion's stored device fields are correct. The installed Linphone provisioning
  template conflates `server_address` (the Kamailio edge) with the identity and
  digest domain and calculates HA1 against the wrong realm. The server-side POC
  is in `/Users/ghost/Projects/sip-proxy/poc/fusionpbx-linphone-qr/` and has not
  been deployed.
- Restored the applicable source changes from upstream commit `6f012274` (`Fix
  qr code scanner`): preserve the assistant while scanning, listen for the
  actual provisioning completion state, and show success only after Linphone
  reports configuration success.
- Verification: `git diff --check` passes and a Debug generic iOS Simulator
  build of scheme `Linphone` succeeds. Existing unrelated compiler/build-setting
  warnings remain.

## Next acceptance step

1. Review, add backup/hash guards, and install the Fusion Linphone template
   change.
2. Render extension 107 provisioning XML and verify identity/realm
   `sheboyg.percipia.net`, edge route `sip.percipia.net:5061;transport=tls`, and
   no clear-text password.
3. Build/install Frequency Connect on a device, scan a newly generated QR code,
   and confirm Kamailio records a successful 107 registration.
