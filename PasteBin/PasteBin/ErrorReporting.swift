import Foundation
#if canImport(SentryWithoutUIKit)
import SentryWithoutUIKit
#else
import Sentry
#endif

/// Error-only reporting. Native stacks and release identity survive; user content does not.
enum ErrorReporting {
    private static let initialization: Void = {
        #if !DEBUG
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
              let dsn = Bundle.main.object(forInfoDictionaryKey: "GlitchTipDSN") as? String,
              !dsn.isEmpty else { return }
        configure(dsn: dsn)
        #endif
    }()

    static func start() {
        _ = initialization
    }

    private static func configure(dsn: String) {
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = "production"
            options.sendDefaultPii = false
            options.maxBreadcrumbs = 0
            options.enableAutoBreadcrumbTracking = false
            options.enableNetworkBreadcrumbs = false
            options.enableAutoSessionTracking = false
            options.enableWatchdogTerminationTracking = false
            options.enableAppHangTracking = false
            if #available(iOS 15.0, macOS 12.0, *) {
                options.enableMetricKit = false
            }
            options.enableAutoPerformanceTracing = false
            options.enableNetworkTracking = false
            options.enableCaptureFailedRequests = false
            options.enableFileIOTracing = false
            options.enableSwizzling = false
            #if os(iOS) && canImport(Sentry)
            options.attachScreenshot = false
            options.attachViewHierarchy = false
            #endif
            options.tracesSampleRate = 0
            options.shutdownTimeInterval = 0
            options.beforeSend = { event in
                return sanitize(event)
            }
        }
    }

    private static func sanitize(_ event: Event) -> Event {
        event.message = nil
        event.error = nil
        event.extra = nil
        event.tags = nil
        event.request = nil
        event.breadcrumbs = nil
        event.transaction = nil
        event.serverName = nil
        let user = User()
        user.ipAddress = "0.0.0.0"
        event.user = user
        // SDK device/install identifiers are not needed to diagnose a stack trace.
        let allowed: [String: Set<String>] = [
            "app": ["app_identifier", "app_version", "app_build"],
            "os": ["name", "version", "build", "kernel_version"],
            "device": ["family", "model", "arch", "simulator"]
        ]
        event.context = event.context?.reduce(into: [:]) { output, entry in
            guard let keys = allowed[entry.key] else { return }
            output[entry.key] = entry.value.filter { keys.contains($0.key) }
        }
        for image in event.debugMeta ?? [] {
            if let path = image.codeFile { image.codeFile = (path as NSString).lastPathComponent }
        }
        for exception in event.exceptions ?? [] {
            exception.value = "[Filtered]"
            exception.mechanism?.data = nil
            exception.mechanism?.desc = nil
            exception.mechanism?.helpLink = nil
            exception.mechanism?.meta = nil
            sanitize(exception.stacktrace)
        }
        for thread in event.threads ?? [] {
            thread.name = nil
            sanitize(thread.stacktrace)
        }
        sanitize(event.stacktrace)
        return event
    }

    private static func sanitize(_ stack: SentryStacktrace?) {
        for frame in stack?.frames ?? [] {
            frame.vars = nil
            frame.contextLine = nil
            frame.preContext = nil
            frame.postContext = nil
            if let path = frame.package { frame.package = (path as NSString).lastPathComponent }
            if let name = frame.fileName { frame.fileName = (name as NSString).lastPathComponent }
        }
    }
}
