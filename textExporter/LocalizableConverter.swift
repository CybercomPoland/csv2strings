//
//  LocalizableConverter.swift
//  textExporter
//
//  Created by Lukasz Majchrzak on 14/09/2017.
//  Copyright © 2017 Cybercom Poland Sp. z o o. All rights reserved.
//

import Foundation

enum ConversionMode {
    case stringsToCsv
    case csvToStrings
}

class LocalizableConverter {
    static let quotationMark = "\""
    static let commaMark = ","
    static let commentMark = "//"

    func convertFiles() {
        convert(inputName: "input", outputName: "output", mode: .stringsToCsv)
        convert(inputName: "input", outputName: "output", mode: .csvToStrings)
    }
}

extension LocalizableConverter {
    fileprivate func convert(inputName: String, outputName: String, mode: ConversionMode) {

        let inputType: String
        let outputType: String
        switch mode {
        case .stringsToCsv:
            inputType = "strings"
            outputType = "csv"
        case .csvToStrings:
            inputType = "csv"
            outputType = "strings"
        }

        guard let data = stringFromFile(inputName, fileType: inputType) else { return }
        let dataLines = splitStringByNewLines(data)

        let outputLines = dataLines.map({ (toConvert) -> String in
            switch mode {
            case .stringsToCsv:
                return LocalizableConverter.convertStringsLineToCsv(input: toConvert)
            case .csvToStrings:
                return LocalizableConverter.convertCsvLineToStrings(input: toConvert)
            }
        })

        let output = outputLines.reduce("") { return $0+"\n"+$1 }
        let outputUrl = Bundle.main.bundleURL.appendingPathComponent("\(outputName).\(outputType)")
        do {
            try output.write(to: outputUrl, atomically: true, encoding: .utf8)
            print("file saved, path: \(outputUrl.path)")
        } catch {
            print("could not save file to path: \(outputUrl.path)")
        }
    }

    fileprivate func stringFromFile(_ fileName: String, fileType: String) -> String? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: fileType) else {
            print("could not find file \(fileName).\(fileType)")
            return nil
        }

        guard let data = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("could not load file input.swift")
            return nil
        }
        return data
    }

    fileprivate func splitStringByNewLines(_ data: String) -> [String] {
        var lines = [String]()
        data.enumerateLines { (line, _) in
            lines.append(line)
        }
        return lines
    }

    fileprivate static func convertStringsLineToCsv(input: String) -> String {
        var output = ""

        let input = input.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return output }

        let nsInput = input as NSString

        //no quotations - it means line contains comment only
        if stringsToCsvIsCommentLineOnly(line: nsInput) {
            let comment = stringsToCsvGetComments(from: nsInput) as NSString
            output = "\(commaMark)\(commaMark)\(formattedCsvString(comment))"
            return output
        }

        //find first quoted string
        let (firstQuotation, firstQuotationEndIndex) = LocalizableConverter.stringsToCsvGetQuotationAndEndIndex(from: nsInput, startIndex: 0)
        //find second quoted string
        let (secondQuotation, _) = stringsToCsvGetQuotationAndEndIndex(from: nsInput, startIndex: firstQuotationEndIndex)
        //find comment
        let comment = stringsToCsvGetComments(from: nsInput)


        let formattedSecondQuotation = formattedCsvString(secondQuotation as NSString)
        let formattedComment = formattedCsvString(comment as NSString)

        output = "\(firstQuotation)\(commaMark)\(formattedSecondQuotation)\(commaMark)\(formattedComment)"
        return output
    }

    fileprivate static func convertCsvLineToStrings(input: String) -> String {
        var output = ""

        
        //find first comma or quote
        //if it's comma, move set pointer and start over
        //if it's quote find next quote and start over
        return output
    }

    fileprivate static func formattedCsvString(_ text: NSString) -> String {
        let doubleQuoted = text.replacingOccurrences(of: quotationMark, with: "\(quotationMark)\(quotationMark)")

        return "\(quotationMark)\(doubleQuoted)\(quotationMark)"
    }

    fileprivate static func stringsToCsvGetQuotationAndEndIndex(from text: NSString, startIndex: Int) -> (String,Int) {
        let quotation = quotationMark
        let rangeForFirstQM = NSMakeRange(startIndex, text.length - startIndex)
        guard rangeForFirstQM.location < Int.max else { return ("", startIndex) }
        let firstQMRange = text.range(of: quotation, options: [], range: rangeForFirstQM, locale: nil)
        let firstQMRangeEnd = firstQMRange.location + firstQMRange.length
        let rangeForSecondQM = NSMakeRange(firstQMRangeEnd, text.length - firstQMRangeEnd)
        guard rangeForSecondQM.location < Int.max else { return ("", firstQMRangeEnd) }
        let secondQMRange = text.range(of: quotation, options: [], range: rangeForSecondQM, locale: nil)
        let firstQuotation = text.substring(with: NSMakeRange(firstQMRangeEnd, secondQMRange.location - firstQMRangeEnd))
        let secondQMRangeEnd = secondQMRange.location + secondQMRange.length
        return (firstQuotation, secondQMRangeEnd)
    }

    fileprivate static func stringsToCsvGetComments(from text: NSString) -> String{
        let commentMarkRange = text.range(of: commentMark)
        guard commentMarkRange.location < Int.max else { return "" }
        let comment = text.substring(from: commentMarkRange.location + commentMarkRange.length)
        return comment
    }

    fileprivate static func stringsToCsvIsCommentLineOnly(line: NSString) -> Bool {
        guard line.contains(commentMark) else { return false }

        let commentRange = line.range(of: commentMark)
        let quotationRange = line.range(of: quotationMark)
        return commentRange.location < quotationRange.location
    }
}
