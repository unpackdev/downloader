// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library LibVCTierStorage {
    event VCNFTTierAdded(
        address nftContract,
        bytes32 traditionalTier,
        address[] spAllowedTokens,
        address[] spAllowedNFTs
    );

    event AddVCSpTokens(address nftContract, address[] spAllowedTokens);

    event AddVCNftTokens(address nftContract, address[] spAllowedNFTs);

    bytes32 constant VCTIER_STORAGE_POSITION =
        keccak256("diamond.standard.VCTIER.storage");
    struct VCNFTTier {
        bytes32 traditionalTier;
        address[] spAllowedTokens;
        address[] spAllowedNFTs;
    }

    struct VCTierStorage {
        mapping(address => VCNFTTier) vcNftTiers;
        mapping(address => mapping(address => bool)) isTokenExist;
        mapping(address => mapping(address => bool)) isNFTExist;
        mapping(address => bool) isAlreadyVcTier;
        address[] vcTiersKeys;
    }

    function vcTierStorage() internal pure returns (VCTierStorage storage es) {
        bytes32 position = VCTIER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}
