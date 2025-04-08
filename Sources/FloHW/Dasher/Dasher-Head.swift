// 𝗙𝗟𝗢 : 𝗗𝗶𝘀𝘁𝗿𝗶𝗯𝘂𝘁𝗲𝗱 𝗛𝗶𝗲𝗿𝗮𝗿𝗰𝗵𝗶𝗰𝗮𝗹 𝗗𝗮𝘁𝗮𝗳𝗹𝗼𝘄 © 𝖪𝖾𝗏𝖾𝗇 𝖪𝖾𝖺𝗋𝗇𝖾𝗒 𝟮𝟬𝟮𝟯
import Foundation
import FloBox

/*
 scp Dasher-Head.swift dasher@10.99.1.223:Swift/FloHW/Sources/FloHW/Dasher (home)
 scp Dasher-Head.swift dasher@10.255.254.3:Swift/FloHW/Sources/FloHW/Dasher
 */

// MARK: Head
private let INPUT_ON = "on"
private let OUTPUT_VIDEO = "video"
public class DasherHead: Device.Box, UDP.RawRecipient{
    
    public let skin = Skin(
        "Head",
        [INPUT_ON:.BOOL()],
        [OUTPUT_VIDEO:.DATA]
    )
    private let vip$: String // dst IP of VIDEO streaming
    private let udp:UDP.EP
    
    public init?(_ vip:String){
        vip$ = vip
        if let addr = IPv4.from(vip){
            do{
                udp = try UDP.EP(ipa:addr)
            }catch let e{
                print(e.localizedDescription)
                return nil
            }
        }else{ return nil }
    }
    deinit{
        __stop_streaming__()
    }
    
    var video_on = false{ didSet{
        if video_on{ __start_streaming__() }
        else{ __stop_streaming__() }
    }}
    
    public func publish(_ inputs:[Ports.ID:Event]){
        for (n,e) in inputs{
            switch n{
            case INPUT_ON:
                video_on = (e.value as? Bool) ?? false
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
        /* rpicam-vid -t 0 --inline -o udp://<ip-addr>:<port> */
        task!.executableURL = URL(fileURLWithPath:"/bin/rpicam-vid")
        task!.arguments = [
            "-t","0", // do it now, for ever
            "--inline", // forces SPS/PPS header on every iframe !!
            "--framerate", "10",
            "--nopreview",
            "--codec", "h264",
            "--width","320",
            "--height","240",
            "--intra","10",
            "-o",
            "udp://"+vip$
        ]
        /* libcamera-vid -t0 --width 640 --height 480 --framerate 10 --nopreview --codec h264 --profile high --intra 5 --listen -o udp://10.99.1.223:9993 */
        /*task!.executableURL = URL(fileURLWithPath:"/bin/libcamera-vid")
        task!.arguments = [
            "-t0", // do it now
            "--width","640",
            "--height","480",
            "--framerate","10",
            "--nopreview",
            "--inline",
            "--codec","h264",
            "--profile","high",
            "--intra","5",
            "--listen",
            "-o",
            "udp://"+vip$
        ]*/
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
        //enqueueRaw(&bytes) // just to see what's in them ..
        self.callback?([OUTPUT_VIDEO:Event( Data(bytes) )])
    }
    
    private func __stop_streaming__(){
        udp.rawRecipient = nil
        task?.terminate()
        task = nil
    }
    
}
/*
private var pkt = [UInt8]()
private var _zero_count = 0

func enqueueRaw(_ bytes: inout [UInt8]){
    if !bytes.isEmpty{
        //__log__.info("- RAW - received \(bytes.count)")
        //__log__.info("   \(bytes)")
        var i = 0
        let n = bytes.count
        while i < n{
            let b = bytes[i]
            switch b{
            case 0:
                if _zero_count < 3{ _zero_count += 1 }
                else{ pkt.append(b) }
            case 1:
                if _zero_count >= 2{
                    if let nalu = H264NALU(Data(pkt)){ enqueueH264(nalu) }
                    pkt = [UInt8]() // reset
                    _zero_count = 0
                }else{ fallthrough }
            default:
                while _zero_count > 0{ pkt.append(0); _zero_count -= 1 }
                pkt.append(b)
            }
            i += 1
        }
    }

    func enqueueH264(_ nalu:H264NALU){
        let n = nalu.count
        switch nalu.kind {
        case .SPS:
            __log__.info("-> SPS = \(n) bytes")
        case .PPS:
            __log__.info("-> PPS = \(n) bytes")
        case .IFrame:
            __log__.info("-> IFrame = \(n) bytes")
        case .BFrame:
            __log__.info("-> BFrame = \(n) bytes")
        case .PFrame:
            __log__.info("-> PFrame = \(n) bytes")
        }
    }
}

public struct H264NALU {
    
    enum Kind{ case SPS, PPS, IFrame, PFrame, BFrame }
    static let startCode = Data([0x00, 0x00, 0x00, 0x01])

    let data: Data
    let kind: Kind
    let count: Int
    
    init?(_ data:Data){
        count = data.count
        if count > 0{
            self.data = data // MUST NOT INCLUDE START CODE !!!
            switch (data[0] & 0x1f){
            case 1: self.kind = .PFrame
            case 5: self.kind = .IFrame
            case 7: self.kind = .SPS
            case 8: self.kind = .PPS
            default: self.kind = .BFrame
            }
            /*if data.count > 1{
                print("\(kind) -> 2nd byte = \(data[1])")
            }else{
                print("data count == 1")
            }*/
        }/*
        if let first = data.first{
            self.data = data // MUST NOT INCLUDE START CODE !!!
            switch (first & 0x1f){
            case 1: self.kind = .PFrame
            case 5: self.kind = .IFrame
            case 7: self.kind = .SPS
            case 8: self.kind = .PPS
            default: self.kind = .BFrame
            }
        }*/else{ return nil }
    }
    
}
*/
