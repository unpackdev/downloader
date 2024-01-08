// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;
    uint256 public creaturePrice = 0.09 ether;
    bool public isOpen = false;
    string private _baseUrl;
    address constant private myAddress = 0x69975C0F87d66D0507Aa63464814fC8Cf45fB771;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */     
    function mintTo(address _to) public onlyOwner {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }

    function mintVdv(address _to, uint256 _nb) public payable{
        require(msg.value + 200 >= creaturePrice * _nb, "not enough money");
        require((_nb>=1) && (_nb<21), "too many items");
        require(_currentTokenId.add(_nb) <= 10000, "out of stock");
        for (uint i=0; i< _nb; i++){
            uint256 newTokenId = _getNextTokenId();
            _mint(_to, newTokenId);
            _incrementTokenId();
        }
        address payable wallet = payable(address(myAddress));
        wallet.transfer(msg.value);
    }

    /*
    function setCreaturePrice(uint _price) external onlyOwner {
        creaturePrice = _price;
    }*/

    function setOpen(bool _isopen) external onlyOwner {
        isOpen = _isopen;
    }

    function setBaseUrl(string memory _url) external onlyOwner {
        _baseUrl = _url;
    }

    function getUrl() external view returns(string memory) {
        return _baseUrl;
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function baseTokenURI() virtual public pure returns (string memory);

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        //return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId), ".json"));
        if (!isOpen)
            return string(abi.encodePacked(baseTokenURI(), Strings.toString(1), ".json"));
        //return _token2urls[_tokenId];      _baseUrl
        return string(abi.encodePacked(_baseUrl, Strings.toString(_tokenId), ".json"));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
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
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
