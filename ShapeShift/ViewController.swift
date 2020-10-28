//
//  ViewController.swift
//  ShapeShift
//
//  Created by Buddyng on 24/10/2020.
//  Copyright © 2020 Luke Ellis Bower. All rights reserved.
//

import UIKit

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

func createTestVirtualViewData() -> VirtualView {
    var virtualSubViews = [VirtualView]()
    for _ in 0...300{
        virtualSubViews.append(VirtualView(
            text: "level 1",//"\(i)",
            layout: { parentView in return Layout(h: 100, color: .cyan) },
            subViews: [
                VirtualView(
                    text: "level 2",
                    layout: { parentView in return Layout(h: 50, color: .orange) },
                    subViews: [
                        VirtualView(
                            layout: { _ in return Layout(h: 25, color: .darkGray) }
                        )
                    ]
                )
            ]
        ))
    }
    return VirtualView(
        text: "root",
        //layoutSubViews: { (i, total, parentView) in return Layout(h: 600) },
        subViews: virtualSubViews
    )
}


class ViewController: UIViewController {
    let vTree = createTestVirtualViewData()
    let react = React(virtualView: createTestVirtualViewData(), isRoot: true)
    
    override func viewDidLoad() {
        addViewController(react)
        react.view.fill(view)
    }
    
    override func viewDidLayoutSubviews() {
        react.render(vTree)
    }
}

class React: UIViewController, UIScrollViewDelegate {
    var isRoot: Bool
    
    let scrollView = UIScrollView()

    var screenHeight: CGFloat = 1
    let screenBuffer = 1
    var currentScreenIndex = 0
    let spacing: CGFloat = 2
    
    var virtualViewTree: VirtualView
    var virtualViewScreenBuckets: [Int: [VirtualView]] = [0: []]
    
    var recycledViews = [React]()
    var viewScreenBuckets = [Int: [React]]()
    
    init(virtualView: VirtualView, isRoot: Bool = false) {
        self.virtualViewTree = virtualView
        self.isRoot = isRoot
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    override func viewDidLoad() {
        initScrollView()
    }
    
    func initScrollView() {
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.clipsToBounds = true
    }
    
    func render(_ virtualViewTree: VirtualView) {
        self.virtualViewTree = virtualViewTree
        renderSelf()
        virtualCalculations()
        renderScreens()
    }
    
    func renderSelf() {
        scrollView.frame = CGRect(x: 0, y: 0,
            width: view.safeAreaLayoutGuide.layoutFrame.width,
            height: view.safeAreaLayoutGuide.layoutFrame.height)
        view.backgroundColor = virtualViewTree.layout(view).color ?? .white
    }
    
    func virtualCalculations() {
        setScrollViewVirtualSize()
        createVirtualScreenBuckets()
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
        screenHeight = view.frame.height
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
        
    func getView(_ virtualView: VirtualView) -> React { // recylce old view if possible, if not create new one
        if let view = recycledViews.popLast() { // get from queue
            view.virtualViewTree = virtualView
            return view
        }
        let view = React(virtualView: virtualView)
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
    
    func renderView(_ i: Int, _ virtualSubView: VirtualView) -> React {
        // recycle
        let subScrollView = getView(virtualSubView)
        // size
        let height = (virtualViewTree.layoutSubViews(i, virtualViewTree.subViews.count, view).h ?? virtualSubView.layout(view).h ?? defaultViewHeight)
        subScrollView.view.frame = CGRect(
            x: 0,
            y: CGFloat(virtualSubView.index) * height,
            width: view.frame.size.width,
            height: height - spacing
        )
        // add to view
        scrollView.addSubview(subScrollView.view)
        addChild(subScrollView)
        subScrollView.didMove(toParent: self)
        // render
        subScrollView.render(virtualSubView)
        return subScrollView
    }
    
    func recycleScreen(screenIndex: Int) {
        if let screenViews = viewScreenBuckets[screenIndex] {
            for screenView in screenViews {
                recycledViews.append(screenView)
//                screenView.view.subviews.forEach({ // remove child views
//                    $0.removeFromSuperview()
//                })
//                screenView.removeFromParent()
                // TODO think more about recycling, maybe calling a clean up method on React to do this recursively
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
