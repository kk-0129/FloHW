// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

protocol SSD1306_Image{
   var width: UInt8{ get }
   var height: UInt8{ get }
   func pixel(_ x: UInt8,_ y: UInt8)->Bool
}
/*
 original: https://github.com/adafruit/Adafruit_Python_SSD1306/blob/master/Adafruit_SSD1306/SSD1306.py
      alt: https://github.com/adafruit/Adafruit_SSD1306/blob/master/Adafruit_SSD1306.cpp
 */

class SSD1306{
    
    public enum Size{
        case _128x64, _128x32, _96x16
        var width:Int{
            switch self{
            case ._128x64,._128x32: return 128
            case ._96x16: return 96
            }
        }
        var height:Int{
            switch self{
            case ._128x64: return 64
            case ._128x32: return 32
            case ._96x16: return 16
            }
        }
    }
    
    private var ext:Bool{ return _vccstate == SSD1306.EXTERNALVCC }
    private let i2c:I2C
    private var _vccstate: UInt8 = SSD1306.SWITCHCAPVCC
    let size:Size
    
    private typealias WORD = [UInt8] // 32 bytes = 4 chars
    private typealias ROW = [WORD] // 4 in a row
    private var BUFFER = [ROW]() // 8 rows
    private var row_count = 0
    private var col_count = 0
    private var word_len = I2C.DEFAULT_PAYLOAD_LENGTH
    private var word_count = 0 // = number of (32 byte) words per row
    
    private var BUFFER2 = [UInt8]() // 8 rows
    
    // MARK: init
    init(_ i2c:I2C,_ size:Size,_ rst:RPi5.Pin?=nil){
        self.i2c = i2c
        self.size = size
        contrast = 128
        _gpioResetPin = rst
        //if let p = _gpioResetPin{ p.direction = .OUT }
        row_count = Int(size.height/8)
        col_count = Int(size.width/8)
        word_count = Int(size.width/word_len)
        clearBuffer()
        switch size{                // ratio, height, compins, contrast
        case ._128x64: _init_params = (0x80,UInt8(size.height-1),0x12,ext ? 0x9F : 0xCF)
        case ._128x32: _init_params = (0x80,UInt8(size.height-1),0x02,0x8F)
        case ._96x16: _init_params = (0x60,UInt8(size.height-1),0x02,ext ? 0x10 : 0xAF)
        }
        begin()
    }
    
    // MARK: display text
    func display(strings:[String]){
        for row in 0..<strings.count{
            var s = strings[row]
            let n = word_count * 4
            while s.count < n{ s += " " }
            var i: UInt8 = 0
            let p = UInt8(row)
            for c in s{
                self.__write_char_to_buffer__(c,x:Int(i),y:Int(p))
                i += 1
            }
        }
        __write_buffer_to_chip__()
    }
    
    private func __write_char_to_buffer__(_ ch: Character,x:Int,y:Int){ // 0<x<16 , 0<y<8
        let x = inverted ? col_count - x - 1 : x
        let y = inverted ? row_count - y - 1 : y
        if let _u = _TheFont["\(ch)"]{
            var row = BUFFER[y]
            let w = Int(x/word_count)
            var word = row[w] // 32 byte array = 4 chars
            let start = 8 * (x - (w*4)) // start index in word
            var u = _u
            for i in 0..<8{
                let j = inverted ? 7 - i : i
                let b = UInt8(u & 0x00000000000000FF)
                word[start + j] = inverted ? b.reversed : b
                u = u >> 8
            }
            row[w] = word
            BUFFER[y] = row
        }
    }
    
