// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

// MARK: Head
class FlakeHead: Device.Box, UDP.RawRecipient{
    
    public let skin = Skin(
        "Head",
        ["pan/tilt":XY,"eyes":.FLOAT(),"video":.BOOL()],
        ["pan/tilt":XY,"eyes":.FLOAT(),"video":VIDEO_STRUCT]
    )
    private let vip$: String // dst IP of VIDEO streaming
    private var _pan:PCA9685.Servo
    private var _tilt:PCA9685.Servo
    private var _eyeL:PCA9685.Servo
    private var _eyeR:PCA9685.Servo
    private var _ssdL:SSD1306
    private var _ssdR:SSD1306
    private let udp:UDP.EP
    private var target_pan_and_tilt:(Float32,Float32,Float32) = (0,0,0.1)
    
    public init?(_ i2c:I2CInterface,_ pca:PCA9685,_ vip:String){
        vip$ = vip
        if let addr = IPv4.from(vip){
            _pan = pca.servo(7,(450,850,false))
            _tilt = pca.servo(8,(340,640,false))
            _eyeL = pca.servo(6,(550,750,false))
            _eyeR = pca.servo(9,(575,775,false))
            _ssdL = SSD1306(i2c.at(0x3c),._128x64)
            _ssdR = SSD1306(i2c.at(0x3d),._128x64)
            _pan.pos = 0
            _tilt.pos = 0
            _eyeL.pos = 0
            _eyeR.pos = 0
            do{
                udp = try UDP.EP(ipa:addr)
            }catch let e{
                print(e.localizedDescription)
                return nil
            }
            _ssdL.display(strings:EYE_PATTERN_1)
            _ssdR.display(strings:EYE_PATTERN_1)
        }else{ return nil }
    }
    deinit{
        __stop_streaming__()
    }
    
    func tick(){
        let dx = target_pan_and_tilt.0 - _pan.pos
        let dy = target_pan_and_tilt.1 - _tilt.pos
        if dx+dy != 0{
            let rate = target_pan_and_tilt.2
            _pan.pos = (_pan.pos + (dx*rate)).clip(-1,1)
            _tilt.pos = (_tilt.pos + (dy*rate)).clip(-1,1)
        }
        let s = XY.instance(["x":_pan.pos,"y":_tilt.pos])
        callback?(["pan/tilt":Event(s)])
        let x = Int.random(in:0...10)
        if x == 0{
            _ssdL.display(strings:EYE_PATTERN_1)
            _ssdR.display(strings:EYE_PATTERN_1)
        }else if x == 1{
            _ssdL.display(strings:EYE_PATTERN_2)
            _ssdR.display(strings:EYE_PATTERN_2)
        }
    }
    
    var video = false{ didSet{
        if video{ __start_streaming__() }
        else{ __stop_streaming__() }
    }}
    
    public func publish(_ inputs:[Ports.ID:Event]){
        for (n,e) in inputs{
            switch n{
            case "pan/tilt":
                if let s = e.value as? Struct,
                    s.isa(XY),
                    let x = s["x"] as? Float32,
                    let y = s["y"] as? Float32{
                    target_pan_and_tilt = (x,y,0.1)
                }else{
                    target_pan_and_tilt = (0,0,0.01)
                }
            case "eyes":
                let f = e.value as? Float32 ?? Float32(0)
                _eyeL.pos = f
                _eyeR.pos = -f
                callback?(["eyes":Event(f)])
            case "video":
                video = (e.value as? Bool) ?? false
            default: break
            }
        }
    }
    
    public var callback: (([FloBox.Ports.ID : FloBox.Event]) -> ())?
    
    var task:Process?
    func __start_streaming__(){
        udp.rawRecipient = self
        print("starting video stream ..")
        task = Process()
        task!.executableURL = URL(fileURLWithPath:"/bin/rpicam-vid")
        task!.arguments = [
            "--camera","0", // THIS MAY NOT WORK ON RASP 4 !!!
            "-t","0", // do it now
            "--inline",
            "--codec","h264",
            "--intra","10",
            "--framerate","10",
            "-n", // no preview
            "--width","640",
            "--height","480",
            "-o","udp://"+vip$
        ]
        do{
            try self.task!.run()
        }catch let e{
            __log__.err(e.localizedDescription)
        }
    }
    
    // MARK: UDP.RawRecipient
    //let Q = DispatchQueue.global(qos:.utility)
    public let maxBufferSize = 40_000
    public func received(data bytes:inout[UInt8]){
        var event = Event()
        if !bytes.isEmpty{
            //print("raw - received \(bytes.count) bytes")
            let s = VIDEO_STRUCT.instance([
                "width" : Float32(320),
                "height" : Float32(240),
                "data" : Data(bytes)
            ])
            event = Event(s)
        }
        self.callback?(["video":event])
    }
    
    private func __stop_streaming__(){
        //udp.rawRecipient = nil
        task?.terminate()
        task = nil
    }
    
}
