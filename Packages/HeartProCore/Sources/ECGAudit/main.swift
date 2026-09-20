import Foundation
import HeartProCore

// Input is a public-data audit fixture, not a patient record. Output includes every
// evaluated/excluded beat so the audit cannot silently omit rejected true events.
struct Input: Decodable { var samplingFrequency: Double; var values: [Double] }
struct Output: Encodable { var start: Double; var peaks: [Double]; var assessment: RhythmAssessment? }
let input = try JSONDecoder().decode(Input.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
let count = Int(input.samplingFrequency * 30)
var output: [Output] = []
for start in stride(from: 0, to: input.values.count - count + 1, by: count) {
    let points = (0..<count).map { VoltagePoint(time: Double($0) / input.samplingFrequency, millivolts: input.values[start + $0]) }
    let analysis = try SignalAnalyzer.analyze(Waveform(samplingFrequency: input.samplingFrequency, points: points))
    output.append(Output(start: Double(start) / input.samplingFrequency, peaks: analysis.peakTimes, assessment: analysis.rhythmAssessment))
}
let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
try encoder.encode(output).write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
