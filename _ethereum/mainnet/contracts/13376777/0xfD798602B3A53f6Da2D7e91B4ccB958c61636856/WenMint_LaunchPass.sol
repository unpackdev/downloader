// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./SafeMath.sol";

/**
 * @title WenMint LaunchPass
 * WenMint - a contract for WenMint LaunchPass NFTs
 */
contract WenMint_LaunchPass is ERC721Tradable {
    using SafeMath for uint256;
    bool public saleIsActive = false;
    uint256 public mintPrice = 1000000000000000000;
    uint256 public maxToMint = 10;
    uint256 public maxSupply = 100;
    string _baseTokenURI;
    string _contractURI;

    constructor(address _proxyRegistryAddress) ERC721Tradable("WenMint_LaunchPass", "WPASS", _proxyRegistryAddress) {}

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

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        _contractURI = _uri;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setMaxToMint(uint256 _maxToMint) external onlyOwner {
        maxToMint = _maxToMint;
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
        require(totalSupply().add(numberOfTokens) <= maxSupply, "Current batch is sold out.");
        require(mintPrice.mul(numberOfTokens) <= msg.value, "ETH sent is incorrect.");
        require(numberOfTokens <= maxToMint, "Exceeds per wallet limit.");
        for(uint i = 0; i < numberOfTokens; i++) {
            mintTo(msg.sender);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}