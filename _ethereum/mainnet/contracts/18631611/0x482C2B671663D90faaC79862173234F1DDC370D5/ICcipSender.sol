// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICcipSender {
    // function DFX() external returns (address);
    // function relayReward2() external;
    function relayReward(uint256 amount) external returns (bytes32);
}
