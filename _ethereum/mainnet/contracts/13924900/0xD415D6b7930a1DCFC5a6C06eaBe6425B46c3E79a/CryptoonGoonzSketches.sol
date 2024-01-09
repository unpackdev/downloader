// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC2981.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract CryptoonGoonzSketches is ERC721Enumerable, IERC2981, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    string private baseURI;
    address private storeOwner;
    address private proxyRegistryAddress;
    bool public isOpenSeaProxyActive = true;
    uint16 public constant MAX_SUPPLY = 140;

    constructor(
        string memory _name,
        string memory _symbol,
        address _storeOwner,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        storeOwner = _storeOwner;
        proxyRegistryAddress = _proxyRegistryAddress;
        setBaseURI("ipfs://");
        tokenIdCounter.increment();
    }

    function mint(string memory _tokenURI) public onlyOwners {
        _mintTo(msg.sender, _tokenURI);
    }

    function mintTo(address _recipient, string memory _tokenURI) public onlyOwners {
        _mintTo(_recipient, _tokenURI);
    }

    function _mintTo(address _recipient, string memory _tokenURI) private {
        uint256 tokenId = tokenIdCounter.current();
        require(tokenId <= MAX_SUPPLY, "Mint: max supply reached");

        _safeMint(_recipient, tokenId);
        setTokenURI(tokenId, _tokenURI);
        tokenIdCounter.increment();
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwners {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setBaseURI(string memory baseURI_) public onlyOwners {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev To disable OpenSea gasless listings proxy in case of an issue
     */
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive) external onlyOwner {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    modifier onlyOwners() {
        require(owner() == _msgSender() || storeOwner == _msgSender(), "caller is not the contract or store owner");
        _;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice enable OpenSea gasless listings
     * @dev Overriding `isApprovedForAll` to allowlist user's OpenSea proxy accounts
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 15), 200));
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
