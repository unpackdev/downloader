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

contract Potus45 is
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

    // Public Constants
    address public constant DEAD =
        address(0x000000000000000000000000000000000000dEaD);
    uint256 public maxSupply;
    uint256 public maxPrivateQuantity; // Maximum amount per user
    uint256 public maxPublicQuantity; // Maximum mint per transaction
    uint256 public privatePrice;
    uint256 public publicPrice;
    uint256 public constant PRIVATE_SALE_OPEN = 1633882800; 
    uint256 public constant PUBLIC_SALE_OPEN = 1633969200; 
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    string public PROVENANCE_HASH;

    // Public Variables
    address public ADMIN;
    address payable public TREASURY;

    // Private Variables
    CountersUpgradeable.Counter private _tokenIds;
    string public baseTokenURI;
    uint256[] private _allTokens; // Array with all token ids, used for enumeration
    mapping(uint256 => string) private _tokenURIs; // Maps token index to URI
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens; // Mapping from owner to list of owned token IDs
    mapping(uint256 => uint256) private _ownedTokensIndex; // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _allTokensIndex; // Mapping from token id to position in the allTokens array

    mapping(address => bool) private _privateSaleWhitelist;
    mapping(address => uint256) private _privateQuantity;


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


    function initialize(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI,
        address admin,
        address payable treasury,
        address owner
    ) external initializer {
        __ERC721_init(name, symbol);
        __Context_init();
        __AccessControlEnumerable_init();
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __ERC721Pausable_init();
        __Ownable_init();

        maxSupply = 10420;
        maxPrivateQuantity = 3;
        maxPublicQuantity = 20;
        privatePrice = 0.08 ether;
        publicPrice = 0.08 ether;

        baseTokenURI = _baseTokenURI;
        ADMIN = admin;
        TREASURY = treasury;
        transferOwnership(owner);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(DEFAULT_ADMIN_ROLE, ADMIN);
        _setupRole(TREASURY_ROLE, TREASURY);
    }

    function mint(uint256 _quantity) public payable whenNotPaused {
        require(
            totalSupply().add(_quantity) <= maxSupply,
            "mint: Quantity must be lesser than maxSupply"
        );
        require(
            _quantity > 0,
            "mint: Quantity must be greater then zero"
        );
        require(
            _quantity <= maxPublicQuantity,
            "mint: Quantity must be less than maxPublicQuantity"
        );
        require(
            msg.value == _quantity * publicPrice,
            "mint: ETH Value incorrect (quantity * publicPrice)"
        );
        require(
            block.timestamp >= PUBLIC_SALE_OPEN,
            "mint: Public Sale not open"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(_msgSender(), newItemId);
            emit Minted(_msgSender(), newItemId);
        }
    }

    function privateMint(uint256 _quantity) public payable whenNotPaused {
        require(
            _privateQuantity[_msgSender()].add(_quantity) <= maxPrivateQuantity,
            "privateMint: Each user should have at most maxPrivateQuantity tokens for private sale"
        );
        require(
            totalSupply().add(_quantity) <= maxSupply,
            "privateMint: Quantity must be lesser than maxSupply"
        );
        require(
            _quantity > 0 && _quantity <= maxPrivateQuantity,
            "privateMint: Quantity must be greater then zero and lesser than maxPrivateQuantity"
        );
        require(
            msg.value == _quantity * privatePrice,
            "privateMint: ETH Value incorrect (quantity * privatePrice)"
        );
        require(
            block.timestamp >= PRIVATE_SALE_OPEN,
            "privateMint: Private Sale not open"
        );
        require(
            isWhitelisted(_msgSender()) == true,
            "privateMint: Not Whitelisted for private sale"
        );

        for (uint256 i = 0; i < _quantity; i++) {
            _tokenIds.increment();
            _privateQuantity[_msgSender()] += 1;
            uint256 newItemId = _tokenIds.current();
            _mint(_msgSender(), newItemId);
            emit Minted(_msgSender(), newItemId);
        }
    }

    // ------------------------- USER FUNCTION ---------------------------
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Get Token URI Concatenated with Base URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, tokenId));
        }

        return super.tokenURI(tokenId);
    }

    // ----------------------- CALCULATION FUNCTIONS -----------------------
    /// @dev Convert String to lower
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function isWhitelisted(address _from) public view returns (bool) {
        return _privateSaleWhitelist[_from];
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

    /// @dev Set some NFTs aside
    function reserve(uint256 _count) public onlyAdmin {
        for (uint256 i = 0; i < _count; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(_msgSender(), newItemId);
        }
    }

    // ---------------------- ADMIN FUNCTIONS -----------------------
    function setProvenanceHash(string memory provenanceHash) public onlyAdmin {
        PROVENANCE_HASH = provenanceHash;
    }

    function updateBaseURI(string memory newURI) public onlyAdmin {
        _setBaseURI(newURI);
    }

    function updateMaxSupply(uint256 _maxSupply) external onlyAdmin {
        maxSupply = _maxSupply;
    }

    function updateQuantity(uint256 _maxPrivateQuantity, uint256 _maxPublicQuantity) external onlyAdmin {
        maxPrivateQuantity = _maxPrivateQuantity;
        maxPublicQuantity = _maxPublicQuantity;
    }

    function updatePrice(uint256 _privatePrice, uint256 _publicPrice) external onlyAdmin {
        privatePrice = _privatePrice;
        publicPrice = _publicPrice;
    }

    ///  @dev Pauses all token transfers.
    function pause() public virtual onlyAdmin {
        _pause();
    }

    /// @dev Unpauses all token transfers.
    function unpause() public virtual onlyAdmin {
        _unpause();
    }

    function updateWhitelist(address[] calldata whitelist) public onlyAdmin {
        for (uint256 i = 0; i < whitelist.length; i++) {
            _privateSaleWhitelist[whitelist[i]] = true;
        }
    }

    function withdrawToTreasury() public onlyTreasury {
        uint256 withdrawAmount = address(this).balance;
        TREASURY.call{value: withdrawAmount}("");
    }

    // --------------------- INTERNAL FUNCTIONS ---------------------
    function _setBaseURI(string memory _baseTokenURI) internal virtual {
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Gets baseToken URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    uint256[33] private __gap;
}
