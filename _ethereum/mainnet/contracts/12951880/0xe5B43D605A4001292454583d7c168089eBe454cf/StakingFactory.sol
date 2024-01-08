//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./IStakingFactory.sol";
import "./StakingRewards.sol";
import "./IStakingRewards.sol";

/// @title StakingFactory, A contract where users can create their own staking pool
contract StakingFactory is IStakingFactory {
    address[] private allPools;
    mapping(address => bool) private isOurs;

    /**
     * @notice Caller creates a new StakingRewards pool and it gets added to this factory
     * @param _stakingToken token address that needs to be staked to earn rewards
     * @param _startBlock block number when rewards start
     * @param _endBlock block number when rewards end
     * @param _bufferBlocks no. of blocks after which owner can reclaim any unclaimed rewards
     * @return listaddr address of newly created contract
     */
    function createPool(
        address _stakingToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _bufferBlocks
    ) external override returns (address listaddr) {
        listaddr = address(
            new StakingRewards(
                _stakingToken,
                _startBlock,
                _endBlock,
                _bufferBlocks
            )
        );

        StakingRewards(listaddr).transferOwnership(msg.sender);

        allPools.push(listaddr);
        isOurs[listaddr] = true;

        emit PoolCreated(msg.sender, listaddr);
    }

    /**
     * @notice Checks if a address belongs to this contract' pools
     */
    function ours(address _a) external view override returns (bool) {
        return isOurs[_a];
    }

    /**
     * @notice Returns no. of pools stored in contract
     */
    function listCount() external view override returns (uint256) {
        return allPools.length;
    }

    /**
     * @notice Returns address of the pool located at given id
     */
    function listAt(uint256 _idx) external view override returns (address) {
        require(_idx < allPools.length, "Index exceeds list length");
        return allPools[_idx];
    }
}
