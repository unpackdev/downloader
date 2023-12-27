// SPDX-License-Identifier: MIT
/*******************************************
              _                       _
             | |                     | |
  _ __   ___ | |_   _ ___   __ _ _ __| |_
 | '_ \ / _ \| | | | / __| / _` | '__| __|
 | |_) | (_) | | |_| \__ \| (_| | |  | |_
 | .__/ \___/|_|\__, |___(_)__,_|_|   \__|
 | |             __/ |
 |_|            |___/

 a homage to math, geometry and cryptography.
********************************************/
pragma solidity ^0.8.4;


library Fixed {
    uint8 constant scale = 32;

    function toFixed(int64 i) internal pure returns (int64){
        return i << scale;
    }

    function toInt(int64 f) internal pure returns (int64){
        return f >> scale;
    }

    /// @notice outputs the first 5 decimal places
    function fractionPart(int64 f) internal pure returns (int64){
        int8 sign = f < 0 ? - 1 : int8(1);
        // zero out the digits before the comma
        int64 fraction = (sign * f) & 2 ** 32 - 1;
        // Get the first 5 decimals
        return int64(int128(fraction) * 1e5 >> scale);
    }

    function wholePart(int64 f) internal pure returns (int64){
        return f >> scale;
    }

    function mul(int64 a, int64 b) internal pure returns (int64) {
        return int64(int128(a) * int128(b) >> scale);
    }

    function div(int64 a, int64 b) internal pure returns (int64){
        return int64((int128(a) << scale) / b);
    }
}