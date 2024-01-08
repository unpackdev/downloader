// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IERC2981.sol";
import "./IERC165.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Punk is ERC721, ERC721URIStorage, Ownable, IERC2981 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address _royaltyReceiver;
    uint16 _royaltyPercentage;
    string _contractURI;
    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _contractURIString
    ) ERC721(_name, _symbol) {
        _royaltyReceiver = msg.sender;
        proxyRegistryAddress = _proxyRegistryAddress;
        _contractURI = _contractURIString;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Royalty Info query for nonexistent token");
        uint256 _royaltyAmount = (_royaltyPercentage * _salePrice) / 10000;
        return (_royaltyReceiver, _royaltyAmount);
    }

    function setRoyaltyReceiver(address _receiver) public onlyOwner {
        _royaltyReceiver = _receiver;
    }

    function setRoyaltyPercentage(uint16 _percentage) public onlyOwner {
        _royaltyPercentage = _percentage;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function safeMint(address to, string memory _tokenURI) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        _tokenIdCounter.increment();
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
