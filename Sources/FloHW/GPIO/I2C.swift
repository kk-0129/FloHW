/*
 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄
 MIT License

 Copyright (c) 2025 kk-0129

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 *//*
    SwiftyGPIO

    Copyright (c) 2016 Umberto Raimondi
    Licensed under the MIT license, as follows:

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.)
    */
import FloBox
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public class I2C{
    
    let i2c : I2CInterface
    let addr:Int
    
    init(_ i2c:I2CInterface,_ addr:Int){
        self.i2c = i2c
        self.addr = addr
    }
    
    var isReachable:Bool{ return i2c.isReachable(addr) }
    func setPEC(_ on:Bool){ i2c.setPEC(addr,enabled:on) }
    
    func readByte()->UInt8{ return i2c.readByte(addr) }
    func readByte(_ c:UInt8)->UInt8{ return i2c.readByte(addr,command:c) }
    func readWord(_ c:UInt8)->UInt16{ return i2c.readWord(addr,command:c) }
    func readData(_ c:UInt8)->[UInt8]{ return i2c.readData(addr,command:c) }
    func readI2CData(_ c:UInt8)->[UInt8]{ return i2c.readI2CData(addr,command:c) }
    func readN(_ c:UInt8,_ n:Int)->[UInt8]?{ return i2c.readN(addr,command:c,bytes:n) }
    
    func writeQuick(){ i2c.writeQuick(addr) }
    func writeByte(_ v:UInt8){ i2c.writeByte(addr,value:v) }
    func writeByte(_ c:UInt8,_ v:UInt8){ i2c.writeByte(addr,command:c,value:v) }
    func writeWord(_ c:UInt8,_ v:UInt16){ i2c.writeWord(addr,command:c,value:v) }
    func writeData(_ c:UInt8,_ v:[UInt8]){ i2c.writeData(addr,command:c,values:v) }
    func writeI2CData(_ c:UInt8,_ v:[UInt8]){ i2c.writeI2CData(addr,command:c,values:v) }
    
    static let DEFAULT_PAYLOAD_LENGTH = I2C_DEFAULT_PAYLOAD_LENGTH
    
}
public extension I2CInterface{
    func at(_ a:Int)->I2C{ return I2C(self,a) }
}

extension SwiftyGPIO {
    
    public static func hardwareI2C(for board: SupportedBoard)->I2CInterface?{
        let i2cs = SwiftyGPIO.hardwareI2Cs(for:board)!
        return i2cs.count == 2 ? i2cs[1] : nil // is this correct ??
    }

    public static func hardwareI2Cs(for board: SupportedBoard)->[I2CInterface]?{
        switch board {
        case .RaspberryPiRev1,
             .RaspberryPiRev2,
             .RaspberryPiPlusZero,
             .RaspberryPiZero2,
             .RaspberryPi2,
             .RaspberryPi3,
             .RaspberryPi4:
            return [I2CRPI[0]!, I2CRPI[1]!]
        }
    }
}

// MARK: - I2C Presets
extension SwiftyGPIO {
    // RaspberryPis I2Cs
    static let I2CRPI: [Int:I2CInterface] = [
        0: SysFSI2C(i2cId: 0),
        1: SysFSI2C(i2cId: 1)
    ]

    // CHIP I2Cs
    // i2c.0: connected to the AXP209 chip
    // i2c.1: after 4.4.13-ntc-mlc connected to the U13 header I2C interface
    // i2c.2: connected to the U14 header I2C interface, XIO gpios are connected on this bus
    static let I2CCHIP: [Int:I2CInterface] = [
        1: SysFSI2C(i2cId: 1),
        2: SysFSI2C(i2cId: 2),
    ]
}

// MARK: I2C

public protocol I2CInterface {
    func isReachable(_ address: Int) -> Bool
    func setPEC(_ address: Int, enabled: Bool)
    func readByte(_ address: Int) -> UInt8
    func readByte(_ address: Int, command: UInt8) -> UInt8
    func readWord(_ address: Int, command: UInt8) -> UInt16
    func readData(_ address: Int, command: UInt8) -> [UInt8]
    func readN(_ address:Int,command:UInt8,bytes:Int)->[UInt8]?
    func readI2CData(_ address: Int, command: UInt8) -> [UInt8]
    func writeQuick(_ address: Int)
    func writeByte(_ address: Int, value: UInt8)
    func writeByte(_ address: Int, command: UInt8, value: UInt8)
    func writeWord(_ address: Int, command: UInt8, value: UInt16)
    func writeData(_ address: Int, command: UInt8, values: [UInt8])
    func writeI2CData(_ address: Int, command: UInt8, values: [UInt8])
}

