# Crash and error reporting

The app reports native crashes to the **pastebin-mobile** project in the private [GlitchTip dashboard](https://errors.watchtrader.net/). The public DSN is bundled with the app; the upload token must never be bundled or committed.

The SDK retains crash stacks, release/build identity and app/device versions. Client filtering removes exception text, request details, breadcrumbs, extra fields and installation identifiers; collector filtering provides a second layer. Performance tracing, replay, logs, automatic sessions and network instrumentation are disabled. Events expire after 30 days. Ordinary Debug builds do not send reports.

Only the native application is instrumented; paste content and account credentials are never added to reports.

## Release symbols

After archiving, run `scripts/upload_glitchtip_symbols.sh /path/to/App.xcarchive`. The script verifies bundle/project identity and matching executable/dSYM UUIDs, downloads checksum-pinned Sentry CLI 3.8.2, and uploads privately. It reads `SENTRY_AUTH_TOKEN` or the macOS Keychain item **GlitchTip Native Apps Upload**, account **jonluca-apps**. Upload failure fails the script.

Before distribution, verify the exact archived DSN and symbols, update any hosted privacy disclosure, and verify receipt using an isolated verification project. New installed binaries are required; an existing installation does not acquire the SDK automatically.

## Legacy release build compatibility

The app and its CocoaPods targets require iOS 13. Apple rejected the earlier iOS 11 archive with error 90068, and the owner authorized the minimum-version increase. With Xcode 27, pass `__DIAGNOSE_INVALID_DEPLOYMENT_TARGET_AS_ERROR=NO` to allow its iOS 13 compatibility diagnostic as a warning. Inspect the archived minimum OS before export.

The vendored AFNetworking reachability source uses public `netinet/in.h`, which provides the IPv6 definitions; its redundant private `netinet6/in6.h` import was removed for current SDK module validation.
