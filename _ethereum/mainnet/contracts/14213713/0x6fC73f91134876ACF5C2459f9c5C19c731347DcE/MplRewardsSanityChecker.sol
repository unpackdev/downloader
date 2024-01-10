// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;

contract MplRewardsSanityChecker {

    function checkPeriodFinish(uint256 timestamp_) external {
        require(timestamp_ > block.timestamp);
    }

}