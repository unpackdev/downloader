// SPDX-License-Identifier: MIT
// ERC20 Extensions v1.1.1
pragma solidity ^0.8.0;

library SafeMathInt {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        assert(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        assert(b >= 0);
        return b;
    }
}
