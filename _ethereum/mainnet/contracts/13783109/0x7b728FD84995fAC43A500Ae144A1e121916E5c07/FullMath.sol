// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library FullMath {
    function divMul(uint256 a, uint256 b, uint256 c) internal pure returns (uint256 result) {
        assembly {
            let d := div(a, b)
            result := mul(d, c)
        }
        return result;
    }
}