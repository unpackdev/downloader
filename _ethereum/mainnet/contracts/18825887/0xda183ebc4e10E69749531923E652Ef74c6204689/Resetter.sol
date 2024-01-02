// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import "./ICounter.sol";

contract Resetter {
    function reset(ICounter counter) external {
        counter.setNumber(0);
    }
}
