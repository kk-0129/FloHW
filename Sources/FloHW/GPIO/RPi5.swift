// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox
#if os(Linux)
import Glibc
#elseif os(macOS) || os(iOS)
private var O_SYNC: CInt { fatalError("Linux only") }
import Darwin.C
#endif

/*
 https://lloydrochester.com/post/hardware/libgpiod-blink-led-rpi/
 https://www.mastering-swift.com/post/controlling-gpio-pins-with-swift-and-libgpiod
 */

// MARK: ■ R-PI Pins
fileprivate var _pins = [UInt:RPi5.Pin]()

// MARK: ■ RP
public final class RPi5 {
    public static subscript(_ u:UInt)->Pin?{
        get{var p:Pin?
            if u>=2 && u<=31{ // valid pin numbers
                p = _pins[u]
                if p == nil{ p = Pin(u); _pins[u] = p }
            }
            return p
        }
    }
    // MARK: ■ Pin
    public final class Pin{
        
        private var id:UInt = 0
        
        // MARK: ■ init
        fileprivate init(_ id:UInt){
            self.id = id
            self.out = true
            self.high = false
        }

        // MARK: ■ out
        public var out:Bool{
            get{
                return true // TODO: how to get pin IN/OUT setting ?
            }
            set(v){
                // TODO: how to set pin IN/OUT setting ?
            }
        }

        // MARK: ■ high
        public var high = false{ didSet{ if high != oldValue{
            //print("\(id).high --> \(high)")
            DispatchQueue.global().async {
                let task = Process()
                task.executableURL = URL(fileURLWithPath:"/bin/gpioset")
                task.arguments = [ "gpiochip0","\(self.id)=\(self.high ? "1" : "0")" ]
                do{
                    try task.run()
                }catch{ __log__.err(error.localizedDescription) }
            }
        }}}
        
    }
    
}
