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
        react.virtualViewTree = vTree
        react.isRoot = true
    }
}

func createTestVirtualViewData() -> VirtualView {
    var virtualSubViews = [VirtualView]()
    for i in 0...1 {
        virtualSubViews.append(VirtualView(
            text: "\(i)",
            layout: { parentView in return Layout(h: parentView.frame.height / 8, color: .cyan) },
            subViews: []
        ))
    }
    return VirtualView(text: "root", layoutSubViews: { (i, total, parentView) in
        return Layout(h: 600)
    }, subViews: virtualSubViews)
}

let defaultViewHeight: CGFloat = 50

struct VirtualView {
    var index: Int = 0
    let text: String
    var layout: (UIView) -> Layout // UIView = parentView
    var layoutSubViews: (Int, Int, UIView) -> Layout // Int = sibling position, Int = total siblings, UIView = parentView
    var subViews: [VirtualView]
    init(
         text: String = "",
         layout: @escaping (UIView) -> Layout = {_ in Layout()},
         layoutSubViews: @escaping (Int, Int, UIView) -> Layout = {_,_,_  in Layout()},
         subViews: [VirtualView] = []
    ) {
        self.text = text
        self.layout = layout
        self.layoutSubViews = layoutSubViews
        self.subViews = subViews
    }
}

struct Layout {
    let x: CGFloat?
    let y: CGFloat?
    let w: CGFloat?
    let h: CGFloat?
    let color: UIColor?
    init(x: CGFloat? = nil, y: CGFloat? = nil, w: CGFloat? = nil, h: CGFloat? = nil, color: UIColor? = nil) {
        self.x = x
        self.y = y
        self.w = w
        self.h = h
        self.color = color
    }
}

class React: UIViewController, UIScrollViewDelegate {
    var isRoot = false
    
    let scrollView = UIScrollView()

    var screenHeight: CGFloat = 0
    let screenBuffer = 1
    var currentScreenIndex = 0
    let spacing: CGFloat = 2
    
    var virtualViewTree = VirtualView(text: "nil", subViews: [])
    var virtualViewScreenBuckets: [Int: [VirtualView]] = [0: []]
    
    var recycledViews = [UIScrollView]()
    var viewScreenBuckets = [Int: [UIScrollView]]()
    
    override func viewDidLoad() {
        initScrollView()
    }
    
    func initScrollView() {
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.clipsToBounds = true
    }
    
    override func viewDidLayoutSubviews() {
        render(virtualViewTree)
    }
    
    func render(_ virtualViewTree: VirtualView) {
        self.virtualViewTree = virtualViewTree
        if isRoot {
            renderSuperView()
        }
        setScrollViewVirtualSize()
        createVirtualScreenBuckets()
        renderScreens()
    }
    
    func renderSuperView() {
        scrollView.frame = CGRect(x: 0, y: 0,
            width: view.safeAreaLayoutGuide.layoutFrame.width,
            height: view.safeAreaLayoutGuide.layoutFrame.height)
        scrollView.backgroundColor = .purple
    }
    
    func setScrollViewVirtualSize() {
        var totalHeight: CGFloat = 0
        for (i, subView) in virtualViewTree.subViews.enumerated() {
            totalHeight += virtualViewTree.layoutSubViews(i, virtualViewTree.subViews.count, view).h ?? subView.layout(view).h ?? defaultViewHeight
        }
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: totalHeight)
    }
    
    func createVirtualScreenBuckets() {
        virtualViewScreenBuckets = [0: []]
        screenHeight = view.safeAreaLayoutGuide.layoutFrame.size.height
        var currentScreen = 1
        var currentHeight: CGFloat = 0
        for (i, _) in virtualViewTree.subViews.enumerated() {
            virtualViewTree.subViews[i].index = i // set index position on virtual view
            let virtualSubView = virtualViewTree.subViews[i]
            if currentHeight >= CGFloat(currentScreen) * screenHeight {
                currentScreen += 1
                virtualViewScreenBuckets[currentScreen - 1] = [VirtualView]()
            }
            virtualViewScreenBuckets[currentScreen - 1]?.append(virtualSubView)
            currentHeight += virtualViewTree.layoutSubViews(i, virtualViewTree.subViews.count, view).h ?? virtualSubView.layout(view).h ?? defaultViewHeight
        }
    }
    
    func renderScreens() {
        viewScreenBuckets = [Int: [UIScrollView]]() // reset view buckets TODO try to recycle these comparing with the last virtual tree time step
        recycleNonVisibleScreens()
        renderCurrentScreenAndBuffer()
    }
    
    func recycleNonVisibleScreens() {
        for bucket in viewScreenBuckets {
            let i = bucket.key
            if i < currentScreenIndex - screenBuffer || i > currentScreenIndex + screenBuffer {
                recycleScreen(screenIndex: i)
            }
        }
    }
    
    func renderCurrentScreenAndBuffer() {
        for i in -screenBuffer ... screenBuffer {
            renderScreen(screenIndex: currentScreenIndex + i)
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
                for (i, virtualSubView) in screenVirtualViews.enumerated() {
                    let subScrollView = renderView(i, virtualSubView)
                    viewScreenBuckets[screenIndex]?.append(subScrollView) // add view to screen bucket for recycling later
                }
            }
        }
    }
    
    func renderView(_ i: Int, _ virtualSubView: VirtualView) -> UIScrollView {
        let subScrollView = getView()
        let height = (virtualViewTree.layoutSubViews(i, virtualViewTree.subViews.count, view).h ?? virtualSubView.layout(view).h ?? defaultViewHeight)
        subScrollView.frame = CGRect(
            x: 0,
            y: CGFloat(virtualSubView.index) * height,
            width: view.frame.size.width,
            height: height - spacing
        )
        subScrollView.contentSize = CGSize(width: subScrollView.frame.size.width, height: subScrollView.frame.size.height)
        subScrollView.backgroundColor = virtualSubView.layout(view).color ?? .black
        scrollView.addSubview(subScrollView)
        // add label
        let label = UILabel(frame:  CGRect(
            x: 2,
            y: 2,
            width: 200,
            height: 20
        ))
        label.text = "\(virtualSubView.text)"
        label.textColor = .black
        subScrollView.addSubview(label)
        return subScrollView
    }
    
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
        if newScreenIndex != currentScreenIndex {
            currentScreenIndex = newScreenIndex
            renderScreens()
        }
    }
}
