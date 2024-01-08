// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./SafeMath.sol";

library Math {
    using SafeMath for uint;

    function sumOf3UintArray(uint[3] memory data) internal pure returns(uint) {
        return data[0].add(data[1]).add(data[2]);
    }
}
