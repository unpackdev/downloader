// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SafeMath.sol";

library UintLibrary {
    using SafeMath for uint;

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}

