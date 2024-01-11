// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./FayreMembershipCard721.sol";

contract FayrePremiumOGCard is FayreMembershipCard721 {
    function initialize() public initializer {
        __FayreMembershipCard721_init("FAYREOGCARD", "FAYREOG", 2500e18, 75000e18, 50, 0, 5);
    }
}