/// Hardware I2C(SMBus) via SysFS using I2C_SMBUS ioctl
public final class SysFSI2C: I2CInterface {

    let i2cId: Int
    var fd: Int32 = -1
    var currentSlave: Int = -1

    public init(i2cId: Int) {
        self.i2cId=i2cId
    }

    deinit {
        if fd != -1 {
            closeI2C()
        }
    }

    public func readByte(_ address:Int)->UInt8{
        setSlaveAddress(address)
        var r =  i2c_smbus_read_byte()
        if r < 0{ r = 0; __log__.err("I2C read failed (1)") }
        return UInt8(truncatingIfNeeded:r)
    }

    public func readByte(_ address:Int,command c:UInt8)->UInt8{
        setSlaveAddress(address)
        var r =  i2c_smbus_read_byte_data(command:c)
        if r < 0{ r = 0; __log__.err("I2C read failed (2)") }
        return UInt8(truncatingIfNeeded:r)
    }

    public func readWord(_ address:Int,command c:UInt8)->UInt16{
        setSlaveAddress(address)
        var r =  i2c_smbus_read_word_data(command:c)
        if r < 0{ r = 0; __log__.err("I2C read failed (3)") }
        return UInt16(truncatingIfNeeded:r)
    }

    public func readData(_ address:Int,command c:UInt8)->[UInt8]{
        var buf: [UInt8] = [UInt8](repeating:0,count:32)
        setSlaveAddress(address)
        var r =  i2c_smbus_read_block_data(command:c,values:&buf)
        if r < 0{ r = 0; __log__.err("I2C read failed (4)") }
        return buf
    }

    public func readI2CData(_ address:Int,command c:UInt8)->[UInt8]{
        var buf: [UInt8] = [UInt8](repeating:0,count:32)
        setSlaveAddress(address)
        var r =  i2c_smbus_read_i2c_block_data(command:c,values:&buf)
        if r < 0{ r = 0; __log__.err("I2C read failed (5)") }
        return buf
    }
    
    public func readN(_ address:Int,command c:UInt8,bytes n:Int)->[UInt8]?{
        setSlaveAddress(address)
        var res = [UInt8]()
        for i in 0..<n{
            let b = readByte(address,command:c + UInt8(i))
            res.append(b)
        }
        /*
        // THIS DOESN'T WORK ..
        var n = n
        while n > 0{
            var buf:[U8] = [U8](repeating:0,count:min(I2C_DEFAULT_PAYLOAD_LENGTH,n))
            let r =  i2c_smbus_read_block_data(c,&buf)
            if r < 0{ __log__("I2C read failed"); return nil }
            res += buf
            n -= I2C_DEFAULT_PAYLOAD_LENGTH
        }
        */
        return res.count == n ? res : nil
    }
 
    public func writeQuick(_ address:Int){
        setSlaveAddress(address)
        let r =  i2c_smbus_write_quick(value: I2C_SMBUS_WRITE)
        if r < 0{ __log__.err("I2C write failed (1)") }
    }

    public func writeByte(_ address:Int,value v:UInt8){
        setSlaveAddress(address)
        let r =  i2c_smbus_write_byte(value:v)
        if r < 0{ __log__.err("I2C write failed (2)") }
    }

    public func writeByte(_ address:Int,command c:UInt8,value v:UInt8){
        setSlaveAddress(address)
        let r =  i2c_smbus_write_byte_data(command:c,value:v)
        if r < 0{ __log__.err("I2C write failed (3)") }
    }

    public func writeWord(_ address:Int,command c:UInt8,value v:UInt16){
        setSlaveAddress(address)
        let r =  i2c_smbus_write_word_data(command:c,value:v)
        if r < 0{ __log__.err("I2C write failed (4)") }
    }

    public func writeData(_ address:Int,command c:UInt8,values v:[UInt8]){
        setSlaveAddress(address)
        let r =  i2c_smbus_write_block_data(command:c,values:v)
        if r < 0{ __log__.err("I2C write failed (5)") }
    }

