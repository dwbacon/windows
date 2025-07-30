
import Foundation

private let logQueue = DispatchQueue(label: "windowpreview.logger", qos: .utility)
private let logPath: String = {
    let logsDirectory = NSHomeDirectory() + "/Desktop/WindowPreview/logs"
    do {
        try FileManager.default.createDirectory(atPath: logsDirectory, withIntermediateDirectories: true, attributes: nil)
    } catch {
        NSLog("Failed to create logs directory: \(error)")
    }
    return logsDirectory + "/debug.log"
}()

// Crash-safe logging function that writes immediately to file
func log(_ message: String) {
    let timestamp = DateFormatter().apply {
        $0.dateFormat = "[h:mm:ss a]"
    }.string(from: Date())
    
    let logMessage = "\(timestamp) \(message)\n"
    
    // Print to console
    print(message)
    
    // Write to file synchronously for crash safety
    do {
        if FileManager.default.fileExists(atPath: logPath) {
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: logPath))
            defer { fileHandle.closeFile() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(logMessage.data(using: .utf8) ?? Data())
        } else {
            try logMessage.write(toFile: logPath, atomically: true, encoding: .utf8)
        }
    } catch {
        NSLog("Failed to write to log file: \(error)")
    }
}

extension DateFormatter {
    func apply(_ closure: (DateFormatter) -> Void) -> DateFormatter {
        closure(self)
        return self
    }
}

