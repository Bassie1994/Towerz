import UIKit

/// Generates app icons programmatically
/// Call generateAppIcon() to create icons for Assets.xcassets
final class AppIconGenerator {
    
    static func generateAppIcon(size: CGFloat = 1024) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // Background gradient
            let colors = [
                UIColor(red: 0.1, green: 0.15, blue: 0.2, alpha: 1.0).cgColor,
                UIColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 1.0).cgColor
            ]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size), options: [])
            
            // Grid pattern
            let gridColor = UIColor(red: 0.2, green: 0.25, blue: 0.3, alpha: 0.3)
            ctx.setStrokeColor(gridColor.cgColor)
            ctx.setLineWidth(size / 100)
            
            let gridSpacing = size / 10
            for i in 1..<10 {
                let pos = CGFloat(i) * gridSpacing
                ctx.move(to: CGPoint(x: pos, y: 0))
                ctx.addLine(to: CGPoint(x: pos, y: size))
                ctx.move(to: CGPoint(x: 0, y: pos))
                ctx.addLine(to: CGPoint(x: size, y: pos))
            }
            ctx.strokePath()
            
            // Central tower
            let towerSize = size * 0.35
            let towerX = size / 2 - towerSize / 2
            let towerY = size / 2 - towerSize / 2
            
            // Tower base
            let baseRect = CGRect(x: towerX, y: towerY, width: towerSize, height: towerSize)
            ctx.setFillColor(UIColor(red: 0.3, green: 0.3, blue: 0.8, alpha: 1.0).cgColor)
            ctx.fill(baseRect.insetBy(dx: towerSize * 0.1, dy: towerSize * 0.1))
            
            // Tower outline
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.setLineWidth(size / 80)
            ctx.stroke(baseRect.insetBy(dx: towerSize * 0.1, dy: towerSize * 0.1))
            
            // Turret circle
            let turretSize = towerSize * 0.5
            let turretRect = CGRect(
                x: size / 2 - turretSize / 2,
                y: size / 2 - turretSize / 2,
                width: turretSize,
                height: turretSize
            )
            ctx.setFillColor(UIColor(red: 0.4, green: 0.4, blue: 0.9, alpha: 1.0).cgColor)
            ctx.fillEllipse(in: turretRect)
            ctx.setStrokeColor(UIColor.white.cgColor)
            ctx.strokeEllipse(in: turretRect)
            
            // Barrel
            let barrelWidth = towerSize * 0.15
            let barrelLength = towerSize * 0.4
            ctx.setFillColor(UIColor.darkGray.cgColor)
            ctx.fill(CGRect(x: size / 2 + turretSize * 0.2, y: size / 2 - barrelWidth / 2, width: barrelLength, height: barrelWidth))
            
            // Range indicator (partial circle)
            let rangeRadius = size * 0.4
            ctx.setStrokeColor(UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).cgColor)
            ctx.setLineWidth(size / 120)
            ctx.addArc(center: CGPoint(x: size / 2, y: size / 2), radius: rangeRadius, startAngle: -0.3, endAngle: 0.3, clockwise: false)
            ctx.strokePath()
            
            // Enemy indicators (small dots approaching)
            let enemyPositions: [(x: CGFloat, y: CGFloat, color: UIColor)] = [
                (0.15, 0.4, UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)), // Infantry
                (0.1, 0.55, UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)),
                (0.2, 0.65, UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)), // Cavalry
                (0.12, 0.25, UIColor(red: 0.3, green: 0.8, blue: 0.9, alpha: 1.0)), // Flying
            ]
            
            for enemy in enemyPositions {
                let enemySize = size * 0.06
                let enemyRect = CGRect(
                    x: size * enemy.x - enemySize / 2,
                    y: size * enemy.y - enemySize / 2,
                    width: enemySize,
                    height: enemySize
                )
                ctx.setFillColor(enemy.color.cgColor)
                ctx.fillEllipse(in: enemyRect)
                ctx.setStrokeColor(UIColor.white.cgColor)
                ctx.setLineWidth(size / 200)
                ctx.strokeEllipse(in: enemyRect)
            }
            
            // Muzzle flash / attack indicator
            let flashSize = size * 0.08
            let flashX = size / 2 + towerSize * 0.35
            let flashY = size / 2
            ctx.setFillColor(UIColor.yellow.cgColor)
            ctx.fillEllipse(in: CGRect(x: flashX - flashSize / 2, y: flashY - flashSize / 2, width: flashSize, height: flashSize))
            
            // "TD" text at bottom
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: size * 0.12),
                .foregroundColor: UIColor.white
            ]
            let text = "TD"
            let textSize = text.size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: (size - textSize.width) / 2,
                y: size * 0.82,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: textAttributes)
        }
    }
    
    /// Saves generated icon to documents directory
    static func saveAppIcon() {
        let icon = generateAppIcon()
        
        if let data = icon.pngData(),
           let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let iconPath = documentsPath.appendingPathComponent("AppIcon.png")
            try? data.write(to: iconPath)
            print("App icon saved to: \(iconPath)")
        }
    }
}