    public func writeI2CData(_ address:Int,command c:UInt8,values v:[UInt8]){
        setSlaveAddress(address)
        let r =  i2c_smbus_write_i2c_block_data(command:c,values:v)
        if r < 0{ __log__.err("I2C write failed (6)") }
    }
 
    public func isReachable(_ address:Int)->Bool{
        setSlaveAddress(address)
        var r: Int32 =  -1
        // Mimic the behaviour of i2cdetect, performing bogus read/quickwrite depending on the address
        switch(address){
            case 0x3...0x2f: r =  i2c_smbus_write_quick(value: 0)
            case 0x30...0x37: r =  i2c_smbus_read_byte()
            case 0x38...0x4f: r = i2c_smbus_write_quick(value: 0)
            case 0x50...0x5f: r =  i2c_smbus_read_byte()
            case 0x60...0x77: r =  i2c_smbus_write_quick(value: 0)
            default: r =  i2c_smbus_read_byte()
        }
        guard r >= 0 else { return false }
        return true
    }

    public func setPEC(_ address:Int,enabled:Bool){
        setSlaveAddress(address)
        let r =  ioctl(fd, I2C_PEC, enabled ? 1 : 0)
        if r != 0{ __log__.err("I2C communication failed (1)") }
    }

    private func setSlaveAddress(_ to:Int){
        if fd == -1 { openI2C() }
        guard currentSlave != to else {return}
        let r = ioctl(fd, I2C_SLAVE_FORCE, CInt(to))
        if r != 0{ __log__.err("I2C communication failed (2)") }
        currentSlave = to
    }

    private func openI2C() {
        let fd = open(I2CBASEPATH+String(i2cId), O_RDWR)
        guard fd > 0 else{ __log__.err("I2C communication failed (3)"); return }
        self.fd = fd
    }

    private func closeI2C(){
        close(fd)
    }

    // Private functions
    // Swift implementation of the smbus functions provided by i2c-dev

    private struct i2c_smbus_ioctl_data{
        var read_write: UInt8
        var command: UInt8
        var size: Int32
        var data: UnsafeMutablePointer<UInt8>? //union: UInt8, UInt16, [UInt8]33
    }

    private func smbus_ioctl(rw:UInt8,command:UInt8,size:Int32,data:UnsafeMutablePointer<UInt8>?)->Int32{
        if fd == -1{ openI2C() }
        var args = i2c_smbus_ioctl_data(read_write:rw,command:command,size:size,data:data)
        return ioctl(fd,I2C_SMBUS,&args)
    }

    // MARK: Read

    private func i2c_smbus_read_byte()->Int32{
        var data = [UInt8](repeating:0,count:I2C_DEFAULT_PAYLOAD_LENGTH)
        let r = smbus_ioctl(rw:I2C_SMBUS_READ,command:0,size:I2C_SMBUS_BYTE,data:&data)
        return r >= 0 ? Int32(data[0]) : -1
    }

    private func i2c_smbus_read_byte_data(command:UInt8)->Int32{
        var data = [UInt8](repeating:0,count:I2C_DEFAULT_PAYLOAD_LENGTH)
        let r = smbus_ioctl(rw:I2C_SMBUS_READ,command:command,size:I2C_SMBUS_BYTE_DATA,data:&data)
        return r >= 0 ? Int32(data[0]) : -1
    }

    private func i2c_smbus_read_word_data(command:UInt8)->Int32{
        var data = [UInt8](repeating:0,count:I2C_DEFAULT_PAYLOAD_LENGTH)
        let r = smbus_ioctl(rw:I2C_SMBUS_READ,command:command,size:I2C_SMBUS_WORD_DATA,data:&data)
        return r >= 0 ? (Int32(data[1]) << 8) + Int32(data[0]) : -1
    }

    private func i2c_smbus_read_block_data(command:UInt8,values:inout[UInt8])->Int32{
        var data = [UInt8](repeating:0,count:I2C_DEFAULT_PAYLOAD_LENGTH)
        let r = smbus_ioctl(rw:I2C_SMBUS_READ,command: command,size:I2C_SMBUS_BLOCK_DATA,data:&data)
        if r >= 0{
            for i in 0..<Int(data[0]) {
                values[i] = data[i+1]
            }
            return Int32(data[0])
        }else{
            return -1
        }
    }

