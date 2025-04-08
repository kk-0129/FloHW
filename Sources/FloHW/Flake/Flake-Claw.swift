// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

// MARK: Claw
class FlakeClaw: Device.Box{
    
    public let skin = Skin(
        "Claw",
        ["grip":.BOOL(),"down":.BOOL()],
        [:]
    )
    private var _grip:PCA9685.Servo
    private var _lift:PCA9685.Servo
    private var _target_grip = Float32(0)
    private var _target_lift = Float32(0)
    
    public init(_ pca:PCA9685){
        _grip = pca.servo(1,(350,675,false))
        _lift = pca.servo(0,(410,530,false))
    }
    
    public func publish(_ inputs:[Ports.ID:Event]){
        for (n,e) in inputs{
            switch n{
            case "grip":
                _target_grip = (e.value as? Bool ?? false) ? 1 : -1
            case "down":
                _target_lift = (e.value as? Bool ?? false) ? 1 : -1
            default: break
            }
        }
    }
    
    public var callback: (([FloBox.Ports.ID : FloBox.Event]) -> ())?
    
    func tick(){
        let dx = _target_grip - _grip.pos
        let dy = _target_lift - _lift.pos
        if dx+dy != 0{
            _grip.pos = (_grip.pos + (dx*0.05)).clip(-1,1)
            _lift.pos = (_lift.pos + (dy*0.05)).clip(-1,1)
        }
    }
    
}
