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
    static let doubleQuotationMark = "\"\""
    static let commaMark = ","
    static let commentMark = "//"

    static let stringsTraslationMark = " = "
    static let stringsCommentSection = "; //"
    

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

    //read file as String
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

    //split multiline String into array of slingleline Strings
    fileprivate func splitStringByNewLines(_ data: String) -> [String] {
        var lines = [String]()
        data.enumerateLines { (line, _) in
            lines.append(line)
        }
        return lines
    }
}

//strings to csv
extension LocalizableConverter {

    //converts line of strings file format to line of csv file format (input is in format: "identifer" = "text"; //comment)
    fileprivate static func convertStringsLineToCsv(input: String) -> String {
        var output = ""

        let input = input.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return output }

        let nsInput = input as NSString
        if stringsToCsvIsCommentLineOnly(line: nsInput) {
            //no quotations - it means line contains comment only
            let comment = stringsToCsvGetComments(from: nsInput) as NSString
            output = commaMark + commaMark + stringsToCsvEmbedInQuotationMarks(comment)
            return output
        }

        let (identifier, identifierEndIndex) = LocalizableConverter.stringsToCsvGetQuotationAndEndIndex(from: nsInput, startIndex: 0)
        let (text, _) = stringsToCsvGetQuotationAndEndIndex(from: nsInput, startIndex: identifierEndIndex)
        let comment = stringsToCsvGetComments(from: nsInput)

        let formattedText = stringsToCsvEmbedInQuotationMarks(text as NSString)
        let formattedComment = stringsToCsvEmbedInQuotationMarks(comment as NSString)

        output = identifier + commaMark + formattedText + commaMark + formattedComment
        return output
    }

    //replace quotation marks with doubled quotation marks and embed result in quotation marks (format of csv file cell)
    fileprivate static func stringsToCsvEmbedInQuotationMarks(_ text: NSString) -> String {
        let doubleQuoted = text.replacingOccurrences(of: quotationMark, with: doubleQuotationMark)
        return "\(quotationMark)\(doubleQuoted)\(quotationMark)"
    }

    //extract csv cell (identifier or text) from strings line
    fileprivate static func stringsToCsvGetQuotationAndEndIndex(from text: NSString, startIndex: Int) -> (String,Int) {
        let rangeForFirstQM = NSMakeRange(startIndex, text.length - startIndex)
        let firstQMRange = text.range(of: quotationMark, options: [], range: rangeForFirstQM, locale: nil)
        guard firstQMRange.location < Int.max else { return ("", startIndex) }
        let firstQMRangeEnd = firstQMRange.location + firstQMRange.length
        let rangeForSecondQM = NSMakeRange(firstQMRangeEnd, text.length - firstQMRangeEnd)
        let secondQMRange = text.range(of: quotationMark, options: [], range: rangeForSecondQM, locale: nil)
        guard secondQMRange.location < Int.max else { return ("", firstQMRangeEnd) }
        let firstQuotation = text.substring(with: NSMakeRange(firstQMRangeEnd, secondQMRange.location - firstQMRangeEnd))
        let secondQMRangeEnd = secondQMRange.location + secondQMRange.length
        return (firstQuotation, secondQMRangeEnd)
    }

    //extract comment from strings line
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

//csv to strings
extension LocalizableConverter {
    //converts line of csv file format to line of strings file format (input line should have 3 columns: identifier, text and comment)
    fileprivate static func convertCsvLineToStrings(input: String) -> String {
        var output = ""
        let input = input.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return output }

        let nsInput = input as NSString

        let (identifer, stringsIdentifierEndIndex) = csvToStringsCellAndEndIndex(from: nsInput, startIndex: 0)
        let (text, stringsTextEndIndex) = csvToStringsCellAndEndIndex(from: nsInput, startIndex: stringsIdentifierEndIndex)
        let (comment, _) = csvToStringsCellAndEndIndex(from: nsInput, startIndex: stringsTextEndIndex)

        guard !identifer.isEmpty else { return commentMark + comment }
        output = quotationMark + identifer + quotationMark + stringsTraslationMark + quotationMark + text + quotationMark + stringsCommentSection + comment
        return output
    }

    //find cvs cell in cvs line (identifier, text or comment)
    fileprivate static func csvToStringsCellAndEndIndex(from text: NSString, startIndex: Int) -> (String, Int) {
        var unmatchingQM = false
        var removeDoubleQM = false

        var (cMRange, qMRange) = csvToStringsGetCommaAndQuestionMarkRanges(from: text, startIndex: startIndex)
        if qMRange.location < cMRange.location {
            //quotation first - it means cell string is embedded in quotation marks
            removeDoubleQM = true
            unmatchingQM = true

            while unmatchingQM {
                //find matching quotation
                (cMRange, qMRange) = csvToStringsGetCommaAndQuestionMarkRanges(from: text, startIndex: qMRange.location + qMRange.length)
                guard qMRange.location != Int.max else { fatalError() }
                unmatchingQM = false

                //check if it's embedded quotation
                (cMRange, qMRange) = csvToStringsGetCommaAndQuestionMarkRanges(from: text, startIndex: qMRange.location + qMRange.length)
                if qMRange.location < cMRange.location { unmatchingQM = true }
            }
        }

        //check if it's the last cvs cell (without comma at the end)
        if cMRange.location == Int.max {
            var output = text.substring(from: startIndex) as NSString
            output = removeDoubleQM ? csvToStringsExtractFromQuotationMarks(output) : output
            return (output as String, text.length)
        }
        let cellStringRange = NSMakeRange(startIndex, cMRange.location - startIndex)
        var cellString = text.substring(with: cellStringRange) as NSString

        if removeDoubleQM {
            cellString = csvToStringsExtractFromQuotationMarks(cellString)
        }

        return (cellString as String, cMRange.location + cMRange.length)
    }

    //find range of next comma or question marks in cvs line
    fileprivate static func csvToStringsGetCommaAndQuestionMarkRanges(from text: NSString, startIndex: Int) -> (NSRange, NSRange) {
        let rangeOfSearch = NSMakeRange(startIndex, text.length - startIndex)
        let cMRange = text.range(of: commaMark, options: [], range: rangeOfSearch, locale: nil)
        let qMRange = text.range(of: quotationMark, options: [], range: rangeOfSearch, locale:  nil)
        return (cMRange, qMRange)
    }

    //convert cvs cell to strings format (remove external quotation marks and change double quotation marks to single one)
    fileprivate static func csvToStringsExtractFromQuotationMarks(_ text: NSString) -> NSString {
        let textRange = NSMakeRange(0, text.length)
        let firstQMRange = text.range(of: quotationMark, options: [], range: textRange, locale: nil)
        let lastQMRange = text.range(of: quotationMark, options: [.backwards], range: textRange, locale: nil)
        let firstQMRangeEndIndex = firstQMRange.location + firstQMRange.length
        let insideQuotationRange = NSMakeRange(firstQMRangeEndIndex, lastQMRange.location - firstQMRangeEndIndex)
        var text = text.substring(with: insideQuotationRange) as NSString
        text = text.replacingOccurrences(of: doubleQuotationMark, with: quotationMark) as NSString
        return text
    }
}
