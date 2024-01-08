// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Kn0wbot is
    ERC721,
    ERC721Enumerable,
    Ownable,
    ContextMixin,
    NativeMetaTransaction
{
    using Counters for Counters.Counter;
    uint256 public maxSupply = 10000;
    uint256 public cost = 0.05 ether;
    string public baseURI =
        "ipfs://QmYyiYyvA5k7RCWPny6LE2zaFNLa9dYMh1hse3CQT6pS7Y/";
    address public proxyRegistryAddress;
    Counters.Counter private _tokenIdCounter;

    constructor(address _proxyRegistryAddress) ERC721("Kn0wbot", "KBOT") {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712("Kn0wbot");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function safeMint(address to) public payable {
        uint256 supply = totalSupply();
        require(supply + 1 <= maxSupply, "All tokens have been minted");

        if (msg.sender != owner()) {
            require(
                msg.value >= cost,
                "Wrong amount of ETH sent. Cost is 0.05 ETH"
            );
        }

        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    // Opensea proxy
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

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
