// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Fix64V1.sol";

library XorShift {
    function nextFloat(int32 seed)
        internal
        pure
        returns (int64 value, int32 modifiedSeed)
    {
        seed ^= seed << 13;
        seed ^= seed >> 17;
        seed ^= seed << 5;

        int256 t0;
        if (seed < 0) {
            t0 = ~seed + 1;
        } else {
            t0 = seed;
        }

        value = Fix64V1.div(int64((t0 % 1000) * Fix64V1.ONE), 1000 * Fix64V1.ONE);  
        return (value, seed);
    }

    function nextFloatRange(int32 seed, int64 a, int64 b) internal pure returns (int64 value, int32 modifiedSeed)
    {
        (int64 nextValue, int32 nextSeed) = nextFloat(seed);
        modifiedSeed = nextSeed;        
        value = Fix64V1.add(a, Fix64V1.mul(Fix64V1.sub(b, a), nextValue));
    }

    function nextInt(int32 seed, int64 a, int64 b) internal pure returns (int32 value, int32 modifiedSeed)
    {
        (int64 nextValue, int32 nextSeed) = nextFloatRange(seed, a, Fix64V1.add(b, Fix64V1.ONE));
        modifiedSeed = nextSeed;   

        int64 floor = Fix64V1.floor(nextValue);
        value = int32(floor / Fix64V1.ONE);
    }    
}
