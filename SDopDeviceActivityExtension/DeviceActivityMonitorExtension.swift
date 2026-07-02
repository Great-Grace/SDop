import DeviceActivity
import FamilyControls
import ManagedSettings

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // Interval started — shield is already applied from main app
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Time interval ended — clear shields
        store.clearAllSettings()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        // Re-apply shields when threshold is exceeded
        let selection = FamilyActivitySelection()
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        // Notify user that monitoring will begin soon
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        // Notify user that monitoring interval is about to end
    }
}
