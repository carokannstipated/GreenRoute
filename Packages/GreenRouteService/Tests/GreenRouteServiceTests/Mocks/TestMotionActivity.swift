//
//  TestMotionActivity.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import CoreMotion

enum TestMotionActivity {
    static func stationary() -> CMMotionActivity {
        let a = CMMotionActivity()
        a.setValue(true, forKey: "stationary")
        return a
    }

    static func walking() -> CMMotionActivity {
        let a = CMMotionActivity()
        a.setValue(true, forKey: "walking")
        return a
    }
}
