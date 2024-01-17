// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract Leaderboard {
    event Claim(uint256 indexed gas, uint256 indexed time, address submitter, bytes32 hash);

    function submitClaim(uint256 gas, bytes32 hash) external {
        emit Claim(gas, block.timestamp, msg.sender, hash);
    }
}