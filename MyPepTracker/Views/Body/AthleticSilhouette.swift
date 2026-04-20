import SwiftUI

/// A reusable athletic front-facing silhouette. Built from overlapping
/// rounded shapes (head, neck, delts, torso, waist, hips, arms, thighs,
/// calves) to give a V-tapered muscular form.
///
/// The reference drawing coordinate space is 320x560. All call sites pass
/// their desired render size via `.frame(...)`; coords are scaled to the
/// actual canvas size at render time so the same figure can be rendered
/// at different sizes (e.g. 320x560 on the Body tab vs. 200x340 on the
/// History injection-site map).
///
/// Absolute-pixel marker positions on the Body tab and injection-site map
/// are expressed in this same 320x560 reference space and scaled at draw
/// time via `AthleticSilhouette.scaled(_:in:)`.
struct AthleticSilhouette: View {
    var fillColor: Color = Color.gray.opacity(0.22)

    /// Reference canvas dimensions. Every coordinate in this file — and in
    /// `BodyMetric.bodyPosition` / `InjectionSite.silhouettePosition` — is
    /// expressed relative to this size.
    static let referenceSize = CGSize(width: 320, height: 560)

    /// Scale a point from the reference 320x560 space to the actual render
    /// size. Both BodySilhouetteView and BodyMapView use this to place
    /// interactive markers over the silhouette.
    static func scaled(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: point.x * size.width / referenceSize.width,
            y: point.y * size.height / referenceSize.height
        )
    }

    var body: some View {
        Canvas { context, size in
            let sx = size.width / Self.referenceSize.width
            let sy = size.height / Self.referenceSize.height
            let s = min(sx, sy)  // uniform scale for corner radii
            let fill = GraphicsContext.Shading.color(fillColor)

            // Helpers.
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
                CGRect(x: x * sx, y: y * sy, width: w * sx, height: h * sy)
            }
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * sx, y: y * sy)
            }

            // Head — slightly taller than wide.
            context.fill(Path(ellipseIn: rect(130, 14, 60, 70)), with: fill)

            // Neck — tapered trapezoid.
            var neck = Path()
            neck.move(to: pt(146, 80))
            neck.addLine(to: pt(174, 80))
            neck.addLine(to: pt(180, 112))
            neck.addLine(to: pt(140, 112))
            neck.closeSubpath()
            context.fill(neck, with: fill)

            // Shoulders / deltoids — two overlapping ellipses for a muscular cap.
            context.fill(Path(ellipseIn: rect(52, 108, 88, 70)), with: fill)
            context.fill(Path(ellipseIn: rect(180, 108, 88, 70)), with: fill)

            // Chest / torso — V-tapered rounded rect.
            context.fill(Path(roundedRect: rect(88, 130, 144, 130), cornerRadius: 20 * s), with: fill)

            // Waist — narrower block bridging torso and hips.
            context.fill(Path(roundedRect: rect(104, 250, 112, 70), cornerRadius: 16 * s), with: fill)

            // Hips / pelvis — flared.
            context.fill(Path(roundedRect: rect(92, 300, 136, 62), cornerRadius: 22 * s), with: fill)

            // Upper arms.
            var leftUpper = Path()
            leftUpper.move(to: pt(58, 145))
            leftUpper.addLine(to: pt(92, 155))
            leftUpper.addLine(to: pt(84, 290))
            leftUpper.addLine(to: pt(46, 280))
            leftUpper.closeSubpath()
            context.fill(leftUpper, with: fill)

            var rightUpper = Path()
            rightUpper.move(to: pt(262, 145))
            rightUpper.addLine(to: pt(228, 155))
            rightUpper.addLine(to: pt(236, 290))
            rightUpper.addLine(to: pt(274, 280))
            rightUpper.closeSubpath()
            context.fill(rightUpper, with: fill)

            // Forearms.
            var leftForearm = Path()
            leftForearm.move(to: pt(46, 280))
            leftForearm.addLine(to: pt(84, 290))
            leftForearm.addLine(to: pt(76, 380))
            leftForearm.addLine(to: pt(44, 380))
            leftForearm.closeSubpath()
            context.fill(leftForearm, with: fill)

            var rightForearm = Path()
            rightForearm.move(to: pt(274, 280))
            rightForearm.addLine(to: pt(236, 290))
            rightForearm.addLine(to: pt(244, 380))
            rightForearm.addLine(to: pt(276, 380))
            rightForearm.closeSubpath()
            context.fill(rightForearm, with: fill)

            // Thighs.
            var leftThigh = Path()
            leftThigh.move(to: pt(96, 358))
            leftThigh.addLine(to: pt(156, 358))
            leftThigh.addLine(to: pt(150, 470))
            leftThigh.addLine(to: pt(108, 470))
            leftThigh.closeSubpath()
            context.fill(leftThigh, with: fill)

            var rightThigh = Path()
            rightThigh.move(to: pt(164, 358))
            rightThigh.addLine(to: pt(224, 358))
            rightThigh.addLine(to: pt(212, 470))
            rightThigh.addLine(to: pt(170, 470))
            rightThigh.closeSubpath()
            context.fill(rightThigh, with: fill)

            // Calves.
            var leftCalf = Path()
            leftCalf.move(to: pt(110, 470))
            leftCalf.addLine(to: pt(148, 470))
            leftCalf.addLine(to: pt(142, 548))
            leftCalf.addLine(to: pt(116, 548))
            leftCalf.closeSubpath()
            context.fill(leftCalf, with: fill)

            var rightCalf = Path()
            rightCalf.move(to: pt(172, 470))
            rightCalf.addLine(to: pt(210, 470))
            rightCalf.addLine(to: pt(204, 548))
            rightCalf.addLine(to: pt(178, 548))
            rightCalf.closeSubpath()
            context.fill(rightCalf, with: fill)
        }
    }
}
