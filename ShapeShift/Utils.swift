//
//  Utils.swift
//  ShapeShift
//
//  Created by Buddyng on 24/10/2020.
//  Copyright © 2020 Luke Ellis Bower. All rights reserved.
//

import UIKit

extension UIViewController {
    func addViewController(_ child: UIViewController) {
        addChild(child)
        child.didMove(toParent: self)
        view.addSubview(child.view)
    }
}

extension UIView {
    func fill(_ parentView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor).isActive = true
        leftAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.rightAnchor).isActive = true
        bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }
    func fill(_ parentView: UIView, top: Int, bottom: Int, left: Int, right: Int) {
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: CGFloat(top)).isActive = true
        leftAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leftAnchor, constant: CGFloat(left)).isActive = true
        rightAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.rightAnchor, constant: CGFloat(right)).isActive = true
        bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: CGFloat(bottom)).isActive = true
    }
}
