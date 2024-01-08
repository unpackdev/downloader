//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20.sol";
import "./IERC721Enumerable.sol";

import "./IYieldTokenUpgradeable.sol";

contract CheekyCorgiBase is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    struct PaymentMethod{
        address token;
        uint256 decimals;
        uint256 publicPrice;
    }

    struct ClaimableNft {
        address token;
        mapping(uint256 => bool) claimed;
    }

    // Public Constants
    address public constant DEAD =
        address(0x000000000000000000000000000000000000dEaD);
    uint256 public maxSupply;
    uint256 public maxPrivateQuantity; // Maximum amount per user
    uint256 public maxPublicQuantity; // Maximum mint per transaction
    uint256 public privatePrice;
    uint256 public publicPrice;
    uint256 public constant PRIVATE_SALE_OPEN = 1638792000;
    uint256 public constant PUBLIC_SALE_OPEN = 1638878400;
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    address public constant UCD = 0xB1Db366890EeB8f28C2813C6a6084353e0b90713;

    string public PROVENANCE_HASH;

    IYieldTokenUpgradeable public YIELD_TOKEN;

    // Public Variables
    uint256 public NAME_CHANGE_PRICE; 
    uint256 public BIO_CHANGE_PRICE; 

    address public ADMIN;
    address payable public TREASURY;
    mapping(uint256 => uint256) public birthTimes;
    mapping(uint256 => string) public bio;

    // Private Variables
    CountersUpgradeable.Counter internal _tokenIds;
    string public baseTokenURI;
    uint256[] internal _allTokens; // Array with all token ids, used for enumeration
    mapping(uint256 => string) internal _tokenURIs; // Maps token index to URI
    mapping(address => mapping(uint256 => uint256)) internal _ownedTokens; // Mapping from owner to list of owned token IDs
    mapping(uint256 => uint256) internal _ownedTokensIndex; // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal _allTokensIndex; // Mapping from token id to position in the allTokens array
    mapping(uint256 => string) internal _tokenName;
    mapping(string => bool) internal _nameReserved;

    mapping(address => bool) internal _privateSaleWhitelist;
    mapping(address => uint256) internal _privateQuantity;

    PaymentMethod[4] public PAYMENT_METHODS;

    mapping(address => bool) public claimedAddresses; // wallet address vs claimed status
    ClaimableNft[2] internal Claimables;    // 2 Friendship NFT, Junkyard & ApprovingCorgis
    // 3rd option for claiming, just UCD holders
    mapping(address => bool) public claimableUcdHolders;   // address, who holds 500 + UCDs

    uint256 public totalClaimed;
    uint256 public maxClaimable;

    address internal adminImplementation;

    // Please update the following _gap size if changing the storage here.
    uint256[19] private __gap;

    // Modifiers
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "OnlyAdmin"
        );
        _;
    }

    // Modifiers
    modifier onlyTreasury() {
        require(
            hasRole(TREASURY_ROLE, _msgSender()),
            "OnlyTreasury"
        );
        _;
    }

    // Events
    event Minted(address indexed minter, uint256 indexed tokenId);
    event Sacrifice(address indexed minter, uint256 indexed tokenId);
    event NameChange(uint256 indexed tokenId, string newName);
    event BioChange(uint256 indexed tokenId, string bio);

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
