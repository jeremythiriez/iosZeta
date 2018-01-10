//
//  FFT.swift
//  Zeta
//
//  Created by jeremy thiriez on 21/12/2017.
//  Copyright © 2017 jeremy thiriez. All rights reserved.
//


import Foundation
import AudioKit

@IBDesignable
@objc open class GanglionFFT: NSObject, EZAudioFFTDelegate {
    
    @objc public func setupNode(_ input: AKNode?) {
        if fft == nil {
            fft = EZAudioFFT(maximumBufferSize: vDSP_Length(200),
                             sampleRate: Float(200),
                             delegate: self)
        }
         print("Get Node")
        if input == nil {
            print("NODE NULL")
        }

        input?.avAudioNode.installTap(onBus: 0,
                                      bufferSize: 200,
                                      format: nil) { [weak self] (buffer, _) in
                                    
                                        print("Lets copy self")
                                        let strongSelf = self
                                        if strongSelf == nil {
                                            print("STRONG NIL")
                                        }
                                        if strongSelf != nil {
                                            print("STRONG SELF WORKS")
                                            buffer.frameLength = 200
                                            let offset = Int(buffer.frameCapacity - buffer.frameLength)
                                            if let tail = buffer.floatChannelData?[0], let existingFFT = strongSelf?.fft {
                                                existingFFT.computeFFT(withBuffer: &tail[offset],
                                                                       withBufferSize: 200)
                                            }
                                        }
        }
        print("End of setupNode")
    }
    
    internal var bufferSize: UInt32 = 200
    open var fftData = [Double](zeros: 200)
    
    /// EZAudioFFT container
    var fft: EZAudioFFT?
    
    /// The node whose output to graph
    open var node: AKNode? {
        willSet {
            node?.avAudioNode.removeTap(onBus: 0)
        }
        didSet {
            setupNode(node)
        }
    }
    
    deinit {
        node?.avAudioNode.removeTap(onBus: 0)
    }
    
    /// Required coder-based initialization (for use with Interface Builder)
    ///
    /// - parameter coder: NSCoder
    ///
    required public init?(coder aDecoder: NSCoder) {
        super.init()
        setupNode(nil)
    }
    
    /// Initialize the plot with the output from a given node and optional plot size
    ///
    /// - Parameters:
    ///   - input: AKNode from which to get the plot data
    ///   - width: Width of the view
    ///   - height: Height of the view
    ///
    @objc public init(bufferSize: Int = 200) {
   //     super.init(frame: frame)
     //   self.plotType = .buffer
//        self.backgroundColor = AKColor.white
//        self.shouldCenterYAxis = true
        super.init()
        self.bufferSize = UInt32(bufferSize)
        
    }
    
    /// Callback function for FFT data:
    ///
    /// - Parameters:
    ///   - fft: EZAudioFFT Reference
    ///   - updatedWithFFTData: A pointer to a c-style array of floats
    ///   - bufferSize: Number of elements in the FFT Data array
    ///
    @objc open func fft(_ fft: EZAudioFFT!,
                        updatedWithFFTData fftData: UnsafeMutablePointer<Float>,
                        bufferSize: vDSP_Length) {
        DispatchQueue.main.async { () -> Void in
            for i in 0..<200 {
                self.fftData[i] = Double(fftData[i])
            }
        }
    }
}


