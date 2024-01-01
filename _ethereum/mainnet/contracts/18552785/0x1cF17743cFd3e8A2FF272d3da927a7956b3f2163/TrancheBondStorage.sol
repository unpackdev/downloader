// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

enum TrancheLevel {
    A,
    B,
    Z
}

enum UnderlyingAssetType {
    PODS,
    ERC20
}

struct TrancheMetadata {
    // farmer's market value for tranche. it is same as totalSupply when minting
    uint256 fmv;
    // fmv claimed after tranche is mature
    uint256 claimedFMV;
}

struct UnderlyingAssetMetadata {
    // zero address if underlying asset is pods
    address contractAddress;
    UnderlyingAssetType assetType;
    uint48 maturityDate;
    // total amount of deposited underlying asset
    // sum of pods for all deposited podlines if underlying asset is pods
    uint256 totalDeposited;
    // calculated FMV
    uint256 totalFMV;
}

/// @notice stores group of podlines that user deposited
struct DepositPods {
    // array of indexes for each plot
    uint256[] podIndexes;
    // array of pods for each plot
    uint256[] amounts;
    // array of fmves for each plot
    uint256[] fmvs;
    // FMV Farmer Market Value in USD
    // uint256 totalFMV;
    // represent divided podline by each tranche level after transfer some pods
    // 1,3 - startIndex and Offsets for tranche A, 2,4 - for tranche B, 3,5 - for tranche Z
    uint128[6] startIndexAndOffsets;
}

library TrancheBondStorage {
    struct Layout {
        // Stores all pods that users deposited, mapping from podline index to pods amount
        // mapping(uint256 => uint256) depositedPlots;
        // Pods group deposited to create tranche, mapping from deposit id to pods groups
        mapping(uint256 => DepositPods) depositedPods;
        // Mapping from deposit id to underlying asset metadata
        mapping(uint256 => UnderlyingAssetMetadata) underlyingAssets;
        // Mapping from tranch index to A,B,Z tranches. the total number of tranches is always 4 times the number of deposits
        mapping(uint256 => TrancheMetadata) tranches;
        // total number of deposits, also it is used as a latest id for storage to store deposited assets
        uint256 curDepositCount;
        uint48[] periods;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("irrigation.contracts.storage.TrancheBond");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
