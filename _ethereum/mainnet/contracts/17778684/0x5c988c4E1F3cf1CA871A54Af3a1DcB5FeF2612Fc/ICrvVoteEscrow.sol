// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ICrvVoteEscrow {
    function balanceOf(address) external view returns (uint256);
}
