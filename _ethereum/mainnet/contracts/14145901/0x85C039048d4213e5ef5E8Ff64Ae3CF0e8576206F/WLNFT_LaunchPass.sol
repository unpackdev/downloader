// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721A.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract WLNFT_LaunchPass is ERC721A, Ownable {

    bool public saleIsActive = false;
    uint256 public preSalePrice = 1000000000000000000; // for compatibility with WenMint hosted form
    uint256 public pubSalePrice = 1000000000000000000;
    uint256 public maxPerWallet = 1; // for compatibility with WenMint hosted form
    uint256 public maxPerTransaction = 1;
    uint256 public maxSupply = 10000;
    string _baseTokenURI;
    address proxyRegistryAddress;

    constructor(address _proxyRegistryAddress) ERC721A("WhitelistNFT LaunchPass", "WxLAUNCH", 100) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply > maxSupply, "You cannot reduce supply.");
        maxSupply = _maxSupply;
    }

    function setPubSalePrice(uint256 _price) external onlyOwner {
        pubSalePrice = _price;
    }

    function setMaxPerTransaction(uint256 _maxToMint) external onlyOwner {
        maxPerTransaction = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function reserve(address _address, uint256 _quantity) public onlyOwner {
        _safeMint(_address, _quantity);
    }

    function mint(uint256 _quantity) public payable {
        require(saleIsActive, "Sale is not active.");
        require(totalSupply() < maxSupply, "Sold out.");
        require(pubSalePrice * _quantity <= msg.value, "ETH sent is incorrect.");
        require(_quantity <= maxPerTransaction, "Exceeds per transaction limit.");
        _safeMint(msg.sender, _quantity);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}