    // MARK: display image
    func display(_ img:SSD1306_Image){
        /*
        if img.width == width || img.height == height{
            // Iterate through the memory pages
            var index = 0
            for page in 0..<_pages{
                // Iterate through all x axis columns.
                for x in 0..<width{
                    // Set the bits for the column of pixels at the current position.
                    var bits: UInt8 = 0
                    for bit in 0...7{
                        bits = bits << 1
                        bits |= img.pixel(x,page*8+7-UInt8(bit)) ? 0 : 1
                    }
                    // Update buffer byte and increment to next byte.
                    _buffer[index] = bits
                    index += 1
                }
            }
            
        }else{ __log__.err("HW.SSD1306.display() : invalid image size") }
         */
    }
    
    // MARK: display
    private func __write_buffer_to_chip__(){
        for r in 0..<row_count{
            command(SSD1306.PAGEADDR)
            command(UInt8(r))   // Page start address. (0 = reset)
            command(UInt8(r+1)) // Page end address.
            command(SSD1306.COLUMNADDR)
            command(0)                   // Column start address. (0 = reset)
            command(UInt8(size.width-1)) // Column end address.
            let row = BUFFER[r]
            for w in 0..<word_count{
                i2c.writeI2CData(0x40,row[w])
            }
        }
    }
    
    // MARK: reset
    private var _gpioResetPin:RPi5.Pin?
    func reset(){
        if let p = _gpioResetPin{
            p.high = true; usleep(1_000) // set high for 1 ms
            p.high = false; usleep(10_000) // set low for 10 ms
            p.high = true // set high again
        }
    }
    
    // MARK: clear
    func clearBuffer(){
        BUFFER.removeAll()
        for _ in 0..<row_count{
            var row = [WORD]()
            for _ in 0..<word_count{ row.append(WORD(repeating:0,count:word_len)) }
            BUFFER.append(row)
        }
        
        BUFFER2.removeAll()
        BUFFER2 = [UInt8](repeating:0,count:size.width*size.height)
    }
    
    // MARK: begin ..
    private func begin(){ begin(_vccstate) }
    private func begin(_ vccstate: UInt8){
        _vccstate = vccstate // save old vccstate
        reset()
        __initialize__()
        command(SSD1306.DISPLAYON) // Turn on the display
    }
    
    // MARK: contrast
    var contrast: UInt8{ didSet{ if contrast != oldValue{
        command(SSD1306.SETCONTRAST)
        command(contrast)
    }}}
    // Adjusts contrast to dim the display (if true),
    // otherwise sets the contrast to normal brightness.
    var dim = false{ didSet{ if dim != oldValue{
        contrast = 0 // always dim first
        if !dim{
            contrast = _vccstate == SSD1306.EXTERNALVCC ? 0x9F : 0xCF
        }
    }}}
    
    var inverted = false
    
    // MARK: _initialize ..
    private var _init_params: (UInt8,UInt8,UInt8,UInt8) = (0,0,0,0){ didSet{ begin() }}
    private func __initialize__(){
        command(SSD1306.DISPLAYOFF)
        command(SSD1306.SETDISPLAYCLOCKDIV)
        command(_init_params.0) // the suggested ratio
        command(SSD1306.SETMULTIPLEX)
        command(_init_params.1)
        command(SSD1306.SETDISPLAYOFFSET)
        command(0x0) // no offset
        command(SSD1306.SETSTARTLINE | 0x0) // line #0
        command(SSD1306.CHARGEPUMP)
        if ext{ command(0x10) }else{ command(0x14) }
        command(SSD1306.MEMORYMODE)
        command(0x00) // 0x0 act like ks0108
        command(SSD1306.SEGREMAP | 0x1)
        command(SSD1306.COMSCANDEC)
        command(SSD1306.SETCOMPINS)
        command(_init_params.2)
        command(SSD1306.SETCONTRAST)
        command(_init_params.3)
        command(SSD1306.SETPRECHARGE)
        command(ext ? 0x22 : 0xF1)
        command(SSD1306.SETVCOMDETECT)
        command(0x40)
        command(SSD1306.DISPLAYALLON_RESUME)
        command(SSD1306.NORMALDISPLAY)
        command(SSD1306.DEACTIVATE_SCROLL)
        command(SSD1306.DISPLAYON)
    }
    
