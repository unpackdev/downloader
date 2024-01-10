// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

/**
 *  @title Tracks various configurations related to rewards
 *  Reactors, pools, base reward amounts, contracts query, etc
 *  Any off-chain process should use this as its source of truth for configuration
 */
interface IRewardsManager {

    event ExcludePoolsRegistered(address[] pools);
    event ExcludePoolsUnRegistered(address[] pools);

    /// @notice Register the pools to exclude from the reward calculation
    function registerExcludePools(address[] calldata pools) external;
    
     /// @notice Unregister the pools to exclude from the reward calculation
    function unregisterExcludePools(address[] calldata pools) external;

    /// @notice Get the pools to exclude from the reward calculation
    /// @return pools
    function getExcludePools() external view returns (address[] memory pools);
}   
