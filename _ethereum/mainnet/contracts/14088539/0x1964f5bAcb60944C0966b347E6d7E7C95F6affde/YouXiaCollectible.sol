//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract YouXiaCollectible is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string public baseTokenURI;

    uint public maxSupply = 20;
    uint public unitPrice = 0.01 ether;
    uint public maxMint = 5;

    constructor(string memory baseURI) ERC721("YouXia Collectible", "NFTC") {
        setBaseURI(baseURI);
    }

    function mintNFTs(uint _count) public payable {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(_count) <= maxSupply, "Not enough NFTs left!");
        require(_count > 0 && _count <= maxMint, "Cannot mint specified number of NFTs.");
        require(msg.value >= unitPrice.mul(_count), "Not enough ether to purchase NFTs.");

        for (uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMaxSupply(uint _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setUnitPrice(uint _unitPrice) public onlyOwner {
        unitPrice = _unitPrice;
    }

    function setMaxMint(uint _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function surplusSupply() external view returns (uint) {
        return maxSupply - totalSupply();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _mintSingleNFT() private {
        _tokenIds.increment();
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
    }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
}
