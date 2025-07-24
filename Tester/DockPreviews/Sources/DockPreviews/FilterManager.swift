
import Foundation

class FilterManager {
    private var filteredApps: [String] = []

    func updateFilteredApps(apps: [String]) {
        self.filteredApps = apps
    }

    func shouldFilter(appName: String) -> Bool {
        return filteredApps.contains(appName.lowercased())
    }
}
