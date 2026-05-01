// Factory helpers for constructing CMMotionActivity instances in tests.
// CMMotionActivity has no public initialiser, so KVC is used to set the flags.

import CoreMotion

/// Provides CMMotionActivity instances with specific flags set via KVC,
/// working around the absence of a public designated initialiser.
enum TestMotionActivity {
    /// Returns a `CMMotionActivity` with only the `stationary` flag set to true.
    static func stationary() -> CMMotionActivity {
        let a = CMMotionActivity()
        a.setValue(true, forKey: "stationary")
        return a
    }

    /// Returns a `CMMotionActivity` with only the `walking` flag set to true.
    static func walking() -> CMMotionActivity {
        let a = CMMotionActivity()
        a.setValue(true, forKey: "walking")
        return a
    }
}
