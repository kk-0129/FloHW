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
 */
import Foundation
import FloBox

// MARK: ■ Box

public typealias F3 = SIMD3<Float32>

// MARK: ■ Imp
public class BNO055{
    
    private var _cache = [F3](repeating:F3(),count:6)
    
    public var temperature:Float32{
        if let x = getTemperature(){ _cache[0] = F3(Float32(x),0,0) }
        return _cache[0].x
    }
    private var temp = 0
    public var euler:F3{
        if let x = getXYZ(type:.EULER){ _cache[1] = x }
        return _cache[1]
    }
    public var accelerometer:F3{
        if let x = getXYZ(type:.LINEAR_ACC){ _cache[2] = x }
        return _cache[2]
    }
    public var gyroscope:F3{
        if let x = getXYZ(type:.GYR){ _cache[3] = x }
        return _cache[3]
    }
    public var magnetometer:F3{
        if let x = getXYZ(type:.MAG){ _cache[4] = x }
        return _cache[4]
    }
    public var gravity:F3{
        if let x = getXYZ(type:.GRAVITY){ _cache[5] = x }
        return _cache[5]
    }
    
    /* this code ported & chopped from: https://github.com/adafruit/Adafruit_BNO055 */
    private static let ID:UInt8 = 0xA0
    private let _i2c: I2C
    // MARK: ■ init
    public init(_ i2c:I2C){
        _i2c = i2c
        /*
         NDOF = fusion mode with 9 degrees of freedom where the fused absolute orientation data is calculated from accelerometer, gyroscope and the magnetometer.
         */
        _ = begin(mode: .NDOF)
        __log__.info("BNO055 inited")
    }
    
