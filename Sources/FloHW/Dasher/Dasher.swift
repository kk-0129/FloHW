// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

/*
 from a terminal ...
 ssh dasher@10.99.1.223 + Dasher45K (home)
 ssh dasher@10.255.254.3 + Dasher45K (skynet)
 cd Swift/Dasher
 swift run
 scp Dasher.swift dasher@10.99.1.223:Swift/FloHW/Sources/FloHW/Dasher (home)
 scp Dasher.swift dasher@10.255.254.3:Swift/FloHW/Sources/FloHW/Dasher
 */

private let PORT = ":9992"
private let KLM_AIR = "10.99.1.223"
private let SKY_NET = "10.255.254.3"
private let LOCAL_HOST = KLM_AIR
private let ____ADDR____ = LOCAL_HOST + PORT
//private let VIDEO_HOST = "10.255.254.3"
private let VIDEO_PORT = ":9800"
private let ____VIDEO_ADDR____ = LOCAL_HOST + VIDEO_PORT

// MARK: ■ Dasher
public class Dasher{
    
    public static func launch(){
        
        _ = VIDEO_STRUCT.register()
        if let addr = IPv4.from(____ADDR____),
           let i2c = SwiftyGPIO.hardwareI2C(for:.RaspberryPi4),
           let head = DasherHead(____VIDEO_ADDR____),
           let box = MyBox(i2c){
            do{
                 let d = Device(
                     Device.Name("Dasher"),
                     endpoint:try UDP.EP(ipa:addr),
                     boxs:[
                         head,
                         box
                     ]
                 )
                d.periodic = {
                    box.periodic()
                }
                 __log__.info("Dasher server launched @ \(addr.uri)")
                 d.waitForExit()
            }catch let e{ __log__.err(e.localizedDescription) }
        }else{ __log__.err("Dasher failed setup") }
    }
    
}

class MyBox : Device.Box{
    
    let skin = Skin(
        "Dasher",
        ["gimball":XY,
         "arms":XY,
         "wheels":XY,
         "led":.BOOL(),
         "light":.FLOAT(),
         "eye":.BOOL()
        ],
        ["gimball":XY,
         "arms":XY,
         "wheels":XY,
         "led":.BOOL(),
         "light":.FLOAT(),
         "euler":Euler,
         "accel":XYZ,
         "gravity":XYZ
        ]
    )
    
    private var gimball:MyServo!
    private var arms:MyServo!
    private var wheels:MyMotor!
    private var led_pin:RPi5.Pin!
    private let bno055:BNO055
    private let ssd:SSD1306
    
    init?(_ i2c:I2CInterface){
        guard let PCA = PCA9685(i2c.at(0x40)) else{ __log__.err("failed PCA9685"); return nil }
        guard let p16 = RPi5[16] else{ __log__.err("failed RPi5[16]"); return nil }
        guard let p19 = RPi5[19] else{ __log__.err("failed RPi5[19]"); return nil }
        guard let p20 = RPi5[20] else{ __log__.err("failed RPi5[20]"); return nil }
        guard let p21 = RPi5[21] else{ __log__.err("failed RPi5[21]"); return nil }
        guard let p26 = RPi5[26] else{ __log__.err("failed RPi5[26]"); return nil }
        bno055 = BNO055(i2c.at(0x29))
        ssd = SSD1306(i2c.at(0x3c),._128x64)
        ssd.inverted = true
        gimball = MyServo(PCA.servo(1,(475,1000,false)),PCA.servo(14,(440,900,false))){ f2 in
            self.callback?(["gimball":Event(f2.xy)])
        }
        arms = MyServo(PCA.servo(0,(520,830,false)),PCA.servo(15,(440,750,true))){ f2 in
            self.callback?(["arms":Event(f2.xy)])
        }
        led_pin = p21
        //p.direction = .OUT
        p21.high = false
        wheels = MyMotor(PCA.motor(12,{
            p16.high = $0
            p20.high = !$0
        }),PCA.motor(3){
            p19.high = $0
            p26.high = !$0
        }){ f2 in self.callback?(["wheels":Event(f2.xy)]) }
    }
    
    var led = false{ didSet{
        led_pin?.high = led
        callback?(["led":Event(led)])
    }}
    
    func periodic(){
        gimball.periodic()
        arms.periodic()
        wheels.periodic()
        self.callback?([
            "euler":  Event(bno055.euler.euler),
            "accel":  Event(bno055.accelerometer.xyz),
            "gravity":  Event(bno055.gravity.xyz)
        ])
    }
    
    func publish(_ inputs:[Ports.ID:Event]){
        for (k,e) in inputs{
            switch k{
            case "gimball": gimball.target = __XY2F2__(e)
            case "arms": arms.target = __XY2F2__(e)
            case "wheels": wheels.target = __XY2F2__(e,true)
            case "led": led = (e.value as? Bool) ?? false
            case "eye":
                // TODO: temporary ..
                let x = e.value as? Bool ?? false
                ssd.display(strings:x ? EYE_PATTERN_1 : EYE_PATTERN_2)
            default: break
            }
        }
    }
    
    var callback: (([FloBox.Ports.ID : FloBox.Event]) -> ())?
    
}

private func __XY2F2__(_ e:Event,_ neg:Bool = false)->F2?{
    if let v = e.value as? Struct,v.isa(XY),
       let x = v["x"] as? Float32, let y = v["y"] as? Float32{
        return neg ? F2(-x,-y) : F2(x,y)
    }
    return nil
}

typealias F2 = SIMD2<Float32>
extension F2{
    var xy:Struct{ return XY.instance(["x":x,"y":y])! }
    static prefix func -(a:F2)->F2{ return F2(x:-a.x,y:-a.y) }
}

class MyServo{
    
    var target:F2?
    let servo1:PCA9685.Servo
    let servo2:PCA9685.Servo
    let callback:(F2)->()
    
    init(_ s1:PCA9685.Servo,_ s2:PCA9685.Servo,_ cb:@escaping(F2)->()){
        servo1 = s1
        servo2 = s2
        callback = cb
    }
    
    func periodic(){
        let d1 = (target?.x ?? Float32(0)) - servo1.pos
        let d2 = (target?.y ?? Float32(0)) - servo2.pos
        if d1 + d2 != 0{
            let r:Float32 = target == nil ? 0.05 : 0.2
            servo1.pos = (servo1.pos + (d1*r)).clip(-1,1)
            servo2.pos = (servo2.pos + (d2*r)).clip(-1,1)
            callback(F2(servo1.pos,servo2.pos))
        }
    }
    
}

class MyMotor{
    
    var target:F2?
    let motor1:PCA9685.Motor
    let motor2:PCA9685.Motor
    let callback:(F2)->()
    
    init(_ m1:PCA9685.Motor,_ m2:PCA9685.Motor,_ cb:@escaping(F2)->()){
        motor1 = m1
        motor2 = m2
        callback = cb
    }
    
    func periodic(){
        let d1 = (target?.x ?? Float32(0)) - motor1.vel
        let d2 = (target?.y ?? Float32(0)) - motor2.vel
        if d1 + d2 != 0{
            let r:Float32 = target == nil ? 0.05 : 0.2
            motor1.vel = (motor1.vel + (d1*r)).clip(-1,1)
            motor2.vel = (motor2.vel + (d2*r)).clip(-1,1)
            callback(F2(motor1.vel,motor2.vel))
        }
    }
    
}