    private func command(_ c:UInt8){ self.__write8__(0x00,c) } // send command
    
    // MARK: ■ send ..
    //func data(_ c: UInt8){ self.__write8__(0x40, c) } // send byte
    
    private func __write8__(_ c:UInt8,_ v:UInt8){
        i2c.writeByte(c,v)
    }
    
    // MARK: Registers
    //static let I2C_ADDRESS: UInt8 = 0x3C    // 011110+SA0+RW - 0x3C or 0x3D
    private static let SETCONTRAST: UInt8 = 0x81
    private static let DISPLAYALLON_RESUME: UInt8 = 0xA4
    private static let DISPLAYALLON: UInt8 = 0xA5
    private static let NORMALDISPLAY: UInt8 = 0xA6
    private static let INVERTDISPLAY: UInt8 = 0xA7
    private static let DISPLAYOFF: UInt8 = 0xAE
    private static let DISPLAYON: UInt8 = 0xAF
    private static let SETDISPLAYOFFSET: UInt8 = 0xD3
    private static let SETCOMPINS: UInt8 = 0xDA
    private static let SETVCOMDETECT: UInt8 = 0xDB
    private static let SETDISPLAYCLOCKDIV: UInt8 = 0xD5
    private static let SETPRECHARGE: UInt8 = 0xD9
    private static let SETMULTIPLEX: UInt8 = 0xA8
    private static let SETLOWCOLUMN: UInt8 = 0x00
    private static let SETHIGHCOLUMN: UInt8 = 0x10
    private static let SETSTARTLINE: UInt8 = 0x40
    private static let MEMORYMODE: UInt8 = 0x20
    private static let COLUMNADDR: UInt8 = 0x21
    private static let PAGEADDR: UInt8 = 0x22
    private static let COMSCANINC: UInt8 = 0xC0
    private static let COMSCANDEC: UInt8 = 0xC8
    private static let SEGREMAP: UInt8 = 0xA0
    private static let CHARGEPUMP: UInt8 = 0x8D
    private static let EXTERNALVCC: UInt8 = 0x1
    private static let SWITCHCAPVCC: UInt8 = 0x2
    // SCROLLING *******************
    private static let ACTIVATE_SCROLL: UInt8 = 0x2F
    private static let DEACTIVATE_SCROLL: UInt8 = 0x2E
    private static let SET_VERTICAL_SCROLL_AREA: UInt8 = 0xA3
    private static let RIGHT_HORIZONTAL_SCROLL: UInt8 = 0x26
    private static let LEFT_HORIZONTAL_SCROLL: UInt8 = 0x27
    private static let VERTICAL_AND_RIGHT_HORIZONTAL_SCROLL: UInt8 = 0x29
    private static let VERTICAL_AND_LEFT_HORIZONTAL_SCROLL: UInt8 = 0x2A
    
}

let EYE_PATTERN_1 = [
    "  D A S H E R   ",
    "  ◥◼︎◣      ◢◼︎◤  ",
    "   ◥◼︎◣    ◢◼︎◤   ",
    "    ◥◼︎◣  ◢◼︎◤    ",
    "     ◼︎◼︎◼︎◼︎◼︎◼︎     ",
    "    ◢◼︎◤  ◥◼︎◣    ",
    "   ◢◼︎◤    ◥◼︎◣   ",
    "  ◢◼︎◤      ◥◼︎◣  "
]

let EYE_PATTERN_2 = [
    "  D A S H E R   ",
    "    ◢◼︎◼︎◼︎◼︎◼︎◼︎◣    ",
    "   ◢◼︎◤    ◥◼︎◣   ",
    "   ◼︎◼︎      ◼︎◼︎   ",
    "   ◼︎◼︎      ◼︎◼︎   ",
    "   ◥◼︎◣    ◢◼︎◤   ",
    "    ◥◼︎◼︎◼︎◼︎◼︎◼︎◤    ",
    "                "
]

