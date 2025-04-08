// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

private let PORT = ":9992"
private let KLM_AIR = "10.99.1.212"
private let SKY_NET = "10.255.254.2"
private let HOST = KLM_AIR
private let ____ADDR____ = HOST+PORT
private let VIDEO_PORT = ":9993"
private let ____VIDEO_ADDR____ = HOST+VIDEO_PORT

private let __Video_Struct__$ = "Video"
private let __width__$ = "width"
private let __height__$ = "height"
private let __data__$ = "data"

// MARK: ■ Flake
public class Flake{
    
    private static var clock:__clock__?
    private static var tock = 0
    
    public static func launch(){
        _ = VIDEO_STRUCT.register()
        if let addr = IPv4.from(____ADDR____),
           let i2c = SwiftyGPIO.hardwareI2C(for:.RaspberryPi4),
           let PCA = PCA9685(i2c.at(0x40)),
           let head = FlakeHead(i2c,PCA,____VIDEO_ADDR____)
           //,let wheels = FlakeWheels(PCA)
        {
            do{
                let claw = FlakeClaw(PCA)
                 let d = Device(
                     Device.Name("Flake"),
                     endpoint:try UDP.EP(ipa:addr),
                     boxs:[
                         Test(),
                         head,
                         claw,
                         //wheels
                         //YDLidar(),
                         //BNO055("Front IMU",I2C(0x29,1)),
                         //BNO055("Rear IMU",I2C(0x29,1)),
                         //Sensors(arduino),
                         //Sounds()
                     ]
                 )
                 clock = __clock__(ms:10){
                     switch tock{
                     case 0: head.tick()
                     case 1: claw.tick()
                     default: break
                     }
                     tock += 1
                     if tock == 2{ tock = 0 }
                 }
                 clock!.running = true
                 __log__.info("Flake server launched @ \(addr.uri)")
                 d.waitForExit()
            }catch let e{ __log__.err(e.localizedDescription) }
        }else{ __log__.err("Flake failed setup") }
    }
    
}

// MARK: ■ Test
private class Test:Device.Box{
    
    let skin = Skin("Test",["in":.BOOL()],["out":.BOOL()])
    var state = false{ didSet{ if state != oldValue{
        callback?(["out":Event(state)])
    } }}
    
    func publish(_ inputs:[Ports.ID:Event]){
        for (k,e) in inputs{
            switch k{
            case "in": state = (e.value as? Bool) ?? false
            default: break
            }
        }
    }
    
    var callback:(([Ports.ID:FloBox.Event])->())?
    
}

// MARK: ■ Head
/*
private class Head:Box{
    
    static let _box = Node(
        "Head",
        ["pan":.FLOAT32,"tilt":.FLOAT32,"torch":.FLOAT32,"left":.FLOAT32,"right":.FLOAT32],
        ["pan":.FLOAT32,"tilt":.FLOAT32,"torch":.FLOAT32,"left":.FLOAT32,"right":.FLOAT32])
    
    private var _pan,_tilt,_torch,_left,_right:PCA9685.Servo
    
    init(_ a:PCA9685){
        _pan = a.servo(2,(350,850,false))
        _tilt = a.servo(1,(340,640,false))
        _torch = a.servo(5,(0,4095,false))
        _left = a.servo(6,(400,1000,false)) // ears, still to add :)
        _right = a.servo(7,(450,1000,false))
        super.init(Head._box)
    }
    
    override func invoke(_ t: TIME_INTERVAL?){
        if inputs.count == 5, outputs.count == 5{
            if let v = inputs[0] as? F{ _pan.pos = v }
            if let v = inputs[1] as? F{ _tilt.pos = v }
            if let v = inputs[2] as? F{ _torch.pos = v }
            if let v = inputs[3] as? F{ _left.pos = v }
            if let v = inputs[4] as? F{ _right.pos = v }
            outputs = [_pan.pos,_tilt.pos,_torch.pos,_left.pos,_right.pos]
        }
    }
}*/


/*
// MARK: ■ Wheels
private class Wheels:Box{
    
    static let _box = Node("Wheels",["left":.FLOAT32,"right":.FLOAT32],[:])
    
    private var _R,_L:PCA9685.Motor
    
    init(_ a:PCA9685){
        _L = a.motor(14){ RPi[25]?.high = $0; RPi[24]?.high = !$0 }
        _R = a.motor(15){ RPi[23]?.high = $0; RPi[22]?.high = !$0 }
        super.init(Wheels._box)
    }
    
    override func invoke(_ t: TIME_INTERVAL?){
        if inputs.count == 2{
            _L.vel = -((inputs[0] as? F) ?? F(0))
            _R.vel = -((inputs[1] as? F) ?? F(0))
        }
    }
}

// MARK: ■ Arduino Sensors
private class Sensors:Box{
    
    static let _box = Node("Sensors",[:],["front":F3.t,"back":F3.t,"left":F3.t,"right":F3.t])
    
    let arduino: Arduino.Serial
    init(_ a:Arduino.Serial){
        arduino = a
        super.init(Sensors._box)
    }
    
    override func invoke(_ t: TIME_INTERVAL?){
        let o = arduino.out
        if o.count == 12{
            outputs = [
                F3(o[0],o[1],o[2]),
                F3(o[3],o[4],o[5]),
                F3(o[6],o[7],o[8]),
                F3(o[9],o[10],o[12])
            ]
        }
    }
}

// MARK: ■ Sounds
private class Sounds:Box{
    
    static let _box = Node("Sounds",["speak":.STRING8_SMALL(0),"play":.STRING8_SMALL(0)],[:])
    
    init(){ super.init(Sounds._box) }
    
    override func invoke(_ t: TIME_INTERVAL?){
        if inputs.count == 2{
            if let s = inputs[0] as? S{
                print("TODO: speak \"\(s)\"")
                EXEC("echo '\(s)' | festival --tts")
            }
            if let s = inputs[1] as? S{
                print("TODO: play audio '\(s)'")
                EXEC("mpg321 /home/pi/Downloads/alarm.mp3")
            }
        }
    }
}
 
// MARK: ■ EXEC
private func EXEC(_ s:S){
    DispatchQueue.global().async{
        do{
            let url = URL(fileURLWithPath:"/bin/bash")
            let args = ["-c",s]
            if #available(OSX 10.13, *) {
                _ = try Process.run(url,arguments:args){ _ in }
            } else {
                // Fallback on earlier versions
            }
        }catch let e{
            __FLOG__( e.localizedDescription )
        }
    }
}
*/
