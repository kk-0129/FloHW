// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

// MARK: ■ Wheels

private let __LEFT__ = "left"
private let __RIGHT__ = "right"

class FlakeWheels: Device.Box{
    
    let skin = Skin(
        "Wheels",
        [__LEFT__:.FLOAT(),__RIGHT__:.FLOAT()],
        [:]
    )
    
    var _R,_L:PCA9685.Motor
    
    init?(_ a:PCA9685){
        //let gpios = SwiftyGPIO.GPIOs(for:.RaspberryPi4)
        if let p_19 = RPi5[19],
           let p_26 = RPi5[26],
           let p_16 = RPi5[16],
           let p_20 = RPi5[20]{
            p_19.out = true
            p_26.out = true
            p_16.out = true
            p_20.out = true
            _L = a.motor(12){
                p_19.high = $0
                p_26.high = !$0
            }
            _R = a.motor(3){
                p_16.high = $0
                p_20.high = !$0
            }
        }
        /*
        if let p_19 = gpios[.P19],
           let p_26 = gpios[.P26],
           let p_16 = gpios[.P16],
           let p_20 = gpios[.P20]{
            p_19.direction = .OUT
            p_26.direction = .OUT
            p_16.direction = .OUT
            p_20.direction = .OUT
            _L = a.motor(12){
                p_19.value = $0 ? 1 : 0
                p_26.value = $0 ? 0 : 1
            }
            _R = a.motor(3){
                p_16.value = $0 ? 1 : 0
                p_20.value = $0 ? 0 : 1
            }
        }*/else{
            return nil
        }
    }
    
    func publish(_ inputs:[Ports.ID:Event]){
        for (k,e) in inputs{
            switch k{
            case __LEFT__: _L.vel = -( (e.value as? Float32) ?? Float32(0) )
            case __RIGHT__: _R.vel = -( (e.value as? Float32) ?? Float32(0) )
            default: break
            }
        }
    }
    
    var callback: (([FloBox.Ports.ID : FloBox.Event]) -> ())?
    
}
