//
//  DataHandler.swift
//  Zeta
//
//  Created by jeremy thiriez on 04/01/2018.
//  Copyright © 2018 jeremy thiriez. All rights reserved.
//

import Foundation
import AudioKit

public class DataHandler : NSObject
{
    private var index: Int = 0
    private var Vsave: [Double] = [Double](repeating: 0.0, count: 4)
    var channels: [[Double]] = [[Double]](repeating: [Double](repeating: 0, count: 200), count: 4)
    private var parser: GanglionParser = GanglionParser()
    public var feedback: Float = 0
    
    override public init() {
        super.init()
    }
    
    private func ComputeDelta(data: [Int32]) -> [Double] {
        var delta: [Double] = [Double](repeating: 0.0, count: 4)
        
        for i in 0..<4 {
            delta[i] = Double(data[i]) * parser.V_SCALE
        }
        return delta
    }
    
    private func ComputeVsave(delta: [Double]) -> [Double] {
        var v: [Double] = [Double](repeating: 0.0, count: 4)
        
        for i in 0..<4 {
            v[i] = Vsave[i] - delta[i]
        }
        return v
    }
    
    public func HandleFrame(data: [UInt8]) {
        parser.parse(buffer: data)
        // MARK: print Id
        //print("id: \(data[0])")
        if data[0] == 0 {
            Vsave = ComputeDelta(data: parser.data)
            print("New frame")
        } else {
            parser.process_sample(sample: 0)
            Vsave = ComputeVsave(delta: ComputeDelta(data: parser.data))
            StorData(v: Vsave)
            parser.process_sample(sample: 1)
            Vsave = ComputeVsave(delta: ComputeDelta(data: parser.data))
            StorData(v: Vsave)
    
        }
    }
    
    //MARK: StorData, stoque les points dans un buffer circulaire.
    private func StorData(v: [Double]) {
        
        for i in 0..<4 {
            channels[i][index] = v[i]
            // MARK: print Value
            //print("Value chan[\(i)]: \(v[i])");
        }
        if index % 25 == 0 { // Calcule le feedback tout les 25 points
            feedback = ComputeFeedBack()
            // MARK: print feedback
            print("Feedback: \(feedback)")
        }
        index = (index + 1) % 200
    }
    
    //MARK: Compute the FeedBack
    public func ComputeFeedBack() -> Float {
        let FFT = EZAudioFFT(maximumBufferSize: 200, sampleRate: 200)
        var i = index
        var tmp: UnsafeMutablePointer<Float>?
        var fftArray: [[Float]] = [[Float]](repeating: [Float](repeating: 0, count: 200), count: 4)
        
        for k in 0..<4 {
            i = index
            for j in 0..<200 {
                fftArray[k][j] = Float(channels[k][i])
                i = (i + 1) % 200
            }
        }
        for k in 0..<4 {
            FFT?.computeFFT(withBuffer: &fftArray[k][0], withBufferSize: 200)
            tmp = FFT?.fftData
            for j in 0..<200 {
                fftArray[k][j] = tmp![j]
                //MARK: print FFT by chan
                //print("fft chan[\(k)]: \(fftArray[k][j])")
            }
        }
        return ComputeAverageAlpha(fftArray: fftArray) / ComputeAverageDelta(fftArray: fftArray);
    }
    
    private func ComputeAverageDelta(fftArray: [[Float]]) -> Float {
        var value: Float = 0
        
        for i in 0..<4 {
            for j in 1...4 {
                value += fftArray[i][j]
            }
        }
        // MARK: print Average Delta
        //print("Average Delta: \(value / 16)")
        return value / 16
    }
    
    private func ComputeAverageAlpha(fftArray: [[Float]]) -> Float {
        var value: Float = 0
        
        for i in 0..<4 {
            for j in 8...12 {
                value += fftArray[i][j]
            }
        }
        // MARK: print Average Alpha
        //print("Average Alpha: \(value / 20)")
        return value / 20
    }
}
