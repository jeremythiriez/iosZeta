//
//  GanglionParser.swift
//  Zeta
//
//  Created by jeremy thiriez on 21/12/2017.
//  Copyright © 2017 jeremy thiriez. All rights reserved.
//

import Foundation

extension UInt8 {
    var char: Character {
        return Character(UnicodeScalar(self))
    }
}

public class GanglionParser : NSObject
{
    private let accelerometer_axis: [Int] = [7, 8, 9]
    private let byteId_format_18: [Int] = [0, 101]
    private let byteId_format_19: [Int] = [100, 201]
    
    private let byteId_impedance: [Int] = [200, 206]
    private let byteId_ascii: Int = 206
    private let byteId_end_ascii: Int = 207
    private let BUFFER_LENGTH_ERR: Int = -1
    private let BYTEID_ERR: Int = -2
    private var samples_count: Int32 = 0
    //private Int32[,] samples = new Int32[2, 4];
    private var samples: [[Int32]] = [[Int32]](repeating: [Int32](repeating: 0, count: 4), count: 2)
    public let V_SCALE: Double = 1.2 / (8388607.0 * 1.5 * 51.0)
    public let A_SCALE: Double = 0.032
    
    public var id: UInt8 = 0
    public var accelerometer: [Int] = [Int](repeating: 0, count: 3)
    public var data: [Int32] = [Int32](repeating: 0, count: 4)
    public var last_ascii_msg: String? = nil
    
    // impedance_channels : respectively : 1, 2, 3, 4, ref;
    public var impedance_channels: [Int] = [Int](repeating: 0, count: 5)
    
    override init() {
        super.init()
   }

    public func parse(buffer: [UInt8]) -> Int {
        id = buffer[0]
        if (id == 0) {
            return (set_channels_raw(buffer: buffer))
        } else if (id > byteId_format_18[0] && id < byteId_format_18[1]) {
            return (set_channels_18(buffer: buffer))
        } else if (id > byteId_format_19[0] && id < byteId_format_19[1]) {
            return (set_channels_19(buffer: buffer))
        } else if (id > byteId_impedance[0] && id < byteId_impedance[1]) {
            return (set_impedance_channel(channel: Int(id - 201), buffer: buffer))
        } else if (id == byteId_ascii) {
            return (set_ascii(buffer: buffer))
        } else if (id == byteId_end_ascii) {
            return (0)
        }
        return (BYTEID_ERR)
    }
    
    public func process_sample(sample: Int) -> Int {

        if (sample != 0 && sample != 1) {
            return (-1)
        }
        if (id > byteId_format_18[0] && id < byteId_format_19[1]) {
            data[0] = samples[sample][0]
            data[1] = samples[sample][1]
            data[2] = samples[sample][2]
            data[3] = samples[sample][3]
        }
        return (0)
    }
   
    
    public func set_ascii(buffer: [UInt8]) -> Int {
        //char[] msg = new char[buffer.Length];
        
        last_ascii_msg = ""
        for i in 0..<buffer.count {
            last_ascii_msg?.append(buffer[i].char)
        }
        /*
        for (int x = 0; x < buffer.Length; x++){
            msg[x] = (char) buffer[x];
        }
        last_ascii_msg = new String(msg);
 
        
        last_ascii_msg = String(buffer)*/
        return (0)
    }
    
    private func set_impedance_channel(channel: Int, buffer: [UInt8]) -> Int {
        var len: Int = buffer.count - 1
        while (len != 0 && Double(buffer[len]).isNaN) {
            len -= len
        }
        if (len != 0) {
            impedance_channels[channel] = Int(buffer[len])
        }
        return (0)
    }
    
    private func set_channels_raw(buffer: [UInt8]) -> Int {
        if (buffer.count != 20) {
            return (BUFFER_LENGTH_ERR)
        }
        data[0] = bit_format_16(buffer:buffer, index: 1)
        data[1] = bit_format_16(buffer:buffer, index: 4)
        data[2] = bit_format_16(buffer:buffer, index: 7)
        data[3] = bit_format_16(buffer:buffer, index: 10)
        return (0)
    }
    
    private func set_channels_18(buffer: [UInt8]) -> Int {
        if (buffer.count != 20) {
            return (BUFFER_LENGTH_ERR)
        }
        samples_count += 2
        let s0_c0: [UInt8] = [UInt8(buffer[1] >> 6),
            UInt8(((buffer[1] & 0x3F) << 2) | (buffer[2] >> 6)),
            UInt8(((buffer[2] & 0x3F) << 2) | (buffer[3] >> 6))]
        let s0_c1: [UInt8] = [UInt8((buffer[3] & 0x3F) >> 4),
            UInt8((buffer[3] << 4) | (buffer[4] >> 4)),
            UInt8((buffer[4] << 4) | (buffer[5] >> 4))]
        let s0_c2: [UInt8] = [UInt8((buffer[5] & 0x0F) >> 2),
            UInt8((buffer[5] << 6) | (buffer[6] >> 2)),
            UInt8((buffer[6] << 6) | (buffer[7] >> 2))]
        let s0_c3: [UInt8] = [UInt8(buffer[7] & 0x03), buffer[8], buffer[9]]
        set_sample(sample: 0, channel_0: s0_c0, channel_1: s0_c1, channel_2: s0_c2, channel_3: s0_c3, size: 18)
        let s1_c0: [UInt8] = [UInt8(buffer[10] >> 6),
            UInt8(((buffer[10] & 0x3F) << 2) | (buffer[11] >> 6)),
            UInt8(((buffer[11] & 0x3F) << 2) | (buffer[12] >> 6))]
        let s1_c1: [UInt8] = [UInt8((buffer[12] & 0x3F) >> 4),
            UInt8((buffer[12] << 4) | (buffer[13] >> 4)),
            UInt8((buffer[13] << 4) | (buffer[14] >> 4))]
        let s1_c2: [UInt8] = [UInt8((buffer[14] & 0x0F) >> 2),
            UInt8((buffer[14] << 6) | (buffer[15] >> 2)),
            UInt8((buffer[15] << 6) | (buffer[16] >> 2))]
        let s1_c3: [UInt8] = [UInt8(buffer[16] & 0x03), buffer[17], buffer[18]]
        set_sample(sample: 1, channel_0: s1_c0, channel_1: s1_c1, channel_2: s1_c2, channel_3: s1_c3, size: 18)
        let has_accelerometer: Int32 = samples_count % 10
        if (has_accelerometer == accelerometer_axis[0]) {
            accelerometer[0] = Int(buffer[19])
        } else if (has_accelerometer == accelerometer_axis[1]) {
            accelerometer[1] = Int(buffer[19])
        } else if (has_accelerometer == accelerometer_axis[2]) {
            accelerometer[2] = Int(buffer[19])
        }
        return (0)
    }
    
