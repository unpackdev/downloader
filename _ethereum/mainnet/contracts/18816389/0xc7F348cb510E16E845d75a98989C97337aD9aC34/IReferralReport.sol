// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IReferralReport {
    function distributeReferrerReward(address _referrer, uint _referrer_reward) external;
}