    // MARK: ■ set the OpMode
    private var _mode:OpMode = .CONFIG{ // Puts the chip in the specified operating mode
        didSet{ if _mode != oldValue{
            _i2c.writeByte(Register.OPR_MODE.addr,_mode.rawValue)
            usleep(50_000)
        }}
    }
    // MARK: ■ begin
    private func begin(mode:OpMode)->Bool{ // Sets up the HW
        /* Make sure we have the right device */
        var id = _i2c.readByte(Register.CHIP_ID.addr)
        if id != BNO055.ID{
            usleep(1_000_000); // hold on for boot
            id = _i2c.readByte(Register.CHIP_ID.addr)
            if id != BNO055.ID{ return false } // still not? ok bail
        }
        /* Switch to config mode (just in case since this is the default) */
        _mode = .CONFIG
        /* Reset */ // <------------------ PROBLEM HERE - always aborts !
        //_i2c.write8(Register.SYS_TRIGGER.addr, 0x20)
        //while _i2c.read8(Register.CHIP_ID.addr) != _BNO055.ID{ __delay(10) }
        //__delay(50)
        /* Set to normal power mode */
        _i2c.writeByte(Register.PWR_MODE.addr, PowerMode.NORMAL.rawValue)
        usleep(10_000)
        _i2c.writeByte(Register.PAGE_ID.addr, 0)
        /* Set the output units */
        let unitsel:UInt8 = 0b00000110
            /*
            (0 << 7) | // Orientation = Windows
            (0 << 4) | // Temperature = Celsius
            (1 << 2) | // Euler = Radians
            (1 << 1) | // Gyro = Rads
            (0 << 0);  // Accelerometer = m/s^2
            */
        _i2c.writeByte(Register.UNIT_SEL.addr, unitsel)
        /* Configure axis mapping (see section 3.4) */
        /*
         write8(Register.AXIS_MAP_CONFIG.addr, REMAP_CONFIG_P2); // P0-P7, Default is P1
         delay(10);
         write8(Register.AXIS_MAP_SIGN.addr, REMAP_SIGN_P2); // P0-P7, Default is P1
         delay(10);
         */
        /* clear the sys trigger */ // <------------------ PROBLEM HERE - always aborts !
        //_i2c.write8(Register.SYS_TRIGGER.addr, 0x0)
        //__delay(10)
        /* Set the requested operating mode (see section 3.3) */
        _mode = mode
        usleep(20_000)
        return true
    }
    // MARK: ■ Registers
    private enum Register: UInt8{
        var addr: UInt8{ return rawValue }
        /* Page id register definition */
        case PAGE_ID                    = 0x07
        /* PAGE0 REGISTER DEFINITION START*/
        case CHIP_ID                    = 0x00
        /* Accel data register */
        case ACC_DATA_X_LSB             = 0x08
        case ACC_DATA_X_MSB             = 0x09
        case ACC_DATA_Y_LSB             = 0x0A
        case ACC_DATA_Y_MSB             = 0x0B
        case ACC_DATA_Z_LSB             = 0x0C
        case ACC_DATA_Z_MSB             = 0x0D
        /* Mag data register */
        case MAG_DATA_X_LSB             = 0x0E
        case MAG_DATA_X_MSB             = 0x0F
        case MAG_DATA_Y_LSB             = 0x10
        case MAG_DATA_Y_MSB             = 0x11
        case MAG_DATA_Z_LSB             = 0x12
        case MAG_DATA_Z_MSB             = 0x13
        /* Gyro data registers */
        case GYR_DATA_X_LSB             = 0x14
        case GYR_DATA_X_MSB             = 0x15
        case GYR_DATA_Y_LSB             = 0x16
        case GYR_DATA_Y_MSB             = 0x17
        case GYR_DATA_Z_LSB             = 0x18
        case GYR_DATA_Z_MSB             = 0x19
        /* Euler data registers */
        case EULER_H_LSB                = 0x1A
        case EULER_H_MSB                = 0x1B
        case EULER_R_LSB                = 0x1C
        case EULER_R_MSB                = 0x1D
        case EULER_P_LSB                = 0x1E
        case EULER_P_MSB                = 0x1F
        /* Quaternion data registers */
        case QUATERNION_DATA_W_LSB      = 0x20
        case QUATERNION_DATA_W_MSB      = 0x21
        case QUATERNION_DATA_X_LSB      = 0x22
        case QUATERNION_DATA_X_MSB      = 0x23
        case QUATERNION_DATA_Y_LSB      = 0x24
        case QUATERNION_DATA_Y_MSB      = 0x25
        case QUATERNION_DATA_Z_LSB      = 0x26
        case QUATERNION_DATA_Z_MSB      = 0x27
        /* Linear acceleration data registers */
        case LINEAR_ACC_DATA_X_LSB      = 0x28
        case LINEAR_ACC_DATA_X_MSB      = 0x29
        case LINEAR_ACC_DATA_Y_LSB      = 0x2A
        case LINEAR_ACC_DATA_Y_MSB      = 0x2B
        case LINEAR_ACC_DATA_Z_LSB      = 0x2C
        case LINEAR_ACC_DATA_Z_MSB      = 0x2D
        /* Gravity data registers */
        case GRAVITY_DATA_X_LSB         = 0x2E
        case GRAVITY_DATA_X_MSB         = 0x2F
        case GRAVITY_DATA_Y_LSB         = 0x30
        case GRAVITY_DATA_Y_MSB         = 0x31
        case GRAVITY_DATA_Z_LSB         = 0x32
        case GRAVITY_DATA_Z_MSB         = 0x33
        /* Temperature data register */
        case TEMPERATURE                = 0x34
        /* Uint selection registers */
        case UNIT_SEL                   = 0x3B
        /* Mode registers */
        case OPR_MODE                   = 0x3D
        case PWR_MODE                   = 0x3E
        case SYS_TRIGGER                = 0x3F
    }
    // MARK: ■ PowerMode
    private enum PowerMode:UInt8{
        case NORMAL      = 0x00
        case LOWPOWER    = 0x01
        case SUSPEND     = 0x02
    }
    // MARK: ■ OpMode
    private enum OpMode:UInt8{
        /* Operation mode settings*/
        case CONFIG          = 0x00
        case ACC_ONLY         = 0x01
        case MAG_ONLY         = 0x02
        case GYR_ONLY         = 0x03
        case ACC_MAG          = 0x04
        case ACC_GYRO         = 0x05
        case MAG_GYRO         = 0x06
        case ACC_MAG_GYR             = 0x07
        case IMU_PLUS         = 0x08
        case COMPASS         = 0x09
        case M4G             = 0x0A
        case NDOF_FMC_OFF    = 0x0B
        case NDOF            = 0x0C
    }
    // MARK: ■ VectorType
    private enum VectorType:UInt8{
        case ACC            = 0x08 // ACCEL_DATA_X_LSB
        case MAG            = 0x0E // MAG_DATA_X_LSB
        case GYR            = 0x14 // GYRO_DATA_X_LSB
        case EULER          = 0x1A // EULER_H_LSB
        case LINEAR_ACC     = 0x28 // LINEAR_ACCEL_DATA_X_LSB
        case GRAVITY        = 0x2E // GRAVITY_DATA_X_LSB
        func convert_to_reg_t() -> Register{
            switch self{
            case .ACC: return .ACC_DATA_X_LSB
            case .MAG: return .MAG_DATA_X_LSB
            case .GYR: return .GYR_DATA_X_LSB
            case .EULER: return .EULER_H_LSB
            case .LINEAR_ACC: return .LINEAR_ACC_DATA_X_LSB
            case .GRAVITY: return .GRAVITY_DATA_X_LSB
            }
        }
    }
    
