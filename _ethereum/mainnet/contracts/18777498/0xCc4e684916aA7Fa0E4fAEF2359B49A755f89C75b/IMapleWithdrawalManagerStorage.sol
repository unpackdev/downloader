// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IMapleWithdrawalManagerStorage {

    struct CycleConfig {
        uint64 initialCycleId;    // Identifier of the first withdrawal cycle using this configuration.
        uint64 initialCycleTime;  // Timestamp of the first withdrawal cycle using this configuration.
        uint64 cycleDuration;     // Duration of the withdrawal cycle.
        uint64 windowDuration;    // Duration of the withdrawal window.
    }

    /**
     *  @dev    Gets the configuration for a given config id.
     *  @param  configId_        The id of the configuration to use.
     *  @return initialCycleId   Identifier of the first withdrawal cycle using this configuration.
     *  @return initialCycleTime Timestamp of the first withdrawal cycle using this configuration.
     *  @return cycleDuration    Duration of the withdrawal cycle.
     *  @return windowDuration   Duration of the withdrawal window.
     */
    function cycleConfigs(uint256 configId_)
        external returns (uint64 initialCycleId, uint64 initialCycleTime, uint64 cycleDuration, uint64 windowDuration);

    /**
     *  @dev    Gets the id of the cycle that account can exit on.
     *  @param  account_ The address to check the exit for.
     *  @return cycleId_ The id of the cycle that account can exit on.
     */
    function exitCycleId(address account_) external view returns (uint256 cycleId_);

    /**
     *  @dev    Gets the most recent configuration id.
     *  @return configId_ The id of the most recent configuration.
     */
    function latestConfigId() external view returns (uint256 configId_);

    /**
     *  @dev    Gets the amount of locked shares for an account.
     *  @param  account_      The address to check the exit for.
     *  @return lockedShares_ The amount of shares locked.
     */
    function lockedShares(address account_) external view returns (uint256 lockedShares_);

    /**
     *  @dev    Gets the address of the pool associated with this withdrawal manager.
     *  @return pool_ The address of the pool.
     */
    function pool() external view returns (address pool_);

    /**
     *  @dev    Gets the address of the pool manager associated with this withdrawal manager.
     *  @return poolManager_ The address of the pool manager.
     */
    function poolManager() external view returns (address poolManager_);

    /**
     *  @dev    Gets the amount of shares for a cycle.
     *  @param  cycleId_          The id to cycle to check.
     *  @return totalCycleShares_ The amount of shares in the cycle.
     */
    function totalCycleShares(uint256 cycleId_) external view returns (uint256 totalCycleShares_);

}