    private func i2c_smbus_read_i2c_block_data(command:UInt8,values:inout[UInt8])->Int32{
        var data = [UInt8](repeating:0,count:I2C_DEFAULT_PAYLOAD_LENGTH)
        let r = smbus_ioctl(rw:I2C_SMBUS_READ,command:command,size:I2C_SMBUS_I2C_BLOCK_DATA,data:&data)
        if r >= 0{
            for i in 0..<Int(data[0]) {
                values[i] = data[i+1]
            }
            return Int32(data[0])
        }else{
            return -1
        }
    }

 
    // MARK: Write

    private func i2c_smbus_write_quick(value:UInt8)->Int32{
        return smbus_ioctl(rw:value,command:0,size:I2C_SMBUS_QUICK,data:nil)
    }

    private func i2c_smbus_write_byte(value:UInt8)->Int32{
        return smbus_ioctl(rw:I2C_SMBUS_WRITE,command:value,size:I2C_SMBUS_BYTE,data:nil)
    }

    private func i2c_smbus_write_byte_data(command:UInt8,value:UInt8)->Int32{
        var data = [UInt8](repeating:0,count:I2C_DEFAULT_PAYLOAD_LENGTH)
        data[0] = value
        return smbus_ioctl(rw:I2C_SMBUS_WRITE,command:command,size:I2C_SMBUS_BYTE_DATA,data:&data)
    }

    private func i2c_smbus_write_word_data(command:UInt8,value:UInt16)->Int32{
        var data = [UInt8](repeating:0,count:I2C_DEFAULT_PAYLOAD_LENGTH)
        data[0] = UInt8(value & 0xFF)
        data[1] = UInt8(value >> 8)
        return smbus_ioctl(rw:I2C_SMBUS_WRITE,command:command,size:I2C_SMBUS_WORD_DATA,data:&data)
    }

    private func i2c_smbus_write_block_data(command:UInt8,values:[UInt8])->Int32{
        guard values.count<=I2C_DEFAULT_PAYLOAD_LENGTH else {
            fatalError("Invalid data length, can't send more than \(I2C_DEFAULT_PAYLOAD_LENGTH) bytes!")
        }
        var data = [UInt8](repeating:0,count:values.count+1)
        for i in 1...values.count{
            data[i] = values[i-1]
        }
        data[0] = UInt8(values.count)
        return smbus_ioctl(rw:I2C_SMBUS_WRITE,command:command,size:I2C_SMBUS_BLOCK_DATA,data:&data)
    }

    private func i2c_smbus_write_i2c_block_data(command:UInt8,values:[UInt8])->Int32{
        guard values.count<=I2C_DEFAULT_PAYLOAD_LENGTH else {
            fatalError("Invalid data length, can't send more than \(I2C_DEFAULT_PAYLOAD_LENGTH) bytes!")
        }
        var data = [UInt8](repeating:0,count:values.count+1)
        for i in 1...values.count {
            data[i] = values[i-1]
        }
        data[0] = UInt8(values.count)
        return smbus_ioctl(rw:I2C_SMBUS_WRITE,command:command,size:I2C_SMBUS_I2C_BLOCK_DATA,data:&data)
    }
 
}

// MARK: - I2C/SMBUS Constants
internal let I2C_SMBUS_READ: UInt8 =   1
internal let I2C_SMBUS_WRITE: UInt8 =  0

internal let I2C_SMBUS_QUICK: Int32 = 0
internal let I2C_SMBUS_BYTE: Int32 = 1
internal let I2C_SMBUS_BYTE_DATA: Int32 = 2
internal let I2C_SMBUS_WORD_DATA: Int32 = 3
internal let I2C_SMBUS_BLOCK_DATA: Int32 = 5
//Not implemented: I2C_SMBUS_I2C_BLOCK_BROKEN  6
//Not implemented:  I2C_SMBUS_BLOCK_PROC_CALL   7
internal let I2C_SMBUS_I2C_BLOCK_DATA: Int32 = 8

internal let I2C_SLAVE: UInt = 0x703
internal let I2C_SLAVE_FORCE: UInt = 0x706
internal let I2C_RDWR: UInt = 0x707
internal let I2C_PEC: UInt = 0x708
internal let I2C_SMBUS: UInt = 0x720
internal let I2C_DEFAULT_PAYLOAD_LENGTH: Int = 32
internal let I2CBASEPATH="/dev/i2c-"

// MARK: - Darwin / Xcode Support
#if os(OSX) || os(iOS)
    private var O_SYNC: CInt { fatalError("Linux only") }
#endif
