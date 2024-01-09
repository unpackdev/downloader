// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "AccessControl.sol";
import "ABDKMath64x64.sol";

// Some hints to help with the math:
//
// https://mathopenref.com/graphfunctions.html
// https://www.wolframalpha.com/input/?i2d=true&i=Integrate%5BPower%5Be%2Ckt%5D%2C%7Bt%2Ca%2Cb%7D%5D
// https://www.wolframalpha.com/input/?i2d=true&i=plot+Piecewise%5B%7B%7BPower%5Be%2C4%5C%2840%29t-1%5C%2841%29%5D%2Ct%3C%3D1%7D%2C%7B1%2C1%3Ct%3C2%7D%2C%7BPower%5Be%2C-t%2B2%5D%2Ct%3E%3D2%7D%7D%5D%5C%2844%29+0.01%2BIntegrate%5BPiecewise%5B%7B%7BPower%5Be%2C4%5C%2840%29t-1%5C%2841%29%5D%2Ct%3C%3D1%7D%2C%7B1%2C1%3Ct%3C2%7D%2C%7BPower%5Be%2C-t%2B2%5D%2Ct%3E%3D2%7D%7D%5D%2Ct%5D+from+t%3D0+to+8
//
// Special thanks to ABDK!
// https://abdk.consulting
// https://github.com/abdk-consulting
//

/**
 * @dev declare and safegaurd token allocations among a number of slices.
 */
library EmissionCurves {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    struct Curve {
        int128 timeStart;       // time of emission start as 64.64 seconds
        int128 durationGrowth;  // seconds until max emissions reached as 64.64
        int128 expGrowth;       // e^(expGrowth * t) t=[-durationGrowthI, 0) as +64.64
        int128 durationMax;     // seconds duration of max emissions as 64.64
        int128 durationDecay;   // seconds duration of emission decay phase as 64.64
        int128 expDecay;        // e^(expDecay * t) t=(0, durationDecayI] as -64.64
        int128 A;               // area under entire envelope in world units
    }

    function newCurve(
        uint256 timeStart,
        uint32 durationGrowth,
        uint8 expGrowth,
        uint32 durationMax,
        uint32 durationDecay,
        uint8 expDecay
    )
        internal
        pure
        returns (Curve memory)
    {
        return newCurve64x64(
            timeStart.fromUInt(),
            uint256(durationGrowth).fromUInt(),
            uint256(expGrowth).fromUInt().div(uint256(10).fromUInt()),
            uint256(durationMax).fromUInt(),
            uint256(durationDecay).fromUInt(),
            uint256(expDecay).fromUInt().div(uint256(10).fromUInt()));
    }

    function newCurve64x64(
        int128 timeStart,
        int128 durationGrowth,
        int128 expGrowth,
        int128 durationMax,
        int128 durationDecay,
        int128 expDecay
    )
        internal
        pure
        returns (Curve memory)
    {
        // It is easiest to treat the time of max emission as t=0 and growth phase
        // occuring before t=0 to avoid dealing with the asymptotic coming from -∞.  
        //
        // area under growth era = ∫(-1, 0) e^(expGrowth * t) dt
        //                       = (1 - e^-expGrowth / expGrowth
        //
        int128 I_growth = expGrowth == 0 ? int128(0) : uint256(1).fromUInt().sub(expGrowth.neg().exp()).div(expGrowth);

        // After the growth phase, max emissions occur for the given duration.
        //
        // area under max emission era = ∫(0, 1) 1 dt
        //                             = 1
        //
        //int128 I_max = 1;

        // After the max emission phase, emissions decay exponentially.
        //
        // area under decay era = ∫(0, 1) e^-(expDecay * t) dt
        //                      = (1 - e^-expDecay) / expDecay
        //
        int128 I_decay = expDecay == 0 ? int128(0) : uint256(1).fromUInt().sub(expDecay.neg().exp()).div(expDecay);

        return Curve(
            timeStart,
            durationGrowth,
            expGrowth,
            durationMax,
            durationDecay,
            expDecay,
            I_growth.mul(durationGrowth).add(durationMax).add(I_decay.mul(durationDecay))
        );
    }

    function calcGrowth(Curve storage curve, uint256 timestamp)
        public view
        returns (int128)
    {
        // time elapsed since curve start    
        int128 t = timestamp.fromUInt().sub(curve.timeStart);
        if (t < 0) {
            return 0;
        }

        if (curve.durationGrowth == 0 && curve.durationMax == 0 && curve.durationDecay == 0) {
            // Since there's no envelope defined, minting may occur whenever,
            // so return the unit max and defer to total allocation limit.
            return uint256(1).fromUInt();
        }

        if (t < curve.durationGrowth) {
            // convert time from world to integral coordinates to keep the math simple and no overflow
            t = t.div(curve.durationGrowth);
            return _integrateGrowth(curve, t)
                .mul(curve.durationGrowth) // scale to world coordinates
                .div(curve.A);             // normalize against sum of all phases
        }
        t = t.sub(curve.durationGrowth);
        if (t < curve.durationMax) {
            return _integrateGrowth(curve, uint256(1).fromUInt()) // growth phase
                .mul(curve.durationGrowth) // in world coordinates
                .add(t)                    // add max emission area
                .div(curve.A);             // normalize against sum of all phases
        }
        t = t.sub(curve.durationMax);
        if (t < curve.durationDecay) {
            // convert time from world to integral coordinates to keep the math simple and no overflow
            t = t.div(curve.durationDecay);
            return _integrateGrowth(curve, uint256(1).fromUInt()) // growth phase
                .mul(curve.durationGrowth)     // scale to world coordinates
                .add(curve.durationMax)        // max phase (already in world coords)
                .add(_integrateDecay(curve, t) // decay phase
                    .mul(curve.durationDecay)) // scale to world coordinates
                .div(curve.A);                 // normalize against sum of all phases
        }
        // 100%
        return uint256(1).fromUInt();
    }

    function _integrateGrowth(Curve storage curve, int128 t) private view returns (int128) {
        //
        // = ∫(-durationGrowthI, t-durationGrowthI) e^(expGrowth * T) dT
        // = (e^((t - durationGrowthI) * expGrowth) - e^(-durationGrowthI * expGrowth)) / expGrowth
        //
        return t
            .sub(uint256(1).fromUInt())
            .mul(curve.expGrowth)
            .exp()
            .sub(curve.expGrowth.neg().exp())
            .div(curve.expGrowth);
    }

    function _integrateDecay(Curve storage curve, int128 t) private view returns (int128) {
        //
        // = ∫(0,t) e^(-expDecay * T) dT
        // = (1 - e^(-expDecay * t)) / expDecay
        //
        return uint256(1).fromUInt()
            .sub(curve.expDecay.mul(t).neg().exp())
            .div(curve.expDecay);
    }
}
