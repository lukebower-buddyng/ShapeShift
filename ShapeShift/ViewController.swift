//
//  ViewController.swift
//  ShapeShift
//
//  Created by Buddyng on 24/10/2020.
//  Copyright © 2020 Luke Ellis Bower. All rights reserved.
//

import UIKit

let spacing: CGFloat = 10

struct VirtualView {
    let text: String
    let height: CGFloat
    let subViews: [VirtualView]
}

class ViewController: UIViewController, UIScrollViewDelegate {
    let scrollView = UIScrollView()
    var virtualView = VirtualView(text: "nil", height: 0, subViews: [])
    var subViews = [UIScrollView]()
    
    override func viewDidLoad() {
        // create virtual views
        var virtualSubViews = [VirtualView]()
        for _ in 1...100 {
            virtualSubViews.append(VirtualView(text: "hello", height: 200, subViews: []))
        }
        virtualView = VirtualView(text: "root", height: 600, subViews: virtualSubViews)
        
        // init scroll view
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.backgroundColor = .purple
        scrollView.fill(view)
        var totalHeight: CGFloat = 0
        for subView in virtualView.subViews {
            totalHeight += subView.height + spacing
        }
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: totalHeight)
        scrollView.delegate = self
        
        // group virtual views by their screen position
        let screenHeight = view.frame.size.height
        var screenBuckets: [[VirtualView]] = [[]]
        var currentScreen = 1
        var currentHeight: CGFloat = 0
        for virtualSubView in virtualView.subViews {
            if currentHeight >= CGFloat(currentScreen) * screenHeight {
                currentScreen += 1
                screenBuckets.append([VirtualView]())
            }
            screenBuckets[currentScreen - 1].append(virtualSubView)
            currentHeight += virtualSubView.height
        }
        
        // render children
        let screenBuffer = 2
        var i = 0
        for screenBucketIndex in 0 ..< screenBuffer {
            for virtualSubView in screenBuckets[screenBucketIndex] {
                let subScrollView = UIScrollView()
                subScrollView.frame = CGRect(
                    x: 0,
                    y: CGFloat(i) * virtualSubView.height,
                    width: view.frame.size.width,
                    height: virtualSubView.height - spacing
                )
                subScrollView.backgroundColor = .black
                subViews.append(subScrollView)
                scrollView.addSubview(subScrollView)
                i += 1
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(scrollView.contentOffset)
    }
}
