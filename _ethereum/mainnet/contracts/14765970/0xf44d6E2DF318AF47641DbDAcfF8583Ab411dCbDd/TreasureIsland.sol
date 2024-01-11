// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./IERC165.sol";
import "./IERC2981.sol";
import "./Ownable.sol";

interface IWhitelistContract {
    function isWhitelisted(address account) external view returns (bool);
}

/**
 * @dev Treasure Island
 */
contract TreasureIsland is ERC721Enumerable, Ownable, IERC2981 {
    using Strings for uint256;

    /**
    @dev tokenId to nesting start time (0 = not nesting).
     */
    mapping(uint256 => uint256) private _nestedTokens;

    /**
    @dev Cumulative per-token nesting, excluding the current period.
     */
    mapping(uint256 => uint256) private cummulativeNesting;

    uint256 private nestingTransfer = 1;

    address _whitelist;
    address public _royaltyAddress = address(0);
    uint256 public _royaltyPoints = 1000;
    bool public _isPaused = true;
    bool public _publicMint = false;
    bool public _isNestingOpen = false;
    uint256 public _PRICE;
    uint256 public _SUPPLY;
    string private _baseUri;
    mapping(address => uint8) public mints;
    event Mint(address to, uint256 tokenId);
    event Nested(uint256 indexed tokenId);
    event Unnested(uint256 indexed tokenId);

    constructor(
        uint256 price,
        uint256 supply,
        string memory uri
    ) ERC721("Treasure Island", "TRE") Ownable() ERC721Enumerable() {
        _PRICE = price;
        _SUPPLY = supply;
        _baseUri = uri;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function sanity(uint256 amount) internal view {
        if (!_publicMint) {
            require(
                IWhitelistContract(_whitelist).isWhitelisted(msg.sender),
                "ERC721: Sender is not whitelisted"
            );
        }
        uint256 available = 5 - mints[msg.sender];
        require(available >= amount, "ERC721: mints not available");
        require(!_isPaused, "ERC721: minting paused");
        uint256 totalPrice;
        unchecked {
            totalPrice = _PRICE * amount;
        }
        require(totalPrice <= msg.value, "ERC721: not enough ETH");
    }

    /**
     *@dev Mint many to address
     */
    function mint(address to, uint256 amount) public payable {
        sanity(amount);
        for (uint8 i; i < amount; i++) {
            _mint(to);
        }
    }

    /**
     *@dev Mint one to address
     */
    function mint(address to) public payable {
        sanity(1);
        _mint(to);
    }

    /**
     *@dev Mint one to address
     */
    function _mint(address to) internal {
        uint256 tokenId = totalSupply() + 1;
        _safeMint(to, tokenId);
        mints[msg.sender] = mints[msg.sender] + 1;
        emit Mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(
            _msgSender() == ERC721.ownerOf(tokenId),
            "ERC721: caller must be owner of token"
        );
        _burn(tokenId);
    }

    /**
     * @dev {IERC2981}
     */
    function royaltyInfo(uint256, uint256 price)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (_royaltyAddress, (_royaltyPoints * price) / 10_000);
    }

    /**
     * @dev Set royalty info
     */
    function setRoyaltyInfo(address receiver, uint256 points) public onlyOwner {
        _royaltyAddress = receiver;
        _royaltyPoints = points;
    }

    /**
     *@dev Mint owner.
     */
    function mintOwner(address to) public onlyOwner {
        _mint(to);
    }

    /**
     * @dev Setting the base uri. Can only be called by owner
     */
    function setBaseURI(string memory uri) public onlyOwner {
        _baseUri = uri;
    }

    /**
     * @dev Setting the whitelist contrtact address
     */
    function setWhitelistContract(address whitelist) public onlyOwner {
        _whitelist = whitelist;
    }

    /**
     *@dev Toggle paused state
     */
    function togglePaused(bool paused) public onlyOwner {
        _isPaused = paused;
    }

    /**
     *@dev Toggle public mint
     */
    function togglePublic(bool toggle) public onlyOwner {
        _publicMint = toggle;
    }

    /**
     *@dev Toggle nesting
     */
    function toggleNestingOpen(bool toggle) public onlyOwner {
        _isNestingOpen = toggle;
    }

    function toggleNesting(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: nesting caller is not owner nor approved"
        );

        uint256 start = _nestedTokens[tokenId];
        if (start == 0) {
            require(_isNestingOpen, "ERC721: nesting closed");
            _nestedTokens[tokenId] = block.timestamp;
            emit Nested(tokenId);
        } else {
            cummulativeNesting[tokenId] += block.timestamp - start;
            _nestedTokens[tokenId] = 0;
            emit Unnested(tokenId);
        }
    }

    function toggleNesting(uint256[] memory tokenIds) public {
        for (uint8 i; i < tokenIds.length; i++) {
            toggleNesting(tokenIds[i]);
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    function nestingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool nesting,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = _nestedTokens[tokenId];
        if (start != 0) {
            nesting = true;
            current = block.timestamp - start;
        }
        total = current + cummulativeNesting[tokenId];
    }

    /**
    @dev Disable transfer while nesting
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(_nestedTokens[tokenId] == 0, "ERC721: token is nested");
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}
