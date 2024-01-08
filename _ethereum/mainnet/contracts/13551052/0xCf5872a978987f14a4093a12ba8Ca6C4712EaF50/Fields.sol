// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./IERC721.sol";

interface IDepositor {
    function getContractBalance() external view returns (uint256);

    function withdrawTo(address to_, uint256 value) external;
}

interface ISoulToken {
    function goldTokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function setGoldRole(uint256 tokenId, uint256 numberOfMintedTokens)
        external;
}

contract Fields {
    // struct that holds information about when a token was created/transferred
    struct NFTDetails {
        uint256 tokenId;
        uint256 index;
        uint256 starTime;
        uint256 endTime;
    }
    // struct that holds information about royalty stages to reward token owners
    struct RoyaltyStage {
        uint256 startDate;
        uint256 endDate;
        uint256 amount;
        uint256 totalSupply;
        uint256 totalWithdrawals;
    }

    // nonce to be used on generating the random token id
    uint16 nonce;
    uint16[1000] indices;

    // maximum number of tokens that can be minted. can be changed to lower number
    uint256 internal MAX_TOKENS = 1000;
    uint256 internal MAX_WHITELIST_TOKENS = 500;
    uint256 internal MAX_WHITELIST_PER_PURCHASE = 5;
    // maximum number of tokens that can be minted in a single transaction
    uint256 internal constant MAX_TOKENS_PER_PURCHASE = 15;
    // maximum number of tokens that can be minted at pre-sale
    uint256 internal constant MAX_PRE_SALE_TOKENS = 10;
    // max number of reserved tokens
    uint256 internal constant MAX_RESERVED_TOKENS = 60;
    // minted reserved tokens
    uint256 internal mintedReservedTokens;

    uint256 internal firstPaymentRemaining;

    // the price to mint a token
    uint256 internal constant MINT_PRICE = 0.06 ether;
    uint256 internal constant MINT_PRICE_WHITELIST = 0.04 ether;

    uint8 internal currentMaxTokensBeforeAutoWithdraw;
    uint8 internal constant MAX_TOKENS_BEFORE_AUTO_WITHDRAW = 25;

    uint8 numberOfReservedTeamCustomTokens;

    uint256 public numberOfMintedWhitelistTokens;

    bool public whitelistMintingStarted = true;

    bool public publicMintingStarted;

    string internal constant ROLE_LION = "LION";
    string internal constant ROLE_INFERNAL = "INFERNAL";
    mapping(address => string) public addressRoles;
    mapping(uint256 => string) public tokenRoles;
    mapping(address => uint256) public numberOfMintedTokensFor;
    mapping(uint256 => uint8) goldTokenUsed;

    mapping(address => bool) internal claimedFree;
    mapping(address => bool) internal claimedGoldFree;
    mapping(address => uint8) internal mintedWhitelist;

    // receiver address to ge the funds
    address[5] internal receiverAddresses;
    // receiver percentage of total funds
    uint256[5] internal receiverPercentages;
    // current balance to withdraw from contract by a specific address
    uint256[5] internal currentTeamBalance;
    // mapping from address to index of receiverAddresses array
    mapping(address => uint8) internal addressToIndex;

    // current royalty to withdraw from contract by a specific address
    uint256[5] internal currentTeamRoyalty;
    // mapping from address to index of royalty receiverAddresses array
    mapping(address => uint8) internal addressRoyaltyToIndex;

    // the baseURI for token metadata
    string internal baseURI;

    // mapping from owner to list of token ids
    mapping(address => uint256[]) internal ownerTokenList;
    // mapping from token ID to token details of the owner tokens list
    mapping(address => mapping(uint256 => NFTDetails))
        internal ownedTokensDetails;
    // mapping from owner address to the stage index to start collecting royalties
    mapping(address => uint256) internal ownerRoyaltyStageIndex;

    // the interval in which royalty gets collected
    uint256 public royaltyInterval = 4 weeks;
    // royalty stage details
    RoyaltyStage[] public royaltyStages;
    // mapping from owner address to the stage index to start collecting royalties
    mapping(uint256 => mapping(uint256 => bool)) internal royaltyTokenClaimed;

    // total royalty added to the depositor
    uint256 internal totalRoyaltyAdded;
    // total royalty withdrawed
    uint256 internal totalRoyaltyWithdrawed;

    // index from which the owner will withdraw the unclaimed rewards;
    uint256 internal unclaimedRoyaltyStageIndex;
    uint256 internal constant WITHDRAW_ROYALTY_TIME = 365 days;

    IDepositor internal depositor;
    ISoulToken internal soulToken;

    string internal constant SAME_VALUE = "same value";
    string internal constant WRONG_BALANCE = "wrong balance";
    string internal constant DISABLED_CHANGES = "disabled changes";
    string internal constant NO_BALANCE = "no balance";
    string internal constant WRONG_LENGTH = "wrong length";
    string internal constant TOO_MANY = "too many";
    string internal constant NOT_STARTED = "not started";
    string internal constant NO_ACCESS = "no access";
    string internal constant CANT_MINT = "can't mint";
    string internal constant ALREADY_ENABLED = "already enabled";
    string internal constant FUNCTION_CALL_ERROR =
        "Function call not successful";
}
