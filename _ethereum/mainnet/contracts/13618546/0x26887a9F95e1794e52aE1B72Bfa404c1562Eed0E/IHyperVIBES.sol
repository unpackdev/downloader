//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";

// data stored for-each infused token
struct TokenData {
    // total staked tokens for this NFT
    uint256 balance;

    // timestamp of last executed claim, determines claimable tokens
    uint256 lastClaimAt;
}

// per-realm configuration
struct RealmConfig {
    // ERC-20 for the realm
    IERC20 token;

    // daily token mining rate -- constant for the entire realm
    uint256 dailyRate;

    // configured constraints for the realm
    RealmConstraints constraints;
}

// constraint parameters for a realm
struct RealmConstraints {
    // An NFT must be infused with at least this amount of the token every time
    // it's infused.
    uint256 minInfusionAmount;

    // An NFT's infused balance cannot exceed this amount. If an infusion would
    // result in exceeding the max token balance, amount transferred is clamped
    // to the max.
    uint256 maxTokenBalance;

    // When claiming mined tokens, at least this much must be claimed at a time.
    uint256 minClaimAmount;

    // If true, the infuser must own the NFT at time of infusion.
    bool requireNftIsOwned;

    // If true, an NFT can be infused more than once in the same realm.
    bool allowMultiInfuse;

    // If true, anybody with enough tokens may infuse an NFT. If false, they
    // must be on the infusers list.
    bool allowPublicInfusion;

    // If true, anybody who owns an infused NFT may claim the mined tokens. If
    // false, they must be on the claimers list
    bool allowPublicClaiming;

    // If true, NFTs from any ERC-721 contract can be infused. If false, the
    // contract address must be on the collections list.
    bool allowAllCollections;
}

// data provided when creating a realm
struct CreateRealmInput {
    // Display name for the realm. Does not have to be unique across HyperVIBES.
    string name;

    // Description for the realm.
    string description;

    // token, mining rate, an constraint data
    RealmConfig config;

    // Addresses that are allowed to add or remove admins, infusers, claimers,
    // or collections to the realm.
    address[] admins;

    // Addresses that are allowed to infuse NFTs. Ignored if the allow public
    // infusion constraint is true.
    address[] infusers;

    // Addresses that are allowed to claim mined tokens from an NFT. Ignored if
    // the allow public claiming constraint is true.
    address[] claimers;

    // NFT contract addresses that can be infused. Ignore if the allow all
    // collections constraint is true.
    IERC721[] collections;
}

// data provided when modifying a realm -- constraints, token, etc are not
// modifiable, but admins/infusers/claimers/collections can be added and removed
// by an admin
struct ModifyRealmInput {
    uint256 realmId;
    address[] adminsToAdd;
    address[] adminsToRemove;
    address[] infusersToAdd;
    address[] infusersToRemove;
    address[] claimersToAdd;
    address[] claimersToRemove;
    IERC721[] collectionsToAdd;
    IERC721[] collectionsToRemove;
}

// data provided when infusing an nft
struct InfuseInput {
    uint256 realmId;

    // NFT contract address
    IERC721 collection;

    // NFT token ID
    uint256 tokenId;

    // Infuser is manually specified, in the case of proxy infusions, msg.sender
    // might not be the infuser. Proxy infusions require msg.sender to be an
    // approved proxy by the credited infuser
    address infuser;

    // total amount of tokens to infuse. Actual infusion amount may be less
    // based on maxTokenBalance realm constraint
    uint256 amount;

    // emitted with event
    string comment;
}

// data provided when claiming from an infused nft
struct ClaimInput {
    uint256 realmId;

    // NFT contract address
    IERC721 collection;

    // NFT token ID
    uint256 tokenId;

    // amount to claim. If this is greater than total claimable, only the max
    // will be claimed (use a huge number here to "claim all" effectively)
    uint256 amount;
}

interface IHyperVIBES {
    event RealmCreated(uint256 indexed realmId, string name, string description);

    event AdminAdded(uint256 indexed realmId, address indexed admin);

    event AdminRemoved(uint256 indexed realmId, address indexed admin);

    event InfuserAdded(uint256 indexed realmId, address indexed infuser);

    event InfuserRemoved(uint256 indexed realmId, address indexed infuser);

    event CollectionAdded(uint256 indexed realmId, IERC721 indexed collection);

    event CollectionRemoved(uint256 indexed realmId, IERC721 indexed collection);

    event ClaimerAdded(uint256 indexed realmId, address indexed claimer);

    event ClaimerRemoved(uint256 indexed realmId, address indexed claimer);

    event ProxyAdded(uint256 indexed realmId, address indexed proxy);

    event ProxyRemoved(uint256 indexed realmId, address indexed proxy);

    event Infused(
        uint256 indexed realmId,
        IERC721 indexed collection,
        uint256 indexed tokenId,
        address infuser,
        uint256 amount,
        string comment
    );

    event Claimed(
        uint256 indexed realmId,
        IERC721 indexed collection,
        uint256 indexed tokenId,
        uint256 amount
    );

    // setup a new realm, returns the ID
    function createRealm(CreateRealmInput memory create) external returns (uint256);

    // update admins, infusers, claimers, or collections for a realm
    function modifyRealm(ModifyRealmInput memory input) external;

    // infuse an nft
    function infuse(InfuseInput memory input) external returns (uint256);

    // allower operator to infuse or claim on behalf of msg.sender for a specific realm
    function allowProxy(uint256 realmId, address proxy) external;

    // deny operator the ability to infuse or claim on behalf of msg.sender for a specific realm
    function denyProxy(uint256 realmId, address proxy) external;

    // claim infused tokens
    function claim(ClaimInput memory input) external returns (uint256);

    // execute a batch of claims
    function batchClaim(ClaimInput[] memory batch) external returns (uint256);

    // execute a batch of infusions
    function batchInfuse(InfuseInput[] memory batch) external returns (uint256);

    // HyperVIBES
    function name() external pure returns (string memory);

    // total amount of mined tokens
    function currentMinedTokens(uint256 realmId, IERC721 collection, uint256 tokenId) external view returns (uint256);
}