// MARK: ■ Font
class FontCalculator{
    static func calculate()->UInt64{
        let char = [
            "########",
            ".#######",
            "..######",
            "...#####",
            "....####",
            ".....###",
            "......##",
            ".......#",
        ]
        var u = UInt64(0)
        for row in char{
            var _u = UInt8(0)
            for c in row{
                if c == "#"{ _u = _u | 0x01 }
                _u = _u << 1
            }
            u = u | UInt64(_u)
            u = u << 8
        }
        return u
    }
}

let _TheFont : [String:UInt64] = [
    "a" : 33869718374064128,
    "b" : 13590274169667072,
    "c" : 75059992985600,
    "d" : 35545322353078272,
    "e" : 24862519119329280,
    "f" : 2244053303296,
    "g" : 16981219771418624,
    "h" : 31534027979128320,
    "i" : 276929445888,
    "j" : 250183942144,
    "k" : 74938866073600,
    "l" : 275955712000,
    "m" : 131960655870976,
    "n" : 131958650437632,
    "o" : 15837658689583104,
    "p" : 6795137084849152,
    "q" : 34942634755889152,
    "r" : 1130315200887808,
    "s" : 9099920423536640,
    "t" : 70661842403328,
    "u" : 16959143302675456,
    "v" : 7916759673740288,
    "w" : 16959005326851072,
    "x" : 19184348276457472,
    "y" : 16976804477668352,
    "z" : 19224223759466496,
    "A" : 34922765934033920,
    "B" : 14718381723385344,
    "C" : 10205951508495360,
    "D" : 6795266439151104,
    "E" : 18659031397334528,
    "F" : 573988187831808,
    "G" : 14727212041387008,
    "H" : 35474677653077504,
    "I" : 73110040608768,
    "J" : 631404220133376,
    "K" : 18051867938946560,
    "L" : 18085043209534976,
    "M" : 35470279606304256,
    "N" : 35501100291620352,
    "O" : 16961350949551104,
    "P" : 3397568542440960,
    "Q" : 16996604041116672,
    "R" : 21447151424011776,
    "S" : 14155431769949184,
    "T" : 2209727250944,
    "U" : 17522093256097280,
    "V" : 8479709627162112,
    "W" : 17521955280272896,
    "X" : 18617034365747712,
    "Y" : 2218216653312,
    "Z" : 18654633486598656,
    " " : 0,
    "0" : 16965783626333184,
    "1" : 18085309565108224,
    "2" : 21482611751937024,
    "3" : 14718381588620288,
    "4" : 9145893012905984,
    "5" : 14155431769943552,
    "6" : 13592481816525824,
    "7" : 1699923930251776,
    "8" : 14718381723366400,
    "9" : 16979012124544000,
    "@" : 7971847362722816,
    "!" : 403726925824,
    "?" : 1137247244255232,
    "\"" : 6597170429952,
    "#" : 10271792857752576,
    "$" : 39945315305472,
    "€" : 18659100384303104,
    "£" : 19213219754954752,
    "%" : 27694533511104000,
    "&" : 22553544532571136,
    "(" : 284474474496,
    ")" : 258805334016,
    "*" : 4596200532606976,
    "-" : 17661175005184,
    "+" : 4521724658843648,
    "." : 413927473152,
    "," : 207232172032,
    "/" : 567382630219776,
    "\\" : 18049651735527936,
    "<" : 292729913344,
    ">" : 17765125586944,
    "=" : 44152937512960,
    "[" : 285581770752,
    "]" : 542273175552,
    "^" : 2256206517764096,
    ":" : 154618822656,
    ";" : 224412041216,
    //
    "◼︎" : 18374403900871474688,
    "◢" : 18228584339875037184,
    "◣" : 9277662557957324288,
    "◤" : 436319467668962816,
    "◥" : 18338163031504454144
]

