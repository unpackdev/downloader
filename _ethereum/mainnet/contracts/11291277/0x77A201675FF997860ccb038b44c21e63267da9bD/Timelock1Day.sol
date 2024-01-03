// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.12;

import "./Timelock.sol";

contract Timelock1Day is Timelock {

    uint public constant DELAY = 1 days;
    constructor(address admin_) public Timelock(admin_, DELAY) {
    }

}