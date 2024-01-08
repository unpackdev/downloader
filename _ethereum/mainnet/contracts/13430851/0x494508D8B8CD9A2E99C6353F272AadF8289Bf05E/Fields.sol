// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./IERC721.sol";

interface IDepositor {
    function getContractBalance() external view returns (uint256);

    function withdrawTo(address to_, uint256 value) external;
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
    }

    struct IndexStorage {
        // nonce to be used on generating the random token id
        uint16 nonce;
        uint16[] indices;
    }
    IndexStorage indexStorage;

    // emits BaseURIChanged event when the baseURI changes
    event BaseURIChanged(string initialBaseURI, string finalBaseURI);

    // maximum number of tokens that can be minted. can be changed to lower number
    uint256 public MAX_TOKENS = 250;
    // maximum number of tokens that can be minted in a single transaction
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 3;

    // the price to mint a token
    uint256 public constant MINT_PRICE = 0.04 ether;

    uint8 public currentMaxTokensBeforeAutoWithdraw;
    uint8 public constant MAX_TOKENS_BEFORE_AUTO_WITHDRAW = 50;

    uint256 public whitelistMintingStartTime;
    uint256 public maxWhitelistMintingTime = 2 days;
    bool public whitelistMintingStarted;

    uint256 public publicMintingStartTime;
    bool public publicMintingStarted;

    string public constant ROLE_Common = "Common";
    string public constant ROLE_Uncommon = "Uncommon";
    string public constant ROLE_Rare = "Rare";
    string public constant ROLE_Epic = "Epic";
    string public constant ROLE_Legendary = "Legendary";
    mapping(address => string) public addressRoles;
    mapping(address => uint256) public numberOfMintedTokensFor;
    mapping(address => uint256) public claimedFreeMintedTokensFor;
    mapping(uint256 => string) public tokenRoles;

    // receiver address to ge the funds
    address[] public receiverAddresses;
    // receiver percentage of total funds
    uint256[] public receiverPercentages;
    // current balance to withdraw from contract by a specific address
    uint256[] internal currentTeamBalance;
    // mapping from address to index of receiverAddresses array
    mapping(address => uint8) internal addressToIndex;

    // royalty receiver address to ge the funds
    address[] public royaltyReceiverAddresses;
    // royalty receiver percentage of total funds
    uint256[] public royaltyReceiverPercentages;
    // current royalty to withdraw from contract by a specific address
    uint256[] internal currentTeamRoyalty;
    // mapping from address to index of royalty receiverAddresses array
    mapping(address => uint8) internal addressRoyaltyToIndex;

    // the baseURI for token metadata
    string public baseURI;
    // flag to signal if the owner can change the baseURI
    bool public canChangeBaseURI = true;

    // mapping from owner to list of token ids
    mapping(address => uint256[]) public ownerTokenList;
    // mapping from token ID to token details of the owner tokens list
    mapping(address => mapping(uint256 => NFTDetails))
        public ownedTokensDetails;
    // mapping from owner address to the stage index to start collecting royalties
    mapping(address => uint256) public ownerRoyaltyStageIndex;

    // the interval in which royalty gets collected
    uint256 public royaltyInterval = 4 weeks;
    // royalty stage details
    RoyaltyStage[] public royaltyStages;

    // total royalty added to the depositor
    uint256 public totalRoyaltyAdded;
    // total royalty withdrawed
    uint256 public totalRoyaltyWithdrawed;

    IDepositor depositor;

    string internal constant SAME_VALUE = "same value";
    string internal constant WRONG_BALANCE = "wrong balance";
    string internal constant DISABLED_CHANGES = "disabled changes";
    string internal constant IS_EMPTY = "is empty";
    string internal constant NO_BALANCE = "no balance";
    string internal constant WRONG_LENGTH = "wrong length";
    string internal constant TOO_MANY = "too many";
    string internal constant NOT_STARTED = "not started";
    string internal constant NO_ACCESS = "no access";
    string internal constant CANT_MINT = "can't mint";
    string internal constant ALREADY_ENABLED = "already enabled";
    string internal constant ALREADY_DISABLED = "already disabled";
    string internal constant FUNCTION_CALL_ERROR =
        "Function call not successful";
}