extension UInt8{
    
    var reversed:UInt8{ return REVERSED_BYTES[Int(self)] }
    
}

private let REVERSED_BYTES:[UInt8] = [
    0x00, 0x80, 0x40, 0xc0, 0x20, 0xa0, 0x60, 0xe0,
    0x10, 0x90, 0x50, 0xd0, 0x30, 0xb0, 0x70, 0xf0,
    0x08, 0x88, 0x48, 0xc8, 0x28, 0xa8, 0x68, 0xe8,
    0x18, 0x98, 0x58, 0xd8, 0x38, 0xb8, 0x78, 0xf8,
    0x04, 0x84, 0x44, 0xc4, 0x24, 0xa4, 0x64, 0xe4,
    0x14, 0x94, 0x54, 0xd4, 0x34, 0xb4, 0x74, 0xf4,
    0x0c, 0x8c, 0x4c, 0xcc, 0x2c, 0xac, 0x6c, 0xec,
    0x1c, 0x9c, 0x5c, 0xdc, 0x3c, 0xbc, 0x7c, 0xfc,
    0x02, 0x82, 0x42, 0xc2, 0x22, 0xa2, 0x62, 0xe2,
    0x12, 0x92, 0x52, 0xd2, 0x32, 0xb2, 0x72, 0xf2,
    0x0a, 0x8a, 0x4a, 0xca, 0x2a, 0xaa, 0x6a, 0xea,
    0x1a, 0x9a, 0x5a, 0xda, 0x3a, 0xba, 0x7a, 0xfa,
    0x06, 0x86, 0x46, 0xc6, 0x26, 0xa6, 0x66, 0xe6,
    0x16, 0x96, 0x56, 0xd6, 0x36, 0xb6, 0x76, 0xf6,
    0x0e, 0x8e, 0x4e, 0xce, 0x2e, 0xae, 0x6e, 0xee,
    0x1e, 0x9e, 0x5e, 0xde, 0x3e, 0xbe, 0x7e, 0xfe,
    0x01, 0x81, 0x41, 0xc1, 0x21, 0xa1, 0x61, 0xe1,
    0x11, 0x91, 0x51, 0xd1, 0x31, 0xb1, 0x71, 0xf1,
    0x09, 0x89, 0x49, 0xc9, 0x29, 0xa9, 0x69, 0xe9,
    0x19, 0x99, 0x59, 0xd9, 0x39, 0xb9, 0x79, 0xf9,
    0x05, 0x85, 0x45, 0xc5, 0x25, 0xa5, 0x65, 0xe5,
    0x15, 0x95, 0x55, 0xd5, 0x35, 0xb5, 0x75, 0xf5,
    0x0d, 0x8d, 0x4d, 0xcd, 0x2d, 0xad, 0x6d, 0xed,
    0x1d, 0x9d, 0x5d, 0xdd, 0x3d, 0xbd, 0x7d, 0xfd,
    0x03, 0x83, 0x43, 0xc3, 0x23, 0xa3, 0x63, 0xe3,
    0x13, 0x93, 0x53, 0xd3, 0x33, 0xb3, 0x73, 0xf3,
    0x0b, 0x8b, 0x4b, 0xcb, 0x2b, 0xab, 0x6b, 0xeb,
    0x1b, 0x9b, 0x5b, 0xdb, 0x3b, 0xbb, 0x7b, 0xfb,
    0x07, 0x87, 0x47, 0xc7, 0x27, 0xa7, 0x67, 0xe7,
    0x17, 0x97, 0x57, 0xd7, 0x37, 0xb7, 0x77, 0xf7,
    0x0f, 0x8f, 0x4f, 0xcf, 0x2f, 0xaf, 0x6f, 0xef,
    0x1f, 0x9f, 0x5f, 0xdf, 0x3f, 0xbf, 0x7f, 0xff
]
