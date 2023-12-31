// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./base-contract.sol";

contract TestContract is BaseContract {
    uint arg;
    Point[] p_;

    constructor(uint firstarg, Body memory body) BaseContract(5) {
        arg = firstarg;

        Point[] memory test = body.p;

        p_.push(test[0]);

        p_.push(test[1]);
    }
}
