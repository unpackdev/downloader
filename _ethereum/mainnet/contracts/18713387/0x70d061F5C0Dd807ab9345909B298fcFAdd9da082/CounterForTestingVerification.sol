// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

contract CounterForTestingVerification {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function reset() public {
        number = 0;
    }
}
