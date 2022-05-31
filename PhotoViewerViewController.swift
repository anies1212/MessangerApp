//
//  PhotoViewerViewController.swift
//  chatWithFBAppSample
//
//  Created by anies1212 on 2022/03/25.
//

import UIKit
import SDWebImage

class PhotoViewerViewController: UIViewController {
    private let url: URL
    private let imageView:UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    init(with url: URL){
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Photo"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .black
        view.addSubview(imageView)
        self.imageView.sd_setImage(with: url, completed: nil)
    }
    
    override func viewDidLayoutSubviews() {
        imageView.frame = self.view.bounds
        
    }
    

    

}
