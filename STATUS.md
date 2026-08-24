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
