// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

import "./SafeMath.sol";

library BinaryExp {
    using SafeMath for uint256;

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            return 1;
        } else if (b == 1) {
            return a;
        } else {
            uint256 ret = 1;
            for (; b > 0; ) {
                if (b.mod(2) == 1) {
                    ret = ret.mul(a);
                }
                a = a.mul(a);
                b = b.div(2);
            }
            return ret;
        }
    }
}
