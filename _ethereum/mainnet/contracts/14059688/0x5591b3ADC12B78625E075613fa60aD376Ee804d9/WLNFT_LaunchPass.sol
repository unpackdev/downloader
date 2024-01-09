// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./SafeMath.sol";

/**
 * @title WhitelistNFT
 * WhitelistNFT - a contract for WhitelistNFT LaunchPass NFTs
 */

contract WLNFT_LaunchPass is ERC721Tradable {

    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    address constant WALLET2 = 0xe5c07AcF973Ccda3a141efbb2e829049591F938e;
    address constant WALLET3 = 0xC87C8BF777701ccFfB1230051E33f0524E5975b5;
    using SafeMath for uint256;
    bool public saleIsActive = false;
    uint256 public preSalePrice = 1000000000000000000; // for compatibility with WenMint hosted form
    uint256 public pubSalePrice = 1000000000000000000;
    uint256 public maxPerWallet = 1; // for compatibility with WenMint hosted form
    uint256 public maxPerTransaction = 1;
    uint256 public maxSupply = 10000;
    string _baseTokenURI;
    string _contractURI;

    constructor(address _proxyRegistryAddress) ERC721Tradable("WLNFT_LaunchPass", "WLNFT", _proxyRegistryAddress) {}

    function baseTokenURI() override virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply > maxSupply, "You cannot reduce supply.");
        maxSupply = _maxSupply;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
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

    function reserve(address to, uint256 numberOfTokens) public onlyOwner {
        uint i;
        for (i = 0; i < numberOfTokens; i++) {
            mintTo(to);
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active.");
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Sold out.");
        require(pubSalePrice.mul(numberOfTokens) <= msg.value, "ETH sent is incorrect.");
        require(numberOfTokens <= maxPerTransaction, "Exceeds per transaction limit.");
        for(uint i = 0; i < numberOfTokens; i++) {
            mintTo(msg.sender);
        }
    }

    function withdraw() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        uint256 balance1 = totalBalance.mul(40).div(100);
        uint256 balance2 = totalBalance.mul(20).div(100);
        uint256 balance3 = totalBalance.mul(20).div(100);
        payable(WALLET1).transfer(balance1);
        payable(WALLET2).transfer(balance2);
        payable(WALLET3).transfer(balance3);
        uint256 balance4 = totalBalance.sub(balance1.add(balance2).add(balance3));
        payable(msg.sender).transfer(balance4);
    }
}