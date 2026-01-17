//
//  NSNumberDisplayTests.swift
//  DHBootlegToolkitCoreTests
//
//  Unit tests for NSNumber+Display extension
//

import Testing
import Foundation
@testable import DHBootlegToolkitCore

@Suite("NSNumber Display Value Tests")
struct NSNumberDisplayTests {

    @Test("Integer displays without decimal point")
    func integerDisplayValue() {
        let number = NSNumber(value: 30)
        #expect(number.displayValue == "30")
    }

    @Test("Float displays with decimal point")
    func floatDisplayValue() {
        let number = NSNumber(value: 30.0)
        #expect(number.displayValue == "30.0")
    }

    @Test("Float with non-zero decimal displays correctly")
    func floatWithDecimalDisplayValue() {
        let number = NSNumber(value: 30.5)
        #expect(number.displayValue == "30.5")
    }

    @Test("Boolean true displays as 'true'")
    func booleanTrueDisplayValue() {
        let number = NSNumber(value: true)
        #expect(number.displayValue == "true")
    }

    @Test("Boolean false displays as 'false'")
    func booleanFalseDisplayValue() {
        let number = NSNumber(value: false)
        #expect(number.displayValue == "false")
    }

    @Test("Negative float displays with decimal point")
    func negativeFloatDisplayValue() {
        let number = NSNumber(value: -30.0)
        #expect(number.displayValue == "-30.0")
    }

    @Test("Large float displays correctly")
    func largeFloatDisplayValue() {
        let number = NSNumber(value: 1000000.0)
        #expect(number.displayValue == "1000000.0")
    }

    @Test("Negative integer displays without decimal point")
    func negativeIntegerDisplayValue() {
        let number = NSNumber(value: -30)
        #expect(number.displayValue == "-30")
    }

    @Test("Zero integer displays without decimal point")
    func zeroIntegerDisplayValue() {
        let number = NSNumber(value: 0)
        #expect(number.displayValue == "0")
    }

    @Test("Zero float displays with decimal point")
    func zeroFloatDisplayValue() {
        let number = NSNumber(value: 0.0)
        #expect(number.displayValue == "0.0")
    }

    @Test("Display matches serialization logic for integer")
    func displayMatchesSerializationInteger() {
        let number = NSNumber(value: 42)
        let displayValue = number.displayValue
        let serializedValue = "\(number.intValue)"
        #expect(displayValue == serializedValue)
    }

    @Test("Display matches serialization logic for float")
    func displayMatchesSerializationFloat() {
        let number = NSNumber(value: 42.0)
        let displayValue = number.displayValue
        let serializedValue = "\(number.doubleValue)"
        #expect(displayValue == serializedValue)
    }

    @Test("Display distinguishes between 30 and 30.0")
    func distinguishesBetweenIntAndFloat() {
        let intNumber = NSNumber(value: 30)
        let floatNumber = NSNumber(value: 30.0)

        #expect(intNumber.displayValue == "30")
        #expect(floatNumber.displayValue == "30.0")
        #expect(intNumber.displayValue != floatNumber.displayValue)
    }
}
