// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

// interface for Sushiswap MasterChef contract
interface ISushiRewarder {
    function pendingToken(uint256 pid, address user)
        external
        view
        returns (uint256);
}
