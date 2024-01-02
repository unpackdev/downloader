// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAdapter
 * @author StakeEase
 */
interface IAdapter {
    /**
     * @notice Function to stake ETH on Stader/Lido and then restake using Kelp.
     * @param index Index of the call.
     * @param returnAmount Amount returned from the last call.
     * @param data data for this adapter.
     */
    function execute(
        uint256 index,
        uint256 returnAmount,
        bytes memory data
    ) external payable returns (uint256, address);
}
