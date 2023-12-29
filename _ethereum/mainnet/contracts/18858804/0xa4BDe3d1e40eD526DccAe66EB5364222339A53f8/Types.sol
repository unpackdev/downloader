//SPDX-License-Identifier: CC-BY-NC-ND-2.5
pragma solidity 0.8.16;

import "./SafeERC20.sol";
import "./ERC721A.sol";

import "./Venture.sol";

library Types {
    struct VentureConfig {
        address fundsAddress;
        IERC20 ventureToken;
        IERC20 treasuryToken;
        uint256 tokenSupply;
        string name;
        string site;
        string logoUrl;
        string description;
    }

    struct NftAllocatorConfig {
        ERC721A nft;
        Venture venture;
        string name;
        uint256 nftPrice;
        uint256 tokensForAllocation;
        bytes32 inviteCodesMerkleRoot;
        string merkleTreeId;
        SignatureStoreNftAllocatorInitialConfig signatureStore;
    }
    // TODO: this can now be collapsed into a single struct for both NFT and ERC20
    struct SignatureStoreNftAllocatorInitialConfig {
        string termsUrl;
        bytes32 termsHash;
        uint256 hurdle;
        uint256 releaseScheduleStartTimeStamp;
        uint256 tokenLockDuration;
        uint256 releaseDuration;
        SignatureStoreNftAllocator config;
    }

    struct SignatureStoreNftAllocator {
        bytes signature;
        bytes32 inviteCode;
        uint256 numTokens;
    }

    struct ERC20FixedPriceAllocatorConfig {
        Venture venture;
        string name;
        string description;
        IERC20 allocationToken;
        uint256 tokensForAllocation;
        bytes32 inviteCodesMerkleRoot;
        string merkleTreeId;
        ERC20FixedPriceAllocatorSignatureInitialConfig signatureStoreConfig;
    }

    struct ERC20FixedPriceAllocatorSignatureInitialConfig {
        string termsUrl;
        bytes32 termsHash;
        uint256 tokenPrice;
        uint256 hurdle;
        uint256 releaseScheduleStartTimeStamp;
        uint256 tokenLockDuration;
        uint256 releaseDuration;
        ERC20FixedPriceAllocatorSignatureConfig config;
    }

    struct ERC20FixedPriceAllocatorSignatureConfig {
        bytes signature;
        uint256 numTokens;
        bytes32 inviteCode;
    }

    struct AllocatorConfig {
        Venture venture;
        string name;
        string description;
        IERC20 allocationToken;
        uint256 tokensForAllocation;
        uint256 tokenPrice;
        uint256 releaseScheduleStartTimeStamp;
        uint256 tokenLockDuration;
        uint256 releaseDuration;
    }

    struct TokenConfig {
        string name;
        string symbol;
        address owner;
        address[] minterburners;
    }

    enum AllocatorType {
        NFT,
        ERC20_FIXED_PRICE,
        ERC20_MANUAL,
        ERC20_OPTIONS_ALLOCATOR
    }

    enum ImplementationType {
        VENTURE,
        NFT_ALLOCATOR,
        ERC20_FIXED_PRICE_ALLOCATOR,
        ERC20_ULTIMATE_TOKEN,
        ERC20_GOVERNANCE_TOKEN,
        ERC20_BASIC_TOKEN,
        ERC20_OPTIONS_ALLOCATOR
    }

    struct Fraction {
        uint128 num;
        uint128 den;
    }
}

