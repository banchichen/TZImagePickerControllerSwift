//
//  TZVideoPlayerController.swift
//  TZImagePickerControllerSwift
//
//  Created by 希达 on 2018/1/22.
//  Copyright © 2018年 Tan.huang. All rights reserved.
//

import UIKit
import AVFoundation

class TZVideoPlayerController: UIViewController {

    var model: TZAssetModel?


    private var _player: AVPlayer?
    private var _playerLayer: AVPlayerLayer?
    private var _playButton: UIButton?
    private var _cover: UIImage?

    private var _toolBar: UIView?
    private var _doneButton: UIButton?
    private var _progress: UIProgressView?

    private var _originStatusBarStyle: UIStatusBarStyle?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        if (tzImagePickerVc != nil) {
            self.navigationItem.title = tzImagePickerVc?.previewBtnTitleStr
        }
        self.configMoviePlayer()
        NotificationCenter.default.addObserver(self, selector: #selector(pausePlayerAndShowNaviBar), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _originStatusBarStyle = UIApplication.shared.statusBarStyle
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = _originStatusBarStyle!
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        _playerLayer?.frame = self.view.bounds;
        _playButton?.frame = CGRect(x: 0, y: 64, width: view.frame.width, height: view.frame.height - 64 - 44);
        _doneButton?.frame = CGRect(x: view.frame.width - 44 - 12, y: 0, width: 44, height: 44);
        _toolBar?.frame = CGRect(x: 0, y: view.frame.height - 44, width: view.frame.width, height: 44);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func configMoviePlayer() {
        _ = TZImageManager.manager.getPhoto(photoWithAsset: model?.asset, completion: { (photo, info, isDegraded) -> (Void) in
            self._cover = photo
        }, progressHandler: {
            (progress, error, stop, info) -> Void in

        })

        TZImageManager.manager.getVideo(model?.asset, progressHandler: {
            (progress, error, stop, info) -> (Void) in

        }) { (playerItem, info) -> (Void) in
            DispatchQueue.main.async {
                self._player = AVPlayer(playerItem: playerItem)
                self._playerLayer = AVPlayerLayer(player: self._player!)
                self._playerLayer?.frame = self.view.bounds
                self.view.layer.addSublayer(self._playerLayer!)
                self.addProgressObserver()
                self.configPlayButton()
                self.configBottomToolBar()
                NotificationCenter.default.addObserver(self, selector: #selector(self.pausePlayerAndShowNaviBar), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            }
        }
    }
    /// Show progress，do it next time / 给播放器添加进度更新,下次加上
    func addProgressObserver() {
        let playerItem = _player?.currentItem;
        let progress = _progress;
        _player?.addPeriodicTimeObserver(forInterval: CMTimeMake(Int64(1.0), Int32(1.0)), queue: DispatchQueue.main, using: { (time) in
            let current = CMTimeGetSeconds(time)
            let total = CMTimeGetSeconds((playerItem?.duration)!)
            if current > 0 {
                progress?.setProgress(Float(current / total), animated: true)
            }
        })
    }

    func configPlayButton() {
        _playButton = UIButton(type: .custom)
        _playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlay"), for: .normal)
        _playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlayHL"), for: .highlighted)
        _playButton?.addTarget(self, action: #selector(playButtonClick), for: .touchUpInside)
        view.addSubview(_playButton!)
    }

    func configBottomToolBar() {
        _toolBar = UIView(frame: CGRect.zero)
        _toolBar?.backgroundColor = UIColor(red: 34 / 255.0, green: 34 / 255.0, blue: 34 / 255.0, alpha: 0.7)

        _doneButton = UIButton(type: .custom)
        _doneButton?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        _doneButton?.addTarget(self, action: #selector(doneButtonClick), for: .touchUpInside)

        let tzImagePickerVc = self.navigationController as? TZImagePickerController
        if (tzImagePickerVc != nil) {
            _doneButton?.setTitle(tzImagePickerVc?.doneBtnTitleStr, for: .normal)
            _doneButton?.setTitleColor(tzImagePickerVc?.oKButtonTitleColorNormal, for: UIControlState.normal)
        } else {
            _doneButton?.setTitle(Bundle.tz_localizedString(forKey: "Done"), for: .normal)
            _doneButton?.setTitleColor(UIColor(red: 83 / 255.0, green: 179 / 255.0, blue: 17 / 255.0, alpha: 1), for: .normal)
        }
        _toolBar?.addSubview(_doneButton!)
        view.addSubview(_toolBar!)
    }

    @objc func playButtonClick() {
        let currentTime = _player?.currentItem?.currentTime()
        let durationTime = _player?.currentItem?.duration
        if (_player?.rate == 0.0) {
            if (currentTime?.value == durationTime?.value) {
                _player?.currentItem?.seek(to: CMTimeMake(0, 1))
            }
            _player?.play()
            self.navigationController?.isNavigationBarHidden = true
            _toolBar?.isHidden = true
            _playButton?.setImage(nil, for: .normal)
            if !Bundle.TZ_isGlobalHideStatusBar() {
                UIApplication.shared.isStatusBarHidden = true
            }
        } else {
            self.pausePlayerAndShowNaviBar()
        }
    }

    @objc func doneButtonClick() {
        let imagePickerVc = self.navigationController as? TZImagePickerController
        if imagePickerVc != nil {
            if (imagePickerVc?.autoDismiss)! {
                self.navigationController?.dismiss(animated: true, completion: {
                    self.callDelegateMethod()
                })
            } else {
                self.callDelegateMethod()
            }
        } else {
            self.dismiss(animated: true, completion: {
                self.callDelegateMethod()
            })
        }
    }

    func callDelegateMethod() {
        guard let imagePickerVc = self.navigationController as? TZImagePickerController  else {
            return
        }

        if (imagePickerVc.pickerDelegate?.responds(to: #selector(imagePickerVc.pickerDelegate?.imagePickerController(_:didFinishPickingVideo:sourceAssets:))))! {
            imagePickerVc.pickerDelegate?.imagePickerController!(imagePickerVc, didFinishPickingVideo: _cover!, sourceAssets: (model?.asset)!)
        }

        imagePickerVc.didFinishPickingVideoHandle?(_cover!, (model?.asset)!)

    }

    //MARK: - Notification Method
    @objc func pausePlayerAndShowNaviBar() {
        _player?.pause()
        _toolBar?.isHidden = false
        navigationController?.isNavigationBarHidden = false
        _playButton?.setImage(UIImage.imageNamedFromMyBundle(name: "MMVideoPreviewPlay"), for: .normal)
        if !Bundle.TZ_isGlobalHideStatusBar() {
            UIApplication.shared.isStatusBarHidden = false
        }
    }

    deinit {
        debugPrint("释放了...\(self.classForCoder)")
        NotificationCenter.default.removeObserver(self)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    

}
