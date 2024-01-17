// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";

contract DeSpace_721_NFT is
    AccessControlEnumerable,
    ERC721Burnable,
    ERC721URIStorage,
    ERC721Enumerable
{
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _id;
    uint96 public immutable royalty;
    address payable private controller;
    string private _uri;

    mapping(address => bool) public whitelisted;

    event MarketUpdated(
        address indexed admin,
        address indexed market,
        bool ismarket
    );

    event RoyaltyInfoUpdated(address indexed caller, address indexed receiver);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory uri,
        address payable _controller,
        uint96 _royalty //1% = 100
    ) ERC721(_name, _symbol) {
        require(_controller != address(0), "Invalid address");
        _uri = uri;
        controller = _controller;
        royalty = _royalty;
        _setupRole(DEFAULT_ADMIN_ROLE, _controller);
        _setupRole(MINTER_ROLE, _controller);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _controller);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    modifier adminOnly() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "UNAUTHORIZED_CALLER");
        _;
    }

    modifier minterOnly() {
        require(hasRole(MINTER_ROLE, _msgSender()), "UNAUTHORIZED_CALLER");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setCustomURI(uint256 _tokenId, string memory _newURI)
        external
        adminOnly
    {
        _setTokenURI(_tokenId, _newURI);
    }

    function updateMarket(address market, bool isMarket) external adminOnly {
        require(market != address(0), "ZERO_ADDRESS");

        whitelisted[market] = isMarket;
        emit MarketUpdated(msg.sender, market, isMarket);
    }

    function mint(address to) external minterOnly returns (uint256 newItemId) {
        return _mintToken(to);
    }

    function mintBatch(address to, uint256 quantity)
        external
        minterOnly
        returns (uint256[] memory newItemIds)
    {
        for (uint256 i = 0; i < quantity; i++) {
            newItemIds[i] = _mintToken(to);
        }
    }

    function _mintToken(address to) private returns (uint256 newItemId) {
        _id.increment();
        newItemId = _id.current();
        _safeMint(to, newItemId);
    }

    function setRoyaltyInfo(address payable _receiver) external adminOnly {
        require(_receiver != address(0), "INVALID_ADDRESS");
        controller = _receiver;
        emit RoyaltyInfoUpdated(msg.sender, _receiver);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function royaltyInfo(uint256 price)
        external
        view
        returns (address, uint256)
    {
        return (controller, calculateRoyalty(price));
    }

    function calculateRoyalty(uint256 price) public view returns (uint256) {
        return (price * royalty) / 10000;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool itSupports)
    {
        //bytes4(keccak256("royaltyInfo(uint256)"))
        return
            interfaceId == 0xcef6d368 ||
            interfaceId == 0x2a55205a ||
            super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool isOperator)
    {
        if (whitelisted[operator]) return true;

        return ERC721.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage, ERC721)
        returns (string memory URI)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, id);
    }
}
