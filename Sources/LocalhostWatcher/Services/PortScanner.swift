import Foundation

private let jsRuntimes: Set<String> = ["node", "bun", "deno"]

final class PortScanner {

    // Returns all TCP listening processes on localhost
    func scan() -> [ServerProcess] {
        let lsofOutput = shell("lsof -iTCP -sTCP:LISTEN -P -n")
        var pidPortPairs: [(pid: Int, port: Int)] = []
        var seen = Set<Int>()

        for line in lsofOutput.components(separatedBy: "\n").dropFirst() {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            // lsof columns: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME (LISTEN)
            guard parts.count >= 10,
                  let pid = Int(parts[1]),
                  let port = extractPort(from: String(parts[parts.count - 2])) else { continue }
            let key = pid * 100000 + port
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            pidPortPairs.append((pid: pid, port: port))
        }

        guard !pidPortPairs.isEmpty else { return [] }

        let uniquePids = Array(Set(pidPortPairs.map(\.pid)))
        let pidList = uniquePids.map(String.init).joined(separator: ",")

        // Three batch ps calls — all pids in one shot each
        let nameMap = batchNames(pidList: pidList)
        let argsMap = batchArgs(pidList: pidList)
        let dateMap = batchDates(pidList: pidList)
        let cwdMap = batchWorkingDirectories(pids: uniquePids)

        return pidPortPairs.map { pair in
            var name = nameMap[pair.pid] ?? "Unknown"
            let args = argsMap[pair.pid]
            let workingDirectory = cwdMap[pair.pid]

            // For JS runtimes, resolve project/tool name from full command args
            if jsRuntimes.contains(name.lowercased()), let args {
                name = resolvedNodeName(args: args, workingDirectory: workingDirectory)
            }

            return ServerProcess(
                id: pair.pid,
                name: name,
                port: pair.port,
                startedAt: dateMap[pair.pid] ?? Date(),
                launchCommand: args,
                workingDirectory: workingDirectory
            )
        }.sorted { $0.port < $1.port }
    }

    func stop(process: ServerProcess) {
        _ = shell("kill -TERM \(process.id)")
    }

    // MARK: - Name resolution

    // Derive a human-readable project/tool name from a node process's argv
    private func resolvedNodeName(args: String, workingDirectory: String?) -> String {
        // 1. node_modules/.bin/<tool> → project directory + tool
        //    e.g. "/Users/kika/my-app/node_modules/.bin/vite" → "my-app (vite)"
        if let nmRange = args.range(of: "/node_modules/") {
            let projectPath = String(args[..<nmRange.lowerBound])
            let projectName = URL(fileURLWithPath: projectPath).lastPathComponent

            // Extract the tool name (token after .bin/)
            let after = String(args[nmRange.upperBound...])
            let toolToken = after.components(separatedBy: "/").last?
                .components(separatedBy: " ").first ?? ""
            let tool = toolToken.isEmpty ? "" : toolToken

            return tool.isEmpty ? projectName : "\(projectName) · \(tool)"
        }

        // 2. Known global npm tools by binary name
        //    e.g. "/opt/homebrew/bin/n8n start" → "n8n"
        let tokens = args.components(separatedBy: " ").filter { !$0.isEmpty }
        let binaryName = URL(fileURLWithPath: tokens.first ?? "").lastPathComponent
        let globalTools = ["n8n", "next", "nuxt", "astro", "remix", "svelte", "gatsby", "nest", "strapi"]
        if globalTools.contains(binaryName) {
            return binaryName
        }
        // Also catch them anywhere in the args (e.g. "/opt/homebrew/bin/n8n")
        for tool in globalTools {
            if tokens.first?.hasSuffix("/\(tool)") == true {
                return tool
            }
        }

        // 3. Absolute .js/.mjs/.ts path → parent directory name
        for token in tokens.dropFirst() {
            let url = URL(fileURLWithPath: token)
            guard ["js", "mjs", "cjs", "ts"].contains(url.pathExtension) else { continue }
            let parentName = url.deletingLastPathComponent().lastPathComponent
            // Skip generic dirs, walk up one level
            if ["dist", "build", "src", "lib", "out", "."].contains(parentName) {
                return url.deletingLastPathComponent()
                    .deletingLastPathComponent().lastPathComponent
            }
            return parentName
        }

        // 4. Relative script path → resolve via working directory
        if let cwd = workingDirectory {
            return URL(fileURLWithPath: cwd).lastPathComponent
        }

        return "node"
    }

    // Get process cwd using lsof field output
    private func workingDirectory(pid: Int) -> String? {
        let output = shell("lsof -p \(pid) -a -d cwd -Fn")
        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("n") { return String(line.dropFirst()) }
        }
        return nil
    }

    // MARK: - Batch ps calls

    private func batchNames(pidList: String) -> [Int: String] {
        let output = shell("ps -p \(pidList) -o pid=,comm=")
        var map: [Int: String] = [:]
        for line in output.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else { continue }
            let parts = t.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2, let pid = Int(parts[0]) else { continue }
            map[pid] = readableName(from: String(parts[1]))
        }
        return map
    }

    private func batchArgs(pidList: String) -> [Int: String] {
        let output = shell("ps -p \(pidList) -o pid=,args=")
        var map: [Int: String] = [:]
        for line in output.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else { continue }
            let parts = t.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2, let pid = Int(parts[0]) else { continue }
            map[pid] = String(parts[1])
        }
        return map
    }

    private func batchDates(pidList: String) -> [Int: Date] {
        let output = shell("ps -p \(pidList) -o pid=,lstart=")
        var map: [Int: Date] = [:]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for line in output.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard !t.isEmpty else { continue }
            let parts = t.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 6, let pid = Int(parts[0]) else { continue }
            let dateStr = parts[1...5].joined(separator: " ")
            formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
            if let date = formatter.date(from: dateStr) { map[pid] = date; continue }
            formatter.dateFormat = "EEE MMM  d HH:mm:ss yyyy"
            if let date = formatter.date(from: dateStr) { map[pid] = date }
        }
        return map
    }

    private func batchWorkingDirectories(pids: [Int]) -> [Int: String] {
        var map: [Int: String] = [:]

        for pid in pids {
            if let directory = workingDirectory(pid: pid) {
                map[pid] = directory
            }
        }

        return map
    }

    // MARK: - Helpers

    private func readableName(from fullPath: String) -> String {
        if let appRange = fullPath.range(of: ".app/") {
            let upToApp = fullPath[..<appRange.lowerBound]
            if let lastSlash = upToApp.lastIndex(of: "/") {
                return String(upToApp[upToApp.index(after: lastSlash)...])
            }
            return String(upToApp)
        }
        return (fullPath as NSString).lastPathComponent
    }

    private func extractPort(from addr: String) -> Int? {
        guard let colonIdx = addr.lastIndex(of: ":") else { return nil }
        let portStr = String(addr[addr.index(after: colonIdx)...])
        return Int(portStr)
    }

    @discardableResult
    private func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command]
        task.launch()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}
