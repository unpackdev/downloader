// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library LibGovNFTTierStorage {
    event SingleSPTierLevelAdded(
        uint256 indexed spTierId,
        uint256 ltv,
        bool singleToken,
        bool multiToken,
        bool singleNft,
        bool multiNFT
    );

    event NFTTierLevelAdded(
        address nftContract,
        bool isTraditional,
        address spToken,
        bytes32 traditionalTier,
        uint256 spTierId,
        address[] allowedNfts,
        address[] allowedSuns
    );

    event AddNFTTokensinNftTier(address nftContract, address[] allowedNfts);

    event AddNFTSunTokensinNftTier(address nftContract, address[] allowedSuns);

    event SingleSPTierLevelUpdated(
        uint256 indexed spTierId,
        uint256 ltv,
        bool singleToken,
        bool multiToken,
        bool singleNft,
        bool multiNFT
    );

    event SingleSPTierLevelRemoved(uint256 spTierId);
    event NftTierLevelRemoved(address nftContract);

    bytes32 constant GOVNFTTIER_STORAGE_POSITION =
        keccak256("diamond.standard.GOVNFTTier.storage");

    struct SingleSPTierData {
        uint256 ltv;
        bool singleToken;
        bool multiToken;
        bool singleNft;
        bool multiNFT;
    }

    struct NFTTierData {
        bool isTraditional;
        address spToken; // strategic partner token address - erc20, in case if isTraditional is false
        bytes32 traditionalTier;
        uint256 spTierId;
        address[] allowedNfts; //for sp nft tier, when isTraditional is false
        address[] allowedSuns; //for sp nft tier, when isTraditional is false
    }

    struct GovNFTTierStorage {
        mapping(uint256 => SingleSPTierData) spTierLevels;
        mapping(address => NFTTierData) nftTierLevels;
        mapping(address => mapping(address => bool)) isNFTExist;
        mapping(address => mapping(address => bool)) isSunTokenExist;
        address[] nftTierLevelsKeys;
        uint256[] spTierLevelKeys;
    }

    function govNftTierStorage()
        internal
        pure
        returns (GovNFTTierStorage storage es)
    {
        bytes32 position = GOVNFTTIER_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}
