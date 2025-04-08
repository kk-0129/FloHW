// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox
//import SwiftyGPIO

// MARK: ■ PCA9685
public class PCA9685{
    /*
     Adafruit PCA9685 16-Channel Servo Driver
     https://learn.adafruit.com/16-channel-pwm-servo-driver/overview
     */
    // MARK: ■ MOTOR
    public func motor(_ ch:UInt8,_ d:@escaping Motor.Dir)->Motor{ return Motor(self,ch,d) }
    public class Motor{
        public typealias Dir = (Bool)->() // Directional Control (true = forward)
        private let dir:Dir
        private let ch:UInt8
        private let a16:PCA9685
        fileprivate init(_ a:PCA9685,_ ch:UInt8,_ d:@escaping Dir){
            a16 = a
            self.ch = ch
            dir = d
            __u()
        }
        public var vel:Float32=0{ didSet{ if vel != oldValue{ __u() }}}
        private func __u(){
            dir(vel > 0)
            var f = abs(vel)
            if f > 1.0{ f = 1.0 }
            else if f < 0.1{ f = 0.0 }
            a16.pwm(ch,0,UInt16(f*4095))
        }
    }
    // MARK: ■ SERVO
    public func servo(_ ch:UInt8,_ rc:Servo.Range)->Servo{ return Servo(self,ch,rc) }
    public class Servo{
        public typealias Range = (lo:UInt16,hi:UInt16,inv:Bool)
        private let ch:UInt8
        private let rc:Range
        private let a16:PCA9685
        fileprivate init(_ a:PCA9685,_ ch:UInt8,_ rc:Range){
            self.ch = ch
            self.rc = (lo:min(rc.lo,rc.hi),hi:max(rc.lo,rc.hi),inv:rc.inv)
            a16 = a
            self.pos = 0
        }
        public var pos:Float32 = 0{ didSet{ if pos != oldValue{ // -1 to +1
            var f = ((pos+1)*0.5).clip(0,1)
            if rc.inv{ f = 1-f } // invert
            let pulse_width = rc.lo + UInt16(f*Float32(rc.hi-rc.lo))
            a16.pwm(ch,0,pulse_width)
        }}}
    }
    
    private let _i2c:I2C
    // MARK: ■ INIT
    init?(_ i2c:I2C){
        self._i2c = i2c
        usleep(100_000)
        _i2c.writeByte(self._MODE1,0x00)
        usleep(100_000)
        __log__.info("Adafruit PWMx16 initiated on i2c [0x\(String(i2c.addr,radix:16))]")
        DispatchQueue.global().async { self._initFreq() }
    }
    
    // MARK: ■ pwm(ch,on,off)
    public func pwm(_ ch:UInt8,_ on:UInt16,_ off:UInt16){
        let _ch = 4 * ch
        //<<"pwm: ch:\(_ch) on:\(on) off:\(off)"
        _i2c.writeByte(self._LED0_ON_L + _ch, UInt8(on & 0xFF))
        _i2c.writeByte(self._LED0_ON_H + _ch, UInt8(on >> 8))
        _i2c.writeByte(self._LED0_OFF_L + _ch, UInt8(off & 0xFF))
        _i2c.writeByte(self._LED0_OFF_H + _ch, UInt8(off >> 8))
    }
    
    // MARK: ■ allPwmOff()
    public func allPwmOff(_ on:Bool){
        _i2c.writeByte(self._ALLLED_ON_L, 0)
        _i2c.writeByte(self._ALLLED_ON_H, 0)
        _i2c.writeByte(self._ALLLED_OFF_L, 0)
        _i2c.writeByte(self._ALLLED_OFF_H, 0)
    }
    
    // MARK: ■ Registers
    private let _SUBADR1:UInt8 = 0x02
    private let _SUBADR2:UInt8 = 0x03
    private let _SUBADR3:UInt8 = 0x04
    private let _MODE1:UInt8 = 0x00
    private let _PRESCALE:UInt8 = 0xFE
    private let _LED0_ON_L:UInt8 = 0x06
    private let _LED0_ON_H:UInt8 = 0x07
    private let _LED0_OFF_L:UInt8 = 0x08
    private let _LED0_OFF_H:UInt8 = 0x09
    private let _ALLLED_ON_L:UInt8 = 0xFA
    private let _ALLLED_ON_H:UInt8 = 0xFB
    private let _ALLLED_OFF_L:UInt8 = 0xFC
    private let _ALLLED_OFF_H:UInt8 = 0xFD
    
    // MARK: ■ Freq
    private var _freq: Float = 100.0
    private func _initFreq(){
        var prescaleval:Float = 25000000.0 // 25MHz
        prescaleval /= 4096.0 //12-bit
        prescaleval /= _freq
        prescaleval -= 1.0
        let prescale = floor(prescaleval + 0.5)
        let oldmode = _i2c.readByte(_MODE1)
        let newmode:UInt8 = (oldmode & 0x7F) | 0x10 // sleep
        _i2c.writeByte(_MODE1, newmode) // go to sleep
        _i2c.writeByte(_PRESCALE, UInt8(floor(prescale)))
        _i2c.writeByte(_MODE1, oldmode)
        usleep(5000)
        _i2c.writeByte(_MODE1, oldmode | 0x80)
    }
    
}

