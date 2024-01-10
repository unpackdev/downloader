// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./Context.sol";

import "./Ownable.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Kongtama is Ownable, ERC721 {
    using Strings for uint256;

    address private _proxyRegistryAddress;

    uint256 private _price;
    uint256 private _maxMint;
    uint256 private _maxMintPerWallet = 10;  
    uint256 private _currentTokenID;


    string private _baseMetadataURI;
    mapping(address => uint8) public mintsPerWallet;

    constructor(
        address owner, 
        address proxyRegistryAddress, 
        uint256 price, 
        uint256 maxMint,
        string memory baseMetadataURI
    ) ERC721("Kongtama", "Kong") Ownable(owner) {
        _price = price;
        _maxMint = maxMint;
        _proxyRegistryAddress = proxyRegistryAddress;
        _baseMetadataURI = baseMetadataURI;
    }

    /***********************************|
    |        Ownable Functions          |
    |__________________________________*/

    function setPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function setMaxMint(uint256 newMaxMint) public onlyOwner {
        _maxMint = newMaxMint;
    }

    function setMaxMintPerWallet(uint256 newMaxMintPerWallet) public onlyOwner {
        _maxMintPerWallet = newMaxMintPerWallet;
    }

    function setProxyRegistryAddress(address newProxyRegistryAddress) public onlyOwner {
        _proxyRegistryAddress = newProxyRegistryAddress;
    }

    function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyOwner {
        _baseMetadataURI = _newBaseMetadataURI;
    }

    /**
    * @dev calculates the next token ID based on value of _currentTokenID
    * @return uint256 for the next token ID
    */
    function getNextTokenID() public view returns (uint256) {
        return _currentTokenID + 1;
    }

    /**
        * @dev increments the value of _currentTokenID
        */
    function _incrementTokenTypeId() private {
        _currentTokenID++;
    }


    function mint(uint8 amount) public payable {
        require(amount > 0, "Wrong batch amout");

        uint256 tokenId = _currentTokenID;
        require(tokenId + amount <= _maxMint, "Amount reaches maxMint");

        address owner = owner();
        address sender = _msgSender();
        uint256 value = msg.value;

        if(sender == owner) {
            require(value == 0, "Owner doesn't need to send ETH");
            _mintBatch(sender, amount);
            return;
        }

        require(mintsPerWallet[sender] + amount <= _maxMintPerWallet, "Reached maxMintPerWallet");

       
        uint256 tokenPrice = _price;
        require(value >= tokenPrice*amount, "Not enough ETH");

        payable(owner).transfer(value);
        _mintBatch(sender, amount);
    }

    function _mintBatch(address to, uint8 amount) internal {
        for (uint i=0; i < amount; i++){
            _incrementTokenTypeId();
            uint256 tokenId = _currentTokenID;
            mintsPerWallet[to] += 1;
            _safeMint(to, tokenId);
        }
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 _id) public override view returns (string memory) {
        require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
        return bytes(_baseMetadataURI).length > 0 ? string(abi.encodePacked(_baseMetadataURI, _id.toString())) : "";
    }

    function withdraw() public {
        payable(owner()).transfer(address(this).balance);
    }

    function getPrice() public view returns(uint256) {
        return _price;
    }

    function getMaxMint() public view returns(uint256) {
        return _maxMint;
    }

    function getMaxMintperWallet() public view returns(uint256) {
        return _maxMintPerWallet;
    }
}