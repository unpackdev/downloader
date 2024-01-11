// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MADTypeDefinitions {
    // Shared enums
    enum Metaverse {
        DCL_LAND,
        DCL_ESTATE,
        CV
    }

    enum Product {
        ADS,
        RM
    }

    // Radical Market
    struct AssetInfoRM {
        address currentLender;
        uint256 currentPricePerDay;
        uint256 currentCollateral;
        uint256 lastRentUpdateTimestamp;
        uint256 gracePeriodExpiry;
        address pendingLender; // Bidder that's higher than current bid
        uint256 pendingPricePerDay;
        uint256 pendingCollateral;
    }

    struct MetaverseInfoRM {
        uint256 minIncrement;
        uint256 minPeriod;
        uint256 gracePeriod;
        mapping(address => uint256) refunds;
        mapping(address => bool) authorizedStakers;
        mapping(uint256 => AssetInfoRM) assetInfos;
    }

    // Staking Manager
    struct AssetSM {
        address owner;
        Product lockedTo;
        uint256 unclaimedEtherRevenue;
        uint256 unclaimedMADRevenue;
        uint256 unstakeCooldownDeadline; // When unstake is allowed (after the cooldown after a request)
    }

    struct MetaverseInfoSM {
        bool isStakingOpenToPublic;
        uint8 maxOperators;
        address contractAddress;
        uint256 unstakeCooldownDuration;
        mapping(address => bool) authorizedStakers;
        mapping(uint256 => AssetSM) stakedAssets;
        mapping(uint256 => bool) isAdsAsset;
    }
}
