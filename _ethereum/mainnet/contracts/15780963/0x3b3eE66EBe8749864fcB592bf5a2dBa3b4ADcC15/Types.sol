//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

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

    struct FixedPriceAllocatorConfig {
        uint256 tokenPrice;
        uint256 hardCap;
        uint256 hurdle;
        uint256 vestingCliffDuration;
        uint256 vestingDuration;
        IERC20 purchaseToken;
        bytes32 inviteCodesMerkleRoot;
        Venture venture;
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

    struct SignatureStoreNftAllocatorInitialConfig {
        string termsUrl;
        bytes32 termsHash;
        SignatureStoreNftAllocator config;
    }

    struct SignatureStoreNftAllocator {
        bytes signature;
        bytes32 inviteCode;
        uint256 numTokens;
    }

    enum AllocatorType {
        NFT
    }

    struct Fraction {
        uint128 num;
        uint128 den;
    }
}

