// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./FayreMembershipCard721.sol";

contract FayreStandardCard is FayreMembershipCard721 {
    function initialize() public initializer {
        __FayreMembershipCard721_init("FAYRESTANDARDCARD", "FAYRESC", 50e18, 1000e18, 1500, 10000e18, 1);
    }
}