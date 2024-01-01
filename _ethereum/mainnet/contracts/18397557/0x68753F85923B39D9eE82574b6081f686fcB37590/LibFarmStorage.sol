//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IERC20.sol";

library LibFarmStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("Farm.contracts.storage.LibFarmStorage");

    struct Lock {
        uint256 startTimestamp; // lock start time
        uint256 amount; // amount of LP
        uint256 receiptAmount; // amount of receipt tokens
        uint256 duration; // lock duration
        uint256 unlocked; // 0 false, 1 true
        address locker; // address that locked LP
    }

    struct Vest {
        uint256 startTimestamp; // reward vesting start time
        uint256 amount; // amount of S rewards vested in base amount
        uint256 vested; // 0 false, 1 true
        address vester; // address that is vesting
    }

    struct Layout {
        address stakingToken; // WETH-S-LP
        address rewardToken; // S
        address treasury; // treasury multisig or something
        address router; // router for swapping to ETH
        mapping(address => uint) balanceOf; // balance of receipt token
        uint256 totalSupply; // totalSupply of receipt tokens
        uint256 rewardIndex; // in base amount
        mapping(address => uint) rewardIndexOf;
        mapping(address => uint) earned;
        uint256 lastRewardBalance; // rewardToken balance of farm in base amounts
        /* lock */
        uint256 currentLockingIndex; // current index and current total locks
        uint256 minLockDuration; // currently 3 days
        uint256 maxLockDuration; // currently 90 days
        mapping(uint256 => Lock) lockingIndexToLock; // lockingIndex => Lock
        mapping(address => uint256[]) addressToLockingIndexList; // address => lockingIndexList that is still locked
        /* vest */
        uint256 currentVestIndex;
        uint256 earlyVestPenalty; // in BP currently 5_000
        uint256 vestDuration; // currently 7 days
        mapping(uint256 => Vest) vestIndexToVest; // vestIndex => Vest
        mapping(address => uint256[]) addressToVestIndexList; // address => vestIndexList
        mapping(address => uint256) addressToTotalVesting; // address => totalVesting
        uint256 penaltyToStaker;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
