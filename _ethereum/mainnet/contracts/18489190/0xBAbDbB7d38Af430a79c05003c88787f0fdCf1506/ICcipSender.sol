// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICcipSender {
    function relayReward(uint256 amount) external returns (bytes32);
}
