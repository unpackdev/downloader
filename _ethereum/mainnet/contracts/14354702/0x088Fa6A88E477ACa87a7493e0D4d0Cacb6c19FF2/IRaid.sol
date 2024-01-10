// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRaid {
    struct Round {
        uint16 boss;
        uint32 roll;
        uint32 startBlock;
        uint32 finalBlock;
    }

    struct Raider {
        uint32 dpb;
        uint32 startedAt;
        uint32 startBlock;
        uint32 startRound;
        uint32 startSnapshot;
        uint256 pendingRewards;
    }

    struct Boss {
        uint32 weight;
        uint32 blockHealth;
        uint128 multiplier;
    }

    struct Snapshot {
        uint32 initialBlock;
        uint32 initialRound;
        uint32 finalBlock;
        uint32 finalRound;
        uint256 attackDealt;
    }

    struct RaidData {
        uint16 boss;
        uint32 roundId;
        uint32 health;
        uint32 maxHealth;
        uint256 seed;
    }

    function updateDamage(address user, uint32 _dpb) external;
}
