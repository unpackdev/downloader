// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./SafeMath.sol";

/**
 * @title HowdyPartner
 * HowdyPartner - a contract for HowdyPartner
 */
contract HowdyPartner is ERC721Tradable {

    using SafeMath for uint256;
    bool public preSaleIsActive = false; // for compatibility with WenMint's hosted form
    bool public saleIsActive = false;
    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    address constant WALLET2 = 0xd2c7D6Cc69455e713300b86916EfC058554C634f;
    uint256 public maxPerWallet = 5;
    uint256 public preSaleSupply = 1500;
    uint256 public preSalePrice = 60000000000000000;
    uint256 public maxSupply = 5555;
    uint256 _maxPerTransaction = 10;
    uint256 _pubSalePrice = 80000000000000000;
    string _baseTokenURI;

    constructor(address _proxyRegistryAddress) ERC721Tradable("Howdy Partner", "HOWDY", _proxyRegistryAddress) {}

    function setPreSaleSupply(uint256 _supply) external onlyOwner {
        preSaleSupply = _supply;
    }

    function setPreSalePrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    function setPubSalePrice(uint256 _price) external onlyOwner {
        _pubSalePrice = _price;
    }

    function baseTokenURI() override virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function pubSalePrice() public view returns (uint256) {
        if (totalSupply() <= preSaleSupply) {
            return preSalePrice;
        } else {
            return _pubSalePrice;
        }
    }

    function maxPerTransaction() public view returns (uint256) {
        if (totalSupply() <= preSaleSupply) {
            return maxPerWallet;
        } else {
            return _maxPerTransaction;
        }
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setMaxPerWallet(uint256 _maxToMint) external onlyOwner {
        maxPerWallet = _maxToMint;
    }

    function setMaxPerTransaction(uint256 _maxToMint) external onlyOwner {
        _maxPerTransaction = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function reserve(address _address, uint256 _quantity) public onlyOwner {
        uint i;
        for (i = 0; i < _quantity; i++) {
            mintTo(_address);
        }
    }

    function mint(uint _quantity) public payable {
        uint256 currentSupply = totalSupply();
        uint256 balance = balanceOf(msg.sender);
        require(saleIsActive, "Sale is not active.");
        require(currentSupply <= maxSupply, "Sold out.");
        require(currentSupply.add(_quantity) <= maxSupply, "Requested quantity would exceed total supply.");
        if (currentSupply <= preSaleSupply) {
            require(preSalePrice.mul(_quantity) <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= maxPerWallet, "Exceeds per wallet limit for pre-sale.");
            require(balance <= maxPerWallet, "Exceeds per wallet limit for pre-sale.");
            require(balance.add(_quantity) <= maxPerWallet, "Exceeds per wallet limit for pre-sale.");
        } else {
            require(_pubSalePrice.mul(_quantity) <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= _maxPerTransaction, "Exceeds per transaction limit for public sale.");
        }
        for(uint i = 0; i < _quantity; i++) {
            mintTo(msg.sender);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 wallet1Balance = balance.mul(125).div(1000);
        uint256 wallet2Balance = balance.mul(35).div(1000);
        payable(WALLET1).transfer(wallet1Balance);
        payable(WALLET2).transfer(wallet2Balance);
        payable(msg.sender).transfer(
            balance.sub(wallet1Balance.add(wallet2Balance))
        );
    }
}