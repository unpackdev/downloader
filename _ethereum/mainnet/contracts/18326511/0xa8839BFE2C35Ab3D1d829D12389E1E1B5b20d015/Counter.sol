// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Counter {
    uint256 public number = 0;

    function reset() public {
        number = 0;
    }

    function increase() public returns (uint256) {
        number++;
        return number;
    }
}
