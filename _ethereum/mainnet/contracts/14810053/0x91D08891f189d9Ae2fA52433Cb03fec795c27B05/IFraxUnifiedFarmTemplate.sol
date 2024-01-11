// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

interface IFraxUnifiedFarmTemplate {
    // Struct for the stake
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    // Calculate the combined weight for an account
    function calcCurCombinedWeight(address account)
        external
        view
        returns (
            uint256 old_combined_weight,
            uint256 new_vefxs_multiplier,
            uint256 new_combined_weight
        );

    // get the current minimum lockTime on the staking contract
    function lock_time_min() external view returns (uint256);

    /// @notice Send the rewards to the destination
    /// @return Array of all sent rewards (only the amounts you need to know the order of the rewards)
    function getReward(address destination_address) external returns (uint256[] memory);

    // ------ LOCK RELATED ------

    /// @notice get the current lock amount (without accruing interest) useful to compute the kekId
    function lockedLiquidityOf(address account) external view returns (uint256);

    // Add additional LPs to an existing locked stake
    // REBASE: If you simply want to accrue interest, call this with addl_liq = 0
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;

    /// @notice Two different stake functions are needed because of delegateCall and msg.sender issues (important for migration)
    /// @return the keckId
    function stakeLocked(uint256 liquidity, uint256 secs) external returns (bytes32);

    // ------ WITHDRAWING ------

    /// @notice Each withdraw will delete the locked associated to the `keck_id`
    /// @return Liquidity withdrawn from the locker
    function withdrawLocked(bytes32 kek_id, address destination_address) external returns (uint256);

    // ------ REWARDS ------

    function stakerSetVeFXSProxy(address proxy_address) external;

    function rewardRates(uint256 token_idx) external view returns (uint256 rwd_rate);

    function lockMultiplier(uint256 secs) external view returns (uint256);

    function totalCombinedWeight() external view returns (uint256);
}
