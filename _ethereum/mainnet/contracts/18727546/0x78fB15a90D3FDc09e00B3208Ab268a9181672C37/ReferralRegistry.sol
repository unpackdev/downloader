// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract ReferralRegistry {
    mapping(address => address) public referrals; // Maps a referee to the referrer

    event ReferralSet(address indexed referee, address indexed referrer);

    constructor() {}

    // Set a referrer for a referee
    function setReferral(address referee, address referrer) external {
        require(referee != referrer, "Cannot refer oneself");
        require(referrals[referee] == address(0), "Referrer already set");
        referrals[referee] = referrer;
        emit ReferralSet(referee, referrer);
    }
}