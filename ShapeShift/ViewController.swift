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
    var index: Int = 0
    let text: String
    let height: CGFloat
    var subViews: [VirtualView]
}

class ViewController: UIViewController, UIScrollViewDelegate {
    var screenHeight: CGFloat = 0
    let scrollView = UIScrollView()
    var virtualView = VirtualView(text: "nil", height: 0, subViews: [])
    var virtualViewScreenBuckets: [Int: [VirtualView]] = [0: []]
    var viewScreenBuckets = [Int: [UIScrollView]]()
    var screenIndex = 0
    let screenBuffer = 2
    
    override func viewDidLoad() {
        // Create virtual views
        var virtualSubViews = [VirtualView]()
        for _ in 0...50 {
            virtualSubViews.append(VirtualView(text: "hello", height: 200, subViews: []))
        }
        virtualView = VirtualView(text: "root", height: 600, subViews: virtualSubViews)
        
        // Init scroll view
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
        
        // Group virtual views by their screen position
        screenHeight = view.safeAreaLayoutGuide.layoutFrame.size.height
        var currentScreen = 1
        var currentHeight: CGFloat = 0
        for (i, _) in virtualView.subViews.enumerated() {
            virtualView.subViews[i].index = i // set index position
            let virtualSubView = virtualView.subViews[i]
            if currentHeight >= CGFloat(currentScreen) * screenHeight {
                currentScreen += 1
                virtualViewScreenBuckets[currentScreen - 1] = [VirtualView]()
            }
            virtualViewScreenBuckets[currentScreen - 1]?.append(virtualSubView)
            currentHeight += virtualSubView.height
        }
        
        // Initial render children
        for i in screenIndex ..< screenBuffer + 1 {
            renderScreen(screenIndex: i)
        }
    }
    
    func getView() -> UIScrollView { // recylce old view if possible, if not create new one
        let view = UIScrollView()
        return view
    }
    
    func renderScreen(screenIndex: Int) {
        if viewScreenBuckets[screenIndex] == nil && screenIndex >= 0 { // don't re-render screens that are already drawn
            viewScreenBuckets[screenIndex] = []
            if let screenVirtualViews = virtualViewScreenBuckets[screenIndex] {
                for virtualSubView in screenVirtualViews {
                    let subScrollView = getView()
                    viewScreenBuckets[screenIndex]?.append(subScrollView) // add view to screen bucket for recycling later
                    subScrollView.frame = CGRect(
                        x: 0,
                        y: CGFloat(virtualSubView.index) * virtualSubView.height,
                        width: view.frame.size.width,
                        height: virtualSubView.height - spacing
                    )
                    subScrollView.backgroundColor = .black
                    scrollView.addSubview(subScrollView)
                }
            }
        }
    }
    
    // Recycle screen
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let screenPosition = scrollView.contentOffset.y / screenHeight
        let newScreenIndex = Int(floor(screenPosition))
        print("newScreenIndex: \(newScreenIndex)")
        if newScreenIndex != screenIndex {
            screenIndex = newScreenIndex
            renderScreen(screenIndex: screenIndex - 2)
            renderScreen(screenIndex: screenIndex - 1)
            renderScreen(screenIndex: screenIndex + 1)
            renderScreen(screenIndex: screenIndex)
            renderScreen(screenIndex: screenIndex + 1)
            renderScreen(screenIndex: screenIndex + 2)
        }
    }
}
