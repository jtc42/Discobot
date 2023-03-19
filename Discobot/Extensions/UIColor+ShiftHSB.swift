//
//  UIColor+ShiftHSB.swift
//  Discobot
//
//  Created by Joel Collins on 19/03/2023.
//

import Foundation
import SwiftUI

extension UIColor {
    var lighterColor: UIColor {
        return lighterColor(removeSaturation: 0.5, resultAlpha: -1)
    }

    private func clamp(_ val: CGFloat) -> CGFloat {
        return min(max(val, 0.0), 1.0)
    }

    func lighterColor(removeSaturation val: CGFloat, resultAlpha alpha: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0
        var b: CGFloat = 0, a: CGFloat = 0

        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        else { return self }

        return UIColor(hue: h,
                       saturation: max(s - val, 0.0),
                       brightness: b,
                       alpha: alpha == -1 ? a : alpha)
    }

    func shiftHSB(hueBy: CGFloat, saturationBy: CGFloat, brightnessBy: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0
        var b: CGFloat = 0, a: CGFloat = 0

        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        else { return self }

        return UIColor(hue: clamp(h + hueBy),
                       saturation: clamp(s + saturationBy),
                       brightness: clamp(b + brightnessBy),
                       alpha: a)
    }
}
