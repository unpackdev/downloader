// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC20Upgradeable.sol";

/// @notice User Setting Info
struct UserInfo {
    bool isAutoIrrigate;
    // last poolIndex that user interact
    uint256 lastPoolIndex;
    // total claimable reward of user
    uint256 pending;
    // reward rate in this month = sum (block time * amount)
    uint256 rewardRate;
    // deposited water amount
    uint256 amount;
}

struct PoolInfo {
    // sum of all user reward rate in this month
    uint256 totalRewardRate;
    uint256 monthlyRewards;
    uint256 endTime;
}

library WaterTowerStorage {
    struct Layout {
        // total ether reward received from other markets
        uint256 totalRewards;
        // current pool index
        uint256 curPoolIndex;
        // total water deposit amount
        uint256 totalDeposits;
        // water amount sent as irrigate bonus
        uint256 totalBonus;
        // pool info per month
        mapping(uint256 => PoolInfo) pools;
        // deposit amount, pending reward, and setting for user
        mapping(address => UserInfo) users;

        /// @dev config variables
        // bonus percent for irrigator
        uint256 irrigateBonusRate;
        // Middle asset for irrigating ether reward
        address middleAssetForIrrigate;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("irrigation.contracts.storage.WaterTower");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function curPool() internal view returns (PoolInfo storage) {
        return layout().pools[layout().curPoolIndex];
    }

    function userInfo(address user) internal view returns (UserInfo storage) {
        return layout().users[user];
    }
}