    private func _LSB(_ u:UInt16)->UInt8{ return UInt8(u & 0x00FF) }
    private func _MSB(_ u:UInt16)->UInt8{ return UInt8(u >> 8) }
    
    private func _FLOAT(_ a:UInt8,_ b:UInt8)->Float32{
        let v = Float32( UInt16(a) | (UInt16(b) << 8) )
        return v > 32767 ? -(65535 - v) : v
    }
    // MARK: ■ getTemperature
    private func getTemperature() -> UInt8?{ // Gets the temperature in degrees celsius
        return _i2c.readByte(Register.TEMPERATURE.addr)
    }
    // MARK: ■ getXYZ
    private func getXYZ(type: VectorType)->F3?{ // Gets a vector reading from the specified source
        if let bytes = _i2c.readN(type.convert_to_reg_t().rawValue,6){
            let x = _FLOAT(bytes[0],bytes[1])
            let y = _FLOAT(bytes[2],bytes[3])
            let z = _FLOAT(bytes[4],bytes[5])
            /* Convert the value to an appropriate range (section 3.6.4) */
            /* and assign the value to the Vector type */
            switch type{
            case .MAG: /* 1uT = 16 LSB */ fallthrough
            case .GYR: /* 1dps = 16 LSB */
                return F3(x/16.0,y/16.0,z/16.0)
            case .EULER: /* 1 rad = 900 LSB */
                return F3((y/900.0).πclip,(x/900.0).πclip,(z/900.0).πclip)
            case .ACC: fallthrough
            case .LINEAR_ACC: fallthrough
            case .GRAVITY:
                /* 1m/s^2 = 100 LSB */
                return F3(x/100.0, y/100.0, z/100.0)
            }
        }else{ __log__.err("BNO055: getXYZ - i2c.read8 failure") }
        return nil
    }
    
    // Gets a quaternion reading from the specified source
    /*
     func getWXYZ() -> WXYZ?{
     let bytes = _i2c.read8(Register.QUATERNION_DATA_W_LSB.addr, 8)
     let w = Float( I16(bitPattern: U16(bytes[0]) | (U16(bytes[1]) << 8) ) )
     let x = Float( I16(bitPattern: U16(bytes[2]) | (U16(bytes[3]) << 8) ) )
     let y = Float( I16(bitPattern: U16(bytes[4]) | (U16(bytes[5]) << 8) ) )
     let z = Float( I16(bitPattern: U16(bytes[6]) | (U16(bytes[7]) << 8) ) )
     /* Assign to Quaternion */
     /* See http://ae-bst.resource.bosch.com/media/products/dokumente/bno055/BST_BNO055_DS000_12~1.pdf
     3.6.5.5 Orientation (Quaternion)  */
     let scale: Float = ( 1.0 / Float( 1 << 14 ) )
     return WXYZ(scale * w, scale * x, scale * y, scale * z)
     
     //return nil
     }*/
    
}
