//
//  ViewController.swift
//  ShapeShift
//
//  Created by Buddyng on 24/10/2020.
//  Copyright © 2020 Luke Ellis Bower. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        let react = React()
        addViewController(react)
        react.view.fill(view)
        let vTree = createTestVirtualViewData()
        react.render(vTree)
    }
}

func createTestVirtualViewData() -> VirtualView {
    var virtualSubViews = [VirtualView]()
    for i in 0...200 {
        virtualSubViews.append(VirtualView(text: "\(i)", height: 30, subViews: []))
    }
    return VirtualView(text: "root", height: 400, subViews: virtualSubViews)
}

struct VirtualView {
    var index: Int = 0
    let text: String
    let height: CGFloat
    var subViews: [VirtualView]
}

class React: UIViewController, UIScrollViewDelegate {
    
    let scrollView = UIScrollView()

    var screenHeight: CGFloat = 0
    let screenBuffer = 1
    var screenIndex = 0
    let spacing: CGFloat = 2
    
    var virtualViewTree = VirtualView(text: "nil", height: 0, subViews: [])
    var virtualViewScreenBuckets: [Int: [VirtualView]] = [0: []]
    
    var recycledViews = [UIScrollView]()
    var viewScreenBuckets = [Int: [UIScrollView]]()
    
    override func viewDidLoad() {
        initScrollView()
    }
    
    func initScrollView() {
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.fill(view)
        scrollView.backgroundColor = .purple
    }
    
    func render(_ virtualViewTree: VirtualView) {
        self.virtualViewTree = virtualViewTree
        setScrollViewSize()
        createVirtualScreenBuckets()
        renderScreens()
    }
    
    func setScrollViewSize() {
        var totalHeight: CGFloat = 0
        for subView in virtualViewTree.subViews {
            totalHeight += subView.height
        }
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: totalHeight)
    }
    
    func createVirtualScreenBuckets() {
        screenHeight = view.safeAreaLayoutGuide.layoutFrame.size.height
        var currentScreen = 1
        var currentHeight: CGFloat = 0
        for (i, _) in virtualViewTree.subViews.enumerated() {
            virtualViewTree.subViews[i].index = i // set index position
            let virtualSubView = virtualViewTree.subViews[i]
            if currentHeight >= CGFloat(currentScreen) * screenHeight {
                currentScreen += 1
                virtualViewScreenBuckets[currentScreen - 1] = [VirtualView]()
            }
            virtualViewScreenBuckets[currentScreen - 1]?.append(virtualSubView)
            currentHeight += virtualSubView.height
        }
    }
    
    func renderScreens() {
        recycleNonVisibleScreens()
        renderCurrentScreenAndBuffer()
    }
    
    func recycleNonVisibleScreens() {
        for bucket in viewScreenBuckets {
            let i = bucket.key
            if i < screenIndex - screenBuffer || i > screenIndex + screenBuffer {
                recycleScreen(screenIndex: i)
            }
        }
    }
    
    func renderCurrentScreenAndBuffer() {
        for i in -screenBuffer ... screenBuffer {
            renderScreen(screenIndex: screenIndex + i)
        }
    }
    
    func getView() -> UIScrollView { // recylce old view if possible, if not create new one
        if let view = recycledViews.popLast() { // get from queue
            return view
        }
        let view = UIScrollView()
        return view
    }
    
    func renderScreen(screenIndex: Int) {
        if viewScreenBuckets[screenIndex] == nil && screenIndex >= 0 { // don't re-render screens that are already drawn
            viewScreenBuckets[screenIndex] = []
            if let screenVirtualViews = virtualViewScreenBuckets[screenIndex] {
                for (_, virtualSubView) in screenVirtualViews.enumerated() {
                    let subScrollView = getView()
                    viewScreenBuckets[screenIndex]?.append(subScrollView) // add view to screen bucket for recycling later
                    subScrollView.frame = CGRect(
                        x: 0,
                        y: CGFloat(virtualSubView.index) * virtualSubView.height,
                        width: view.frame.size.width,
                        height: virtualSubView.height - spacing
                    )
                    subScrollView.contentSize = CGSize(width: subScrollView.frame.size.width, height: subScrollView.frame.size.height)
                    subScrollView.backgroundColor = .black
                    scrollView.addSubview(subScrollView)
                    // add label
                    let label = UILabel(frame:  CGRect(
                        x: 2,
                        y: 2,
                        width: 200,
                        height: 20
                    ))
                    label.text = "\(virtualSubView.text)"
                    label.textColor = .green
                    subScrollView.addSubview(label)
                }
            }
        }
    }
    
//    func renderView(_ virtualSubView: VirtualView) {
//
//    }
    
    func recycleScreen(screenIndex: Int) {
        if let screenViews = viewScreenBuckets[screenIndex] {
            for screenView in screenViews {
                recycledViews.append(screenView)
                screenView.subviews.forEach({ $0.removeFromSuperview() }) // remove child views
                // TODO add all subviews to recylced views queue?
            }
        }
        viewScreenBuckets[screenIndex] = nil // reset so it gets rendered next time
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateScreenIndex()
    }
    
    func updateScreenIndex() {
        let screenPosition = scrollView.contentOffset.y / screenHeight
        let newScreenIndex = Int(floor(screenPosition))
        if newScreenIndex != screenIndex {
            screenIndex = newScreenIndex
            renderScreens()
        }
    }
}
