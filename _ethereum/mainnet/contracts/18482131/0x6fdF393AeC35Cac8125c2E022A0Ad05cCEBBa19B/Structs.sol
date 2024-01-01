// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum ClaimType {
    WalletRewards,
    CommunityPresale,
    PrivatePresale,
    Ecosystem,
    Contributors
}

struct ClaimData {
    uint128 totalClaimable;
    uint128 claimed;
}

struct NFTClaimData {
    uint128 airdropTotalClaimable;
    uint128 rewardsTotalClaimable;
    uint128 airdropClaimed;
    uint128 rewardsClaimed;
}

struct ClaimSchedule {
    uint256 startCycle;
    uint256[] lockUpBPs;
}

struct NFTClaimable {
    uint256 collectionId;
    uint256 tokenId;
    uint128 airdropTotalClaimable;
    uint128 rewardsTotalClaimable;
}

struct NFTCollectionInfo {
    uint256 collectionId;
    uint256[] tokenIds;
}

struct NFTCollectionClaimRequest {
    uint256 collectionId;
    uint256[] tokenIds;
    bool[] withNFTAirdropList;
    bool[] withNFTRewardsList;
}

struct CollectionClaimData {
    uint256 collectionId;
    uint256 tokenId;
    uint128 airdropClaimable;
    uint256 airdropClaimableExpiry;
    uint128 airdropTotalClaimable;
    uint128 airdropClaimed;
    uint128 rewardsClaimable;
    uint256 rewardsClaimableExpiry;
    uint128 rewardsTotalClaimable;
    uint128 rewardsClaimed;
}

struct UnclaimedNFTRewards {
    uint128 lastTokenId;
    uint128 totalUnclaimed;
}
