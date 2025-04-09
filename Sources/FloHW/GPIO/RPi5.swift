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