    private func set_channels_19(buffer: [UInt8]) -> Int
    {
        if (buffer.count != 20) {
            return (BUFFER_LENGTH_ERR)
        }
        samples_count += 2;
        let s0_c0: [UInt8] = [UInt8(buffer[1] >> 5),
            UInt8(((buffer[1] & 0x1F) << 3) | (buffer[2] >> 5)),
            UInt8(((buffer[2] & 0x1F) << 3) | (buffer[3] >> 5))]
        let s0_c1: [UInt8] = [UInt8((buffer[3] & 0x1F) >> 2),
            UInt8((buffer[3] << 6) | (buffer[4] >> 2)),
            UInt8((buffer[4] << 6) | (buffer[5] >> 2))]
        let s0_c2: [UInt8] = [UInt8(((buffer[5] & 0x03) << 1) | (buffer[6] >> 7)),
            UInt8(((buffer[6] & 0x7F) << 1) | (buffer[7] >> 7)),
            UInt8(((buffer[7] & 0x7F) << 1) | (buffer[8] >> 7))]
        let s0_c3: [UInt8] = [UInt8(((buffer[8] & 0x7F) >> 4)),
            UInt8(((buffer[8] & 0x0F) << 4) | (buffer[9] >> 4)),
            UInt8(((buffer[9] & 0x0F) << 4) | (buffer[10] >> 4))]
        set_sample(sample: 0, channel_0: s0_c0, channel_1: s0_c1, channel_2: s0_c2, channel_3: s0_c3, size: 19)
        let s1_c0: [UInt8] = [UInt8((buffer[10] & 0x0F) >> 1),
            UInt8((buffer[10] << 7) | (buffer[11] >> 1)),
            UInt8((buffer[11] << 7) | (buffer[12] >> 1))]
        let s1_c1 = [UInt8(((buffer[12] & 0x01) << 2) | (buffer[13] >> 6)),
            UInt8((buffer[13] << 2) | (buffer[14] >> 6)),
            UInt8((buffer[14] << 2) | (buffer[15] >> 6))]
        let s1_c2: [UInt8] = [UInt8(((buffer[15] & 0x38) >> 3)),
            UInt8(((buffer[15] & 0x07) << 5) | ((buffer[16] & 0xF8) >> 3)),
            UInt8(((buffer[16] & 0x07) << 5) | ((buffer[17] & 0xF8) >> 3))]
        let s1_c3 = [UInt8(buffer[17] & 0x07), buffer[18], buffer[19]]
        set_sample(sample: 1, channel_0: s1_c0, channel_1: s1_c1, channel_2: s1_c2, channel_3: s1_c3, size: 19)
        return (0)
    }
    
    private func set_sample(sample: Int, channel_0: [UInt8], channel_1: [UInt8], channel_2: [UInt8], channel_3: [UInt8], size: Int) {
        if (size == 18)
        {
            samples[sample][0] = bit_format_18(to_concat: channel_0)
            samples[sample][1] = bit_format_18(to_concat: channel_1)
            samples[sample][2] = bit_format_18(to_concat: channel_2)
            samples[sample][3] = bit_format_18(to_concat: channel_3)
        }
        else
        {
            samples[sample][0] = bit_format_19(to_concat: channel_0)
            samples[sample][1] = bit_format_19(to_concat: channel_1)
            samples[sample][2] = bit_format_19(to_concat: channel_2)
            samples[sample][3] = bit_format_19(to_concat: channel_3)
        }
    }
    
    private func bit_format_16(buffer: [UInt8], index: Int) -> Int32 {
        let a = (0xFF & buffer[index]) << 16
        let b = (0xFF & buffer[index + 1]) << 8
        let c = (0xFF & buffer[index + 2])
        var result: UInt32 = UInt32(a | b | c)
        if ((result & 0x00800000) > 0) {
            result = result | 0xFF000000
        } else {
            result = result & 0x00FFFFFF
        }
        return (Int32(result))
    }
    
    private func bit_format_18(to_concat: [UInt8]) -> Int32 {
        var default_byte: Int32 = 0
        if ((to_concat[2] & 0x01) > 0) {
            default_byte = 0x3FFF
        }
        return (default_byte << 18) | (Int32(to_concat[0]) << 16) | (Int32(to_concat[1]) << 8) | Int32(to_concat[2])
    }
    
    private func bit_format_19(to_concat: [UInt8]) -> Int32 {
        var default_byte: Int32 = 0
        if ((to_concat[2] & 0x01) > 0) {
            default_byte = 0x3FFF
        }
        return (default_byte << 19) | (Int32(to_concat[0]) << 16) | (Int32(to_concat[1]) << 8) | Int32(to_concat[2])
    }
}
