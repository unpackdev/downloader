// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IUnshethFarm {
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function stakeLocked(uint256, uint256) external;

    function getReward() external returns (uint256[] memory);

    function withdrawLocked(bytes32 kek_id) external;

    function lock_time_for_max_multiplier() external view returns (uint256);
    function lock_time_min() external view returns (uint256);

    function lockedStakesOf(address) external view returns (LockedStake[] memory);

    function sync() external;
}
