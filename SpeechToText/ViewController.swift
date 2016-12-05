//
//  ViewController.swift
//  SpeechToText
//
//  Created by 何晓文 on 2016/12/5.
//  Copyright © 2016年 何晓文. All rights reserved.
//

import UIKit
import Speech
class ViewController: UIViewController {
 
    
    @IBOutlet weak var textView: UITextView!

    @IBOutlet weak var speakerBtn: UIButton!
    
    //用于apple语言识别的变量
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh-CN"))
    // 可以将识别请求的结果返回给你，它带来了极大的便利，必要时，可以取消或停止任务。
    private var recognitionTask: SFSpeechRecognitionTask?
    //对象用于处理语音识别请求，为语音识别提供音频输入
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    // 音频引擎 用于进行音频输入
    private let audioEngine = AVAudioEngine()
    
    @IBAction func speakAction(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            speakerBtn.isEnabled = false
            speakerBtn.setTitle("开始说话", for: .normal)
//            textView.text = "说点啥"
        } else {
            startRecording()
            speakerBtn.setTitle("说完了", for: .normal)
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
        authRequest()
        
        
    }
    
    // MARK: - *** 获取用户权限 ***
    func authRequest(){
        
        speakerBtn.isEnabled = false
        
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isBtnEndable = false
            
            switch authStatus{
            case.authorized:
                isBtnEndable = true
            case .denied:
                isBtnEndable = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isBtnEndable = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isBtnEndable = false
                
                
                
            }
            
            OperationQueue.main.addOperation {
                self.speakerBtn.isEnabled = isBtnEndable
            }
            
        }
    
    }
    
    // MARK: - *** 开始授权 ***
    func startRecording(){
    
        if recognitionTask != nil{
            recognitionTask?.cancel()
            recognitionTask = nil
 
        }
    let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)

        
        }catch{
        
        fatalError("会话创建失败")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("音频引擎 没有输入节点")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("创建音频缓存失败")
        }
        //结果报告
        recognitionRequest.shouldReportPartialResults = true
        
        //开启授权任务
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.speakerBtn.isEnabled = true
            }
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
            
        }
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
//        textView.text = "说点啥......"
        
    
    }



}
// MARK: - *** delegate ***
extension ViewController: SFSpeechRecognizerDelegate{

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            speakerBtn.isEnabled = true
        } else {
            speakerBtn.isEnabled = false
        }
    }

}

