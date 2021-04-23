//
//  UIColorExtension.swift
//  AnyType
//
//  Created by Denis Batvinkin on 20.08.2019.
//  Copyright © 2019 AnyType. All rights reserved.
//

import UIKit


extension UIColor {
    
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }
    
    static func randomColor() -> UIColor {
        let random = { CGFloat(arc4random_uniform(256)) / 255.0 }
        return UIColor(red: random(), green: random(), blue: random(), alpha: 1)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb:Int = (Int)(r*0xff)<<16 | (Int)(g*0xff)<<8 | (Int)(b*0xff)<<0

        return String(format:"#%06x", rgb)
    }
    
    convenience init(hexString: String, alpha: CGFloat = 1) {
        let chars = Array(hexString.dropFirst())
        self.init(red:   .init(strtoul(String(chars[0...1]), nil ,16)) / 255,
                  green: .init(strtoul(String(chars[2...3]), nil ,16)) / 255,
                  blue:  .init(strtoul(String(chars[4...5]), nil ,16)) / 255,
                  alpha: alpha)
        
    }
    
    static var highlighterColor: UIColor {
        .init(red: 255.0/255.0, green: 181.0/255.0, blue: 34.0/255.0, alpha: 1)
    }
    
    static var textColor: UIColor {
        .init(red: 44.0/255.0, green: 43.0/255.0, blue: 39.0/255.0, alpha: 1)
    }
    
    static var secondaryTextColor: UIColor {
        .init(red: 172.0/255.0, green: 169.0/255.0, blue: 150.0/255.0, alpha: 1)
    }
    
    static var selectedItemColor: UIColor {
        .init(red: 229.0/255.0, green: 239.0/255.0, blue: 249.0/255.0, alpha: 1)
    }
    
    static var accentItemColor: UIColor {
        .orange
    }

    static var activeOrange: UIColor {
        .init(hexString: "#F6A927")
    }
    

    /// Color that can be used in case if we couldn't parse color from middleware
    static var defaultColor: UIColor {
        .black
    }

    /// Color that can be used in case if we couldn't parse color from middleware
    static var defaultBackgroundColor: UIColor {
        .white
    }
    
    static var lemonBackground: UIColor {
        UIColor(hexString: "#FEF9CC")
    }
    
    static var amberBackground: UIColor {
        UIColor(hexString: "#FEF3C5")
    }
    
    static var redBackground: UIColor {
        UIColor(hexString: "#FFEBE5")
    }
    
    static var pinkBackground: UIColor {
        UIColor(hexString: "#FEE3F5")
    }
    
    static var purpleBackground: UIColor {
        UIColor(hexString: "#F4E3FA")
    }
    
    static var ultramarineBackground: UIColor {
        UIColor(hexString: "#E4E7FC")
    }
    
    static var blueBackground: UIColor {
        UIColor(hexString: "#D6EFFD")
    }
    
    static var tealBackground: UIColor {
        UIColor(hexString: "#D6F5F3")
    }
    
    static var greenBackground: UIColor {
        UIColor(hexString: "#E3F7D0")
    }
    
    static var coldgrayBackground: UIColor {
        UIColor(hexString: "#EBEFF1")
    }
    
    static var black: UIColor {
        UIColor(hexString: "#2C2B27")
    }
    
    static var lemon: UIColor {
        UIColor(hexString: "#ECD91B")
    }
    
    static var amber: UIColor {
        UIColor(hexString: "#FFB522")
    }
    
    static var red: UIColor {
        UIColor(hexString: "#F55522")
    }
    
    static var pink: UIColor {
        UIColor(hexString: "#E51CA0")
    }
    
    static var purple: UIColor {
        UIColor(hexString: "#AB50CC")
    }
    
    static var ultramarine: UIColor {
        UIColor(hexString: "#3E58EB")
    }
    
    static var blue: UIColor {
        UIColor(hexString: "#2AA7EE")
    }
    
    static var teal: UIColor {
        UIColor(hexString: "#0FC8BA")
    }
    
    static var green: UIColor {
        UIColor(hexString: "#5DD400")
    }
    
    static var coldgray: UIColor {
        UIColor(hexString: "#8C9EA5")
    }

    static var stroke: UIColor {
        .init(hexString: "#DFDDD0")
    }

    /// Buttons color
    ///
    /// Design [link](https://www.figma.com/file/TupCOWb8sC9NcjtSToWIkS/Android-main-draft?node-id=3681%3A1066)
    enum Button {
        static var secondaryPressed: UIColor {
            .init(hexString: "#F3F2EC")
        }
    }
}
