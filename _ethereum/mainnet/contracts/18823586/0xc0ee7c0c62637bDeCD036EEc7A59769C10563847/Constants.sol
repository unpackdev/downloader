// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/*//////////////////////////////////////////////////////////////////////////
                                CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

// Core
string constant FX_CONTRACT_REGISTRY = "FX_CONTRACT_REGISTRY";
string constant FX_GEN_ART_721 = "FX_GEN_ART_721";
string constant FX_ISSUER_FACTORY = "FX_ISSUER_FACTORY";
string constant FX_MINT_TICKET_721 = "FX_MINT_TICKET_721";
string constant FX_ROLE_REGISTRY = "FX_ROLE_REGISTRY";
string constant FX_TICKET_FACTORY = "FX_TICKET_FACTORY";

// Periphery
string constant DUTCH_AUCTION = "DUTCH_AUCTION";
string constant FIXED_PRICE = "FIXED_PRICE";
string constant ONCHFS_RENDERER = "ONCHFS_RENDERER";
string constant IPFS_RENDERER = "IPFS_RENDERER";
string constant PSEUDO_RANDOMIZER = "PSEUDO_RANDOMIZER";
string constant TICKET_REDEEMER = "TICKET_REDEEMER";

// EIP-712
bytes32 constant CLAIM_TYPEHASH = keccak256(
    "Claim(address token,uint256 reserveId,uint96 nonce,uint256 index,address user)"
);
bytes32 constant SET_ONCHAIN_POINTER_TYPEHASH = keccak256("SetOnchainPointer(bytes onchainData,uint96 nonce)");
bytes32 constant SET_PRIMARY_RECEIVER_TYPEHASH = keccak256("SetPrimaryReceiver(address receiver,uint96 nonce)");
bytes32 constant SET_RENDERER_TYPEHASH = keccak256("SetRenderer(address renderer,uint96 nonce)");

// IPFS
bytes constant IPFS_URL = hex"697066733a2f2f172c151325290607391d2c391b242225180a020b291b260929391d1b31222525202804120031280917120b280400";
string constant IPFS_PREFIX = "ipfs://";

// Metadata
string constant API_VERSION = "0.2";
string constant ATTRIBUTES_ENDPOINT = "/attributes.json";
string constant METADATA_ENDPOINT = "/metadata.json";
string constant THUMBNAIL_ENDPOINT = "/thumbnail.json";

// ONCHFS
string constant FX_HASH_QUERY = "/?fxhash=";
string constant FX_PARAMS_QUERY = "#0x";
string constant ITERATION_QUERY = "&fxiteration=";
string constant MINTER_QUERY = "&fxminter=";
string constant ONCHFS_PREFIX = "onchfs://";

// Minters
uint8 constant UNINITIALIZED = 0;
uint8 constant FALSE = 1;
uint8 constant TRUE = 2;

// Project
uint32 constant LOCK_TIME = 3600; // 1 hour
uint64 constant TIME_UNLIMITED = type(uint64).max;
uint120 constant OPEN_EDITION_SUPPLY = type(uint120).max;
uint256 constant LAUNCH_TIMESTAMP = 1702558800; // 12/14/23 14:00 CET

// Roles
bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 constant BANNED_USER_ROLE = keccak256("BANNED_USER_ROLE");
bytes32 constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
bytes32 constant METADATA_ROLE = keccak256("METADATA_ROLE");
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
bytes32 constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
bytes32 constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

// Royalties
uint32 constant ALLOCATION_DENOMINATOR = 1_000_000;
uint96 constant FEE_DENOMINATOR = 10_000;
uint96 constant MAX_ROYALTY_BPS = 2500; // 25%

// Splits
address constant SPLITS_MAIN = 0x2ed6c4B5dA6378c7897AC67Ba9e43102Feb694EE;

// Ticket
uint256 constant AUCTION_DECAY_RATE = 200; // 2%
uint256 constant DAILY_TAX_RATE = 27; // 0.274%
uint256 constant MINIMUM_PRICE = 0.001 ether;
uint256 constant ONE_DAY = 86_400;
uint256 constant SCALING_FACTOR = 10_000;
uint256 constant TEN_MINUTES = 600;
