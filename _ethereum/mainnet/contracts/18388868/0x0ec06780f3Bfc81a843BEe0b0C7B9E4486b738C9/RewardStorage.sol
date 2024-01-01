// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library RewardStorage {
    struct RewardCheckpoint {
        uint256 startRound;
        uint256 totalRound;
        uint256 totalReward;
        uint256 lastActiveRound; // deprecated
        uint256[] activeRounds;
        // claimable round index
        uint256 daoCreatorClaimableRoundIndex;
        mapping(bytes32 canvasId => uint256 claimableRoundIndex) canvasCreatorClaimableRoundIndexes;
        mapping(address nftMinter => uint256 claimableRoundIndex) nftMinterClaimableRoundIndexes;
    }

    struct RewardInfo {
        RewardCheckpoint[] rewardCheckpoints;
        uint256 rewardIssuePendingRound;
        uint256 rewardDecayFactor;
        bool isProgressiveJackpot;
        // weights
        mapping(uint256 round => uint256 totalWeight) totalWeights; // also total ETH in DAO fee pool at given round
        mapping(uint256 round => uint256 weight) protocolWeights;
        mapping(uint256 round => uint256 weight) daoCreatorWeights;
        mapping(uint256 round => mapping(bytes32 canvasId => uint256 weight)) canvasCreatorWeights;
        mapping(uint256 round => mapping(address nftMinter => uint256 weight)) nftMinterWeights;
        uint256 daoCreatorERC20RatioInBps;
        uint256 canvasCreatorERC20RatioInBps;
    }

    struct Layout {
        mapping(bytes32 daoId => RewardInfo rewardInfo) rewardInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.RewardStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
